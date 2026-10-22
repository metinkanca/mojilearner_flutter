/// The drawn pieces of Pyrewing's fight: the fireball it breathes in the
/// Spells round, and its colours. Everything else of its is drawn in its
/// skin (`trial_skin.dart`) from the owner's sheet (`fire_ui_art.dart`):
/// its words on basalt panels with flames along them, its replies and
/// embers on burnt scrolls, its runes on stone, its hoard in gold coins.
library;

import 'dart:math';

import 'package:flutter/material.dart';

import 'arena_pieces.dart';
import 'fire_ui_art.dart';
import 'pixel_sprite.dart';
import 'trial_particles.dart';

/// A rune stone's height as the owner drew it, a point a cell: the Link
/// round makes room for all of it when it can.
final double runeStoneHeight = fireRune.height.toDouble();

/// Pyrewing's colours, lifted from its sprite (`art_src/gen_dragon.py`), bar
/// the [ember]: its fire's edge, which the sprite's flame no longer draws.
class DragonPalette {
  DragonPalette._();
  static const Color outline = Color(0xFF14120E);
  static const Color ember = Color(0xFFDC5A30);
  static const Color body = Color(0xFFCF4F2F);
  static const Color gold = Color(0xFFF0A93C);
  static const Color cream = Color(0xFFFBE9BF);

  /// Basalt, for its reply slabs.
  static const SlabPalette slab = SlabPalette(
    outline: outline,
    body: Color(0xFF5A4A4C),
    light: Color(0xFF7A6668),
    shade: Color(0xFF3B3032),
  );

  /// A scorched pet's ash, and the sparks and smoke of its fire.
  static const Color ash = Color(0xFF4A4244);
  static const List<Color> sparks = [ember, gold, cream];
  static const List<Color> smoke = [ash, Color(0xFF6A6062), Color(0xFF8A8082)];
}

/// The fireball it breathes over its head in the Spells round, and throws:
/// the owner's, from the sheet, as large as fits.
class FireballSprite extends StatelessWidget {
  const FireballSprite({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: PixelSpritePainter.contained(fireball));
}

/// The lids over the sleeping dragon's eyes, drawn over its own box (its
/// sprite's 136 x 117 cells): [open] 0 is shut tight, 1 is as it was drawn,
/// glaring.
class DragonEyelids extends StatelessWidget {
  const DragonEyelids({super.key, required this.open});

  final double open;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _EyelidPainter(open));
}

class _EyelidPainter extends CustomPainter {
  const _EyelidPainter(this.open);

  final double open;

  /// The sprite's size in cells, and its two eyes, with their brows, in
  /// them: left, top, width, height. All from `art_src/gen_dragon.py`.
  static const double _cellsW = 136, _cellsH = 117;
  static const List<(double, double, double, double)> _eyes = [
    (86.0, 44.0, 6.0, 11.0),
    (109.0, 44.0, 6.0, 11.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final o = open.clamp(0.0, 1.0);
    if (o >= 1) return;
    final sx = size.width / _cellsW, sy = size.height / _cellsH;
    final paint = Paint()..isAntiAlias = false;
    for (final (l, t, w, h) in _eyes) {
      final lid = (h * (1 - o) * 4).round() / 4;
      if (lid <= 0) continue;
      final lidded = Rect.fromLTWH(l * sx, t * sy, w * sx, lid * sy);
      canvas.drawRect(lidded.inflate(0.5), paint..color = DragonPalette.body);
      // The lid's edge: a dark line along it.
      canvas.drawRect(
          Rect.fromLTWH(l * sx, lidded.bottom - sy * 0.6, w * sx, sy * 1.2),
          paint..color = DragonPalette.outline);
    }
  }

  @override
  bool shouldRepaint(covariant _EyelidPainter old) => old.open != open;
}

/// The bridge of light that forms between the two flames once the rune that
/// joins them lands: from [rune] up to the first flame and down to the
/// second, growing out from the rune as [progress] runs from 0 to 1.
class BridgePainter extends CustomPainter {
  const BridgePainter({
    required this.progress,
    required this.x,
    required this.top,
    required this.rune,
    required this.bottom,
  });

  final double progress;
  final double x, top, bottom;
  final Rect rune;

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.clamp(0.0, 1.0);
    if (p <= 0) return;
    final paint = Paint()..isAntiAlias = false;
    void bar(double from, double to) {
      final len = (to - from) * p;
      if (len.abs() < 1) return;
      final a = from, b = from + len;
      final r = Rect.fromLTRB(x - 6, min(a, b), x + 6, max(a, b));
      canvas.drawRect(r, paint..color = DebrisPalette.rune.withValues(alpha: 0.75));
      canvas.drawRect(Rect.fromLTRB(x - 2, r.top, x + 2, r.bottom),
          paint..color = DebrisPalette.runeLight);
      // Motes running along it.
      for (var y = r.top.roundToDouble() + 4; y < r.bottom; y += 20) {
        canvas.drawRect(Rect.fromLTWH(x - 8, y, 4, 4),
            paint..color = DebrisPalette.runeLight);
        canvas.drawRect(Rect.fromLTWH(x + 4, y + 8, 4, 4),
            paint..color = DebrisPalette.runeLight);
      }
    }

    bar(rune.top, top);
    bar(rune.bottom, bottom);
  }

  @override
  bool shouldRepaint(covariant BridgePainter old) =>
      old.progress != progress ||
      old.x != x ||
      old.top != top ||
      old.bottom != bottom ||
      old.rune != rune;
}

/// Soot on the pet's whiskers, drawn over the pet's box: [fade] 1 is freshly
/// singed, 0 is gone.
class WhiskerSootPainter extends CustomPainter {
  const WhiskerSootPainter({required this.fade, required this.facesLeft});

  final double fade;
  final bool facesLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final f = fade.clamp(0.0, 1.0);
    if (f <= 0) return;
    final paint = Paint()
      ..isAntiAlias = false
      ..color = DragonPalette.outline.withValues(alpha: min(1.0, f * 1.6) * 0.85);
    final cx = size.width * (facesLeft ? 0.42 : 0.58);
    final cy = size.height * 0.56;
    for (final side in const [-1.0, 1.0]) {
      for (var i = 0; i < 3; i++) {
        final x0 = cx + side * size.width * (0.1 + 0.015 * i);
        final len = size.width * (0.1 - 0.015 * i);
        final y = (cy + (i - 1) * 6).roundToDouble();
        final left = side < 0 ? x0 - len : x0;
        canvas.drawRect(Rect.fromLTWH(left.roundToDouble(), y, len, 3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant WhiskerSootPainter old) =>
      old.fade != fade || old.facesLeft != facesLeft;
}
