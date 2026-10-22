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

  /// Hex for the beak, on a pet that has one. Null keeps the beak as drawn —
  /// which, for a beak painted in [kBeakFill], means the coat's shade.
  final String? beakColor;

  const PetColorSpec({
    required this.bodyColor,
    required this.eyeMode,
    required this.eyeColor1,
    required this.eyeColor2,
    this.beakColor,
  });

  @override
  bool operator ==(Object other) =>
      other is PetColorSpec &&
      other.bodyColor == bodyColor &&
      other.eyeMode == eyeMode &&
      other.eyeColor1 == eyeColor1 &&
      other.eyeColor2 == eyeColor2 &&
      other.beakColor == beakColor;

  @override
  int get hashCode =>
      Object.hash(bodyColor, eyeMode, eyeColor1, eyeColor2, beakColor);
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

/// Beak colours, for the pets that have a beak (see `beakFillsFor` in the
/// sprite). All free: a beak is a small patch of the pet, and the choice is as
/// much about matching a coat as about decoration.
///
/// The first entry a pet is offered is not in this list — it is that pet's own
/// natural beak, which clears the choice rather than naming a colour.
const List<PetSwatch> kBeakSwatches = [
  PetSwatch('beak_orange', 'Orange', '#F29422'),
  PetSwatch('beak_yellow', 'Yellow', '#F6CB1D'),
  PetSwatch('beak_ivory', 'Ivory', '#EFE3C8'),
  PetSwatch('beak_pink', 'Pink', '#F2A2B0'),
  PetSwatch('beak_red', 'Red', '#D9463A'),
  PetSwatch('beak_blue', 'Blue', '#5AA0E0'),
  PetSwatch('beak_charcoal', 'Charcoal', '#3A3F4A'),
];

/// Id of the swatch standing for "the beak as drawn".
const String kNaturalBeakSwatchId = 'beak_natural';

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

/// The third coat tone: a highlight, lighter than the coat rather than darker.
///
/// The original trio had no use for one — a cat is a flat coat with one shade
/// under the chin. Most of the roster pets are drawn with a pale front: a
/// cream chest on the fox, a white belly on the seal, a pale throat on the
/// frog. Those cannot be [_bodyShadeFill], which is derived by darkening, and
/// leaving them as fixed markings is worse than it sounds — a mint frog would
/// keep a green throat, and a lilac seal a grey belly. So a layer may name
/// this tone and have it move with the coat like the other two.
const String _bodyLightFill = '#c8c6b3';

/// The beak marker fill: a beak drawn in it follows the coat, rendering as the
/// coat's shade, until the player gives the beak a colour of its own. It is
/// what lets the reworked bird's beak be grey by default and orange on request
/// without a second asset.
const String kBeakFill = '#7a6f5a';

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

/// Moves each RGB channel [factor] of the way to white (0 is white, 1 is no
/// change), to derive the highlight tone from the base coat colour.
///
/// Deliberately a screen rather than [darken]'s multiply: multiplying by more
/// than one clips the bright channels first and swings the hue as it does —
/// a ginger coat would highlight to pure yellow. Lightening toward white keeps
/// the hue and just drains it, which is what a pale belly looks like.
String lighten(String hex, double factor) {
  final c = hexToColor(hex);
  int up(double channel) {
    final v = (channel * 255).round();
    return (255 - (255 - v) * factor).round();
  }

  return _colorToHex(up(c.r), up(c.g), up(c.b));
}

/// Recolours an accessory by swapping the flat fills a variant names.
///
/// Deliberately a plain substitution rather than a hue shift: the art is flat
/// colour with a hard outline, so a variant is exactly "this fill becomes that
/// one" and anything cleverer would drift the palette away from the drawing
/// somebody actually approved.
///
/// The outline is not swappable — see [AccessoryRecolor.fills] — and a fill
/// the art does not contain is simply a no-op, so a variant that outlives a
/// redraw renders as the source rather than as nothing.
String recolorAccessory(String svg, Map<String, String> fills) {
  if (fills.isEmpty) return svg;

  // One pass over the whole string rather than a `replaceAll` per entry.
  // Substituting in sequence lets a palette chain into itself: swapping
  // A into B and then B into C turns the *newly written* Bs into Cs too, so a
  // variant that shades one colour into another piece's colour collapses to a
  // single tone. Each fill is therefore read once and mapped once.
  return svg.replaceAllMapped(
    RegExp(r'fill="(#[0-9a-fA-F]{6})"'),
    (match) {
      final from = match.group(1)!;
      // The outline is shared by every pet and every accessory, so a variant
      // must not be able to move it — see [AccessoryRecolor.fills].
      if (from.toLowerCase() == kOutlineFill.toLowerCase()) {
        return match.group(0)!;
      }
      final to = fills[from];
      return to == null ? match.group(0)! : 'fill="$to"';
    },
  );
}

/// Recolours a body/tail layer SVG by swapping the flat coat fills. The dark
/// outline (`#1f2223`) and any non-body fills are left untouched.
///
/// Non-body fills are how a pet keeps what makes it that animal: the panda's
/// black, the raccoon's mask, the penguin's beak. A pet declares which of its
/// fills are coat when its art is generated — see `art_src/gen_roster_pets.py`
/// — and everything it does not declare arrives here and is left alone.
///
/// [beakColor] repaints the beak: [kBeakFill] always (as the coat's shade when
/// no colour is chosen), and [beakFills] — a pet's own drawn beak tones — only
/// when one is. [beakShadeFills] are the beak's shaded tones, which follow a
/// chosen colour as its darker self rather than being flattened into it: the
/// penguin's bill is two-toned, and a blue bill with a rust underside reads as
/// a mistake. Beaks go first, so a beak colour can never be caught by the
/// coat swap after it.
///
/// [shadeColor], [lightColor] and [naturalBeak] replace the derived tones —
/// how a pet in its natural coat is painted in the tones it was drawn in
/// rather than ones computed from the coat (see `naturalTonesFor`).
String recolorBodyLayer(
  String svg,
  String bodyColor, {
  String? beakColor,
  List<String> beakFills = const [],
  List<String> beakShadeFills = const [],
  String? shadeColor,
  String? lightColor,
  String? naturalBeak,
}) {
  final shade = shadeColor ?? darken(bodyColor, 0.72);
  var out = svg;
  if (beakColor != null) {
    for (final fill in beakFills) {
      out = out.replaceAll('fill="$fill"', 'fill="$beakColor"');
    }
    final beakShade = darken(beakColor, 0.72);
    for (final fill in beakShadeFills) {
      out = out.replaceAll('fill="$fill"', 'fill="$beakShade"');
    }
  }
  out = out.replaceAll(
      'fill="$kBeakFill"', 'fill="${beakColor ?? naturalBeak ?? shade}"');
  for (final fill in _bodyMainFills) {
    out = out.replaceAll('fill="$fill"', 'fill="$bodyColor"');
  }
  out = out.replaceAll('fill="$_bodyShadeFill"', 'fill="$shade"');
  out = out.replaceAll('fill="$_bodyLightFill"',
      'fill="${lightColor ?? lighten(bodyColor, 0.45)}"');
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

  /// Height of the right eye when it differs from the left's [h]. Both eyes
  /// share a top edge; the reworked bird's right eye is cut short where its
  /// beak starts, and a full-height cell would be drawn over the beak.
  final int? rightH;

  /// The canvas the cells are measured on. Every pet but the reworked dog is
  /// drawn on the shared one; that pet is wider than it fits and carries its
  /// own, so the eyes it generates have to be placed on the same frame as the
  /// coat they sit on or they land somewhere else entirely.
  final String viewBox;

  const PetEyeGeometry({
    required this.leftX,
    this.rightX,
    required this.y,
    required this.w,
    required this.h,
    this.rightH,
    this.viewBox = _eyeViewBox,
  });

  /// True when the pet shows a single eye, so odd-eyed has nothing to act on.
  bool get isSingle => rightX == null;

  String _rect(int x, String fill, [int? height]) =>
      '<rect fill="$fill" x="$x" y="$y" width="$w" height="${height ?? h}"/>';
}

/// Cat eyes: two 16x20 cells. Also the fallback for any pet without an entry.
const PetEyeGeometry kCatEyes =
    PetEyeGeometry(leftX: 80, rightX: 141, y: 69, w: 16, h: 20);

/// Dog eyes: taller and narrower than the cat's, and higher on the canvas
/// because the dog's head sits higher (see the sprite's `_layeredPets`).
const PetEyeGeometry kDogEyes =
    PetEyeGeometry(leftX: 99, rightX: 148, y: 40, w: 11, h: 23);

/// Reworked dog eyes: two 12x24 cells on that pet's own wider canvas, printed
/// by `art_src/gen_dog2.py`. Placeholder, alongside the `dog2_*.svg` art — see
/// the dog's entry in the sprite's `_layeredPets`.
const PetEyeGeometry kDog2Eyes = PetEyeGeometry(
    leftX: 93,
    rightX: 150,
    y: 79,
    w: 12,
    h: 24,
    viewBox: '-36.5 -114.3784 255 376.7568');

/// Reworked cat, bird and rabbit eyes, printed by `art_src/gen_rework.py` on
/// the reworked dog's wider canvas. Placeholders, alongside the `cat2_*`,
/// `bird2_*` and `rabbit2_*` art — see the entries in the sprite's
/// `_layeredPets`. The reworked bird faces front, so unlike [kBirdEyes] it
/// shows both eyes.
const PetEyeGeometry kCat2Eyes = PetEyeGeometry(
    leftX: 83,
    rightX: 146,
    y: 106,
    w: 12,
    h: 21,
    viewBox: '-36.5 -114.3784 255 376.7568');
const PetEyeGeometry kBird2Eyes = PetEyeGeometry(
    leftX: 100,
    rightX: 139,
    y: 124,
    w: 12,
    h: 21,
    rightH: 15,
    viewBox: '-36.5 -114.3784 255 376.7568');
const PetEyeGeometry kRabbit2Eyes = PetEyeGeometry(
    leftX: 82,
    rightX: 142,
    y: 124,
    w: 12,
    h: 24,
    viewBox: '-36.5 -114.3784 255 376.7568');

/// Reworked raccoon eyes, printed by `art_src/gen_rework.py`. Placeholder,
/// alongside the `raccoon2_*` art.
const PetEyeGeometry kRaccoon2Eyes = PetEyeGeometry(
    leftX: 94,
    rightX: 152,
    y: 94,
    w: 12,
    h: 20,
    viewBox: '-36.5 -114.3784 255 376.7568');

/// Reworked axolotl eyes, printed by `art_src/gen_rework.py`. Placeholder,
/// alongside the `axolotl2_*` art.
const PetEyeGeometry kAxolotl2Eyes = PetEyeGeometry(
    leftX: 103,
    rightX: 159,
    y: 130,
    w: 12,
    h: 24,
    viewBox: '-36.5 -114.3784 255 376.7568');

/// Reworked penguin eyes, printed by `art_src/gen_rework.py`. Alongside the
/// `penguin2_*` art, which replaces the roster penguin.
const PetEyeGeometry kPenguin2Eyes = PetEyeGeometry(
    leftX: 90,
    rightX: 136,
    y: 140,
    w: 8,
    h: 14,
    viewBox: '-36.5 -114.3784 255 376.7568');

/// Bird eye: one 8x15 cell. The chick is drawn in profile, so the far eye is
/// on the side of its head nobody can see.
const PetEyeGeometry kBirdEyes = PetEyeGeometry(leftX: 121, y: 92, w: 8, h: 15);

// The three cell-map pets. Unlike the trio above, whose numbers were read out
// of hand-separated Inkscape layers, these are printed by their generator
// (`art_src/gen_<pet>.py`) straight off the cell map that draws the pet — so
// they cannot drift from the art as long as they are copied across after an
// edit. All three draw on a 6-unit cell against the trio's 7-9.

/// Rabbit eyes: two 12x18 cells, low on a tall head with the ears above it.
const PetEyeGeometry kRabbitEyes =
    PetEyeGeometry(leftX: 87, rightX: 135, y: 100, w: 12, h: 18);

/// Hamster eyes: two 12x12 cells. The squarest pair of the set, on a pet
/// that is mostly cheek.
const PetEyeGeometry kHamsterEyes =
    PetEyeGeometry(leftX: 75, rightX: 123, y: 106, w: 12, h: 12);

/// Parrot eye: one 12x12 cell, and the highest on the canvas of any pet —
/// it is perched on a stand. Drawn in profile like the chick, so there is no
/// second cell.
const PetEyeGeometry kParrotEyes =
    PetEyeGeometry(leftX: 114, y: 16, w: 12, h: 12);

// The roster pets. Same construction as the three above -- printed straight
// off the art by the generator that draws them (`art_src/gen_roster_pets.py`)
// and pasted here, so they cannot drift from the sprite as long as they are
// copied across after an edit. All twenty-four draw on a 2-unit cell, the
// finest grid of any pet, which is why their eye cells are the smallest.

/// Fox eyes: two 8x18 cells.
const PetEyeGeometry kFoxEyes =
    PetEyeGeometry(leftX: 121, rightX: 167, y: 112, w: 8, h: 18);

/// Raccoon eyes: two 12x18 cells.
const PetEyeGeometry kRaccoonEyes =
    PetEyeGeometry(leftX: 101, rightX: 151, y: 124, w: 12, h: 18);

/// Red panda eyes: two 10x20 cells.
const PetEyeGeometry kRedPandaEyes =
    PetEyeGeometry(leftX: 114, rightX: 160, y: 118, w: 10, h: 20);

/// Otter eyes: two 10x18 cells.
const PetEyeGeometry kOtterEyes =
    PetEyeGeometry(leftX: 104, rightX: 156, y: 102, w: 10, h: 18);

/// Hedgehog eyes: two 8x16 cells.
const PetEyeGeometry kHedgehogEyes =
    PetEyeGeometry(leftX: 121, rightX: 161, y: 162, w: 8, h: 16);

/// Chinchilla eyes: two 8x16 cells.
const PetEyeGeometry kChinchillaEyes =
    PetEyeGeometry(leftX: 107, rightX: 149, y: 120, w: 8, h: 16);

/// Squirrel eyes: two 8x16 cells.
const PetEyeGeometry kSquirrelEyes =
    PetEyeGeometry(leftX: 132, rightX: 174, y: 128, w: 8, h: 16);

/// Mouse eyes: two 8x16 cells.
const PetEyeGeometry kMouseEyes =
    PetEyeGeometry(leftX: 111, rightX: 151, y: 140, w: 8, h: 16);

/// Bat eyes: two 10x18 cells.
const PetEyeGeometry kBatEyes =
    PetEyeGeometry(leftX: 101, rightX: 145, y: 132, w: 10, h: 18);

/// Fennec eyes: two 8x16 cells.
const PetEyeGeometry kFennecEyes =
    PetEyeGeometry(leftX: 84, rightX: 126, y: 136, w: 8, h: 16);

/// Skunk eyes: two 8x16 cells.
const PetEyeGeometry kSkunkEyes =
    PetEyeGeometry(leftX: 138, rightX: 176, y: 130, w: 8, h: 16);

/// Beaver eyes: two 8x16 cells.
const PetEyeGeometry kBeaverEyes =
    PetEyeGeometry(leftX: 125, rightX: 169, y: 112, w: 8, h: 16);

/// Koala eyes: two 10x16 cells.
const PetEyeGeometry kKoalaEyes =
    PetEyeGeometry(leftX: 82, rightX: 130, y: 120, w: 10, h: 16);

/// Wombat eyes: two 8x16 cells.
const PetEyeGeometry kWombatEyes =
    PetEyeGeometry(leftX: 105, rightX: 159, y: 134, w: 8, h: 16);

/// Panda eyes: two 10x14 cells.
const PetEyeGeometry kPandaEyes =
    PetEyeGeometry(leftX: 87, rightX: 133, y: 110, w: 10, h: 14);

/// Sloth eyes: two 10x16 cells.
const PetEyeGeometry kSlothEyes =
    PetEyeGeometry(leftX: 97, rightX: 149, y: 108, w: 10, h: 16);

/// Capybara eyes: one 8x16 cell. Drawn side-on, so there is no second cell.
const PetEyeGeometry kCapybaraEyes =
    PetEyeGeometry(leftX: 108, y: 106, w: 8, h: 16);

/// Piglet eyes: two 10x14 cells.
const PetEyeGeometry kPigletEyes =
    PetEyeGeometry(leftX: 108, rightX: 156, y: 130, w: 10, h: 14);

/// Frog eyes: two 10x16 cells.
const PetEyeGeometry kFrogEyes =
    PetEyeGeometry(leftX: 88, rightX: 148, y: 116, w: 10, h: 16);

/// Axolotl eyes: two 10x18 cells.
const PetEyeGeometry kAxolotlEyes =
    PetEyeGeometry(leftX: 92, rightX: 144, y: 138, w: 10, h: 18);

/// Gecko eyes: two 10x18 cells.
const PetEyeGeometry kGeckoEyes =
    PetEyeGeometry(leftX: 116, rightX: 176, y: 112, w: 10, h: 18);

/// Chameleon eyes: two 10x18 cells.
const PetEyeGeometry kChameleonEyes =
    PetEyeGeometry(leftX: 136, rightX: 182, y: 130, w: 10, h: 18);

/// Seal eyes: two 8x16 cells.
const PetEyeGeometry kSealEyes =
    PetEyeGeometry(leftX: 116, rightX: 158, y: 118, w: 8, h: 16);

/// Penguin eyes: two 8x14 cells.
const PetEyeGeometry kPenguinEyes =
    PetEyeGeometry(leftX: 104, rightX: 148, y: 116, w: 8, h: 14);

/// Builds the eyes layer SVG entirely from [spec], so solid / odd-eyed both
/// share the exact eye geometry of the original asset.
///
/// A single-eyed pet always uses [PetColorSpec.eyeColor1]: it has no second
/// cell, so odd-eyed would otherwise silently pick whichever colour happened
/// to be in the slot the pet does not show.
String buildEyesLayer(PetColorSpec spec, [PetEyeGeometry eyes = kCatEyes]) {
  final buffer = StringBuffer(
    '<svg id="katman_1" xmlns="http://www.w3.org/2000/svg" version="1.1" '
    'viewBox="${eyes.viewBox}" shape-rendering="crispEdges">',
  );

  buffer.write(eyes._rect(eyes.leftX, spec.eyeColor1));
  final rightX = eyes.rightX;
  if (rightX != null) {
    buffer.write(eyes._rect(
      rightX,
      spec.eyeMode == EyeMode.heterochromia ? spec.eyeColor2 : spec.eyeColor1,
      eyes.rightH,
    ));
  }

  buffer.write('</svg>');
  return buffer.toString();
}
