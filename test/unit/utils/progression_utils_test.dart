import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/progression.dart';
import 'package:mojilearner_flutter/utils/progression_utils.dart';

/// The curve these tests are checking against, restated independently of the
/// implementation but derived from the same constants — so retuning
/// [ProgressionConstants.growthRate] does not mean rewriting every number
/// here, while a bug in the implementation still shows up.
int expectedXpForLevel(int level) =>
    (ProgressionConstants.baseXP * pow(level, ProgressionConstants.growthRate))
        .round();

void main() {
  group('ProgressionUtils', () {
    group('getXPRequiredForNextLevel', () {
      test('should calculate XP required for level 1 to 2', () {
        // Act
        final xp = ProgressionUtils.getXPRequiredForNextLevel(1);
        
        // Assert
        expect(xp, equals(100));
      });

      test('should calculate XP required using exponential formula', () {
        // Act & Assert
        // Formula: baseXP * level^growthRate
        expect(ProgressionUtils.getXPRequiredForNextLevel(2),
            equals(expectedXpForLevel(2)));
        expect(ProgressionUtils.getXPRequiredForNextLevel(5),
            equals(expectedXpForLevel(5)));
      });

      test('gets steeper with every level', () {
        for (var level = 1; level < ProgressionConstants.maxLevel - 1; level++) {
          expect(
            ProgressionUtils.getXPRequiredForNextLevel(level + 1),
            greaterThan(ProgressionUtils.getXPRequiredForNextLevel(level)),
          );
        }
      });

      test('keeps level 20 inside a committed year of study', () {
        // The curve was 1.8, which put the cap at 146,115 XP — about 1.4
        // years at ~290 XP/day, so most of `levelRewards` was unreachable
        // decoration. Guard that the ladder stays finishable.
        final toMaxLevel =
            ProgressionUtils.getTotalXPForLevel(ProgressionConstants.maxLevel);

        expect(toMaxLevel, lessThan(290 * 365));
      });

      test('should return 0 XP required when at max level', () {
        // Act
        final xp = ProgressionUtils.getXPRequiredForNextLevel(20);
        
        // Assert
        expect(xp, equals(0));
      });
    });

    group('getTotalXPForLevel', () {
      test('should return 0 XP for level 1', () {
        // Act
        final xp = ProgressionUtils.getTotalXPForLevel(1);
        
        // Assert
        expect(xp, equals(0));
      });

      test('should calculate cumulative XP by summing level requirements', () {
        // Act & Assert
        // Level 2 requires 100 XP from level 1
        expect(ProgressionUtils.getTotalXPForLevel(2), equals(100));
        // Level 3 requires level 1's 100 plus level 2's step
        expect(ProgressionUtils.getTotalXPForLevel(3),
            equals(100 + expectedXpForLevel(2)));
      });
    });

    group('getLevelFromTotalXP', () {
      test('should return level 1 for 0 XP', () {
        // Act
        final level = ProgressionUtils.getLevelFromTotalXP(0);
        
        // Assert
        expect(level, equals(1));
      });

      test('should return correct level from total XP', () {
        // Act & Assert
        expect(ProgressionUtils.getLevelFromTotalXP(100), equals(2));
        expect(ProgressionUtils.getLevelFromTotalXP(250), equals(2)); // Still level 2
        expect(ProgressionUtils.getLevelFromTotalXP(500), equals(3));
      });

      test('should cap level at max level', () {
        // Act
        final level = ProgressionUtils.getLevelFromTotalXP(999999);
        
        // Assert
        expect(level, equals(20));
      });

      test('should handle negative XP as level 1', () {
        // Act
        final level = ProgressionUtils.getLevelFromTotalXP(-5);
        
        // Assert
        expect(level, equals(1));
      });
    });

    group('getLevelProgress', () {
      test('should return 0.0 progress at level start', () {
        // Arrange: Level 2 starts at 100 XP
        const xp = 100;
        
        // Act
        final progress = ProgressionUtils.getLevelProgress(xp);
        
        // Assert
        expect(progress, equals(0.0));
      });

      test('should return approximately 0.5 progress at level midpoint', () {
        // Arrange: halfway through the level-2 step
        final midpoint = 100 + (expectedXpForLevel(2) ~/ 2);
        
        // Act
        final progress = ProgressionUtils.getLevelProgress(midpoint);
        
        // Assert
        expect(progress, closeTo(0.5, 0.05));
      });

      test('should return 1.0 at max level', () {
        // Act
        final progress = ProgressionUtils.getLevelProgress(999999);
        
        // Assert
        expect(progress, equals(1.0));
      });
    });

    group('getXPToNextLevel', () {
      test('should calculate XP remaining to next level', () {
        // Arrange: partway through level 2
        const currentXP = 150;

        // Act
        final remaining = ProgressionUtils.getXPToNextLevel(currentXP);

        // Assert
        expect(remaining, equals(100 + expectedXpForLevel(2) - currentXP));
      });

      test('should return 0 at max level', () {
        // Act
        final remaining = ProgressionUtils.getXPToNextLevel(999999);

        // Assert
        expect(remaining, equals(0));
      });
    });

    group('getQuizRewardOutcome - coin economy', () {
      int coinsFor(int correct) => ProgressionUtils.getQuizRewardOutcome(
            correctAnswers: correct,
            totalQuestions: 5,
          ).coinReward;

      test('coins scale with accuracy', () {
        expect(coinsFor(0), equals(6));
        expect(coinsFor(1), equals(10));
        expect(coinsFor(2), equals(12));
        expect(coinsFor(3), equals(14));
        expect(coinsFor(4), equals(15));
        expect(coinsFor(5), equals(16));
      });

      test('a slower learner is not priced out of the shop', () {
        // Accuracy is not a choice, and the player who most needs to stay is
        // the one finding it hard. XP is where doing well shows; coins must
        // stay close enough that a struggling learner still affords things.
        // The gap used to be 3.3x on a 40%-vs-100% run.
        expect(coinsFor(2) / coinsFor(5), greaterThan(0.6));
        expect(coinsFor(0) / coinsFor(5), greaterThan(0.3));
      });

      test('doing well is still worth more, and XP is where it shows', () {
        expect(coinsFor(5), greaterThan(coinsFor(0)));

        int xpFor(int correct) => ProgressionUtils.getQuizRewardOutcome(
              correctAnswers: correct,
              totalQuestions: 5,
            ).xpReward;
        expect(xpFor(5) / xpFor(0), greaterThanOrEqualTo(5.0));
      });

      test('coins never decrease as accuracy rises', () {
        var previous = -1;
        for (var correct = 0; correct <= 5; correct++) {
          final coins = ProgressionUtils.getQuizRewardOutcome(
            correctAnswers: correct,
            totalQuestions: 5,
          ).coinReward;
          expect(coins, greaterThanOrEqualTo(previous));
          previous = coins;
        }
      });

      test('every outcome pays something, so a bad quiz is never wasted', () {
        for (var correct = 0; correct <= 5; correct++) {
          final reward = ProgressionUtils.getQuizRewardOutcome(
            correctAnswers: correct,
            totalQuestions: 5,
          );
          expect(reward.coinReward, greaterThan(0));
          expect(reward.xpReward, greaterThan(0));
        }
      });

      test('a degenerate quiz still returns the floor reward', () {
        final reward = ProgressionUtils.getQuizRewardOutcome(
          correctAnswers: 0,
          totalQuestions: 0,
        );

        expect(reward.coinReward, equals(6));
        expect(reward.xpReward, equals(10));
      });

      test('a quiz is worth more than a day of the login cycle', () {
        // The daily cycle used to pay 375 coins a week — more than half of an
        // average player's income, and 84% of a light one's, which made
        // opening the app the best-paid thing in the game. It now feeds the
        // pet instead (see `dailyRewards`). Guard the ordering that fixed:
        // sitting one quiz must beat showing up for one day.
        final perQuiz = ProgressionUtils.getQuizRewardOutcome(
          correctAnswers: 4,
          totalQuestions: 5,
        ).coinReward;

        final weeklyLoginCoins = dailyRewards
            .where((r) => r.type == RewardType.coins)
            .fold(0, (sum, r) => sum + r.value);

        expect(perQuiz, greaterThan(weeklyLoginCoins / dailyRewards.length));
      });
    });
  });
}
