import 'package:flutter/material.dart';

import '../constants/pixel_flags.dart';
import '../constants/theme.dart';

/// A language's flag, drawn as pixels.
///
/// Sized by [height]; the width follows from the 12x8 grid, so a column of
/// these lines up whatever mix of flags is in it. The dark outline is the same
/// one every other retro surface in the app wears.
class PixelFlag extends StatelessWidget {
  /// Language code, as used by `LanguageProvider`. An unknown code draws the
  /// neutral fallback plate rather than nothing.
  final String code;

  /// Height of the flag itself, outline excluded.
  final double height;

  /// Thickness of the outline. Zero draws none.
  final double borderWidth;

  const PixelFlag({
    super.key,
    required this.code,
    this.height = 16,
    this.borderWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    final grid = pixelFlags[code] ?? pixelFlagFallback;
    final width = height * pixelFlagColumns / pixelFlagRows;
    return SizedBox(
      width: width + borderWidth * 2,
      height: height + borderWidth * 2,
      child: CustomPaint(
        painter: _PixelFlagPainter(grid: grid, borderWidth: borderWidth),
      ),
    );
  }
}

class _PixelFlagPainter extends CustomPainter {
  final List<String> grid;
  final double borderWidth;

  const _PixelFlagPainter({required this.grid, required this.borderWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = (size.width - borderWidth * 2) / pixelFlagColumns;
    final cellHeight = (size.height - borderWidth * 2) / pixelFlagRows;
    final paint = Paint()..isAntiAlias = false;

    canvas.save();
    // Clipped so the half-pixel overlap below cannot bleed under the outline.
    canvas.clipRect(Rect.fromLTWH(
      borderWidth,
      borderWidth,
      size.width - borderWidth * 2,
      size.height - borderWidth * 2,
    ));

    for (var row = 0; row < grid.length; row++) {
      final cells = grid[row];
      var start = 0;
      while (start < cells.length) {
        // Runs of one colour are drawn as one rect: fewer seams to land on a
        // fractional pixel, and far fewer draw calls per list row.
        var end = start + 1;
        while (end < cells.length && cells[end] == cells[start]) {
          end++;
        }
        paint.color = pixelFlagPalette[cells[start]] ?? Colors.transparent;
        // Half a pixel of overlap: at fractional cell sizes, exact rects leave
        // hairline gaps between neighbouring runs.
        canvas.drawRect(
          Rect.fromLTWH(
            borderWidth + start * cellWidth,
            borderWidth + row * cellHeight,
            (end - start) * cellWidth + 0.5,
            cellHeight + 0.5,
          ),
          paint,
        );
        start = end;
      }
    }
    canvas.restore();

    if (borderWidth > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
          borderWidth / 2,
          borderWidth / 2,
          size.width - borderWidth,
          size.height - borderWidth,
        ),
        Paint()
          ..color = AppTheme.retroDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth
          ..isAntiAlias = false,
      );
    }
  }

  @override
  bool shouldRepaint(_PixelFlagPainter oldDelegate) =>
      oldDelegate.grid != grid || oldDelegate.borderWidth != borderWidth;
}
