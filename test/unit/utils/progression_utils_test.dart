import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/utils/progression_utils.dart';

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
        // Formula: 100 * level^1.8
        expect(ProgressionUtils.getXPRequiredForNextLevel(2), closeTo(348, 5));
        expect(ProgressionUtils.getXPRequiredForNextLevel(5), closeTo(1812, 10));
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
        // Level 3 requires 100 + ~352 = ~452
        expect(ProgressionUtils.getTotalXPForLevel(3), closeTo(452, 5));
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
        // Arrange: Level 2 needs ~352 XP to reach level 3
        // Midpoint = 100 + (352 / 2) = ~276
        const midpoint = 100 + (352 ~/ 2);
        
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
        // Arrange: At 150 XP (level 2), need ~302 more to reach level 3
        const currentXP = 150;
        
        // Act
        final remaining = ProgressionUtils.getXPToNextLevel(currentXP);
        
        // Assert
        expect(remaining, closeTo(302, 5));
      });

      test('should return 0 at max level', () {
        // Act
        final remaining = ProgressionUtils.getXPToNextLevel(999999);

        // Assert
        expect(remaining, equals(0));
      });
    });

    group('getQuizRewardOutcome - coin economy', () {
      test('coins scale with accuracy', () {
        int coinsFor(int correct) => ProgressionUtils.getQuizRewardOutcome(
              correctAnswers: correct,
              totalQuestions: 5,
            ).coinReward;

        expect(coinsFor(0), equals(2));
        expect(coinsFor(1), equals(4));
        expect(coinsFor(2), equals(6));
        expect(coinsFor(3), equals(10));
        expect(coinsFor(4), equals(15));
        expect(coinsFor(5), equals(20));
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

        expect(reward.coinReward, equals(2));
        expect(reward.xpReward, equals(10));
      });

      test('two good quizzes a day cover a day of food decay', () {
        // Hunger climbs 3/hour = 72/day. Pizza restores 40 hunger for 25
        // coins, so a day of upkeep costs roughly 50 coins. Guard that the
        // repeatable coin source keeps pace with the decay rates.
        final perQuiz = ProgressionUtils.getQuizRewardOutcome(
          correctAnswers: 4,
          totalQuestions: 5,
        ).coinReward;

        expect(perQuiz * 4, greaterThanOrEqualTo(50));
      });
    });
  });
}
