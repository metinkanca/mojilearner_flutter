import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/play/play_kit.dart';
import 'package:mojilearner_flutter/components/play/toy_chest_art.dart';

/// The toy chest's pixel pieces are drawn from an image of each, made once,
/// rather than replayed as the rectangles they are made of.
///
/// On the phone every rectangle is a draw of its own, and the games rebuild
/// their scene every frame: ten bubbles of 289 cells each rising through the
/// bath was thousands of draws a frame, and the game stuttered. These hold the
/// count to a draw a piece and check the image is the picture the rectangles
/// made.
void main() {
  final counted = <String, int>{};
  int count(String name) => counted[name] ?? 0;

  setUp(counted.clear);

  test('a bubble is one draw, however many cells it has', () {
    const size = Size(51, 51);
    const painter = PixelPatternPainter(bathBubbleArtRows, bathBubbleArtInks);

    // Drawn twice, the way two frames draw it: the second is the cached one.
    painter.paint(_CountingCanvas(counted), size);
    painter.paint(_CountingCanvas(counted), size);

    expect(count('drawImageRect'), 2);
    expect(count('drawRect'), 0);
  });

  testWidgets('the image is the picture the rectangles made', (tester) async {
    // The bubble: round, so its runs of cells differ row to row.
    final rows = bathBubbleArtRows;
    final inks = bathBubbleArtInks;
    const cell = 3.0;
    final size = Size(rows.first.length * cell, rows.length * cell);

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

    for (final mirrored in [false, true]) {
      final drawn = await capture(
          PixelPatternPainter(rows, inks, mirrored: mirrored));
      final cells = await capture(_CellByCell(rows, inks, mirrored));

      expect(drawn.length, cells.length);
      var differing = 0;
      for (var i = 0; i < drawn.length; i++) {
        if (drawn[i] != cells[i]) differing++;
      }
      expect(differing, 0, reason: 'mirrored: $mirrored');
    }
  });

  test('a pattern rebuilt with the same inks is not made again', () {
    const size = Size(45, 45);
    final before = PixelPatternPainter.cachedImages;
    // A new map every time, as a tile that greys a toy out builds one.
    for (var i = 0; i < 3; i++) {
      final inks = {for (final e in toyCatchArtInks.entries) e.key: e.value};
      PixelPatternPainter(toyCatchArtRows, inks)
          .paint(_CountingCanvas(counted), size);
    }

    expect(PixelPatternPainter.cachedImages, before + 1);
  });
}

/// The pattern as plain rectangles, a cell at a time: what it should look like.
class _CellByCell extends CustomPainter {
  _CellByCell(this.rows, this.inks, this.mirrored);

  final List<String> rows;
  final Map<String, Color> inks;
  final bool mirrored;

  @override
  void paint(Canvas canvas, Size size) {
    final cols = rows.fold<int>(0, (m, r) => r.length > m ? r.length : m);
    final cw = size.width / cols;
    final ch = size.height / rows.length;
    final paint = Paint()..isAntiAlias = false;
    for (var y = 0; y < rows.length; y++) {
      for (var x = 0; x < rows[y].length; x++) {
        final ink = inks[rows[y][x]];
        if (ink == null) continue;
        final col = mirrored ? cols - 1 - x : x;
        canvas.drawRect(Rect.fromLTWH(col * cw, y * ch, cw + 0.5, ch + 0.5),
            paint..color = ink);
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
