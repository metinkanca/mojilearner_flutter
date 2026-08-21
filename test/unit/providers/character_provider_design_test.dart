import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/accessories.dart';
import 'package:mojilearner_flutter/constants/bond.dart';
import 'package:mojilearner_flutter/models/models.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:mojilearner_flutter/utils/pet_recolor.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A pet's look — coat, eyes and outfit — belongs to that pet. Dressing the
/// cat used to dress the dog too, because there was one shared design.
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

  group('designs are per character type', () {
    test('a coat colour does not follow the player to another pet', () async {
      final provider = await buildProvider();

      provider.updateBodyColor('#E0883B'); // ginger cat
      await provider.updateCharacterType('dog');

      expect(provider.design.bodyColor, kDefaultBodyColor);
      expect(provider.colorSpec.bodyColor, kDefaultBodyColor);
    });

    test('each pet keeps its own coat and eyes', () async {
      final provider = await buildProvider();

      provider.updateBodyColor('#E0883B');
      provider.updateEyeColors(mode: EyeMode.solid, color1: '#4CA65B');

      await provider.updateCharacterType('dog');
      provider.updateBodyColor('#5A554F');
      provider.updateEyeColors(
        mode: EyeMode.heterochromia,
        color1: '#F4C430',
        color2: '#5AA0E0',
      );

      expect(provider.designFor('cat').bodyColor, '#E0883B');
      expect(provider.designFor('cat').eyeColor1, '#4CA65B');
      expect(provider.designFor('cat').eyeMode, 'solid');
      expect(provider.designFor('dog').bodyColor, '#5A554F');
      expect(provider.designFor('dog').eyeMode, 'heterochromia');
    });

    test('switching back restores the design that pet was given', () async {
      final provider = await buildProvider();

      provider.updateBodyColor('#E0883B');
      await provider.updateCharacterType('dog');
      await provider.updateCharacterType('cat');

      expect(provider.design.bodyColor, '#E0883B');
    });

    test('an accessory is worn by one pet, not all of them', () async {
      final provider = await buildProvider();

      expect(provider.equipAccessory('cap', stage: PetStage.curious), isTrue);
      await provider.updateCharacterType('dog');

      expect(provider.equippedInSlot(AccessorySlots.hat), isNull);
      expect(provider.equippedAccessoryAssets, isEmpty);

      await provider.updateCharacterType('cat');
      expect(provider.equippedInSlot(AccessorySlots.hat), 'cap');
    });

    // Buying a hat buys the hat, not "a hat for the cat" — otherwise the
    // wardrobe would ask the player to pay again per pet.
    test('ownership stays shared: the same hat fits both pets', () async {
      final provider = await buildProvider();

      provider.equipAccessory('cap', stage: PetStage.curious);
      await provider.updateCharacterType('dog');

      expect(provider.equipAccessory('cap', stage: PetStage.curious), isTrue);
      expect(provider.equippedInSlot(AccessorySlots.hat), 'cap');
      expect(provider.designFor('cat').accessories[AccessorySlots.hat], 'cap');
    });
  });

  group('persistence', () {
    test('each pet keeps its own design across a restart', () async {
      final provider = await buildProvider();

      provider.updateBodyColor('#E0883B');
      provider.equipAccessory('cap', stage: PetStage.curious);
      await provider.updateCharacterType('dog');
      provider.updateBodyColor('#5A554F');
      await Future.delayed(const Duration(milliseconds: 50));

      final reloaded = await buildProvider();

      expect(reloaded.currentCharacterType, 'dog');
      expect(reloaded.design.bodyColor, '#5A554F');
      expect(reloaded.designFor('cat').bodyColor, '#E0883B');
      expect(
        reloaded.designFor('cat').accessories[AccessorySlots.hat],
        'cap',
      );
    });

    test('an accessory retired from the catalogue is dropped', () async {
      SharedPreferences.setMockInitialValues({
        'pet_designs': jsonEncode({
          'cat': {
            'bodyColor': '#E0883B',
            'accessories': {'hat': 'sombrero'},
          },
        }),
      });

      final provider = await buildProvider();

      expect(provider.design.bodyColor, '#E0883B');
      expect(provider.equippedInSlot(AccessorySlots.hat), isNull);
    });
  });

  // Older saves had a single coat/eyes/outfit shared by every pet. It belongs
  // to whichever pet was out when it was saved.
  group('migration from the shared-design build', () {
    test('the shared design lands on the pet that was wearing it', () async {
      SharedPreferences.setMockInitialValues({
        'character_type': 'dog',
        'pet_body_color': '#E0883B',
        'pet_eye_mode': 'heterochromia',
        'pet_eye_color1': '#4CA65B',
        'pet_eye_color2': '#5AA0E0',
        'equipped_accessories': jsonEncode({'hat': 'cap'}),
      });

      final provider = await buildProvider();

      expect(provider.currentCharacterType, 'dog');
      expect(provider.design.bodyColor, '#E0883B');
      expect(provider.design.eyeMode, 'heterochromia');
      expect(provider.equippedInSlot(AccessorySlots.hat), 'cap');
    });

    test('the other pets start from the defaults', () async {
      SharedPreferences.setMockInitialValues({
        'character_type': 'dog',
        'pet_body_color': '#E0883B',
        'equipped_accessories': jsonEncode({'hat': 'cap'}),
      });

      final provider = await buildProvider();
      await provider.updateCharacterType('cat');

      expect(provider.design.bodyColor, kDefaultBodyColor);
      expect(provider.equippedInSlot(AccessorySlots.hat), isNull);
    });

    test('the migrated design is stored in the new shape', () async {
      SharedPreferences.setMockInitialValues({
        'character_type': 'dog',
        'pet_body_color': '#E0883B',
      });

      await buildProvider();
      final prefs = await SharedPreferences.getInstance();
      final stored = jsonDecode(prefs.getString('pet_designs')!) as Map;

      expect(stored['dog']['bodyColor'], '#E0883B');
    });
  });
}
