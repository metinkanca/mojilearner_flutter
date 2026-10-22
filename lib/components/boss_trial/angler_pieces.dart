/// The drawn pieces of Lanternmaw's fight: the lantern board with its missing
/// word, the fish that swim past with words for it, the letter bubbles off
/// the seabed, the bubble it charges in the Spells round, and the bubble that
/// traps the pet when anything gets through.
///
/// Its colours are its own sprite's (`art_src/gen_anglerfish.py`): lantern
/// gold, seafoam, slate. None of them is the UI's cyan, which stays the pet's
/// spell light.
///
/// The board, its lantern, the pills the words are written on, the fish, the
/// net and the bubbles are the owner's sheet (`sea_ui_art.dart`, from
/// `art_src/gen_sea_ui.py`).
library;

import 'dart:math';

import 'package:flutter/material.dart';

import 'pixel_sprite.dart';
import 'sea_ui_art.dart';
import 'trial_particles.dart';

/// The owner's sheet is drawn a point a cell; a letter bubble, which would be
/// a thumbnail of thirty points at that, two.
const double _sheet = 1;
const double _bubbleCell = 2;
const Color _wrongFace = Color(0xFFF1A7A9);

/// Lanternmaw's colours, lifted from its sprite.
class AnglerPalette {
  AnglerPalette._();
  static const Color outline = Color(0xFF14120E);
  static const Color slate = Color(0xFF376C79);
  static const Color fin = Color(0xFF58909C);
  static const Color seafoam = Color(0xFF83AAA8);
  static const Color lantern = Color(0xFFE3B65D);
  static const Color lanternCore = Color(0xFFFFF0C9);

  /// The deep water, and the board the lantern lights.
  static const Color deep = Color(0xFF15243F);
  static const Color board = Color(0xFF1D3151);

  /// A bubble's skin and its shine.
  static const Color skin = Color(0xFFC9DEDA);
  static const Color shine = Color(0xFFFFFFFF);

  /// Bubbles bursting, and the sparks of its arrival.
  static const List<Color> bubbles = [seafoam, skin, shine];
}

/// The cells of a circle [cells] across, row by row: the first and last
/// column each row covers. Shared by everything round here, so every bubble
/// steps the same way.
List<(int, int)> _circleRows(int cells) {
  final r = cells / 2;
  return [
    for (var y = 0; y < cells; y++)
      () {
        final dy = y + 0.5 - r;
        final half = sqrt(max(0.0, r * r - dy * dy));
        final from = (r - half).round();
        return (from, cells - from);
      }(),
  ];
}

// ---- Lure -------------------------------------------------------------------

/// How the lantern's missing word is showing.
enum LureGap {
  /// Still missing: a lit "?".
  waiting,

  /// Filled by the fish that was hooked.
  hooked,

  /// The lantern went out, and the gap shows what it needed.
  missed,
}

/// The sentence the lantern lights, with its missing word, and the lantern's
/// light running down along its foot.
class LureBoard extends StatelessWidget {
  const LureBoard({
    super.key,
    required this.words,
    required this.gap,
    required this.style,
    required this.state,
    required this.light,
    this.textDirection = TextDirection.ltr,
  });

  final List<String> words;
  final int gap;
  final TextStyle style;
  final LureGap state;

  /// How much of the lantern's light is left, from 1 to 0.
  final double light;

  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    // Each word on a glass pill, the gap's in the lantern's gold while it is
    // still missing.
    Widget word(int i) {
      final isGap = i == gap;
      final (face, text) = !isGap
          ? (null, words[i])
          : switch (state) {
              LureGap.waiting => (AnglerPalette.lantern, '?'),
              LureGap.hooked => (DebrisPalette.runeLight, words[i]),
              LureGap.missed => (_wrongFace, words[i]),
            };
      return CustomPaint(
        painter: PixelSpritePainter.tiled(seaPill, cell: _sheet, face: face),
        child: Container(
          height: 40,
          constraints: BoxConstraints(minWidth: isGap ? 64 : 48),
          padding:
              seaPillFace * _sheet + const EdgeInsets.symmetric(horizontal: 2),
          child: Align(
            widthFactor: 1,
            child: Text(text, maxLines: 1, style: style),
          ),
        ),
      );
    }

    final stepped = (light.clamp(0.0, 1.0) * 20).ceil() / 20;
    // The lantern hangs over the board's top left corner, so the words start
    // clear of it. It goes out with the light.
    final lantern = stepped > 0.25 ? seaLantern : seaLanternUnlit;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          painter: const PixelSpritePainter.tiled(seaPanel, cell: _sheet),
          child: Padding(
            padding: seaPanelFace * _sheet +
                EdgeInsets.fromLTRB((seaLantern.width + 2) * _sheet, 0, 4, 0),
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    textDirection: textDirection,
                    spacing: 6,
                    runSpacing: 6,
                    children: [for (var i = 0; i < words.length; i++) word(i)],
                  ),
                  const SizedBox(height: 8),
                  // Painted, not a sized box: the board is laid out at its
                  // words' width, and the bar has none of its own.
                  SizedBox(
                    height: 8,
                    child: CustomPaint(painter: _LightPainter(stepped)),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: seaLanternLeft * _sheet,
          top: seaLanternTop * _sheet,
          child: IgnorePointer(
            child: CustomPaint(
              size: Size(lantern.width * _sheet, lantern.height * _sheet),
              painter: PixelSpritePainter.tiled(lantern, cell: _sheet),
            ),
          ),
        ),
      ],
    );
  }
}

/// The lantern's light left, as a bar along the foot of its board.
class _LightPainter extends CustomPainter {
  const _LightPainter(this.light);

  final double light;

  @override
  void paint(Canvas canvas, Size size) {
    final w = ((size.width * light) / 4).round() * 4.0;
    if (w <= 0) return;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, size.height),
      Paint()
        ..isAntiAlias = false
        ..color = AnglerPalette.lantern,
    );
  }

  @override
  bool shouldRepaint(covariant _LightPainter old) => old.light != light;
}

/// Dark water over the lantern on the sprite, thicker as its light runs out:
/// [dim] 0 is fully lit, 1 out.
class LanternShade extends StatelessWidget {
  const LanternShade({super.key, required this.dim});

  final double dim;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _LanternShadePainter(dim));
}

class _LanternShadePainter extends CustomPainter {
  const _LanternShadePainter(this.dim);

  final double dim;

  @override
  void paint(Canvas canvas, Size size) {
    // In quarters, so the light goes in steps like the bar under the board.
    final stepped = (dim.clamp(0.0, 1.0) * 4).floor() / 4;
    if (stepped <= 0) return;
    final paint = Paint()
      ..isAntiAlias = false
      ..color = AnglerPalette.deep.withValues(alpha: 0.7 * stepped);
    const u = 2.0;
    final cells = (min(size.width, size.height) / u).floor();
    final rows = _circleRows(cells);
    for (var y = 0; y < cells; y++) {
      final (from, to) = rows[y];
      canvas.drawRect(
          Rect.fromLTWH(from * u, y * u, (to - from) * u, u), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LanternShadePainter old) => old.dim != dim;
}

/// How a fish is showing.
enum FishState { plain, wrong, right }

/// A fish swimming past with a word for the gap on its side.
class WordFish extends StatelessWidget {
  const WordFish({
    super.key,
    required this.label,
    required this.style,
    required this.facingRight,
    required this.onTapDown,
    this.state = FishState.plain,
  });

  final String label;
  final TextStyle style;
  final bool facingRight;
  final VoidCallback? onTapDown;
  final FishState state;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTapDown != null,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: onTapDown == null ? null : (_) => onTapDown!(),
        child: CustomPaint(
          painter: _FishPainter(facingRight: facingRight, state: state),
          child: Padding(
            // Clear of the tail on one side and the eye on the other.
            padding: EdgeInsets.fromLTRB(
              (facingRight ? seaFishFace.left : seaFishFace.right) * _sheet,
              seaFishFace.top * _sheet,
              (facingRight ? seaFishFace.right : seaFishFace.left) * _sheet,
              seaFishFace.bottom * _sheet,
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, maxLines: 1, style: style),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The sheet's fish, as tall as it is drawn and as long as its box: its back
/// and belly stretch along the middle of its body, and the tail stays at one
/// end and the head at the other. Drawn facing right and mirrored for left.
class _FishPainter extends CustomPainter {
  const _FishPainter({required this.facingRight, required this.state});

  final bool facingRight;
  final FishState state;

  @override
  void paint(Canvas canvas, Size size) {
    final face = switch (state) {
      FishState.plain => null,
      FishState.wrong => _wrongFace,
      FishState.right => DebrisPalette.runeLight,
    };
    canvas.save();
    if (!facingRight) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    seaFish.paint(
      canvas,
      Offset(0, ((size.height - seaFish.height * _sheet) / 2).roundToDouble()),
      (size.width / _sheet).floor(),
      seaFish.height,
      cellW: _sheet,
      cellH: _sheet,
      face: face,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FishPainter old) =>
      old.facingRight != facingRight || old.state != state;
}

/// The net the pet throws over a fish: cords knotted in a mesh, opening out as
/// it flies — [grow] 0 a bundle, 1 laid right over — and [slack] 1 hanging loose
/// on a fish, 0 pulled taut by the pet.
class NetMesh extends StatelessWidget {
  const NetMesh({super.key, this.grow = 1, this.slack = 1});

  final double grow;
  final double slack;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _NetMeshPainter(grow: grow, slack: slack));
}

/// An even lattice of the sheet's cords and knots, as many cells as the box
/// holds: it opens by covering more of them, not by stretching.
class _NetMeshPainter extends CustomPainter {
  const _NetMeshPainter({required this.grow, required this.slack});

  final double grow;
  final double slack;

  @override
  void paint(Canvas canvas, Size size) {
    final g = grow.clamp(0.0, 1.0);
    if (g <= 0) return;
    // Opening out from the middle, in whole cells.
    final cols = (size.width * (0.3 + 0.7 * g) / _sheet).round();
    final rows = (size.height * (0.3 + 0.7 * g) / _sheet).round();
    seaNet.paint(
      canvas,
      Offset(
        ((size.width - cols * _sheet) / 2).roundToDouble(),
        ((size.height - rows * _sheet) / 2).roundToDouble() +
            (slack.clamp(0.0, 1.0) * 2).roundToDouble(),
      ),
      cols,
      rows,
      cellW: _sheet,
      cellH: _sheet,
    );
  }

  @override
  bool shouldRepaint(covariant _NetMeshPainter old) =>
      old.grow != grow || old.slack != slack;
}

/// The cords from the pet's hands to the fish in its net, drawn as straight
/// lines from [hands] to each of [fish]; drawn pulled [taut] (1) or hanging
/// slack (0).
class NetRopesPainter extends CustomPainter {
  const NetRopesPainter({
    required this.hands,
    required this.fish,
    this.taut = 1,
  });

  final Offset hands;
  final List<Offset> fish;
  final double taut;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..isAntiAlias = false
      ..strokeWidth = 2
      ..color = const Color(0xE6EAF2E2);
    for (final to in fish) {
      // Slack cord sags in the middle; pulled tight it runs straight.
      final sag = (1 - taut.clamp(0.0, 1.0)) * 16;
      const parts = 8;
      Offset? last;
      for (var i = 0; i <= parts; i++) {
        final k = i / parts;
        final at = Offset(
          hands.dx + (to.dx - hands.dx) * k,
          hands.dy + (to.dy - hands.dy) * k + sin(k * pi) * sag,
        );
        final here = Offset(at.dx.roundToDouble(), at.dy.roundToDouble());
        if (last != null) canvas.drawLine(last, here, paint);
        last = here;
      }
    }
  }

  @override
  bool shouldRepaint(covariant NetRopesPainter old) => true;
}

// ---- Bubbles ----------------------------------------------------------------

/// A bubble off the seabed with a letter in it.
class LetterBubble extends StatelessWidget {
  const LetterBubble({
    super.key,
    required this.label,
    required this.style,
    required this.onTapDown,
    this.flashing = false,
  });

  final String label;
  final TextStyle style;
  final VoidCallback? onTapDown;

  /// Just refused: its face flashes red.
  final bool flashing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTapDown != null,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: onTapDown == null ? null : (_) => onTapDown!(),
        child: CustomPaint(
          painter: _BubblePainter(flashing: flashing),
          child: Padding(
            // Inside the bubble's face, which a 52-point box holds with a few
            // points of the bubble over its edge on each side.
            padding: EdgeInsets.all(
                (seaBubbleFace.left * _bubbleCell - 3).roundToDouble()),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, maxLines: 1, style: style),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The sheet's bubble at two points a cell, centred on its box and a little
/// larger than it.
class _BubblePainter extends CustomPainter {
  const _BubblePainter({this.flashing = false});

  final bool flashing;

  @override
  void paint(Canvas canvas, Size size) => seaBubble.paint(
        canvas,
        Offset(
          ((size.width - seaBubble.width * _bubbleCell) / 2).roundToDouble(),
          ((size.height - seaBubble.height * _bubbleCell) / 2).roundToDouble(),
        ),
        seaBubble.width,
        seaBubble.height,
        cellW: _bubbleCell,
        cellH: _bubbleCell,
        // A letter needs a face solid enough to read on the dark water.
        face: flashing ? _wrongFace : null,
      );

  @override
  bool shouldRepaint(covariant _BubblePainter old) => old.flashing != flashing;
}

/// The sheet's ring of glass, whole while a cell of it is a point or more and
/// at half resolution under that, as large as fits [size].
void _paintRing(Canvas canvas, Size size) =>
    (size.shortestSide >= seaRing.width ? seaRing : seaRingHalf)
        .paintContained(canvas, size);

/// The bubble Lanternmaw blows by its lantern in the Spells round, and flings
/// at the pet when it is full.
class WaterBubble extends StatelessWidget {
  const WaterBubble({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _WaterBubblePainter());
}

class _WaterBubblePainter extends CustomPainter {
  const _WaterBubblePainter();

  @override
  void paint(Canvas canvas, Size size) => _paintRing(canvas, size);

  @override
  bool shouldRepaint(covariant _WaterBubblePainter old) => false;
}

/// The bubble the pet is trapped in when Lanternmaw's attack gets through,
/// drawn over it: [fill] 1 is the whole bubble, 0 none, and in between it is
/// swelling round the pet.
class PetBubblePainter extends CustomPainter {
  const PetBubblePainter(this.fill);

  final double fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (fill <= 0) return;
    // Round the pet as drawn, which sits low in its box.
    final side =
        (size.width * 0.96 * (0.45 + 0.55 * fill.clamp(0.0, 1.0))).roundToDouble();
    final box = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.56),
      width: side,
      height: side,
    );
    // Faint as it swells, so the pet shows through the glass.
    canvas
      ..saveLayer(
        box,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85 * fill.clamp(0.0, 1.0)),
      )
      ..translate(box.left.roundToDouble(), box.top.roundToDouble());
    _paintRing(canvas, box.size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PetBubblePainter old) => old.fill != fill;
}
