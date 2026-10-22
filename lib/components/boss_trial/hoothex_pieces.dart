/// The drawn pieces of the witch's openers under test: her clones' speech
/// bubbles, the cauldrons of Tangled Spells, and the gates and broom of the
/// Broom Chase.
///
/// Hers are purple and parchment, like her scroll. All of it is the owner's
/// sheet (`hex_ui_art.dart`, from `art_src/gen_hex_ui.py`), flattened where the
/// tool shaded it heavily: the pots, the broom.
library;

import 'package:flutter/material.dart';

import 'hex_pieces.dart';
import 'hex_ui_art.dart';
import 'pixel_sprite.dart';

/// The sheet is drawn a point a cell; the broom, whose head would be a thin
/// eighteen points at that, two.
const double _cell = 1;
const double _broomCell = 2;
const Color _wrongFace = Color(0xFFF1A7A9);

/// How a bubble, a word or a gate is showing.
enum HexPieceState { plain, wrong, right }

/// The colour a tag or a bubble's face takes while it is showing [state], or
/// null for the sheet's own.
Color? _faceOf(HexPieceState state) => switch (state) {
      HexPieceState.plain => null,
      HexPieceState.wrong => _wrongFace,
      HexPieceState.right => HexPalette.hexLight,
    };

// ---- Mirror Clones ----------------------------------------------------------

/// What one of her owls is saying, over its head.
class OwlBubble extends StatelessWidget {
  const OwlBubble({
    super.key,
    required this.text,
    required this.style,
    required this.onTapDown,
    this.state = HexPieceState.plain,
  });

  final String text;
  final TextStyle style;
  final VoidCallback? onTapDown;
  final HexPieceState state;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTapDown != null,
      label: text,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: onTapDown == null ? null : (_) => onTapDown!(),
        child: CustomPaint(
          painter: _BubblePainter(_faceOf(state)),
          child: Padding(
            // In from the bubble's rim, and up from its tail, which hangs
            // below the body.
            padding: hexBubbleFace * _cell +
                const EdgeInsets.fromLTRB(3, 0, 3, _BubblePainter.tailDrop),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(text, maxLines: 1, style: style),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The sheet's bubble: a body that stretches to its words, and its tail, which
/// is a piece of its own so it stays in the middle of the foot at any width.
class _BubblePainter extends CustomPainter {
  const _BubblePainter(this.face);

  final Color? face;

  /// How many rows of the tail are the body's own, where it joins.
  static const int _joined = 3;

  /// How far the tail hangs below the body.
  static const double tailDrop = 4 * _cell;

  @override
  void paint(Canvas canvas, Size size) {
    final body = size.height - tailDrop;
    hexBubble.paintTiled(canvas, Size(size.width, body), _cell, face: face);
    hexBubbleTail.paint(
      canvas,
      Offset(((size.width - hexBubbleTail.width * _cell) / 2).roundToDouble(),
          body - _joined * _cell),
      hexBubbleTail.width,
      hexBubbleTail.height,
      cellW: _cell,
      cellH: _cell,
      face: face,
    );
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) => old.face != face;
}

// ---- Tangled Spells ---------------------------------------------------------

/// A word out of the tangle, falling toward the cauldrons.
class TangleTile extends StatelessWidget {
  const TangleTile({
    super.key,
    required this.label,
    required this.style,
    this.state = HexPieceState.plain,
  });

  final String label;
  final TextStyle style;
  final HexPieceState state;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: PixelSpritePainter.tiled(hexTag,
            cell: _cell, face: _faceOf(state)),
        child: Padding(
          // In from the tag's torn edge, and clear of its folded corner.
          padding:
              hexTagFace * _cell + const EdgeInsets.symmetric(horizontal: 4),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, maxLines: 1, style: style),
            ),
          ),
        ),
      );
}

/// A cauldron and the spell it is for: the meaning on a parchment label
/// above the pot. The whole of it takes the tap.
class Cauldron extends StatelessWidget {
  const Cauldron({
    super.key,
    required this.meaning,
    required this.style,
    required this.labelHeight,
    required this.onTapDown,
    this.filled = 0,
    this.state = HexPieceState.plain,
  });

  final String meaning;
  final TextStyle style;
  final double labelHeight;
  final VoidCallback? onTapDown;

  /// Words dropped in so far, which raise the brew.
  final int filled;
  final HexPieceState state;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTapDown != null,
      label: meaning,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: onTapDown == null ? null : (_) => onTapDown!(),
        child: Column(
          children: [
            CustomPaint(
              painter: PixelSpritePainter.tiled(hexTag,
                  cell: _cell, face: _faceOf(state)),
              child: Container(
                height: labelHeight,
                width: double.infinity,
                padding: hexTagFace * _cell +
                    const EdgeInsets.symmetric(horizontal: 4),
                child: Center(
                  child: Text(
                    meaning,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: CustomPaint(
                painter: _CauldronPainter(filled),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The sheet's pot, standing on the grass at the foot of its box, the brew
/// higher for each word dropped in: three pots, brimming at the third.
class _CauldronPainter extends CustomPainter {
  const _CauldronPainter(this.filled);

  final int filled;

  @override
  void paint(Canvas canvas, Size size) {
    final pot = switch (filled) {
      <= 0 => hexCauldronLow,
      1 => hexCauldronMid,
      _ => hexCauldronFull,
    };
    pot.paint(
      canvas,
      Offset(((size.width - pot.width * _cell) / 2).roundToDouble(),
          size.height - pot.height * _cell),
      pot.width,
      pot.height,
      cellW: _cell,
      cellH: _cell,
    );
  }

  @override
  bool shouldRepaint(covariant _CauldronPainter old) => old.filled != filled;
}

// ---- Broom Chase ------------------------------------------------------------

/// A gate in the chase: a hexed arch of runed stone with a word hanging in it,
/// the stone red when it was the wrong one and rune light when it was right.
class WordGate extends StatelessWidget {
  const WordGate({
    super.key,
    required this.label,
    required this.style,
    this.state = HexPieceState.plain,
  });

  final String label;
  final TextStyle style;
  final HexPieceState state;

  @override
  Widget build(BuildContext context) {
    final stone = switch (state) {
      HexPieceState.plain => hexGate,
      HexPieceState.wrong => hexGateWrong,
      HexPieceState.right => hexGateRight,
    };
    return CustomPaint(
      painter: PixelSpritePainter.tiled(stone, cell: _cell),
      child: Padding(
        // Inside the arch, under its curve.
        padding: hexGateFace * _cell,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, maxLines: 1, style: style),
          ),
        ),
      ),
    );
  }
}

/// The broom the pet rides in the chase, drawn under it: bristles behind, the
/// handle out ahead, stretched to the length of its box.
class BroomPainter extends CustomPainter {
  const BroomPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cols = (size.width / _broomCell).floor();
    // From the top of the box, not its middle: the handle's top outline falls
    // on the box's 14th point, so the pet's feet at its middle stand on the
    // handle.
    hexBroom.paint(
      canvas,
      Offset(((size.width - cols * _broomCell) / 2).roundToDouble(), 0),
      cols,
      hexBroom.height,
      cellW: _broomCell,
      cellH: _broomCell,
    );
  }

  @override
  bool shouldRepaint(covariant BroomPainter oldDelegate) => false;
}
