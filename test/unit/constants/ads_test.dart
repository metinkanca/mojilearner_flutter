import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/ads.dart';
import 'package:mojilearner_flutter/constants/gold.dart';

/// The ad rules decide how much of the economy can be bought with attention
/// rather than study, so they are worth pinning down away from the SDK, the
/// provider and the screens — none of which can run in a unit test anyway.
void main() {
  final day = DateTime(2026, 8, 29, 9);

  /// A ledger that has already paid out [count] rewarded ads today.
  AdLedger afterRewarded(int count) {
    var ledger = AdLedger(day: day);
    for (var i = 0; i < count; i++) {
      ledger = ledger.recordingRewarded();
    }
    return ledger;
  }

  group('the rewarded ladder', () {
    test('pays each slot the advertised amount, in order', () {
      final paid = [
        for (var i = 0; i < AdsConstants.rewardedDailyLimit; i++)
          afterRewarded(i).nextRewardValue,
      ];

      expect(paid, equals(AdsConstants.rewardedCoinLadder));
    });

    test('rises, so finishing the set is what is being paid for', () {
      final ladder = AdsConstants.rewardedCoinLadder;

      for (var i = 1; i < ladder.length; i++) {
        expect(ladder[i], greaterThan(ladder[i - 1]),
            reason: 'slot $i pays no more than the one before it');
      }
    });

    test('runs out after the daily limit', () {
      final spent = afterRewarded(AdsConstants.rewardedDailyLimit);

      expect(spent.hasRewardedLeft, isFalse);
      expect(spent.rewardedRemaining, isZero);
      expect(spent.nextRewardValue, isNull);
    });

    test('counts down as ads are watched', () {
      expect(afterRewarded(0).rewardedRemaining,
          equals(AdsConstants.rewardedDailyLimit));
      expect(afterRewarded(2).rewardedRemaining,
          equals(AdsConstants.rewardedDailyLimit - 2));
    });

    test('never reports a negative remainder past the limit', () {
      // Nothing should push past the cap, but the getter is read straight
      // into UI copy ("3 left today"), so a stray increment must not render
      // as a negative count.
      expect(afterRewarded(AdsConstants.rewardedDailyLimit + 3).rewardedRemaining,
          isZero);
    });

    test('the limit and the ladder cannot drift apart', () {
      expect(AdsConstants.rewardedDailyLimit,
          equals(AdsConstants.rewardedCoinLadder.length));
    });
  });

  group('what a day of ads is worth', () {
    test('tops up a learning day rather than replacing one', () {
      // The whole point of the ladder's size. An engaged day of learning pays
      // roughly the full-rate band; ads must stay meaningfully under it, or
      // the cheapest route to the catalogue stops being the content.
      expect(AdsConstants.rewardedDailyTotal,
          lessThan(GoldConstants.fullRateDailyGold));
    });

    test('is still worth crossing the room for', () {
      // The other half of the same trade: too small and the offer is an
      // insult, the player ignores it, and the ad earns nothing either.
      // Roughly a fifth of a learning day is the floor.
      expect(AdsConstants.rewardedDailyTotal,
          greaterThan(GoldConstants.fullRateDailyGold ~/ 5));
    });

    test('does not buy the cheapest accessory in a single day', () {
      // Accessories start around 60 coins. A day of ads alone should not
      // clear one outright — some learning has to happen in between.
      expect(AdsConstants.rewardedDailyTotal, lessThan(60));
    });
  });

  group('the interstitial cooldown', () {
    test('allows the first one', () {
      const ledger = AdLedger();

      expect(ledger.canShowInterstitial(day, isPremium: false), isTrue);
    });

    test('blocks a second one inside the hour', () {
      final ledger = const AdLedger().recordingInterstitial(day);

      expect(
        ledger.canShowInterstitial(
          day.add(const Duration(minutes: 59)),
          isPremium: false,
        ),
        isFalse,
      );
    });

    test('allows another one once the hour has passed', () {
      final ledger = const AdLedger().recordingInterstitial(day);

      expect(
        ledger.canShowInterstitial(
          day.add(AdsConstants.interstitialCooldown),
          isPremium: false,
        ),
        isTrue,
      );
    });

    test('is what a membership removes', () {
      const ledger = AdLedger();

      expect(ledger.canShowInterstitial(day, isPremium: true), isFalse);
    });

    test('does not take rewarded ads away from a member', () {
      // Selling a coin source back out of the game would leave a paying
      // player worse off than a free one. Membership buys the absence of
      // interruption, not the absence of income.
      final ledger = AdLedger(day: day);

      expect(ledger.hasRewardedLeft, isTrue);
      expect(ledger.nextRewardValue,
          equals(AdsConstants.rewardedCoinLadder.first));
    });
  });

  group('the day rollover', () {
    test('restores the rewarded allowance on a new day', () {
      final spent = afterRewarded(AdsConstants.rewardedDailyLimit);

      final tomorrow = spent.rolledOver(day.add(const Duration(days: 1)));

      expect(tomorrow.rewardedWatchedToday, isZero);
      expect(tomorrow.hasRewardedLeft, isTrue);
    });

    test('leaves the count alone within the same day', () {
      final spent = afterRewarded(2);

      final later = spent.rolledOver(day.add(const Duration(hours: 6)));

      expect(later.rewardedWatchedToday, equals(2));
    });

    test('carries the interstitial cooldown across midnight', () {
      // The cooldown is a rolling hour, not a daily allowance. Clearing it at
      // midnight would show two interstitials two minutes apart to someone
      // studying at 23:59.
      final lateNight = DateTime(2026, 8, 29, 23, 59);
      final ledger = AdLedger(day: lateNight).recordingInterstitial(lateNight);

      final justAfterMidnight = DateTime(2026, 8, 30, 0, 1);
      final tomorrow = ledger.rolledOver(justAfterMidnight);

      expect(tomorrow.lastInterstitialAt, equals(lateNight));
      expect(tomorrow.canShowInterstitial(justAfterMidnight, isPremium: false),
          isFalse);
    });

    test('adopts the day on a ledger that has never seen one', () {
      const fresh = AdLedger();

      expect(fresh.rolledOver(day).day, equals(day));
    });
  });

  group('the age rule', () {
    final now = DateTime(2026, 8, 29);

    test('treats a clear adult as a general audience', () {
      expect(audienceForBirthYear(1990, now), equals(AdAudience.general));
    });

    test('treats someone under the consent age as a child', () {
      expect(audienceForBirthYear(now.year - 8, now), equals(AdAudience.child));
    });

    test('the consent age itself counts as general', () {
      expect(
        audienceForBirthYear(now.year - AdsConstants.consentAge, now),
        equals(AdAudience.general),
      );
      expect(
        audienceForBirthYear(now.year - AdsConstants.consentAge + 1, now),
        equals(AdAudience.child),
      );
    });

    test('an unanswered question is unknown, not an adult', () {
      // The direction matters: every caller treats unknown exactly as it
      // treats a child, so defaulting the other way would serve personalised
      // ads to someone who might be nine.
      expect(audienceForBirthYear(null, now), equals(AdAudience.unknown));
    });

    test('rejects a year that cannot be real', () {
      expect(audienceForBirthYear(1200, now), equals(AdAudience.unknown));
      expect(audienceForBirthYear(now.year + 1, now), equals(AdAudience.unknown));
    });

    test('accepts someone born this year', () {
      // Nonsense as a player, but it is a real year, and the answer it gives
      // — child — is the safe one either way.
      expect(audienceForBirthYear(now.year, now), equals(AdAudience.child));
    });
  });
}
