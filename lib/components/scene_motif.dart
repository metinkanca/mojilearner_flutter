import 'package:flutter/material.dart';

import '../constants/scenes.dart';

/// One of a scene's drawings — the airliner, the control tower, a cloud.
///
/// Painted rather than built. A motif is a few hundred hard-edged rectangles,
/// and the obvious rendering — a `Positioned` and a `ColoredBox` per block —
/// puts every one of them in the widget tree, on a screen that rebuilds
/// whenever the pet moves. That worked while the airfield was traced at half
/// the reference's resolution and stopped being defensible the moment it was
/// not: this is one render object drawing rectangles, so detail costs
/// drawing time and nothing else, and the art can be as fine as the source.
///
/// Both the home screen and [SceneThumbnail] use this, which is also what
/// keeps a tile an honest miniature of the screen — the two used to hold
/// separate copies of the same arithmetic.
class SceneMotifBox extends StatelessWidget {
  const SceneMotifBox({
    super.key,
    required this.motif,
    required this.inks,
    this.scale = 1.0,
  });

  final SceneMotif motif;

  /// The palette's motif inks, indexed by [SceneMotifBlock.ink].
  final List<Color> inks;

  /// Shrinks the whole drawing as a unit. 1.0 on the home screen, which is
  /// what the art is authored against; smaller on a tile.
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment(motif.x, motif.y),
      child: SizedBox(
        width: motif.width * scale,
        height: motif.height * scale,
        child: CustomPaint(
          painter: _MotifPainter(motif: motif, inks: inks, scale: scale),
          // Nothing is drawn outside the motif's own box, and saying so lets
          // the painter skip the clip layer.
          isComplex: true,
          willChange: false,
        ),
      ),
    );
  }
}

class _MotifPainter extends CustomPainter {
  _MotifPainter({
    required this.motif,
    required this.inks,
    required this.scale,
  });

  final SceneMotif motif;
  final List<Color> inks;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    // Anti-aliasing is the enemy here: it would feather every block edge into
    // its neighbour and turn pixel art into a smudge.
    final paint = Paint()..isAntiAlias = false;
    for (final block in motif.blocks) {
      // An ink past the end of the palette draws nothing. A short palette
      // therefore loses part of a drawing rather than throwing on a frame —
      // and `scenes_test.dart` fails on it, which is where that should be
      // caught.
      if (block.ink >= inks.length) continue;
      paint.color = block.opacity == 1.0
          ? inks[block.ink]
          : inks[block.ink].withValues(alpha: block.opacity);
      canvas.drawRect(
        Rect.fromLTWH(
          block.x * scale,
          block.y * scale,
          // Never rounded away to nothing: on the smallest tiles a cell is
          // under a pixel across, and a drawing that lost its thinnest
          // blocks would lose its outline first.
          (block.width * scale).clamp(1.0, block.width),
          (block.height * scale).clamp(1.0, block.height),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MotifPainter old) =>
      old.motif != motif || old.scale != scale || old.inks != inks;
}
