import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/accessories.dart';
import 'package:mojilearner_flutter/constants/bond.dart';
import 'package:mojilearner_flutter/constants/shop.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:mojilearner_flutter/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The equip guard lives in the provider, not only in the wardrobe, so these
/// go through the provider directly — that is the thing a future caller would
/// reach for.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<CharacterProvider> buildProvider() async {
    final provider = CharacterProvider(startDecayTimer: false);
    await Future.delayed(const Duration(milliseconds: 50));
    return provider;
  }

  Future<UserProvider> buildUser() async {
    final user = UserProvider();
    await Future.delayed(const Duration(milliseconds: 50));
    return user;
  }

  group('equip guard', () {
    test('a free starter goes on straight away', () async {
      final provider = await buildProvider();

      expect(
        provider.equipAccessory('cap', stage: PetStage.curious),
        isTrue,
      );
      expect(provider.equippedInSlot(AccessorySlots.hat), 'cap');
    });

    test('an unbought accessory is refused and changes nothing', () async {
      final provider = await buildProvider();

      expect(
        provider.equipAccessory('bowtie', stage: PetStage.inseparable),
        isFalse,
      );
      expect(provider.equippedInSlot(AccessorySlots.neck), isNull);
    });

    test('a bond-gated accessory is refused below its stage', () async {
      final provider = await buildProvider();

      expect(
        provider.equipAccessory('tophat', stage: PetStage.friendly),
        isFalse,
      );
      expect(
        provider.equipAccessory('tophat', stage: PetStage.attached),
        isTrue,
      );
      expect(provider.equippedInSlot(AccessorySlots.hat), 'tophat');
    });

    test('an unknown id is refused', () async {
      final provider = await buildProvider();
      expect(
        provider.equipAccessory('sombrero', stage: PetStage.inseparable),
        isFalse,
      );
    });

    // Otherwise a retuned catalogue could leave someone stuck wearing
    // something they can no longer equip.
    test('taking something off is always allowed', () async {
      SharedPreferences.setMockInitialValues({
        'equipped_accessories': jsonEncode({'neck': 'bowtie'}),
      });
      final provider = await buildProvider();
      expect(provider.equippedInSlot(AccessorySlots.neck), 'bowtie');

      expect(
        provider.equipAccessory('bowtie', stage: PetStage.curious),
        isTrue,
      );
      expect(provider.equippedInSlot(AccessorySlots.neck), isNull);
    });
  });

  group('buying', () {
    test('an accessory bought in the shop becomes wearable', () async {
      SharedPreferences.setMockInitialValues({'coins': 500});
      final provider = await buildProvider();
      final user = await buildUser();

      final item = accessoryShopItemById('bowtie')!;
      expect(await provider.purchaseItem(item, user), isTrue);

      expect(provider.ownsAccessory('bowtie', stage: PetStage.curious), isTrue);
      expect(
        provider.equipAccessory('bowtie', stage: PetStage.curious),
        isTrue,
      );
    });

    test('a purchase that cannot be afforded leaves it locked', () async {
      SharedPreferences.setMockInitialValues({'coins': 0});
      final provider = await buildProvider();
      final user = await buildUser();

      final item = accessoryShopItemById('necklace')!;
      expect(await provider.purchaseItem(item, user), isFalse);
      expect(
        provider.ownsAccessory('necklace', stage: PetStage.curious),
        isFalse,
      );
    });
  });

  // Every accessory used to be free. Players who already dressed their pet
  // have no purchase record for what it is wearing, and must not be asked to
  // buy it back.
  group('migration from the free-for-all build', () {
    test('what the pet is already wearing counts as owned', () async {
      SharedPreferences.setMockInitialValues({
        'equipped_accessories': jsonEncode({'neck': 'necklace'}),
      });
      final provider = await buildProvider();

      expect(
        provider.ownsAccessory('necklace', stage: PetStage.curious),
        isTrue,
      );
      expect(provider.unlockedItems, contains('necklace'));
    });

    test('grandfathering does not hand over the rest of the catalogue',
        () async {
      SharedPreferences.setMockInitialValues({
        'equipped_accessories': jsonEncode({'neck': 'necklace'}),
      });
      final provider = await buildProvider();

      expect(
        provider.ownsAccessory('cowboyhat', stage: PetStage.curious),
        isFalse,
      );
      expect(
        provider.ownsAccessory('crown', stage: PetStage.curious),
        isFalse,
      );
    });

    test('survives taking the item off', () async {
      SharedPreferences.setMockInitialValues({
        'equipped_accessories': jsonEncode({'neck': 'necklace'}),
      });
      final provider = await buildProvider();

      provider.equipAccessory('necklace', stage: PetStage.curious);
      expect(provider.equippedInSlot(AccessorySlots.neck), isNull);
      expect(
        provider.ownsAccessory('necklace', stage: PetStage.curious),
        isTrue,
      );
    });
  });
}
