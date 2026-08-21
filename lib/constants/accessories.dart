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
/// Exactly one of [price] and [requiredStage] is set, or neither:
///
/// * neither — a free starter, owned from the first launch so the wardrobe is
///   never an empty room with a lock on every shelf.
/// * [price] — bought with coins. This is what coins are *for*; food is upkeep
///   and backgrounds are a one-off, so without these the currency runs out of
///   things to want.
/// * [requiredStage] — earned by reaching a bond stage, and deliberately not
///   purchasable at any price. These are the pieces that have to read as
///   earned rather than afforded, which is only true if money cannot get them.
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

  const AccessoryDef({
    required this.id,
    required this.name,
    required this.slot,
    required this.asset,
    required this.icon,
    this.price,
    this.requiredStage,
  }) : assert(price == null || requiredStage == null,
            'an accessory is either bought or earned, never both');

  /// True when nothing gates it — see the class doc.
  bool get isFreeStarter => price == null && requiredStage == null;
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
  ),
  AccessoryDef(
    id: 'mustache',
    name: 'Mustache',
    slot: AccessorySlots.face,
    asset: 'assets/svgs/acc_mustache.svg',
    icon: '🥸',
    price: 90,
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
  AccessoryDef(
    id: 'devilhorns',
    name: 'Devil Horns',
    slot: AccessorySlots.hat,
    asset: 'assets/svgs/acc_devilhorns.svg',
    icon: '😈',
    price: 110,
  ),
];

AccessoryDef? accessoryById(String? id) {
  if (id == null) return null;
  for (final a in kAccessories) {
    if (a.id == id) return a;
  }
  return null;
}

List<AccessoryDef> accessoriesForSlot(String slot) =>
    kAccessories.where((a) => a.slot == slot).toList();
