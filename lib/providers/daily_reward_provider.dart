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

  int get _claims => _userProvider?.rewardClaims ?? 0;

  int get _loginStreak => _userProvider?.loginStreak ?? 0;

  int get dailyRewardClaimCount => _claims;

  /// Days claimed in a row. Shown, and nothing else — see
  /// [UserProvider.loginStreak].
  int get loginStreak => _loginStreak;

  int get completedRewardCycleDay {
    if (_claims == 0) {
      return 0;
    }
    final remainder = _claims % dailyRewards.length;
    return remainder == 0 ? dailyRewards.length : remainder;
  }

  int get nextRewardCycleDay {
    final nextClaimCount = _claims + 1;
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
  ///
  /// Rewards advance one step per claim, at most once per calendar day, and
  /// **a missed day costs nothing**. Someone who claims on Monday and next
  /// opens the app a fortnight later picks up at the step after Monday's.
  ///
  /// The alternative — sending a broken run back to day one — was in here for
  /// a while, and it did far more damage than it looked like it did, because
  /// the cycle is not flat. `dailyRewards` is food, and it is back-loaded:
  /// 260 of the week's 300 hunger points sit on days 4, 6 and 7, against a pet
  /// that burns 336 a week. A player resetting every other day therefore
  /// claimed day one's 12 coins forever and *never ate* — and then paid for
  /// the shortfall twice, because a hungry pet gets sick and a sick pet halves
  /// coin income (`CharacterProvider.sickRewardMultiplier`). Missing a Tuesday
  /// compounded into an economy that never recovered.
  ///
  /// So the cycle is a queue of seven rewards to work through, not a test to
  /// fail. `BOND.md` takes the same position on absence, and `PetWarmth` is
  /// the shape of it: being away costs nothing but the pet saying it noticed.
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

    // A missed day costs the cycle nothing: the next claim is the next step,
    // whether the last one was yesterday or last month. See this method's own
    // note for why.
    final nextClaimCount = _claims + 1;
    final rewardIndex = (nextClaimCount - 1) % dailyRewards.length;
    final reward = dailyRewards[rewardIndex];

    // The run of days *is* broken by a gap — that is what a run means, and
    // the player is shown it. It buys nothing and costs nothing, which is the
    // only reason it is safe to let it break.
    final nextLoginStreak = daysSinceLastLogin == 1 ? _loginStreak + 1 : 1;

    return DailyRewardInfo(
      dayNumber: rewardIndex + 1,
      reward: reward,
      claimCount: nextClaimCount,
      loginStreak: nextLoginStreak,
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
    await user.setRewardProgress(
      claims: rewardInfo.claimCount,
      loginStreak: rewardInfo.loginStreak,
    );

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    _lastRewardClaimDate = today;
    _lastLoginDate = today;
    await _repository.saveClaim(today);

    notifyListeners();
  }
}
