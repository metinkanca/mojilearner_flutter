import 'package:flutter/foundation.dart';

import '../constants/progression.dart';
import '../models/models.dart';
import '../repositories/daily_reward_repository.dart';
import 'user_provider.dart';

/// Owns the daily-reward cycle: which reward is due, claiming it, and the
/// once-per-calendar-day bookkeeping. Depends on [UserProvider] for the
/// streak counter (shared with user stats) and for granting rewards.
///
/// Wire via ChangeNotifierProxyProvider so [updateDependencies] runs
/// whenever UserProvider changes; the pending reward resolves once both
/// providers have finished loading.
class DailyRewardProvider extends ChangeNotifier {
  DailyRewardProvider({DailyRewardRepository? repository})
      : _repository = repository ?? DailyRewardRepository() {
    loadFuture = _load();
  }

  final DailyRewardRepository _repository;
  late final Future<void> loadFuture;

  UserProvider? _userProvider;
  DateTime? _lastRewardClaimDate;
  DateTime? _lastLoginDate;
  DailyRewardInfo? _pendingDailyReward;
  bool _isLoaded = false;
  bool _pendingResolved = false;

  DailyRewardInfo? get pendingDailyReward => _pendingDailyReward;

  int get _streak => _userProvider?.streak ?? 0;

  int get dailyRewardClaimCount => _streak;

  int get completedRewardCycleDay {
    if (_streak == 0) {
      return 0;
    }
    final remainder = _streak % dailyRewards.length;
    return remainder == 0 ? dailyRewards.length : remainder;
  }

  int get nextRewardCycleDay {
    final nextClaimCount = _streak + 1;
    final remainder = nextClaimCount % dailyRewards.length;
    return remainder == 0 ? dailyRewards.length : remainder;
  }

  /// True when today's reward has not been claimed yet.
  bool get isRewardAvailableNow {
    final claimed = _lastRewardClaimDate;
    if (claimed == null) return true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return claimed.isBefore(today);
  }

  /// When the next reward becomes claimable, or null when one already is.
  ///
  /// Rewards reset on the local day boundary, so this is simply the next
  /// midnight. Exposed for reminder scheduling.
  DateTime? get nextRewardAvailableAt {
    if (isRewardAvailableNow) return null;

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1));
  }

  /// Called by the ProxyProvider whenever [UserProvider] notifies.
  void updateDependencies(UserProvider userProvider) {
    _userProvider = userProvider;
    _maybeResolvePending();
  }

  Future<void> _load() async {
    final data = await _repository.load();
    _lastRewardClaimDate = data.lastClaimDate;
    _lastLoginDate = data.lastLoginDate;
    _isLoaded = true;
    await _maybeResolvePending();
  }

  /// Resolves the startup pending reward once both this provider and
  /// UserProvider (for the streak) have loaded.
  Future<void> _maybeResolvePending() async {
    if (_pendingResolved) return;
    final user = _userProvider;
    if (user == null || user.isLoading || !_isLoaded) return;
    _pendingResolved = true;
    _pendingDailyReward = await checkDailyReward();
    notifyListeners();
  }

  void clearPendingReward() {
    _pendingDailyReward = null;
    notifyListeners();
  }

  /// Check if a daily reward is available.
  /// Rewards advance one step per claim, up to once per calendar day.
  /// Missing days does not reset progress.
  Future<DailyRewardInfo?> checkDailyReward() async {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    // Backward compatibility: if legacy data has reward date but no login
    // date, infer last login from the reward date.
    if (_lastLoginDate == null && _lastRewardClaimDate != null) {
      _lastLoginDate = _lastRewardClaimDate;
    }

    // First-ever launch: initialize login date and do not show reward yet.
    if (_lastLoginDate == null) {
      _lastLoginDate = today;
      await _repository.saveLastLoginDate(today);
      return null;
    }

    final lastLoginDay = DateTime(
      _lastLoginDate!.year,
      _lastLoginDate!.month,
      _lastLoginDate!.day,
    );

    final daysSinceLastLogin = today.difference(lastLoginDay).inDays;

    // Same-day login: do nothing.
    if (daysSinceLastLogin == 0) {
      return null;
    }

    if (_lastRewardClaimDate != null) {
      final lastRewardDay = DateTime(
        _lastRewardClaimDate!.year,
        _lastRewardClaimDate!.month,
        _lastRewardClaimDate!.day,
      );

      // Already claimed today.
      if (today == lastRewardDay) {
        return null;
      }
    }

    final streakReset = daysSinceLastLogin > 1;
    final nextClaimCount = streakReset ? 1 : _streak + 1;
    final rewardIndex = (nextClaimCount - 1) % dailyRewards.length;
    final reward = dailyRewards[rewardIndex];

    return DailyRewardInfo(
      dayNumber: rewardIndex + 1,
      reward: reward,
      streakReset: streakReset,
      currentStreak: nextClaimCount,
    );
  }

  /// Claim the daily reward.
  /// Grants coins/items, advances progress by one step, and locks claims
  /// for the day.
  Future<void> claimDailyReward() async {
    final user = _userProvider;
    if (user == null) return;

    final rewardInfo = await checkDailyReward();
    if (rewardInfo == null) return; // No reward available

    await user.grantReward(rewardInfo.reward);
    await user.setStreak(rewardInfo.currentStreak);

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    _lastRewardClaimDate = today;
    _lastLoginDate = today;
    await _repository.saveClaim(today);

    notifyListeners();
  }
}
