// Accessory catalog for the pet wardrobe.
//
// Each accessory belongs to a slot (one equipped per slot at a time):
//   - `hat`  : worn on the head (cap, top hat, cowboy hat, crown, party hat)
//   - `neck` : worn at the neck/chest (bow tie, necklace)
//   - `face` : worn on the face (mustache)
//
// The SVG assets are pre-positioned on the pet canvas (viewBox
// "-20 0 222 238") and re-pixelised to the pet's grid, so they overlay the
// pet layers directly with matching pixel/outline size.

class AccessorySlots {
  static const String hat = 'hat';
  static const String neck = 'neck';
  static const String face = 'face';

  /// Stable display order of the slots.
  /// Display labels are localized in the UI (l10n keys slotHat/slotNeck/slotFace).
  static const List<String> all = [hat, neck, face];
}

class AccessoryDef {
  final String id;
  final String name;
  final String slot;
  final String asset;

  const AccessoryDef({
    required this.id,
    required this.name,
    required this.slot,
    required this.asset,
  });
}

const List<AccessoryDef> kAccessories = [
  AccessoryDef(
      id: 'cap',
      name: 'Cap',
      slot: AccessorySlots.hat,
      asset: 'assets/svgs/acc_cap.svg'),
  AccessoryDef(
      id: 'tophat',
      name: 'Top Hat',
      slot: AccessorySlots.hat,
      asset: 'assets/svgs/acc_tophat.svg'),
  AccessoryDef(
      id: 'cowboyhat',
      name: 'Cowboy Hat',
      slot: AccessorySlots.hat,
      asset: 'assets/svgs/acc_cowboyhat.svg'),
  AccessoryDef(
      id: 'crown',
      name: 'Crown',
      slot: AccessorySlots.hat,
      asset: 'assets/svgs/acc_crown.svg'),
  AccessoryDef(
      id: 'partyhat',
      name: 'Party Hat',
      slot: AccessorySlots.hat,
      asset: 'assets/svgs/acc_partyhat.svg'),
  AccessoryDef(
      id: 'bowtie',
      name: 'Bow Tie',
      slot: AccessorySlots.neck,
      asset: 'assets/svgs/acc_bowtie.svg'),
  AccessoryDef(
      id: 'necklace',
      name: 'Necklace',
      slot: AccessorySlots.neck,
      asset: 'assets/svgs/acc_necklace.svg'),
  AccessoryDef(
      id: 'mustache',
      name: 'Mustache',
      slot: AccessorySlots.face,
      asset: 'assets/svgs/acc_mustache.svg'),
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
