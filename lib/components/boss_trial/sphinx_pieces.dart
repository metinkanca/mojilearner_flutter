/// The drawn pieces of Sableth's fight: the talk panel its words go on
/// (shared with Pyrewing, in whichever boss's look it is fought under), the
/// carved door of the Sealed Door and its dial, the hourglass it turns in the
/// Spells round, and the sand that buries the pet when anything gets
/// through. Its answers are [SkinTile]s — cartouches, and stone tablets.
///
/// Sableth's colours are sandstone and headdress blue, lifted from its sprite
/// (`art_src/gen_sphinx.py`). The door, its dial, the sand grid's tiles, the
/// hourglass and the heap of sand are the owner's sheet (`sand_ui_art.dart`,
/// from `art_src/gen_sand_ui.py`); the slot rail of the Tablets round is
/// still painted here.
library;

import 'dart:math';

import 'package:flutter/material.dart';

import 'arena_pieces.dart';
import 'sand_ui_art.dart';
import 'trial_particles.dart';
import 'trial_skin.dart';

const double _cell = 4;

/// The owner's sheet is drawn a point a cell, as the skin's panel is.
const double _sheetCell = 1;

/// Sableth's colours, lifted from its sprite.
class SphinxPalette {
  SphinxPalette._();
  static const Color outline = Color(0xFF14120E);
  static const Color sandstone = Color(0xFFD8963A);
  static const Color cream = Color(0xFFF7DCA5);
  static const Color band = Color(0xFF304B68);

  /// The sand that runs through its hourglass and buries the pet.
  static const Color sand = Color(0xFFD8B06A);
  static const Color sandDark = Color(0xFFA9844A);

  static const SlabPalette slab = SlabPalette(
    outline: outline,
    body: Color(0xFFC99A4E),
    light: Color(0xFFE6C07A),
    shade: Color(0xFF8E6A36),
  );

  /// Sand thrown up, and the dust of its landing.
  static const List<Color> dust = [sand, sandDark, cream];
}

/// A boss's words, on a panel above it in its own look, and how long it will
/// wait, as its charge bar along the panel's foot.
class TalkPanel extends StatelessWidget {
  const TalkPanel({
    super.key,
    required this.text,
    required this.style,
    required this.clock,
    this.label,
    this.labelStyle,
  });

  final String text;
  final TextStyle style;

  /// How much of its patience is gone, from 0 to 1.
  final double clock;

  /// A line above the words, in the player's language: what to do.
  final String? label;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final skin = TrialSkinScope.of(context) ?? TrialSkin.sand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SkinPrompt(
            skin: skin,
            label: label ?? '',
            text: text,
            labelStyle: labelStyle ?? style,
            textStyle: style,
            maxLines: 4,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(height: 12, child: SkinBar(skin: skin, value: clock)),
      ],
    );
  }
}

// ---- Sealed Door ------------------------------------------------------------

/// The door: a sandstone slab between two pillars under a striped lintel,
/// the sentence carved across it and a stone dial set in the gap. The dial
/// takes a tap to turn; the push is a tap on the slab at the door's foot.
class SealedDoor extends StatelessWidget {
  const SealedDoor({
    super.key,
    required this.before,
    required this.after,
    required this.dial,
    required this.turn,
    required this.base,
    required this.style,
    required this.baseStyle,
    required this.onTurn,
    required this.onPush,
    this.state = TileState.plain,
    this.textDirection = TextDirection.ltr,
  });

  final List<String> before;
  final List<String> after;

  /// The form the dial shows now, how many times it has turned, and the
  /// word it is a form of.
  final String dial;
  final int turn;
  final String base;
  final TextStyle style;
  final TextStyle baseStyle;
  final VoidCallback? onTurn;
  final VoidCallback? onPush;

  /// The dial's face: plain, refused, or opened.
  final TileState state;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    Widget carved(String w) => Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE6C98E),
            border: Border(
              top: BorderSide(color: SphinxPalette.slab.shade, width: 3),
              left: BorderSide(color: SphinxPalette.slab.shade, width: 3),
              bottom: const BorderSide(color: Color(0xFFF6E3B4), width: 2),
              right: const BorderSide(color: Color(0xFFF6E3B4), width: 2),
            ),
          ),
          child: Align(
            widthFactor: 1,
            child: Text(w, maxLines: 1, style: style),
          ),
        );

    final dialTile = Semantics(
      button: onTurn != null,
      label: 'turn: $dial',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: onTurn == null ? null : (_) => onTurn!(),
        child: CustomPaint(
          painter: _DialPainter(turn: turn, state: state),
          child: Container(
            height: 52,
            constraints: const BoxConstraints(minWidth: 96),
            // Inside the dial's rim: its face starts 4 cells in and 7 down.
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('($base)', maxLines: 1, style: baseStyle),
                const SizedBox(height: 3),
                Text(dial, maxLines: 1, style: style),
              ],
            ),
          ),
        ),
      ),
    );

    return CustomPaint(
      painter: const _DoorPainter(),
      child: Padding(
        // Inside the doorway: clear of the pillars, the lintel, and the step.
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              textDirection: textDirection,
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final w in before) carved(w),
                dialTile,
                for (final w in after) carved(w),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 150,
              height: 40,
              child: SkinTile(
                skin: TrialSkin.sand,
                shape: TileShape.tablet,
                label: 'PUSH',
                style: baseStyle.copyWith(fontSize: 11),
                onTapDown: onPush,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The door's stone, from the owner's sheet: pillars either side, a lintel
/// striped like the headdress, the doorway between them. Its stripes repeat
/// every ten cells, so it is drawn as wide as whole repeats allow.
class _DoorPainter extends CustomPainter {
  const _DoorPainter();

  @override
  void paint(Canvas canvas, Size size) =>
      sandDoor.paintTiled(canvas, size, _sheetCell, wholeX: true);

  @override
  bool shouldRepaint(covariant _DoorPainter old) => false;
}

/// The dial set in the door, from the owner's sheet: a gold wheel as wide as
/// the word, with a notch on its rim that moves round a step each turn.
class _DialPainter extends CustomPainter {
  const _DialPainter({required this.turn, required this.state});

  final int turn;
  final TileState state;

  @override
  void paint(Canvas canvas, Size size) {
    final face = switch (state) {
      TileState.flashing => const Color(0xFFF1A7A9),
      TileState.right => DebrisPalette.runeLight,
      _ => null,
    };
    sandDial.paintTiled(canvas, size, _sheetCell, face: face);
    // The marker, a dark notch on the gold of the rim, a step further each
    // turn. The rim runs from the 6th cell in to the 8th from the end.
    final cols = (size.width / _sheetCell).floor();
    final steps = max(3, (cols - 16) ~/ 4 + 1);
    final x = 7 + (turn % steps) * 4;
    final rows = (size.height / _sheetCell).floor();
    canvas.drawRect(
      Rect.fromLTWH(
        ((size.width - cols * _sheetCell) / 2 + x * _sheetCell).roundToDouble(),
        ((size.height - rows * _sheetCell) / 2 + 3 * _sheetCell).roundToDouble(),
        2 * _sheetCell,
        2 * _sheetCell,
      ),
      Paint()
        ..isAntiAlias = false
        ..color = sandPalette['K']!,
    );
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) =>
      old.turn != turn || old.state != state;
}

// ---- Sandstorm --------------------------------------------------------------

/// The letter grid of the Sandstorm: a tile of sand for each letter, lit
/// along a swipe, gold once the word is found, red where a swipe found
/// nothing.
class SandGridPainter extends CustomPainter {
  const SandGridPainter({
    required this.cols,
    required this.rows,
    required this.lit,
    required this.found,
    required this.refused,
    this.cleared = const [],
  });

  final int cols, rows;
  final List<int> lit;
  final bool found;
  final List<int> refused;

  /// Cells the sand has been blown off, leaving the stone bare.
  final List<int> cleared;

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width / cols, ch = size.height / rows;
    for (var i = 0; i < cols * rows; i++) {
      // A point of the field between one tile and the next.
      final r = Rect.fromLTWH((i % cols) * cw, (i ~/ cols) * ch, cw, ch)
          .deflate(1);
      final face = cleared.contains(i)
          ? SphinxPalette.slab.shade
          : refused.contains(i)
              ? const Color(0xFFF1A7A9)
              : lit.contains(i)
                  ? (found ? SphinxPalette.sandstone : DebrisPalette.runeLight)
                  : ((i + i ~/ cols).isEven
                      ? const Color(0xFFEBD3AC)
                      : const Color(0xFFE3C99A));
      // The sheet's tile, its gold bevel round a face that takes the
      // state's colour.
      canvas
        ..save()
        ..translate(r.left.roundToDouble(), r.top.roundToDouble());
      sandCell.paintTiled(canvas, r.size, _sheetCell, face: face);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant SandGridPainter old) =>
      old.lit != lit ||
      old.found != found ||
      old.refused != refused ||
      old.cleared != cleared;
}

/// The storm drifting over the grid, laid over the letters: dunes rising
/// from the foot with [buried], thin enough that the letters still show.
class SandDriftPainter extends CustomPainter {
  const SandDriftPainter(this.buried);

  final double buried;

  @override
  void paint(Canvas canvas, Size size) {
    final b = buried.clamp(0.0, 1.0);
    if (b <= 0.02) return;
    final paint = Paint()..isAntiAlias = false;
    final cols = (size.width / _cell).floor();
    final peak = size.height * 0.85 * b;
    // Every column's sand as one shape and every crest as another: two draws
    // rather than two a column, which on a phone is two hundred a frame. The
    // columns never overlap, so it lands the same.
    final sand = Path(), crests = Path();
    for (var c = 0; c < cols; c++) {
      final wave = sin(c / 3.0 + b * 6) * 0.5 + 0.5;
      final h = ((peak * (0.7 + 0.3 * wave)) / _cell).round() * _cell;
      sand.addRect(Rect.fromLTWH(c * _cell, size.height - h, _cell, h));
      crests.addRect(Rect.fromLTWH(c * _cell, size.height - h, _cell, _cell));
    }
    canvas
      ..drawPath(sand, paint..color = SphinxPalette.sand.withValues(alpha: 0.55))
      ..drawPath(
          crests, paint..color = SphinxPalette.sandDark.withValues(alpha: 0.8));
  }

  @override
  bool shouldRepaint(covariant SandDriftPainter old) =>
      (old.buried * 20).floor() != (buried * 20).floor();
}

// ---- Riddle: the stamp and the crack ----------------------------------------

/// The seal the pet stamps on the tablet it chose: a ring and a cross cut in
/// the stone, coming down half as big again and settling as [progress] runs
/// from 0 to 1.
class SealMark extends StatelessWidget {
  const SealMark({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _SealPainter(progress));
}

class _SealPainter extends CustomPainter {
  const _SealPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.clamp(0.0, 1.0);
    if (p <= 0) return;
    final u = 3.0 * (1 + 0.6 * (1 - p) * (1 - p));
    const r = 5;
    final paint = Paint()
      ..isAntiAlias = false
      ..color = SphinxPalette.band.withValues(alpha: min(1.0, p * 6) * 0.9);
    final c = Offset(size.width - size.height * 0.62, size.height / 2);
    for (var j = -r; j <= r; j++) {
      for (var i = -r; i <= r; i++) {
        final d = sqrt((i * i + j * j).toDouble());
        final ring = d <= r + 0.4 && d >= r - 1.1;
        final cross = (i == 0 || j == 0) && d <= r - 1.5;
        if (!ring && !cross) continue;
        canvas.drawRect(
          Rect.fromLTWH(
              (c.dx + i * u - u / 2).roundToDouble(),
              (c.dy + j * u - u / 2).roundToDouble(),
              u.roundToDouble(),
              u.roundToDouble()),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SealPainter old) => old.progress != progress;
}

/// A crack running down a tablet the pet rammed that was not the answer,
/// opening from the top as [progress] runs from 0 to 1.
class TabletCrack extends StatelessWidget {
  const TabletCrack({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _CrackPainter(progress));
}

class _CrackPainter extends CustomPainter {
  const _CrackPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.clamp(0.0, 1.0);
    if (p <= 0) return;
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w * 0.58, 0)
      ..lineTo(w * 0.53, h * 0.26)
      ..lineTo(w * 0.62, h * 0.48)
      ..lineTo(w * 0.5, h * 0.7)
      ..lineTo(w * 0.57, h);
    final paint = Paint()
      ..isAntiAlias = false
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (final metric in path.computeMetrics()) {
      final cut = metric.extractPath(0, metric.length * p);
      canvas.drawPath(
          cut.shift(const Offset(2, 0)), paint..color = SphinxPalette.cream);
      canvas.drawPath(cut, paint..color = SphinxPalette.outline);
    }
  }

  @override
  bool shouldRepaint(covariant _CrackPainter old) => old.progress != progress;
}

// ---- Tablets: the slots ------------------------------------------------------

/// A place on the ground for a tablet the pet carries: a hollow cut in the
/// sand with the number of the line that goes in it.
class PlaqueSlot extends StatelessWidget {
  const PlaqueSlot({super.key, required this.number, required this.style});

  final String number;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: const _SlotPainter(),
        child: Center(
          child: Text(number,
              style: style.copyWith(
                  color: SphinxPalette.sandDark.withValues(alpha: 0.9))),
        ),
      );
}

class _SlotPainter extends CustomPainter {
  const _SlotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    final r = Offset.zero & size;
    canvas.drawRect(r, paint..color = SphinxPalette.sandDark);
    canvas.drawRect(
        r.deflate(2), paint..color = SphinxPalette.outline.withValues(alpha: 0.55));
    // A lit lip along its foot.
    canvas.drawRect(Rect.fromLTWH(2, size.height - 4, size.width - 4, 2),
        paint..color = SphinxPalette.cream.withValues(alpha: 0.7));
  }

  @override
  bool shouldRepaint(covariant _SlotPainter old) => false;
}

// ---- Sandstorm: the wind and the howl ----------------------------------------

/// Streaks of sand blown across the grid, right to left: faster and thicker the
/// more of the clock has run.
class WindStreaksPainter extends CustomPainter {
  const WindStreaksPainter({required this.time, required this.strength});

  /// The game clock, in seconds.
  final double time;

  /// 0 to 1.
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final s = strength.clamp(0.0, 1.0);
    final paint = Paint()..isAntiAlias = false;
    for (var i = 0; i < 10; i++) {
      final y = ((size.height * ((i * 0.137 + 0.06) % 1)) / 2).round() * 2.0;
      final speed = (110 + 55 * ((i * 7) % 5)) * (0.5 + s);
      final length = 14.0 + ((i * 11) % 18);
      final travel = size.width + length + 40;
      final x = size.width - ((time * speed + i * 53) % travel);
      paint.color = SphinxPalette.sandDark.withValues(alpha: 0.3 + 0.5 * s);
      canvas.drawRect(
          Rect.fromLTWH(x.roundToDouble(), y, length, i.isEven ? 3 : 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant WindStreaksPainter old) =>
      old.time != time || old.strength != strength;
}

/// The pet's howl: rings of sound spreading up from [origin], each a little
/// behind the one before, as [progress] runs from 0 to 1.
class HowlRingsPainter extends CustomPainter {
  const HowlRingsPainter({required this.origin, required this.progress});

  final Offset origin;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..isAntiAlias = false
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    for (var i = 0; i < 3; i++) {
      final k = ((progress - i * 0.16) / 0.7).clamp(0.0, 1.0);
      if (k <= 0 || k >= 1) continue;
      final radius = (16 + k * 150).roundToDouble();
      paint.color = (i.isEven ? SphinxPalette.band : SphinxPalette.sandstone)
          .withValues(alpha: (1 - k) * 0.9);
      canvas.drawArc(
        Rect.fromCircle(center: origin, radius: radius),
        -pi / 2 - 0.8,
        1.6,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant HowlRingsPainter old) =>
      old.origin != origin || old.progress != progress;
}

// ---- Spells round and the curse ---------------------------------------------

/// The hourglass Sableth turns in the Spells round and brings down on the pet
/// when the sand is through.
class HourglassSprite extends StatelessWidget {
  const HourglassSprite({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _HourglassPainter());
}

class _HourglassPainter extends CustomPainter {
  const _HourglassPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // The owner's hourglass, on whole cells whenever it fits at one or more,
    // and smaller ones while the charge is still growing to that.
    final fit = min(size.width / sandHourglass.width,
        size.height / sandHourglass.height);
    final u = fit >= 1 ? fit.floorToDouble() : fit;
    sandHourglass.paint(
      canvas,
      Offset((size.width - u * sandHourglass.width) / 2,
          (size.height - u * sandHourglass.height) / 2),
      sandHourglass.width,
      sandHourglass.height,
      cellW: u,
      cellH: u,
    );
  }

  @override
  bool shouldRepaint(covariant _HourglassPainter old) => false;
}

/// Sand heaped over the pet, drawn in front of it: [fill] 1 buries it to the
/// ears, 0 is none. The owner's pyramid of sand, as wide as the pet and a
/// little over, growing taller as it fills.
class SandPilePainter extends CustomPainter {
  const SandPilePainter(this.fill);

  final double fill;

  /// How far past the pet's box the heap spreads, so it covers the pet's
  /// flanks and not just what is under its peak.
  static const double _spread = 1.25;

  @override
  void paint(Canvas canvas, Size size) {
    // In twentieths, so it grows in visible steps and the pictures cache.
    final f = (fill.clamp(0.0, 1.0) * 20).ceil() / 20;
    if (f <= 0) return;
    final width = size.width * _spread;
    final height = size.height * 0.72 * f;
    sandHeap.paint(
      canvas,
      Offset((size.width - width) / 2, size.height - height),
      sandHeap.width,
      sandHeap.height,
      cellW: width / sandHeap.width,
      cellH: height / sandHeap.height,
    );
  }

  @override
  bool shouldRepaint(covariant SandPilePainter old) => old.fill != fill;
}
