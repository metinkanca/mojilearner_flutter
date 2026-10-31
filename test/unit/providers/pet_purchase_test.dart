import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/constants/pets.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/mock_providers.dart';

/// Pets beyond the original three are bought, once, for [kPetPrice].
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<CharacterProvider> load() async {
    final provider = CharacterProvider(startDecayTimer: false);
    await Future.delayed(const Duration(milliseconds: 50));
    return provider;
  }

  /// A purse holding [coins], which records what is spent from it.
  MockUserProvider purse(int coins) {
    final user = MockUserProvider();
    var balance = coins;
    when(() => user.coins).thenAnswer((_) => balance);
    when(() => user.spendCoins(any())).thenAnswer((call) async {
      balance -= call.positionalArguments.first as int;
    });
    return user;
  }

  final forSale = kPetTypes.firstWhere((t) => !isStarterPet(t));

  test('the three starters are free and everything else has the one price', () {
    expect(kStarterPetTypes, ['dog', 'cat', 'bird']);
    expect(kStarterPetTypes, contains(kDefaultPetType));
    for (final type in kPetTypes) {
      expect(petPrice(type), isStarterPet(type) ? isNull : kPetPrice,
          reason: type);
    }
    expect(kPetTypes.where((t) => !isStarterPet(t)), hasLength(27));
  });

  test('a new player owns the starters and nothing else', () async {
    final provider = await load();
    for (final type in kPetTypes) {
      expect(provider.ownsPet(type), isStarterPet(type), reason: type);
    }
  });

  test('an unbought pet cannot be brought out', () async {
    final provider = await load();

    await provider.updateCharacterType(forSale);
    expect(provider.currentCharacterType, kDefaultPetType);

    await provider.updateCharacterType('dog');
    expect(provider.currentCharacterType, 'dog');
  });

  test('buying takes the price once and makes the pet choosable', () async {
    final provider = await load();
    final user = purse(1000);

    expect(await provider.purchasePet(forSale, user), isTrue);
    expect(user.coins, 1000 - kPetPrice);
    expect(provider.ownsPet(forSale), isTrue);

    // Bought, not adopted: bringing it out is the caller's call.
    expect(provider.currentCharacterType, kDefaultPetType);
    await provider.updateCharacterType(forSale);
    expect(provider.currentCharacterType, forSale);

    // A second purchase is refused and costs nothing.
    expect(await provider.purchasePet(forSale, user), isFalse);
    expect(user.coins, 1000 - kPetPrice);
  });

  test('refuses what cannot be afforded, and never sells a starter', () async {
    final provider = await load();

    final poor = purse(kPetPrice - 1);
    expect(await provider.purchasePet(forSale, poor), isFalse);
    expect(poor.coins, kPetPrice - 1);
    expect(provider.ownsPet(forSale), isFalse);

    final rich = purse(1000);
    expect(await provider.purchasePet('cat', rich), isFalse);
    expect(await provider.purchasePet('unicorn', rich), isFalse);
    expect(rich.coins, 1000);
  });

  test('a bought pet is still owned after a restart', () async {
    final provider = await load();
    await provider.purchasePet(forSale, purse(1000));
    await Future.delayed(const Duration(milliseconds: 50));

    final reloaded = await load();
    expect(reloaded.ownsPet(forSale), isTrue);
  });

  // Every pet used to be free. A save already living with one that now has a
  // price keeps it, rather than being bounced back to the cat.
  test('a pet already out before pets had prices stays owned', () async {
    SharedPreferences.setMockInitialValues({'character_type': forSale});

    final provider = await load();

    expect(provider.currentCharacterType, forSale);
    expect(provider.ownsPet(forSale), isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('unlocked_items'), contains(petUnlockId(forSale)));
  });
}
