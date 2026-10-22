/// The drawn pieces of Mossback's openers under test: the shell cups of its
/// Shell Game, the holes and pebbles of Pebble Pop, and the river and stones
/// of Stepping Stones.
///
/// The cups, pebbles, stones and the slabs words are written on are the
/// owner's own sprite sheet (moss_ui_art.dart); the holes and the river are
/// painted here in the same stone and moss, on whole pixels.
library;

import 'dart:math';

import 'package:flutter/material.dart';

import 'moss_ui_art.dart';
import 'pixel_sprite.dart';
import 'trial_particles.dart';

const double _cell = 4;

/// The sheet's cells, as its answer tile is drawn everywhere else.
const double _sheetCell = 2;
const Color _wrongFace = Color(0xFFF1A7A9);
const Color _rightFace = DebrisPalette.runeLight;
const Color _hole = Color(0xFF0B0D09);

/// How a cup, pebble or stone is showing.
enum MossPieceState { plain, wrong, right }

/// The face words sit on, when it is not the stone's own.
Color? _face(MossPieceState state) => switch (state) {
      MossPieceState.plain => null,
      MossPieceState.wrong => _wrongFace,
      MossPieceState.right => _rightFace,
    };

/// The sheet's answer tile with a word on it, in [state]'s face.
class _WordSlab extends StatelessWidget {
  const _WordSlab({
    required this.label,
    required this.style,
    required this.state,
  });

  final String label;
  final TextStyle style;
  final MossPieceState state;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: PixelSpritePainter.tiled(mossTile,
            cell: _sheetCell, face: _face(state)),
        child: Padding(
          // Clear of its frame: three cells each side, three top and bottom.
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, maxLines: 1, style: style),
            ),
          ),
        ),
      );
}

// ---- Shell Game -------------------------------------------------------------

/// The meaning a cup hides, on the slab under it.
class ShellSlab extends StatelessWidget {
  const ShellSlab({
    super.key,
    required this.label,
    required this.style,
    this.state = MossPieceState.plain,
  });

  final String label;
  final TextStyle style;
  final MossPieceState state;

  @override
  Widget build(BuildContext context) =>
      _WordSlab(label: label, style: style, state: state);
}

/// A cup: an upturned stone cup, mossy round its foot, that sits over a slab
/// and lifts off it. Drawn whole, as wide as its box, standing on its foot.
class ShellDome extends StatelessWidget {
  const ShellDome({super.key, required this.onTapDown});

  final VoidCallback? onTapDown;

  /// How tall a cup [width] across stands.
  static double heightFor(double width) =>
      (width * mossCup.height / mossCup.width).roundToDouble();

  /// One of the cup's cells, on a cup [width] across.
  static double cellFor(double width) => width / mossCup.width;

  @override
  Widget build(BuildContext context) => Semantics(
        button: onTapDown != null,
        label: 'cup',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: onTapDown == null ? null : (_) => onTapDown!(),
          child: const CustomPaint(
            painter: PixelSpritePainter.contained(mossCup,
                alignment: Alignment.bottomCenter),
          ),
        ),
      );
}

// ---- Pebble Pop -------------------------------------------------------------

/// A hole in the moss a pebble pops out of.
class MossHole extends StatelessWidget {
  const MossHole({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _HolePainter());
}

class _HolePainter extends CustomPainter {
  const _HolePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const u = _cell;
    final paint = Paint()..isAntiAlias = false;
    final w = size.width, h = size.height;
    // A lip of moss, then the dark inside, both cut round at the ends.
    canvas.drawRect(Rect.fromLTWH(2 * u, 0, w - 4 * u, h),
        paint..color = DebrisPalette.moss);
    canvas.drawRect(Rect.fromLTWH(0, u, w, h - 2 * u), paint);
    canvas.drawRect(
        Rect.fromLTWH(3 * u, u, w - 6 * u, h - 2 * u), paint..color = _hole);
    canvas.drawRect(
        Rect.fromLTWH(u, 2 * u, w - 2 * u, max(0, h - 4 * u)), paint);
  }

  @override
  bool shouldRepaint(covariant _HolePainter oldDelegate) => false;
}

/// A pebble popped up, carrying a word in the boss's language on the tile
/// it holds up in front of it.
class PebbleTile extends StatelessWidget {
  const PebbleTile({
    super.key,
    required this.label,
    required this.style,
    required this.onTapDown,
    this.state = MossPieceState.plain,
  });

  final String label;
  final TextStyle style;
  final VoidCallback? onTapDown;
  final MossPieceState state;

  @override
  Widget build(BuildContext context) => Semantics(
        button: onTapDown != null,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: onTapDown == null ? null : (_) => onTapDown!(),
          child: Stack(
            children: [
              // The sheet's pebble, cell for cell, its mossy foot behind the
              // top of the tile.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: mossPebble.height * _sheetCell,
                child: const CustomPaint(
                  painter: PixelSpritePainter.contained(mossPebble),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: tileHeight,
                child: _WordSlab(label: label, style: style, state: state),
              ),
            ],
          ),
        ),
      );

  /// The tile, the sheet's own height.
  static const double tileHeight = 28;

  /// How much of the pebble shows over its tile.
  static const double pebbleShows = 26;

  /// The whole of it, pebble and tile.
  static const double height = pebbleShows + tileHeight;
}

// ---- Stepping Stones --------------------------------------------------------

/// The river between the bank and Mossback's ledge, its ripples drifting
/// with [time].
class RiverPainter extends CustomPainter {
  const RiverPainter(this.time);

  final double time;

  static const Color water = Color(0xFF1E3E5C);
  static const Color ripple = Color(0xFF2F5F85);
  static const Color glint = Color(0xFF6FA8CF);

  @override
  void paint(Canvas canvas, Size size) {
    const u = _cell;
    final paint = Paint()..isAntiAlias = false;
    canvas.drawRect(Offset.zero & size, paint..color = water);
    // Ripples in rows, each row drifting its own way, in whole cells.
    var row = 0;
    for (var y = 2 * u; y < size.height - u; y += 5 * u, row++) {
      final dir = row.isEven ? 1 : -1;
      final shift = ((time * 10 * dir) / u).floor() * u;
      for (var x = (row * 23 % 60) * 1.0 - 60; x < size.width; x += 60) {
        final at = (x + shift) % (size.width + 60) - 30;
        canvas.drawRect(Rect.fromLTWH(at, y, 5 * u, u), paint..color = ripple);
        canvas.drawRect(Rect.fromLTWH(at + u, y, u, u), paint..color = glint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant RiverPainter old) => old.time != time;
}

/// Hides whatever is below the water line [line] (a y in the clipped box), so
/// a pet sinking into the river is cut off at the surface and the river
/// behind shows through. With no line nothing is hidden.
class WaterlineClipper extends CustomClipper<Rect> {
  const WaterlineClipper(this.line);

  final double? line;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
        -size.width,
        -size.height,
        size.width * 2,
        line ?? size.height * 2,
      );

  @override
  bool shouldReclip(covariant WaterlineClipper old) => old.line != line;
}

/// A stepping stone with a meaning on it. [sunk] is how far into the water
/// it has gone, 0 to 1: it slides down out of its box, into the river.
class SteppingStone extends StatelessWidget {
  const SteppingStone({
    super.key,
    required this.label,
    required this.style,
    required this.onTapDown,
    this.state = MossPieceState.plain,
    this.sunk = 0,
  });

  final String label;
  final TextStyle style;
  final VoidCallback? onTapDown;
  final MossPieceState state;
  final double sunk;

  @override
  Widget build(BuildContext context) => Semantics(
        button: onTapDown != null,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: onTapDown == null ? null : (_) => onTapDown!(),
          child: ClipRect(
            child: LayoutBuilder(builder: (context, box) {
              // The sheet's stone on its own cells, its flat top grown deep
              // and wide enough for a word: 7 cells in from either end, a
              // cell down, 8 up.
              const cell = _sheetCell;
              final down = ((sunk * 8).ceil() / 8).clamp(0.0, 1.0);
              return Transform.translate(
                offset: Offset(0, (down * box.maxHeight / cell).round() * cell),
                child: CustomPaint(
                  painter: PixelSpritePainter.tiled(mossStone,
                      cell: cell, face: _face(state)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        7 * cell, cell, 7 * cell, 8 * cell),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(label, maxLines: 1, style: style),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      );
}
