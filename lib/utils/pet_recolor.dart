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
///
/// [id] is the ownership key. Bought swatches are recorded in the same
/// unlocked-item set the shop writes to, so a coat the player paid for is
/// carried by the existing save and cloud-sync path with nothing new to
/// persist, and the ids are prefixed (`coat_` / `eye_`) so they can never
/// collide with a shop item.
class PetSwatch {
  final String id;
  final String label;
  final String hex;

  /// Coin cost, or null when the swatch is free from the first launch.
  final int? price;

  const PetSwatch(this.id, this.label, this.hex, {this.price});

  /// True when nothing gates it: the natural coats and eye colours a pet can
  /// plausibly be born with.
  bool get isFree => price == null;
}

// Prices sit against the rest of the economy the way accessory prices do (see
// `kAccessories`): a solid day of quizzes pays roughly 40-60 coins, hats run
// 60-150, backgrounds 100-200. A coat repaints the whole pet, so it is priced
// above a hat — a few days for a pastel, most of a fortnight for the metallics
// — and eyes, which are two small cells, are priced below one.
const int kCoatPricePastel = 120;
const int kCoatPriceVivid = 250;
const int kCoatPriceExotic = 450;
const int kEyePriceFancy = 80;
const int kEyePriceExotic = 160;

/// Natural coat palette for the body + tail, free from the first launch and
/// shared by every recolourable pet. The first entry (`Smoke`) is the pets'
/// original flat fill, so an un-customised pet looks unchanged.
const List<PetSwatch> kBodySwatches = [
  PetSwatch('coat_smoke', 'Smoke', '#959379'),
  PetSwatch('coat_charcoal', 'Charcoal', '#5A554F'),
  PetSwatch('coat_white', 'White', '#EDEAE0'),
  PetSwatch('coat_ginger', 'Ginger', '#E0883B'),
  PetSwatch('coat_cream', 'Cream', '#E8D2A6'),
  PetSwatch('coat_brown', 'Brown', '#9C6B3F'),
  PetSwatch('coat_bluegrey', 'Blue-grey', '#8C97A0'),
];

/// Coats no animal was ever born with, bought with coins.
///
/// Deliberately a separate list from [kBodySwatches] rather than priced
/// entries mixed into it: the free palette is what a pet plausibly looks like,
/// and this is the part the player is grinding for. Keeping the two apart
/// means the natural coats can never be accidentally locked, and the paid tier
/// can grow without re-reading every entry above.
const List<PetSwatch> kFancyBodySwatches = [
  // Pastels — the gentle end, and the first thing most players can afford.
  PetSwatch('coat_mint', 'Mint', '#7FD6B5', price: kCoatPricePastel),
  PetSwatch('coat_bubblegum', 'Bubblegum', '#F7A8CE', price: kCoatPricePastel),
  PetSwatch('coat_lilac', 'Lilac', '#B79CE8', price: kCoatPricePastel),
  PetSwatch('coat_sky', 'Sky', '#86C9F2', price: kCoatPricePastel),
  PetSwatch('coat_butter', 'Butter', '#F3E27A', price: kCoatPricePastel),
  PetSwatch('coat_ghost', 'Ghost', '#E4F1F7', price: kCoatPricePastel),
  // Vivid — reads as a costume across the room.
  PetSwatch('coat_neonlime', 'Neon Lime', '#A6F03C', price: kCoatPriceVivid),
  PetSwatch('coat_magenta', 'Magenta', '#E24BB0', price: kCoatPriceVivid),
  PetSwatch('coat_aqua', 'Aqua', '#35D6D6', price: kCoatPriceVivid),
  PetSwatch('coat_tangerine', 'Tangerine', '#FF7A33', price: kCoatPriceVivid),
  PetSwatch('coat_ultraviolet', 'Ultraviolet', '#8A4BF0',
      price: kCoatPriceVivid),
  PetSwatch('coat_ember', 'Ember', '#E8452C', price: kCoatPriceVivid),
  // Exotic — the long goals, kept few so they stay rare.
  PetSwatch('coat_void', 'Void', '#262A38', price: kCoatPriceExotic),
  PetSwatch('coat_gold', 'Gold', '#E6C453', price: kCoatPriceExotic),
  PetSwatch('coat_silver', 'Silver', '#C7D2DC', price: kCoatPriceExotic),
  PetSwatch('coat_rosegold', 'Rose Gold', '#E8B4A6', price: kCoatPriceExotic),
];

/// Every coat in picker order: the natural ones first, then the paid tiers
/// cheapest-first, so the row reads as a ladder.
const List<PetSwatch> kAllBodySwatches = [
  ...kBodySwatches,
  ...kFancyBodySwatches,
];

/// Natural eye-colour palette, in the order described by the design brief
/// (most common first). Free, and shared by every recolourable pet.
const List<PetSwatch> kEyeSwatches = [
  PetSwatch('eye_gold', 'Gold', '#F4C430'),
  PetSwatch('eye_green', 'Green', '#4CA65B'),
  PetSwatch('eye_amber', 'Amber', '#D9943A'),
  PetSwatch('eye_copper', 'Copper', '#B0641E'),
  PetSwatch('eye_blue', 'Blue', '#5AA0E0'),
];

/// Bought eye colours. Cheaper than a coat because the eyes are two small
/// cells — but they combine with odd-eyes, so a paid colour on one side is a
/// visible thing to spend on early.
const List<PetSwatch> kFancyEyeSwatches = [
  PetSwatch('eye_violet', 'Violet', '#9B5CF0', price: kEyePriceFancy),
  PetSwatch('eye_rose', 'Rose', '#FF6BAE', price: kEyePriceFancy),
  PetSwatch('eye_jade', 'Jade', '#2FD6A5', price: kEyePriceFancy),
  PetSwatch('eye_ice', 'Ice', '#BFE8FF', price: kEyePriceFancy),
  PetSwatch('eye_crimson', 'Crimson', '#E0364C', price: kEyePriceFancy),
  PetSwatch('eye_silver', 'Silver', '#DCE6F0', price: kEyePriceExotic),
  PetSwatch('eye_void', 'Void', '#2B2F3C', price: kEyePriceExotic),
  PetSwatch('eye_neon', 'Neon', '#A6F03C', price: kEyePriceExotic),
];

/// Every eye colour in picker order (see [kAllBodySwatches]).
const List<PetSwatch> kAllEyeSwatches = [
  ...kEyeSwatches,
  ...kFancyEyeSwatches,
];

/// The swatch in [palette] painted with [hex], or null when the colour is not
/// in the catalogue at all — a legacy save or a hand-edited value, which is
/// treated as free rather than locked so an update can never take a pet's
/// existing coat away.
PetSwatch? swatchByHex(List<PetSwatch> palette, String hex) {
  final wanted = hex.toLowerCase();
  for (final s in palette) {
    if (s.hex.toLowerCase() == wanted) return s;
  }
  return null;
}

/// The swatch with [id] across both palettes, or null.
PetSwatch? swatchById(String id) {
  for (final s in kAllBodySwatches) {
    if (s.id == id) return s;
  }
  for (final s in kAllEyeSwatches) {
    if (s.id == id) return s;
  }
  return null;
}

/// The cat's original source fills, replaced when recolouring the body layers.
const List<String> _bodyMainFills = ['#959379', '#959279'];
const String _bodyShadeFill = '#606659';

/// The dark outline every pet layer and accessory is drawn with.
const String kOutlineFill = '#1f2223';

/// Widens the outline by half a unit, so it covers the coat's own antialiased
/// edge.
///
/// The art is drawn as a flat coat polygon with the outline laid over it, and
/// the two share their outer boundary. Drawn at the fractional scale the pet
/// is actually rendered at, that boundary lands mid-pixel: the coat paints a
/// partial-coverage sliver of `#959379`, then the outline paints an equally
/// partial sliver of `#1f2223` over it, and what survives is a blend of coat,
/// outline and background — about twice as bright as either. Against a pale
/// sky nobody sees it. Against the night sky it is a white rim around the pet.
///
/// Stroking each outline path with its own colour makes the outline the last
/// thing under the edge, so the boundary pixel blends outline with background
/// instead of coat with background. It closes the hairline gaps between
/// abutting outline pieces for the same reason — the gaps a rotated tail used
/// to open. Half of the 1-unit stroke lands outside the shape and half inside,
/// so the silhouette grows by a quarter of a pixel at the size the pet is
/// drawn: invisible, unlike the rim.
String sealOutlines(String svg) {
  if (svg.contains('stroke="$kOutlineFill"')) return svg;
  return svg.replaceAll(
    'fill="$kOutlineFill"',
    'fill="$kOutlineFill" stroke="$kOutlineFill" stroke-width="1"',
  );
}

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

/// The eye cells of one pet. Both eyes are the same size; only their x
/// positions differ, so a squint/blink can scale the pair as a unit.
///
/// A pet drawn in profile shows one eye, not two: [rightX] is null for it, and
/// there is then no second cell for an odd-eyed pair to colour differently.
class PetEyeGeometry {
  final int leftX;
  final int? rightX;
  final int y;
  final int w;
  final int h;

  const PetEyeGeometry({
    required this.leftX,
    this.rightX,
    required this.y,
    required this.w,
    required this.h,
  });

  /// True when the pet shows a single eye, so odd-eyed has nothing to act on.
  bool get isSingle => rightX == null;

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

/// Bird eye: one 8x15 cell. The chick is drawn in profile, so the far eye is
/// on the side of its head nobody can see.
const PetEyeGeometry kBirdEyes = PetEyeGeometry(leftX: 121, y: 92, w: 8, h: 15);

/// Builds the eyes layer SVG entirely from [spec], so solid / odd-eyed both
/// share the exact eye geometry of the original asset.
///
/// A single-eyed pet always uses [PetColorSpec.eyeColor1]: it has no second
/// cell, so odd-eyed would otherwise silently pick whichever colour happened
/// to be in the slot the pet does not show.
String buildEyesLayer(PetColorSpec spec, [PetEyeGeometry eyes = kCatEyes]) {
  final buffer = StringBuffer(
    '<svg id="katman_1" xmlns="http://www.w3.org/2000/svg" version="1.1" '
    'viewBox="$_eyeViewBox" shape-rendering="crispEdges">',
  );

  buffer.write(eyes._rect(eyes.leftX, spec.eyeColor1));
  final rightX = eyes.rightX;
  if (rightX != null) {
    buffer.write(eyes._rect(
      rightX,
      spec.eyeMode == EyeMode.heterochromia ? spec.eyeColor2 : spec.eyeColor1,
    ));
  }

  buffer.write('</svg>');
  return buffer.toString();
}
