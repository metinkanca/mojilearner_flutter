/// The drawn pieces of the boss arena: the ledge the boss stands on, the
/// rubble that breaks off it, the rock thrown back, and the shout.
///
/// All of it is drawn on whole pixels in the boss's own stone colours, with
/// cut corners instead of rounded ones, so it sits in the same pixel-art world
/// as the sprites.
library;

import 'package:flutter/material.dart';

import '../speech_bubble_tail.dart';
import 'moss_ui_art.dart';
import 'pixel_sprite.dart';
import 'trial_particles.dart';
import 'trial_skin.dart';

/// The pale face a word is written on.
const Color kSlabFace = Color(0xFFD9D3C2);
const Color _stoneLight = Color(0xFFB4AE9F);

/// The four colours a slab is drawn in. Stone for the boss's rubble; the
/// home game of catch paints the same slab as toy blocks.
class SlabPalette {
  const SlabPalette({
    required this.outline,
    required this.body,
    required this.light,
    required this.shade,
  });

  /// A block of [body], lit and shaded from it, in the arena's outline.
  SlabPalette.tinted(this.body)
      : outline = DebrisPalette.outline,
        light = Color.lerp(body, const Color(0xFFFFFFFF), 0.35)!,
        shade = Color.lerp(body, const Color(0xFF000000), 0.3)!;

  final Color outline;
  final Color body;
  final Color light;
  final Color shade;

  static const SlabPalette stone = SlabPalette(
    outline: DebrisPalette.outline,
    body: DebrisPalette.stone,
    light: _stoneLight,
    shade: DebrisPalette.seam,
  );
}

/// A chunky slab: outline, body, a lit top edge and a shaded bottom one, with
/// its corners cut back by one [unit].
void _paintSlab(
  Canvas canvas,
  Rect r,
  double unit, {
  Color? face,
  SlabPalette palette = SlabPalette.stone,
}) {
  final u = unit.roundToDouble().clamp(2.0, 6.0);
  final paint = Paint()..isAntiAlias = false;
  final x0 = r.left.roundToDouble(), y0 = r.top.roundToDouble();
  final x1 = r.right.roundToDouble(), y1 = r.bottom.roundToDouble();

  Path notched(double inset) {
    final a = x0 + inset, b = y0 + inset, c = x1 - inset, d = y1 - inset;
    return Path()
      ..moveTo(a + u, b)
      ..lineTo(c - u, b)
      ..lineTo(c - u, b + u)
      ..lineTo(c, b + u)
      ..lineTo(c, d - u)
      ..lineTo(c - u, d - u)
      ..lineTo(c - u, d)
      ..lineTo(a + u, d)
      ..lineTo(a + u, d - u)
      ..lineTo(a, d - u)
      ..lineTo(a, b + u)
      ..lineTo(a + u, b + u)
      ..close();
  }

  canvas.drawPath(notched(0), paint..color = palette.outline);
  canvas.drawPath(notched(u), paint..color = palette.body);
  // Lit top, shaded bottom.
  canvas.drawRect(Rect.fromLTRB(x0 + 2 * u, y0 + u, x1 - 2 * u, y0 + 2 * u),
      paint..color = palette.light);
  canvas.drawRect(Rect.fromLTRB(x0 + 2 * u, y1 - 2 * u, x1 - 2 * u, y1 - u),
      paint..color = palette.shade);
  if (face != null) {
    canvas.drawRect(
        Rect.fromLTRB(x0 + 2 * u, y0 + 2 * u, x1 - 2 * u, y1 - 2 * u),
        paint..color = face);
  }
}

/// A slab — in the boss's stone for rubble, a thrown rock or a word stone,
/// or in [palette] for anything else built the same way.
class SlabPainter extends CustomPainter {
  const SlabPainter({this.face, this.palette = SlabPalette.stone});

  /// The flat face words are written on, or null for bare stone.
  final Color? face;
  final SlabPalette palette;

  @override
  void paint(Canvas canvas, Size size) => _paintSlab(
        canvas,
        Offset.zero & size,
        (size.shortestSide / 12).roundToDouble(),
        face: face,
        palette: palette,
      );

  @override
  bool shouldRepaint(covariant SlabPainter old) =>
      old.face != face || old.palette != palette;
}

/// A piece of falling rubble carrying a meaning.
class RubbleTile extends StatelessWidget {
  const RubbleTile({
    super.key,
    required this.label,
    required this.style,
    required this.onTapDown,
    this.palette = SlabPalette.stone,
    this.face = kSlabFace,
  });

  final String label;
  final TextStyle style;
  final VoidCallback onTapDown;
  final SlabPalette palette;
  final Color face;

  @override
  Widget build(BuildContext context) {
    final words = Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(label, maxLines: 1, style: style),
      ),
    );
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        // On the press, not the release: a tap that lands a frame before the
        // rubble does should count.
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => onTapDown(),
        // Mossback's own chunk of rubble from its sheet; anything else (the
        // home game's toy blocks) is a slab.
        child: TrialSkinScope.of(context) == TrialSkin.moss
            ? LayoutBuilder(builder: (context, box) {
                // Its face, in the sheet's cells: 5 in from the left, 3 from
                // the right, 3 from the top and the bottom.
                final cell = box.maxHeight / mossRubble.height;
                return CustomPaint(
                  painter: PixelSpritePainter.toHeight(mossRubble,
                      face: face == kSlabFace ? null : face),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        5 * cell, 3 * cell, 3 * cell, 3 * cell),
                    child: words,
                  ),
                );
              })
            : CustomPaint(
                painter: SlabPainter(face: face, palette: palette),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: words,
                ),
              ),
      ),
    );
  }
}

/// The rubble on its way back to the boss: the same stone, word knocked off.
class ThrownRock extends StatelessWidget {
  const ThrownRock({super.key});

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: TrialSkinScope.of(context) == TrialSkin.moss
            ? const PixelSpritePainter.contained(mossRubble)
            : const SlabPainter(),
      );
}

/// The ledge the boss stands on, running the width of the arena.
class LedgePainter extends CustomPainter {
  const LedgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    final w = size.width, h = size.height.roundToDouble();
    const u = 4.0;

    // Body, with a stepped, broken underside.
    final body = Path()..moveTo(0, 0)..lineTo(w, 0)..lineTo(w, h - u);
    var x = w;
    var low = false;
    while (x > 0) {
      final step = (x / 16).floor().isEven ? 20.0 : 12.0;
      final nx = (x - step).clamp(0.0, w);
      body.lineTo(x, low ? h : h - u);
      body.lineTo(nx, low ? h : h - u);
      low = !low;
      x = nx;
    }
    body.close();
    canvas.drawPath(body, paint..color = DebrisPalette.outline);

    final inner = Rect.fromLTRB(0, u, w, h - 2 * u);
    canvas.drawRect(inner, paint..color = DebrisPalette.stone);
    // Moss along the top, where the boss's feet are.
    canvas.drawRect(Rect.fromLTRB(0, u, w, 2 * u), paint..color = DebrisPalette.moss);
    // Block seams.
    paint.color = DebrisPalette.seam;
    var row = 0;
    for (var y = 2 * u; y < h - 2 * u; y += 2 * u, row++) {
      canvas.drawRect(Rect.fromLTRB(0, y + 2 * u - 1, w, y + 2 * u), paint);
      for (var sx = row.isEven ? 0.0 : 18.0; sx < w; sx += 36) {
        canvas.drawRect(Rect.fromLTRB(sx, y, sx + 2, y + 2 * u), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LedgePainter oldDelegate) => false;
}

/// The boss's shout: the word it said, in a pixel speech bubble whose tail
/// points [tailX] from the bubble's left edge.
class ShoutBubble extends StatelessWidget {
  const ShoutBubble({
    super.key,
    required this.word,
    required this.style,
    required this.tailX,
  });

  final String word;
  final TextStyle style;
  final double tailX;

  static const double tailW = 18;
  static const double tailH = 12;

  @override
  Widget build(BuildContext context) {
    // In the boss's colours when fought under one: its face, and its rim.
    final skin = TrialSkinScope.of(context);
    if (skin == TrialSkin.moss) return _mossBubble();
    final face = skin == null ? Colors.white : skin.tileFace;
    final rim = skin == null ? DebrisPalette.outline : skin.colors.rimDark;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          bottom: tailH - 3,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: face,
              border: Border.all(color: rim, width: 3),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(word, maxLines: 1, style: style),
            ),
          ),
        ),
        Positioned(
          left: tailX - tailW / 2,
          bottom: 0,
          width: tailW,
          height: tailH,
          child: const CustomPaint(painter: PixelTrianglePainter()),
        ),
      ],
    );
  }

  /// Mossback's: its sheet's text panel, a stone tail stepping down out of
  /// its foot to the mouth.
  Widget _mossBubble() {
    const cell = 2.0;
    return LayoutBuilder(builder: (context, box) {
      // The panel on whole cells, leaving room under it for the tail. Its
      // last row is only the moss dripping off it, and the row above that its
      // outline: the tail starts on the outline, opening it.
      final panelH =
          ((box.maxHeight - (_mossTail.height - 2) * cell) / cell).floor() *
              cell;
      final tailW = _mossTail.width * cell;
      final left = ((tailX - tailW / 2) / cell).round() * cell;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: panelH,
            child: CustomPaint(
              painter: const PixelSpritePainter.tiled(mossPanel, cell: cell),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(word, maxLines: 1, style: style),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: left,
            top: panelH - 2 * cell,
            width: tailW,
            height: _mossTail.height * cell,
            child: const CustomPaint(
              painter: PixelSpritePainter.tiled(_mossTail, cell: cell),
            ),
          ),
        ],
      );
    });
  }
}

/// The tail of Mossback's speech: not on the owner's sheet, so drawn here in
/// its colours — the panel's stone, lit down the left, shaded down the right.
const PixelSprite _mossTail = PixelSprite(
  palette: mossPalette,
  rows: [
    'KHPPPPPPPPPSK',
    '.KHPPPPPPPSK.',
    '..KHPPPPPSK..',
    '...KHPPPSK...',
    '....KHPSK....',
    '.....KSK.....',
    '......K......',
  ],
);
