/// Pure season-pass arithmetic: what a player owns, how far along a track they
/// are, and what is waiting to be claimed.
///
/// Kept out of the provider for the same reason [BondProgress] and
/// [GoldLedger] are — the numbers are the part most likely to be retuned, and
/// they should be tunable and testable without a widget in the way.
library;

import '../constants/season_pass.dart';

/// A pass the player has bought, and where they are on it.
///
/// Immutable. The record it describes is two numbers — the XP total at the
/// moment of purchase, and the highest tier claimed — which is deliberately
/// the smallest thing that can express "no expiry": nothing here can go stale,
/// and nothing has to be swept when a season ends.
class OwnedPass {
  const OwnedPass({
    required this.passId,
    required this.xpAtPurchase,
    this.claimedThroughTier = -1,
  });

  final String passId;

  /// `UserProvider.totalXP` at the moment the pass was bought.
  ///
  /// Storing the baseline rather than a running counter is what makes buying
  /// late cost nothing: progress is always "XP now minus XP then", so a player
  /// who buys on the last day of a season starts exactly where a first-day
  /// buyer did. It also means a long-time player cannot unlock a whole track
  /// instantly off a balance earned before the pass existed.
  final int xpAtPurchase;

  /// Highest tier index already handed over, or -1 when none has been.
  ///
  /// An index rather than a set: tiers are ordered and cumulative, so there is
  /// no way for this to describe a track with a hole in it.
  final int claimedThroughTier;

  OwnedPass copyWith({int? claimedThroughTier}) => OwnedPass(
        passId: passId,
        xpAtPurchase: xpAtPurchase,
        claimedThroughTier: claimedThroughTier ?? this.claimedThroughTier,
      );
}

/// One pass as a screen needs to draw it.
class PassProgress {
  const PassProgress({
    required this.pass,
    required this.owned,
    required this.xpSincePurchase,
  });

  final SeasonPassDef pass;
  final OwnedPass owned;

  /// XP earned since the pass was bought. Never negative — a total that has
  /// somehow gone backwards reads as no progress rather than as debt.
  final int xpSincePurchase;

  /// Highest tier the XP has reached, or -1 for none.
  int get reachedTierIndex => pass.reachedTierIndex(xpSincePurchase);

  /// Tiers reached but not yet handed over.
  ///
  /// The list a "claim" button acts on, and the reason nothing is lost by
  /// being away: an unclaimed tier simply stays here.
  List<int> get claimableTierIndexes => [
        for (var i = owned.claimedThroughTier + 1; i <= reachedTierIndex; i++) i,
      ];

  bool get hasClaimable => claimableTierIndexes.isNotEmpty;

  bool get isComplete => owned.claimedThroughTier >= pass.tiers.length - 1;

  /// XP still owed for the next unreached tier, or 0 at the end of the track.
  int get xpToNextTier {
    final next = reachedTierIndex + 1;
    if (next >= pass.tiers.length) return 0;
    final owed = pass.tiers[next].xpFromPurchase - xpSincePurchase;
    return owed > 0 ? owed : 0;
  }

  /// 0.0-1.0 across the current tier, so the bar moves every session rather
  /// than once a fortnight.
  double get tierProgress {
    final next = reachedTierIndex + 1;
    if (next >= pass.tiers.length) return 1.0;
    final floor =
        reachedTierIndex < 0 ? 0 : pass.tiers[reachedTierIndex].xpFromPurchase;
    final ceiling = pass.tiers[next].xpFromPurchase;
    final span = ceiling - floor;
    if (span <= 0) return 1.0;
    return ((xpSincePurchase - floor) / span).clamp(0.0, 1.0);
  }
}

class SeasonPassProgress {
  SeasonPassProgress._();

  /// Reads one owned pass against the player's XP.
  ///
  /// Returns null when the pass id is not in the catalogue — a record for a
  /// pass that no longer exists is ignored rather than crashing, though
  /// `seasonPasses` is append-only precisely so this should never happen.
  static PassProgress? progressFor(OwnedPass owned, {required int totalXP}) {
    final pass = seasonPassById(owned.passId);
    if (pass == null) return null;

    final since = totalXP - owned.xpAtPurchase;
    return PassProgress(
      pass: pass,
      owned: owned,
      xpSincePurchase: since > 0 ? since : 0,
    );
  }

  /// Every accessory the player has actually claimed across every pass.
  ///
  /// Claimed rather than reached, so a piece appears in the wardrobe when the
  /// player took it rather than the moment the XP crossed a line — the claim
  /// is the small ceremony the track is for.
  ///
  /// Scene tiers are not in here. A scene is owned the way every other world
  /// is — through `CharacterProvider`'s unlocked set, written when the tier is
  /// claimed — because the render path has to answer "which world am I
  /// painting" without a pass record in reach. See `CharacterProvider.
  /// grantScene`.
  static Set<String> claimedAccessoryIds(Iterable<OwnedPass> owned) =>
      _claimed(owned, (tier) => tier.accessoryId);

  /// Every scene the player has actually claimed across every pass.
  ///
  /// Not an ownership check — see the note above — but the answer to "what
  /// should already have been handed over", which is what re-grants a scene
  /// whose claim landed before the unlock could be written.
  static Set<String> claimedSceneIds(Iterable<OwnedPass> owned) =>
      _claimed(owned, (tier) => tier.sceneId);

  static Set<String> _claimed(
    Iterable<OwnedPass> owned,
    String? Function(SeasonPassTier) pick,
  ) {
    final ids = <String>{};
    for (final record in owned) {
      final pass = seasonPassById(record.passId);
      if (pass == null) continue;
      for (var i = 0; i <= record.claimedThroughTier; i++) {
        if (i >= pass.tiers.length) break;
        final id = pick(pass.tiers[i]);
        if (id != null) ids.add(id);
      }
    }
    return ids;
  }
}
