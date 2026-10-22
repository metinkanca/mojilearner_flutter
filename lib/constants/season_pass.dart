/// The season pass: a track of cosmetics, bought once and worked through.
///
/// Deliberately *not* a battle pass, and the difference is the expiry. A
/// normal pass says finish inside the season or lose what you paid for, which
/// is a charge for being away — and `bond.dart` already settled the app's
/// position on that: "absence in a language app is usually life getting in the
/// way, and charging for it is how people decide not to come back at all".
/// `PetWarmth` costs the player nothing for exactly that reason, and selling
/// the violation of it would be the same mistake with a price on it.
///
/// So three rules replace the season deadline:
///
/// * **Progress is measured from the purchase, not from a calendar.** A tier
///   is owed XP earned *since this pass was bought*, so buying on the last day
///   of a season is worth exactly what buying on the first day was.
/// * **Nothing expires.** A tier reached stays reached and a tier not yet
///   reached stays reachable. Someone who lapses for a month comes back to
///   something waiting rather than something wasted.
/// * **A season governs what is on sale, never what is still claimable.** New
///   passes are new content, not a reason the old one stopped working.
///
/// What this costs, and it is the real constraint: the whole accessory
/// catalogue is twenty pieces. A ten-tier pass every two months is sixty a
/// year, three times the catalogue annually. `utils/pet_recolor.dart` already
/// recolours SVGs by fill substitution, and the same trick applies to
/// accessories — so a track is a few new shapes plus palette variants of them
/// rather than ten separate drawings.
library;

import 'scenes.dart';

/// Season one's id.
///
/// Named rather than written as a literal wherever it is needed: the
/// catalogue tags ten accessories with it, and a typo in any one of them is
/// a piece belonging to a pass that does not exist, which `statusFor`
/// reports as pass-locked forever rather than as an error.
const String kSeasonOneId = 'season-1';

/// Season two's id. Accessories tagged for this pass use it, the way the first
/// ten pieces use [kSeasonOneId]. Four are tagged and drawn (see
/// HALLOWEEN_PASS.md), none is on a tier yet.
const String kSeasonTwoId = 'season-2';

/// One rung of a pass track.
///
/// A tier carries exactly one thing, and there are two kinds it can be: an
/// accessory, which is what nine rungs in ten are, or a scene. Two
/// constructors rather than a kind flag, so a tier cannot be written that
/// carries both or neither.
class SeasonPassTier {
  const SeasonPassTier({
    required this.xpFromPurchase,
    required String this.accessoryId,
  }) : sceneId = null;

  /// A tier that hands over a world instead of a thing to wear.
  ///
  /// Reserved for the end of a track. A scene is the largest single piece of
  /// art a season has and it changes every screen the pet appears on, which
  /// makes it a finale and a poor tier three.
  const SeasonPassTier.scene({
    required this.xpFromPurchase,
    required String this.sceneId,
  }) : accessoryId = null;

  /// XP the player must earn *after buying the pass* to reach this tier.
  ///
  /// Measured from purchase rather than from a total, so a long-time player
  /// with a large XP balance does not unlock a whole track the moment they
  /// buy it — and a brand-new one is not starting from behind.
  final int xpFromPurchase;

  /// The accessory this tier hands over, or null on a scene tier. Pass pieces
  /// are never for sale with coins and never gated on a bond stage; see
  /// [seasonPasses].
  final String? accessoryId;

  /// The scene this tier hands over, or null on an accessory tier. A pass
  /// scene is in `kSceneThemes` like every other world, but in neither the
  /// shop catalogue nor the level ladder.
  final String? sceneId;

  /// Whether this rung is a world rather than a thing to wear.
  bool get isScene => sceneId != null;

  /// The id of whatever this tier hands over, whichever kind it is. For the
  /// places that only need to tell one tier from another.
  String get itemId => accessoryId ?? sceneId!;
}

/// One pass, as sold.
class SeasonPassDef {
  const SeasonPassDef({
    required this.id,
    required this.name,
    required this.productId,
    required this.tiers,
  });

  /// Stable id, used in storage and on the accessory that belongs to it.
  /// Never reused, because a claimed tier is recorded against it forever.
  final String id;

  final String name;

  /// Store product id. A non-consumable rather than a subscription: a pass is
  /// bought once and owned, and it has no renewal to manage.
  final String productId;

  /// The track, in order. [SeasonPassTier.xpFromPurchase] must increase.
  final List<SeasonPassTier> tiers;

  /// Total XP to finish the track.
  int get xpToComplete => tiers.isEmpty ? 0 : tiers.last.xpFromPurchase;

  /// Every accessory this pass can hand out. Scene tiers are not in here —
  /// see [sceneIds].
  List<String> get accessoryIds =>
      [for (final t in tiers) if (t.accessoryId != null) t.accessoryId!];

  /// Every scene this pass can hand out.
  List<String> get sceneIds =>
      [for (final t in tiers) if (t.sceneId != null) t.sceneId!];

  /// Highest tier index reached with [xpSincePurchase], or -1 for none.
  ///
  /// An index rather than a set: tiers are ordered and cumulative, so "how far
  /// along" is one number and there is no way for the record to describe a
  /// track with a hole in it.
  int reachedTierIndex(int xpSincePurchase) {
    var reached = -1;
    for (var i = 0; i < tiers.length; i++) {
      if (xpSincePurchase < tiers[i].xpFromPurchase) break;
      reached = i;
    }
    return reached;
  }
}

/// Evenly spaced rungs.
///
/// 500 XP a rung: ten wearable tiers and a scene at the end, so 5,500 for the
/// full track. Against the curve in `progression.dart` — which paces a
/// committed daily learner at roughly 184 XP a day — that is about a month of
/// real use, and no time at all for someone who studies less. Which is the
/// point: the number is a pace, not a deadline.
const int _kTierXP = 500;

List<SeasonPassTier> _evenTrack(List<String> accessoryIds) => [
      for (var i = 0; i < accessoryIds.length; i++)
        SeasonPassTier(
          xpFromPurchase: _kTierXP * (i + 1),
          accessoryId: accessoryIds[i],
        ),
    ];

/// Every pass ever sold, oldest first.
///
/// Entries are never removed. A player who bought season one still owns its
/// track and may still be working through it, and a pass that vanished from
/// this list would take their unclaimed tiers with it — which is the expiry
/// this design exists to avoid. Whether a pass is still *on sale* is a
/// question for the store, not for this list.
///
/// Tiers are written out rather than built with [seasonPassTrack] because this
/// list is `const` and that helper is not. Spelling the numbers out also puts
/// the spacing where a reader looks for it.
const List<SeasonPassDef> seasonPasses = [
  // First Flight. New shapes land on tiers 1, 4, 7 and 10 — one every third
  // rung, so no three recolours run together and the first claim is an object
  // rather than a tint. See SEASON_PASS.md for the theme and the art notes.
  SeasonPassDef(
    id: kSeasonOneId,
    name: 'First Flight',
    productId: 'com.mimikin.app.pass.season1',
    tiers: [
      SeasonPassTier(xpFromPurchase: 500, accessoryId: 'bandana'),
      SeasonPassTier(xpFromPurchase: 1000, accessoryId: 'bandana_cloud'),
      SeasonPassTier(xpFromPurchase: 1500, accessoryId: 'scarf_dusk'),
      SeasonPassTier(xpFromPurchase: 2000, accessoryId: 'goggles'),
      SeasonPassTier(xpFromPurchase: 2500, accessoryId: 'goggles_brass'),
      SeasonPassTier(xpFromPurchase: 3000, accessoryId: 'beanie_dusk'),
      SeasonPassTier(xpFromPurchase: 3500, accessoryId: 'flightcap'),
      SeasonPassTier(xpFromPurchase: 4000, accessoryId: 'flightcap_cloud'),
      SeasonPassTier(xpFromPurchase: 4500, accessoryId: 'cowboyhat_charcoal'),
      SeasonPassTier(xpFromPurchase: 5000, accessoryId: 'flightscarf'),
      // The finale, and the only tier on any track that is not something to
      // wear. Ten rungs dress the pet for a departure; this one is the
      // departure. See `constants/scenes.dart` for the world itself, and
      // SEASON_PASS.md for why a *new* scene may be pass content when the
      // level ladder's three may not.
      SeasonPassTier.scene(xpFromPurchase: 5500, sceneId: kAirfieldSceneId),
    ],
  ),
  // Witching Hour. A placeholder season: the world is drawn and wired, the ten
  // pieces that will lead up to it are not, and there is no store listing, so
  // the pass screen says "not on sale yet" and nothing can be bought.
  //
  // The world sits at 5,500 XP, where the finale of an eleven-rung track
  // belongs, so that the ten rungs can be added in front of it later without
  // moving it. They would shift its index, and a claim is recorded as an index
  // (`claimedThroughTier`): that is safe only while the pass cannot be bought,
  // so put the pieces in before the listing exists, not after. The name is
  // not final and is shown as written; it is a mood and not a date on purpose,
  // see "No dated holidays" in SEASON_PASS.md.
  SeasonPassDef(
    id: kSeasonTwoId,
    name: 'Witching Hour',
    productId: 'com.mimikin.app.pass.season2',
    tiers: [
      SeasonPassTier.scene(
        xpFromPurchase: 5500,
        sceneId: kPumpkinPatchSceneId,
      ),
    ],
  ),
];

/// Looks up a pass by id, or null when it is not in the catalogue.
SeasonPassDef? seasonPassById(String? id) {
  if (id == null) return null;
  for (final pass in seasonPasses) {
    if (pass.id == id) return pass;
  }
  return null;
}

/// Builds an evenly-spaced track. Exposed for the season definitions above and
/// for tests, so the spacing rule lives in one place.
List<SeasonPassTier> seasonPassTrack(List<String> accessoryIds) =>
    _evenTrack(accessoryIds);

/// The pass whose track carries the scene [sceneId], or null when no pass
/// does.
///
/// The wardrobe's answer to "why can I see this world and not buy it": it
/// names the pass on the tile rather than showing an empty price.
SeasonPassDef? seasonPassForScene(String sceneId) {
  for (final pass in seasonPasses) {
    if (pass.sceneIds.contains(sceneId)) return pass;
  }
  return null;
}
