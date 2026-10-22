/// Each boss's own look for the pieces every round shares: the panels its
/// words and prompts go on, the bar its attack charges along, and the tiles
/// answers are written on.
///
/// Without these every boss drew the same parchment rectangles. A skin is a
/// palette lifted from the boss's sprite and a way of drawing each of the
/// three in it, on the 4px cell grid the rest of the arena is drawn on:
///
///   moss     Mossback: the owner's own sprite sheet (moss_ui_art.dart) —
///            mossy stone blocks, a groove with a vine creeping along it.
///   crystal  Amethyst: the owner's own sheet (crystal_ui_art.dart) — plum
///            stone framed in crystal, answers on cut gems, crystals growing
///            along a dark groove.
///   hex      Hoothex: the owner's own sheet (hex_ui_art.dart) — a parchment
///            scroll, answers on torn tags, a purple groove with a fuse
///            burning along it.
///   sea      Lanternmaw: the owner's own sheet (sea_ui_art.dart) — a slate
///            glass panel with bubbles on its rim, answers in glass pills,
///            water rising in a gauge.
///   sand     Sableth: the owner's own sheet (sand_ui_art.dart) — papyrus
///            hung between rods under headdress stripes, answers in
///            cartouches and cracked tablets, sand running into a gold groove.
///   fire     Pyrewing: the owner's own sprite sheet (fire_ui_art.dart) —
///            basalt panels with flames along them, answers on burnt scrolls,
///            runes on stone, gold coins, flames burning along a groove.
library;

import 'dart:math';

import 'package:flutter/material.dart';

import 'crystal_ui_art.dart';
import 'fire_ui_art.dart';
import 'hex_ui_art.dart';
import 'moss_ui_art.dart';
import 'pixel_sprite.dart';
import 'sand_ui_art.dart';
import 'sea_ui_art.dart';
import 'trial_particles.dart';

const double _u = 4;

/// Mossback's sheet is drawn two pixels a cell: its groove is seven cells
/// tall, which makes it exactly the charge bar's 14.
const double _mossCell = 2;

/// Pyrewing's sheet is drawn a point a cell: drawn on an 8px grid, its
/// answer scroll is then 41 points tall and its coin 47, for tiles of 46
/// and 48.
const double _fireCell = 1;

/// Lanternmaw's sheet is drawn a point a cell, like the others: its panel's
/// frame has to fit a 52-point prompt, and its pill is stretched from 35 rows.
const double _seaCell = 1;

/// Hoothex's sheet is drawn a point a cell throughout, too: its scroll's frame
/// has to fit a 52-point prompt, and its tag is stretched to 40 to 50 points
/// tall from 28 rows.
const double _hexCell = 1;

/// Amethyst's sheet is drawn a point a cell throughout: its panel's frame has
/// to fit a 52-point prompt, and its gem's ends are cut at forty-five degrees,
/// which at two points a cell slope in far enough to hide a word's first letter.
const double _crystalCell = 1;

/// Sableth's sheet is drawn a point a cell, like Pyrewing's, which is what its
/// panel needs: the frame is 15 cells at the top and 13 at the foot, and a
/// prompt is only 52 points tall. Its answer cartouche is drawn two, so it is
/// as tall as the 46-point tile it goes in rather than a thin strip of one.
const double _sandCell = 1;
const double _sandTileCell = 2;

/// A fire panel this tall or more is the big one, flames along its top;
/// anything shorter is the flame panel, whose flames stand off its frame
/// above and below, past its box.
const double _fireTallPanel = 70;

/// How far the big panel's flames reach up past its box: the talk panel
/// sits this far down from the top of the arena, and every point the
/// flames take inside the box comes off the words.
const int _fireTallOverhang = 8;

const Color _wrongFace = Color(0xFFF1A7A9);

/// A held coin's face: the gold lit up, so it stands out from the rest.
const Color _heldCoin = Color(0xFFF7E3AC);

enum TrialSkin { moss, crystal, hex, sea, sand, fire }

/// The skin of the boss being fought, for every piece drawn under it: the
/// shared prompt, charge bar and word stones take their look from here, so
/// every round is drawn in its boss's look without being told.
class TrialSkinScope extends InheritedWidget {
  const TrialSkinScope({super.key, required this.skin, required super.child});

  final TrialSkin skin;

  static TrialSkin? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TrialSkinScope>()?.skin;

  @override
  bool updateShouldNotify(TrialSkinScope old) => old.skin != skin;
}

/// A skin's colours.
class SkinColors {
  const SkinColors({
    required this.outline,
    required this.face,
    required this.ink,
    required this.rim,
    required this.rimLight,
    required this.rimDark,
    required this.accent,
    required this.accentLight,
    required this.label,
  });

  final Color outline;

  /// What words are written on, and in.
  final Color face;
  final Color ink;

  /// The frame, lit and shaded.
  final Color rim;
  final Color rimLight;
  final Color rimDark;

  /// What makes it the boss's: moss, crystal, wax, seafoam, stripes, flame.
  final Color accent;
  final Color accentLight;

  /// The small line over a prompt.
  final Color label;
}

extension TrialSkinLook on TrialSkin {
  SkinColors get colors => switch (this) {
        TrialSkin.moss => const SkinColors(
            outline: Color(0xFF11120D),
            face: Color(0xFFD9D3C2),
            ink: Color(0xFF2A1E14),
            rim: Color(0xFF989387),
            rimLight: Color(0xFFB4AE9F),
            rimDark: Color(0xFF4F504B),
            accent: Color(0xFF7E8A3E),
            accentLight: Color(0xFFA7B45A),
            label: Color(0xFF5F6A2C),
          ),
        // The sheet's plum stone and amethyst (crystal_ui_art.dart).
        TrialSkin.crystal => const SkinColors(
            outline: Color(0xFF11120E),
            face: Color(0xFFF2E5F6),
            ink: Color(0xFF2A1E14),
            rim: Color(0xFF8359A7),
            rimLight: Color(0xFFD4BAD8),
            rimDark: Color(0xFF6E4489),
            accent: Color(0xFFBF94D7),
            accentLight: Color(0xFFD4BAD8),
            label: Color(0xFF6E4489),
          ),
        // The sheet's parchment and the witch's purple (hex_ui_art.dart).
        TrialSkin.hex => const SkinColors(
            outline: Color(0xFF14120E),
            face: Color(0xFFF4DAB1),
            ink: Color(0xFF2A1E14),
            rim: Color(0xFFDEB27C),
            rimLight: Color(0xFFF5E5C9),
            rimDark: Color(0xFF885B38),
            accent: Color(0xFF895BB8),
            accentLight: Color(0xFFCCACED),
            label: Color(0xFF58307A),
          ),
        // The sheet's slate glass and seafoam (sea_ui_art.dart).
        TrialSkin.sea => const SkinColors(
            outline: Color(0xFF14120E),
            face: Color(0xFFBFD4D3),
            ink: Color(0xFF1D2B3A),
            rim: Color(0xFF456F7A),
            rimLight: Color(0xFFA4C3BE),
            rimDark: Color(0xFF233942),
            accent: Color(0xFF80A8A7),
            accentLight: Color(0xFFC9DDDB),
            label: Color(0xFF345763),
          ),
        // The sheet's papyrus, gold and headdress blue (sand_ui_art.dart).
        TrialSkin.sand => const SkinColors(
            outline: Color(0xFF14120E),
            face: Color(0xFFEBD3AC),
            ink: Color(0xFF2A1E14),
            rim: Color(0xFFD99F43),
            rimLight: Color(0xFFF3C756),
            rimDark: Color(0xFFA3692F),
            accent: Color(0xFF324963),
            accentLight: Color(0xFF82B1C4),
            label: Color(0xFF324963),
          ),
        // The sheet's basalt and fire (fire_ui_art.dart).
        TrialSkin.fire => const SkinColors(
            outline: Color(0xFF14120E),
            face: Color(0xFF463635),
            ink: Color(0xFFF7E3AC),
            rim: Color(0xFF553F3E),
            rimLight: Color(0xFF6A5150),
            rimDark: Color(0xFF322627),
            accent: Color(0xFFD25E2B),
            accentLight: Color(0xFFF2BD4E),
            label: Color(0xFFF2BD4E),
          ),
      };

  /// How far in from a panel's edge its words start, past its frame and
  /// whatever hangs off it.
  EdgeInsets get panelPadding => switch (this) {
        // Exactly the frame's thickness, and a cell more for what hangs off
        // it: a prompt is barely taller than its two lines, and every pixel
        // of padding comes off the words.
        TrialSkin.moss => const EdgeInsets.fromLTRB(12, 12, 12, 12),
        // The stone frame exactly, and a little air either side of the words.
        TrialSkin.crystal => crystalPanelFace * _crystalCell +
            const EdgeInsets.symmetric(horizontal: 3),
        // The scroll's parchment exactly, between its rollers.
        TrialSkin.hex => hexScrollFace * _hexCell +
            const EdgeInsets.symmetric(horizontal: 3),
        // The glass frame exactly, and a little air either side of the words.
        TrialSkin.sea => seaPanelFace * _seaCell +
            const EdgeInsets.symmetric(horizontal: 3),
        // The papyrus exactly, and a little air either side of the words.
        TrialSkin.sand =>
          sandPanelFace * _sandCell + const EdgeInsets.symmetric(horizontal: 4),
        TrialSkin.fire => const EdgeInsets.fromLTRB(14, 16, 14, 8),
      };

  /// The shape its answers are written on.
  TileShape get tile => switch (this) {
        TrialSkin.moss => TileShape.slab,
        TrialSkin.crystal => TileShape.gem,
        TrialSkin.hex => TileShape.tag,
        TrialSkin.sea => TileShape.pill,
        TrialSkin.sand => TileShape.cartouche,
        TrialSkin.fire => TileShape.scroll,
      };

  /// What its answer tiles are written on, which is not always its panel's
  /// face: Pyrewing's panels are obsidian, its scrolls are not.
  Color get tileFace => switch (this) {
        TrialSkin.fire => const Color(0xFFEBD6B3),
        _ => colors.face,
      };

  Color get tileInk => switch (this) {
        TrialSkin.fire => const Color(0xFF2A1E14),
        _ => colors.ink,
      };
}

/// Draws cells of [u] pixels from an origin, for the painters below.
class _Cells {
  _Cells(this.canvas, {this.x0 = 0, this.y0 = 0});

  final Canvas canvas;
  final double x0, y0;
  final Paint _paint = Paint()..isAntiAlias = false;

  void rect(int x, int y, int w, int h, Color c) {
    if (w <= 0 || h <= 0) return;
    canvas.drawRect(
      Rect.fromLTWH(x0 + x * _u, y0 + y * _u, w * _u, h * _u),
      _paint..color = c,
    );
  }
}

// ---- panels -----------------------------------------------------------------

/// A boss's panel: its frame, drawn behind [child].
class SkinPanel extends StatelessWidget {
  const SkinPanel({super.key, required this.skin, required this.child});

  final TrialSkin skin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (skin == TrialSkin.fire) {
      return LayoutBuilder(builder: (context, box) {
        final tall =
            !box.hasBoundedHeight || box.maxHeight >= _fireTallPanel;
        // The face exactly, and a little air either side of the words.
        final frame = tall
            ? firePanelFrame * _fireCell -
                const EdgeInsets.only(top: _fireTallOverhang * _fireCell)
            : fireFlamePanelFrame * _fireCell;
        final padding = frame + const EdgeInsets.symmetric(horizontal: 4);
        return CustomPaint(
          painter: _FirePanelPainter(tall: tall),
          child: Padding(padding: padding, child: child),
        );
      });
    }
    return CustomPaint(
      painter: _PanelPainter(skin),
      child: Padding(padding: skin.panelPadding, child: child),
    );
  }
}

/// Pyrewing's panels, from the owner's sheet: the big one, its flames
/// reaching up past its box, or the flame panel, its flames standing off
/// the top and bottom of its frame, past the box.
class _FirePanelPainter extends CustomPainter {
  const _FirePanelPainter({required this.tall});

  final bool tall;

  @override
  void paint(Canvas canvas, Size size) {
    final cols = (size.width / _fireCell).floor();
    final rows = (size.height / _fireCell).floor();
    final x = (size.width - cols * _fireCell) / 2;
    final y = (size.height - rows * _fireCell) / 2;
    if (tall) {
      const over = _fireTallOverhang;
      firePanel.paint(
          canvas, Offset(x, y - over * _fireCell), cols, rows + over,
          cellW: _fireCell, cellH: _fireCell);
      return;
    }
    const over = fireFlamePanelOverhang;
    fireFlamePanel.paint(
        canvas, Offset(x, y - over * _fireCell), cols, rows + 2 * over,
        cellW: _fireCell, cellH: _fireCell);
  }

  @override
  bool shouldRepaint(covariant _FirePanelPainter old) => old.tall != tall;
}

class _PanelPainter extends CustomPainter {
  const _PanelPainter(this.skin);

  final TrialSkin skin;

  @override
  void paint(Canvas canvas, Size size) {
    if (skin == TrialSkin.moss) {
      mossPanel.paintTiled(canvas, size, _mossCell);
      return;
    }
    if (skin == TrialSkin.sand) {
      // Whole stripes only: the lintel's gold and blue repeat every ten cells.
      sandPanel.paintTiled(canvas, size, _sandCell, wholeX: true);
      return;
    }
    if (skin == TrialSkin.crystal) {
      crystalPanel.paintTiled(canvas, size, _crystalCell);
      return;
    }
    if (skin == TrialSkin.hex) {
      hexScroll.paintTiled(canvas, size, _hexCell);
      return;
    }
    if (skin == TrialSkin.sea) {
      seaPanel.paintTiled(canvas, size, _seaCell);
      return;
    }
    final c = skin.colors;
    final cols = (size.width / _u).floor();
    final rows = (size.height / _u).floor();
    final x0 = ((size.width - cols * _u) / 2).roundToDouble();
    final y0 = ((size.height - rows * _u) / 2).roundToDouble();
    final g = _Cells(canvas, x0: x0, y0: y0);
    if (cols < 8 || rows < 6) return;

    // The body of the panel: inset where something hangs off its edge.
    final top = switch (skin) {
      TrialSkin.fire => 2,
      _ => 0,
    };
    final bottom = rows;
    const side = 0;
    final w = cols - 2 * side;
    final h = bottom - top;
    const round = 1;

    // Outline, rim, face — each a rectangle with its corners stepped in.
    void box(int inset, Color color) {
      for (var y = 0; y < h - 2 * inset; y++) {
        final fromEnd = min(y, h - 2 * inset - 1 - y);
        final cut = fromEnd < round ? round - fromEnd : 0;
        g.rect(side + inset + cut, top + inset + y, w - 2 * inset - 2 * cut, 1,
            color);
      }
    }

    box(0, c.outline);
    box(1, c.rim);
    // A lit top edge and a shaded bottom one on the rim.
    g.rect(side + 2, top + 1, w - 4, 1, c.rimLight);
    g.rect(side + 2, top + h - 2, w - 4, 1, c.rimDark);
    box(2, c.face);

    switch (skin) {
      case TrialSkin.moss:
        break;
      case TrialSkin.crystal:
        break;
      case TrialSkin.hex:
        break;
      case TrialSkin.sea:
        break;
      case TrialSkin.sand:
        break;
      case TrialSkin.fire:
        // Flames licking up over the top edge, and embers in the cracks.
        for (var x = 2; x < cols - 3; x += 5) {
          final tall = 1 + (x ~/ 5) % 2;
          g.rect(x, 2 - tall, 2, tall, c.accent);
          g.rect(x, 2 - tall, 1, 1, c.accentLight);
          g.rect(x + 2, 1, 1, 1, c.accent);
        }
        for (var x = 7; x < cols - 7; x += 11) {
          g.rect(x, rows - 2, 2, 1, c.accent);
          g.rect(x + 1, rows - 3, 1, 1, c.accentLight);
        }
    }
  }

  @override
  bool shouldRepaint(covariant _PanelPainter old) => old.skin != skin;
}

/// A prompt on a boss's panel: a small line saying what to do, and the words
/// themselves.
class SkinPrompt extends StatelessWidget {
  const SkinPrompt({
    super.key,
    required this.skin,
    required this.label,
    required this.text,
    required this.labelStyle,
    required this.textStyle,
    this.maxLines = 1,
  });

  final TrialSkin skin;
  final String label;
  final String text;
  final TextStyle labelStyle;
  final TextStyle textStyle;

  /// One line for a meaning; more for a boss's words, wrapped at the panel's
  /// width and shrunk whole if they will not fit.
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final c = skin.colors;
    return SkinPanel(
      skin: skin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (label.isNotEmpty) ...[
            Text(label, style: labelStyle.copyWith(color: c.label)),
            const SizedBox(height: 3),
          ],
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: maxLines == 1
                  ? Text(text,
                      maxLines: 1, style: textStyle.copyWith(color: c.ink))
                  : ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 330),
                      child:
                          Text(text, style: textStyle.copyWith(color: c.ink)),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- timers -----------------------------------------------------------------

/// A boss's attack charging, in its own look: [value] 0 is nothing yet, 1 is
/// the attack landing.
class SkinBar extends StatelessWidget {
  const SkinBar({super.key, required this.skin, required this.value});

  final TrialSkin skin;
  final double value;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _BarPainter(skin, value));
}

class _BarPainter extends CustomPainter {
  const _BarPainter(this.skin, this.value);

  final TrialSkin skin;
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    if (skin == TrialSkin.moss) {
      _paintVine(canvas, size);
      return;
    }
    if (skin == TrialSkin.fire) {
      _paintFire(canvas, size);
      return;
    }
    if (skin == TrialSkin.sand) {
      _paintSand(canvas, size);
      return;
    }
    if (skin == TrialSkin.crystal) {
      _paintCrystal(canvas, size);
      return;
    }
    if (skin == TrialSkin.hex) {
      _paintHex(canvas, size);
      return;
    }
    if (skin == TrialSkin.sea) {
      _paintSea(canvas, size);
      return;
    }
    final c = skin.colors;
    final cols = (size.width / _u).floor();
    final rows = max(3, (size.height / _u).floor());
    final g = _Cells(canvas,
        x0: ((size.width - cols * _u) / 2).roundToDouble(),
        y0: ((size.height - rows * _u) / 2).roundToDouble());
    // In twentieths, so it fills in visible steps like everything else.
    final stepped = (value.clamp(0.0, 1.0) * 20).floor() / 20;
    final inner = cols - 2;
    final fill = (inner * stepped).round();
    final mid = rows ~/ 2;

    g.rect(0, 0, cols, rows, c.outline);
    g.rect(1, 1, inner, rows - 2, const Color(0xFF0B0B10));

    switch (skin) {
      case TrialSkin.moss:
        break;
      case TrialSkin.crystal:
        break;
      case TrialSkin.hex:
        break;
      case TrialSkin.sea:
        break;
      case TrialSkin.sand:
        break;
      case TrialSkin.fire:
        // Fire: embers along the bottom, flame tips flickering over them.
        g.rect(1, mid, fill, rows - 1 - mid, c.accent);
        for (var x = 1; x < fill; x++) {
          final tip = (x * 5 + (stepped * 20).floor()) % 3;
          g.rect(x, max(1, mid - tip), 1, tip, c.accentLight);
        }
    }
  }

  /// Mossback's: a vine creeping along the groove in its stone, a sprout
  /// every eight cells.
  void _paintVine(Canvas canvas, Size size) {
    final cell = min(_mossCell, size.height / mossGroove.height);
    final cols = (size.width / cell).floor();
    final origin = Offset((size.width - cols * cell) / 2,
        (size.height - mossGroove.height * cell) / 2);
    mossGroove.paint(canvas, origin, cols, mossGroove.height,
        cellW: cell, cellH: cell);
    // The groove runs between its end caps: four cells in from either end.
    const inset = 4;
    final stepped = (value.clamp(0.0, 1.0) * 20).floor() / 20;
    final fill = ((cols - 2 * inset) * stepped).round();
    mossVine.paint(canvas, origin + Offset(inset * cell, 0), fill,
        mossVine.height,
        cellW: cell, cellH: cell);
  }

  /// Sableth's: sand running into a gold groove.
  void _paintSand(Canvas canvas, Size size) => _paintGroove(
        canvas,
        size,
        sandGroove,
        sandFill,
        _sandCell,
        top: sandChannelTop,
        bottom: sandChannelBottom,
        side: sandChannelSide,
      );

  /// Amethyst's: crystal growing along a dark groove with a crystal at each
  /// end.
  void _paintCrystal(Canvas canvas, Size size) => _paintGroove(
        canvas,
        size,
        crystalGroove,
        crystalFill,
        _crystalCell,
        top: crystalChannelTop,
        bottom: crystalChannelBottom,
        side: crystalChannelSide,
      );

  /// Lanternmaw's: water rising along a glass gauge with a cap at each end. Its
  /// channel is seven rows of deep water under a line of reflection, and the
  /// water fills five of them, so the gauge is drawn as tall as the sheet draws
  /// it, 16 points, and overlaps a 12-point bar by two points a side.
  void _paintSea(Canvas canvas, Size size) {
    const cell = _seaCell;
    final cols = (size.width / cell).floor();
    final origin = Offset(
        ((size.width - cols * cell) / 2).roundToDouble(),
        ((size.height - seaGroove.height * cell) / 2).roundToDouble());
    seaGroove.paint(canvas, origin, cols, seaGroove.height,
        cellW: cell, cellH: cell);
    // In twentieths, so it fills in visible steps like everything else.
    final stepped = (value.clamp(0.0, 1.0) * 20).floor() / 20;
    final fill = ((cols - 2 * seaChannelSide) * stepped).round();
    if (fill < 1) return;
    seaWater.paint(
      canvas,
      origin + const Offset(seaChannelSide * cell, seaChannelTop * cell),
      fill,
      seaGroove.height - seaChannelTop - seaChannelBottom,
      cellW: cell,
      cellH: cell,
    );
  }

  /// Hoothex's: a fuse burning along a purple groove, from the left. Ash lies
  /// behind the flame and rope ahead of it. The groove is drawn as tall as the
  /// sheet draws it, 16 points, because its channel is only six cells deep and
  /// the rope needs four; a 12-point bar is overlapped by two points a side.
  void _paintHex(Canvas canvas, Size size) {
    const cell = _hexCell;
    final cols = (size.width / cell).floor();
    final origin = Offset(
        ((size.width - cols * cell) / 2).roundToDouble(),
        ((size.height - hexGroove.height * cell) / 2).roundToDouble());
    hexGroove.paint(canvas, origin, cols, hexGroove.height,
        cellW: cell, cellH: cell);
    final length = cols - 2 * hexChannelSide;
    // In twentieths, so it burns in visible steps like everything else.
    final step = (value.clamp(0.0, 1.0) * 20).floor();
    final burned = (length * step / 20).round();
    final rows = hexGroove.height - hexChannelTop - hexChannelBottom;
    final fuse = origin + const Offset(hexChannelSide * cell, hexChannelTop * cell);
    if (burned > 0) {
      hexAsh.paint(canvas, fuse, burned, rows, cellW: cell, cellH: cell);
    }
    if (burned >= length) return;
    hexRope.paint(canvas, fuse + Offset(burned * cell, 0), length - burned, rows,
        cellW: cell, cellH: cell);
    // The flame at the burning end, flickering a point up and down.
    hexSpark.paint(
      canvas,
      origin +
          Offset((hexChannelSide + burned - hexSpark.width / 2) * cell,
              (hexGroove.height - hexSpark.height) / 2 * cell - (step.isEven ? 0 : cell)),
      hexSpark.width,
      hexSpark.height,
      cellW: cell,
      cellH: cell,
    );
  }

  /// A sheet's groove with its fill laid along the channel. The groove is as
  /// tall as the sheet draws it, but its rim is the same thickness whatever
  /// the height, so it takes the bar's own height (a bar is 12 or 14 points)
  /// and the fill takes what is left of the channel: [top] and [bottom] are
  /// the rows of rim above and below it, [side] the columns in from either
  /// end.
  void _paintGroove(
    Canvas canvas,
    Size size,
    PixelSprite groove,
    PixelSprite fillSprite,
    double cell, {
    required int top,
    required int bottom,
    required int side,
  }) {
    final cols = (size.width / cell).floor();
    final rows = min((size.height / cell).floor(), groove.height);
    final origin = Offset(((size.width - cols * cell) / 2).roundToDouble(),
        ((size.height - rows * cell) / 2).roundToDouble());
    groove.paint(canvas, origin, cols, rows, cellW: cell, cellH: cell);
    final fillRows = rows - top - bottom;
    // In twentieths, so it fills in visible steps like everything else.
    final stepped = (value.clamp(0.0, 1.0) * 20).floor() / 20;
    final fill = ((cols - 2 * side) * stepped).round();
    if (fillRows < 1 || fill < 1) return;
    fillSprite.paint(
      canvas,
      origin + Offset(side * cell, top * cell),
      fill,
      fillRows,
      cellW: cell,
      cellH: cell,
    );
  }

  /// Pyrewing's: flames catching one by one along a basalt groove, as the
  /// sheet lays them out, the groove as tall as it is drawn and centred on
  /// the bar.
  void _paintFire(Canvas canvas, Size size) {
    const cell = _fireCell;
    final cols = (size.width / cell).floor();
    final origin = Offset(((size.width - cols * cell) / 2).roundToDouble(),
        ((size.height - fireGroove.height * cell) / 2).roundToDouble());
    fireGroove.paint(canvas, origin, cols, fireGroove.height,
        cellW: cell, cellH: cell);
    // Whole flames only, as many as the channel holds, the row of them
    // centred in it.
    final channel = cols - 2 * fireChannelInset;
    final room = channel ~/ fireFlame.width;
    final lit = (value.clamp(0.0, 1.0) * room).floor();
    final x0 = fireChannelInset + (channel - room * fireFlame.width) ~/ 2;
    for (var i = 0; i < lit; i++) {
      fireFlame.paint(
        canvas,
        origin +
            Offset((x0 + i * fireFlame.width) * cell, fireFlameTop * cell),
        fireFlame.width,
        fireFlame.height,
        cellW: cell,
        cellH: cell,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.skin != skin || old.value != value;
}

// ---- tiles ------------------------------------------------------------------

/// The shape an answer is written on.
enum TileShape {
  /// Mossback's stone slab.
  slab,

  /// Amethyst's cut gem: corners cut back, a lit facet.
  gem,

  /// Hoothex's parchment tag, a corner folded over.
  tag,

  /// Lanternmaw's rounded glass.
  pill,

  /// Sableth's cartouche: rounded ends, a double rim, the tie at its end.
  cartouche,

  /// Sableth's stone tablet, round at the top.
  tablet,

  /// Pyrewing's charred scroll, its edges burnt ragged.
  scroll,

  /// Pyrewing's gold coin.
  coin,

  /// Pyrewing's rune stone: an arch stepped up to a flat top.
  rune,
}

extension TileShapePadding on TileShape {
  /// How far in from its edges words go: clear of a cartouche's tie, a
  /// tablet's rounded top, a coin's rim.
  EdgeInsets get padding => switch (this) {
        // The sheet's faces: inside a gem's bevel, clear of a cartouche's tie,
        // inside a tablet's inner line.
        TileShape.gem =>
          crystalGemFace * _crystalCell + const EdgeInsets.symmetric(horizontal: 2),
        TileShape.cartouche =>
          sandTileFace * _sandTileCell + const EdgeInsets.symmetric(horizontal: 2),
        TileShape.tablet =>
          sandTabletFace * _sandCell + const EdgeInsets.symmetric(horizontal: 2),
        TileShape.coin =>
          const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        // Under its arch, between its sides.
        TileShape.rune => const EdgeInsets.fromLTRB(18, 16, 18, 8),
        // Clear of the ragged burnt edge at its ends.
        TileShape.scroll => const EdgeInsets.fromLTRB(18, 6, 18, 6),
        TileShape.tag =>
          hexTagFace * _hexCell + const EdgeInsets.symmetric(horizontal: 3),
        // In from a glass pill's rounded ends.
        TileShape.pill =>
          seaPillFace * _seaCell + const EdgeInsets.symmetric(horizontal: 2),
        _ => const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      };
}

/// How a tile is showing.
enum TileState { plain, flashing, wrong, right, held, spent }

/// An answer in a boss's look: [shape] drawn in [skin]'s colours, with its
/// words on it.
class SkinTile extends StatelessWidget {
  const SkinTile({
    super.key,
    required this.skin,
    required this.label,
    required this.style,
    required this.onTapDown,
    this.shape,
    this.state = TileState.plain,
    this.badge,
  });

  final TrialSkin skin;
  final String label;
  final TextStyle style;
  final VoidCallback? onTapDown;

  /// Its shape, when not the skin's own: a tablet, a coin.
  final TileShape? shape;
  final TileState state;

  /// A number carved in its corner: its place in an order.
  final String? badge;

  bool get _tappable =>
      onTapDown != null &&
      (state == TileState.plain ||
          state == TileState.flashing ||
          state == TileState.held);

  @override
  Widget build(BuildContext context) {
    final s = shape ?? skin.tile;
    final faded = state == TileState.wrong || state == TileState.spent;
    final ink = state == TileState.flashing || state == TileState.right
        ? const Color(0xFF2A1E14)
        : s == TileShape.coin
            ? const Color(0xFF2A1E14)
            : skin.tileInk;
    final pad = s.padding;
    return Semantics(
      button: _tappable,
      label: label,
      child: Visibility(
        // A spent tile leaves its place empty, so nothing moves under the
        // player's finger.
        visible: state != TileState.spent,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: Opacity(
          opacity: faded ? 0.45 : 1,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _tappable ? (_) => onTapDown!() : null,
            child: CustomPaint(
              painter: SkinTilePainter(skin, s, state),
              child: Padding(
                padding: pad,
                child: Row(
                  children: [
                    if (badge case final badge?) ...[
                      Text(badge,
                          style: style.copyWith(color: skin.colors.rimDark)),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label,
                            maxLines: 1,
                            style: style.copyWith(
                              color: ink,
                              decoration: state == TileState.wrong
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: ink,
                              decorationThickness: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A tile's shape in a skin, for pieces that draw their own: the word
/// stones of the Spells round.
class SkinTilePainter extends CustomPainter {
  const SkinTilePainter(this.skin, this.shape, this.state);

  final TrialSkin skin;
  final TileShape shape;
  final TileState state;

  @override
  void paint(Canvas canvas, Size size) {
    final c = skin.colors;
    if (skin == TrialSkin.fire) {
      _paintFire(canvas, size);
      return;
    }
    if (skin == TrialSkin.sand) {
      _paintSand(canvas, size);
      return;
    }
    if (skin == TrialSkin.crystal) {
      _paintCrystal(canvas, size);
      return;
    }
    if (skin == TrialSkin.hex) {
      _paintHex(canvas, size);
      return;
    }
    if (skin == TrialSkin.sea) {
      _paintSea(canvas, size);
      return;
    }
    if (skin == TrialSkin.moss && shape == TileShape.slab) {
      mossTile.paintTiled(canvas, size, _mossCell, face: switch (state) {
        TileState.flashing => _wrongFace,
        TileState.right => DebrisPalette.runeLight,
        TileState.held => c.accentLight,
        _ => null,
      });
      return;
    }
    final cols = (size.width / _u).floor();
    final rows = (size.height / _u).floor();
    if (cols < 6 || rows < 4) return;
    final g = _Cells(canvas,
        x0: ((size.width - cols * _u) / 2).roundToDouble(),
        y0: ((size.height - rows * _u) / 2).roundToDouble());
    final face = switch (state) {
      TileState.flashing => _wrongFace,
      TileState.right => DebrisPalette.runeLight,
      TileState.held => c.accentLight,
      _ => shape == TileShape.coin
          ? const Color(0xFFF3BD60)
          : shape == TileShape.tablet
              ? const Color(0xFFE6D2A8)
              : skin.tileFace,
    };
    final rim = shape == TileShape.coin ? const Color(0xFFB8863A) : c.rim;
    final rimLight =
        shape == TileShape.coin ? const Color(0xFFF7E3AC) : c.rimLight;

    /// Each row's cut from the ends: how many cells in the shape starts on
    /// the left and right of row [y].
    (int, int) cut(int y) {
      final fromTop = y, fromBottom = rows - 1 - y;
      final edge = min(fromTop, fromBottom);
      switch (shape) {
        case TileShape.slab:
        case TileShape.tag:
        case TileShape.scroll:
          final n = edge == 0 ? 1 : 0;
          return (n, n);
        case TileShape.gem:
          final n = max(0, 2 - edge);
          return (n, n);
        case TileShape.pill:
        case TileShape.cartouche:
        case TileShape.coin:
          // Round ends: a half circle the tile's height across.
          final r = rows / 2;
          final dy = (y + 0.5 - r).abs();
          final n = (r - sqrt(max(0.0, r * r - dy * dy))).round();
          return shape == TileShape.coin ? (n, n) : (n, n);
        case TileShape.tablet:
        case TileShape.rune:
          // Round at the top only.
          final r = min(rows / 2, cols / 4);
          if (y >= r) return (0, 0);
          final dy = r - y - 0.5;
          final n = (r - sqrt(max(0.0, r * r - dy * dy))).round();
          return (n, n);
      }
    }

    void fill(int inset, Color color) {
      for (var y = inset; y < rows - inset; y++) {
        var (l, r) = cut(y);
        if (shape == TileShape.scroll) {
          // Burnt ragged: the ends eaten away every other row.
          l += (y % 2) * (inset == 0 ? 1 : 0);
          r += ((y + 1) % 2) * (inset == 0 ? 1 : 0);
        }
        g.rect(l + inset, y, cols - l - r - 2 * inset, 1, color);
      }
    }

    fill(0, c.outline);
    fill(1, rim);
    // Lit along the top.
    final (tl, tr) = cut(1);
    g.rect(tl + 2, 1, cols - tl - tr - 4, 1, rimLight);
    fill(2, face);

    switch (shape) {
      case TileShape.slab:
        g.rect(2, rows - 2, cols - 4, 1, c.rimDark);
      case TileShape.gem:
        // A lit facet at top left.
        g.rect(3, 2, 2, 1, c.accentLight);
        g.rect(2, 3, 1, 1, c.accentLight);
      case TileShape.tag:
        // A corner folded over, top right.
        g.rect(cols - 4, 1, 3, 3, c.rimDark);
        g.rect(cols - 4, 1, 1, 3, c.outline);
        g.rect(cols - 4, 3, 3, 1, c.outline);
      case TileShape.pill:
        g.rect(3, 2, 2, 1, c.accentLight);
      case TileShape.cartouche:
        // The tie across its right end, and a second rim inside the first.
        g.rect(cols - 4, 1, 1, rows - 2, c.outline);
        g.rect(cols - 3, 2, 1, rows - 4, c.rimDark);
        g.rect(4, 3, cols - 10, 1, c.rimLight);
        g.rect(4, rows - 4, cols - 10, 1, c.rimLight);
      case TileShape.tablet:
      case TileShape.rune:
        // A crack down from the top, and chipped corners at the foot.
        final x = cols * 2 ~/ 3;
        g.rect(x, 2, 1, 2, c.rimDark);
        g.rect(x + 1, 4, 1, 1, c.rimDark);
      case TileShape.scroll:
        // Embers still glowing on its burnt corners.
        g.rect(1, 1, 1, 1, c.accent);
        g.rect(cols - 2, rows - 2, 1, 1, c.accent);
        g.rect(cols - 3, 1, 1, 1, c.accentLight);
      case TileShape.coin:
        // A glint on the gold, and a rim stamped round it.
        g.rect(cols ~/ 2 - 3, 2, 2, 1, rimLight);
        g.rect(cols ~/ 2 - 4, 3, 1, 1, rimLight);
    }
  }

  /// Lanternmaw's, from the owner's sheet: its glass pill, round at both ends,
  /// its middle repeating to the tile's width and its height.
  void _paintSea(Canvas canvas, Size size) {
    final face = switch (state) {
      TileState.flashing => _wrongFace,
      TileState.right => DebrisPalette.runeLight,
      TileState.held => skin.colors.accentLight,
      _ => null,
    };
    seaPill.paintTiled(canvas, size, _seaCell, face: face);
  }

  /// Hoothex's, from the owner's sheet: its torn tag, its middle repeating to
  /// the tile's width and its height, with the folded corner kept to the
  /// top right.
  void _paintHex(Canvas canvas, Size size) {
    final face = switch (state) {
      TileState.flashing => _wrongFace,
      TileState.right => DebrisPalette.runeLight,
      TileState.held => skin.colors.accentLight,
      _ => null,
    };
    hexTag.paintTiled(canvas, size, _hexCell, face: face);
  }

  /// Amethyst's, from the owner's sheet: its cut gem, drawn two points a cell
  /// so it is as tall as the tile, its middle repeating to the tile's width.
  void _paintCrystal(Canvas canvas, Size size) {
    final face = switch (state) {
      TileState.flashing => _wrongFace,
      TileState.right => DebrisPalette.runeLight,
      TileState.held => skin.colors.accentLight,
      _ => null,
    };
    crystalGem.paintTiled(canvas, size, _crystalCell, face: face);
  }

  /// Sableth's, from the owner's sheet: its cartouche, drawn two points a
  /// cell so it is as tall as the tile, or its cracked tablet, one; the
  /// middle of either repeats to the tile's width and is cut or repeated to
  /// its height, so the tablet's cracks stay in its corners.
  void _paintSand(Canvas canvas, Size size) {
    final tablet = shape == TileShape.tablet;
    final face = switch (state) {
      TileState.flashing => _wrongFace,
      TileState.right => DebrisPalette.runeLight,
      TileState.held => skin.colors.accentLight,
      _ => null,
    };
    (tablet ? sandTablet : sandTile).paintTiled(
        canvas, size, tablet ? _sandCell : _sandTileCell,
        face: face);
  }

  /// Pyrewing's, from the owner's sheet: its burnt scroll, its rune stone
  /// or a gold coin, as tall as drawn and centred, its middle stretched to
  /// the tile's width; squeezed in its middle when the tile is shorter.
  void _paintFire(Canvas canvas, Size size) {
    final sprite = switch (shape) {
      TileShape.coin => fireCoin,
      TileShape.rune || TileShape.tablet => fireRune,
      _ => fireScroll,
    };
    final face = switch (state) {
      TileState.flashing => _wrongFace,
      TileState.right => DebrisPalette.runeLight,
      TileState.held =>
        sprite == fireCoin ? _heldCoin : skin.colors.accentLight,
      _ => null,
    };
    final cols = (size.width / _fireCell).floor();
    final rows = min((size.height / _fireCell).floor(), sprite.height);
    sprite.paint(
      canvas,
      Offset((size.width - cols * _fireCell) / 2,
          (size.height - rows * _fireCell) / 2),
      cols,
      rows,
      cellW: _fireCell,
      cellH: _fireCell,
      face: face,
    );
  }

  @override
  bool shouldRepaint(covariant SkinTilePainter old) =>
      old.skin != skin || old.shape != shape || old.state != state;
}
