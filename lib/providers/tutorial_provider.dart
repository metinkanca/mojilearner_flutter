import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/tutorials.dart';

/// Remembers which per-page tours have already been offered.
///
/// The flag is set when the offer is *answered*, not when a tour is finished:
/// the question has been asked, and asking it again every launch until the
/// player sits through the whole thing is how a tutorial becomes nagging.
///
/// Follows the same shape as [SettingsProvider] — eager load at startup,
/// in-memory update first so the UI never waits on disk, then persist.
class TutorialProvider with ChangeNotifier {
  final Set<TutorialId> _seen = <TutorialId>{};

  bool _isLoaded = false;

  /// False until [load] has run. Callers must not act on [hasSeen] before
  /// this flips, or a slow disk read shows a tour the player already skipped.
  bool get isLoaded => _isLoaded;

  bool hasSeen(TutorialId id) => _seen.contains(id);

  Future<void> load() async {
    if (_isLoaded) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      for (final id in TutorialId.values) {
        if (prefs.getBool(id.prefsKey) ?? false) _seen.add(id);
      }
    } catch (e) {
      debugPrint('⚠️ TUTORIAL: Failed to load - $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> markSeen(TutorialId id) async {
    if (!_seen.add(id)) return;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(id.prefsKey, true);
    } catch (e) {
      debugPrint('⚠️ TUTORIAL: Failed to save ${id.prefsKey} - $e');
    }
  }

  /// Puts every tour back on offer. Behind the settings dialog, for the
  /// player who tapped SKIP by reflex on the first screen they ever saw.
  Future<void> resetAll() async {
    if (_seen.isEmpty) return;
    _seen.clear();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      for (final id in TutorialId.values) {
        await prefs.remove(id.prefsKey);
      }
    } catch (e) {
      debugPrint('⚠️ TUTORIAL: Failed to reset - $e');
    }
  }
}
