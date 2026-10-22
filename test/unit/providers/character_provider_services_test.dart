import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/shop.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:mojilearner_flutter/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_fixtures.dart';

/// A scenario's service — the restaurant's meal, the doctor's medicine — is
/// the shop item bought and eaten on the spot. These hold it to the shop's
/// price and the shop's effect, and to changing nothing when it is refused.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(CharacterProvider, UserProvider)> build(
      Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues({
      ...TestFixtures.welcomeGiftAlreadyGiven,
      ...prefs,
    });
    final character = CharacterProvider(startDecayTimer: false);
    final user = UserProvider();
    await Future.delayed(const Duration(milliseconds: 50));
    return (character, user);
  }

  test('a meal costs the shop price and fills like the shop dish', () async {
    final (character, user) =
        await build({'coins': 100, 'pet_hunger': 70, 'pet_happiness': 50});
    final pizza = shopItemById('pizza')!;

    expect(await character.purchaseAndFeed(pizza, user), isTrue);

    expect(user.coins, 100 - pizza.price);
    expect(character.hunger, 70 - pizza.hungerRestore!);
    expect(character.happiness, 50 + pizza.happinessRestore!);
  });

  test('medicine from the doctor heals like medicine from the shop', () async {
    final (character, user) = await build({'coins': 100, 'pet_health': 20});
    final medicine = shopItemById('medicine')!;

    expect(await character.purchaseAndFeed(medicine, user), isTrue);

    expect(user.coins, 100 - medicine.price);
    expect(character.health, 20 + medicine.healthRestore!);
    expect(character.isSick, isFalse);
  });

  test('a dish already in the bag stays there', () async {
    final (character, user) = await build({
      'coins': 100,
      'inventory': ['pizza'],
    });
    final bag = List.of(character.inventory);

    await character.purchaseAndFeed(shopItemById('pizza')!, user);

    expect(character.inventory, bag);
    expect(character.inventory, contains('pizza'));
  });

  test('one that cannot be afforded changes nothing', () async {
    final (character, user) =
        await build({'coins': 10, 'pet_hunger': 70, 'pet_health': 20});
    final bag = List.of(character.inventory);

    expect(
        await character.purchaseAndFeed(shopItemById('pizza')!, user), isFalse);

    expect(user.coins, 10);
    expect(character.hunger, 70);
    expect(character.health, 20);
    expect(character.inventory, bag);
  });

  test('only food can be served', () async {
    final (character, user) = await build({'coins': 1000});

    expect(
        await character.purchaseAndFeed(shopItemById('bg_galaxy')!, user),
        isFalse);
    expect(user.coins, 1000);
  });
}
