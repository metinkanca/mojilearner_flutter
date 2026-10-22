import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/ads.dart';
import 'package:mojilearner_flutter/constants/entitlements.dart';

/// The allowance arithmetic, away from a provider.
///
/// What is pinned here is the shape of the deal rather than the numbers: that
/// a free player is bounded, that a member is bounded higher, that an ad opens
/// a real route past the wall, and that a day turning over is what gives the
/// allowance back.
void main() {
  const free = EntitlementConstants.free;
  const premium = EntitlementConstants.premium;

  group('allowances', () {
    test('a membership is worth more of both meters', () {
      expect(premium.quizzes, greaterThan(free.quizzes));
      expect(premium.messages, greaterThan(free.messages));
    });

    // The message allowance is a runaway-cost backstop, not a felt limit: it
    // has to sit well above the engagement the coin cap already assumes.
    test('the free message allowance clears an engaged day', () {
      expect(free.messages, greaterThan(15));
    });

    test('forTier picks by membership', () {
      expect(EntitlementConstants.forTier(isPremium: false), free);
      expect(EntitlementConstants.forTier(isPremium: true), premium);
    });
  });

  group('spending', () {
    test('a fresh day has the whole allowance', () {
      const ledger = AiUsageLedger();

      expect(ledger.remaining(AiSpend.quiz, free), free.quizzes);
      expect(ledger.remaining(AiSpend.message, free), free.messages);
      expect(ledger.canSpend(AiSpend.quiz, free), isTrue);
    });

    test('spending draws down only the meter it belongs to', () {
      final ledger = const AiUsageLedger().recording(AiSpend.quiz, free);

      expect(ledger.remaining(AiSpend.quiz, free), free.quizzes - 1);
      expect(ledger.remaining(AiSpend.message, free), free.messages);
    });

    test('a spent meter closes and cannot go negative', () {
      var ledger = const AiUsageLedger();
      for (var i = 0; i < free.quizzes + 5; i++) {
        ledger = ledger.recording(AiSpend.quiz, free);
      }

      expect(ledger.canSpend(AiSpend.quiz, free), isFalse);
      expect(ledger.remaining(AiSpend.quiz, free), 0);
      // ...and the other meter is untouched by it.
      expect(ledger.canSpend(AiSpend.message, free), isTrue);
    });

    // Chat and scenario turns are the same call, so they must share a meter or
    // alternating between the two screens buys twice the budget.
    test('chat and scenario turns draw on one message meter', () {
      var ledger = const AiUsageLedger();
      for (var i = 0; i < free.messages; i++) {
        ledger = ledger.recording(AiSpend.message, free);
      }

      expect(ledger.canSpend(AiSpend.message, free), isFalse);
    });

    test('upgrading mid-day opens the meter back up', () {
      var ledger = const AiUsageLedger();
      for (var i = 0; i < free.quizzes; i++) {
        ledger = ledger.recording(AiSpend.quiz, free);
      }
      expect(ledger.canSpend(AiSpend.quiz, free), isFalse);

      // The tier is asked at the point of the question, so nothing stored has
      // to be rewritten when the player subscribes.
      expect(ledger.canSpend(AiSpend.quiz, premium), isTrue);
      expect(
        ledger.remaining(AiSpend.quiz, premium),
        premium.quizzes - free.quizzes,
      );
    });
  });

  group('the route past the wall', () {
    test('a rewarded ad buys a quiz a free player had run out of', () {
      var ledger = const AiUsageLedger();
      for (var i = 0; i < free.quizzes; i++) {
        ledger = ledger.recording(AiSpend.quiz, free);
      }
      expect(ledger.canSpend(AiSpend.quiz, free), isFalse);

      ledger = ledger.recordingRewardedQuiz();

      expect(ledger.canSpend(AiSpend.quiz, free), isTrue);
      expect(
        ledger.remaining(AiSpend.quiz, free),
        EntitlementConstants.quizzesPerRewardedAd,
      );
    });

    test('an ad adds to the meter rather than hiding inside it', () {
      final ledger = const AiUsageLedger().recordingRewardedQuiz();

      expect(ledger.bonusQuizzesToday,
          EntitlementConstants.quizzesPerRewardedAd);
      expect(
        ledger.limitFor(AiSpend.quiz, free),
        free.quizzes + EntitlementConstants.quizzesPerRewardedAd,
      );
    });

    test('ads never buy messages', () {
      final ledger = const AiUsageLedger().recordingRewardedQuiz();

      expect(ledger.limitFor(AiSpend.message, free), free.messages);
    });

    // The whole day of ads has to leave a determined free player short of a
    // member, or the subscription is selling something ads already give away.
    test('a full day of ads still lands short of a membership', () {
      var ledger = const AiUsageLedger();
      for (var i = 0; i < AdsConstants.rewardedDailyLimit; i++) {
        ledger = ledger.recordingRewardedQuiz();
      }

      expect(
        ledger.limitFor(AiSpend.quiz, free),
        lessThan(premium.quizzes),
      );
    });
  });

  group('the day turning over', () {
    final today = DateTime(2026, 3, 14, 9);
    final tomorrow = DateTime(2026, 3, 15, 1);

    test('gives the allowance back', () {
      var ledger = AiUsageLedger(day: today);
      for (var i = 0; i < free.quizzes; i++) {
        ledger = ledger.recording(AiSpend.quiz, free);
      }
      expect(ledger.canSpend(AiSpend.quiz, free), isFalse);

      final rolled = ledger.rolledOver(tomorrow);

      expect(rolled.remaining(AiSpend.quiz, free), free.quizzes);
      expect(rolled.remaining(AiSpend.message, free), free.messages);
      expect(rolled.day, tomorrow);
    });

    test('leaves the same day alone', () {
      final ledger =
          AiUsageLedger(day: today).recording(AiSpend.quiz, free);

      final rolled = ledger.rolledOver(DateTime(2026, 3, 14, 23, 59));

      expect(rolled.spent(AiSpend.quiz), 1);
    });

    // An ad buys a quiz now, not a credit to bank against next week.
    test('expires the quizzes ads bought', () {
      final ledger = AiUsageLedger(day: today).recordingRewardedQuiz();

      expect(ledger.rolledOver(tomorrow).bonusQuizzesToday, 0);
    });

    // Restarting the app must not be a way to clear the day.
    test('a ledger from an earlier day is not trusted as today', () {
      var ledger = AiUsageLedger(day: today);
      for (var i = 0; i < free.quizzes; i++) {
        ledger = ledger.recording(AiSpend.quiz, free);
      }

      expect(ledger.rolledOver(today).canSpend(AiSpend.quiz, free), isFalse);
    });
  });

  /// The bank, which is what makes a daily number mean something to a week.
  ///
  /// The property worth defending here is the one that makes it affordable:
  /// banking can move quizzes between days but can never conjure one, so the
  /// spend across any stretch of days stays at or under the allowance times
  /// the days in it. Most of these tests are that claim from a different
  /// angle.
  group('banking unused quizzes', () {
    final monday = DateTime(2026, 3, 9, 9);
    final tuesday = DateTime(2026, 3, 10, 9);

    AiUsageLedger spend(
      AiUsageLedger ledger,
      int times,
      AiAllowance allowance,
    ) {
      for (var i = 0; i < times; i++) {
        ledger = ledger.recording(AiSpend.quiz, allowance);
      }
      return ledger;
    }

    test('a quiet day carries its leftovers into the next one', () {
      final ledger = spend(AiUsageLedger(day: monday), 4, premium);

      final rolled = ledger.rolledOver(tuesday, banking: premium);

      expect(rolled.bankedQuizzes, premium.quizzes - 4);
      expect(
        rolled.limitFor(AiSpend.quiz, premium),
        premium.quizzes + (premium.quizzes - 4),
      );
    });

    test('a day that used everything banks nothing', () {
      final ledger =
          spend(AiUsageLedger(day: monday), premium.quizzes, premium);

      expect(ledger.rolledOver(tuesday, banking: premium).bankedQuizzes, 0);
    });

    test('a tier that does not bank carries nothing forward', () {
      final ledger = AiUsageLedger(day: monday);

      expect(ledger.rolledOver(tuesday).bankedQuizzes, 0);
    });

    // The point of the feature: the Sunday afternoon that wants more than ten.
    test('the bank is spent once the day and its ads are gone', () {
      var ledger = AiUsageLedger(day: monday, bankedQuizzes: 5);

      ledger = spend(ledger, premium.quizzes, premium);
      expect(ledger.spent(AiSpend.quiz), premium.quizzes);
      expect(ledger.canSpend(AiSpend.quiz, premium), isTrue);

      ledger = ledger.recording(AiSpend.quiz, premium);

      expect(ledger.bankedQuizzes, 4, reason: 'drawn from the bank');
      expect(ledger.bankedQuizzesUsedToday, 1);
      expect(ledger.spent(AiSpend.quiz), premium.quizzes,
          reason: "the day's own allowance was already spent");
      expect(ledger.remaining(AiSpend.quiz, premium), 4);
    });

    // A total that walked towards the player as they spent would be worse
    // than no total at all.
    test('the total on the meter holds still while the bank is drawn', () {
      var ledger = AiUsageLedger(day: monday, bankedQuizzes: 5);
      final total = ledger.limitFor(AiSpend.quiz, premium);

      ledger = spend(ledger, premium.quizzes + 3, premium);

      expect(ledger.limitFor(AiSpend.quiz, premium), total);
      expect(ledger.taken(AiSpend.quiz), premium.quizzes + 3);
      expect(ledger.remaining(AiSpend.quiz, premium),
          total - (premium.quizzes + 3));
    });

    // Ads expire tonight and the bank does not, so an ad quiz spent before an
    // allowance quiz would turn a day's rewarded ads into a permanent credit.
    test('a rewarded ad cannot be banked', () {
      var ledger = AiUsageLedger(day: monday).recordingRewardedQuiz();
      ledger = spend(ledger, premium.quizzes, premium);

      final rolled = ledger.rolledOver(tuesday, banking: premium);

      expect(rolled.bankedQuizzes, 0);
    });

    // Only a day the player opened banks anything, so being away is not
    // itself worth an allowance a day. `server/src/quotas.js` cannot bank for
    // days it never saw a call, and the client must never promise a quiz the
    // proxy would refuse.
    test('the days in between an absence bank nothing', () {
      final ledger = AiUsageLedger(day: monday);

      final rolled = ledger.rolledOver(
        monday.add(const Duration(days: 400)),
        banking: premium,
      );

      expect(rolled.bankedQuizzes, premium.quizzes);
    });

    test('quiet days fill the bank up to the cap and no further', () {
      var ledger = AiUsageLedger(day: DateTime(2026, 3, 1, 9));

      for (var day = 1; day <= 10; day++) {
        ledger = ledger.rolledOver(
          DateTime(2026, 3, 1 + day, 9),
          banking: premium,
        );
      }

      expect(ledger.bankedQuizzes, EntitlementConstants.quizBankCap);
    });

    // The affordability claim, stated as arithmetic: a fortnight of banking
    // and spending cannot exceed a fortnight of allowances.
    test('banking moves quizzes between days without creating any', () {
      var ledger = AiUsageLedger(day: DateTime(2026, 3, 1, 9));
      var taken = 0;

      for (var day = 1; day <= 14; day++) {
        // A player who studies hard every third day and not at all otherwise.
        final wanted = day % 3 == 0 ? 25 : 0;
        for (var i = 0; i < wanted; i++) {
          if (!ledger.canSpend(AiSpend.quiz, premium)) break;
          ledger = ledger.recording(AiSpend.quiz, premium);
          taken++;
        }
        ledger = ledger.rolledOver(
          DateTime(2026, 3, 1 + day, 9),
          banking: premium,
        );
      }

      expect(taken, lessThanOrEqualTo(14 * premium.quizzes));
    });

    // Cancelling should not be the moment someone loses something they paid
    // for — but it must stop the bank filling.
    test('a lapsed membership keeps its bank and stops adding to it', () {
      final ledger = AiUsageLedger(day: monday, bankedQuizzes: 6);

      final rolled = ledger.rolledOver(tuesday);

      expect(rolled.bankedQuizzes, 6);
      expect(rolled.limitFor(AiSpend.quiz, free), free.quizzes + 6);
    });

    test('the bank never pays for a message', () {
      final ledger = AiUsageLedger(day: monday, bankedQuizzes: 6);

      expect(ledger.limitFor(AiSpend.message, premium), premium.messages);
    });
  });

  /// The slower decay, which is the one thing Plus sells that is not a number.
  ///
  /// The divisor is only meaningful against the thresholds it has to move a
  /// pet across, so that relationship is what is pinned here — see
  /// `CharacterProvider` for the decay that reads it.
  group('the slower decay a membership buys', () {
    // Hunger starts at 50 and climbs 2 an hour, so the free pet reaches the
    // starving line (80) in about 16 hours: one skipped evening.
    int hoursToStarving(int divisor) => ((80 - 50) ~/ 2) * divisor;

    test('moves a skipped evening onto the safe side of starving', () {
      expect(hoursToStarving(1), lessThan(24));
      expect(hoursToStarving(PlusCareConstants.decayDivisor),
          greaterThan(24 + 12));
    });

    // A pet that could not get into trouble would stop being a pet, and the
    // food that fixes one is the catalogue's only recurring coin sink.
    test('does not put a week away on it', () {
      expect(hoursToStarving(PlusCareConstants.decayDivisor),
          lessThan(24 * 7));
    });
  });
}
