import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/character_sprite.dart';
import 'package:mojilearner_flutter/constants/accessories.dart';
import 'package:mojilearner_flutter/constants/accessory_extents.dart';
import 'package:mojilearner_flutter/constants/pets.dart';

/// Everything a pet wears is drawn on one 222-unit-wide canvas and is clipped
/// by it. The accessory art was drawn on the cat, whose head is near the
/// middle, and some pieces are nearly canvas-wide — so a pet whose head is off
/// to one side moves a hat sideways to wear it and can push the brim over the
/// edge, where it is silently sliced off rather than failing.
///
/// The roster pets did exactly that: the skunk's head sits 38 units right of
/// the cat's, and its top hat, its right lens and the end of its collar all
/// came off. `accessoryPlacementOnCanvas` is the clamp that stops it, and this
/// is the check that it is actually enough for every pet and every piece.
void main() {
  const canvasLeft = -20.0;
  const canvasRight = 202.0;

  test('no pet can wear any accessory off the edge of the canvas', () {
    final misses = <String>[];

    for (final type in kPetTypes) {
      for (final def in kAccessories) {
        final asset = accessoryAssetFor(type, def);
        final extent = kAccessoryExtents[asset];
        if (extent == null) {
          misses.add('$asset has no measured extent '
              '(re-run art_src/gen_acc_extents.py)');
          continue;
        }
        // Wider than the canvas is a drawing that cannot be made to fit at any
        // offset; the clamp gives up on those, and so does this.
        if (extent.right - extent.left > canvasRight - canvasLeft) continue;

        final wanted = accessoryOffsetFor(type, def);
        if (wanted == null) continue; // its own cut, placed verbatim

        final mirrored = accessoryIsMirrored(type, def);
        final placed =
            accessoryPlacementOnCanvas(wanted, asset, mirrored: mirrored);
        // The flip happens before the move — about the canvas centre, which is
        // what a negative scaleX does to art that fills the canvas — so what
        // has to fit is the reflected span, not the drawn one.
        const centre = canvasLeft + (canvasRight - canvasLeft) / 2;
        final drawnLeft =
            mirrored ? 2 * centre - extent.right : extent.left;
        final drawnRight =
            mirrored ? 2 * centre - extent.left : extent.right;
        final left = drawnLeft + placed.dx;
        final right = drawnRight + placed.dx;
        if (left < canvasLeft - 0.01 || right > canvasRight + 0.01) {
          misses.add('$type/${def.id} lands at ${left.toStringAsFixed(0)}..'
              '${right.toStringAsFixed(0)}, outside $canvasLeft..$canvasRight');
        }
      }
    }

    expect(misses, isEmpty, reason: misses.join('\n'));
  });

  /// The clamp is only allowed to pull a piece back, never to shove it
  /// somewhere the pet did not ask for. If it ever moved a piece further out,
  /// a hat would drift off a head that had been measured correctly.
  test('the clamp only ever reduces the movement asked for', () {
    for (final entry in kAccessoryExtents.entries) {
      for (final dx in const [-90.0, -40.0, -5.0, 0.0, 5.0, 40.0, 90.0]) {
        final placed = accessoryPlacementOnCanvas(
            Offset(dx, 7), entry.key,
            mirrored: false);
        expect(placed.dy, 7, reason: '${entry.key} was moved vertically');
        expect(placed.dx.abs(), lessThanOrEqualTo(dx.abs() + 0.01),
            reason: '${entry.key} was pushed further out than $dx');
        expect(placed.dx * dx, greaterThanOrEqualTo(-0.01),
            reason: '${entry.key} was moved the other way from $dx');
      }
    }
  });
}
