import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/progression.dart';
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
      expect(reward!.claimCount, equals(4));
      expect(reward.loginStreak, equals(4));
    });

    /// The cycle is a queue of seven rewards to work through, not a test to
    /// fail.
    ///
    /// Sending a broken run back to day one looked like a small punishment
    /// and was not: `dailyRewards` is the pet's food and it is back-loaded,
    /// so a player who reset often claimed day one's 12 coins forever and
    /// never ate — then paid again, because a hungry pet gets sick and a sick
    /// pet earns half. These pin that it cannot come back by accident.
    group('a missed day costs the cycle nothing', () {
      /// A player who last claimed [days] ago, five rewards in.
      Future<DailyRewardProvider> lastClaimed(int days) async {
        final then = DateTime.now().subtract(Duration(days: days));
        SharedPreferences.setMockInitialValues({
          'last_reward_claim_date':
              DateTime(then.year, then.month, then.day).toIso8601String(),
          'streak': 5,
        });
        return buildProvider();
      }

      test('one missed day picks up where it left off', () async {
        final reward = await (await lastClaimed(2)).checkDailyReward();

        expect(reward!.claimCount, 6);
        expect(reward.dayNumber, 6);
      });

      test('so does a fortnight away', () async {
        final reward = await (await lastClaimed(14)).checkDailyReward();

        expect(reward!.claimCount, 6);
        expect(reward.dayNumber, 6);
      });

      // The week's two biggest food drops are days 6 and 7, which is exactly
      // what a reset used to take away from the players who most needed them.
      test('the back-loaded end of the week stays reachable', () async {
        final reward = await (await lastClaimed(30)).checkDailyReward();

        expect(reward!.reward.itemId, 'sushi');
      });

      test('a consecutive day is still worth exactly one step', () async {
        final reward = await (await lastClaimed(1)).checkDailyReward();

        expect(reward!.claimCount, 6);
      });
    });

    /// The run of days, which is shown and does nothing else.
    ///
    /// It is the one counter here a gap still breaks — safely, because no
    /// reward reads it. The tests above are the other half of the same claim:
    /// what the player loses by missing a day is the number, not the sushi.
    group('the run of days', () {
      /// A player [days] since their last claim, mid-run and mid-cycle.
      Future<DailyRewardProvider> lastClaimed(int days) async {
        final then = DateTime.now().subtract(Duration(days: days));
        SharedPreferences.setMockInitialValues({
          'last_reward_claim_date':
              DateTime(then.year, then.month, then.day).toIso8601String(),
          'streak': 12,
          'login_streak': 9,
        });
        return buildProvider();
      }

      test('grows by one for a day claimed back to back', () async {
        final reward = await (await lastClaimed(1)).checkDailyReward();

        expect(reward!.loginStreak, 10);
      });

      test('starts again at one after a missed day', () async {
        final reward = await (await lastClaimed(2)).checkDailyReward();

        expect(reward!.loginStreak, 1);
      });

      // The whole point of separating the two counters.
      test('breaking it leaves the reward cycle exactly where it was',
          () async {
        final reward = await (await lastClaimed(30)).checkDailyReward();

        expect(reward!.loginStreak, 1);
        expect(reward.claimCount, 13);
        expect(reward.dayNumber, 6);
      });

      test('claiming persists both counters', () async {
        final provider = await lastClaimed(1);
        await provider.claimDailyReward();

        expect(provider.loginStreak, 10);
        expect(provider.dailyRewardClaimCount, 13);
      });
    });

    test('should grant coins and update dates when claimDailyReward called',
        () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayStr =
          DateTime(yesterday.year, yesterday.month, yesterday.day)
              .toIso8601String();

      // Use streak 0 so next reward is streak 1, the cycle's coin day
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

      // Day 1 pays coins; both counters advanced on UserProvider. Read the
      // amount from the schedule rather than restating it, so retuning the
      // cycle does not mean editing this assertion.
      expect(
        userProvider.coins,
        equals(initialCoins + dailyRewards.first.value),
      );
      expect(userProvider.rewardClaims, equals(1));
      expect(userProvider.loginStreak, equals(1));
      expect(provider.dailyRewardClaimCount, equals(1));

      // Verify dates updated
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_reward_claim_date'), isNotNull);
    });

    test('cycle getters reflect the claim count from UserProvider', () async {
      SharedPreferences.setMockInitialValues({'streak': 3});
      final provider = await buildProvider();

      expect(provider.dailyRewardClaimCount, equals(3));
      expect(provider.completedRewardCycleDay, equals(3));
      expect(provider.nextRewardCycleDay, equals(4));
    });
  });
}
