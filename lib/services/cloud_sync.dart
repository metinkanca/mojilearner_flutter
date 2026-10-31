import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_snapshot.dart';

/// Where a snapshot goes. Firestore in the app, a fake in tests — the point of
/// the seam is that none of the scheduling logic below needs a live backend to
/// be exercised.
abstract class CloudSyncBackend {
  /// A stable id for this player, created silently on first run.
  Future<String?> signIn();

  /// The stored document, or null when this player has never synced.
  Future<Map<String, dynamic>?> fetch(String uid);

  /// Writes the whole document. One call, one billed write.
  Future<void> upload(String uid, Map<String, dynamic> data);

  /// Removes the stored document. Deleting one that is not there succeeds, so
  /// a retry after a half-finished erase is safe.
  Future<void> delete(String uid);
}

/// Keeps local progress mirrored to a backend, cheaply.
///
/// The whole design exists to answer one question: how many writes does a
/// player cost per day? Persisting on every change — which is what the app
/// does locally — measured at roughly 130-210 writes per active player per
/// day, and Firestore's free tier is 20,000 writes per day for the *whole
/// project*. That is about a hundred players before saving starts failing.
///
/// So nothing here writes on change. Instead:
///
///  * a snapshot is taken on a timer and when the app leaves the foreground,
///  * it is hashed, and an unchanged hash does not write at all,
///  * and the whole of local state is one document, so a write costs one
///    write no matter how much moved.
///
/// That lands around 2-6 writes per player per day, which is a few thousand
/// players inside the free tier instead of a hundred.
class CloudSync with WidgetsBindingObserver {
  CloudSync({
    required CloudSyncBackend backend,
    Duration flushInterval = const Duration(minutes: 5),
  })  : _backend = backend,
        _flushInterval = flushInterval;

  final CloudSyncBackend _backend;
  final Duration _flushInterval;

  /// Local marker of what the backend last accepted. Kept in prefs rather than
  /// memory so a relaunch does not re-upload an unchanged snapshot.
  ///
  /// This key and [_revisionPrefsKey] are both in
  /// [LocalSnapshot.syncBookkeepingPrefs], and that is load-bearing: they
  /// change on every upload, so a snapshot that included them would hash
  /// differently every time, write, change them again, and write forever. An
  /// unbounded write loop is the exact failure that turns a $0 Firestore bill
  /// into a real one.
  static const String _lastSyncedHashKey = 'sync_last_hash';

  /// Local copy of the revision last written, so a device that has been played
  /// on can be told apart from a fresh install.
  static const String _revisionPrefsKey = 'sync_revision';

  /// The same number on the stored document.
  static const String _revisionField = 'revision';

  /// Set when a player erased their data but the cloud copy could not be
  /// reached (offline). Survives `SharedPreferences.clear()` because it is
  /// written *after* it, and makes the next [start] delete the stored save
  /// before anything is allowed to restore it. Without this an offline reset
  /// would be undone by the next launch.
  static const String _pendingEraseKey = 'sync_pending_erase';

  /// Whether this device has been played on, i.e. already holds a save.
  ///
  /// Decides how startup may treat sync: a device with a save never has one
  /// restored over it, so it can open straight away and sync in the background.
  /// A device without one has to wait, because a restore rewrites the storage
  /// the providers are about to read.
  static Future<bool> hasLocalSave() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_revisionPrefsKey) != null;
  }

  String? _uid;
  Timer? _timer;
  bool _flushing = false;

  /// While true nothing uploads. Held for the length of an erase, so the timer
  /// cannot re-upload the save that is being deleted.
  bool _paused = false;

  bool get isSignedIn => _uid != null;

  /// Signs in and pulls down a save if this device does not already have one.
  ///
  /// Call before the providers are constructed: they read local storage once,
  /// at creation, so restoring underneath them afterwards would leave the UI
  /// showing the old save until the next launch.
  Future<void> start() async {
    _uid = await _backend.signIn();
    if (_uid == null) return;

    await _finishPendingErase();
    await restoreIfRemoteIsAhead();

    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(_flushInterval, (_) => flush());
  }

  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  /// Deletes the stored save if an earlier erase could not reach it.
  ///
  /// If it still cannot, the marker stays and [restoreIfRemoteIsAhead] refuses
  /// to restore while it is set, so the erased save is never pulled back down.
  Future<void> _finishPendingErase() async {
    final uid = _uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_pendingEraseKey) != true) return;
    try {
      await _backend.delete(uid);
      await prefs.remove(_pendingEraseKey);
    } catch (e) {
      debugPrint('⚠️ SYNC: pending erase still cannot reach the cloud - $e');
    }
  }

  /// Stops uploads and deletes the stored save, ahead of wiping the device.
  ///
  /// Returns whether the cloud copy is gone. A false is not an error to show:
  /// the caller wipes the device anyway and calls [rememberPendingErase], so
  /// the delete is retried on a later launch rather than the reset being
  /// refused because the phone is offline.
  Future<bool> deleteCloudCopy() async {
    _paused = true;
    final uid = _uid;
    if (uid == null) return true;
    try {
      await _backend.delete(uid);
      return true;
    } catch (e) {
      debugPrint('⚠️ SYNC: could not delete the cloud copy - $e');
      return false;
    }
  }

  /// Leaves a note, after the device has been wiped, that the cloud copy
  /// survived. Must run after `SharedPreferences.clear()` or it is cleared too.
  Future<void> rememberPendingErase() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingEraseKey, true);
  }

  /// Picks sync back up after an erase, under whatever identity is signed in
  /// now. After an account deletion that is a brand-new anonymous one, so the
  /// player who deleted their account can keep using the app.
  Future<void> resumeAfterErase() async {
    _uid = await _backend.signIn();
    _paused = false;
  }

  /// Pulls the stored save down when this device has nothing of its own.
  ///
  /// Deliberately not a merge. Merging a tamagotchi is not obviously
  /// meaningful — there is no sensible way to combine two pets that were both
  /// fed at 8am — and guessing wrong destroys the thing the player cares
  /// about. So: restore only onto a device with no local revision, which is
  /// exactly the reinstall and new-phone case this exists for. A device that
  /// has been played on keeps what it has and pushes it up on the next flush.
  Future<void> restoreIfRemoteIsAhead() async {
    final uid = _uid;
    if (uid == null) return;

    final prefs = await SharedPreferences.getInstance();
    final localRevision = prefs.getInt(_revisionPrefsKey);
    if (localRevision != null) return; // Played on. Leave it alone.
    // An erase the cloud has not heard about yet: what is stored there is what
    // the player asked to have deleted, not a save to bring back.
    if (prefs.getBool(_pendingEraseKey) == true) return;

    final remote = await _backend.fetch(uid);
    if (remote == null) return; // Nothing stored; nothing to restore.

    await LocalSnapshot.restore(remote);

    final revision = remote[_revisionField];
    if (revision is int) await prefs.setInt(_revisionPrefsKey, revision);
  }

  /// Re-points sync at a different identity, after the player signs in.
  ///
  /// The uid has just changed, so the local save and the stored one now belong
  /// to different accounts and the usual "has this device been played on?"
  /// rule no longer means anything. [keepLocalProgress] is the player's answer
  /// to which pet survives, and it is the caller's job to have asked:
  ///
  ///  * `true` — this device's pet wins. The last-synced hash is cleared so
  ///    the next flush is guaranteed to upload, overwriting the account's save.
  ///  * `false` — the account's saved pet wins. The local revision is cleared,
  ///    which is exactly the state a fresh install is in, so the ordinary
  ///    restore path pulls the save down.
  ///
  /// Nothing here decides on the player's behalf. Silently picking one is how
  /// a sync feature ends up deleting the thing it exists to protect.
  Future<void> onAccountChanged({required bool keepLocalProgress}) async {
    _uid = await _backend.signIn();
    if (_uid == null) return;

    final prefs = await SharedPreferences.getInstance();
    // Either way this is stale: it describes what some *other* account last
    // accepted, so leaving it could make a needed upload look redundant.
    await prefs.remove(_lastSyncedHashKey);

    if (keepLocalProgress) {
      await flush();
      return;
    }

    await prefs.remove(_revisionPrefsKey);
    await restoreIfRemoteIsAhead();
  }

  /// Uploads local state, unless it is byte-for-byte what was last uploaded.
  ///
  /// The hash check is what makes the timer safe to run: an idle app on a
  /// five-minute timer would otherwise pay 288 writes a day for changing
  /// nothing at all.
  Future<bool> flush() async {
    final uid = _uid;
    if (uid == null || _flushing || _paused) return false;
    _flushing = true;

    try {
      final snapshot = await LocalSnapshot.capture();
      final hash = _hash(snapshot);

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_lastSyncedHashKey) == hash) return false;

      final revision = (prefs.getInt(_revisionPrefsKey) ?? 0) + 1;
      await _backend.upload(uid, {
        ...snapshot,
        _revisionField: revision,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });

      await prefs.setInt(_revisionPrefsKey, revision);
      await prefs.setString(_lastSyncedHashKey, hash);
      // The upload replaced the document, so the save that was waiting to be
      // deleted is gone, and deleting "the cloud copy" on the next launch would
      // now delete what the player has built since.
      await prefs.remove(_pendingEraseKey);
      return true;
    } catch (e) {
      // A failed sync is not a failed app. The local save is untouched and
      // the next flush retries, so there is nothing here worth interrupting
      // the player for.
      debugPrint('⚠️ SYNC: flush failed - $e');
      return false;
    } finally {
      _flushing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The important one. A player who closes the app mid-session should not
    // lose the session, and this is the last moment we are told about.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      flush();
    }
  }

  static String _hash(Map<String, dynamic> snapshot) {
    // Sorted so two identical snapshots cannot hash differently because a map
    // happened to iterate in another order.
    return sha256.convert(utf8.encode(jsonEncode(_sorted(snapshot)))).toString();
  }

  static Object? _sorted(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((k) => k.toString()).toList()..sort();
      return {for (final k in keys) k: _sorted(value[k])};
    }
    if (value is List) return value.map(_sorted).toList();
    return value;
  }
}
