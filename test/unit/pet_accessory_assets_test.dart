import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/character_sprite.dart';
import 'package:mojilearner_flutter/constants/accessories.dart';
import 'package:mojilearner_flutter/constants/pets.dart';

/// A pet whose head is not the cat's wears its own cut of some pieces — the
/// bird's hats are re-pixelised smaller and its face pieces are re-cut side-on.
/// Those overrides are a map of string ids to string paths, so a typo in either
/// is silent: the pet just wears nothing, and only that pet with that one item.
/// Loading every pair is what makes that loud instead.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A pet missing from the sprite's layer table still renders — it falls
  /// back to the whole-sprite asset — but it silently loses recolouring, the
  /// blink and the petting squint, which is most of what a pet does. A pet in
  /// the rank and not in the table is the shape that mistake takes.
  test('every pet is rigged into layers, on the shared canvas', () async {
    for (final type in kPetTypes) {
      expect(isLayeredPet(type), isTrue,
          reason: '$type is in the rank but not split into layers');
      final base = await rootBundle.loadString('assets/svgs/${type}_base.svg');
      expect(base, contains('viewBox="-20 -90 222 328"'),
          reason: 'the $type coat is not on the shared pet canvas');
    }
  });

  test('every pet has art it can actually wear for every accessory', () async {
    for (final type in kPetTypes) {
      for (final def in kAccessories) {
        final asset = accessoryAssetFor(type, def);
        expect(
          asset.endsWith('.svg'),
          isTrue,
          reason: '$type/${def.id} resolved to "$asset"',
        );
        final svg = await rootBundle.loadString(asset);
        expect(
          svg,
          contains('viewBox="-20 -90 222 328"'),
          reason: '$asset is not on the shared pet canvas, so it will not '
              'line up with the pet it is drawn over',
        );
      }
    }
  });

  /// The wardrobe tiles come from the same catalogue and are cropped to their
  /// own content, so they are checked for loading but not for the canvas.
  test('every accessory has a wardrobe icon', () async {
    for (final def in kAccessories) {
      final icon = def.asset.replaceFirst('.svg', '_icon.svg');
      await expectLater(rootBundle.loadString(icon), completes);
    }
  });
}
