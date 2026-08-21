import 'dart:ui' show Color;

/// How the two eye colors are combined.
enum EyeMode {
  /// Both eyes a single colour ([PetColorSpec.eyeColor1]).
  solid,

  /// Odd-eyed: left eye [PetColorSpec.eyeColor1], right [PetColorSpec.eyeColor2].
  heterochromia,
}

String eyeModeToString(EyeMode m) => m.name;

EyeMode eyeModeFromString(String? s) {
  switch (s) {
    case 'heterochromia':
      return EyeMode.heterochromia;
    case 'solid':
    default:
      return EyeMode.solid;
  }
}

/// The full set of recolourable choices for a pet. Immutable so it can be used
/// as a cache key (see [==]/[hashCode]).
class PetColorSpec {
  /// Hex (`#RRGGBB`) for the body + tail flat fill. Body and tail always share
  /// this colour.
  final String bodyColor;
  final EyeMode eyeMode;
  final String eyeColor1;
  final String eyeColor2;

  const PetColorSpec({
    required this.bodyColor,
    required this.eyeMode,
    required this.eyeColor1,
    required this.eyeColor2,
  });

  @override
  bool operator ==(Object other) =>
      other is PetColorSpec &&
      other.bodyColor == bodyColor &&
      other.eyeMode == eyeMode &&
      other.eyeColor1 == eyeColor1 &&
      other.eyeColor2 == eyeColor2;

  @override
  int get hashCode => Object.hash(bodyColor, eyeMode, eyeColor1, eyeColor2);
}

/// A named swatch for the customisation UI.
class PetSwatch {
  final String label;
  final String hex;
  const PetSwatch(this.label, this.hex);
}

/// Curated coat palette for the body + tail, shared by every recolourable pet.
/// The first entry (`Smoke`) is the pets' original flat fill, so an
/// un-customised pet looks unchanged.
const List<PetSwatch> kBodySwatches = [
  PetSwatch('Smoke', '#959379'),
  PetSwatch('Charcoal', '#5A554F'),
  PetSwatch('White', '#EDEAE0'),
  PetSwatch('Ginger', '#E0883B'),
  PetSwatch('Cream', '#E8D2A6'),
  PetSwatch('Brown', '#9C6B3F'),
  PetSwatch('Blue-grey', '#8C97A0'),
];

/// Eye-colour palette, in the order described by the design brief (most common
/// first). Shared by every recolourable pet.
const List<PetSwatch> kEyeSwatches = [
  PetSwatch('Gold', '#F4C430'),
  PetSwatch('Green', '#4CA65B'),
  PetSwatch('Amber', '#D9943A'),
  PetSwatch('Copper', '#B0641E'),
  PetSwatch('Blue', '#5AA0E0'),
];

/// The cat's original source fills, replaced when recolouring the body layers.
const List<String> _bodyMainFills = ['#959379', '#959279'];
const String _bodyShadeFill = '#606659';

/// Parses `#RRGGBB` into a [Color] (opaque). Falls back to mid-grey on bad
/// input so a typo never crashes the render.
Color hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '').trim();
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null || cleaned.length != 6) return const Color(0xFF959379);
  return Color(0xFF000000 | value);
}

String _colorToHex(int r, int g, int b) {
  String two(int v) => v.clamp(0, 255).toRadixString(16).padLeft(2, '0');
  return '#${two(r)}${two(g)}${two(b)}';
}

/// Multiplies each RGB channel by [factor] (<1 darkens) to derive a shading
/// tone from the base coat colour.
String darken(String hex, double factor) {
  final c = hexToColor(hex);
  return _colorToHex(
    (((c.r * 255).round()) * factor).round(),
    (((c.g * 255).round()) * factor).round(),
    (((c.b * 255).round()) * factor).round(),
  );
}

/// Recolours a body/tail layer SVG by swapping the flat coat fills. The dark
/// outline (`#1f2223`) and any non-body fills are left untouched.
String recolorBodyLayer(String svg, String bodyColor) {
  var out = svg;
  for (final fill in _bodyMainFills) {
    out = out.replaceAll('fill="$fill"', 'fill="$bodyColor"');
  }
  out =
      out.replaceAll('fill="$_bodyShadeFill"', 'fill="${darken(bodyColor, 0.72)}"');
  return out;
}

// Eye geometry, lifted verbatim from each pet's `*_eyes.svg` so the generated
// layer overlays the body pixel-perfectly and the blink transform still lines
// up. All pets share the one canvas, so the rects are canvas coordinates.
const String _eyeViewBox = '-20 -90 222 328';

/// The two eye cells of one pet. Both eyes are the same size; only their x
/// positions differ, so a squint/blink can scale the pair as a unit.
class PetEyeGeometry {
  final int leftX;
  final int rightX;
  final int y;
  final int w;
  final int h;

  const PetEyeGeometry({
    required this.leftX,
    required this.rightX,
    required this.y,
    required this.w,
    required this.h,
  });

  String _rect(int x, String fill) =>
      '<rect fill="$fill" x="$x" y="$y" width="$w" height="$h"/>';
}

/// Cat eyes: two 16x20 cells. Also the fallback for any pet without an entry.
const PetEyeGeometry kCatEyes =
    PetEyeGeometry(leftX: 80, rightX: 141, y: 69, w: 16, h: 20);

/// Dog eyes: taller and narrower than the cat's, and higher on the canvas
/// because the dog's head sits higher (see the sprite's `_layeredPets`).
const PetEyeGeometry kDogEyes =
    PetEyeGeometry(leftX: 99, rightX: 148, y: 40, w: 11, h: 23);

/// Builds the eyes layer SVG entirely from [spec], so solid / odd-eyed both
/// share the exact eye geometry of the original asset.
String buildEyesLayer(PetColorSpec spec, [PetEyeGeometry eyes = kCatEyes]) {
  final buffer = StringBuffer(
    '<svg id="katman_1" xmlns="http://www.w3.org/2000/svg" version="1.1" '
    'viewBox="$_eyeViewBox" shape-rendering="crispEdges">',
  );

  switch (spec.eyeMode) {
    case EyeMode.solid:
      buffer.write(eyes._rect(eyes.leftX, spec.eyeColor1));
      buffer.write(eyes._rect(eyes.rightX, spec.eyeColor1));
      break;
    case EyeMode.heterochromia:
      buffer.write(eyes._rect(eyes.leftX, spec.eyeColor1));
      buffer.write(eyes._rect(eyes.rightX, spec.eyeColor2));
      break;
  }

  buffer.write('</svg>');
  return buffer.toString();
}
