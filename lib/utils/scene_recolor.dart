/// Recolours a scene's SVG for a time of day.
///
/// A scene drawn from a palette gets its day, sunset and night for free: the
/// art is geometry and the colour is a lookup. A scene that *is* a picture
/// does not, and the obvious answer — export the picture three times — puts
/// the burden on whoever draws it and guarantees the three drift apart. So the
/// picture is exported once, in daylight, and the other two are computed from
/// it.
///
/// The transform is deliberately blunt: every fill is pushed through the same
/// lightness, saturation and hue shift, plus a blend toward one tint colour.
/// A scene has hundreds of fills and no two exports will have the same set, so
/// anything that named them individually would break on the next export.
///
/// What cannot be blunt is light. Dusk darkens a building and *brightens* its
/// windows, and no global transform does both — run one and a terminal at
/// midnight is a dark shape with darker holes in it, which reads as a ruin.
/// So [SceneTint.lights] names the handful of fills that are glass and says
/// what they become. That list is short enough to redo by hand when the art
/// changes, and the failure mode if it is not redone is a window that stays
/// unlit rather than a scene that breaks.
///
/// A lit fill is still only a flat colour, though, and a thing that gives off
/// light also lights what is around it. [SceneTint.glow] adds that: a halo
/// painted behind the picture's objects, so it washes the sky and the ground
/// but never the outline.
library;

import 'dart:math' as math;
import 'dart:ui' show Color;

/// One halo of a [SceneGlow]: an ellipse of light, in the picture's own
/// coordinates (its `viewBox`, not the screen).
class SceneHalo {
  const SceneHalo(this.x, this.y, this.rx, this.ry);

  /// The centre.
  final double x;
  final double y;

  /// The outermost radii. The halo is drawn smaller than this in steps.
  final double rx;
  final double ry;
}

/// Light given off by things in a picture, for a time of day that has it.
///
/// Drawn the way the picture is: as rows of pixels on its grid in a few
/// steps, not a smooth gradient, so the light looks like part of the same
/// drawing instead of a filter laid over it.
class SceneGlow {
  const SceneGlow({
    required this.color,
    required this.under,
    required this.halos,
    this.cell = 2,
    this.steps = const [(1.0, 0.08), (0.85, 0.09), (0.7, 0.1), (0.55, 0.11)],
  });

  /// The colour of the light, as 24-bit RGB. Not subject to the tint around
  /// it: it is a light, like [SceneTint.lights].
  final int color;

  /// The fill of the first layer the light must sit behind. Everything drawn
  /// from that layer on — the objects, then the outline — covers it, which is
  /// what keeps the outline black and the light from spilling over the thing
  /// that gives it off. Everything before it, the sky and the ground, is lit.
  final int under;

  final List<SceneHalo> halos;

  /// The picture's pixel size, so the rings step on its grid.
  final int cell;

  /// Rings from the outside in: how far out each one reaches as a fraction of
  /// a halo's radii, and how opaque it is. They stack, so the light is
  /// strongest next to what gives it off.
  final List<(double, double)> steps;

  /// The `<path>` elements for every halo.
  String get markup {
    final hex = color.toRadixString(16).padLeft(6, '0');
    final out = StringBuffer();
    for (final (reach, opacity) in steps) {
      final d = StringBuffer();
      for (final h in halos) {
        _ring(d, h.x, h.y, h.rx * reach, h.ry * reach);
      }
      out.write('<path fill="#$hex" fill-opacity="$opacity" d="$d"/>');
    }
    return '$out';
  }

  /// One ellipse as rows of [cell]-high rectangles.
  void _ring(StringBuffer d, double cx, double cy, double rx, double ry) {
    int snap(double v) => (v / cell).round() * cell;

    final top = ((cy - ry) / cell).floor() * cell;
    for (var y = top; y < cy + ry; y += cell) {
      final t = (y + cell / 2 - cy) / ry;
      if (t.abs() >= 1) continue;
      final half = rx * math.sqrt(1 - t * t);
      final from = snap(cx - half);
      final to = snap(cx + half);
      if (to > from) d.write('M$from ${y}h${to - from}v${cell}h${from - to}z');
    }
  }
}

/// One time of day, as a transform over a scene's fills.
class SceneTint {
  const SceneTint({
    this.lightness = 1.0,
    this.saturation = 1.0,
    this.hueShift = 0.0,
    this.towards,
    this.towardsAmount = 0.0,
    this.lights = const {},
    this.keep = const {},
    this.glow,
  });

  /// Multiplies each fill's lightness. Below 1 darkens.
  final double lightness;

  /// Multiplies each fill's saturation. Below 1 drains colour toward grey.
  final double saturation;

  /// Degrees to rotate the hue by.
  final double hueShift;

  /// A colour every fill is blended toward, which is what actually sells a
  /// time of day: dusk is not "the same picture, darker", it is the same
  /// picture with one colour of light over all of it.
  final Color? towards;

  /// How far toward [towards], 0 to 1.
  final double towardsAmount;

  /// Fills that are light sources, and what they become. Applied after
  /// everything else and not subject to it — see the note above.
  final Map<int, int> lights;

  /// Fills left exactly as drawn, whatever the time of day.
  ///
  /// For the outline. Every other fill is pushed toward the tint's colour,
  /// which is the point of a tint, but black pushed toward dusk-orange is
  /// brown, and a drawing whose lines change colour with the clock has stopped
  /// looking like the same drawing. Unlike [lights], which replaces a fill
  /// with a different colour, this is a fill the tint does not touch at all.
  final Set<int> keep;

  /// Light the picture's lit things throw onto what is around them, or null.
  ///
  /// [lights] makes a lamp bright; this makes it shine. See [SceneGlow].
  final SceneGlow? glow;

  /// The identity, for the time of day the art was drawn in.
  static const SceneTint none = SceneTint();

  bool get isIdentity =>
      lightness == 1.0 &&
      saturation == 1.0 &&
      hueShift == 0.0 &&
      towardsAmount == 0.0 &&
      lights.isEmpty &&
      glow == null;
}

/// Applies [tint] to every `fill="#rrggbb"` in [svg].
///
/// String substitution rather than parsing, for the reason
/// `utils/pet_recolor.dart` does the same to the pet: the documents are
/// generated, their fills are literal, and a parser would be a great deal of
/// machinery to arrive at the same replacements.
String recolorSceneSvg(String svg, SceneTint tint) {
  if (tint.isIdentity) return svg;

  final cache = <String, String>{};
  String recolour(String part) => part.replaceAllMapped(
        RegExp(r'(fill|stop-color)="#([0-9a-fA-F]{6})"'),
        (m) {
          final hex = m[2]!.toLowerCase();
          final replaced = cache.putIfAbsent(hex, () => _shift(hex, tint));
          return '${m[1]}="#$replaced"';
        },
      );

  // The light goes in between the recolouring of what is before it and what is
  // after, so it is the one thing no tint touches. If the art has no such layer
  // there is no halo, which is the same failure as a window that stays unlit:
  // quiet, and nothing else breaks.
  final glow = tint.glow;
  final at = glow == null
      ? -1
      : svg.indexOf(
          '<path fill="#${glow.under.toRadixString(16).padLeft(6, '0')}"');
  if (glow == null || at < 0) return recolour(svg);

  return recolour(svg.substring(0, at)) +
      glow.markup +
      recolour(svg.substring(at));
}

String _shift(String hex, SceneTint tint) {
  final value = int.parse(hex, radix: 16);

  if (tint.keep.contains(value)) return hex;

  final lit = tint.lights[value];
  if (lit != null) return lit.toRadixString(16).padLeft(6, '0');

  var r = ((value >> 16) & 0xFF) / 255.0;
  var g = ((value >> 8) & 0xFF) / 255.0;
  var b = (value & 0xFF) / 255.0;

  final hsl = _toHsl(r, g, b);
  final rgb = _toRgb(
    (hsl[0] + tint.hueShift) % 360,
    (hsl[1] * tint.saturation).clamp(0.0, 1.0),
    (hsl[2] * tint.lightness).clamp(0.0, 1.0),
  );
  r = rgb[0];
  g = rgb[1];
  b = rgb[2];

  final towards = tint.towards;
  if (towards != null && tint.towardsAmount > 0) {
    final t = tint.towardsAmount.clamp(0.0, 1.0);
    r = r + (towards.r - r) * t;
    g = g + (towards.g - g) * t;
    b = b + (towards.b - b) * t;
  }

  int byte(double v) => (v.clamp(0.0, 1.0) * 255).round();
  return ((byte(r) << 16) | (byte(g) << 8) | byte(b))
      .toRadixString(16)
      .padLeft(6, '0');
}

List<double> _toHsl(double r, double g, double b) {
  final max = [r, g, b].reduce((a, c) => a > c ? a : c);
  final min = [r, g, b].reduce((a, c) => a < c ? a : c);
  final l = (max + min) / 2;
  if (max == min) return [0, 0, l];

  final d = max - min;
  final s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
  double h;
  if (max == r) {
    h = (g - b) / d + (g < b ? 6 : 0);
  } else if (max == g) {
    h = (b - r) / d + 2;
  } else {
    h = (r - g) / d + 4;
  }
  return [h * 60, s, l];
}

List<double> _toRgb(double h, double s, double l) {
  if (s == 0) return [l, l, l];
  final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
  final p = 2 * l - q;
  double channel(double t) {
    var v = t;
    if (v < 0) v += 1;
    if (v > 1) v -= 1;
    if (v < 1 / 6) return p + (q - p) * 6 * v;
    if (v < 1 / 2) return q;
    if (v < 2 / 3) return p + (q - p) * (2 / 3 - v) * 6;
    return p;
  }

  final hk = h / 360;
  return [channel(hk + 1 / 3), channel(hk), channel(hk - 1 / 3)];
}
