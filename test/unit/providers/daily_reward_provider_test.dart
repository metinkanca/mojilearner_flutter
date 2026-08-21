import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/providers/daily_reward_provider.dart';
import 'package:mojilearner_flutter/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Builds a DailyRewardProvider wired to a freshly-loaded UserProvider,
  /// the same way the ProxyProvider does in main.dart.
  Future<DailyRewardProvider> buildProvider() async {
    final userProvider = UserProvider();
    await Future.delayed(const Duration(milliseconds: 100));
    final provider = DailyRewardProvider()..updateDependencies(userProvider);
    await provider.loadFuture;
    return provider;
  }

  group('DailyRewardProvider', () {
    test('should return null on first-ever app launch', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = await buildProvider();

      final reward = await provider.checkDailyReward();

      expect(reward, isNull);

      // Verify lastLoginDate was set
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_login_date'), isNotNull);
    });

    test('should return null if already claimed today', () async {
      final today = DateTime.now();
      final todayStr =
          DateTime(today.year, today.month, today.day).toIso8601String();

      SharedPreferences.setMockInitialValues({
        'last_reward_claim_date': todayStr,
        'streak': 3,
      });
      final provider = await buildProvider();

      final reward = await provider.checkDailyReward();

      expect(reward, isNull);
    });

    test('should return reward with streak increment on consecutive day',
        () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayStr =
          DateTime(yesterday.year, yesterday.month, yesterday.day)
              .toIso8601String();

      SharedPreferences.setMockInitialValues({
        'last_reward_claim_date': yesterdayStr,
        'streak': 3,
      });
      final provider = await buildProvider();

      final reward = await provider.checkDailyReward();

      expect(reward, isNotNull);
      expect(reward!.currentStreak, equals(4));
      expect(reward.streakReset, isFalse);
    });

    test('should reset streak to 1 when day is missed', () async {
      final today = DateTime.now();
      final threeDaysAgo = today.subtract(const Duration(days: 3));
      final threeDaysAgoStr =
          DateTime(threeDaysAgo.year, threeDaysAgo.month, threeDaysAgo.day)
              .toIso8601String();

      SharedPreferences.setMockInitialValues({
        'last_reward_claim_date': threeDaysAgoStr,
        'streak': 5,
      });
      final provider = await buildProvider();

      final reward = await provider.checkDailyReward();

      expect(reward, isNotNull);
      expect(reward!.currentStreak, equals(1));
      expect(reward.streakReset, isTrue);
    });

    test('should grant coins and update dates when claimDailyReward called',
        () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayStr =
          DateTime(yesterday.year, yesterday.month, yesterday.day)
              .toIso8601String();

      // Use streak 0 so next reward is streak 1 (day 1 = 50 coins)
      SharedPreferences.setMockInitialValues({
        'last_reward_claim_date': yesterdayStr,
        'streak': 0,
        'coins': 100,
      });
      final userProvider = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      final provider = DailyRewardProvider()
        ..updateDependencies(userProvider);
      await provider.loadFuture;
      final initialCoins = userProvider.coins;

      await provider.claimDailyReward();
      await Future.delayed(const Duration(milliseconds: 50));

      // Day 1 reward gives 50 coins; streak advanced on UserProvider.
      expect(userProvider.coins, equals(initialCoins + 50));
      expect(userProvider.streak, equals(1));
      expect(provider.dailyRewardClaimCount, equals(1));

      // Verify dates updated
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_reward_claim_date'), isNotNull);
    });

    test('cycle getters reflect the streak from UserProvider', () async {
      SharedPreferences.setMockInitialValues({'streak': 3});
      final provider = await buildProvider();

      expect(provider.dailyRewardClaimCount, equals(3));
      expect(provider.completedRewardCycleDay, equals(3));
      expect(provider.nextRewardCycleDay, equals(4));
    });
  });
}
