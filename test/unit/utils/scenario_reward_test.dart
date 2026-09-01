import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/utils/progression_utils.dart';

ScenarioRewardOutcome reward({
  int bonusCleared = 0,
  int bonusTotal = 1,
  bool isFirstClear = true,
}) {
  return ProgressionUtils.getScenarioRewardOutcome(
    bonusObjectivesCleared: bonusCleared,
    bonusObjectivesTotal: bonusTotal,
    isFirstClear: isFirstClear,
  );
}

void main() {
  group('getScenarioRewardOutcome - first clear', () {
    test('pays the base rate with no bonus objectives cleared', () {
      final outcome = reward(bonusCleared: 0);

      expect(outcome.xpReward, equals(35));
      expect(outcome.coinReward, equals(30));
      expect(outcome.isFirstClear, isTrue);
    });

    test('pays more when the bonus objective is cleared', () {
      final outcome = reward(bonusCleared: 1);

      expect(outcome.xpReward, equals(45));
      expect(outcome.coinReward, equals(35));
    });

    test('scales partially with several bonus objectives', () {
      final outcome = reward(bonusCleared: 1, bonusTotal: 2);

      expect(outcome.xpReward, greaterThan(reward(bonusCleared: 0).xpReward));
      expect(outcome.xpReward, lessThan(45));
    });
  });

  group('getScenarioRewardOutcome - replays', () {
    test('pays a fraction of a first clear', () {
      final first = reward(bonusCleared: 1);
      final replay = reward(bonusCleared: 1, isFirstClear: false);

      expect(replay.isFirstClear, isFalse);
      expect(replay.xpReward, lessThan(first.xpReward));
      expect(replay.coinReward, lessThan(first.coinReward));
      expect(
        replay.xpReward,
        equals((first.xpReward * ProgressionUtils.replayMultiplier).floor()),
      );
    });

    test('a replay still pays at least one coin', () {
      final replay = reward(bonusCleared: 0, isFirstClear: false);

      expect(replay.coinReward, greaterThanOrEqualTo(1));
    });

    test('replays give less happiness than a first clear', () {
      expect(
        reward(isFirstClear: false).happinessDelta,
        lessThan(reward(isFirstClear: true).happinessDelta),
      );
    });

    test('a first clear beats a quiz, because it is the harder work', () {
      // A scenario is five minutes of unbroken target language against a
      // quiz's ninety seconds. It used to pay 12-18 coins to a quiz's 20,
      // which made the hardest content in the game the worst-paid per minute
      // in it.
      final bestQuiz = ProgressionUtils.getQuizRewardOutcome(
        correctAnswers: 5,
        totalQuestions: 5,
      );
      final firstClear = reward(bonusCleared: 1, isFirstClear: true);

      expect(firstClear.coinReward, greaterThan(bestQuiz.coinReward));
    });

    test('a replay never out-earns a quiz, so it cannot become the farm', () {
      // The best repeatable quiz payout is the yardstick: scenario replays
      // must stay clearly below it or they become the cheapest coin source.
      final bestQuiz = ProgressionUtils.getQuizRewardOutcome(
        correctAnswers: 5,
        totalQuestions: 5,
      );
      final bestReplay = reward(bonusCleared: 1, isFirstClear: false);

      expect(bestReplay.coinReward, lessThan(bestQuiz.coinReward));
      expect(bestReplay.xpReward, lessThan(bestQuiz.xpReward));
    });
  });

  group('getScenarioPartialOutcome', () {
    ScenarioRewardOutcome partial({required int cleared, int total = 4}) {
      return ProgressionUtils.getScenarioPartialOutcome(
        objectivesCleared: cleared,
        objectivesTotal: total,
      );
    }

    test('is never a clear, so it cannot consume the first-clear tier', () {
      final outcome = partial(cleared: 3);

      expect(outcome.isPartial, isTrue);
      expect(outcome.isFirstClear, isFalse);
    });

    test('pays nothing for a run walked out of immediately', () {
      final outcome = partial(cleared: 0);

      expect(outcome.xpReward, isZero);
      expect(outcome.coinReward, isZero);
      expect(outcome.happinessDelta, isZero);
    });

    test('pays more the further the run got', () {
      expect(partial(cleared: 3).xpReward,
          greaterThan(partial(cleared: 1).xpReward));
      expect(partial(cleared: 3).coinReward,
          greaterThan(partial(cleared: 1).coinReward));
    });

    test('a near-complete bail still pays less than the cheapest clear', () {
      // Otherwise finishing early becomes the efficient way to play: three of
      // four objectives and out, over and over.
      final cheapestClear = reward(bonusCleared: 0, isFirstClear: false);

      expect(partial(cleared: 3).coinReward,
          lessThan(cheapestClear.coinReward));
      expect(partial(cleared: 3).xpReward, lessThan(cheapestClear.xpReward));
    });

    test('tolerates degenerate counts', () {
      expect(partial(cleared: 9, total: 4).xpReward,
          equals(partial(cleared: 4, total: 4).xpReward));
      expect(partial(cleared: -2, total: 4).xpReward, isZero);
      expect(partial(cleared: 1, total: 0).xpReward, isZero);
      expect(partial(cleared: 1, total: -3).xpReward, isZero);
    });
  });

  group('getScenarioRewardOutcome - degenerate input', () {
    test('handles a scenario with no bonus objectives', () {
      final outcome = reward(bonusCleared: 0, bonusTotal: 0);

      expect(outcome.xpReward, equals(35));
      expect(outcome.coinReward, equals(30));
    });

    test('clamps a cleared count above the total', () {
      expect(
        reward(bonusCleared: 9, bonusTotal: 1).xpReward,
        equals(reward(bonusCleared: 1, bonusTotal: 1).xpReward),
      );
    });

    test('clamps a negative cleared count', () {
      expect(
        reward(bonusCleared: -3, bonusTotal: 1).xpReward,
        equals(reward(bonusCleared: 0, bonusTotal: 1).xpReward),
      );
    });

    test('tolerates a negative total', () {
      final outcome = reward(bonusCleared: 0, bonusTotal: -2);

      expect(outcome.xpReward, equals(35));
    });
  });
}
