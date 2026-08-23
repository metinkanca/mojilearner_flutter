import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/models/models.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:mojilearner_flutter/providers/user_provider.dart';
import 'package:mojilearner_flutter/utils/pet_recolor.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fantasy coats and eyes are bought, so the guard has to hold in the
/// provider: the wardrobe's own check only covers taps, and a colour reached
/// any other way must still be paid for.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const ultraviolet = '#8A4BF0';
  const jadeEyes = '#2FD6A5';

  PetSwatch coat(String id) => kAllBodySwatches.firstWhere((s) => s.id == id);
  PetSwatch eye(String id) => kAllEyeSwatches.firstWhere((s) => s.id == id);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<CharacterProvider> buildProvider() async {
    final provider = CharacterProvider(startDecayTimer: false);
    await Future.delayed(const Duration(milliseconds: 50));
    return provider;
  }

  Future<UserProvider> buildUser({int coins = 0}) async {
    SharedPreferences.setMockInitialValues({'coins': coins});
    final user = UserProvider();
    await Future.delayed(const Duration(milliseconds: 50));
    return user;
  }

  group('buying a colour', () {
    test('unlocks it and charges for it once', () async {
      final provider = await buildProvider();
      final user = await buildUser(coins: 1000);
      final swatch = coat('coat_ultraviolet');

      expect(provider.ownsSwatch(swatch), isFalse);
      expect(await provider.purchaseSwatch(swatch, user), isTrue);

      expect(provider.ownsSwatch(swatch), isTrue);
      expect(user.coins, 1000 - swatch.price!);

      // Already owned: nothing to sell, and nothing to charge.
      expect(await provider.purchaseSwatch(swatch, user), isFalse);
      expect(user.coins, 1000 - swatch.price!);
    });

    test('is refused when the player is short', () async {
      final provider = await buildProvider();
      final user = await buildUser(coins: 10);
      final swatch = coat('coat_ultraviolet');

      expect(await provider.purchaseSwatch(swatch, user), isFalse);
      expect(provider.ownsSwatch(swatch), isFalse);
      expect(user.coins, 10);
    });

    test('a free colour is never sold', () async {
      final provider = await buildProvider();
      final user = await buildUser(coins: 1000);

      expect(await provider.purchaseSwatch(coat('coat_smoke'), user), isFalse);
      expect(user.coins, 1000);
    });

    test('survives a restart', () async {
      final provider = await buildProvider();
      final user = await buildUser(coins: 1000);
      await provider.purchaseSwatch(coat('coat_gold'), user);

      final reloaded = await buildProvider();
      expect(reloaded.ownsSwatch(coat('coat_gold')), isTrue);
    });
  });

  group('wearing a colour', () {
    test('an unbought coat does not go on', () async {
      final provider = await buildProvider();

      provider.updateBodyColor(ultraviolet);

      expect(provider.design.bodyColor, kDefaultBodyColor);
    });

    test('buying it makes it wearable', () async {
      final provider = await buildProvider();
      final user = await buildUser(coins: 1000);

      await provider.purchaseSwatch(coat('coat_ultraviolet'), user);
      provider.updateBodyColor(ultraviolet);

      expect(provider.design.bodyColor, ultraviolet);
    });

    test('a natural coat still needs nothing', () async {
      final provider = await buildProvider();

      provider.updateBodyColor('#E0883B');

      expect(provider.design.bodyColor, '#E0883B');
    });

    test('an unbought eye colour does not go on, on either side', () async {
      final provider = await buildProvider();

      provider.updateEyeColors(mode: EyeMode.solid, color1: jadeEyes);
      expect(provider.colorSpec.eyeColor1, kDefaultEyeColor1);

      provider.updateEyeColors(
        mode: EyeMode.heterochromia,
        color1: kDefaultEyeColor1,
        color2: jadeEyes,
      );
      expect(provider.colorSpec.eyeMode, EyeMode.solid);
      expect(provider.colorSpec.eyeColor2, kDefaultEyeColor2);
    });

    test('buying an eye colour makes it wearable', () async {
      final provider = await buildProvider();
      final user = await buildUser(coins: 1000);

      await provider.purchaseSwatch(eye('eye_jade'), user);
      provider.updateEyeColors(mode: EyeMode.solid, color1: jadeEyes);

      expect(provider.colorSpec.eyeColor1, jadeEyes);
    });

    // The colour is bought, not the cat's coat: a player who paid once should
    // not pay again to paint the dog.
    test('a bought colour dresses every pet', () async {
      final provider = await buildProvider();
      final user = await buildUser(coins: 1000);
      await provider.purchaseSwatch(coat('coat_ultraviolet'), user);

      provider.updateBodyColor(ultraviolet);
      await provider.updateCharacterType('dog');
      provider.updateBodyColor(ultraviolet);

      expect(provider.designFor('cat').bodyColor, ultraviolet);
      expect(provider.designFor('dog').bodyColor, ultraviolet);
    });
  });
}
