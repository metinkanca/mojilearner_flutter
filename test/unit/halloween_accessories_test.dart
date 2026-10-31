import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/character_sprite.dart';
import 'package:mojilearner_flutter/constants/accessories.dart';
import 'package:mojilearner_flutter/constants/accessory_extents.dart';
import 'package:mojilearner_flutter/constants/pets.dart';
import 'package:mojilearner_flutter/constants/season_pass.dart';
import 'package:mojilearner_flutter/l10n/app_localizations.dart';
import 'package:mojilearner_flutter/screens/wardrobe_screen.dart';

/// The Witching Hour wearables (HALLOWEEN_PASS.md) were fitted straight onto
/// the reworked cat, in cat2's own units, and then shipped shifted back by the
/// cat's offset so that every other pet derives its seat the way it does for
/// every other piece (`art_src/gen_halloween_acc.py`: CAT_SLOT_OFFSET, and for
/// the hat CAT_PIECE_OFFSET).
///
/// That makes the art and `_layeredPets['cat']` two halves of one number.
/// Change the cat's hat or neck offset, or its hat placement, on its own and
/// these four drift off its head, with nothing else failing: they would still
/// load, still be on the canvas and still be clamped. This is the check that
/// fails instead.
void main() {
  /// Where each piece was fitted on cat2: left, top, right, bottom, in cat2
  /// units. Read off `art_src/halloween/fit.png`.
  const fitted = <String, List<double>>{
    'pumpkinwitch': [36, -29.6, 197, 96.4],
    'devilband': [48, 6, 174, 102],
    'ghostbandana': [34.94, 148.66, 193.46, 229.1],
    'batchoker': [63, 150, 165, 186],
  };

  AccessoryDef piece(String id) {
    final def = accessoryById(id);
    expect(def, isNotNull, reason: '$id is not in the catalogue');
    return def!;
  }

  /// Top and bottom of the art. The traced paths are axis-aligned and absolute:
  /// every y is the second number of an `M` or the argument of a `V`. The hat
  /// and the bandana use their PNG's own pixel density (3.5 and 2.37 units a
  /// cell), so the numbers are fractional.
  List<double> yExtent(String path) {
    final ys = <double>[];
    final svg = File(path).readAsStringSync();
    for (final d in RegExp(r'\sd="([^"]+)"').allMatches(svg)) {
      for (final m
          in RegExp(r'([MV])(-?[\d.]+)(?: (-?[\d.]+))?').allMatches(d.group(1)!)) {
        ys.add(double.parse(m.group(1) == 'M' ? m.group(3)! : m.group(2)!));
      }
    }
    return [ys.reduce((a, b) => a < b ? a : b), ys.reduce((a, b) => a > b ? a : b)];
  }

  test('are season-two pass content, never sold or earned by bond', () {
    for (final id in fitted.keys) {
      final def = piece(id);
      expect(def.requiredPass, kSeasonTwoId, reason: id);
      expect(def.price, isNull, reason: id);
      expect(def.requiredStage, isNull, reason: id);
      expect(def.recolor, isNull, reason: '$id has art of its own');
      expect(def.isFreeStarter, isFalse, reason: id);
    }
  });

  test('sit in the slots HALLOWEEN_PASS.md gives them', () {
    expect(piece('pumpkinwitch').slot, AccessorySlots.hat);
    expect(piece('devilband').slot, AccessorySlots.hat);
    expect(piece('ghostbandana').slot, AccessorySlots.neck);
    expect(piece('batchoker').slot, AccessorySlots.neck);
  });

  test('land on the cat where they were fitted', () {
    final misses = <String>[];
    for (final entry in fitted.entries) {
      final def = piece(entry.key);
      // The cat's own drawing of a piece is worn exactly as drawn
      // (art_src/gen_cat_hats.py), so it has no seat to drift from.
      if (accessoryAssetFor('cat', def) != def.asset) continue;
      final offset = accessoryOffsetFor('cat', def);
      expect(offset, isNotNull, reason: '${entry.key} has no seat on the cat');
      final extent = kAccessoryExtents[def.asset];
      expect(extent, isNotNull, reason: '${def.asset} has no measured extent');
      final y = yExtent(def.asset);
      final got = [
        extent!.left + offset!.dx,
        y[0] + offset.dy,
        extent.right + offset.dx,
        y[1] + offset.dy,
      ];
      var drift = 0.0;
      for (var i = 0; i < 4; i++) {
        drift = drift > (got[i] - entry.value[i]).abs()
            ? drift
            : (got[i] - entry.value[i]).abs();
      }
      // Two decimals are all the generator writes, so anything over 0.05 is a
      // move and not rounding.
      if (drift > 0.05) {
        misses.add('${entry.key} lands at $got, was fitted at ${entry.value}');
      }
    }
    expect(misses, isEmpty,
        reason: '${misses.join('\n')}\n'
            'Update CAT_SLOT_OFFSET in art_src/gen_halloween_acc.py to the '
            "cat's new hat/neck offset and re-run it, then "
            'art_src/gen_acc_extents.py.');
  });

  test("never seat the hat over any pet's eyes", () {
    // The owner's mock-up pulls the hat low on the cat and the dog, to just
    // above the eyes. That seat belongs to those two; the rest of the roster
    // derives from a generic head seat, and a pet with less head above its
    // eyes than the cat's would otherwise have its eyes covered.
    final hat = piece('pumpkinwitch');
    final covered = <String>[];
    for (final type in kPetTypes) {
      // A pet's own drawing of the hat is worn exactly as drawn, so its brim
      // is where the art puts it and there is no offset to add.
      final own = accessoryAssetFor(type, hat);
      final offset = own != hat.asset ? Offset.zero : accessoryOffsetFor(type, hat);
      expect(offset, isNotNull, reason: '$type has no seat for the hat');
      final eyeTop = eyeGeometryFor(type).y;
      final bottom = yExtent(own)[1] + offset!.dy;
      if (bottom > eyeTop) {
        covered.add('$type: brim bottom ${bottom.toStringAsFixed(1)}, '
            'eyes start $eyeTop');
      }
    }
    expect(covered, isEmpty, reason: covered.join('\n'));
  });

  test('are named in every language, not just the English fallback', () {
    // `accessoryName` falls back to the catalogue's own English name, so a
    // missing switch case would pass every other check and ship in English.
    final ja = lookupAppLocalizations(const Locale('ja'));
    for (final id in fitted.keys) {
      final def = piece(id);
      expect(accessoryName(ja, def), isNot(def.name),
          reason: '$id has no entry in wardrobe_screen.dart accessoryName');
    }
  });
}
