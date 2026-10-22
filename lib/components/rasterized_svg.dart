import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A picture that never changes, drawn once into an image the size it is
/// shown at, and that image shown from then on.
///
/// [SvgPicture] draws an SVG by replaying its paths every frame. That is
/// nothing for an icon and a great deal for this game's scenery: the
/// backgrounds are pixel art traced into paths, thousands to tens of thousands
/// of points apiece, and the phone's renderer keeps no copy of the frame
/// before — so a screen with anything at all moving on it redrew every one of
/// those points, every frame. On a phone-speed CPU, Sableth's and Pyrewing's
/// arenas alone held their fights to 15-20 frames a second.
///
/// The image is made at the exact pixel size it is shown at, so it is the
/// same picture, pixel for pixel. It is made in the background the first time
/// it is needed, one image at a time, with [placeholder] showing until then,
/// and kept in a cache every screen shares, so coming back to a screen costs
/// nothing.
///
/// Only for art that is laid out once and left alone: something resized every
/// frame would make a new image every frame, which is the opposite of the
/// point. The one resize this allows for is the home scene's — a
/// [BoxFit.cover] picture whose box shrinks along the side it crops, as the
/// keyboard slides in — because the image is the whole picture at its fitted
/// scale rather than the box, and that scale does not change.
class RasterizedSvg extends StatefulWidget {
  /// [svg] is the document and [cacheKey] its name: the same key must always
  /// mean the same document — its asset path, plus whatever recolouring was
  /// applied to it.
  RasterizedSvg.string(
    String svg, {
    super.key,
    required this.cacheKey,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.window,
    this.placeholder,
  }) : loader = SvgStringLoader(svg);

  /// An asset, drawn as it is in the bundle.
  RasterizedSvg.asset(
    String assetName, {
    super.key,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.window,
    this.placeholder,
  })  : loader = SvgAssetLoader(assetName),
        cacheKey = assetName;

  final BytesLoader loader;
  final String cacheKey;
  final BoxFit fit;
  final Alignment alignment;

  /// The part of the picture to show, as fractions of its width and height,
  /// laid into the box by [fit] and [alignment] as if it were all of it. The
  /// whole picture when null.
  ///
  /// For a picture shown in slices: drawing all of it into each slice and
  /// clipping would make an image of all of it for each one.
  final Rect? window;

  /// Shown until the image is ready. Nothing, when null.
  final Widget? placeholder;

  @override
  State<RasterizedSvg> createState() => _RasterizedSvgState();
}

const Rect _whole = Rect.fromLTRB(0, 0, 1, 1);

class _RasterizedSvgState extends State<RasterizedSvg> {
  /// The image painted now: this state's own handle on it.
  _Still? _shown;

  /// The layout last asked for, so a rebuild with the same one asks nothing.
  _Request? _asked;

  @override
  void dispose() {
    _shown?.dispose();
    super.dispose();
  }

  void _show(_Still still) {
    _shown?.dispose();
    _shown = still;
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(builder: (context, constraints) {
      final box = constraints.biggest;
      if (!box.isFinite || box.isEmpty) {
        return widget.placeholder ?? const SizedBox.shrink();
      }
      final request = _Request(widget.loader, widget.cacheKey, box, widget.fit,
          widget.alignment, widget.window ?? _whole, dpr);
      if (request != _asked) {
        _asked = request;
        final ready = _Stills.lookup(request);
        if (ready != null) {
          _show(ready);
        } else {
          // Until it arrives, the last image stays up, stretched to the new
          // layout — or the placeholder, the first time.
          _Stills.make(request).then((still) {
            if (still == null) return;
            if (!mounted || _asked != request) {
              still.dispose();
              return;
            }
            setState(() => _show(still));
          });
        }
      }
      final shown = _shown;
      if (shown == null) return widget.placeholder ?? const SizedBox.shrink();
      return CustomPaint(size: box, painter: _StillPainter(shown, request));
    });
  }
}

/// One drawn image, and the size of the picture it was drawn from.
class _Still {
  _Still(this.image, this.pictureSize);

  final ui.Image image;
  final Size pictureSize;

  int get bytes => image.width * image.height * 4;

  _Still clone() => _Still(image.clone(), pictureSize);

  void dispose() => image.dispose();
}

/// What a [RasterizedSvg] needs drawn: a picture, laid out into a box.
@immutable
class _Request {
  const _Request(this.loader, this.cacheKey, this.box, this.fit,
      this.alignment, this.window, this.devicePixelRatio);

  /// Not part of equality: [cacheKey] names what it loads.
  final BytesLoader loader;
  final String cacheKey;
  final Size box;
  final BoxFit fit;
  final Alignment alignment;
  final Rect window;
  final double devicePixelRatio;

  @override
  bool operator ==(Object other) =>
      other is _Request &&
      other.cacheKey == cacheKey &&
      other.box == box &&
      other.fit == fit &&
      other.alignment == alignment &&
      other.window == window &&
      other.devicePixelRatio == devicePixelRatio;

  @override
  int get hashCode =>
      Object.hash(cacheKey, box, fit, alignment, window, devicePixelRatio);
}

/// How a request is drawn: which part of the picture, into an image how
/// big, and where that image lands in the box.
@immutable
class _Plan {
  const _Plan(this.region, this.width, this.height, this.destination);

  /// The longest side an image is made at. Past it, older phones cannot hold
  /// the texture, so the image is made smaller and drawn up to size.
  static const double _maxSide = 4096;

  /// The part of the picture drawn, in the picture's own units.
  final Rect region;

  /// The image, in physical pixels.
  final int width;
  final int height;

  /// Where the image lands, in the box's logical pixels. It can overhang the
  /// box — a covered picture is cropped — and is clipped to it.
  final Rect destination;

  factory _Plan.of(Size picture, _Request request) {
    final w = request.window;
    final region = Rect.fromLTRB(w.left * picture.width,
        w.top * picture.height, w.right * picture.width, w.bottom * picture.height);
    if (region.isEmpty) return _Plan(region, 1, 1, Rect.zero);
    // The fit's scale, and where it puts the region, exactly as FittedBox
    // would lay the picture out.
    final fitted = applyBoxFit(request.fit, region.size, request.box);
    final sx = fitted.destination.width / fitted.source.width;
    final sy = fitted.destination.height / fitted.source.height;
    final shown =
        request.alignment.inscribe(fitted.destination, Offset.zero & request.box);
    final cropped =
        request.alignment.inscribe(fitted.source, Offset.zero & region.size);
    var width = region.width * sx * request.devicePixelRatio;
    var height = region.height * sy * request.devicePixelRatio;
    final over = math.max(width, height) / _maxSide;
    if (over > 1) {
      width /= over;
      height /= over;
    }
    return _Plan(
      region,
      math.max(1, width.round()),
      math.max(1, height.round()),
      Rect.fromLTWH(shown.left - cropped.left * sx, shown.top - cropped.top * sy,
          region.width * sx, region.height * sy),
    );
  }
}

/// A cached image's name: the picture, the part of it, and the pixel size —
/// all that decides what the image looks like.
@immutable
class _StillKey {
  const _StillKey(this.cacheKey, this.window, this.width, this.height);

  factory _StillKey.of(_Request request, Size picture) {
    final plan = _Plan.of(picture, request);
    return _StillKey(request.cacheKey, request.window, plan.width, plan.height);
  }

  final String cacheKey;
  final Rect window;
  final int width;
  final int height;

  @override
  bool operator ==(Object other) =>
      other is _StillKey &&
      other.cacheKey == cacheKey &&
      other.window == window &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(cacheKey, window, width, height);
}

/// The images every [RasterizedSvg] shares, and the queue that makes them.
abstract final class _Stills {
  /// What the cache may hold beyond the images on screen, which their widgets
  /// keep alive on their own handles: a few screens' worth of scenery.
  static const int _budget = 64 << 20;

  static final LinkedHashMap<_StillKey, _Still> _cache =
      LinkedHashMap<_StillKey, _Still>();
  static int _bytes = 0;

  /// Each picture's own size, learned when it is first drawn: what turns a
  /// request into a cache key without decoding the picture again.
  static final Map<String, Size> _sizes = {};

  /// The last job asked for; null until the first. Made inside [make] rather
  /// than here, so that it too belongs to the root zone.
  static Future<void>? _queue;
  static int _queued = 0;

  /// The last picture decoded, kept while the queue still has work: the
  /// arena asks for three slices of the one backdrop in a row.
  static (String, PictureInfo)? _decoded;

  /// A handle on the image [request] needs, if it has been made already.
  static _Still? lookup(_Request request) {
    final size = _sizes[request.cacheKey];
    if (size == null) return null;
    final key = _StillKey.of(request, size);
    final still = _cache.remove(key);
    if (still == null) return null;
    _cache[key] = still; // now the most recently used
    return still.clone();
  }

  /// Makes the image [request] needs, after whatever was asked for before.
  ///
  /// One at a time, so a screen that needs several makes them over several
  /// frames rather than stalling one: each is a full draw of its picture.
  ///
  /// The queue runs on the root zone. It belongs to no one widget — it
  /// outlives whichever asked first — and in a widget test the asking zone's
  /// clock is fake: work queued there that waits on the real world would
  /// never be resumed, and every image after it would wait forever.
  static Future<_Still?> make(_Request request) => Zone.root.run(() {
        _queued++;
        final made =
            (_queue ?? Future<void>.value()).then((_) => _make(request));
        _queue = made.then<void>((_) {}, onError: (_) {}).whenComplete(() {
          if (--_queued == 0) {
            _decoded?.$2.picture.dispose();
            _decoded = null;
          }
        });
        return made;
      });

  static Future<_Still?> _make(_Request request) async {
    try {
      // Asked for twice while it waited, by two widgets showing the same
      // thing: the first has made it.
      final ready = lookup(request);
      if (ready != null) return ready;

      final info = await _decode(request);
      _sizes[request.cacheKey] = info.size;
      final known = lookup(request);
      if (known != null) return known;

      final plan = _Plan.of(info.size, request);
      final image = await _rasterize(info, plan);
      final still = _Still(image, info.size);
      _store(_StillKey.of(request, info.size), still);
      return still.clone();
    } catch (error) {
      // A missing or malformed file: the placeholder stays, as it would for
      // an SvgPicture that failed to load.
      if (kDebugMode) {
        debugPrint('RasterizedSvg: could not draw ${request.cacheKey}: $error');
      }
      return null;
    }
  }

  static Future<PictureInfo> _decode(_Request request) async {
    final last = _decoded;
    if (last != null && last.$1 == request.cacheKey) return last.$2;
    _decoded = null;
    last?.$2.picture.dispose();
    final info = await vg.loadPicture(request.loader, null);
    _decoded = (request.cacheKey, info);
    return info;
  }

  static Future<ui.Image> _rasterize(PictureInfo info, _Plan plan) async {
    final recorder = ui.PictureRecorder();
    final region = plan.region;
    Canvas(recorder)
      ..scale(plan.width / region.width, plan.height / region.height)
      ..translate(-region.left, -region.top)
      ..drawPicture(info.picture);
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(plan.width, plan.height);
    } finally {
      picture.dispose();
    }
  }

  static void _store(_StillKey key, _Still still) {
    final replaced = _cache.remove(key);
    if (replaced != null) {
      _bytes -= replaced.bytes;
      replaced.dispose();
    }
    _cache[key] = still;
    _bytes += still.bytes;
    while (_bytes > _budget && _cache.length > 1) {
      final evicted = _cache.remove(_cache.keys.first)!;
      _bytes -= evicted.bytes;
      evicted.dispose();
    }
  }

  static void clear() {
    for (final still in _cache.values) {
      still.dispose();
    }
    _cache.clear();
    _bytes = 0;
    _sizes.clear();
  }
}

/// Forgets every image made so far, so a test starts from a cold cache.
@visibleForTesting
void debugClearRasterizedSvgCache() => _Stills.clear();

class _StillPainter extends CustomPainter {
  _StillPainter(this.still, this.request);

  final _Still still;
  final _Request request;

  @override
  void paint(Canvas canvas, Size size) {
    final image = still.image;
    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        _Plan.of(still.pictureSize, request).destination,
        Paint()..filterQuality = FilterQuality.low,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_StillPainter old) =>
      !identical(old.still, still) || old.request != request;
}
