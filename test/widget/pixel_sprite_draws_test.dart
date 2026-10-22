import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/boss_trial/pixel_sprite.dart';
import 'package:mojilearner_flutter/components/boss_trial/sand_ui_art.dart';
import 'package:mojilearner_flutter/components/boss_trial/sphinx_pieces.dart';
import 'package:mojilearner_flutter/utils/boss_trial_sphinx.dart';

/// The boss skins' pixel pieces are drawn from an image of each, made once,
/// rather than replayed as the rectangles they are made of.
///
/// On the phone every rectangle is a draw of its own, so the replay was what
/// sank the Sandstorm: thirty sand tiles of 550 rectangles each, 16,500 draws
/// a frame. These hold the count down to a draw a piece, and check the image
/// is the same picture the rectangles made.
void main() {
  /// Counts the calls made on it, by name, and does nothing else.
  final counted = <String, int>{};

  int count(String name) => counted[name] ?? 0;

  setUp(counted.clear);

  testWidgets('the storm grid is a draw a tile, not hundreds', (tester) async {
    const grid = Size(388, 323);
    const SandGridPainter(
      cols: SphinxRules.stormCols,
      rows: SphinxRules.stormRows,
      lit: [],
      found: false,
      refused: [],
    ).paint(_CountingCanvas(counted), grid);

    expect(count('drawImageRect'),
        SphinxRules.stormCols * SphinxRules.stormRows);
    expect(count('drawRect'), 0);
  });

  testWidgets('the drifting sand is two draws, not two a column',
      (tester) async {
    const SandDriftPainter(0.8).paint(_CountingCanvas(counted), const Size(388, 323));

    expect(count('drawPath'), 2);
    expect(count('drawRect'), 0);
  });

  testWidgets('the image is the picture the rectangles made', (tester) async {
    // Whole cells at a whole number of pixels, so every one of them can be
    // drawn as a plain rectangle to compare against.
    const cell = 3.0;
    final sprite = sandCell;
    final size = Size(sprite.width * cell, sprite.height * cell);

    Future<Uint8List> capture(CustomPainter painter) async {
      final key = GlobalKey();
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: key,
            child: CustomPaint(size: size, painter: painter),
          ),
        ),
      ));
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      return (await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData();
        image.dispose();
        return bytes!.buffer.asUint8List();
      }))!;
    }

    final drawn =
        await capture(PixelSpritePainter.tiled(sprite, cell: cell));
    final cells = await capture(_CellByCell(sprite, cell));

    expect(drawn.length, cells.length);
    var differing = 0;
    for (var i = 0; i < drawn.length; i++) {
      if (drawn[i] != cells[i]) differing++;
    }
    expect(differing, 0);
  });
}

/// The sprite as plain rectangles, a cell at a time: what it should look like.
class _CellByCell extends CustomPainter {
  _CellByCell(this.sprite, this.cell);

  final PixelSprite sprite;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    for (var y = 0; y < sprite.height; y++) {
      for (var x = 0; x < sprite.width; x++) {
        final letter = sprite.rows[y][x];
        if (letter == '.') continue;
        canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell),
            paint..color = sprite.palette[letter]!);
      }
    }
  }

  @override
  bool shouldRepaint(_CellByCell old) => false;
}

class _CountingCanvas implements Canvas {
  _CountingCanvas(this.counts);

  final Map<String, int> counts;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // A Symbol prints as Symbol("drawRect").
    final name = invocation.memberName.toString();
    final member = RegExp(r'"(\w+)"').firstMatch(name)?.group(1) ?? name;
    counts[member] = (counts[member] ?? 0) + 1;
    return null;
  }
}
