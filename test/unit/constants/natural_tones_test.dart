import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/pets.dart';
import 'package:mojilearner_flutter/utils/pet_recolor.dart';

/// A pet in its natural coat is painted in the tones it was drawn in, not in
/// tones derived from the coat.
void main() {
  const layer = '<rect fill="#959379"/><rect fill="#606659"/>'
      '<rect fill="#c8c6b3"/><rect fill="$kBeakFill"/>';

  test('every pet is born in a coloured coat, not the house grey', () {
    for (final type in ['dog', 'cat', 'bird', 'rabbit', 'fox']) {
      expect(naturalCoatFor(type).toLowerCase(), isNot('#959379'),
          reason: type);
    }
  });

  test('the natural coat puts back the drawn shade, highlight and beak', () {
    final tones = naturalTonesFor('bird', naturalCoatFor('bird'))!;
    final out = recolorBodyLayer(layer, naturalCoatFor('bird'),
        shadeColor: tones.shade,
        lightColor: tones.light,
        naturalBeak: tones.beak);
    expect(out, contains('fill="#e6a42c"'));
    expect(out, contains('fill="#f29422"'));
  });

  test('any other coat derives its tones as before', () {
    expect(naturalTonesFor('bird', '#E0883B'), isNull);
  });

  test('the wardrobe offers the drawn coat first', () {
    final swatches = bodySwatchesFor('fox');
    expect(swatches.first.id, kNaturalCoatSwatchId);
    expect(swatches.first.hex, naturalCoatFor('fox'));
    expect(swatches.first.isFree, isTrue);
  });
}
