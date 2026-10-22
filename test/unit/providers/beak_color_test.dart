import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/character_sprite.dart';
import 'package:mojilearner_flutter/constants/pets.dart';
import 'package:mojilearner_flutter/models/models.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:mojilearner_flutter/utils/pet_recolor.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A pet with a beak can have it coloured apart from its coat. Left alone, the
/// bird's beak follows the coat and the parrot's and penguin's keep the tone
/// they were drawn in.
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

  const beak = '<path fill="$kBeakFill"/>';
  const orange = '#F29422';

  group('recolouring a layer', () {
    test('an unchosen beak is the coat shade, and moves with the coat', () {
      expect(recolorBodyLayer(beak, '#959379'),
          contains('fill="${darken('#959379', 0.72)}"'));
      expect(recolorBodyLayer(beak, '#E0883B'),
          contains('fill="${darken('#E0883B', 0.72)}"'));
    });

    test('a chosen beak takes its colour and leaves the coat alone', () {
      final out = recolorBodyLayer(
        '$beak<path fill="#959379"/>',
        '#E0883B',
        beakColor: orange,
        beakFills: const [kBeakFill],
      );
      expect(out, contains('fill="$orange"'));
      expect(out, contains('fill="#E0883B"'));
    });

    test("a drawn beak tone only changes once a colour is picked", () {
      const parrot = '<path fill="#e9c289"/>';
      expect(
        recolorBodyLayer(parrot, '#959379', beakFills: const ['#e9c289']),
        parrot,
      );
      expect(
        recolorBodyLayer(parrot, '#959379',
            beakColor: orange, beakFills: const ['#e9c289']),
        contains('fill="$orange"'),
      );
    });
  });

  group('a two-toned beak', () {
    // The penguin's bill: a bright orange with a darker one under it.
    const bill = '<path fill="#ffa11c"/><path fill="#c76a09"/>';

    test('is left as drawn until a colour is picked', () {
      expect(
        recolorBodyLayer(bill, '#959379',
            beakFills: const ['#ffa11c'], beakShadeFills: const ['#c76a09']),
        bill,
      );
    });

    test('keeps its shading under a chosen colour, as a darker one', () {
      const blue = '#5AA0E0';
      final out = recolorBodyLayer(bill, '#959379',
          beakColor: blue,
          beakFills: const ['#ffa11c'],
          beakShadeFills: const ['#c76a09']);
      expect(out, contains('fill="$blue"'));
      expect(out, contains('fill="${darken(blue, 0.72)}"'));
      expect(out, isNot(contains('#c76a09')));
    });
  });

  group('which pets have a beak', () {
    test('the birds do and the mammals do not', () {
      for (final type in ['bird', 'parrot', 'penguin']) {
        expect(petHasBeak(type), isTrue, reason: type);
      }
      for (final type in ['cat', 'dog', 'rabbit']) {
        expect(petHasBeak(type), isFalse, reason: type);
        expect(naturalBeakFor(type, kDefaultBodyColor), isNull, reason: type);
      }
    });

    test("the bird's natural beak is its coat's shade", () {
      expect(naturalBeakFor('bird', '#E0883B'), darken('#E0883B', 0.72));
      expect(naturalBeakFor('penguin', kDefaultBodyColor), '#ffa11c');
    });
  });

  group('choosing a beak colour', () {
    test('sets it on the pet out, and only that pet', () async {
      // The penguin is bought, not a starter.
      SharedPreferences.setMockInitialValues({
        'unlocked_items': [petUnlockId('penguin')],
      });
      final provider = await buildProvider();
      await provider.updateCharacterType('bird');

      provider.updateBeakColor(orange);
      expect(provider.colorSpec.beakColor, orange);

      await provider.updateCharacterType('penguin');
      expect(provider.colorSpec.beakColor, isNull);
    });

    test('null returns the beak to the one drawn', () async {
      final provider = await buildProvider();
      await provider.updateCharacterType('bird');

      provider.updateBeakColor(orange);
      provider.updateBeakColor(null);
      expect(provider.design.beakColor, isNull);
    });

    test('a colour outside the beak palette is ignored', () async {
      final provider = await buildProvider();
      await provider.updateCharacterType('bird');

      provider.updateBeakColor('#123456');
      expect(provider.design.beakColor, isNull);
    });

    test('survives a restart', () async {
      final provider = await buildProvider();
      await provider.updateCharacterType('bird');
      provider.updateBeakColor(orange);
      await Future.delayed(const Duration(milliseconds: 50));

      final reloaded = await buildProvider();
      expect(reloaded.designFor('bird').beakColor, orange);
    });

    test('a save from before beaks loads with the beak as drawn', () {
      final design = PetDesign.fromJson({'bodyColor': '#E0883B'});
      expect(design.beakColor, isNull);
      expect(design.toJson().containsKey('beakColor'), isFalse);
    });
  });
}
