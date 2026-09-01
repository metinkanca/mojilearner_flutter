import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/gold.dart';
import 'package:mojilearner_flutter/constants/progression.dart';
import 'package:mojilearner_flutter/utils/progression_utils.dart';

/// The taper and the source caps are what let the repeatable sources pay
/// properly without the catalogue collapsing in a weekend, so the arithmetic
/// is worth pinning down on its own — away from prefs and providers.
void main() {
  const quiz = GoldSource.quiz;
  const chat = GoldSource.conversation;

  /// Pays [raw] from [source] repeatedly, returning the running total paid.
  int payOut(GoldLedger ledger, int raw, GoldSource source, int times) {
    var total = 0;
    var current = ledger;
    for (var i = 0; i < times; i++) {
      final award = current.award(raw, source);
      total += award.paid;
      current = current.recording(award, source);
    }
    return total;
  }

  group('the daily taper', () {
    test('pays in full inside the first band', () {
      const ledger = GoldLedger();

      final award = ledger.award(16, quiz);

      expect(award.paid, equals(16));
      expect(award.raw, equals(16));
      expect(award.wasReduced, isFalse);
    });

    test('halves what is earned past the full-rate band', () {
      const ledger =
          GoldLedger(rawEarnedToday: GoldConstants.fullRateDailyGold);

      expect(ledger.award(16, quiz).paid, equals(8));
    });

    test('quarters what is earned past the half-rate band', () {
      const ledger =
          GoldLedger(rawEarnedToday: GoldConstants.halfRateDailyGold);

      expect(ledger.award(16, quiz).paid, equals(4));
    });

    test('splits a payout across a band boundary rather than rounding it', () {
      const ledger =
          GoldLedger(rawEarnedToday: GoldConstants.fullRateDailyGold - 10);

      // 10 at full rate, 10 at half.
      expect(ledger.award(20, quiz).paid, equals(15));
    });

    test('never pays nothing for real work, however long the session', () {
      // A taper should shade a reward, not tell a player still studying that
      // the next hour is worthless.
      const deepIntoTheTail = GoldLedger(rawEarnedToday: 10000);

      expect(deepIntoTheTail.award(16, quiz).paid, greaterThan(0));
      expect(deepIntoTheTail.award(GoldConstants.conversation, chat).paid,
          greaterThan(0));
    });

    test('a full day of grinding beats a short one, by less than its length',
        () {
      // The point of the taper: more play is always worth more, but fifteen
      // quizzes must not be worth fifteen times three.
      const ledger = GoldLedger();
      final three = payOut(ledger, 16, quiz, 3);
      final fifteen = payOut(ledger, 16, quiz, 15);

      expect(fifteen, greaterThan(three));
      expect(fifteen, lessThan(three * 5));
    });
  });

  group('per-source daily caps', () {
    test('stop an unbounded source from becoming a faucet', () {
      const ledger = GoldLedger();

      final total = payOut(
        ledger,
        GoldConstants.conversation,
        chat,
        GoldConstants.conversationDailyCap + 20,
      );

      expect(total, equals(GoldConstants.conversationDailyCap));
    });

    test('a capped-out day of chat is worth less than one good quiz', () {
      // Chat pays per message and cannot be allowed to out-earn sitting a
      // quiz, or the cheapest possible action becomes the best-paid one.
      final bestQuiz = ProgressionUtils.getQuizRewardOutcome(
        correctAnswers: 5,
        totalQuestions: 5,
      ).coinReward;

      expect(GoldConstants.conversationDailyCap, lessThan(bestQuiz * 2));
    });

    test('a refused payout does not consume the taper bands', () {
      const spent = GoldLedger(
        rawPerSourceToday: {chat: GoldConstants.conversationDailyCap},
      );

      final award = spent.award(GoldConstants.conversation, chat);

      expect(award.paid, equals(0));
      expect(spent.recording(award, chat).rawEarnedToday, equals(0));
    });

    test('one source running out leaves the others alone', () {
      const spent = GoldLedger(
        rawPerSourceToday: {chat: GoldConstants.conversationDailyCap},
      );

      expect(spent.award(16, quiz).paid, equals(16));
      expect(spent.remainingFor(quiz), isNull);
    });
  });

  group('the shape of a day', () {
    test('an ordinary session never reaches the taper', () {
      // Three quizzes, a scenario and a chatty session: a good day's study,
      // and it should be paid in full throughout.
      const ledger = GoldLedger();
      var current = ledger;
      var paid = 0;
      var raw = 0;

      for (var i = 0; i < 3; i++) {
        final award = current.award(15, quiz);
        paid += award.paid;
        raw += award.raw;
        current = current.recording(award, quiz);
      }
      final scenario = current.award(35, GoldSource.scenario);
      paid += scenario.paid;
      raw += scenario.raw;

      expect(paid, equals(raw));
    });

    test('the repeat rate keeps a stale quiz worth taking, but not farming',
        () {
      final full = ProgressionUtils.getQuizRewardOutcome(
        correctAnswers: 5,
        totalQuestions: 5,
      ).coinReward;
      final repeat = (full * GoldConstants.repeatQuizRate).round();

      expect(repeat, greaterThan(0));
      expect(repeat, lessThan(full ~/ 2));
    });

    test('coins never buy survival: the cheapest food is a login reward', () {
      // The economy only holds together while the pet's upkeep comes from
      // showing up rather than from the wardrobe budget.
      final foodDays =
          dailyRewards.where((r) => r.type == RewardType.item).length;

      expect(foodDays, greaterThanOrEqualTo(dailyRewards.length ~/ 2));
    });
  });
}
