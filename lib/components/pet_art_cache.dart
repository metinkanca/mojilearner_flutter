import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Every drawing the pet is made of, read and parsed once and then kept.
///
/// A pet is eight or so SVG layers -- the coat, a tail in two poses, a mouth,
/// the eyes, and a layer for each thing it wears. [SvgPicture] parses each of
/// them in the background when it first mounts, and lets go of the parsed
/// picture the moment the last widget showing it unmounts. So every screen
/// that showed the pet parsed it again, layer by layer, each finishing in its
/// own frame: the coat in its drawn colour first, then the tail, then the
/// eyes, then the hat. That staggered arrival was the half-dressed pet.
///
/// Here the parse happens once, ahead of time, and the result outlives the
/// screen. A sprite asks whether everything it will draw is [has]-ready, draws
/// it all in one go if so, and otherwise waits and draws none of it.
abstract final class PetArt {
  /// How many parsed layers to keep. A pet is about ten, and the pet picker
  /// shows thirty at once; this is a few hundred so that scrolling the picker
  /// back and forth does not parse anything twice.
  ///
  /// Evicted pictures are not disposed: a sprite on screen may still be
  /// holding one, and the engine frees a picture nobody refers to anyway.
  static const int _capacity = 400;

  static final Map<String, String> _raw = {};
  static final Map<String, Future<void>> _rawPending = {};

  static final LinkedHashMap<String, PictureInfo> _pictures =
      LinkedHashMap<String, PictureInfo>();
  static final Map<String, Future<void>> _pending = {};

  /// Documents that would not parse. Counted as ready -- drawn as nothing --
  /// so one bad file cannot hold a whole pet back for ever.
  static final Set<String> _failed = {};

  /// The text of [asset], once [loadRaw] has read it. An asset that could not
  /// be read is the empty document, which parses to nothing.
  static String? raw(String asset) => _raw[asset];

  /// Reads each of [assets] from the bundle that has not been read already.
  static Future<void> loadRaw(Iterable<String> assets) =>
      Future.wait([for (final asset in assets.toSet()) _loadRaw(asset)]);

  // The work below runs on the root zone. It belongs to no one widget -- it
  // outlives whichever asked first -- and in a widget test the asking zone's
  // clock is fake: a load begun there that waits on the real world would
  // never be resumed, and every sprite after it would wait for ever.
  static Future<void> _loadRaw(String asset) {
    if (_raw.containsKey(asset)) return Future<void>.value();
    return _rawPending[asset] ??= Zone.root.run(() async {
      try {
        _raw[asset] = await rootBundle.loadString(asset);
      } catch (_) {
        _raw[asset] = '';
      } finally {
        _rawPending.remove(asset);
      }
    });
  }

  /// Whether [svg] is parsed (or has been tried and failed), so a sprite
  /// can draw it this frame.
  static bool has(String svg) =>
      _pictures.containsKey(svg) || _failed.contains(svg);

  /// The parsed [svg], or null if it is not ready.
  static PictureInfo? picture(String svg) {
    final info = _pictures.remove(svg);
    if (info == null) return null;
    _pictures[svg] = info; // now the most recently used
    return info;
  }

  /// Parses each of [svgs] that is not parsed already.
  static Future<void> prepare(Iterable<String> svgs) => Future.wait([
        for (final svg in svgs.toSet())
          if (!has(svg)) _parse(svg),
      ]);

  static Future<void> _parse(String svg) {
    return _pending[svg] ??= Zone.root.run(() async {
      try {
        final info = await vg.loadPicture(SvgStringLoader(svg), null);
        _pictures[svg] = info;
        while (_pictures.length > _capacity) {
          _pictures.remove(_pictures.keys.first);
        }
      } catch (error) {
        _failed.add(svg);
        if (kDebugMode) debugPrint('PetArt: could not parse a layer: $error');
      } finally {
        _pending.remove(svg);
      }
    });
  }

  /// Completes once nothing is being read or parsed. For tests, which have to
  /// let real time pass for the bundle to answer: wait on this inside
  /// `tester.runAsync`, then pump, and repeat until the pet is whole.
  @visibleForTesting
  static Future<void> settled() async {
    while (_rawPending.isNotEmpty || _pending.isNotEmpty) {
      await Future.wait([..._rawPending.values, ..._pending.values]);
    }
  }

  /// Forgets everything, so a test starts from a cold cache.
  @visibleForTesting
  static void debugClear() {
    _raw.clear();
    _rawPending.clear();
    _pictures.clear();
    _pending.clear();
    _failed.clear();
  }
}

/// One parsed pet layer, drawn into whatever box it is given.
///
/// Reads [PetArt] synchronously, so it is on screen in the very frame it is
/// built; it draws nothing for a layer that is not there. The sprite checks
/// that every layer is ready before it builds any of these, which is the
/// point.
///
/// Laid out as [SvgPicture] laid the same art out: the picture's own size when
/// the constraints are loose, and fitted into the box by [fit], centred, when
/// they are tight.
class PetPicture extends StatelessWidget {
  const PetPicture(this.svg, {super.key, this.fit = BoxFit.contain});

  final String svg;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final info = PetArt.picture(svg);
    if (info == null) return const SizedBox.shrink();
    return CustomPaint(size: info.size, painter: _PetPicturePainter(info, fit));
  }
}

class _PetPicturePainter extends CustomPainter {
  _PetPicturePainter(this.info, this.fit);

  final PictureInfo info;
  final BoxFit fit;

  @override
  void paint(Canvas canvas, Size size) {
    final picture = info.size;
    if (picture.isEmpty || size.isEmpty) return;
    final fitted = applyBoxFit(fit, picture, size);
    final sx = fitted.destination.width / fitted.source.width;
    final sy = fitted.destination.height / fitted.source.height;
    final shown = Alignment.center.inscribe(fitted.destination, Offset.zero & size);
    final cropped =
        Alignment.center.inscribe(fitted.source, Offset.zero & picture);
    canvas
      ..save()
      // The picture's own frame, as SvgPicture clips to its viewBox.
      ..clipRect(shown.intersect(Offset.zero & size))
      ..translate(shown.left, shown.top)
      ..scale(sx, sy)
      ..translate(-cropped.left, -cropped.top)
      ..drawPicture(info.picture)
      ..restore();
  }

  @override
  bool shouldRepaint(_PetPicturePainter old) =>
      !identical(old.info, info) || old.fit != fit;

  /// A picture is not a button. A painter that does not say otherwise claims
  /// every tap inside its box, and the pet's box is where the things behind it
  /// -- a close button under the sprite, the petting hand above it -- need
  /// theirs. [SvgPicture] never claimed them either.
  @override
  bool? hitTest(Offset position) => false;
}
