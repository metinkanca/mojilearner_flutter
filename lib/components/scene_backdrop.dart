import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/scenes.dart';
import '../utils/scene_recolor.dart';
import 'rasterized_svg.dart';

/// A scene that is a picture rather than a palette.
///
/// Most worlds are bands and rectangles, which is what gives them their three
/// times of day for nothing. A scene may instead name an SVG, and then this
/// draws it: loaded once, recoloured per time of day by
/// [recolorSceneSvg], and cached so neither cost is paid per frame.
///
/// The banded scene is still drawn underneath. That is not belt and braces —
/// it is what is on screen for the frames before the asset resolves, and what
/// stays there if it never does, so a missing or malformed file costs the
/// player a less detailed airfield rather than a blank screen.
class SceneBackdrop extends StatefulWidget {
  const SceneBackdrop({
    super.key,
    required this.scene,
    required this.time,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.bottomCenter,
    this.rasterize = false,
  });

  final SceneTheme scene;
  final SceneTime time;
  final BoxFit fit;

  /// Draws the picture once into an image and shows that, rather than
  /// replaying its paths every frame. See [RasterizedSvg].
  ///
  /// For the home screen, where the scene is the whole background behind a
  /// pet that moves all day: as paths, every step of its breath redrew a
  /// picture of up to fifteen thousand points.
  ///
  /// Off for the wardrobe's and the pass's tiles. Making the image costs about
  /// one full draw of the picture up front, and a screen of tiles all making
  /// theirs at once held the wardrobe up for half a second as it opened.
  final bool rasterize;

  /// Where the picture is anchored when it cannot fill the box at its own
  /// aspect. Bottom by default: a scene's horizon and its ground are the part
  /// the pet has to stand in, so sky is what gets cropped.
  final Alignment alignment;

  @override
  State<SceneBackdrop> createState() => _SceneBackdropState();
}

class _SceneBackdropState extends State<SceneBackdrop> {
  /// Recoloured documents, by asset and time of day.
  ///
  /// Static: two screens can show the same world at once — the home screen and
  /// a wardrobe tile — and the recolour is a pass over a couple of hundred
  /// kilobytes of text.
  static final Map<String, String> _cache = {};
  static final Map<String, Future<String>> _loading = {};

  String? _svg;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(SceneBackdrop old) {
    super.didUpdateWidget(old);
    if (old.scene.id != widget.scene.id || old.time != widget.time) {
      _svg = null;
      _load();
    }
  }

  String get _key => '${widget.scene.asset}#${widget.time.name}';

  Future<void> _load() async {
    final asset = widget.scene.asset;
    if (asset == null) return;

    final cached = _cache[_key];
    if (cached != null) {
      _svg = cached;
      return;
    }

    final key = _key;
    final future = _loading.putIfAbsent(key, () async {
      final raw = await rootBundle.loadString(asset);
      final tinted = recolorSceneSvg(raw, widget.scene.tintFor(widget.time));
      _cache[key] = tinted;
      return tinted;
    });

    try {
      final tinted = await future;
      if (mounted && key == _key) setState(() => _svg = tinted);
    } catch (_) {
      // The banded scene underneath is the fallback; see the class note.
    } finally {
      _loading.remove(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    final svg = _svg;
    if (svg == null) return const SizedBox.shrink();
    if (widget.rasterize) {
      return RasterizedSvg.string(
        svg,
        cacheKey: _key,
        fit: widget.fit,
        alignment: widget.alignment,
      );
    }
    return SvgPicture.string(
      svg,
      fit: widget.fit,
      alignment: widget.alignment,
      // The picture is the whole background; letting it animate or rebuild
      // would be paying for a scene that never changes within a time of day.
      placeholderBuilder: (_) => const SizedBox.shrink(),
    );
  }
}
