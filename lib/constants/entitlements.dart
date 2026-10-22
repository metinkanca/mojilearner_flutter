/// What a membership buys, and what the free tier gets.
///
/// The fourth axis, after the XP ledger in `progression.dart`, [GoldConstants]
/// in `gold.dart` and [AdsConstants] in `ads.dart`. Those three shape what
/// *rewards* a day can pay. This one shapes what a day can *cost*: every quiz
/// generated and every message answered is a model call somebody pays for.
///
/// Two rules hold it in place.
///
/// * **The wall never stops studying.** `gold.dart` rejected a hard cap on
///   coins because "hitting a wall mid-session tells the player to stop
///   studying", and that objection stands. What makes a cap defensible here is
///   that a quiz is a *cost*, not a reward — so the cap may stop the app
///   *generating* new material, and must never stop the player working. When
///   [AiAllowance.quizzes] is spent, the spaced-repetition review queue and
///   the stock question set are both still there, both free, and neither one
///   costs a model call. "Come back tomorrow" is not an answer this app gives.
///
/// * **The client is not the enforcer.** `UserProvider.isPremium` is a stored
///   bool, and the thing being rationed is a server-side model call — so a
///   rebuilt client can set it. The numbers here drive the meter, the wall and
///   the upgrade prompt; the proxy has to hold the same allowance against a
///   validated entitlement or none of this protects anything that costs money.
///   [EntitlementConstants.quizBankCap] is part of that contract: a proxy that
///   enforces a flat ten a day would reject the eleventh quiz of a day the
///   client has already promised, so the bank has to be mirrored there too.
///
/// The file also holds [PlusCareConstants], which is the one thing Plus buys
/// that costs nothing to serve. It lives here because it is an entitlement —
/// what a membership is worth — rather than because it is a model call.
library;

import 'app_runtime_config.dart';

/// A metered thing the player can spend, because it costs a model call.
///
/// Chat and scenario turns share [AiSpend.message] deliberately: they are the
/// same call to the same model, and splitting them would let a player spend
/// twice the budget by alternating between two screens.
enum AiSpend {
  /// Generating one quiz.
  quiz,

  /// One exchange with the pet, scenario or not.
  message,
}

/// One tier's daily allowance.
class AiAllowance {
  const AiAllowance({required this.quizzes, required this.messages});

  final int quizzes;
  final int messages;

  int limitFor(AiSpend spend) => switch (spend) {
        AiSpend.quiz => quizzes,
        AiSpend.message => messages,
      };
}

class EntitlementConstants {
  EntitlementConstants._();

  /// The free tier.
  ///
  /// Three quizzes is deliberately the tightest number here, because it is the
  /// one with a free alternative sitting right behind it: the review queue is
  /// unlimited, and it is also the better way to study. The message allowance
  /// is set well above what an engaged day actually produces — `gold.dart`
  /// caps conversation coins at 15 a day on the grounds that a real
  /// conversation never notices it — so 30 is a runaway-cost backstop rather
  /// than a felt limit.
  static const AiAllowance free = AiAllowance(quizzes: 3, messages: 30);

  /// What Mimikin Plus buys.
  ///
  /// Not "unlimited": an unlimited tier prices a subscription against the
  /// heaviest possible user, and the honest way to sell more capacity is to
  /// say how much more. Ten quizzes and two hundred messages are past what a
  /// long study day reaches, so in practice a member never meets the ceiling.
  static const AiAllowance premium = AiAllowance(quizzes: 10, messages: 200);

  static AiAllowance forTier({required bool isPremium}) {
    final base = isPremium ? premium : free;

    // Debug-only, and off unless a --dart-define asks for it. Both walls
    // otherwise take a real session to reach, which makes the screen carrying
    // the upgrade offer the most tedious one in the app to review. See
    // `AppRuntimeConfig.aiQuizLimitOverride`.
    final quizzes = AppRuntimeConfig.aiQuizLimitOverride;
    final messages = AppRuntimeConfig.aiMessageLimitOverride;
    if (quizzes < 0 && messages < 0) return base;

    return AiAllowance(
      quizzes: quizzes < 0 ? base.quizzes : quizzes,
      messages: messages < 0 ? base.messages : messages,
    );
  }

  /// The most unused quizzes Mimikin Plus will carry forward.
  ///
  /// Ten a day is invisible to the way people actually study. Someone who
  /// works through a Sunday afternoon and does nothing on Tuesday never meets
  /// the ceiling on either day, so the number they are paying for does
  /// nothing for them on the one day they wanted it. Banking makes the
  /// allowance weekly in the shape a week really has, without making it
  /// bigger.
  ///
  /// It cannot raise what a week costs, which is the whole reason it is
  /// affordable: a bank only ever fills with quizzes that were *not*
  /// generated, so the total across any stretch of days stays at or under the
  /// daily allowance times the days in it. The cap is here for the other
  /// risk — burst. Three days' worth bounds how much a single day can spike.
  ///
  /// Only a day the player actually opened banks anything. Being away for a
  /// week is not itself worth seventy quizzes, and the alternative would be
  /// worse than merely generous: `server/src/quotas.js` cannot bank for days
  /// it never saw the account call, so a client that credited them would
  /// promise a member quizzes the proxy then refused. Every rule here has to
  /// leave the server the more generous of the two.
  static const int quizBankCap = 30;

  /// Extra quizzes one rewarded ad buys a free player.
  ///
  /// The route past the wall for someone who will not pay. It needs no cap of
  /// its own — `AdsConstants.rewardedDailyLimit` already bounds it at five,
  /// which lands a determined free player at eight quizzes, still short of a
  /// member's ten.
  static const int quizzesPerRewardedAd = 1;
}

/// What Mimikin Plus does for a pet whose player is away.
///
/// The one thing on the paywall that is not a number. Every other line of this
/// file sells capacity; this sells a gentler slope, which is what a tamagotchi
/// player actually worries about — coming back after a hard week to something
/// sick and starving, and being told off by it.
///
/// **It slows the slide, it does not stop it**, and that is deliberate twice
/// over.
///
/// Design first: a pet that could no longer get into trouble would stop being
/// a pet. The care loop is the game, so the honest thing to sell is time, not
/// exemption — a weekend away costs a member almost nothing, a fortnight still
/// costs them a sick pet, and either way they come home to something that
/// needs them.
///
/// Then the money, which points the same way. Food and medicine are the
/// catalogue's only recurring coin sink, and coins are what `coin_packs.dart`
/// sells. A floor — the obvious alternative, holding stats above the crisis
/// thresholds — would have capped how much food any absence could ever demand,
/// and capped it *low*, so the members most likely to spend would have been
/// the ones with the least left to spend on. A divisor caps nothing: it only
/// buys time, and a member who is away long enough still comes back to a pet
/// that needs feeding all the way from the bottom.
///
/// `bond.dart` is untouched by all of this. Closeness is still only earned
/// through the language, and a member's pet gets no closer for paying. Nothing
/// here moves a stat upwards either — decay is slower, never reversed, so a
/// membership is time rather than care that was bought instead of given.
///
/// This once also bought a missed day's forgiveness on the daily-reward
/// streak. That is gone, and not because it was cut from the tier: the streak
/// no longer resets for anybody, so there is nothing left to forgive. A perk
/// that only has value while a punishment exists is a reason to look hard at
/// the punishment — see `DailyRewardProvider.checkDailyReward`.
class PlusCareConstants {
  PlusCareConstants._();

  /// How many hours of absence it takes to cost one hour of decay.
  ///
  /// Four, which is the smallest number that changes the *shape* of an
  /// absence rather than just its speed. `CharacterProvider` moves hunger 2
  /// points an hour from a starting 50, so a free pet crosses into starving
  /// (`_criticalHunger`, 80) after about sixteen hours — a single skipped
  /// evening. At a quarter of that it takes about two and a half days, which
  /// puts the ordinary reasons people miss a day (a long shift, a night out,
  /// a weekend away) on the safe side of the line, and leaves a genuinely
  /// neglected pet to get sick anyway.
  ///
  /// Applied to the clock rather than the amounts: a decay step still moves
  /// the same points, it just takes four hours to come around. That keeps the
  /// arithmetic in integers, so nothing rounds and no fraction of an hour is
  /// lost at a tick boundary — see `CharacterProvider._applyElapsedDecay`.
  static const int decayDivisor = 4;
}

/// One day's model spend, and the rules read from it.
///
/// Immutable and pure for the same reason [GoldLedger] and [AdLedger] are:
/// these are the numbers most likely to be retuned, and they should be tunable
/// with a test rather than a device.
///
/// Holds no notion of which tier the player is on. The allowance is passed in
/// at the point of the question, so an upgrade takes effect on the next call
/// rather than needing the stored ledger to be rewritten.
class AiUsageLedger {
  const AiUsageLedger({
    this.day,
    this.spentToday = const {},
    this.bonusQuizzesToday = 0,
    this.bankedQuizzes = 0,
    this.bankedQuizzesUsedToday = 0,
  });

  /// The calendar day [spentToday] belongs to, or null before anything has
  /// been spent.
  final DateTime? day;

  /// How much of each meter today has used.
  ///
  /// Quizzes drawn from [bankedQuizzes] are counted in
  /// [bankedQuizzesUsedToday] instead, so this stays what its name says: how
  /// much of *today's own* allowance today has taken.
  final Map<AiSpend, int> spentToday;

  /// Extra quizzes bought with rewarded ads today.
  ///
  /// Kept apart from the allowance rather than folded into it, so the meter
  /// can say "3 of 3, plus 2 earned" instead of quietly showing a limit that
  /// moves. A player who watched an ad should be able to see what it bought.
  final int bonusQuizzesToday;

  /// Unused quizzes carried in from earlier days, spendable once today's own
  /// allowance and any ad quizzes are gone.
  ///
  /// Only a banking tier fills it — see [EntitlementConstants.quizBankCap] —
  /// but whatever is already in it stays spendable if a membership lapses. It
  /// was earned while paying, and emptying someone's bank at the moment they
  /// cancel is the kind of thing that gets noticed and written about.
  final int bankedQuizzes;

  /// How many of the banked quizzes today has already drawn.
  ///
  /// Kept apart from [spentToday] for the same reason [bonusQuizzesToday] is:
  /// so the meter reads honestly. Folded in, the total on screen would shrink
  /// by one every time the bank paid for a quiz, and a player watching it
  /// would see the finish line walking towards them.
  final int bankedQuizzesUsedToday;

  int spent(AiSpend spend) => spentToday[spend] ?? 0;

  /// Everything [spend] may use today: the allowance, anything ads have
  /// added, and whatever the bank held when the day opened.
  int limitFor(AiSpend spend, AiAllowance allowance) =>
      allowance.limitFor(spend) +
      (spend == AiSpend.quiz
          ? bonusQuizzesToday + bankedQuizzes + bankedQuizzesUsedToday
          : 0);

  /// Everything today has actually taken out of [spend], the bank included.
  int taken(AiSpend spend) =>
      spent(spend) + (spend == AiSpend.quiz ? bankedQuizzesUsedToday : 0);

  /// What [spend] has left today.
  int remaining(AiSpend spend, AiAllowance allowance) =>
      (limitFor(spend, allowance) - taken(spend)).clamp(0, 1 << 30);

  /// Whether one more [spend] is allowed right now.
  bool canSpend(AiSpend spend, AiAllowance allowance) =>
      remaining(spend, allowance) > 0;

  /// Today's own quota for [spend] — the allowance plus any ad quizzes, and
  /// nothing banked. What [spentToday] fills before the bank is touched.
  int _dailyQuota(AiSpend spend, AiAllowance allowance) =>
      allowance.limitFor(spend) +
      (spend == AiSpend.quiz ? bonusQuizzesToday : 0);

  /// This ledger with one [spend] recorded against it.
  ///
  /// Takes the allowance because the bank has to be drawn from last. Today's
  /// allowance and today's ad quizzes both expire tonight; the bank does not.
  /// Spending the expiring ones first is the only order that does not quietly
  /// turn a quiz that was about to vanish into a banked one — which is how a
  /// rewarded ad would otherwise become a permanent credit.
  AiUsageLedger recording(AiSpend spend, AiAllowance allowance) {
    final fromBank = spend == AiSpend.quiz &&
        bankedQuizzes > 0 &&
        spent(spend) >= _dailyQuota(spend, allowance);

    return AiUsageLedger(
      day: day,
      spentToday:
          fromBank ? spentToday : {...spentToday, spend: spent(spend) + 1},
      bonusQuizzesToday: bonusQuizzesToday,
      bankedQuizzes: fromBank ? bankedQuizzes - 1 : bankedQuizzes,
      bankedQuizzesUsedToday:
          fromBank ? bankedQuizzesUsedToday + 1 : bankedQuizzesUsedToday,
    );
  }

  /// This ledger with a rewarded ad's extra quizzes added.
  AiUsageLedger recordingRewardedQuiz() => AiUsageLedger(
        day: day,
        spentToday: spentToday,
        bonusQuizzesToday:
            bonusQuizzesToday + EntitlementConstants.quizzesPerRewardedAd,
        bankedQuizzes: bankedQuizzes,
        bankedQuizzesUsedToday: bankedQuizzesUsedToday,
      );

  /// This ledger advanced to [now]'s calendar day, clearing the day's spend
  /// if the day turned over.
  ///
  /// Same local-calendar rule as `UserProvider._rolloverGoldDayIfNeeded` and
  /// [AdLedger.rolledOver], so all the daily systems reset together — a player
  /// never sees their quizzes come back while the coin taper is still on
  /// yesterday's numbers.
  ///
  /// Bonus quizzes expire with the day too. An ad buys a quiz now, not a
  /// credit to hoard — which is exactly what [banking] hands out, and the
  /// reason the two are counted apart.
  ///
  /// [banking] is the allowance whose unused quizzes carry forward, or null
  /// for a tier that does not bank. Passed in rather than read off a
  /// membership flag, for the same reason the allowance itself is: this class
  /// holds no notion of which tier the player is on, so an upgrade takes
  /// effect at the next question instead of needing the stored ledger
  /// rewritten.
  AiUsageLedger rolledOver(DateTime now, {AiAllowance? banking}) {
    final current = day;
    final sameDay = current != null &&
        current.year == now.year &&
        current.month == now.month &&
        current.day == now.day;
    if (sameDay) return this;

    return AiUsageLedger(
      day: now,
      // A ledger with no day behind it carries its bank over untouched: there
      // is nothing to add, because there was no allowance to leave unspent.
      bankedQuizzes: current == null ? bankedQuizzes : _bankedAfter(banking),
    );
  }

  /// The bank once the day that was open has closed.
  int _bankedAfter(AiAllowance? banking) {
    if (banking == null) return bankedQuizzes;

    // What the closing day left on the table, and nothing for the days
    // between: a week away banks one day's leftovers, not seven days' worth.
    // Only the *allowance* banks, too — `spent` has already absorbed the
    // day's ad quizzes, so a day that ran on rewarded ads leaves nothing
    // behind it.
    final leftover =
        (banking.quizzes - spent(AiSpend.quiz)).clamp(0, banking.quizzes);

    return (bankedQuizzes + leftover)
        .clamp(0, EntitlementConstants.quizBankCap);
  }
}
