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
      expect(outcome.coinReward, equals(12));
      expect(outcome.isFirstClear, isTrue);
    });

    test('pays more when the bonus objective is cleared', () {
      final outcome = reward(bonusCleared: 1);

      expect(outcome.xpReward, equals(45));
      expect(outcome.coinReward, equals(18));
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

  group('getScenarioRewardOutcome - degenerate input', () {
    test('handles a scenario with no bonus objectives', () {
      final outcome = reward(bonusCleared: 0, bonusTotal: 0);

      expect(outcome.xpReward, equals(35));
      expect(outcome.coinReward, equals(12));
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
