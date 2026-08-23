/// Works out which coat and eye colours the player may wear, and what the
/// rest cost.
///
/// Pure, and kept out of [CharacterProvider] for the same reason the accessory
/// gating is (see `accessory_ownership.dart`): the price ladder is the part
/// most likely to be retuned, and retuning it should not mean touching a
/// provider or a widget.
library;

import '../constants/app_runtime_config.dart';
import 'pet_recolor.dart';

/// Why a swatch is or is not available.
enum SwatchAvailability {
  /// Wearable now: a natural colour, or one already bought.
  owned,

  /// Buyable with coins. Affordability is a separate question — see
  /// [SwatchStatus.affordable] — because a price the player cannot meet yet is
  /// still a goal.
  forSale,
}

/// One swatch as the wardrobe needs to render it.
class SwatchStatus {
  const SwatchStatus({
    required this.swatch,
    required this.availability,
    required this.affordable,
  });

  final PetSwatch swatch;
  final SwatchAvailability availability;

  /// Whether the player's balance covers [PetSwatch.price]. Always false when
  /// there is nothing to buy.
  final bool affordable;

  bool get isOwned => availability == SwatchAvailability.owned;
  bool get isForSale => availability == SwatchAvailability.forSale;

  /// True when a tap should open the buy confirmation.
  bool get canBuyNow => isForSale && affordable;
}

class ColorOwnership {
  ColorOwnership._();

  /// Whether [swatch] can be worn.
  ///
  /// Unlike accessories there is no bond-gated tier here: a colour is either
  /// free from the first launch or bought outright. Ownership is global rather
  /// than per pet — buying Ultraviolet buys the colour, not one cat's coat —
  /// so the same purchase dresses whichever pet is out.
  static bool isOwned(
    PetSwatch swatch, {
    required Set<String> unlockedItemIds,
  }) {
    // Debug-only testing override; see AppRuntimeConfig.unlockAllAccessories.
    if (AppRuntimeConfig.unlockAllAccessories) return true;
    if (swatch.isFree) return true;
    return unlockedItemIds.contains(swatch.id);
  }

  /// Whether a colour may be applied, addressed by the hex the design stores.
  ///
  /// A hex that is in no palette is allowed: legacy saves and hand-edited
  /// values keep working, and an update that retires a swatch can never leave
  /// a pet wearing a colour the app then refuses to let it keep.
  static bool isHexAllowed(
    String hex,
    List<PetSwatch> palette, {
    required Set<String> unlockedItemIds,
  }) {
    final swatch = swatchByHex(palette, hex);
    if (swatch == null) return true;
    return isOwned(swatch, unlockedItemIds: unlockedItemIds);
  }

  static SwatchStatus statusFor(
    PetSwatch swatch, {
    required Set<String> unlockedItemIds,
    required int coins,
  }) {
    if (isOwned(swatch, unlockedItemIds: unlockedItemIds)) {
      return SwatchStatus(
        swatch: swatch,
        availability: SwatchAvailability.owned,
        affordable: false,
      );
    }

    return SwatchStatus(
      swatch: swatch,
      availability: SwatchAvailability.forSale,
      // Price is non-null here: a free swatch is owned by the branch above.
      affordable: coins >= swatch.price!,
    );
  }

  /// Every swatch in [palette], in catalogue order.
  static List<SwatchStatus> statusesFor(
    List<PetSwatch> palette, {
    required Set<String> unlockedItemIds,
    required int coins,
  }) =>
      palette
          .map((s) => statusFor(
                s,
                unlockedItemIds: unlockedItemIds,
                coins: coins,
              ))
          .toList();
}
