import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/boss_trial/moss_ui_art.dart';
import 'package:mojilearner_flutter/components/boss_trial/pixel_sprite.dart';

/// Mossback's UI pieces come from the owner's sprite sheet through
/// art_src/gen_moss_ui.py. A bad re-export shows up here, not as a torn
/// panel in the arena.
void main() {
  const pieces = {
    'panel': mossPanel,
    'tile': mossTile,
    'groove': mossGroove,
    'vine': mossVine,
    'rubble': mossRubble,
    'stone': mossStone,
    'cup': mossCup,
    'pebble': mossPebble,
  };

  for (final MapEntry(key: name, value: sprite) in pieces.entries) {
    test('$name is a whole grid in its palette', () {
      for (final row in sprite.rows) {
        expect(row.length, sprite.width, reason: '$name: ragged row');
        for (final letter in row.split('')) {
          expect(letter == '.' || sprite.palette.containsKey(letter), isTrue,
              reason: '$name: no colour for "$letter"');
        }
      }
      for (final (run, n) in [
        (sprite.midX, sprite.width),
        (sprite.midY, sprite.height)
      ]) {
        if (run == null) continue;
        expect(run.$1 >= 0 && run.$1 < run.$2 && run.$2 <= n, isTrue,
            reason: '$name: repeating run $run outside 0..$n');
      }
    });
  }

  test('the pieces words go on have a face to recolour', () {
    for (final sprite in [mossPanel, mossTile, mossRubble, mossStone]) {
      expect(sprite.rows.any((r) => r.contains(PixelSprite.face)), isTrue);
    }
  });

  test('the groove is as tall as the charge bar at two pixels a cell', () {
    expect(mossGroove.height * 2, 14);
  });

  test('draws at sizes smaller and larger than its own', () {
    for (final size in [
      const Size(40, 20),
      const Size(361, 52),
      const Size(96, 46)
    ]) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      mossPanel.paintTiled(canvas, size, 2);
      mossTile.paintTiled(canvas, size, 2, face: const Color(0xFFF1A7A9));
      mossRubble.paintToHeight(canvas, size);
      mossCup.paintContained(canvas, size);
      recorder.endRecording();
    }
  });
}
