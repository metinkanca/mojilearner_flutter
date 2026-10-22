// Accessory catalog for the pet wardrobe.
//
// Each accessory belongs to a slot (one equipped per slot at a time):
//   - `hat`  : worn on the head (cap, top hat, cowboy hat, crown, party hat)
//   - `neck` : worn at the neck/chest (bow tie, necklace)
//   - `face` : worn on the face (mustache)
//
// The SVG assets are pre-positioned on the pet canvas (viewBox
// "-20 -90 222 328") and drawn on the pet's own 7-unit grid, so they overlay
// the pet layers directly with matching pixel/outline size.

import 'bond.dart';
import 'season_pass.dart';

/// A palette variant of another accessory.
///
/// The season pass needs roughly ten pieces every two months against a
/// catalogue that took the whole project to reach twenty, and every new shape
/// is two or three drawings — cat, bird, icon — plus a measured dog placement.
/// Recolouring is what makes that cadence possible: one drawing plus a list of
/// fills is several tiers, and the variants inherit the source's placements
/// and its bird cut for free, because they *are* the source's art.
///
/// The same trick as `utils/pet_recolor.dart`, which recolours the coat by
/// substituting flat fills. The difference is that the coat's source fills are
/// constants — every pet is drawn from one palette — while an accessory is
/// drawn in whatever colours suited it, so each variant names the swaps it
/// makes. Explicit rather than inferred: a hat with three fills where only two
/// should move is common, and guessing which is which from the art would be a
/// rule that silently mis-tints half the catalogue.
class AccessoryRecolor {
  const AccessoryRecolor({required this.sourceId, required this.fills});

  /// Id of the accessory whose art this borrows — its pet cut, its bird cut,
  /// its icon and its dog placement.
  final String sourceId;

  /// Source fill to replacement fill, both `#RRGGBB`.
  ///
  /// The outline (`kOutlineFill`) is deliberately never a key here: every pet
  /// and every accessory shares one outline colour, and letting a variant move
  /// it would put a piece on the pet drawn in a different ink from the animal
  /// wearing it.
  final Map<String, String> fills;
}

class AccessorySlots {
  static const String hat = 'hat';
  static const String neck = 'neck';
  static const String face = 'face';

  /// Stable display order of the slots.
  /// Display labels are localized in the UI (l10n keys slotHat/slotNeck/slotFace).
  static const List<String> all = [hat, neck, face];
}

/// How an accessory is come by.
///
/// Exactly one of [price], [requiredStage] and [requiredPass] is set, or none:
///
/// * none — a free starter, owned from the first launch so the wardrobe is
///   never an empty room with a lock on every shelf.
/// * [price] — bought with coins. This is what coins are *for*; food is upkeep
///   and backgrounds are a one-off, so without these the currency runs out of
///   things to want.
/// * [requiredStage] — earned by reaching a bond stage, and deliberately not
///   purchasable at any price. These are the pieces that have to read as
///   earned rather than afforded, which is only true if money cannot get them.
/// * [requiredPass] — on a season pass track, claimed by studying after buying
///   it. Never priced in coins, so the coin shop stays a complete thing to
///   save towards, and never gated on a bond stage, so nothing bought can sit
///   on the ladder that is supposed to be earned.
///
/// Those three are the whole vocabulary, and keeping them mutually exclusive
/// is what lets the wardrobe answer "why can I not wear this" with one
/// sentence instead of a list of conditions.
class AccessoryDef {
  final String id;
  final String name;
  final String slot;
  final String asset;

  /// Emoji shown on the shop card. Purchasable accessories appear in the shop
  /// alongside food and backgrounds, which render icons as emoji.
  final String icon;

  /// Coin cost, or null when this one is not for sale.
  final int? price;

  /// Bond stage that unlocks it, or null when bond is not what gates it.
  final PetStage? requiredStage;

  /// Id of the season pass whose track carries this piece, or null when it is
  /// not pass content. See `constants/season_pass.dart`.
  final String? requiredPass;

  /// The piece this one is a palette variant of, or null when it has art of
  /// its own. See [AccessoryRecolor].
  final AccessoryRecolor? recolor;

  /// Kept out of the wardrobe and the shop while its art is being reworked.
  ///
  /// Withheld rather than deleted: [accessoryById] still resolves it, so a pet
  /// already wearing one goes on wearing it instead of being quietly stripped
  /// by the catalogue sweep in `CharacterProvider._sanitizeDesign`. Deleting
  /// the entry is what removing a piece for good looks like.
  final bool hidden;

  const AccessoryDef({
    required this.id,
    required this.name,
    required this.slot,
    required this.asset,
    required this.icon,
    this.price,
    this.requiredStage,
    this.requiredPass,
    this.recolor,
    this.hidden = false,
  })  : assert(price == null || requiredStage == null,
            'an accessory is either bought or earned, never both'),
        assert(requiredPass == null || price == null,
            'pass content is never also for sale with coins'),
        assert(requiredPass == null || requiredStage == null,
            'pass content is never also gated on a bond stage');

  /// True when nothing gates it — see the class doc.
  ///
  /// [requiredPass] has to be in here, not just the other two. A pass piece
  /// carries no price and no stage, so without it every season-pass cosmetic
  /// answers "free starter" and `AccessoryOwnership.isOwned` — which asks this
  /// before it asks about the pass — hands the whole track over to everybody.
  bool get isFreeStarter =>
      price == null && requiredStage == null && requiredPass == null;
}

// Prices sit against the rest of the economy: a solid day of quizzes pays
// roughly 40-60 coins, food upkeep eats some of that, and backgrounds cost
// 100-200. So a cheap accessory is a couple of days of play and the dearest is
// most of a week — long enough to be a goal, short enough to stay one.
const List<AccessoryDef> kAccessories = [
  AccessoryDef(
    id: 'cap',
    name: 'Cap',
    slot: AccessorySlots.hat,
    asset: 'assets/svgs/acc_cap.svg',
    icon: '🧢',
  ),
  AccessoryDef(
    id: 'tophat',
    name: 'Top Hat',
    slot: AccessorySlots.hat,
    asset: 'assets/svgs/acc_tophat.svg',
    icon: '🎩',
    requiredStage: PetStage.attached,
  ),
  AccessoryDef(
    id: 'cowboyhat',
    name: 'Cowboy Hat',
    slot: AccessorySlots.hat,
    asset: 'assets/svgs/acc_cowboyhat.svg',
    icon: '🤠',
    price: 120,
  ),
  AccessoryDef(
    id: 'crown',
    name: 'Crown',
    slot: AccessorySlots.hat,
    asset: 'assets/svgs/acc_crown.svg',
    icon: '👑',
    requiredStage: PetStage.devoted,
  ),
  AccessoryDef(
    id: 'partyhat',
    name: 'Party Hat',
    slot: AccessorySlots.hat,
    asset: 'assets/svgs/acc_partyhat.svg',
    icon: '🥳',
    price: 80,
  ),
  AccessoryDef(
    id: 'bowtie',
    name: 'Bow Tie',
    slot: AccessorySlots.neck,
    asset: 'assets/svgs/acc_bowtie.svg',
    icon: '🎀',
    price: 60,
  ),
  AccessoryDef(
    id: 'necklace',
    name: 'Necklace',
    slot: AccessorySlots.neck,
    asset: 'assets/svgs/acc_necklace.svg',
    icon: '📿',
    price: 150,
    hidden: true,
  ),
  AccessoryDef(
    id: 'mustache',
    name: 'Mustache',
    slot: AccessorySlots.face,
    asset: 'assets/svgs/acc_mustache.svg',
    icon: '🥸',
    price: 90,
    hidden: true,
  ),
  AccessoryDef(
    id: 'beanie',
    name: 'Beanie',
    slot: AccessorySlots.hat,
    asset: 'assets/svgs/acc_beanie.svg',
    icon: '🧶',
    price: 70,
  ),
  AccessoryDef(
    id: 'mortarboard',
    name: 'Graduation Cap',
    slot: AccessorySlots.hat,
    asset: 'assets/svgs/acc_mortarboard.svg',
    icon: '🎓',
    requiredStage: PetStage.inseparable,
  ),
  AccessoryDef(
    id: 'collar',
    name: 'Bell Collar',
    slot: AccessorySlots.neck,
    asset: 'assets/svgs/acc_collar.svg',
    icon: '🔔',
    price: 90,
  ),
  AccessoryDef(
    id: 'glasses',
    name: 'Glasses',
    slot: AccessorySlots.face,
    asset: 'assets/svgs/acc_glasses.svg',
    icon: '👓',
    price: 110,
  ),

  AccessoryDef(
    id: 'sunglasses',
    name: 'Sunglasses',
    slot: AccessorySlots.face,
    asset: 'assets/svgs/acc_sunglasses.svg',
    icon: '🕶',
    price: 100,
  ),
  AccessoryDef(
    id: 'mask',
    name: 'Masquerade Mask',
    slot: AccessorySlots.face,
    asset: 'assets/svgs/acc_mask.svg',
    icon: '🎭',
    price: 140,
  ),
  AccessoryDef(
    id: 'medal',
    name: 'Medal',
    slot: AccessorySlots.neck,
    asset: 'assets/svgs/acc_medal.svg',
    icon: '🏅',
    requiredStage: PetStage.friendly,
  ),
  AccessoryDef(
    id: 'scarf',
    name: 'Scarf',
    slot: AccessorySlots.neck,
    asset: 'assets/svgs/acc_scarf.svg',
    icon: '🧣',
    price: 80,
    hidden: true,
  ),
  AccessoryDef(
    id: 'headphones',
    name: 'Headphones',
    slot: AccessorySlots.hat,
    asset: 'assets/svgs/acc_headphones.svg',
    icon: '🎧',
    price: 150,
  ),
  AccessoryDef(
    id: 'wizardhat',
    name: 'Wizard Hat',
    slot: AccessorySlots.hat,
    asset: 'assets/svgs/acc_wizardhat.svg',
    icon: '🧙',
    price: 170,
  ),
  AccessoryDef(
    id: 'flowercrown',
    name: 'Flower Crown',
    slot: AccessorySlots.hat,
    asset: 'assets/svgs/acc_flowercrown.svg',
    icon: '🌸',
    price: 120,
  ),

  // ---------------------------------------------------------------------
  // Season one — First Flight. Track and reasoning in SEASON_PASS.md.
  //
  // Four new shapes, grid-authored by art_src/gen_pass_acc.py, and six
  // palette variants that carry no art of their own: a variant borrows its
  // source's pet cut, bird cut, icon and dog placement and swaps fills at
  // render time, so the whole track costs twelve files rather than thirty.
  //
  // Three of the variants recolour pieces that are already on sale for coins
  // (scarf, beanie, cowboy hat). None recolours a bond-gated piece — a
  // recognisable crimson top hat, sold, is exactly the lane confusion
  // `passLocked` exists to prevent.
  // ---------------------------------------------------------------------
  AccessoryDef(
    id: 'bandana',
    name: 'Sunrise Bandana',
    slot: AccessorySlots.neck,
    asset: 'assets/svgs/acc_bandana.svg',
    icon: '🔻',
    requiredPass: kSeasonOneId,
  ),
  AccessoryDef(
    id: 'bandana_cloud',
    name: 'Cloud Bandana',
    slot: AccessorySlots.neck,
    asset: 'assets/svgs/acc_bandana.svg',
    icon: '🔻',
    requiredPass: kSeasonOneId,
    recolor: AccessoryRecolor(
      sourceId: 'bandana',
      fills: {'#e3664f': '#efeae1'},
    ),
  ),
  AccessoryDef(
    id: 'scarf_dusk',
    name: 'Dusk Scarf',
    slot: AccessorySlots.neck,
    asset: 'assets/svgs/acc_scarf.svg',
    icon: '🧣',
    requiredPass: kSeasonOneId,
    recolor: AccessoryRecolor(
      sourceId: 'scarf',
      fills: {'#4e95a3': '#1a3340', '#94d1d5': '#efeae1'},
    ),
  ),
  AccessoryDef(
    id: 'goggles',
    name: 'Flight Goggles',
    slot: AccessorySlots.face,
    asset: 'assets/svgs/acc_goggles.svg',
    icon: '🥽',
    requiredPass: kSeasonOneId,
  ),
  AccessoryDef(
    id: 'goggles_brass',
    name: 'Brass Goggles',
    slot: AccessorySlots.face,
    asset: 'assets/svgs/acc_goggles.svg',
    icon: '🥽',
    requiredPass: kSeasonOneId,
    recolor: AccessoryRecolor(
      sourceId: 'goggles',
      fills: {'#1a3340': '#7b4b36', '#727072': '#f8b230'},
    ),
  ),
  // Deliberately the same swap as the scarf above: recoloured to one palette
  // two rungs apart, they land as a matched set rather than two unrelated
  // tints.
  AccessoryDef(
    id: 'beanie_dusk',
    name: 'Dusk Beanie',
    slot: AccessorySlots.hat,
    asset: 'assets/svgs/acc_beanie.svg',
    icon: '🧶',
    requiredPass: kSeasonOneId,
    recolor: AccessoryRecolor(
      sourceId: 'beanie',
      fills: {'#4e95a3': '#1a3340', '#94d1d5': '#efeae1'},
    ),
  ),
  AccessoryDef(
    id: 'flightcap',
    name: 'Flight Cap',
    slot: AccessorySlots.hat,
    asset: 'assets/svgs/acc_flightcap.svg',
    icon: '🪖',
    requiredPass: kSeasonOneId,
  ),
  // Leather becomes cream and the cream band becomes navy — the inverse of
  // the source, not a tint of it. Safe because `recolorAccessory` reads each
  // fill once and maps it once, so the newly written cream is not then caught
  // by the cream entry and turned navy along with the band.
  AccessoryDef(
    id: 'flightcap_cloud',
    name: 'Cloud Flight Cap',
    slot: AccessorySlots.hat,
    asset: 'assets/svgs/acc_flightcap.svg',
    icon: '🪖',
    requiredPass: kSeasonOneId,
    recolor: AccessoryRecolor(
      sourceId: 'flightcap',
      fills: {'#7b4b36': '#efeae1', '#efeae1': '#1a3340'},
    ),
  ),
  // The greys are the top hat's `#242e38` and its band `#727072`, not the
  // mortarboard's `#4a5668`: the latter is blue enough that the hat reads as
  // navy rather than charcoal, and the track has navy pieces already.
  AccessoryDef(
    id: 'cowboyhat_charcoal',
    name: 'Charcoal Cowboy Hat',
    slot: AccessorySlots.hat,
    asset: 'assets/svgs/acc_cowboyhat.svg',
    icon: '🤠',
    requiredPass: kSeasonOneId,
    recolor: AccessoryRecolor(
      sourceId: 'cowboyhat',
      fills: {'#492b21': '#242e38', '#7b4b36': '#727072'},
    ),
  ),
  AccessoryDef(
    id: 'flightscarf',
    name: 'Windswept Scarf',
    slot: AccessorySlots.neck,
    asset: 'assets/svgs/acc_flightscarf.svg',
    icon: '🎏',
    requiredPass: kSeasonOneId,
  ),

  // ---------------------------------------------------------------------
  // Season two — Witching Hour. Track and reasoning in HALLOWEEN_PASS.md.
  //
  // The four new shapes only; the recolours and the track itself wait for the
  // event-pass model. None of these is on a tier yet, so they are pass-locked
  // for everyone, and `UNLOCK_ALL_ACCESSORIES` is how to see them on a pet.
  //
  // Unlike the pieces above these were fitted straight onto the reworked cat
  // (art_src/gen_halloween_acc.py, off the owner's pixel-art PNGs) and shipped
  // shifted back by the cat's slot offset, so the cat's own offset lands them
  // where they were fitted and every other pet derives its seat as usual.
  // `test/unit/halloween_accessories_test.dart` pins that coupling.
  // ---------------------------------------------------------------------
  AccessoryDef(
    id: 'pumpkinwitch',
    name: 'Pumpkin Witch Hat',
    slot: AccessorySlots.hat,
    asset: 'assets/svgs/acc_pumpkinwitch.svg',
    icon: '🎃',
    requiredPass: kSeasonTwoId,
  ),
  AccessoryDef(
    id: 'devilband',
    name: 'Devil-Horn Headband',
    slot: AccessorySlots.hat,
    asset: 'assets/svgs/acc_devilband.svg',
    icon: '😈',
    requiredPass: kSeasonTwoId,
  ),
  AccessoryDef(
    id: 'ghostbandana',
    name: 'Ghost Bandana',
    slot: AccessorySlots.neck,
    asset: 'assets/svgs/acc_ghostbandana.svg',
    icon: '👻',
    requiredPass: kSeasonTwoId,
  ),
  AccessoryDef(
    id: 'batchoker',
    name: 'Bat Choker',
    slot: AccessorySlots.neck,
    asset: 'assets/svgs/acc_batchoker.svg',
    icon: '🦇',
    requiredPass: kSeasonTwoId,
  ),
];

AccessoryDef? accessoryById(String? id) {
  if (id == null) return null;
  for (final a in kAccessories) {
    if (a.id == id) return a;
  }
  return null;
}

/// The accessories a player can be shown — everything but the withheld ones.
///
/// [kAccessories] stays the full set so that ids already in a saved design or
/// a purchase history still resolve; this is what the wardrobe and the shop
/// are built from.
final List<AccessoryDef> visibleAccessories =
    kAccessories.where((a) => !a.hidden).toList(growable: false);

List<AccessoryDef> accessoriesForSlot(String slot) =>
    visibleAccessories.where((a) => a.slot == slot).toList();
