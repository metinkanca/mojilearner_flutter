/// What every toy chest game shares around its own scene: the bar across the
/// top, the row of squares that keeps score, the results card, the word bubble,
/// the answer tiles, and the small pixel pieces a game reacts with.
///
/// Lifted from Catch, the first of them, so five games look like one set and
/// a change to how a game ends is made once. Drawn in the cozy room's flat
/// colours ([PlayPalette]) on whole cells, like the toy chest's own picker.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../utils/fonts.dart';
import '../../utils/play_games.dart';
import '../boss_trial/pixel_sprite.dart' show PixelSprite;
import '../pet_hearts.dart' show PixelHeartPainter;
import 'toy_chest_art.dart';

/// The colours of the toy chest and its games: the cozy room's, with its ink.
class PlayPalette {
  static const Color ink = Color(0xFF14120E);
  static const Color wall = Color(0xFFF2E3C6);
  static const Color wood = Color(0xFFC58C56);
  static const Color glass = Color(0xFFA8DCEF);
  static const Color coral = Color(0xFFE98A7B);
  static const Color gold = Color(0xFFF0C24C);
  static const Color stone = Color(0xFFCDC3D9);
  static const Color leaf = Color(0xFF8CC56A);

  /// One cell of the art, in logical pixels: about the pets' own.
  static const double cell = 3;
}

/// The pixel face of a [PlaySquareButton]: an X, a triangle pointing on (play
/// again), or the same pointing back.
enum PlayIcon { close, play, back }

/// The pixel font the games are drawn in, at [size], in [color] — with the
/// locale's own glyphs when [localeCode] is given, since a word in Japanese
/// drawn in the Latin face is a row of boxes.
TextStyle playPixel(double size, Color color, {String? localeCode}) =>
    AppFonts.pressStart2p(
      fontSize: size,
      color: color,
      locale: localeCode == null ? null : Locale(localeCode),
    );

/// A square pixel button carrying an icon, with a label for screen readers.
class PlaySquareButton extends StatelessWidget {
  const PlaySquareButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.size,
    required this.onTap,
  });

  final PlayIcon icon;
  final String label;
  final Color color;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rows = switch (icon) {
      PlayIcon.close => iconCloseArtRows,
      PlayIcon.play || PlayIcon.back => iconPlayArtRows,
    };
    final inks = switch (icon) {
      PlayIcon.close => iconCloseArtInks,
      PlayIcon.play || PlayIcon.back => iconPlayArtInks,
    };
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: PixelPanel(
            color: color,
            child: Center(
              child: SizedBox(
                width: rows.first.length * PlayPalette.cell,
                height: rows.length * PlayPalette.cell,
                child: CustomPaint(
                  painter: PixelPatternPainter(rows, inks,
                      mirrored: icon == PlayIcon.back),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of squares, one per round: right, not right, or still to come, with
/// the round in play in gold.
class PlayResultTrack extends StatelessWidget {
  const PlayResultTrack({
    super.key,
    required this.results,
    required this.total,
    required this.current,
  });

  /// Every round played so far: true for right.
  final List<bool> results;
  final int total;

  /// The round in play, or null once the game is over.
  final int? current;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          for (var i = 0; i < total; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  decoration: BoxDecoration(
                    color: i < results.length
                        ? (results[i] ? PlayPalette.leaf : PlayPalette.coral)
                        : i == current
                            ? PlayPalette.gold
                            : PlayPalette.wall,
                    border: Border.all(color: PlayPalette.ink, width: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The bar over a game: close, the score so far, and the streak.
class PlayHud extends StatelessWidget {
  const PlayHud({
    super.key,
    required this.results,
    required this.total,
    required this.current,
    required this.combo,
    required this.onClose,
  });

  final List<bool> results;
  final int total;
  final int? current;
  final int combo;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: PlayPalette.wood,
        border: Border(bottom: BorderSide(color: PlayPalette.ink, width: 3)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: Row(
        children: [
          PlaySquareButton(
            icon: PlayIcon.close,
            label: MaterialLocalizations.of(context).closeButtonTooltip,
            color: PlayPalette.coral,
            size: 36,
            onTap: onClose,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PlayResultTrack(
              results: results,
              total: total,
              current: current,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: Text(
              combo > 1 ? 'x$combo' : '',
              textAlign: TextAlign.end,
              textDirection: TextDirection.ltr,
              style: playPixel(10, PlayPalette.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// The word a pet calls out, in a cream bubble with its tail pointing down at
/// the pet. The bubble is [tailH] shorter than the box it is given; the tail
/// takes the rest, [tailX] in from the left.
class PlayBubble extends StatelessWidget {
  const PlayBubble({
    super.key,
    required this.word,
    required this.style,
    required this.tailX,
  });

  final String word;
  final TextStyle style;
  final double tailX;

  /// How far the tail hangs below the bubble's border.
  static const double tailH = 4 * PlayPalette.cell;

  static double get _tailW => bubbleTailArtRows.first.length * PlayPalette.cell;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          bottom: tailH,
          child: PixelPanel(
            color: PlayPalette.wall,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(word, maxLines: 1, style: style),
              ),
            ),
          ),
        ),
        // Its top row is the bubble's border, opened by the tail's cream.
        Positioned(
          left: (tailX - _tailW / 2).roundToDouble(),
          bottom: 0,
          width: _tailW,
          height: bubbleTailArtRows.length * PlayPalette.cell,
          child: const CustomPaint(
            painter: PixelPatternPainter(bubbleTailArtRows, bubbleTailArtInks),
          ),
        ),
      ],
    );
  }
}

/// An answer to pick: a panel with a word on it, its face changing colour as
/// the throw is answered.
class PlayTile extends StatelessWidget {
  const PlayTile({
    super.key,
    required this.label,
    required this.style,
    required this.face,
    required this.onTapDown,
  });

  final String label;
  final TextStyle style;
  final Color face;
  final VoidCallback onTapDown;

  /// The face of a tile still open to be picked.
  static const Color open = PlayPalette.wall;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        // On the press, not the release: a tap that lands a frame before the
        // ball does should count.
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => onTapDown(),
        child: PixelPanel(
          color: face,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, maxLines: 1, style: style),
            ),
          ),
        ),
      ),
    );
  }
}

/// A bubble with a letter on it, rising off the bath: a glass disc of 17 cells,
/// coral for a moment when the letter was the wrong one.
class PlayLetterBubble extends StatelessWidget {
  const PlayLetterBubble({
    super.key,
    required this.label,
    required this.style,
    required this.onTapDown,
    this.flashing = false,
  });

  final String label;
  final TextStyle style;
  final VoidCallback? onTapDown;

  /// Just refused: the bubble flashes coral.
  final bool flashing;

  @override
  Widget build(BuildContext context) {
    final rows = flashing ? bathBubbleWrongArtRows : bathBubbleArtRows;
    final inks = flashing ? bathBubbleWrongArtInks : bathBubbleArtInks;
    return Semantics(
      button: onTapDown != null,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: onTapDown == null ? null : (_) => onTapDown!(),
        child: Center(
          child: SizedBox(
            width: rows.first.length * PlayPalette.cell,
            height: rows.length * PlayPalette.cell,
            child: CustomPaint(
              painter: PixelPatternPainter(rows, inks),
              child: Padding(
                padding: const EdgeInsets.all(9),
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
      ),
    );
  }
}

/// A word being spelled: a cream plaque with a socket for each letter, stone
/// while empty and glass once filled, all leaf green the moment it is spelled.
class PlaySpellLine extends StatelessWidget {
  const PlaySpellLine({
    super.key,
    required this.slots,
    required this.filled,
    required this.style,
    this.glow = false,
    this.textDirection = TextDirection.ltr,
  });

  final int slots;
  final List<String> filled;
  final TextStyle style;

  /// The whole line lit, the moment the word is complete.
  final bool glow;

  /// The order sockets fill in: right to left for Arabic.
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    return PixelPanel(
      color: PlayPalette.wall,
      cell: 2,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Directionality(
          textDirection: textDirection,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < slots; i++)
                Container(
                  height: 30,
                  constraints: const BoxConstraints(minWidth: 36),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i < filled.length
                        ? (glow ? PlayPalette.leaf : PlayPalette.glass)
                        : PlayPalette.stone,
                    border: Border.all(color: PlayPalette.ink, width: 2),
                  ),
                  child: Text(
                    i < filled.length ? filled[i] : '',
                    maxLines: 1,
                    style: style,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The card a game ends on: the score, its squares, what it paid, what is
/// worth practising, and the way to play again or leave.
///
/// Almost wordless, like the games: a number, a row of squares, a heart and
/// the app's own "XP" say how it went in every language the app ships.
class PlayResultsPanel extends StatelessWidget {
  const PlayResultsPanel({
    super.key,
    required this.results,
    required this.total,
    required this.happiness,
    required this.xp,
    required this.xpLabel,
    required this.toPractise,
    required this.targetCode,
    required this.nativeCode,
    required this.againLabel,
    required this.onAgain,
    required this.onClose,
  });

  final List<bool> results;
  final int total;

  /// What the game added to the pet's happiness, and to the player's XP.
  final int happiness;
  final int xp;
  final String xpLabel;

  final List<PlayPractice> toPractise;
  final String? targetCode;
  final String? nativeCode;
  final String againLabel;
  final VoidCallback onAgain;
  final VoidCallback onClose;

  static const Color _ink = PlayPalette.ink;

  @override
  Widget build(BuildContext context) {
    final right = results.where((r) => r).length;
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: PixelPanel(
          color: PlayPalette.wall,
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '$right/${results.length}',
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: playPixel(28, _ink),
                ),
                const SizedBox(height: 14),
                PlayResultTrack(
                  results: results,
                  total: total,
                  current: null,
                ),
                if (happiness > 0 || xp > 0) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 20,
                    runSpacing: 8,
                    textDirection: TextDirection.ltr,
                    children: [
                      if (happiness > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          textDirection: TextDirection.ltr,
                          children: [
                            const SizedBox(
                              width: 22,
                              height: 20,
                              child: CustomPaint(painter: PixelHeartPainter()),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+$happiness',
                              textDirection: TextDirection.ltr,
                              style: playPixel(14, _ink),
                            ),
                          ],
                        ),
                      if (xp > 0)
                        Text(
                          '+$xp $xpLabel',
                          textDirection: TextDirection.ltr,
                          style: playPixel(14, _ink),
                        ),
                    ],
                  ),
                ],
                if (toPractise.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(height: 3, color: _ink),
                  const SizedBox(height: 12),
                  for (final item in toPractise) _practiseRow(item),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: PlaySquareButton(
                        icon: PlayIcon.play,
                        label: againLabel,
                        color: PlayPalette.leaf,
                        size: 52,
                        onTap: onAgain,
                      ),
                    ),
                    const SizedBox(width: 10),
                    PlaySquareButton(
                      icon: PlayIcon.close,
                      label:
                          MaterialLocalizations.of(context).closeButtonTooltip,
                      color: PlayPalette.coral,
                      size: 52,
                      onTap: onClose,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Something that got away, with what it means.
  Widget _practiseRow(PlayPractice item) {
    final reading = item.reading;
    final soft = _ink.withValues(alpha: 0.65);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Text(item.target, style: playPixel(10, _ink, localeCode: targetCode)),
          if (reading != null && reading.isNotEmpty)
            Text('($reading)', style: playPixel(7, soft)),
          Text(
            '= ${item.meaning}',
            style: playPixel(8, soft, localeCode: nativeCode),
          ),
        ],
      ),
    );
  }
}

/// A panel with a one-cell border and its corners notched off a cell, the way
/// the signs and the tub are cut: a flat [color] face in ink, on whole cells.
///
/// The child sits inside the border, in [padding].
class PixelPanel extends StatelessWidget {
  const PixelPanel({
    super.key,
    required this.color,
    required this.child,
    this.cell = 3,
    this.ink = PlayPalette.ink,
    this.padding = EdgeInsets.zero,
  });

  final Color color;
  final Widget child;

  /// How thick the border is, and how much is cut off each corner.
  final double cell;
  final Color ink;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PixelPanelPainter(color: color, ink: ink, cell: cell),
      child: Padding(padding: padding + EdgeInsets.all(cell), child: child),
    );
  }
}

class PixelPanelPainter extends CustomPainter {
  const PixelPanelPainter({
    required this.color,
    required this.ink,
    required this.cell,
  });

  final Color color;
  final Color ink;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    final w = size.width, h = size.height, u = cell;
    canvas.drawRect(Rect.fromLTWH(u, 0, w - 2 * u, h), paint..color = ink);
    canvas.drawRect(Rect.fromLTWH(0, u, w, h - 2 * u), paint);
    canvas.drawRect(
        Rect.fromLTWH(u, u, w - 2 * u, h - 2 * u), paint..color = color);
  }

  @override
  bool shouldRepaint(covariant PixelPanelPainter old) =>
      old.color != color || old.ink != ink || old.cell != cell;
}

/// A five-cell pixel star, for a dizzy orbit.
class PixelStarPainter extends CustomPainter {
  const PixelStarPainter();

  /// '#' outline, 'o' fill.
  static const List<String> _pattern = [
    '..#..',
    '.#o#.',
    '#ooo#',
    '.#o#.',
    '..#..',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 5;
    final paint = Paint()..isAntiAlias = false;
    for (var row = 0; row < 5; row++) {
      for (var col = 0; col < 5; col++) {
        final glyph = _pattern[row][col];
        if (glyph == '.') continue;
        paint.color =
            glyph == '#' ? PlayPalette.ink : PlayPalette.gold;
        canvas.drawRect(
          Rect.fromLTWH(col * cell, row * cell, cell + 0.5, cell + 0.5),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant PixelStarPainter oldDelegate) => false;
}

/// Draws something that never changes from an image of it, made once per [key]
/// and size at the screen's own pixel density.
///
/// The games rebuild their scene every frame, and on the phone every rectangle
/// is a draw call of its own: a bubble is 289 cells, and ten of them rising
/// was thousands of draws a frame. The scenery and the pixel pieces are drawn
/// into an image the first time and that one image after. See
/// [PixelSprite.paint], which the boss pieces are drawn with for the same
/// reason.
class PlayImageCache {
  static final Map<Object, ui.Image> _cache = {};
  static int _cacheBytes = 0;

  /// How many images, and how much memory, the cache holds before it starts
  /// over: the toys, props and scenery of every game are a few dozen sizes.
  static const int _maxImages = 192;
  static const int _maxBytes = 24 << 20;

  static final Paint _imagePaint = Paint()..filterQuality = FilterQuality.none;

  /// How many images are held: for tests, to see a piece is made once.
  @visibleForTesting
  static int get count => _cache.length;

  static double get _pixelRatio =>
      ui.PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 1.0;

  /// The screen's pixels to a logical pixel: what the images are made at.
  static double get pixelRatio => _pixelRatio;

  /// An image of what [record] paints in [size], made once per [key] and size.
  /// [key] says what is being drawn: the same key at the same size must always
  /// record the same picture. The image is [pixelRatio] times [size] big.
  static ui.Image image(Object key, Size size,
      void Function(Canvas canvas, Size size) record) {
    final ratio = _pixelRatio;
    final full = (key, size.width, size.height, ratio);
    var image = _cache[full];
    if (image == null) {
      if (_cache.length >= _maxImages || _cacheBytes > _maxBytes) {
        for (final old in _cache.values) {
          // Safe while a frame still holds one: the engine keeps its own
          // reference.
          old.dispose();
        }
        _cache.clear();
        _cacheBytes = 0;
      }
      final recorder = ui.PictureRecorder();
      record(Canvas(recorder)..scale(ratio), size);
      image = _cache[full] = recorder.endRecording().toImageSync(
          math.max(1, (size.width * ratio).ceil()),
          math.max(1, (size.height * ratio).ceil()));
      _cacheBytes += image.width * image.height * 4;
    }
    return image;
  }

  /// Draws [record]'s picture of [size] at the origin of [canvas], from its
  /// image.
  static void paint(Canvas canvas, Size size, Object key,
      void Function(Canvas canvas, Size size) record) {
    if (size.isEmpty) return;
    final ratio = _pixelRatio;
    final image = PlayImageCache.image(key, size, record);
    // At the image's own size in physical pixels, so it lands one to one.
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, image.width / ratio, image.height / ratio),
      _imagePaint,
    );
  }
}

/// A pattern of pixel cells, drawn to fill its box: each character of
/// [rows] is a cell, looked up in [inks]; a character with no ink is
/// see-through.
///
/// What every small prop in the games is drawn with — a duck, a mole, a
/// lily pad, a stick — so they share the pet's chunky pixels. Drawn from an
/// image of each pattern, made once: see [PlayImageCache].
class PixelPatternPainter extends CustomPainter {
  const PixelPatternPainter(this.rows, this.inks, {this.mirrored = false});

  final List<String> rows;
  final Map<String, Color> inks;

  /// Drawn facing the other way.
  final bool mirrored;

  int get columns => rows.fold(0, (m, r) => r.length > m ? r.length : m);

  /// How many images are held: for tests, to see a pattern is made once.
  @visibleForTesting
  static int get cachedImages => PlayImageCache.count;

  @override
  void paint(Canvas canvas, Size size) {
    if (columns == 0 || rows.isEmpty) return;
    // The patterns are const lists, so the list itself says which one; the
    // inks are often rebuilt, so what is in them does.
    PlayImageCache.paint(
      canvas,
      size,
      (
        rows,
        Object.hashAllUnordered(
            [for (final e in inks.entries) Object.hash(e.key, e.value)]),
        mirrored,
      ),
      _record,
    );
  }

  void _record(Canvas canvas, Size size) {
    final cols = columns;
    final cw = size.width / cols;
    final ch = size.height / rows.length;
    final paint = Paint()..isAntiAlias = false;
    for (var y = 0; y < rows.length; y++) {
      final row = rows[y];
      // Runs of one character along the row, as one rectangle each.
      var start = 0;
      for (var x = 1; x <= row.length; x++) {
        if (x < row.length && row[x] == row[start]) continue;
        final ink = inks[row[start]];
        if (ink != null) {
          canvas.drawRect(
            // Overdrawn by a hair, so cells rounded to different device
            // pixels leave no gaps.
            Rect.fromLTWH((mirrored ? cols - x : start) * cw, y * ch,
                (x - start) * cw + 0.5, ch + 0.5),
            paint..color = ink,
          );
        }
        start = x;
      }
    }
  }

  @override
  bool shouldRepaint(covariant PixelPatternPainter old) =>
      old.rows != rows || old.inks != inks || old.mirrored != mirrored;
}
