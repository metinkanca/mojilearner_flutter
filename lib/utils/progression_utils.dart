import 'dart:math';
import '../constants/progression.dart';

class QuizRewardOutcome {
  final int xpReward;
  final int happinessDelta;
  final int hungerDelta;
  final String level;
  final bool passed;

  const QuizRewardOutcome({
    required this.xpReward,
    required this.happinessDelta,
    required this.hungerDelta,
    required this.level,
    required this.passed,
  });
}

class ProgressionUtils {
  /// Calculates the XP required to grow from [level] to [level + 1]
  static int getXPRequiredForNextLevel(int level) {
    if (level >= ProgressionConstants.maxLevel) return 0;
    return (ProgressionConstants.baseXP * pow(level, ProgressionConstants.growthRate)).round();
  }

  /// Calculates the total cumulative XP required to reach a specific [level]
  static int getTotalXPForLevel(int level) {
    int total = 0;
    for (int i = 1; i < level; i++) {
      total += getXPRequiredForNextLevel(i);
    }
    return total;
  }

  /// Evaluates current level based on [totalXP]
  static int getLevelFromTotalXP(int totalXP) {
    int level = 1;
    while (level < ProgressionConstants.maxLevel) {
      int nextLevelXP = getTotalXPForLevel(level + 1);
      if (totalXP < nextLevelXP) break;
      level++;
    }
    return level;
  }

  /// Calculates progress (0.0 to 1.0) through the current level
  static double getLevelProgress(int totalXP) {
    int currentLevel = getLevelFromTotalXP(totalXP);
    if (currentLevel >= ProgressionConstants.maxLevel) return 1.0;

    int xpAtStartOfLevel = getTotalXPForLevel(currentLevel);
    int xpAtEndOfLevel = getTotalXPForLevel(currentLevel + 1);
    
    int xpInCurrentLevel = totalXP - xpAtStartOfLevel;
    int totalRequiredInLevel = xpAtEndOfLevel - xpAtStartOfLevel;
    
    return (xpInCurrentLevel / totalRequiredInLevel).clamp(0.0, 1.0);
  }
  
  /// Gets the XP remaining until next level
  static int getXPToNextLevel(int totalXP) {
    int currentLevel = getLevelFromTotalXP(totalXP);
    if (currentLevel >= ProgressionConstants.maxLevel) return 0;
    
    int xpAtEndOfLevel = getTotalXPForLevel(currentLevel + 1);
    return xpAtEndOfLevel - totalXP;
  }

  /// Performance-scaled quiz rewards (non-binary)
  ///
  /// Accuracy tiers:
  /// - 0-19%  -> +10 XP, +0 happiness, +4 hunger, A1
  /// - 20-39% -> +16 XP, +1 happiness, +4 hunger, A1
  /// - 40-59% -> +22 XP, +2 happiness, +3 hunger, A2
  /// - 60-79% -> +30 XP, +3 happiness, +3 hunger, B1
  /// - 80-99% -> +40 XP, +4 happiness, +2 hunger, B2
  /// - 100%   -> +50 XP, +5 happiness, +2 hunger, B2
  static QuizRewardOutcome getQuizRewardOutcome({
    required int correctAnswers,
    required int totalQuestions,
  }) {
    if (totalQuestions <= 0) {
      return const QuizRewardOutcome(
        xpReward: 10,
        happinessDelta: 0,
        hungerDelta: 4,
        level: 'A1',
        passed: false,
      );
    }

    final accuracy = (correctAnswers / totalQuestions).clamp(0.0, 1.0);

    if (accuracy >= 1.0) {
      return const QuizRewardOutcome(
        xpReward: 50,
        happinessDelta: 5,
        hungerDelta: 2,
        level: 'B2',
        passed: true,
      );
    }

    if (accuracy >= 0.8) {
      return const QuizRewardOutcome(
        xpReward: 40,
        happinessDelta: 4,
        hungerDelta: 2,
        level: 'B2',
        passed: true,
      );
    }

    if (accuracy >= 0.6) {
      return const QuizRewardOutcome(
        xpReward: 30,
        happinessDelta: 3,
        hungerDelta: 3,
        level: 'B1',
        passed: true,
      );
    }

    if (accuracy >= 0.4) {
      return const QuizRewardOutcome(
        xpReward: 22,
        happinessDelta: 2,
        hungerDelta: 3,
        level: 'A2',
        passed: false,
      );
    }

    if (accuracy >= 0.2) {
      return const QuizRewardOutcome(
        xpReward: 16,
        happinessDelta: 1,
        hungerDelta: 4,
        level: 'A1',
        passed: false,
      );
    }

    return const QuizRewardOutcome(
      xpReward: 10,
      happinessDelta: 0,
      hungerDelta: 4,
      level: 'A1',
      passed: false,
    );
  }
}
