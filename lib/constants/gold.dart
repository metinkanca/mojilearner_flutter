/// The coin axis: what learning pays, and what stops it becoming a grind.
///
/// Coins are the *fast* half of the economy, the counterpart to the XP ledger
/// in `progression.dart`. XP measures whether the relationship grew — the
/// pet's bond stage is projected from it, see `bond.dart` — while coins
/// measure what the player may dress it in. Two rules keep them
/// from collapsing into each other:
///
/// * **Coins buy appearance, never survival.** The daily login reward hands
///   out food, not the money to buy it, so a pet's health is never in
///   competition with a hat. A player who is short of coins is short of
///   cosmetics — never short of the ability to look after the pet.
/// * **Coins come from doing the content.** Every repeatable source here is
///   something done in the target language. Logging in pays a token amount;
///   it is a greeting, not an income.
///
/// See [GoldConstants.fullRateDailyGold] for the third rule — the one that
/// stops a single long session from emptying the catalogue.
library;

/// A repeatable thing the player did that pays coins.
///
/// Deliberately parallel to the events that pay XP, and deliberately not
/// identical: there is no member for feeding, petting or logging in, because
/// those must not pay coins at all.
enum GoldSource {
  /// A finished quiz. See [GoldConstants] for why the payout barely moves
  /// with accuracy.
  quiz,

  /// Clearing a role-play scenario.
  scenario,

  /// One exchange with the pet in the target language.
  conversation,

  /// Reviewing one item from the queue.
  review,
}

class GoldConstants {
  GoldConstants._();

  /// Coins for one conversation exchange, and for one reviewed card.
  ///
  /// Small per unit and capped per day (see [conversationDailyCap] and
  /// [reviewDailyCap]), because both are unbounded actions. The point is not
  /// that they are lucrative — it is that the two activities closest to real
  /// language use should not pay literally nothing, which is what they did
  /// before.
  static const int conversation = 1;
  static const int review = 1;

  /// Daily ceilings for the two unbounded sources.
  ///
  /// Without these, a player typing "ok" a hundred times out-earns one who
  /// actually sat a quiz, and every one of those messages costs a model call.
  /// The caps sit at roughly what an engaged session produces anyway, so a
  /// real conversation never notices them.
  static const int conversationDailyCap = 15;
  static const int reviewDailyCap = 10;

  /// Learning *earned* in a day — before the taper — is paid in full up to
  /// this much, at [halfRate] up to [halfRateDailyGold], and at [tailRate]
  /// beyond. The bands are measured in pre-taper coins, so "the first 100
  /// coins' worth of learning each day pay in full" is literally what the
  /// arithmetic does.
  ///
  /// Without it the fastest route to the whole catalogue is one long grinding
  /// session rather than a habit. A hard cap was the wrong shape — hitting a
  /// wall mid-session tells the player to stop studying — so the rate tapers
  /// instead. Play as long as you like; the tenth quiz of the day is simply
  /// worth less than the first.
  ///
  /// Note this taper is on coins only. XP is uncapped, so grinding does move
  /// the pet's bond stage; it just does not fund the wardrobe any faster.
  ///
  /// A normal session lands inside the full band. Reaching the tail takes
  /// roughly seven quizzes plus a capped-out day of chat and review.
  static const int fullRateDailyGold = 100;
  static const int halfRateDailyGold = 200;
  static const double halfRate = 0.5;
  static const double tailRate = 0.25;

  /// The share of a quiz payout kept when the questions were not drawn from
  /// the due review queue — a repeat of the stock set, or a set built after
  /// the queue ran dry.
  ///
  /// The spaced-repetition schedule already decides how much there is to
  /// usefully study today. Paying repeats at a fraction lets that schedule
  /// pace the economy too, instead of the player's patience for tapping
  /// through the same five questions.
  static const double repeatQuizRate = 0.4;

  /// Per-day ceiling for [source], or null when the source is not capped
  /// (quizzes and scenarios are bounded by the taper instead).
  static int? dailyCapFor(GoldSource source) => switch (source) {
        GoldSource.conversation => conversationDailyCap,
        GoldSource.review => reviewDailyCap,
        GoldSource.quiz || GoldSource.scenario => null,
      };
}

/// What one payout is worth once the caps and the taper have had their say.
class GoldAward {
  const GoldAward({required this.paid, required this.raw});

  /// Coins to actually add to the balance.
  final int paid;

  /// Coins the sources were worth before the taper, which is what the day's
  /// ledger advances by. Callers rarely need this; [GoldLedger.recording]
  /// does.
  final int raw;

  /// True when the taper or a source cap took something off. The UI uses this
  /// to explain a payout that is smaller than the player expects, rather than
  /// leaving it looking like a bug.
  bool get wasReduced => paid < raw;

  static const GoldAward none = GoldAward(paid: 0, raw: 0);
}

/// One day's coin earnings, and the arithmetic that shapes them.
///
/// Immutable and pure so the curve can be tested and retuned without a
/// provider in the way — the same split the bond and ownership rules use.
/// Both tallies count *pre-taper* coins, so the bands and the source caps are
/// measured in the same units the catalogue prices are quoted in.
class GoldLedger {
  const GoldLedger({
    this.rawEarnedToday = 0,
    this.rawPerSourceToday = const {},
  });

  /// Pre-taper coins earned today, which is where the taper bands are read.
  final int rawEarnedToday;

  /// Pre-taper coins earned today per source, for the capped sources.
  final Map<GoldSource, int> rawPerSourceToday;

  int rawEarnedFrom(GoldSource source) => rawPerSourceToday[source] ?? 0;

  /// What [source] still has left today, or null when it is uncapped.
  int? remainingFor(GoldSource source) {
    final cap = GoldConstants.dailyCapFor(source);
    if (cap == null) return null;
    return (cap - rawEarnedFrom(source)).clamp(0, cap);
  }

  /// What [raw] coins from [source] are actually worth right now.
  ///
  /// The per-source daily cap applies first — a capped-out source pays
  /// nothing and does not consume taper bands on the way — then the taper,
  /// band by band, so a payout straddling a boundary is split across the two
  /// rates rather than charged entirely to whichever band it started in.
  GoldAward award(int raw, GoldSource source) {
    if (raw <= 0) return GoldAward.none;

    final remaining = remainingFor(source);
    final allowed = remaining == null ? raw : raw.clamp(0, remaining);
    if (allowed <= 0) return GoldAward.none;

    const bands = <(int?, double)>[
      (GoldConstants.fullRateDailyGold, 1.0),
      (GoldConstants.halfRateDailyGold, GoldConstants.halfRate),
      (null, GoldConstants.tailRate),
    ];

    var paid = 0.0;
    var position = rawEarnedToday;
    var left = allowed;

    for (final (limit, rate) in bands) {
      if (left <= 0) break;
      final room = limit == null ? left : (limit - position).clamp(0, left);
      if (room <= 0) continue;
      paid += room * rate;
      position += room;
      left -= room;
    }

    // Round rather than floor, and never below one coin: a taper should shade
    // a reward, not tell a player who is still studying that the work just
    // stopped counting. At the tail rate a one-coin message would otherwise
    // round to nothing, which reads as a bug rather than as a taper.
    return GoldAward(paid: paid.round().clamp(1, allowed), raw: allowed);
  }

  /// This ledger with [award] recorded against it.
  GoldLedger recording(GoldAward award, GoldSource source) {
    if (award.raw <= 0) return this;
    final cap = GoldConstants.dailyCapFor(source);
    return GoldLedger(
      rawEarnedToday: rawEarnedToday + award.raw,
      rawPerSourceToday: cap == null
          ? rawPerSourceToday
          : {...rawPerSourceToday, source: rawEarnedFrom(source) + award.raw},
    );
  }
}
