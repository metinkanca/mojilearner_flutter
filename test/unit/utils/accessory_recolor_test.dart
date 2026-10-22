import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/character_sprite.dart'
    show artSourceFor, accessoryAssetFor;
import 'package:mojilearner_flutter/constants/accessories.dart';
import 'package:mojilearner_flutter/utils/pet_recolor.dart';

/// Palette variants: one drawing, several pieces.
///
/// This is what makes a ten-tier season pass every two months affordable
/// against a catalogue that took the whole project to reach twenty. So the
/// properties worth pinning are the ones that decide whether a variant is
/// genuinely free: it must borrow the source's art on every pet, inherit its
/// placement, and never be able to move the shared outline.
void main() {
  const outline = kOutlineFill;
  const svg = '<svg>'
      '<path fill="#c0392b"/>'
      '<path fill="#7f2418"/>'
      '<path fill="$outline"/>'
      '</svg>';

  group('recolorAccessory', () {
    test('swaps the fills a variant names', () {
      final out = recolorAccessory(svg, {'#c0392b': '#2980b9'});

      expect(out, contains('fill="#2980b9"'));
      expect(out, isNot(contains('fill="#c0392b"')));
    });

    test('swaps several at once without them chaining', () {
      final out = recolorAccessory(svg, {
        '#c0392b': '#7f2418',
        '#7f2418': '#1a5276',
      });

      // The second swap must not then re-swap what the first produced, or a
      // palette that reuses a shade collapses to one colour.
      expect(out, contains('fill="#7f2418"'));
      expect(out, contains('fill="#1a5276"'));
    });

    // Every pet and every accessory is drawn in one ink. A variant that could
    // move it would put a piece on the pet drawn in a different outline from
    // the animal wearing it.
    test('refuses to move the shared outline', () {
      final out = recolorAccessory(svg, {outline: '#ffffff'});

      expect(out, contains('fill="$outline"'));
      expect(out, isNot(contains('fill="#ffffff"')));
    });

    test('a fill the art does not have is a no-op', () {
      expect(recolorAccessory(svg, {'#123456': '#654321'}), svg);
    });

    test('an empty palette leaves the drawing alone', () {
      expect(recolorAccessory(svg, const {}), svg);
    });
  });

  group('art resolution', () {
    // A real catalogue piece, so the test breaks if the shape it borrows is
    // retired rather than passing against a fiction.
    final source = accessoryById('tophat')!;

    final variant = AccessoryDef(
      id: 'tophat_crimson',
      name: 'Crimson Top Hat',
      slot: source.slot,
      asset: source.asset,
      icon: source.icon,
      requiredPass: 'season-1',
      recolor: const AccessoryRecolor(
        sourceId: 'tophat',
        fills: {'#1a1a1a': '#c0392b'},
      ),
    );

    test('a piece with its own art is its own source', () {
      expect(artSourceFor(source).id, 'tophat');
    });

    test('a variant resolves to the drawing it borrows', () {
      expect(artSourceFor(variant).id, 'tophat');
    });

    // The saving that matters most: the bird cut is the expensive one, since
    // the chick is smaller than the cat's head and cannot wear a scaled copy.
    test('a variant inherits the per-pet cuts made for the shape', () {
      for (final pet in ['cat', 'dog', 'bird']) {
        expect(
          accessoryAssetFor(pet, variant),
          accessoryAssetFor(pet, source),
          reason: 'the $pet should wear the shape it already has art for',
        );
      }
    });

    // A variant of a variant would make "what is this drawn from" a question
    // with more than one answer.
    test('a missing source falls back to the piece itself', () {
      const orphan = AccessoryDef(
        id: 'orphan',
        name: 'Orphan',
        slot: AccessorySlots.hat,
        asset: 'assets/svgs/acc_orphan.svg',
        icon: '🎩',
        recolor: AccessoryRecolor(sourceId: 'never-existed', fills: {}),
      );

      expect(artSourceFor(orphan).id, 'orphan');
    });
  });

  group('the catalogue keeps its rules', () {
    test('no shipping piece is both pass content and for sale', () {
      for (final accessory in kAccessories) {
        if (accessory.requiredPass == null) continue;
        expect(accessory.price, isNull, reason: accessory.id);
        expect(accessory.requiredStage, isNull, reason: accessory.id);
      }
    });

    test('every recolour points at a piece that exists', () {
      for (final accessory in kAccessories) {
        final recolor = accessory.recolor;
        if (recolor == null) continue;
        expect(
          accessoryById(recolor.sourceId),
          isNotNull,
          reason: '${accessory.id} borrows ${recolor.sourceId}',
        );
        // One hop only.
        expect(
          accessoryById(recolor.sourceId)!.recolor,
          isNull,
          reason: '${accessory.id} borrows a variant',
        );
      }
    });

    // `recolorAccessory` treats a fill the art does not contain as a no-op --
    // deliberately, so a variant outliving a redraw renders as the source
    // rather than as nothing. The cost is that a mistyped hex is invisible:
    // the piece just quietly ships in the source's colours. Nothing else
    // catches that, so this reads the drawings.
    test('every recolour names fills its source drawing actually has', () {
      for (final accessory in kAccessories) {
        final recolor = accessory.recolor;
        if (recolor == null) continue;

        final source = accessoryById(recolor.sourceId)!;
        final art = File(source.asset).readAsStringSync();
        final present = RegExp(r'fill="(#[0-9a-fA-F]{6})"')
            .allMatches(art)
            .map((m) => m.group(1)!.toLowerCase())
            .toSet();

        for (final from in recolor.fills.keys) {
          expect(
            present,
            contains(from.toLowerCase()),
            reason: '${accessory.id} recolours $from, which is not in '
                '${source.asset} -- it would render as ${source.id}',
          );
        }
      }
    });

    test('every accessory drawing and wardrobe icon is on disk', () {
      for (final accessory in kAccessories) {
        expect(File(accessory.asset).existsSync(), isTrue,
            reason: '${accessory.id}: ${accessory.asset}');
        // Variants borrow the source's icon, so only shapes need their own.
        if (accessory.recolor != null) continue;
        final icon = accessory.asset.replaceFirst('.svg', '_icon.svg');
        expect(File(icon).existsSync(), isTrue, reason: '${accessory.id}: $icon');
      }
    });
  });
}
