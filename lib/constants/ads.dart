/// What ads are allowed to do, and what they pay.
///
/// The third income axis, after [BondConstants] in `bond.dart` and
/// [GoldConstants] in `gold.dart`. Bond measures whether the relationship
/// grew, coins measure what the player may dress it in, and ads are a way to
/// buy coins with attention instead of study. That last sentence is exactly
/// the risk, so three rules hold it in place:
///
/// * **Ads top up a learning day; they never replace one.** Enforced rather
///   than hoped for: the offer does not appear at all until the player has
///   earned some learning coins that day, which is
///   `AdsProvider.canOfferRewarded`. The gate is not decoration. Ungated,
///   five ads pay 50 coins against the 20 a casual player earns from a real
///   session, and someone who never opened a quiz could buy the whole
///   purchasable catalogue in about four months instead of five years —
///   faster than a casual learner who watched none. The numbers are walked
///   in `test/unit/economy_curve_test.dart`.
/// * **Ad coins are not learning coins.** They are paid with
///   `UserProvider.addCoins` and never touch `awardLearningGold`, so they
///   neither suffer the daily taper nor advance it. Advancing it would mean
///   watching an ad quietly reduced what the next quiz paid, which is the
///   opposite of what an optional reward should do.
/// * **Ads buy coins, and coins buy appearance.** Everything `gold.dart` says
///   about that still holds. In particular a bond-gated accessory has no
///   price and therefore no ad can reach it — see `accessory_ownership.dart`,
///   where `bondLocked` is a different answer from `forSale`.
///
/// The two ad formats are governed differently and should not be reasoned
/// about together:
///
/// * **Rewarded** video is opt-in and player-initiated, capped by
///   [rewardedDailyLimit], and paid on the ladder. Everyone gets it, members
///   included — see [AdLedger.canShowInterstitial] for why.
/// * **Interstitial** is automatic, shown after a finished quiz or scenario,
///   and rate-limited by [interstitialCooldown]. This is the one a membership
///   removes.
library;

/// How the player's age was resolved, for the AdMob age treatment.
///
/// A tri-state rather than a bool, because "we have not asked yet" and "they
/// told us they are an adult" must not collapse into the same ad request.
enum AdAudience {
  /// Nobody has answered the age question yet.
  unknown,

  /// Self-reported under [AdsConstants.consentAge].
  child,

  /// Self-reported at or over [AdsConstants.consentAge].
  general,
}

class AdsConstants {
  AdsConstants._();

  /// The age at which a player stops being treated as a child by AdMob.
  ///
  /// 13 is COPPA's line, and Play's Families policy is written against the
  /// same number.
  static const int consentAge = 13;

  /// The earliest birth year worth accepting, as a sanity bound on a typed
  /// four-digit field. Anything older is a typo, not a player.
  static const int earliestBirthYear = 1900;

  /// Coins paid for the 1st, 2nd, ... rewarded ad of the day, indexed by how
  /// many have already been watched.
  ///
  /// Rising rather than falling, which is the opposite of most reward
  /// ladders. A falling ladder pays the most for the ad the player was
  /// already going to watch and least for the one they have to be persuaded
  /// into; this pays for finishing the set.
  ///
  /// The size is set against a day of learning, which runs from about 20
  /// coins for a one-quiz player to 170 for someone grinding. 50 sits inside
  /// that range on purpose — enough that five ads are worth the two and a
  /// half minutes, not so much that they dwarf the session they attach to.
  /// What stops the low end being a problem is the gate, not the number; see
  /// the library comment above.
  static const List<int> rewardedCoinLadder = [5, 8, 10, 12, 15];

  /// Rewarded ads available per day.
  ///
  /// Derived from the ladder rather than written down twice, so a sixth entry
  /// cannot be added and then silently never paid.
  static int get rewardedDailyLimit => rewardedCoinLadder.length;

  /// Everything the ladder pays in one day. Read by the economy test, which
  /// needs to weigh ad income against learning income.
  static int get rewardedDailyTotal =>
      rewardedCoinLadder.fold(0, (sum, value) => sum + value);

  /// Minimum gap between two automatic interstitials.
  ///
  /// A session where the player does three quizzes back to back is the most
  /// engaged session the app gets, and it is the one a per-completion
  /// interstitial would punish hardest. An hour means a long session sees one
  /// or two, not one per activity.
  static const Duration interstitialCooldown = Duration(hours: 1);
}

/// One day's ad activity, and the rules read from it.
///
/// Immutable and pure for the same reason [GoldLedger] is: these are the
/// numbers most likely to be retuned, and they should be tunable with a test
/// rather than a device.
class AdLedger {
  const AdLedger({
    this.day,
    this.rewardedWatchedToday = 0,
    this.lastInterstitialAt,
  });

  /// The calendar day [rewardedWatchedToday] belongs to, or null before any
  /// ad has ever been watched.
  final DateTime? day;

  /// Rewarded ads actually paid out today.
  ///
  /// Only ever advanced when the ad reported an earned reward, so an ad that
  /// failed to load, or that the player backed out of, does not cost them a
  /// slot.
  final int rewardedWatchedToday;

  /// When the last interstitial was shown, for [interstitialCooldown].
  ///
  /// Deliberately *not* cleared by [rolledOver]: the cooldown is a rolling
  /// hour, not a daily allowance. Clearing it at midnight would show two
  /// interstitials two minutes apart to someone studying at 23:59.
  final DateTime? lastInterstitialAt;

  /// Rewarded ads left today.
  int get rewardedRemaining =>
      (AdsConstants.rewardedDailyLimit - rewardedWatchedToday)
          .clamp(0, AdsConstants.rewardedDailyLimit);

  /// Whether there is still a rewarded ad to offer.
  bool get hasRewardedLeft => rewardedRemaining > 0;

  /// Coins the next rewarded ad would pay, or null when the day is used up.
  ///
  /// The UI shows this on the offer itself. A player deciding whether to
  /// spend thirty seconds should be able to see what it buys before they
  /// start, not after.
  int? get nextRewardValue => hasRewardedLeft
      ? AdsConstants.rewardedCoinLadder[rewardedWatchedToday]
      : null;

  /// Whether an automatic interstitial may be shown at [now].
  ///
  /// [isPremium] is what a membership actually buys. Note that it is checked
  /// here and nowhere near the rewarded path: removing rewarded ads from a
  /// paying player would take away a coin source and leave them worse off
  /// than a free one, which is not a thing to sell.
  bool canShowInterstitial(DateTime now, {required bool isPremium}) {
    if (isPremium) return false;
    final last = lastInterstitialAt;
    if (last == null) return true;
    return now.difference(last) >= AdsConstants.interstitialCooldown;
  }

  /// This ledger with one paid rewarded ad recorded against it.
  AdLedger recordingRewarded() => AdLedger(
        day: day,
        rewardedWatchedToday: rewardedWatchedToday + 1,
        lastInterstitialAt: lastInterstitialAt,
      );

  /// This ledger with an interstitial shown at [now].
  AdLedger recordingInterstitial(DateTime now) => AdLedger(
        day: day,
        rewardedWatchedToday: rewardedWatchedToday,
        lastInterstitialAt: now,
      );

  /// This ledger advanced to [now]'s calendar day, clearing the rewarded
  /// count if the day turned over.
  ///
  /// Same local-calendar rule as `UserProvider._rolloverGoldDayIfNeeded`, so
  /// the two daily systems reset together and a player never sees the coin
  /// taper reset without their ads doing the same.
  AdLedger rolledOver(DateTime now) {
    final current = day;
    final sameDay = current != null &&
        current.year == now.year &&
        current.month == now.month &&
        current.day == now.day;
    if (sameDay) return this;

    return AdLedger(
      day: now,
      rewardedWatchedToday: 0,
      lastInterstitialAt: lastInterstitialAt,
    );
  }
}

/// The ad treatment a player born in [birthYear] should get, as of [now].
///
/// A null or nonsensical year gives [AdAudience.unknown], which every caller
/// then treats exactly like [AdAudience.child]. That direction is deliberate:
/// the cost of wrongly restricting an adult's ads is a little revenue, and the
/// cost of the opposite mistake is a COPPA problem.
///
/// Compares years only. Asking for a full birth date to shave the edge case
/// of a birthday later this year would be collecting more personal data to
/// serve slightly better ads, which is the wrong trade.
AdAudience audienceForBirthYear(int? birthYear, DateTime now) {
  if (birthYear == null) return AdAudience.unknown;
  if (birthYear < AdsConstants.earliestBirthYear) return AdAudience.unknown;
  if (birthYear > now.year) return AdAudience.unknown;

  return now.year - birthYear >= AdsConstants.consentAge
      ? AdAudience.general
      : AdAudience.child;
}
