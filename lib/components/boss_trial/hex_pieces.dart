/// The drawn pieces of the witch's fight: the scroll she reads with its fuse,
/// the words written on it, the potion she brews, and her magic's colours.
///
/// Everything of hers is purple, the way everything of the pet's is rune
/// light, so it is always clear whose magic is on its way where.
///
/// The scroll, the tags its words are written on, the fuse, the wax seal and
/// the potion are the owner's sheet (`hex_ui_art.dart`, from
/// `art_src/gen_hex_ui.py`).
library;

import 'package:flutter/material.dart';

import 'hex_ui_art.dart';
import 'pixel_sprite.dart';
import 'trial_particles.dart';

/// The witch's colours, lifted from her sprite (`art_src/gen_hoothex.py`).
class HexPalette {
  HexPalette._();
  static const Color outline = DebrisPalette.outline;
  static const Color hex = Color(0xFF8B5FC7);
  static const Color hexLight = Color(0xFFCFB3EF);

  /// Her brew, the green of her hat band.
  static const Color brew = Color(0xFF6ABE30);
  static const Color brewLight = Color(0xFFB6E878);

  /// A hex bolt, outermost ring first.
  static const List<Color> bolt = [outline, hex, hexLight, Color(0xFFFFFFFF)];

  static const List<Color> sparks = [hex, hexLight, Color(0xFFFFFFFF)];
  static const List<Color> splash = [brew, brewLight, hex];
}

const Color _ink = Color(0xFF2A1E14);
const Color _wrongFace = Color(0xFFF1A7A9);

/// A struck-through word's tag: the sheet's parchment in shade.
const Color _struckFace = Color(0xFFDEB27C);

/// The owner's sheet is drawn a point a cell.
const double _cell = 1;

/// How a word on the scroll is showing.
enum ScrollWordState {
  /// Not tried yet.
  plain,

  /// Just tapped, and not the hex: flashing red.
  flashing,

  /// Tried and not the hex: struck through, and no longer tappable.
  wrong,

  /// The hex, shown for what it was after the fuse ran out.
  hexed,

  /// The hex, found: burned off the scroll.
  broken,
}

/// One word written on the scroll.
class ScrollWord extends StatelessWidget {
  const ScrollWord({
    super.key,
    required this.label,
    required this.style,
    required this.state,
    required this.onTapDown,
  });

  final String label;
  final TextStyle style;
  final ScrollWordState state;
  final VoidCallback onTapDown;

  static const double height = 40;

  bool get _tappable =>
      state == ScrollWordState.plain || state == ScrollWordState.flashing;

  @override
  Widget build(BuildContext context) {
    final (face, ink) = switch (state) {
      ScrollWordState.plain => (null, _ink),
      ScrollWordState.flashing => (_wrongFace, _ink),
      ScrollWordState.wrong => (_struckFace, _ink.withValues(alpha: 0.35)),
      ScrollWordState.hexed => (HexPalette.hex, const Color(0xFFFFFFFF)),
      ScrollWordState.broken => (null, _ink),
    };
    final word = CustomPaint(
      painter: PixelSpritePainter.tiled(hexTag, cell: _cell, face: face),
      child: Container(
        height: height,
        constraints: const BoxConstraints(minWidth: 52),
        // In from the tag's torn edge and clear of its folded corner.
        padding: hexTagFace * _cell + const EdgeInsets.symmetric(horizontal: 4),
        child: Align(
          widthFactor: 1,
          child: Text(
            label,
            maxLines: 1,
            style: style.copyWith(
              color: ink,
              decoration: state == ScrollWordState.wrong
                  ? TextDecoration.lineThrough
                  : null,
              decorationColor: ink,
              decorationThickness: 2,
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: _tappable,
      label: label,
      child: Visibility(
        // A found hex leaves a gap, so the other words never move under the
        // player's finger.
        visible: state != ScrollWordState.broken,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _tappable ? (_) => onTapDown() : null,
          child: word,
        ),
      ),
    );
  }
}

/// The witch's scroll: the spell as she reads it, and the fuse burning down
/// along its foot.
class HexScrollBoard extends StatelessWidget {
  const HexScrollBoard({
    super.key,
    required this.words,
    required this.style,
    required this.stateOf,
    required this.onTap,
    required this.fuse,
    this.textDirection = TextDirection.ltr,
  });

  final List<String> words;
  final TextStyle style;
  final ScrollWordState Function(int index) stateOf;
  final void Function(int index) onTap;

  /// How much of the fuse has burned, from 0 to 1.
  final double fuse;

  /// The order the words read in — right to left for Arabic.
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          // The scroll with its rolled ends, the words between them.
          painter: const PixelSpritePainter.tiled(hexScroll, cell: _cell),
          child: Padding(
            padding: hexScrollFace * _cell +
                const EdgeInsets.symmetric(horizontal: 4),
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
                    children: [
                      for (var i = 0; i < words.length; i++)
                        ScrollWord(
                          label: words[i],
                          style: style,
                          state: stateOf(i),
                          onTapDown: () => onTap(i),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 10,
                    child: CustomPaint(painter: FusePainter(fuse)),
                  ),
                ],
              ),
            ),
          ),
        ),
        // The wax seal the fuse is tied to, where the sheet has it: low on
        // the right, over the fuse's end. It is not part of the scroll, so no
        // word is ever written across it.
        Positioned(
          right: 16,
          bottom: 2,
          child: IgnorePointer(
            child: CustomPaint(
              size: Size(hexSeal.width * _cell, hexSeal.height * _cell),
              painter: const PixelSpritePainter.tiled(hexSeal, cell: _cell),
            ),
          ),
        ),
      ],
    );
  }
}

/// The fuse: rope burning from its right end toward its left, with the spark
/// where it has got to.
class FusePainter extends CustomPainter {
  const FusePainter(this.burned);

  final double burned;

  @override
  void paint(Canvas canvas, Size size) {
    // In whole steps of 4px, like the charge bar's twentieths.
    final left = ((size.width * (1 - burned.clamp(0.0, 1.0))) / 4).floor() * 4.0;
    final mid = (size.height / 2).roundToDouble();
    if (left > 0) {
      hexRope.paint(
        canvas,
        Offset(0, mid - hexRope.height * _cell / 2),
        (left / _cell).floor(),
        hexRope.height,
        cellW: _cell,
        cellH: _cell,
      );
    }
    if (burned >= 1) return;
    // The flame at the burning end, flickering a point up and down. It is
    // taller than the fuse's box and burns over its edge, onto the scroll.
    final flicker = (burned * 40).floor().isEven ? 0.0 : _cell;
    hexSpark.paint(
      canvas,
      Offset(left - hexSpark.width * _cell / 2,
          mid - hexSpark.height * _cell / 2 - flicker),
      hexSpark.width,
      hexSpark.height,
      cellW: _cell,
      cellH: _cell,
    );
  }

  @override
  bool shouldRepaint(covariant FusePainter old) => old.burned != burned;
}

/// The potion she brews over her head and throws when it is ready.
class PotionFlask extends StatelessWidget {
  const PotionFlask({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _PotionPainter());
}

class _PotionPainter extends CustomPainter {
  const _PotionPainter();

  /// The smallest box the whole flask is drawn in: under it a cell of the
  /// sheet's would be under a point, and half of them are dropped. She charges
  /// it at 20 to 48 points.
  static const double _wholeFrom = 32;

  @override
  void paint(Canvas canvas, Size size) =>
      (size.shortestSide >= _wholeFrom ? hexPotion : hexPotionHalf)
          .paintContained(canvas, size);

  @override
  bool shouldRepaint(covariant _PotionPainter oldDelegate) => false;
}
