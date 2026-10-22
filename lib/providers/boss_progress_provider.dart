import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/boss_rewards.dart';
import '../constants/progression.dart';
import 'user_provider.dart';

/// Which boss levels have been cleared, so each pays once.
///
/// Held in SharedPreferences under [_key]. `LocalSnapshot` syncs every key by
/// default, so a restored player keeps their clears and cannot collect them a
/// second time on a new phone.
class BossProgressProvider extends ChangeNotifier {
  static const String _key = 'boss_cleared';

  final Set<String> _cleared = {};
  bool _loaded = false;
  Future<void> _saving = Future.value();

  /// Completes when the last clear has been written. For tests; the app does
  /// not wait on it, since a payout should not sit behind a disk write.
  @visibleForTesting
  Future<void> get saved => _saving;

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, _cleared.toList());
    } catch (e) {
      debugPrint('BOSS PROGRESS: could not save clears - $e');
    }
  }

  bool get isLoaded => _loaded;

  /// How many levels have been cleared, of the 30.
  int get clearedCount => _cleared.length;

  static String idFor(String bossId, int step) => '$bossId:$step';

  bool isCleared(String bossId, int step) =>
      _cleared.contains(idFor(bossId, step));

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _cleared
      ..clear()
      ..addAll(prefs.getStringList(_key) ?? const []);
    _loaded = true;
    notifyListeners();
  }

  /// Records a clear and pays it out if it is the first.
  ///
  /// Returns what was paid, which is empty for a level cleared before. Marked
  /// cleared *before* the payout is awaited, so two calls racing (a fight that
  /// ends twice) cannot both pay. The write to disk follows the payout rather
  /// than leading it: a crash in between would let one level pay twice, and
  /// that is a smaller harm than a results screen that waits on storage.
  Future<List<RewardDef>> recordClear({
    required String bossId,
    required int step,
    required int level,
    required bool finale,
    required UserProvider user,
  }) async {
    if (!_cleared.add(idFor(bossId, step))) return const [];
    final rewards = BossRewards.firstClear(
      level: level,
      step: step,
      finale: finale,
    );
    notifyListeners();
    for (final reward in rewards) {
      await user.grantReward(reward);
    }
    _saving = _persist();
    return rewards;
  }
}
