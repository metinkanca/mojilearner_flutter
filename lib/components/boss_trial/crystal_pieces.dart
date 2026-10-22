/// The drawn pieces of Amethyst's fight: the spikes it grows down at the pet
/// and the gems that answer them, the crystals its echo raises, the shards it
/// volleys, the crystal it charges in the Spells round, and the amethyst that
/// seals the pet when anything gets through.
///
/// Everything of the bear's is its own amethyst; what belongs to the pet —
/// its gems — is rune light, the colour of the pet's spells, so it is always
/// clear whose piece is whose.
///
/// The plates, the gems, the echo's crystals, the shards and the cluster of
/// crystal are the owner's sheet (`crystal_ui_art.dart`, from
/// `art_src/gen_crystal_ui.py`); the spikes' shafts and the amethyst that
/// seals the pet are still drawn here.
library;

import 'dart:math';

import 'package:flutter/material.dart';

import 'crystal_ui_art.dart';
import 'pixel_sprite.dart';
import 'trial_particles.dart';

/// Amethyst's colours, lifted from its sprite (`art_src/gen_amethyst.py`).
class CrystalPalette {
  CrystalPalette._();
  static const Color outline = Color(0xFF11120E);
  static const Color deep = Color(0xFF493644);
  static const Color purple = Color(0xFF654584);
  static const Color violet = Color(0xFFBC93D8);
  static const Color pale = Color(0xFFD7C1D8);

  /// A shard breaking.
  static const List<Color> shards = [purple, violet, pale, deep];
}

/// Picked up and waiting for the other half of its pair.
const Color _heldFace = Color(0xFFFBE38E);
const Color _wrongFace = Color(0xFFF1A7A9);
const Color _ink = Color(0xFF2A1E14);

/// The cell the crystals are drawn on, like the slabs' notched corners.
const double _cell = 4;

/// The owner's sheet is drawn a point a cell, the way the skin's panel is. A
/// gem could be drawn two, to be as tall as the 40- to 48-point tile it goes in,
/// but its ends are cut at forty-five degrees, and at two points a cell they
/// slope in far enough to hide the first letter of a word.
const double _sheetCell = 1;

/// A crystal on a grid of [u]-pixel cells, [w] cells wide (odd) and [h] tall
/// point included, lit from the left: light, mid and dark thirds, an outline
/// cell all round, and a point that steps in a cell a row.
///
/// [x] and [y] are its top-left cell, in pixels — or, pointing [down], its
/// top-left with the point at the bottom.
void paintPrism(
  Canvas canvas, {
  required double x,
  required double y,
  required int w,
  required int h,
  double u = _cell,
  bool down = false,
}) {
  final paint = Paint()..isAntiAlias = false;
  void shape(double x, double y, int w, int h, List<Color> thirds) {
    final half = w ~/ 2;
    for (var r = 0; r < h; r++) {
      // Rows counted from the point.
      final fromPoint = down ? h - 1 - r : r;
      final inset = max(0, half - fromPoint);
      for (var third = 0; third < 3; third++) {
        final from = max(inset, (w * third / 3).ceil());
        final to = min(w - inset, (w * (third + 1) / 3).ceil());
        if (to <= from) continue;
        canvas.drawRect(
          Rect.fromLTWH(x + from * u, y + r * u, (to - from) * u, u),
          paint..color = thirds[third],
        );
      }
    }
  }

  const outline = CrystalPalette.outline;
  shape(x - u, y - u, w + 2, h + 2, const [outline, outline, outline]);
  shape(x, y, w, h, const [
    CrystalPalette.pale,
    CrystalPalette.violet,
    CrystalPalette.purple,
  ]);
}

// ---- Crystal Spikes ---------------------------------------------------------

/// How a spike, a gem or an echo crystal is showing.
enum CrystalPieceState {
  plain,

  /// Picked up, waiting for the other half of a pair.
  held,

  /// Just tried and wrong: flashing red.
  flashing,

  /// Tried and wrong, and no longer tappable.
  wrong,

  /// The right answer, shown once it is too late.
  revealed,

  /// Answered: gone, leaving its place.
  spent,
}

/// The colour a piece's face takes while it is showing [state], or null for
/// the sheet's own.
Color? _faceOf(CrystalPieceState state) => switch (state) {
      CrystalPieceState.held => _heldFace,
      CrystalPieceState.flashing => _wrongFace,
      CrystalPieceState.revealed => DebrisPalette.runeLight,
      _ => null,
    };

/// The plate a spike hangs from, under the ledge, with the word it roared
/// carved on it. The plate stays where it is while its shaft grows out of it
/// toward the pet, so the word never moves while it is being read.
class CrystalSpike extends StatelessWidget {
  const CrystalSpike({
    super.key,
    required this.label,
    required this.style,
    required this.state,
    required this.onTapDown,
  });

  final String label;
  final TextStyle style;
  final CrystalPieceState state;
  final VoidCallback onTapDown;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => onTapDown(),
        child: CustomPaint(
          painter: PixelSpritePainter.tiled(crystalPlate,
              cell: _sheetCell, face: _faceOf(state)),
          child: Padding(
            // Under the two roots of crystal that dip into the plate's face.
            padding: crystalPlateFace * _sheetCell +
                const EdgeInsets.symmetric(horizontal: 4),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: style.copyWith(color: _ink),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One spike's shaft: from the plate it hangs from to its point.
class SpikeShaft {
  const SpikeShaft({
    required this.root,
    required this.tip,
    this.danger = false,
  });

  final Offset root;
  final Offset tip;

  /// Nearly at the pet: its point flashes.
  final bool danger;
}

/// Every spike's shaft, growing on the diagonal from its plate to the pet.
///
/// Drawn row by row on the cell grid rather than rotated, so a shaft on the
/// slant is a staircase of whole cells like the rest of the pixel art: each
/// row a run of [width] cells, light, mid and dark, narrowing to a point over
/// its last rows.
class SpikeShaftsPainter extends CustomPainter {
  const SpikeShaftsPainter(this.shafts, {this.flashOn = false});

  final List<SpikeShaft> shafts;

  /// Which half of the flash a spike in danger is showing.
  final bool flashOn;

  static const int width = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    // Outlines first, all of them, so where shafts cross near the pet each
    // stays a crystal in front of the others' outline rather than behind it.
    for (final outline in [true, false]) {
      for (final shaft in shafts) {
        _shaft(canvas, paint, shaft, outline: outline);
      }
    }
  }

  void _shaft(Canvas canvas, Paint paint, SpikeShaft shaft,
      {required bool outline}) {
    const u = _cell;
    const half = width ~/ 2;
    final y0 = (shaft.root.dy / u).floorToDouble() * u;
    final rows = ((shaft.tip.dy - y0) / u).round();
    if (rows < 1) return;
    final flashing = shaft.danger && flashOn;
    for (var r = 0; r < rows; r++) {
      final k = (r + 0.5) / rows;
      final cx = shaft.root.dx + (shaft.tip.dx - shaft.root.dx) * k;
      final fromTip = rows - 1 - r;
      final inset = max(0, half - fromTip);
      final left = ((cx / u).round() - half + inset) * u;
      final cells = width - 2 * inset;
      final y = y0 + r * u;
      if (outline) {
        // The row, and the one above it, a cell wider each side: enough to
        // close the steps of a slanted shaft.
        paint.color = CrystalPalette.outline;
        canvas.drawRect(
            Rect.fromLTWH(left - u, y - u, (cells + 2) * u, 2 * u), paint);
        if (fromTip == 0) {
          canvas.drawRect(Rect.fromLTWH(left, y + u, cells * u, u), paint);
        }
        continue;
      }
      for (var third = 0; third < 3; third++) {
        final from = max(inset, (width * third / 3).ceil()) - inset;
        final to = min(width - inset, (width * (third + 1) / 3).ceil()) - inset;
        if (to <= from) continue;
        paint.color = flashing && fromTip < 3
            ? (third == 0 ? const Color(0xFFFFFFFF) : DebrisPalette.fizzle)
            : const [
                CrystalPalette.pale,
                CrystalPalette.violet,
                CrystalPalette.purple,
              ][third];
        canvas.drawRect(
          Rect.fromLTWH(left + from * u, y, (to - from) * u, u),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant SpikeShaftsPainter old) => true;
}

/// One of the pet's gems, carrying a meaning in the player's language.
class CrystalGem extends StatelessWidget {
  const CrystalGem({
    super.key,
    required this.label,
    required this.style,
    required this.state,
    required this.onTapDown,
  });

  final String label;
  final TextStyle style;
  final CrystalPieceState state;
  final VoidCallback onTapDown;

  @override
  Widget build(BuildContext context) {
    final spent = state == CrystalPieceState.spent;
    return Semantics(
      button: !spent,
      label: label,
      child: Visibility(
        // A thrown gem leaves its place, so the others never move under the
        // player's finger.
        visible: !spent,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: spent ? null : (_) => onTapDown(),
          child: CustomPaint(
            painter: PixelSpritePainter.tiled(crystalPetGem,
                cell: _sheetCell, face: _faceOf(state)),
            child: Padding(
              padding: crystalGemFace * _sheetCell +
                  const EdgeInsets.symmetric(horizontal: 2),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, maxLines: 1, style: style),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---- Crystal Echo -----------------------------------------------------------

/// A crystal risen for the echo, carrying a meaning in the player's
/// language.
class EchoCrystal extends StatelessWidget {
  const EchoCrystal({
    super.key,
    required this.label,
    required this.style,
    required this.state,
    required this.onTapDown,
  });

  final String label;
  final TextStyle style;
  final CrystalPieceState state;
  final VoidCallback onTapDown;

  bool get _tappable =>
      state == CrystalPieceState.plain || state == CrystalPieceState.flashing;

  @override
  Widget build(BuildContext context) {
    final dim = state == CrystalPieceState.wrong;
    return Semantics(
      button: _tappable,
      label: label,
      child: Visibility(
        visible: state != CrystalPieceState.spent,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _tappable ? (_) => onTapDown() : null,
          child: CustomPaint(
            painter: PixelSpritePainter.tiled(crystalGem,
                cell: _sheetCell,
                face: dim ? CrystalPalette.pale : _faceOf(state)),
            child: Padding(
              padding: crystalGemFace * _sheetCell +
                  const EdgeInsets.symmetric(horizontal: 4),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: style.copyWith(
                      color: dim ? _ink.withValues(alpha: 0.35) : _ink,
                      decoration: dim ? TextDecoration.lineThrough : null,
                      decorationColor: _ink.withValues(alpha: 0.35),
                      decorationThickness: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---- Shard Volley -----------------------------------------------------------

/// A shard in flight: a word in the boss's language, and what it claims the
/// word means in the player's.
class VolleyShardTile extends StatelessWidget {
  const VolleyShardTile({
    super.key,
    required this.word,
    required this.claim,
    required this.wordStyle,
    required this.claimStyle,
    required this.onTapDown,
  });

  final String word;
  final String claim;
  final TextStyle wordStyle;
  final TextStyle claimStyle;
  final VoidCallback onTapDown;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$word means $claim',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => onTapDown(),
        child: LayoutBuilder(builder: (context, box) {
          // The shard is scaled to its box, so where its words go is too.
          final kx = box.maxWidth / crystalShard.width;
          final ky = box.maxHeight / crystalShard.height;
          return CustomPaint(
            painter: const _ShardPainter(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                crystalShardFace.left * kx,
                crystalShardFace.top * ky,
                crystalShardFace.right * kx,
                crystalShardFace.bottom * ky,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(word,
                          maxLines: 1, style: wordStyle.copyWith(color: _ink)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('= $claim',
                          maxLines: 1,
                          style: claimStyle.copyWith(color: _ink)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// The sheet's shard, scaled to its tile: a teardrop with a curved top, so
/// there is no plain run of columns to repeat, and every cell is stretched
/// instead.
class _ShardPainter extends CustomPainter {
  const _ShardPainter();

  @override
  void paint(Canvas canvas, Size size) => crystalShard.paint(
        canvas,
        Offset.zero,
        crystalShard.width,
        crystalShard.height,
        cellW: size.width / crystalShard.width,
        cellH: size.height / crystalShard.height,
      );

  @override
  bool shouldRepaint(covariant _ShardPainter old) => false;
}

// ---- the crystal it charges, and throws -------------------------------------

/// A cluster of three amethyst points: what Amethyst grows over its head in
/// the Spells round, and any crystal thrown in its fight.
class CrystalChunk extends StatelessWidget {
  const CrystalChunk({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _ChunkPainter());
}

class _ChunkPainter extends CustomPainter {
  const _ChunkPainter();

  /// The smallest box the whole cluster is drawn in: under it a cell of the
  /// sheet's would be under a point, and half of them are dropped.
  static const double _wholeFrom = 46;

  @override
  void paint(Canvas canvas, Size size) =>
      (size.shortestSide >= _wholeFrom ? crystalCluster : crystalClusterHalf)
          .paintContained(canvas, size);

  @override
  bool shouldRepaint(covariant _ChunkPainter oldDelegate) => false;
}

// ---- the pet sealed in amethyst ---------------------------------------------

/// Amethyst growing up round the pet, from the ground: [fill] 0 is none of
/// it, 1 is the pet sealed in. Thin enough for the pet to show through, the
/// way a crystal would.
class CrystalCasePainter extends CustomPainter {
  const CrystalCasePainter(this.fill);

  final double fill;

  /// The cluster, left to right: where each point stands across the box, how
  /// many cells wide it is, and how much of the box's height it reaches.
  static const List<(double, int, double)> _points = [
    (0.5, 9, 1.0),
    (0.3, 7, 0.82),
    (0.7, 7, 0.86),
    (0.14, 5, 0.52),
    (0.86, 5, 0.58),
    (0.4, 3, 0.36),
    (0.62, 3, 0.3),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final f = fill.clamp(0.0, 1.0);
    if (f <= 0) return;
    // Drawn solid and laid over the pet as one layer, so where the points
    // overlap is no less see-through than where they do not.
    canvas.saveLayer(
      (Offset.zero & size).inflate(_cell),
      Paint()..color = const Color(0x94000000),
    );
    // In steps of a cell, like everything else that grows in the arena.
    final cells = (size.height / _cell).floor();
    final bottom = (size.height / _cell).floorToDouble() * _cell;
    for (final (at, w, reach) in _points) {
      final h = (cells * reach * f).round();
      if (h < 2) continue;
      final x = ((size.width * at) / _cell - w / 2).roundToDouble() * _cell;
      paintPrism(canvas, x: x, y: bottom - h * _cell, w: w, h: h);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CrystalCasePainter old) => old.fill != fill;
}
