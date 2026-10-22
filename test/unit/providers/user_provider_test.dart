import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/gold.dart';
import 'package:mojilearner_flutter/constants/progression.dart';
import 'package:mojilearner_flutter/providers/user_provider.dart';
import 'package:mojilearner_flutter/utils/progression_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_fixtures.dart';

/// The level-1 reward, which UserProvider hands out on first load.
final int welcomeCoins = levelRewards
    .firstWhere((r) => r.level == ProgressionConstants.welcomeRewardLevel)
    .value;

/// Ten XP short of level 2, whatever the curve is tuned to.
final int justShyOfLevel2 = ProgressionUtils.getTotalXPForLevel(2) - 10;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserProvider - Initialization', () {
    test('should load persisted user data from SharedPreferences', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        ...TestFixtures.welcomeGiftAlreadyGiven,
        'username': 'TestUser',
        'coins': 500,
        'streak': 5,
        'total_xp': 250,
        'last_login_date': '2026-02-10',
        'last_reward_claim_date': '2026-02-09',
      });

      // Act
      final provider = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100)); // Wait for loading

      // Assert
      expect(provider.username, equals('TestUser'));
      expect(provider.coins, equals(500));
      expect(provider.rewardClaims, equals(5));
      // No `login_streak` in this save, which is what everyone playing before
      // the two counters were told apart looks like: the claim count is the
      // better of the two guesses, being days they did turn up.
      expect(provider.loginStreak, equals(5));
      expect(provider.stats.totalXP, equals(250));
      expect(provider.isLoading, isFalse);
    });

    test('should initialize with default values when no persisted data', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});

      // Act
      final provider = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert - a new player gets the starting float plus the welcome gift
      expect(provider.coins, equals(UserProvider.startingCoins + welcomeCoins));
      expect(provider.rewardClaims, equals(0));
      expect(provider.loginStreak, equals(0));
      expect(provider.stats.totalXP, equals(0));
      expect(provider.stats.level, equals(1));
    });

    test('retires the legacy 999999 testing-mode balance once', () async {
      // Arrange - a tester carrying the old "infinite gold" sentinel
      SharedPreferences.setMockInitialValues({
        ...TestFixtures.welcomeGiftAlreadyGiven,
        'coins': 999999,
      });

      // Act
      final provider = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(provider.coins, equals(UserProvider.startingCoins));
    });

    test('does not reset a balance the player legitimately earned', () async {
      // Arrange - migration already ran; 999999 is now a real balance
      SharedPreferences.setMockInitialValues({
        ...TestFixtures.welcomeGiftAlreadyGiven,
        'coins': 999999,
        'coins_testing_mode_migrated': true,
      });

      // Act
      final provider = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(provider.coins, equals(999999));
    });

    test('leaves ordinary balances untouched when migrating', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        ...TestFixtures.welcomeGiftAlreadyGiven,
        'coins': 120,
      });

      // Act
      final provider = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(provider.coins, equals(120));
    });

    test('should emit notification when loading completes', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final provider = UserProvider();
      bool notified = false;
      
      provider.addListener(() {
        if (!provider.isLoading) {
          notified = true;
        }
      });

      // Act
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(notified, isTrue);
    });
  });

  group('UserProvider - XP & Leveling', () {
    test('should increase totalXP when addXp is called', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'total_xp': 50});
      final provider = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      await provider.addXp(30);

      // Assert
      expect(provider.stats.totalXP, equals(80));
      
      // Verify persisted
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('total_xp'), equals(80));
    });

    test('should trigger level up when XP crosses threshold', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'total_xp': justShyOfLevel2});
      final provider = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.stats.level, equals(1));

      // Act
      await provider.addXp(20); // 10 past the threshold: level 2

      // Assert
      expect(provider.stats.totalXP, equals(justShyOfLevel2 + 20));
      expect(provider.stats.level, equals(2));
    });

    test('should emit event on onLevelUp stream when leveling up', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'total_xp': justShyOfLevel2});
      final provider = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      int? levelUpEvent;
      provider.onLevelUp.listen((level) {
        levelUpEvent = level;
      });

      // Act
      await provider.addXp(20);
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(levelUpEvent, equals(2));
    });

    test('should handle multiple level ups in single addXp call', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'total_xp': 0});
      final provider = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      final levelUps = <int>[];
      provider.onLevelUp.listen((level) {
        levelUps.add(level);
      });

      // Act
      await provider.addXp(1000); // Should trigger multiple level ups (level 3)
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(provider.stats.level, greaterThanOrEqualTo(3));
      expect(levelUps.isNotEmpty, isTrue);
    });

    test('should grant level-up rewards correctly', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'total_xp': justShyOfLevel2,
        'coins': 100,
      });
      final provider = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      final initialCoins = provider.coins;

      // Act
      await provider.addXp(20); // Level up to 2, should grant 150 coins
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(provider.coins, equals(initialCoins + 150));
    });

    test('pays every level crossed in one grant, not just the last', () async {
      // Arrange: level 1, about to jump straight to level 4.
      SharedPreferences.setMockInitialValues({
        ...TestFixtures.welcomeGiftAlreadyGiven,
        'total_xp': 0,
        'coins': 100,
      });
      final provider = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      final items = <int>[];
      provider.onReward.listen((reward) => items.add(reward.level));

      // Act
      await provider.addXp(ProgressionUtils.getTotalXPForLevel(4));
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert: level 2's and level 4's coins, and level 3's apples.
      int coinsAt(int level) =>
          levelRewards.firstWhere((r) => r.level == level).value;
      expect(provider.stats.level, equals(4));
      expect(provider.coins, equals(100 + coinsAt(2) + coinsAt(4)));
      expect(items, equals([3]));
    });
  });

  group('UserProvider - Coins', () {
    test('should increase coins when addCoins is called', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        ...TestFixtures.welcomeGiftAlreadyGiven,
        'coins': 100,
      });
      final provider = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      await provider.addCoins(50);

      // Assert
      expect(provider.coins, equals(150));
      
      // Verify persisted
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('coins'), equals(150));
    });

    test('should decrease coins when spendCoins called with sufficient balance', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        ...TestFixtures.welcomeGiftAlreadyGiven,
        'coins': 100,
      });
      final provider = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      await provider.spendCoins(30);

      // Assert
      expect(provider.coins, equals(70));
      
      // Try to spend more than available
      await provider.spendCoins(200);
      expect(provider.coins, equals(70)); // Should not change
    });
  });

  group('UserProvider - the welcome gift', () {
    Future<UserProvider> load() async {
      final provider = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      return provider;
    }

    test('is granted on first load, since a level-up never can', () async {
      // Level-up rewards fire when the level changes, and everyone starts at
      // level 1 — so without this the level-1 entry is shown on the rewards
      // screen and never paid.
      SharedPreferences.setMockInitialValues({'coins': 0});

      final provider = await load();

      expect(provider.coins, equals(welcomeCoins));
    });

    test('is granted to an existing player who never received it', () async {
      SharedPreferences.setMockInitialValues({'coins': 400, 'total_xp': 5000});

      final provider = await load();

      expect(provider.coins, equals(400 + welcomeCoins));
    });

    test('is never granted twice, across restarts', () async {
      SharedPreferences.setMockInitialValues({'coins': 0});
      await load();

      // A second launch reads the flag the first one persisted.
      final relaunched = await load();

      expect(relaunched.coins, equals(welcomeCoins));
    });
  });

  group('UserProvider - learning gold', () {
    Future<UserProvider> load({int coins = 0}) async {
      SharedPreferences.setMockInitialValues({
        ...TestFixtures.welcomeGiftAlreadyGiven,
        'coins': coins,
      });
      final provider = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      return provider;
    }

    test('pays in full inside the first band', () async {
      final provider = await load();

      final award = await provider.awardLearningGold(16, GoldSource.quiz);

      expect(award.paid, equals(16));
      expect(award.wasReduced, isFalse);
      expect(provider.coins, equals(16));
    });

    test('tapers once the day\'s full-rate band is used up', () async {
      final provider = await load();

      // Fill the full-rate band exactly.
      await provider.awardLearningGold(
        GoldConstants.fullRateDailyGold,
        GoldSource.quiz,
      );
      expect(provider.learningGoldEarnedToday,
          equals(GoldConstants.fullRateDailyGold));

      final tapered = await provider.awardLearningGold(20, GoldSource.quiz);

      expect(tapered.paid, equals(10)); // half rate
      expect(tapered.wasReduced, isTrue);
    });

    test('splits a payout that straddles a band boundary', () async {
      final provider = await load();

      await provider.awardLearningGold(
        GoldConstants.fullRateDailyGold - 10,
        GoldSource.quiz,
      );

      // 10 at full rate, then 10 at half.
      final straddling = await provider.awardLearningGold(20, GoldSource.quiz);

      expect(straddling.paid, equals(15));
    });

    test('caps a capped source without spending the taper bands', () async {
      final provider = await load();
      const cap = GoldConstants.conversationDailyCap;

      for (var i = 0; i < cap; i++) {
        await provider.awardLearningGold(
          GoldConstants.conversation,
          GoldSource.conversation,
        );
      }
      expect(provider.learningGoldRemainingFor(GoldSource.conversation),
          equals(0));

      final overCap = await provider.awardLearningGold(
        GoldConstants.conversation,
        GoldSource.conversation,
      );

      expect(overCap.paid, equals(0));
      // The refused message must not have advanced the day's taper either.
      expect(provider.learningGoldEarnedToday, equals(cap));
    });

    test('one source running out does not cap another', () async {
      final provider = await load();

      for (var i = 0; i < GoldConstants.conversationDailyCap + 5; i++) {
        await provider.awardLearningGold(
          GoldConstants.conversation,
          GoldSource.conversation,
        );
      }

      final quiz = await provider.awardLearningGold(16, GoldSource.quiz);

      expect(quiz.paid, equals(16));
    });

    test('a restart cannot be used to reset the day', () async {
      final provider = await load();
      await provider.awardLearningGold(
        GoldConstants.fullRateDailyGold,
        GoldSource.quiz,
      );

      // Relaunch against the same persisted prefs.
      final relaunched = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(relaunched.learningGoldEarnedToday,
          equals(GoldConstants.fullRateDailyGold));
      final award = await relaunched.awardLearningGold(20, GoldSource.quiz);
      expect(award.paid, equals(10));
    });

    test('grants that are not earned by playing skip the taper', () async {
      final provider = await load();
      await provider.awardLearningGold(
        GoldConstants.halfRateDailyGold,
        GoldSource.quiz,
      );
      final before = provider.coins;

      // The daily login cycle and level-up rewards come through addCoins:
      // they are bounded by their own schedule, not by the taper.
      await provider.addCoins(100);

      expect(provider.coins, equals(before + 100));
    });
  });
}
