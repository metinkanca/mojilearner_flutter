/// The props of the toy chest's games, drawn on whole pixels like the pets:
/// the chest beside the pet, the bath, the moles and their molehills, the pond
/// and its lily pads, and the word sticks. (The toys in the open chest are
/// `toy_chest_art.dart`.)
///
/// Drawn in the cozy room's flat colours ([PlayPalette]) on 3pt cells. Small
/// fixed things are [PixelPatternPainter] grids made in
/// `art_src/pxl/toychest.px.js`; things that stretch to fit a word, or move,
/// are painted on the same cell, and every one is drawn from a cached image
/// (see [PlayImageCache]).
library;

import 'package:flutter/material.dart';

import '../home_button_art.dart';
import 'play_kit.dart';
import 'toy_chest_art.dart';

/// How a pad or a sign is showing once a round is answered.
enum PropState { plain, right, wrong, dim }

// ---- the toy chest ----------------------------------------------------------

/// The toy chest beside the pet, a beach ball standing at its side.
/// Generated from `art_src/pxl/buttons.px.js` (see `home_button_art.dart`).
const List<String> toyChestRows = toyChestArtRows;

const PixelPatternPainter toyChestPainter =
    PixelPatternPainter(toyChestRows, toyChestArtInks);

// ---- the bath ---------------------------------------------------------------

const double _c = PlayPalette.cell;

/// The bathroom: a cream wall with a band of glass-blue tile up from the floor
/// to [wainscotTop], capped in ink, and a wood floor under a baseboard line.
class BathroomPainter extends CustomPainter {
  const BathroomPainter({required this.floorTop, required this.wainscotTop});

  final double floorTop;
  final double wainscotTop;

  @override
  void paint(Canvas canvas, Size size) => PlayImageCache.paint(
      canvas, size, ('bathroom', floorTop, wainscotTop), _record);

  void _record(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    final w = size.width;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, w, floorTop), paint..color = PlayPalette.wall);
    if (wainscotTop < floorTop) {
      canvas.drawRect(Rect.fromLTWH(0, wainscotTop, w, floorTop - wainscotTop),
          paint..color = PlayPalette.glass);
      // The seams between the tiles, in the wall's cream.
      paint.color = PlayPalette.wall;
      const t = 8 * _c;
      for (var x = 0.0; x < w; x += t) {
        canvas.drawRect(
            Rect.fromLTWH(x, wainscotTop, _c, floorTop - wainscotTop), paint);
      }
      for (var y = wainscotTop + t; y < floorTop; y += t) {
        canvas.drawRect(Rect.fromLTWH(0, y, w, _c), paint);
      }
      canvas.drawRect(Rect.fromLTWH(0, wainscotTop, w, _c),
          paint..color = PlayPalette.ink);
    }
    canvas.drawRect(
        Rect.fromLTWH(0, floorTop, w, size.height - floorTop),
        paint..color = PlayPalette.wood);
    canvas.drawRect(Rect.fromLTWH(0, floorTop - _c, w, _c),
        paint..color = PlayPalette.ink);
  }

  @override
  bool shouldRepaint(covariant BathroomPainter old) =>
      old.floorTop != floorTop || old.wainscotTop != wainscotTop;
}

/// The tub's inside, seen over its front: a cream rim along the top and the
/// far wall in stone.
class TubBackPainter extends CustomPainter {
  const TubBackPainter();

  @override
  void paint(Canvas canvas, Size size) =>
      PlayImageCache.paint(canvas, size, 'tub back', _record);

  void _record(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    final w = size.width, h = size.height;
    // The outline, its top corners stepped in.
    canvas.drawRect(
        Rect.fromLTWH(2 * _c, 0, w - 4 * _c, h), paint..color = PlayPalette.ink);
    canvas.drawRect(Rect.fromLTWH(0, 2 * _c, w, h - 2 * _c), paint);
    // The rim: two rows of cream with ink under them, then the inside wall.
    canvas.drawRect(Rect.fromLTWH(3 * _c, _c, w - 6 * _c, _c),
        paint..color = PlayPalette.wall);
    canvas.drawRect(Rect.fromLTWH(_c, 2 * _c, w - 2 * _c, _c), paint);
    canvas.drawRect(Rect.fromLTWH(_c, 3 * _c, w - 2 * _c, _c),
        paint..color = PlayPalette.ink);
    canvas.drawRect(Rect.fromLTWH(_c, 4 * _c, w - 2 * _c, h - 4 * _c),
        paint..color = PlayPalette.stone);
  }

  @override
  bool shouldRepaint(covariant TubBackPainter old) => false;
}

/// The tub's front: coral under a cream rim, on gold claw feet. Words are
/// spelled on it.
class TubFrontPainter extends CustomPainter {
  const TubFrontPainter();

  /// How tall the feet stand under it.
  static const double feetH = 4 * _c;

  @override
  void paint(Canvas canvas, Size size) =>
      PlayImageCache.paint(canvas, size, 'tub front', _record);

  void _record(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    final w = size.width, h = size.height - feetH;
    // Feet first, under the belly.
    for (final x in [4 * _c, w - 9 * _c]) {
      canvas.drawRect(Rect.fromLTWH(x, h - _c, 5 * _c, feetH + _c),
          paint..color = PlayPalette.ink);
      canvas.drawRect(Rect.fromLTWH(x + _c, h, 3 * _c, feetH - _c),
          paint..color = PlayPalette.gold);
    }
    // The body, its bottom corners rounded off in steps.
    canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h - 2 * _c), paint..color = PlayPalette.ink);
    canvas.drawRect(Rect.fromLTWH(_c, h - 2 * _c, w - 2 * _c, _c), paint);
    canvas.drawRect(Rect.fromLTWH(2 * _c, h - _c, w - 4 * _c, _c), paint);
    canvas.drawRect(Rect.fromLTWH(_c, _c, w - 2 * _c, h - 3 * _c),
        paint..color = PlayPalette.coral);
    canvas.drawRect(Rect.fromLTWH(2 * _c, h - 2 * _c, w - 4 * _c, _c), paint);
    // The rim's roll along the top, and the seam under it.
    canvas.drawRect(Rect.fromLTWH(_c, _c, w - 2 * _c, 2 * _c),
        paint..color = PlayPalette.wall);
    canvas.drawRect(Rect.fromLTWH(_c, 3 * _c, w - 2 * _c, _c),
        paint..color = PlayPalette.ink);
  }

  @override
  bool shouldRepaint(covariant TubFrontPainter old) => false;
}

/// The bathwater: a flat band of glass-blue with a line of cream along its
/// surface, stepping along as time goes.
class BathWaterPainter extends CustomPainter {
  const BathWaterPainter(this.time);

  final double time;

  /// Bursts of bubble bath on the surface, and on the letters.
  static const List<Color> foam = [
    PlayPalette.wall,
    PlayPalette.glass,
    PlayPalette.wall,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height <= 0) return;
    final paint = Paint()..isAntiAlias = false;
    // The waves step in from past either end: none may show outside the tub.
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint..color = PlayPalette.glass);
    paint.color = PlayPalette.wall;
    // A wavy surface line, stepping by whole cells.
    final shift = ((time * 6) / _c).floor() * _c;
    for (var x = -2 * _c; x < size.width; x += 6 * _c) {
      final at = (x + shift) % (size.width + 6 * _c) - 3 * _c;
      canvas.drawRect(Rect.fromLTWH(at, 0, 4 * _c, _c), paint);
      canvas.drawRect(Rect.fromLTWH(at + 4 * _c, _c, 2 * _c, _c), paint);
    }
  }

  @override
  bool shouldRepaint(covariant BathWaterPainter old) => old.time != time;
}

// ---- the garden -------------------------------------------------------------

/// What a pounce kicks up.
const List<Color> moleDirt = [
  PlayPalette.wood,
  PlayPalette.wall,
  PlayPalette.leaf,
];

/// A molehill, in two halves so a mole can rise between them: the [back] of
/// the mound, a wood ring round the dark hole, and its front lip, which covers
/// the mole's feet. The lip hangs from the line the moles come out of; the
/// back stands [backAbove] over it.
class MoundPiece extends StatelessWidget {
  const MoundPiece({super.key, required this.back});

  final bool back;

  static final double w = moundBackArtRows.first.length * _c;
  static final double backH = moundBackArtRows.length * _c;
  static final double frontH = moundFrontArtRows.length * _c;

  /// How far above the line the back's top stands: its hole is where the
  /// mole comes out of.
  static const double backAbove = 5 * _c;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: w,
      height: back ? backH : frontH,
      child: CustomPaint(
        painter: back
            ? const PixelPatternPainter(moundBackArtRows, moundBackArtInks)
            : const PixelPatternPainter(moundFrontArtRows, moundFrontArtInks),
      ),
    );
  }
}

/// The face of a mole's sign once the round is answered: coral for a wrong
/// mole, leaf green lit for the right one.
Color moleFace(PropState state) => switch (state) {
      PropState.plain => PlayPalette.wall,
      PropState.right => PlayPalette.leaf,
      PropState.wrong => PlayPalette.coral,
      PropState.dim => PlayPalette.stone,
    };

/// A mole holding up a sign with a word on it: its egg-shaped head behind the
/// sign, its claws over the sign's top edge.
class MoleSign extends StatelessWidget {
  const MoleSign({
    super.key,
    required this.label,
    required this.style,
    required this.onTapDown,
    this.state = PropState.plain,
    this.bonked = false,
  });

  final String label;
  final TextStyle style;
  final VoidCallback? onTapDown;
  final PropState state;
  final bool bonked;

  static final double headW = moleHeadArtRows.first.length * _c;
  static final double headH = moleHeadArtRows.length * _c;
  static final double clawsW = moleClawsArtRows.first.length * _c;
  static final double clawsH = moleClawsArtRows.length * _c;

  /// How far the sign covers the foot of the head.
  static const double overlap = 2 * _c;
  static const double signH = 12 * _c;

  /// The mole and its sign together.
  static final double popH = headH + signH - overlap;

  @override
  Widget build(BuildContext context) {
    const claws = CustomPaint(
      painter: PixelPatternPainter(moleClawsArtRows, moleClawsArtInks),
    );
    return Semantics(
      button: onTapDown != null,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: onTapDown == null ? null : (_) => onTapDown!(),
        child: LayoutBuilder(builder: (context, box) {
          final centre = box.maxWidth / 2;
          final signTop = popH - signH;
          // Over the sign's top corners, either side of the head.
          final clawTop = signTop - clawsH + 2 * _c;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: (centre - headW / 2).roundToDouble(),
                top: 0,
                width: headW,
                height: headH,
                child: CustomPaint(
                  painter: bonked
                      ? const PixelPatternPainter(
                          moleHeadBonkArtRows, moleHeadBonkArtInks)
                      : const PixelPatternPainter(
                          moleHeadArtRows, moleHeadArtInks),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: signH,
                child: PixelPanel(
                  color: moleFace(state),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(label, maxLines: 1, style: style),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: (centre - headW / 2 - clawsW + 2 * _c).roundToDouble(),
                top: clawTop,
                width: clawsW,
                height: clawsH,
                child: claws,
              ),
              Positioned(
                left: (centre + headW / 2 - 2 * _c).roundToDouble(),
                top: clawTop,
                width: clawsW,
                height: clawsH,
                child: claws,
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ---- the pond ---------------------------------------------------------------

/// The pond, its ripples drifting with [time]: flat glass-blue water, with
/// rows of cream ripples that each drift their own way.
///
/// The ripples are two images, one for the rows that drift right and one for
/// those that drift left, each a strip that repeats every [period]; a frame
/// slides each along and draws it. They used to be a rectangle apiece, some
/// three hundred a frame.
class PondPainter extends CustomPainter {
  const PondPainter(this.time);

  final double time;

  static const Color water = PlayPalette.glass;
  static const Color ripple = PlayPalette.wall;

  /// The lit line along the tide's edge.
  static const Color glint = PlayPalette.wall;

  /// A splash.
  static const List<Color> splash = [
    PlayPalette.glass,
    PlayPalette.wall,
    PlayPalette.wall,
  ];

  /// How far apart a row's ripples are: the strips repeat at this.
  static const double period = 28 * _c;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint..color = water);
    final ratio = PlayImageCache.pixelRatio;
    paint.filterQuality = FilterQuality.none;
    for (var parity = 0; parity < 2; parity++) {
      final image = PlayImageCache.image(
        ('ripples', parity),
        Size(size.width + period, size.height),
        (c, s) => _record(c, s, parity),
      );
      // Rows drift opposite ways, in whole cells.
      final shift =
          ((time * 8 * (parity == 0 ? 1 : -1)) / _c).floor() * _c;
      final x = (shift % period) - period;
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(x, 0, image.width / ratio, image.height / ratio),
        paint,
      );
    }
  }

  void _record(Canvas canvas, Size size, int parity) {
    final paint = Paint()
      ..isAntiAlias = false
      ..color = ripple;
    var row = 0;
    for (var y = 3 * _c; y < size.height - _c; y += 7 * _c, row++) {
      if (row % 2 != parity) continue;
      // Each row's own offset, so the ripples do not line up in columns.
      final offset = (row * 37 % 28) * _c;
      for (var x = offset - period; x < size.width; x += period) {
        canvas.drawRect(Rect.fromLTWH(x, y, 5 * _c, _c), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PondPainter old) => old.time != time;
}

/// A bank of grass at the edge of the pond, its edge facing [down] the
/// screen (the far bank) or up it (the near one): a strip of soil, then a
/// line of ink where it meets the water.
class BankPainter extends CustomPainter {
  const BankPainter({required this.down});

  final bool down;

  @override
  void paint(Canvas canvas, Size size) => PlayImageCache.paint(
      canvas, size, ('bank', down), _record);

  void _record(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, paint..color = PlayPalette.leaf);
    canvas.drawRect(Rect.fromLTWH(0, down ? h - 3 * _c : _c, w, 2 * _c),
        paint..color = PlayPalette.wood);
    canvas.drawRect(Rect.fromLTWH(0, down ? h - _c : 0, w, _c),
        paint..color = PlayPalette.ink);
    // Tufts of grass, in ink.
    for (var x = 6 * _c; x < w; x += 17 * _c) {
      final y = down ? 3 * _c : h - 5 * _c;
      canvas.drawRect(Rect.fromLTWH(x, y, _c, 2 * _c), paint);
      canvas.drawRect(Rect.fromLTWH(x + 2 * _c, y + _c, _c, _c), paint);
    }
  }

  @override
  bool shouldRepaint(covariant BankPainter old) => old.down != down;
}

/// A lily pad with a meaning on it. [sunk] is how far under it has gone, 0
/// to 1: it slides down out of its box, into the pond.
class LilyPad extends StatelessWidget {
  const LilyPad({
    super.key,
    required this.label,
    required this.style,
    required this.onTapDown,
    this.state = PropState.plain,
    this.sunk = 0,
  });

  /// Null for a pad with nothing on it yet: a row still to come.
  final String? label;
  final TextStyle style;
  final VoidCallback? onTapDown;
  final PropState state;
  final double sunk;

  /// The pad's size: whole cells, so it is drawn crisp.
  static final double w = lilyPadArtRows.first.length * _c;
  static final double h = lilyPadArtRows.length * _c;

  @override
  Widget build(BuildContext context) {
    final words = label;
    final painter = switch (state) {
      PropState.right =>
        const PixelPatternPainter(lilyPadRightArtRows, lilyPadRightArtInks),
      PropState.wrong =>
        const PixelPatternPainter(lilyPadWrongArtRows, lilyPadWrongArtInks),
      _ => const PixelPatternPainter(lilyPadArtRows, lilyPadArtInks),
    };
    return Semantics(
      button: onTapDown != null,
      label: words,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: onTapDown == null ? null : (_) => onTapDown!(),
        child: ClipRect(
          child: LayoutBuilder(builder: (context, box) {
            final down = ((sunk * 6).ceil() / 6).clamp(0.0, 1.0);
            return Transform.translate(
              offset: Offset(0, (down * box.maxHeight / _c).round() * _c),
              child: CustomPaint(
                painter: painter,
                child: words == null
                    ? const SizedBox.expand()
                    : Padding(
                        // Inside the pad, clear of its edges.
                        padding: const EdgeInsets.fromLTRB(9, 6, 9, 6),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(words, maxLines: 1, style: style),
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
}

// ---- the park ---------------------------------------------------------------

/// A stick with a word on it, waiting to be fetched.
class WordStick extends StatelessWidget {
  const WordStick({
    super.key,
    required this.label,
    required this.style,
    required this.onTapDown,
    this.used = false,
    this.flashing = false,
  });

  final String label;
  final TextStyle style;

  /// Given where the tap landed, so the stick can be thrown from there.
  final void Function(Offset global)? onTapDown;

  /// Already fetched: its place on the grass is left empty, so the other
  /// sticks never shuffle about under the player's finger.
  final bool used;

  /// Just refused: its face flashes coral.
  final bool flashing;

  static const double height = 44;

  @override
  Widget build(BuildContext context) {
    final stick = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 64),
      child: SizedBox(
        height: height,
        child: Padding(
          // Clear of the twig over its top: the word sits on the body.
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
          child: Align(
            widthFactor: 1,
            child: Text(label, maxLines: 1, style: style),
          ),
        ),
      ),
    );
    return Semantics(
      button: !used,
      label: label,
      child: Visibility(
        visible: !used,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: used || onTapDown == null
              ? null
              : (d) => onTapDown!(d.globalPosition),
          child: CustomPaint(
            painter: StickPainter(flashing: flashing),
            child: stick,
          ),
        ),
      ),
    );
  }
}

/// A stick: a wood face for its word between two ringed ends, a twig off its
/// top, all fenced in ink. Drawn on whole cells, from an image of each size.
class StickPainter extends CustomPainter {
  const StickPainter({this.flashing = false});

  final bool flashing;

  @override
  void paint(Canvas canvas, Size size) => PlayImageCache.paint(
      canvas, size, ('stick', flashing), _record);

  void _record(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    final w = size.width, h = size.height;
    final top = 3 * _c;
    // The twig, off the top right.
    canvas.drawRect(Rect.fromLTWH(w - 8 * _c, 0, 3 * _c, top + _c),
        paint..color = PlayPalette.ink);
    canvas.drawRect(Rect.fromLTWH(w - 7 * _c, _c, _c, top),
        paint..color = PlayPalette.wood);
    // The stick: outline with stepped ends, wood inside.
    canvas.drawRect(Rect.fromLTWH(_c, top, w - 2 * _c, h - top),
        paint..color = PlayPalette.ink);
    canvas.drawRect(Rect.fromLTWH(0, top + _c, w, h - top - 2 * _c), paint);
    canvas.drawRect(Rect.fromLTWH(_c, top + _c, w - 2 * _c, h - top - 2 * _c),
        paint..color = flashing ? PlayPalette.coral : PlayPalette.wood);
    // Rings on the ends, which set the face for the word apart from them.
    paint.color = PlayPalette.ink;
    canvas.drawRect(
        Rect.fromLTWH(3 * _c, top + 2 * _c, _c, h - top - 4 * _c), paint);
    canvas.drawRect(
        Rect.fromLTWH(w - 4 * _c, top + 2 * _c, _c, h - top - 4 * _c), paint);
  }

  @override
  bool shouldRepaint(covariant StickPainter old) => old.flashing != flashing;
}

/// The pet's patience in Fetch the Words: a row of hearts that empty from the
/// right as it waits.
class PatienceHearts extends StatelessWidget {
  const PatienceHearts({super.key, required this.left, this.count = 5});

  /// How much patience is left, 0 to 1.
  final double left;
  final int count;

  @override
  Widget build(BuildContext context) {
    // In halves, so it empties in visible steps.
    final halves = (left.clamp(0.0, 1.0) * count * 2).ceil();
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: SizedBox(
              width: 18,
              height: 16,
              child: CustomPaint(
                painter: PixelPatternPainter(
                  _heartRows,
                  halves >= 2 * (i + 1)
                      ? _fullHeart
                      : halves == 2 * i + 1
                          ? _halfHeart
                          : _emptyHeart,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 'A' the left half's fill and 'B' the right's, so a heart can be half
  /// spent.
  static const List<String> _heartRows = [
    '..XX.XX..',
    '.XAAXBBX.',
    'XAAAABBBX',
    'XAAAABBBX',
    '.XAAABBX.',
    '..XAABX..',
    '...XAX...',
    '....X....',
  ];

  static const Map<String, Color> _fullHeart = {
    'X': PlayPalette.ink,
    'A': PlayPalette.coral,
    'B': PlayPalette.coral,
  };

  /// Left half full, right half spent.
  static const Map<String, Color> _halfHeart = {
    'X': PlayPalette.ink,
    'A': PlayPalette.coral,
    'B': PlayPalette.stone,
  };

  static const Map<String, Color> _emptyHeart = {
    'X': PlayPalette.ink,
    'A': PlayPalette.stone,
    'B': PlayPalette.stone,
  };
}
