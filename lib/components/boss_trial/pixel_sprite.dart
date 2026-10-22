/// A piece of pixel art held as rows of letters, one letter a cell, drawn on
/// whole cells at whatever size it is laid out at.
///
/// For UI art that has to fit its words: a panel as wide as the screen, a tile
/// as wide as its word. Stretching the picture would smear its moss clumps
/// and corner stones, so a sprite instead names a middle run of columns (and
/// of rows) plain enough to repeat, keeps its ends as drawn, and tiles that
/// run to fill the rest.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

class PixelSprite {
  const PixelSprite({
    required this.rows,
    required this.palette,
    this.midX,
    this.midY,
  });

  /// One string a row, one letter a cell; `.` is empty.
  final List<String> rows;
  final Map<String, Color> palette;

  /// The run of columns, and of rows, [start, end), that repeats to fill a
  /// larger size — or is cut short for a smaller one. Without one, the
  /// sprite scales whole.
  final (int, int)? midX, midY;

  /// The letter a sprite writes its words on, recoloured by [paint]'s `face`.
  static const String face = 'W';

  int get width => rows.first.length;
  int get height => rows.length;

  /// Which of its own [n] columns (or rows) draws column [d] of [to].
  static int _source(int d, int to, int n, (int, int)? mid) {
    if (to == n) return d;
    if (mid == null) return (d * n / to).floor().clamp(0, n - 1);
    final (a, b) = mid;
    final tail = n - b;
    if (to < a + tail) {
      // Too small even for its ends: some of each, the inner parts cut.
      final left = (to * a / (a + tail)).round();
      return d < left ? d : n - (to - d);
    }
    if (d < a) return d;
    if (d >= to - tail) return n - (to - d);
    return a + (d - a) % (b - a);
  }

  static final Map<Object, ui.Image> _cache = {};
  static int _cacheBytes = 0;

  /// How many images, and how much memory, the cache holds before it starts
  /// over: every size, face colour and piece of every boss's skin would be
  /// a few hundred, and a full-width panel is over a megabyte.
  static const int _maxImages = 256;
  static const int _maxBytes = 32 << 20;

  static final Paint _imagePaint = Paint()..filterQuality = FilterQuality.none;

  /// Draws it [cols] by [rows] cells of [cellW] by [cellH] from [origin],
  /// its words' face in [face] when given.
  ///
  /// Every size is drawn once, into an image at the screen's own pixel
  /// density, and that image is what is drawn after: the arena rebuilds every
  /// frame. It used to keep a recorded picture instead, which saved building
  /// the rectangles again but not drawing them — a picture is replayed
  /// rectangle by rectangle, and the phone's renderer draws each one on its
  /// own. A sand tile 62 cells across is 550 of them, so the Sandstorm's grid
  /// of thirty was 16,500 draws a frame. Now each piece is one.
  void paint(
    Canvas canvas,
    Offset origin,
    int cols,
    int rows, {
    required double cellW,
    required double cellH,
    Color? face,
  }) {
    if (cols <= 0 || rows <= 0) return;
    final ratio = _pixelRatio;
    final key = (this, cols, rows, cellW, cellH, face?.toARGB32(), ratio);
    var image = _cache[key];
    if (image == null) {
      if (_cache.length >= _maxImages || _cacheBytes > _maxBytes) {
        _clearCache();
      }
      image = _cache[key] = _raster(cols, rows, cellW, cellH, face, ratio);
      _cacheBytes += image.width * image.height * 4;
    }
    // At the image's own size in physical pixels, so it lands one to one.
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(origin.dx.roundToDouble(), origin.dy.roundToDouble(),
          image.width / ratio, image.height / ratio),
      _imagePaint,
    );
  }

  /// The screen's pixels to a logical pixel: what the images are made at.
  static double get _pixelRatio =>
      ui.PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 1.0;

  static void _clearCache() {
    // Safe while a frame still holds one: the engine keeps its own reference.
    for (final image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
    _cacheBytes = 0;
  }

  ui.Image _raster(int cols, int rowCount, double cellW, double cellH,
      Color? faceColor, double ratio) {
    final recorder = ui.PictureRecorder();
    _record(Canvas(recorder)..scale(ratio), cols, rowCount, cellW, cellH,
        faceColor);
    final w = (cols * cellW).roundToDouble();
    final h = (rowCount * cellH).roundToDouble();
    return recorder.endRecording().toImageSync(
        math.max(1, (w * ratio).ceil()), math.max(1, (h * ratio).ceil()));
  }

  void _record(Canvas canvas, int cols, int rowCount, double cellW,
      double cellH, Color? faceColor) {
    final paint = Paint()..isAntiAlias = false;
    double x(int i) => (i * cellW).roundToDouble();
    double y(int i) => (i * cellH).roundToDouble();
    final xs = [for (var d = 0; d < cols; d++) _source(d, cols, width, midX)];
    for (var r = 0; r < rowCount; r++) {
      final row = rows[_source(r, rowCount, height, midY)];
      // Runs of one letter along the row, as one rectangle each.
      var start = 0;
      for (var d = 1; d <= cols; d++) {
        final letter = row[xs[start]];
        if (d < cols && row[xs[d]] == letter) continue;
        if (letter != '.') {
          final color = letter == PixelSprite.face && faceColor != null
              ? faceColor
              : palette[letter]!;
          canvas.drawRect(Rect.fromLTRB(x(start), y(r), x(d), y(r + 1)),
              paint..color = color);
        }
        start = d;
      }
    }
  }

  /// [n] cells cut back to where this sprite's repeating run of [mid] has
  /// repeated a whole number of times: for a run of stripes, so none is cut
  /// short where the repeats end.
  static int _whole(int n, int size, (int, int)? mid) {
    if (mid == null) return n;
    final (a, b) = mid;
    final ends = size - (b - a);
    if (n <= ends) return n;
    return ends + (n - ends) ~/ (b - a) * (b - a);
  }

  /// Drawn on cells of [cell] filling [size], centred in it, the middle runs
  /// repeating. With [wholeX] it is as wide as the repeats allow, a few cells
  /// narrower than [size] at most, so a stripe is never cut short.
  void paintTiled(Canvas canvas, Size size, double cell,
      {Color? face, bool wholeX = false}) {
    var cols = (size.width / cell).floor();
    if (wholeX) cols = _whole(cols, width, midX);
    final rows = (size.height / cell).floor();
    paint(
      canvas,
      Offset((size.width - cols * cell) / 2, (size.height - rows * cell) / 2),
      cols,
      rows,
      cellW: cell,
      cellH: cell,
      face: face,
    );
  }

  /// Drawn as tall as [size], square cells, its middle columns repeating to
  /// make it as wide.
  void paintToHeight(Canvas canvas, Size size, {Color? face}) {
    final cell = size.height / height;
    final cols = (size.width / cell).round();
    paint(canvas, Offset((size.width - cols * cell) / 2, 0), cols, height,
        cellW: cell, cellH: cell, face: face);
  }

  /// Drawn whole, as large as fits in [size], placed by [alignment].
  void paintContained(Canvas canvas, Size size,
      {Alignment alignment = Alignment.center, Color? face}) {
    final cell = (size.width / width < size.height / height)
        ? size.width / width
        : size.height / height;
    final free = Size(size.width - width * cell, size.height - height * cell);
    paint(canvas, alignment.alongSize(free), width, height,
        cellW: cell, cellH: cell, face: face);
  }
}

/// A [PixelSprite] as a widget's painter.
class PixelSpritePainter extends CustomPainter {
  /// On cells of [cell], its middle runs repeating to fill the size.
  const PixelSpritePainter.tiled(this.sprite,
      {required double this.cell, this.face})
      : _mode = _Mode.tiled,
        alignment = Alignment.center;

  /// As tall as the size, its middle columns repeating to make it as wide.
  const PixelSpritePainter.toHeight(this.sprite, {this.face})
      : _mode = _Mode.toHeight,
        cell = null,
        alignment = Alignment.center;

  /// Whole, as large as fits.
  const PixelSpritePainter.contained(this.sprite,
      {this.alignment = Alignment.center, this.face})
      : _mode = _Mode.contained,
        cell = null;

  final PixelSprite sprite;
  final double? cell;
  final Color? face;
  final Alignment alignment;
  final _Mode _mode;

  @override
  void paint(Canvas canvas, Size size) => switch (_mode) {
        _Mode.tiled => sprite.paintTiled(canvas, size, cell!, face: face),
        _Mode.toHeight => sprite.paintToHeight(canvas, size, face: face),
        _Mode.contained =>
          sprite.paintContained(canvas, size, alignment: alignment, face: face),
      };

  @override
  bool shouldRepaint(covariant PixelSpritePainter old) =>
      old.sprite != sprite ||
      old.cell != cell ||
      old.face != face ||
      old.alignment != alignment ||
      old._mode != _mode;
}

enum _Mode { tiled, toHeight, contained }
