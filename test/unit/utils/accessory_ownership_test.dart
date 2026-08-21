import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/accessories.dart';
import 'package:mojilearner_flutter/constants/bond.dart';
import 'package:mojilearner_flutter/constants/shop.dart';
import 'package:mojilearner_flutter/utils/accessory_ownership.dart';

/// The catalogue itself is part of the contract here, not just the resolver:
/// the whole point of the split is that some pieces cannot be bought, and a
/// price quietly added to one of those would undo it without failing anything
/// else.
void main() {
  AccessoryDef byId(String id) => accessoryById(id)!;

  AccessoryStatus statusOf(
    String id, {
    Set<String> unlocked = const {},
    PetStage stage = PetStage.curious,
    int coins = 0,
  }) =>
      AccessoryOwnership.statusFor(
        byId(id),
        unlockedItemIds: unlocked,
        stage: stage,
        coins: coins,
      );

  group('the catalogue', () {
    test('never puts a price and a stage on the same item', () {
      for (final a in kAccessories) {
        expect(
          a.price != null && a.requiredStage != null,
          isFalse,
          reason: '${a.id} is both bought and earned',
        );
      }
    });

    test('bond-gated pieces are absent from the shop', () {
      for (final a in kAccessories.where((a) => a.requiredStage != null)) {
        expect(
          a.price,
          isNull,
          reason: '${a.id} is meant to be earned, not sold',
        );
      }
    });

    test('leaves at least one free starter so the wardrobe is not all locks',
        () {
      expect(kAccessories.where((a) => a.isFreeStarter), isNotEmpty);
    });

    test('offers something to buy in the first slot a player opens', () {
      expect(
        accessoriesForSlot(AccessorySlots.hat).where((a) => a.price != null),
        isNotEmpty,
      );
    });
  });

  group('the derived shop listing', () {
    test('lists every priced accessory and nothing else', () {
      expect(
        accessoryShopItems.map((i) => i.id).toSet(),
        kAccessories.where((a) => a.price != null).map((a) => a.id).toSet(),
      );
    });

    test('carries the catalogue price through unchanged', () {
      for (final item in accessoryShopItems) {
        expect(item.price, accessoryById(item.id)!.price);
        expect(item.type, 'accessory');
      }
    });

    // The one that matters: no amount of coins can reach these.
    test('has no entry for anything bond-gated', () {
      for (final a in kAccessories.where((a) => a.requiredStage != null)) {
        expect(accessoryShopItemById(a.id), isNull, reason: a.id);
      }
    });
  });

  group('free starters', () {
    test('are owned with no purchase and no bond', () {
      final status = statusOf('cap');
      expect(status.isOwned, isTrue);
      expect(status.availability, AccessoryAvailability.owned);
    });
  });

  group('purchasable', () {
    test('is for sale until bought, then owned', () {
      expect(statusOf('bowtie').isForSale, isTrue);
      expect(statusOf('bowtie', unlocked: {'bowtie'}).isOwned, isTrue);
    });

    test('separates affordable from for-sale', () {
      final price = byId('necklace').price!;

      final broke = statusOf('necklace', coins: price - 1);
      expect(broke.isForSale, isTrue);
      expect(broke.affordable, isFalse);
      expect(broke.canBuyNow, isFalse);

      final flush = statusOf('necklace', coins: price);
      expect(flush.affordable, isTrue);
      expect(flush.canBuyNow, isTrue);
    });

    // Coins buy coin items. Reaching a bond stage must not hand them over too,
    // or the sink stops being a sink.
    test('is not unlocked by reaching a bond stage', () {
      expect(
        statusOf('necklace', stage: PetStage.inseparable).isForSale,
        isTrue,
      );
    });
  });

  group('bond-gated', () {
    test('is locked below its stage and owned at or above it', () {
      expect(statusOf('tophat', stage: PetStage.curious).isBondLocked, isTrue);
      expect(statusOf('tophat', stage: PetStage.friendly).isBondLocked, isTrue);
      expect(statusOf('tophat', stage: PetStage.attached).isOwned, isTrue);
      expect(statusOf('tophat', stage: PetStage.inseparable).isOwned, isTrue);
    });

    test('never reads as for sale, however rich the player is', () {
      final status = statusOf('crown', coins: 999999);
      expect(status.isBondLocked, isTrue);
      expect(status.isForSale, isFalse);
      expect(status.affordable, isFalse);
      expect(status.canBuyNow, isFalse);
    });

    // A stale unlocked-items entry (an older build, a restored backup) must
    // not be a way around the stage requirement.
    test('is not unlocked by an unlocked-items entry', () {
      expect(
        statusOf('crown', unlocked: {'crown'}, stage: PetStage.curious)
            .isBondLocked,
        isTrue,
      );
    });
  });

  group('statusesForSlot', () {
    test('returns every accessory in the slot, in catalogue order', () {
      final statuses = AccessoryOwnership.statusesForSlot(
        AccessorySlots.hat,
        unlockedItemIds: const {},
        stage: PetStage.curious,
        coins: 0,
      );

      expect(
        statuses.map((s) => s.accessory.id),
        accessoriesForSlot(AccessorySlots.hat).map((a) => a.id),
      );
    });
  });
}
