/// Works out what the player may wear, and what they have to do about the
/// rest.
///
/// Pure, and kept out of [CharacterProvider] for the same reason the bond
/// arithmetic is: the gating rules are the part most likely to be retuned, and
/// they should be tunable without a provider or a widget in the way.
library;

import '../constants/accessories.dart';
import '../constants/app_runtime_config.dart';
import '../constants/bond.dart';

/// Why an accessory is or is not available.
enum AccessoryAvailability {
  /// Wearable now.
  owned,

  /// Buyable with coins. Affordability is a separate question — see
  /// [AccessoryStatus.affordable] — because a price the player cannot meet yet
  /// is still a goal, while a stage they have not reached is a different kind
  /// of answer entirely.
  forSale,

  /// Gated behind a bond stage, and not for sale at any price.
  bondLocked,
}

/// One accessory as the wardrobe needs to render it.
class AccessoryStatus {
  const AccessoryStatus({
    required this.accessory,
    required this.availability,
    required this.affordable,
  });

  final AccessoryDef accessory;
  final AccessoryAvailability availability;

  /// Whether the player's balance covers [AccessoryDef.price]. Always false
  /// when there is nothing to buy.
  final bool affordable;

  bool get isOwned => availability == AccessoryAvailability.owned;
  bool get isForSale => availability == AccessoryAvailability.forSale;
  bool get isBondLocked => availability == AccessoryAvailability.bondLocked;

  /// True when a tap should open the buy confirmation.
  bool get canBuyNow => isForSale && affordable;
}

class AccessoryOwnership {
  AccessoryOwnership._();

  /// Whether [accessory] is wearable.
  ///
  /// Bond-gated pieces are derived from [stage] rather than written into the
  /// unlocked set when reached. Bond is monotonic, so a derived unlock can
  /// never regress, and deriving means there is no unlock event to miss and no
  /// stored copy to fall out of step.
  static bool isOwned(
    AccessoryDef accessory, {
    required Set<String> unlockedItemIds,
    required PetStage stage,
  }) {
    // Debug-only testing override; see AppRuntimeConfig.unlockAllAccessories.
    if (AppRuntimeConfig.unlockAllAccessories) return true;
    if (accessory.isFreeStarter) return true;
    final required = accessory.requiredStage;
    if (required != null) return stage.index >= required.index;
    return unlockedItemIds.contains(accessory.id);
  }

  static AccessoryStatus statusFor(
    AccessoryDef accessory, {
    required Set<String> unlockedItemIds,
    required PetStage stage,
    required int coins,
  }) {
    if (isOwned(
      accessory,
      unlockedItemIds: unlockedItemIds,
      stage: stage,
    )) {
      return AccessoryStatus(
        accessory: accessory,
        availability: AccessoryAvailability.owned,
        affordable: false,
      );
    }

    final price = accessory.price;
    if (price == null) {
      return AccessoryStatus(
        accessory: accessory,
        availability: AccessoryAvailability.bondLocked,
        affordable: false,
      );
    }

    return AccessoryStatus(
      accessory: accessory,
      availability: AccessoryAvailability.forSale,
      affordable: coins >= price,
    );
  }

  /// Every accessory in [slot], in catalogue order.
  static List<AccessoryStatus> statusesForSlot(
    String slot, {
    required Set<String> unlockedItemIds,
    required PetStage stage,
    required int coins,
  }) =>
      accessoriesForSlot(slot)
          .map((a) => statusFor(
                a,
                unlockedItemIds: unlockedItemIds,
                stage: stage,
                coins: coins,
              ))
          .toList();
}
