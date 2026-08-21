import 'package:shared_preferences/shared_preferences.dart';

import '../utils/secure_storage.dart';

/// Everything worth carrying to a new device, as one plain map.
///
/// Deliberately reads storage rather than the providers. Eleven providers own
/// their own persistence, and asking each of them to expose a serialiser
/// would be eleven chances to forget one — and a twelfth provider added later
/// would silently not sync. Storage is the one place all of it already meets.
///
/// The rule is **sync by default**: everything in SharedPreferences goes,
/// except the handful of keys named in [_localOnlyPrefs]. A new feature's
/// state is carried without anyone remembering to add it, and the failure
/// mode of forgetting to *exclude* something is a slightly larger document
/// rather than a player losing progress.
class LocalSnapshot {
  const LocalSnapshot._();

  /// Keys that stay on the device.
  ///
  /// Two kinds: state that is meaningless elsewhere (a half-finished quiz, a
  /// cached question set) and one-shot migration flags, which describe what
  /// has been done to *this* install's storage and would, if restored onto a
  /// fresh device, claim a migration that never ran there.
  static const Set<String> _localOnlyPrefs = {
    'chats',
    'chat_migration_complete',
    'coins_testing_mode_migrated',
    'quiz_cached_set',
    'quiz_saved_index',
    'quiz_saved_score',
    ...syncBookkeepingPrefs,
  };

  /// `CloudSync`'s own bookkeeping, and the most important entries in this
  /// file.
  ///
  /// Both change as a *result* of uploading. If the snapshot included them,
  /// every upload would alter the next snapshot, so its hash would never
  /// match, so it would upload again — a write loop with no upper bound,
  /// running for as long as the app is open, on every install. That is the
  /// shape of the Firestore bills people write blog posts about.
  static const Set<String> syncBookkeepingPrefs = {
    'sync_last_hash',
    'sync_revision',
  };

  /// The encrypted blobs worth carrying.
  ///
  /// An allowlist rather than a denylist, unlike the prefs above, because the
  /// thing being excluded is chat history — `chat_<id>` and `all_chats` — and
  /// that is both the bulk of the bytes and the least valuable to restore. A
  /// new secure key defaulting to "not synced" is the safer mistake here.
  static const Set<String> _syncedSecureKeys = {
    'mistakes',
    'review_items',
    'scenario_progress',
  };

  /// Secure keys carried by prefix: per-language calibration and assessment.
  static const List<String> _syncedSecurePrefixes = ['assessment_'];

  /// Reads current local state into a map suitable for one document.
  static Future<Map<String, dynamic>> capture() async {
    final prefs = await SharedPreferences.getInstance();

    final prefsData = <String, dynamic>{};
    for (final key in prefs.getKeys()) {
      if (_localOnlyPrefs.contains(key)) continue;
      final value = prefs.get(key);
      if (value == null) continue;
      // Firestore has no List<String>; normalise so a round trip returns the
      // same shape the providers stored.
      prefsData[key] = value is List<String> ? {'_list': value} : value;
    }

    final secureData = <String, dynamic>{};
    for (final key in await SecureStorage.getAllKeys()) {
      if (!_isSyncedSecureKey(key)) continue;
      final raw = await SecureStorage.readString(key);
      if (raw != null) secureData[key] = raw;
    }

    return {'prefs': prefsData, 'secure': secureData};
  }

  /// Writes a captured map back over local storage.
  ///
  /// Additive: keys absent from [data] are left alone rather than cleared, so
  /// a restore can never be the thing that deletes local progress. The
  /// decision about *whether* to restore belongs to the caller — see
  /// `CloudSync.restoreIfRemoteIsAhead`.
  static Future<void> restore(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    final prefsData = data['prefs'];
    if (prefsData is Map) {
      for (final entry in prefsData.entries) {
        final key = entry.key as String;
        if (_localOnlyPrefs.contains(key)) continue;
        await _writePref(prefs, key, entry.value);
      }
    }

    final secureData = data['secure'];
    if (secureData is Map) {
      for (final entry in secureData.entries) {
        final key = entry.key as String;
        if (!_isSyncedSecureKey(key)) continue;
        final value = entry.value;
        if (value is String) await SecureStorage.saveString(key, value);
      }
    }
  }

  static bool _isSyncedSecureKey(String key) {
    if (_syncedSecureKeys.contains(key)) return true;
    return _syncedSecurePrefixes.any(key.startsWith);
  }

  static Future<void> _writePref(
    SharedPreferences prefs,
    String key,
    dynamic value,
  ) async {
    if (value is Map && value['_list'] is List) {
      await prefs.setStringList(
        key,
        (value['_list'] as List).map((e) => e.toString()).toList(),
      );
      return;
    }
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is num) {
      // Firestore hands ints back as int, but a value that round-tripped
      // through JSON somewhere else could arrive as num. Anything past this
      // is a shape the app never wrote, and is safer skipped than coerced.
      await prefs.setInt(key, value.toInt());
    }
  }
}
