import 'dart:math';
import '../constants/progression.dart';

class QuizRewardOutcome {
  final int xpReward;

  /// Coins granted for the quiz. Quizzes are the game's only repeatable coin
  /// source — daily rewards and level-ups are drip income — so these values
  /// set the pace at which food and cosmetics become affordable.
  final int coinReward;
  final int happinessDelta;
  final int hungerDelta;
  final String level;
  final bool passed;

  const QuizRewardOutcome({
    required this.xpReward,
    required this.coinReward,
    required this.happinessDelta,
    required this.hungerDelta,
    required this.level,
    required this.passed,
  });
}

/// Payout for clearing a scenario.
class ScenarioRewardOutcome {
  final int xpReward;

  /// Coins granted for the clear. Scenarios are repeatable, so this is the
  /// number that decides whether they become a coin farm — see
  /// [ProgressionUtils.getScenarioRewardOutcome].
  final int coinReward;
  final int happinessDelta;
  final int hungerDelta;

  /// True when this was the learner's first ever clear of the scenario, which
  /// is what the completion popup explains the smaller payout with.
  final bool isFirstClear;

  const ScenarioRewardOutcome({
    required this.xpReward,
    required this.coinReward,
    required this.happinessDelta,
    required this.hungerDelta,
    required this.isFirstClear,
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
  /// - 0-19%  -> +10 XP,  +2 coins, +0 happiness, +4 hunger, A1
  /// - 20-39% -> +16 XP,  +4 coins, +1 happiness, +4 hunger, A1
  /// - 40-59% -> +22 XP,  +6 coins, +2 happiness, +3 hunger, A2
  /// - 60-79% -> +30 XP, +10 coins, +3 happiness, +3 hunger, B1
  /// - 80-99% -> +40 XP, +15 coins, +4 happiness, +2 hunger, B2
  /// - 100%   -> +50 XP, +20 coins, +5 happiness, +2 hunger, B2
  ///
  /// Coin sizing: a day of decay costs roughly 35-50 coins of food, so two or
  /// three solid quizzes a day cover upkeep, and the surplus saves toward
  /// backgrounds (100-200) over about a week.
  static QuizRewardOutcome getQuizRewardOutcome({
    required int correctAnswers,
    required int totalQuestions,
  }) {
    if (totalQuestions <= 0) {
      return const QuizRewardOutcome(
        xpReward: 10,
        coinReward: 2,
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
        coinReward: 20,
        happinessDelta: 5,
        hungerDelta: 2,
        level: 'B2',
        passed: true,
      );
    }

    if (accuracy >= 0.8) {
      return const QuizRewardOutcome(
        xpReward: 40,
        coinReward: 15,
        happinessDelta: 4,
        hungerDelta: 2,
        level: 'B2',
        passed: true,
      );
    }

    if (accuracy >= 0.6) {
      return const QuizRewardOutcome(
        xpReward: 30,
        coinReward: 10,
        happinessDelta: 3,
        hungerDelta: 3,
        level: 'B1',
        passed: true,
      );
    }

    if (accuracy >= 0.4) {
      return const QuizRewardOutcome(
        xpReward: 22,
        coinReward: 6,
        happinessDelta: 2,
        hungerDelta: 3,
        level: 'A2',
        passed: false,
      );
    }

    if (accuracy >= 0.2) {
      return const QuizRewardOutcome(
        xpReward: 16,
        coinReward: 4,
        happinessDelta: 1,
        hungerDelta: 4,
        level: 'A1',
        passed: false,
      );
    }

    return const QuizRewardOutcome(
      xpReward: 10,
      coinReward: 2,
      happinessDelta: 0,
      hungerDelta: 4,
      level: 'A1',
      passed: false,
    );
  }

  /// Reward for clearing a scenario, scaled by bonus objectives and by
  /// whether this is a repeat.
  ///
  /// Scenarios already pay 10 XP per message with no cap, so an uncapped
  /// completion bonus on top would make them the cheapest coin source in the
  /// game — cheaper than a quiz, and repeatable in a minute. Replays
  /// therefore pay [replayMultiplier] of a first clear: still worth doing for
  /// the practice, not worth grinding for the shop.
  ///
  /// First clear, all objectives including bonus: +45 XP, +18 coins.
  /// First clear, required only:                  +35 XP, +12 coins.
  /// Replay is a quarter of that, rounded down, with a floor of 1 coin so a
  /// repeat never reads as worthless.
  static const double replayMultiplier = 0.25;

  static ScenarioRewardOutcome getScenarioRewardOutcome({
    required int bonusObjectivesCleared,
    required int bonusObjectivesTotal,
    required bool isFirstClear,
  }) {
    final safeTotal = bonusObjectivesTotal < 0 ? 0 : bonusObjectivesTotal;
    final safeCleared = bonusObjectivesCleared.clamp(0, safeTotal);
    final bonusRatio = safeTotal == 0 ? 0.0 : safeCleared / safeTotal;

    // Base clear, plus up to a third again for the optional goals.
    final baseXp = 35 + (10 * bonusRatio).round();
    final baseCoins = 12 + (6 * bonusRatio).round();

    if (isFirstClear) {
      return ScenarioRewardOutcome(
        xpReward: baseXp,
        coinReward: baseCoins,
        happinessDelta: 12,
        hungerDelta: 6,
        isFirstClear: true,
      );
    }

    return ScenarioRewardOutcome(
      xpReward: (baseXp * replayMultiplier).floor(),
      coinReward: (baseCoins * replayMultiplier).floor().clamp(1, baseCoins),
      happinessDelta: 5,
      hungerDelta: 6,
      isFirstClear: false,
    );
  }
}
