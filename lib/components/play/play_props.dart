/// The props of the toy chest's games, drawn on whole pixels like the pets:
/// the chest itself and the toys in it, the bath, the moles and their
/// molehills, the pond and its lily pads, and the word sticks.
///
/// All placeholder art in the app's own palette, the way the beach ball is —
/// no sheet from the owner yet. Small fixed things are [PixelPatternPainter]
/// grids; things that stretch to fit a word are painted on a 4px cell.
library;

import 'dart:math';

import 'package:flutter/material.dart';

import '../../constants/theme.dart';
import 'play_kit.dart';

const double _u = 4;
const Color _outline = AppTheme.retroDark;

/// How a pad, a stick or a sign is showing once a round is answered.
enum PropState { plain, right, wrong, dim }

/// A word's face in [state]: lit gold for the right answer, red for a wrong
/// pick, faded for the rest — flat colours, since pale tints read as nothing
/// at arm's length.
Color propFace(PropState state, Color plain) => switch (state) {
      PropState.plain => plain,
      PropState.right => AppTheme.retroAccent,
      PropState.wrong => AppTheme.retroPrimary,
      PropState.dim => const Color(0xFFB9B4AA),
    };

/// The ink a word on [state]'s face is written in.
Color propInk(PropState state) => switch (state) {
      PropState.wrong => AppTheme.retroLight,
      PropState.dim => const Color(0xFF55524D),
      _ => _outline,
    };

// ---- the toy chest ----------------------------------------------------------

const Map<String, Color> _chestInks = {
  'X': _outline,
  'l': AppTheme.wardrobeShelf,
  'L': AppTheme.wardrobeWoodLight,
  'W': AppTheme.wardrobeWood,
  'D': AppTheme.wardrobeWoodDark,
  'y': AppTheme.wardrobeBrass,
  'r': AppTheme.retroPrimary,
  'h': Color(0xFFF1A7AE),
  'o': AppTheme.retroLight,
  'b': Color(0xFF5B6EE1),
  's': Color(0x40000000),
};

/// The toy chest beside the pet, the beach ball resting on its lid.
const List<String> toyChestRows = [
  '.........XXX..',
  '........XrrrX.',
  '.......XrhrrrX',
  '.......XoooooX',
  '.......XbbbbbX',
  '........XbbbX.',
  '.XXXXXXXXXXXX.',
  'XllllllllllllX',
  'XLLLLLLLLLLLLX',
  'XDDDDDyyDDDDDX',
  'XXXXXXyyXXXXXX',
  'XWWWWWyyWWWWWX',
  'XWWWWWWWWWWWWX',
  'XWWWWWWWWWWWWX',
  'XDDDDDDDDDDDDX',
  'XXXXXXXXXXXXXX',
  '.ssssssssssss.',
];

const PixelPatternPainter toyChestPainter =
    PixelPatternPainter(toyChestRows, _chestInks);

// ---- the toys in it ---------------------------------------------------------

const Map<String, Color> _toyInks = {
  'X': _outline,
  'y': AppTheme.retroAccent,
  'd': Color(0xFFD9A020),
  'o': AppTheme.retroOrange,
  'm': Color(0xFF7A5A48),
  'n': Color(0xFF5A4034),
  'p': Color(0xFFF1A7AE),
  'g': Color(0xFF6ABE30),
  'G': Color(0xFF3F7F22),
  'e': Color(0xFF2E5E1A),
  'w': AppTheme.retroLight,
  'k': Color(0xFF8F563B),
  'K': Color(0xFF663931),
  't': Color(0xFFD9A066),
  'D': Color(0xFF4A3426),
};

/// Bubble Bath's toy: a rubber duck.
const List<String> rubberDuckRows = [
  '......XXX...',
  '.....XyyyX..',
  '.....XyXyXX.',
  '.....XyyyXoX',
  '.X...XyyyXX.',
  'XyXXXXyyyyX.',
  'XyyyyyyyyyX.',
  'XyyyyyyyydX.',
  '.XddddddddX.',
  '..XXXXXXXX..',
];

/// Pounce's toy: a mole peeking out of its hill.
const List<String> moleToyRows = [
  '....XXXX....',
  '...XmmmmX...',
  '..XmXmmXmX..',
  '..XmmppmmX..',
  '..XmmmmmmX..',
  '.XXnnnnnnXX.',
  'XnnnDDDDnnnX',
  'XnnnnnnnnnnX',
  '.XXXXXXXXXX.',
];

/// Pond Hop's toy: a lily pad with a flower.
const List<String> lilyPadToyRows = [
  '......XX....',
  '.....XpwX...',
  '..XXXXpXXX..',
  '.XggGXXgggX.',
  'XggggXgggggX',
  'XgggGXggGggX',
  'XggGggggggGX',
  '.XgggGgggeX.',
  '..XXeeeeXX..',
  '....XXXX....',
];

/// Fetch the Words' toy: a stick.
const List<String> stickToyRows = [
  '.........XX.',
  '........XtX.',
  '.....XX.XtX.',
  '....XtkXtkX.',
  '...XtkkkkX..',
  '..XtkkKX....',
  '.XtkkKX.....',
  'XtkkKX......',
  'XkKKX.......',
  '.XXX........',
];

PixelPatternPainter toyPainter(List<String> rows) =>
    PixelPatternPainter(rows, _toyInks);

// ---- the bath ---------------------------------------------------------------

/// The bathroom: tiles on the wall down to [floorTop], a checked floor under
/// it.
class BathroomPainter extends CustomPainter {
  const BathroomPainter({required this.floorTop});

  final double floorTop;

  static const Color tile = Color(0xFFA9D8E8);
  static const Color tileLight = Color(0xFFC8E8F2);
  static const Color grout = Color(0xFF7FB3C6);
  static const Color floorA = Color(0xFFE8E2D6);
  static const Color floorB = Color(0xFFC9BFAE);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, floorTop), paint..color = tile);
    const t = 8 * _u;
    for (var y = 0.0; y < floorTop; y += t) {
      for (var x = 0.0; x < size.width; x += t) {
        // A glint in each tile's corner, grout round it.
        canvas.drawRect(Rect.fromLTWH(x + _u, y + _u, 2 * _u, _u),
            paint..color = tileLight);
        canvas.drawRect(Rect.fromLTWH(x, y, t, _u / 2), paint..color = grout);
        canvas.drawRect(Rect.fromLTWH(x, y, _u / 2, t), paint);
      }
    }
    canvas.drawRect(
        Rect.fromLTWH(0, floorTop, size.width, size.height - floorTop),
        paint..color = floorA);
    const f = 6 * _u;
    var row = 0;
    for (var y = floorTop; y < size.height; y += f, row++) {
      for (var x = (row.isEven ? 0.0 : f); x < size.width; x += 2 * f) {
        canvas.drawRect(Rect.fromLTWH(x, y, f, f), paint..color = floorB);
      }
    }
    canvas.drawRect(Rect.fromLTWH(0, floorTop - _u, size.width, _u),
        paint..color = _outline);
  }

  @override
  bool shouldRepaint(covariant BathroomPainter old) => old.floorTop != floorTop;
}

/// The tub's inside, seen over its front: the far wall, darker the deeper.
class TubBackPainter extends CustomPainter {
  const TubBackPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    final w = size.width, h = size.height;
    // The rim: outline, white enamel, then the shadowed inside.
    canvas.drawRect(
        Rect.fromLTWH(2 * _u, 0, w - 4 * _u, h), paint..color = _outline);
    canvas.drawRect(Rect.fromLTWH(0, 2 * _u, w, h - 2 * _u), paint);
    canvas.drawRect(Rect.fromLTWH(3 * _u, _u, w - 6 * _u, h - _u),
        paint..color = TubFrontPainter.enamel);
    canvas.drawRect(Rect.fromLTWH(_u, 3 * _u, w - 2 * _u, h - 3 * _u), paint);
    canvas.drawRect(Rect.fromLTWH(3 * _u, 3 * _u, w - 6 * _u, h - 3 * _u),
        paint..color = const Color(0xFFB8C6D0));
  }

  @override
  bool shouldRepaint(covariant TubBackPainter old) => false;
}

/// The tub's front: white enamel on gold claw feet. Words are spelled on it.
class TubFrontPainter extends CustomPainter {
  const TubFrontPainter();

  static const Color enamel = Color(0xFFF4F1EC);
  static const Color shade = Color(0xFFC9C6C0);
  static const Color feet = Color(0xFFE3B65D);

  /// How tall the feet stand under it.
  static const double feetH = 3 * _u;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    final w = size.width, h = size.height - feetH;
    // Feet first, under the belly.
    for (final x in [4 * _u, w - 9 * _u]) {
      canvas.drawRect(Rect.fromLTWH(x, h - _u, 5 * _u, feetH + _u),
          paint..color = _outline);
      canvas.drawRect(
          Rect.fromLTWH(x + _u, h, 3 * _u, feetH - _u), paint..color = feet);
    }
    // The body, its bottom corners rounded off in steps.
    canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h - 2 * _u), paint..color = _outline);
    canvas.drawRect(Rect.fromLTWH(_u, h - 2 * _u, w - 2 * _u, _u), paint);
    canvas.drawRect(Rect.fromLTWH(2 * _u, h - _u, w - 4 * _u, _u), paint);
    canvas.drawRect(
        Rect.fromLTWH(_u, _u, w - 2 * _u, h - 3 * _u), paint..color = enamel);
    canvas.drawRect(Rect.fromLTWH(2 * _u, h - 2 * _u, w - 4 * _u, _u), paint);
    // The rim's roll along the top, and the belly's shadow along the bottom.
    canvas.drawRect(
        Rect.fromLTWH(_u, 2 * _u, w - 2 * _u, _u), paint..color = shade);
    canvas.drawRect(
        Rect.fromLTWH(3 * _u, h - 4 * _u, w - 6 * _u, 2 * _u), paint);
  }

  @override
  bool shouldRepaint(covariant TubFrontPainter old) => false;
}

/// The bathwater: a band of water with a lighter line along its surface.
class BathWaterPainter extends CustomPainter {
  const BathWaterPainter(this.time);

  final double time;

  static const Color water = Color(0xCC5FA8E0);
  static const Color surface = Color(0xFFBFE3FA);

  /// Bursts of bubble bath on the surface, and on the letters.
  static const List<Color> foam = [surface, Color(0xFFFFFFFF), water];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height <= 0) return;
    final paint = Paint()..isAntiAlias = false;
    canvas.drawRect(Offset.zero & size, paint..color = water);
    // A wavy surface line, stepping by whole cells.
    final shift = ((time * 6) / _u).floor() * _u;
    for (var x = -2 * _u; x < size.width; x += 6 * _u) {
      final at = (x + shift) % (size.width + 6 * _u) - 3 * _u;
      canvas.drawRect(Rect.fromLTWH(at, 0, 4 * _u, _u), paint..color = surface);
      canvas.drawRect(Rect.fromLTWH(at + 4 * _u, _u, 2 * _u, _u), paint);
    }
  }

  @override
  bool shouldRepaint(covariant BathWaterPainter old) => old.time != time;
}

// ---- the garden -------------------------------------------------------------

/// A molehill: a mound of earth round the hole a mole comes out of. Drawn in
/// two halves, so the mole can rise between them: the [back] of the mound
/// with the dark hole, and its front lip, which covers the mole's feet.
class MolehillPainter extends CustomPainter {
  const MolehillPainter({required this.back});

  final bool back;

  static const Color earth = Color(0xFF8F5A3A);
  static const Color earthLight = Color(0xFFB07A52);
  static const Color hole = Color(0xFF1C130E);

  /// What a pounce kicks up.
  static const List<Color> dirt = [earth, earthLight, Color(0xFF4B8F1D)];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    final cols = (size.width / _u).floor();
    final rows = (size.height / _u).floor();
    if (cols < 8 || rows < 3) return;
    final x0 = ((size.width - cols * _u) / 2).roundToDouble();

    void run(int y, int from, int to, Color color) {
      if (to <= from) return;
      canvas.drawRect(
        Rect.fromLTWH(x0 + from * _u, y * _u, (to - from) * _u, _u),
        paint..color = color,
      );
    }

    if (back) {
      // The far rim of the mound, stepping in at the top, and the hole sunk
      // in it: the mole comes up out of the dark.
      const insets = [5, 3, 2, 1];
      for (var y = 0; y < rows; y++) {
        final inset = insets[min(y, insets.length - 1)];
        run(y, inset, cols - inset, _outline);
        if (y == 0) continue;
        run(y, inset + 1, cols - inset - 1, y == 1 ? earthLight : earth);
        // The hole: an oval of dark, narrower at its far edge.
        if (y < 2) continue;
        final edge = inset + 2 + (y == 2 ? 1 : 0);
        run(y, edge, cols - edge, hole);
      }
      return;
    }
    // The near side: a dome of earth over the mole's feet, its rim narrow
    // round the hole and spreading out to the grass.
    const insets = [3, 2, 1, 0];
    for (var y = 0; y < rows; y++) {
      final inset = insets[min(y, insets.length - 1)];
      run(y, inset, cols - inset, _outline);
      if (y == 0 || y == rows - 1) continue;
      run(y, inset + 1, cols - inset - 1, y == 1 ? earthLight : earth);
    }
  }

  @override
  bool shouldRepaint(covariant MolehillPainter old) => old.back != back;
}

const Map<String, Color> _moleInks = {
  'X': _outline,
  'm': Color(0xFF6E5446),
  'M': Color(0xFF4F3B31),
  'p': Color(0xFFF1A7AE),
  'w': AppTheme.retroLight,
};

/// A mole's head and paws, peeking over the sign it holds up.
const List<String> _moleRows = [
  '...XXXXXX...',
  '..XmmmmmmX..',
  '.XmmmmmmmmX.',
  '.XmXmmmmXmX.',
  '.XmmmppmmmX.',
  '.XMmmppmmMX.',
  'XppXMMMMXppX',
  'XppX....XppX',
];

/// The same mole, eyes screwed shut: bonked.
const List<String> _moleBonkedRows = [
  '...XXXXXX...',
  '..XmmmmmmX..',
  '.XmmmmmmmmX.',
  '.XXXmmmmXXX.',
  '.XmmmppmmmX.',
  '.XMmmppmmMX.',
  'XppXMMMMXppX',
  'XppX....XppX',
];

/// A mole holding up a sign with a word on it.
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

  /// The mole's head over the sign, as a share of the sign's height.
  static const double headShare = 0.62;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTapDown != null,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: onTapDown == null ? null : (_) => onTapDown!(),
        child: LayoutBuilder(builder: (context, box) {
          final signH = box.maxHeight / (1 + headShare);
          final headH = box.maxHeight - signH;
          final headW = headH * 12 / 8;
          return Stack(
            children: [
              Positioned(
                left: (box.maxWidth - headW) / 2,
                top: 0,
                width: headW,
                height: headH + _u,
                child: CustomPaint(
                  painter: PixelPatternPainter(
                      bonked ? _moleBonkedRows : _moleRows, _moleInks),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: signH,
                child: CustomPaint(
                  painter: WoodPanelPainter(
                      face: propFace(state, const Color(0xFFF3E2C3))),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(label, maxLines: 1, style: style),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// A board of wood with a face for a word: the moles' signs.
class WoodPanelPainter extends CustomPainter {
  const WoodPanelPainter({required this.face});

  final Color face;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    final w = size.width, h = size.height;
    canvas.drawRect(
        Rect.fromLTWH(_u, 0, w - 2 * _u, h), paint..color = _outline);
    canvas.drawRect(Rect.fromLTWH(0, _u, w, h - 2 * _u), paint);
    canvas.drawRect(Rect.fromLTWH(_u, _u, w - 2 * _u, h - 2 * _u),
        paint..color = AppTheme.wardrobeWood);
    canvas.drawRect(Rect.fromLTWH(2 * _u, 2 * _u, w - 4 * _u, h - 4 * _u),
        paint..color = face);
  }

  @override
  bool shouldRepaint(covariant WoodPanelPainter old) => old.face != face;
}

// ---- the pond ---------------------------------------------------------------

/// The pond, its ripples drifting with [time].
class PondPainter extends CustomPainter {
  const PondPainter(this.time);

  final double time;

  static const Color water = Color(0xFF3B7DD8);
  static const Color ripple = Color(0xFF5A9BF0);
  static const Color glint = Color(0xFFA9D4FF);

  /// A splash.
  static const List<Color> splash = [ripple, glint, Color(0xFFFFFFFF)];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    canvas.drawRect(Offset.zero & size, paint..color = water);
    // Ripples in rows, each row drifting its own way, in whole cells.
    var row = 0;
    for (var y = 3 * _u; y < size.height - _u; y += 7 * _u, row++) {
      final dir = row.isEven ? 1 : -1;
      final shift = ((time * 8 * dir) / _u).floor() * _u;
      for (var x = (row * 37 % 80) - 80.0; x < size.width; x += 80) {
        final at = (x + shift) % (size.width + 80) - 40;
        canvas.drawRect(
            Rect.fromLTWH(at, y, 5 * _u, _u), paint..color = ripple);
        canvas.drawRect(
            Rect.fromLTWH(at + _u, y, _u, _u), paint..color = glint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PondPainter old) => old.time != time;
}

/// A bank of grass at the edge of the pond, its edge facing [down] the
/// screen (the far bank) or up it (the near one).
class BankPainter extends CustomPainter {
  const BankPainter({required this.down});

  final bool down;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, paint..color = AppTheme.retroGrass);
    final edge = down ? h - 2 * _u : 0.0;
    canvas.drawRect(Rect.fromLTWH(0, edge, w, 2 * _u),
        paint..color = const Color(0xFF8F5A3A));
    canvas.drawRect(Rect.fromLTWH(0, down ? h - _u : 2 * _u, w, _u),
        paint..color = _outline);
    // Tufts.
    for (var x = 6 * _u; x < w; x += 17 * _u) {
      final y = down ? 3 * _u : h - 5 * _u;
      canvas.drawRect(Rect.fromLTWH(x, y, _u, 2 * _u),
          paint..color = AppTheme.retroGrassDark);
      canvas.drawRect(Rect.fromLTWH(x + 2 * _u, y + _u, _u, _u), paint);
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

  static const Color pad = Color(0xFF8FD14F);

  @override
  Widget build(BuildContext context) {
    final words = label;
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
              offset: Offset(0, (down * box.maxHeight / _u).round() * _u),
              child: CustomPaint(
                painter: _LilyPadPainter(face: propFace(state, pad)),
                child: words == null
                    ? const SizedBox.expand()
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
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

class _LilyPadPainter extends CustomPainter {
  const _LilyPadPainter({required this.face});

  final Color face;

  static const Color rim = Color(0xFF2E6B2A);
  static const Color vein = Color(0xFF5FA83A);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    final cols = (size.width / _u).floor();
    final rows = (size.height / _u).floor();
    if (cols < 6 || rows < 4) return;
    final x0 = ((size.width - cols * _u) / 2).roundToDouble();
    final a = cols / 2, b = rows / 2;
    // The notch: a wedge cut into the top edge, right of centre.
    final notchFrom = (a + 1).floor(), notchTo = (a + 1 + cols / 8).ceil();

    (int, int) span(double inset, int y) {
      final ry = b - inset;
      final dy = y + 0.5 - b;
      if (ry <= 0 || dy.abs() > ry) return (0, 0);
      final half = (a - inset) * sqrt(1 - (dy / ry) * (dy / ry));
      return ((a - half).round(), (a + half).round());
    }

    void run(int y, int from, int to, Color color) {
      if (to <= from) return;
      canvas.drawRect(
        Rect.fromLTWH(x0 + from * _u, y * _u, (to - from) * _u, _u),
        paint..color = color,
      );
    }

    final notchRows = (rows / 3).ceil();
    for (var y = 0; y < rows; y++) {
      final (o0, o1) = span(0, y);
      final (i0, i1) = span(1, y);
      if (y >= notchRows || o1 <= notchFrom) {
        run(y, o0, o1, rim);
        run(y, i0, i1, face);
        continue;
      }
      // Either side of the notch, each closed off with rim; the notch
      // itself is left unpainted, so the water shows through it.
      run(y, o0, min(o1, notchFrom), rim);
      run(y, i0, min(i1, notchFrom - 1), face);
      run(y, max(o0, notchTo), o1, rim);
      run(y, max(i0, notchTo + 1), i1, face);
      if (y == notchRows - 1) run(y, notchFrom, notchTo, rim);
    }
    // Two veins running out from the notch, low down where words seldom go.
    if (face == LilyPad.pad) {
      run(rows - 3, (a - cols / 4).round(), (a - cols / 4).round() + 2, vein);
      run(rows - 3, (a + cols / 5).round(), (a + cols / 5).round() + 2, vein);
    }
  }

  @override
  bool shouldRepaint(covariant _LilyPadPainter old) => old.face != face;
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

  /// Already fetched: a flattened patch of grass is left where it lay, so
  /// the other sticks never shuffle about under the player's finger.
  final bool used;

  /// Just refused: its face flashes red.
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
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.fromLTRB(6, 12, 6, 6),
              color: Colors.black.withValues(alpha: used ? 0.18 : 0),
            ),
          ),
          Visibility(
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
        ],
      ),
    );
  }
}

/// A stick: a pale-wood face for its word between knobbly ends, a twig off
/// its top.
class StickPainter extends CustomPainter {
  const StickPainter({this.flashing = false});

  final bool flashing;

  static const Color wood = Color(0xFFD9A066);
  static const Color bark = Color(0xFF8F563B);
  static const Color barkDark = Color(0xFF663931);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    final w = size.width, h = size.height;
    final top = 3 * _u;
    final face = flashing ? AppTheme.retroPrimary : wood;
    // The twig, off the top right.
    canvas.drawRect(Rect.fromLTWH(w - 7 * _u, 0, 3 * _u, top + _u),
        paint..color = _outline);
    canvas.drawRect(
        Rect.fromLTWH(w - 6 * _u, _u, _u, top), paint..color = bark);
    // The stick: outline with stepped ends, bark round a pale face.
    canvas.drawRect(
        Rect.fromLTWH(_u, top, w - 2 * _u, h - top), paint..color = _outline);
    canvas.drawRect(Rect.fromLTWH(0, top + _u, w, h - top - 2 * _u), paint);
    canvas.drawRect(Rect.fromLTWH(_u, top + _u, w - 2 * _u, h - top - 2 * _u),
        paint..color = bark);
    canvas.drawRect(
        Rect.fromLTWH(2 * _u, top + _u, w - 4 * _u, h - top - 3 * _u),
        paint..color = face);
    canvas.drawRect(Rect.fromLTWH(2 * _u, h - 2 * _u, w - 4 * _u, _u),
        paint..color = barkDark);
    // Rings on the ends.
    canvas.drawRect(Rect.fromLTWH(_u, top + 2 * _u, _u, h - top - 4 * _u),
        paint..color = barkDark);
    canvas.drawRect(
        Rect.fromLTWH(w - 2 * _u, top + 2 * _u, _u, h - top - 4 * _u), paint);
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

  /// 'A' the left half's red and 'L' its shine, 'B' the right half's red
  /// and 'b' its shade, so a heart can be half spent.
  static const List<String> _heartRows = [
    '.XX.XX.',
    'XLAXBBX',
    'XAAABbX',
    'XAAABbX',
    '.XAABX.',
    '..XAX..',
    '...X...',
  ];

  static const Color _red = AppTheme.retroPrimary;
  static const Color _spent = Color(0xFF4E4A4E);

  static const Map<String, Color> _fullHeart = {
    'X': _outline,
    'L': Color(0xFFF1A7AE),
    'A': _red,
    'B': _red,
    'b': Color(0xFFAC3232),
  };

  /// Left half full, right half spent.
  static const Map<String, Color> _halfHeart = {
    'X': _outline,
    'L': Color(0xFFF1A7AE),
    'A': _red,
    'B': _spent,
    'b': _spent,
  };

  static const Map<String, Color> _emptyHeart = {
    'X': _outline,
    'L': Color(0xFF6E6A6E),
    'A': _spent,
    'B': _spent,
    'b': _spent,
  };
}
