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

  /// True when the learner ended the run early with required objectives still
  /// outstanding. A partial run pays for what was done and never counts as a
  /// clear, so [isFirstClear] is always false alongside it.
  final bool isPartial;

  const ScenarioRewardOutcome({
    required this.xpReward,
    required this.coinReward,
    required this.happinessDelta,
    required this.hungerDelta,
    required this.isFirstClear,
    this.isPartial = false,
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
  /// - 0-19%  -> +10 XP,  +6 coins, +0 happiness, +4 hunger, A1
  /// - 20-39% -> +16 XP, +10 coins, +1 happiness, +4 hunger, A1
  /// - 40-59% -> +22 XP, +12 coins, +2 happiness, +3 hunger, A2
  /// - 60-79% -> +30 XP, +14 coins, +3 happiness, +3 hunger, B1
  /// - 80-99% -> +40 XP, +15 coins, +4 happiness, +2 hunger, B2
  /// - 100%   -> +50 XP, +16 coins, +5 happiness, +2 hunger, B2
  ///
  /// XP still swings 5x across the tiers, because that is where doing well
  /// should show. Coins deliberately barely move: they used to run 2 to 20,
  /// which meant a learner at 40% accuracy took over three times as long to
  /// afford anything as one at 100%. Learning speed is not a choice, and
  /// charging for it makes the slower learner — the one likeliest to quit —
  /// pay the most. The 6-to-16 spread keeps a perfect run worth chasing while
  /// making the reward mostly about having sat the quiz at all.
  ///
  /// Coins are cosmetics money only. The pet's food comes from the daily
  /// login cycle (see `dailyRewards`), so a bad run at the quiz never means a
  /// hungry pet. What a payout is finally worth also depends on the day's
  /// taper and on whether the questions came from the due review queue — see
  /// `gold.dart`.
  static QuizRewardOutcome getQuizRewardOutcome({
    required int correctAnswers,
    required int totalQuestions,
  }) {
    if (totalQuestions <= 0) {
      return const QuizRewardOutcome(
        xpReward: 10,
        coinReward: 6,
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
        coinReward: 16,
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
        coinReward: 14,
        happinessDelta: 3,
        hungerDelta: 3,
        level: 'B1',
        passed: true,
      );
    }

    if (accuracy >= 0.4) {
      return const QuizRewardOutcome(
        xpReward: 22,
        coinReward: 12,
        happinessDelta: 2,
        hungerDelta: 3,
        level: 'A2',
        passed: false,
      );
    }

    if (accuracy >= 0.2) {
      return const QuizRewardOutcome(
        xpReward: 16,
        coinReward: 10,
        happinessDelta: 1,
        hungerDelta: 4,
        level: 'A1',
        passed: false,
      );
    }

    return const QuizRewardOutcome(
      xpReward: 10,
      coinReward: 6,
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
  /// First clear, all objectives including bonus: +45 XP, +35 coins.
  /// First clear, required only:                  +35 XP, +30 coins.
  /// Replay is [replayMultiplier] of that, rounded down, with a floor of 1
  /// coin so a repeat never reads as worthless.
  ///
  /// The coin figures were 12-18 and are now 30-35. A scenario is the longest
  /// unbroken stretch of target language the app asks for — five minutes or
  /// so against a quiz's ninety seconds — and at the old rate it paid 3.6
  /// coins a minute against a quiz's 13, with replays down at 0.8. The
  /// hardest content in the game was the worst-paid in it. It should still
  /// sit below a quiz per minute, since a quiz tests recall and a scenario
  /// can be talked through, but not by four times.
  ///
  /// The replay share rises with it, to keep a replay clearly under the best
  /// quiz payout in absolute coins — the property `scenario_reward_test`
  /// guards, and the reason this cannot simply be raised further.
  static const double replayMultiplier = 0.35;

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
    final baseCoins = 30 + (5 * bonusRatio).round();

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

  /// Payout for a run the learner ended before clearing every required goal.
  ///
  /// Priced off the replay tier rather than the first-clear base, and then
  /// scaled by the share of the checklist actually cleared. That ordering is
  /// the point: a partial run is a fraction of the cheapest full clear at
  /// every ratio, so ending early can never be the efficient way to play —
  /// which it would be at any flat multiplier generous enough to feel fair.
  /// The exit is there so a scene that ran past a goal can't trap the
  /// learner, not as a shortcut.
  ///
  /// Counts bonus objectives in the denominator too — the tally the popup
  /// shows — so the share reflects the whole checklist the learner saw.
  /// Never a clear, so it neither unlocks the first-clear tier nor consumes
  /// it: the scenario stays available at full value.
  static ScenarioRewardOutcome getScenarioPartialOutcome({
    required int objectivesCleared,
    required int objectivesTotal,
  }) {
    final safeTotal = objectivesTotal < 0 ? 0 : objectivesTotal;
    final safeCleared = objectivesCleared.clamp(0, safeTotal);
    final ratio = safeTotal == 0 ? 0.0 : safeCleared / safeTotal;

    return ScenarioRewardOutcome(
      xpReward: (35 * replayMultiplier * ratio).floor(),
      coinReward: (30 * replayMultiplier * ratio).floor(),
      // The pet reacts to effort, not to the checklist: a run that got most
      // of the way still cheers it up a little, an immediate bail does not.
      happinessDelta: (5 * ratio).floor(),
      hungerDelta: (6 * ratio).floor(),
      isFirstClear: false,
      isPartial: true,
    );
  }
}
