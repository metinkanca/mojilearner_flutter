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

  String? _uid;
  Timer? _timer;
  bool _flushing = false;

  bool get isSignedIn => _uid != null;

  /// Signs in and pulls down a save if this device does not already have one.
  ///
  /// Call before the providers are constructed: they read local storage once,
  /// at creation, so restoring underneath them afterwards would leave the UI
  /// showing the old save until the next launch.
  Future<void> start() async {
    _uid = await _backend.signIn();
    if (_uid == null) return;

    await restoreIfRemoteIsAhead();

    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(_flushInterval, (_) => flush());
  }

  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
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
    if (uid == null || _flushing) return false;
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
