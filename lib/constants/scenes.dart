/// The worlds the pet can live in.
///
/// The home screen scene is drawn, not photographed: a flat sky band, a flat
/// ground band, a celestial body and a handful of hard-edged specks. A
/// "background" from the shop is therefore not a wallpaper but a palette plus
/// a decor list — which is what lets a bought scene keep the pixel look, the
/// pet's contact shadow and the day/night cycle instead of pasting a picture
/// behind all three.
library;

import 'package:flutter/material.dart';

import '../utils/scene_recolor.dart';
import 'theme.dart';

/// The width the decor is authored against.
///
/// Specks and motifs are placed in logical pixels on a canvas this wide, and
/// everywhere smaller — a wardrobe tile, a pass card — scales by its own width
/// over this. A phone is close enough to it that the home screen draws the
/// decor at 1:1.
const double kSceneDesignWidth = 360;

/// Which of a scene's three palettes is showing.
///
/// The bands match what the home screen used to compute inline: day from 6am,
/// sunset from 5pm, night from 8pm.
enum SceneTime { day, sunset, night }

SceneTime sceneTimeAt(DateTime now) {
  final hour = now.hour;
  if (hour < 6 || hour >= 20) return SceneTime.night;
  if (hour >= 17) return SceneTime.sunset;
  return SceneTime.day;
}

/// One hard-edged rectangle of decor — a grass tuft, a wave crest, a star.
///
/// Positioned by fractional alignment rather than pixels so a speck sits in
/// the same place on a phone and a tablet, and sized in logical pixels so it
/// stays a chunky pixel-art block instead of scaling into a smear.
class SceneSpeck {
  /// Alignment within the band, both in [-1, 1] (see [Alignment]).
  final double x;
  final double y;
  final double width;
  final double height;

  /// Scales the speck's colour down for the fainter background details.
  final double opacity;

  const SceneSpeck(
    this.x,
    this.y, {
    this.width = 8,
    this.height = 8,
    this.opacity = 1.0,
  });
}

/// One block inside a [SceneMotif], in the motif's own pixel coordinates.
///
/// Positioned from the motif's top-left rather than by alignment, which is the
/// whole point of the type: a plane whose wings were each placed by fraction
/// would come apart on a wider screen.
class SceneMotifBlock {
  /// Offset from the motif's top-left, in the motif's own pixels.
  final double x;
  final double y;
  final double width;
  final double height;

  /// Which of [ScenePalette.motifInks] this block is drawn in.
  ///
  /// An index rather than a colour, for the reason the specks take theirs from
  /// the palette: the geometry is authored once and every time of day
  /// recolours it, so the aircraft does not have to be redrawn to fly at
  /// night. An index past the end of the list draws nothing, which is how a
  /// half-finished palette fails — quietly and visibly, rather than by
  /// throwing on a frame.
  final int ink;

  final double opacity;

  const SceneMotifBlock(
    this.x,
    this.y,
    this.width,
    this.height, {
    this.ink = 0,
    this.opacity = 1.0,
  });
}

/// A cluster of blocks that has to hold its shape: an aircraft, a control
/// tower, a cloud.
///
/// A [SceneSpeck] is placed by fraction, which is right for scattered decor —
/// a tuft of grass does not care how far it is from the next one. A drawing
/// does: wings placed that way come apart on a wider screen. So a motif is
/// anchored once, by fraction, and everything inside it is laid out in its own
/// pixels and scaled as a unit.
///
/// None of these are written by hand. They are authored on a character grid in
/// `art_src/gen_airfield.py`, which merges the cells into rectangles and
/// generates the consts below; `art_src/preview_airfield.py` draws the same
/// table to a PNG in under a second, which is the loop to iterate the art in.
class SceneMotif {
  /// Where the motif's centre sits in the band, both in [-1, 1].
  final double x;
  final double y;

  /// The motif's own canvas. [blocks] are positioned inside this.
  final double width;
  final double height;

  final List<SceneMotifBlock> blocks;

  const SceneMotif({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.blocks,
  });

  /// How far to shrink this motif to sit on a tile [tileWidth] across.
  ///
  /// The same factor the specks use, so a plane and the runway paint under it
  /// shrink together and the tile is a smaller copy of the screen rather than
  /// a rearrangement of it. Floored, because a thumbnail with the aircraft
  /// rounded out of it is not a thumbnail of this world.
  double scaleFor(double tileWidth) =>
      (tileWidth / kSceneDesignWidth).clamp(0.12, 1.0);
}

/// How one scene looks at one time of day.
class ScenePalette {
  /// The upper band, and the colour the whole screen is painted before the
  /// bands are laid over it.
  final Color sky;

  /// The lower band the pet stands on.
  final Color ground;

  /// The ground's decor and the darker stripe just under the horizon.
  final Color groundDetail;

  /// Sun or moon. Null leaves the sky bare, which is what the meadow does at
  /// sunset — a sun sitting in an orange sky read as a second sun.
  final Color? celestial;

  /// Whether the celestial body carries the moon's soft halo. Deliberately
  /// not tied to [SceneTime]: the galaxy's moon glows at noon.
  final bool celestialGlow;

  /// Sky decor — stars, mostly. Drawn behind the celestial body.
  final List<SceneSpeck> skySpecks;
  final Color skySpeckColor;

  /// Ground decor: tufts, waves, dunes, craters.
  final List<SceneSpeck> groundSpecks;

  /// Decor that is a drawing rather than a scatter. Empty in every scene but
  /// the airfield, whose aircraft is the one thing here that would stop
  /// reading as itself if its parts were placed independently.
  ///
  /// Sky motifs draw over the stars and under the sun; ground motifs draw over
  /// the apron paint, because the one thing on the ground is a shadow and a
  /// shadow falls on the paint.
  final List<SceneMotif> skyMotifs;
  final List<SceneMotif> groundMotifs;

  /// The inks [skyMotifs] are drawn in, indexed by [SceneMotifBlock.ink].
  ///
  /// The order is the art's, not this file's: see `art_src/gen_airfield.py`,
  /// which authors the drawings on a character grid and names one ink per
  /// character. A palette that lists fewer inks than the art uses simply
  /// leaves those blocks unpainted.
  final List<Color> motifInks;

  const ScenePalette({
    required this.sky,
    required this.ground,
    required this.groundDetail,
    this.celestial,
    this.celestialGlow = false,
    this.skySpecks = const [],
    this.skySpeckColor = AppTheme.retroLight,
    this.groundSpecks = const [],
    this.skyMotifs = const [],
    this.groundMotifs = const [],
    this.motifInks = const [],
  });
}

/// A buyable world: three palettes, one per time of day.
///
/// Every scene keeps the cycle rather than freezing one mood, so buying the
/// ocean does not cost the player the night sky they already had.
class SceneTheme {
  final String id;

  /// Fallback name. The shop-catalogue scenes are named through
  /// `ShopItemLocalizer`; this is what the untranslatable places show.
  final String name;

  final ScenePalette day;
  final ScenePalette sunset;
  final ScenePalette night;

  /// Where the horizon sits, as a fraction of the scene's height.
  ///
  /// The meadow and everything derived from it put it at five ninths, which is
  /// what the home screen used to hardcode. A world is allowed its own,
  /// because the horizon is the single thing that decides how much of a scene
  /// is *place* and how much is ground for the pet to stand on — and the two
  /// wants are not the same in every world. The airfield's is high: an
  /// airfield read from the apron is mostly sky, and at five ninths its
  /// buildings sat in a thin strip above an empty half-screen of tarmac.
  ///
  /// The pet is bottom-anchored, so a high horizon still leaves it standing on
  /// the ground; it simply stands nearer the front of it.
  final double horizon;

  /// An SVG to draw instead of the bands, or null for a world that is a
  /// palette.
  ///
  /// The banded scene is still built and still drawn underneath — see
  /// [SceneBackdrop]. A picture takes a frame or two to load and can be
  /// missing altogether, and a world that falls back to a simpler version of
  /// itself is better than one that falls back to nothing.
  final String? asset;

  /// Where the home screen anchors [asset] when the picture is taller than the
  /// space it has, which on a phone it nearly always is.
  ///
  /// Bottom by default: the ground and the horizon are what the pet stands in,
  /// so it is sky that gets cropped. A picture whose top is the point - the
  /// meadow's moon and stars - asks for the top instead, and gives up empty
  /// ground at the bottom.
  final Alignment homeAlignment;

  /// Where a square thumbnail anchors [asset], which is usually far taller than
  /// a tile. Bottom by default, like the home screen: the ground is what the
  /// pet stands in. A room wants more than its floor shown, or the tile is a
  /// picture of boards.
  final Alignment previewAlignment;

  /// How [asset] is recoloured for sunset and night. Ignored without one.
  ///
  /// The picture is exported once, in daylight, and the other two are computed
  /// — see `utils/scene_recolor.dart` for why that is better than exporting
  /// three files.
  final SceneTint sunsetTint;
  final SceneTint nightTint;

  const SceneTheme({
    required this.id,
    required this.name,
    required this.day,
    required this.sunset,
    required this.night,
    this.horizon = 5 / 9,
    this.asset,
    this.homeAlignment = Alignment.bottomCenter,
    this.previewAlignment = Alignment.bottomCenter,
    this.sunsetTint = SceneTint.none,
    this.nightTint = SceneTint.none,
  });

  /// The recolour for [time]. Daylight is what the art was drawn in.
  SceneTint tintFor(SceneTime time) {
    switch (time) {
      case SceneTime.day:
        return SceneTint.none;
      case SceneTime.sunset:
        return sunsetTint;
      case SceneTime.night:
        return nightTint;
    }
  }

  ScenePalette paletteFor(SceneTime time) {
    switch (time) {
      case SceneTime.day:
        return day;
      case SceneTime.sunset:
        return sunset;
      case SceneTime.night:
        return night;
    }
  }

  /// The palette a thumbnail shows. Always the daytime one, so two scenes
  /// side by side in the shop are compared on the same terms rather than one
  /// of them happening to be caught at midnight.
  ScenePalette get preview => day;
}

// --- Decor sets -------------------------------------------------------------
//
// Shared between palettes of the same scene: the grass does not move when the
// sun goes down, only its colour does.

/// The meadow's four tufts, in the two clusters the screen has always drawn.
const List<SceneSpeck> _grassTufts = [
  SceneSpeck(-0.55, -0.55),
  SceneSpeck(-0.45, -0.35),
  SceneSpeck(0.55, 0.05),
  SceneSpeck(0.65, -0.15),
];

/// Denser undergrowth, plus two upright ferns.
const List<SceneSpeck> _fernTufts = [
  SceneSpeck(-0.7, -0.6),
  SceneSpeck(-0.58, -0.4),
  SceneSpeck(-0.62, -0.05, width: 4, height: 14),
  SceneSpeck(0.4, -0.5),
  SceneSpeck(0.52, -0.25),
  SceneSpeck(0.66, 0.1, width: 4, height: 14),
  SceneSpeck(0.0, 0.45, width: 12, height: 6),
];

/// Wave crests: long, flat and lighter than the water, so the ground band
/// reads as a surface rather than a field.
const List<SceneSpeck> _waveCrests = [
  SceneSpeck(-0.6, -0.6, width: 24, height: 4),
  SceneSpeck(0.35, -0.45, width: 16, height: 4),
  SceneSpeck(-0.2, -0.1, width: 20, height: 4),
  SceneSpeck(0.7, 0.05, width: 24, height: 4),
  SceneSpeck(-0.75, 0.4, width: 16, height: 4),
  SceneSpeck(0.15, 0.6, width: 24, height: 4),
];

/// Wind ripples across sand.
const List<SceneSpeck> _duneRipples = [
  SceneSpeck(-0.5, -0.55, width: 28, height: 4),
  SceneSpeck(0.45, -0.3, width: 20, height: 4),
  SceneSpeck(-0.1, 0.05, width: 32, height: 4),
  SceneSpeck(0.7, 0.35, width: 20, height: 4),
  SceneSpeck(-0.65, 0.55, width: 24, height: 4),
];

/// Craters on the moon rock.
const List<SceneSpeck> _craters = [
  SceneSpeck(-0.55, -0.5, width: 14, height: 6),
  SceneSpeck(-0.35, -0.15, width: 6, height: 6),
  SceneSpeck(0.45, -0.4, width: 10, height: 6),
  SceneSpeck(0.62, 0.2, width: 16, height: 6),
  SceneSpeck(-0.15, 0.5, width: 8, height: 6),
];

/// Apron paint.
///
/// One long lead-in line under the horizon, guide lines down both edges and
/// centre marks that grow as they come forward, which is the only perspective
/// available when every mark is an axis-aligned rectangle. The centre marks
/// stop short of the bottom: that is where the pet stands, and a mark it
/// covered would have to be the widest one on screen at exactly the point it
/// is hidden.
const List<SceneSpeck> _apron = [
  // Wider than any screen, so the apron edge runs off both sides rather
  // than stopping short of them on a tablet.
  SceneSpeck(0.0, -0.88, width: 1200, height: 4, opacity: 0.55),
  // Guide lines down both edges, growing as they come forward — the only
  // perspective available when every mark is an axis-aligned rectangle.
  SceneSpeck(-0.9, -0.45, width: 40, height: 5),
  SceneSpeck(-0.9, 0.15, width: 48, height: 5),
  SceneSpeck(-0.9, 0.78, width: 56, height: 5),
  SceneSpeck(0.9, -0.45, width: 40, height: 5),
  SceneSpeck(0.9, 0.15, width: 48, height: 5),
  SceneSpeck(0.9, 0.78, width: 56, height: 5),
  // Centre marks, stopping short of the bottom: that is where the pet
  // stands, and a mark it covered would have to be the widest on screen at
  // exactly the point it is hidden.
  SceneSpeck(0.0, -0.2, width: 34, height: 5, opacity: 0.85),
  SceneSpeck(0.0, 0.35, width: 42, height: 5, opacity: 0.85),
  SceneSpeck(0.0, 0.9, width: 50, height: 5, opacity: 0.85),
];

/// Three tufts on the enchanted meadow's open ground, for the frames before
/// the picture arrives.
const List<SceneSpeck> _meadowFlowers = [
  SceneSpeck(-0.75, -0.55, width: 10, height: 10),
  SceneSpeck(0.7, -0.1, width: 10, height: 10),
  SceneSpeck(-0.35, 0.3, width: 10, height: 10),
];

/// Three tufts of moss on the mushroom glade's open ground, for the frames
/// before the picture arrives. Wider than tall: moss lies flat.
const List<SceneSpeck> _gladeMoss = [
  SceneSpeck(-0.7, -0.5, width: 14, height: 6),
  SceneSpeck(0.6, 0.0, width: 14, height: 6),
  SceneSpeck(-0.25, 0.45, width: 14, height: 6),
];

/// Three tufts of grass on the pumpkin patch's open ground, for the frames
/// before the picture arrives. Wider than tall: grass lies flat.
const List<SceneSpeck> _patchTufts = [
  SceneSpeck(-0.6, -0.4, width: 12, height: 6),
  SceneSpeck(0.5, 0.0, width: 12, height: 6),
  SceneSpeck(-0.1, 0.5, width: 12, height: 6),
];

/// The cozy room's floorboards, as long thin lines across the ground band.
///
/// Placed where the picture's own joints fall, so the bands and the picture
/// agree about where the planks are in the frames before the picture arrives.
const List<SceneSpeck> _floorBoards = [
  SceneSpeck(0.0, -0.88, width: 1200, height: 3, opacity: 0.8),
  SceneSpeck(0.0, -0.69, width: 1200, height: 3, opacity: 0.8),
  SceneSpeck(0.0, -0.50, width: 1200, height: 3, opacity: 0.8),
  SceneSpeck(0.0, -0.27, width: 1200, height: 3, opacity: 0.8),
  SceneSpeck(0.0, -0.01, width: 1200, height: 3, opacity: 0.8),
  SceneSpeck(0.0, 0.27, width: 1200, height: 3, opacity: 0.8),
];

// --- BEGIN GENERATED: art_src/gen_airfield.py ---

/// The pale band along the horizon.
///
/// Generated by `art_src/gen_airfield.py`. Edit the grid
/// there, not the numbers here.
const SceneMotif _haze = SceneMotif(
  x: 0.0,
  y: 1.0,
  width: 1200,
  height: 36,
  blocks: [
    SceneMotifBlock(0, 0, 1200, 18, ink: 9),
    SceneMotifBlock(0, 18, 1200, 18, ink: 6),
  ],
);

/// Cloud, small and high on the left.
///
/// Generated by `art_src/gen_airfield.py`. Edit the grid
/// there, not the numbers here.
const SceneMotif _cloudA = SceneMotif(
  x: -0.78,
  y: -0.76,
  width: 52,
  height: 22,
  blocks: [
    SceneMotifBlock(20, 0, 2, 2, ink: 6),
    SceneMotifBlock(22, 0, 10, 2, ink: 1),
    SceneMotifBlock(18, 2, 18, 4, ink: 1),
    SceneMotifBlock(14, 6, 30, 4, ink: 1),
    SceneMotifBlock(10, 10, 38, 4, ink: 1),
    SceneMotifBlock(2, 14, 8, 4, ink: 6),
    SceneMotifBlock(10, 14, 8, 4, ink: 1),
    SceneMotifBlock(18, 14, 6, 4, ink: 6),
    SceneMotifBlock(24, 14, 16, 4, ink: 1),
    SceneMotifBlock(40, 14, 10, 4, ink: 6),
    SceneMotifBlock(6, 18, 38, 4, ink: 6),
  ],
);

/// Cloud, high on the right.
///
/// Generated by `art_src/gen_airfield.py`. Edit the grid
/// there, not the numbers here.
const SceneMotif _cloudB = SceneMotif(
  x: 0.74,
  y: -0.9,
  width: 54,
  height: 24,
  blocks: [
    SceneMotifBlock(24, 2, 6, 2, ink: 1),
    SceneMotifBlock(22, 4, 8, 2, ink: 1),
    SceneMotifBlock(30, 4, 2, 2, ink: 6),
    SceneMotifBlock(20, 6, 16, 2, ink: 1),
    SceneMotifBlock(12, 8, 32, 4, ink: 1),
    SceneMotifBlock(8, 12, 40, 4, ink: 1),
    SceneMotifBlock(0, 16, 12, 4, ink: 1),
    SceneMotifBlock(12, 16, 6, 4, ink: 6),
    SceneMotifBlock(18, 16, 8, 4, ink: 1),
    SceneMotifBlock(26, 16, 4, 4, ink: 6),
    SceneMotifBlock(30, 16, 6, 4, ink: 1),
    SceneMotifBlock(36, 16, 16, 4, ink: 6),
    SceneMotifBlock(4, 20, 44, 4, ink: 6),
  ],
);

/// Cloud, large, on the left.
///
/// Generated by `art_src/gen_airfield.py`. Edit the grid
/// there, not the numbers here.
const SceneMotif _cloudC = SceneMotif(
  x: -0.9,
  y: -0.04,
  width: 86,
  height: 30,
  blocks: [
    SceneMotifBlock(44, 0, 16, 2, ink: 1),
    SceneMotifBlock(40, 2, 22, 4, ink: 1),
    SceneMotifBlock(62, 4, 2, 2, ink: 6),
    SceneMotifBlock(26, 6, 6, 4, ink: 1),
    SceneMotifBlock(32, 6, 2, 4, ink: 6),
    SceneMotifBlock(36, 6, 2, 4, ink: 6),
    SceneMotifBlock(38, 6, 28, 4, ink: 1),
    SceneMotifBlock(22, 10, 56, 4, ink: 1),
    SceneMotifBlock(18, 14, 64, 4, ink: 1),
    SceneMotifBlock(10, 18, 20, 4, ink: 1),
    SceneMotifBlock(30, 18, 4, 4, ink: 6),
    SceneMotifBlock(34, 18, 18, 4, ink: 1),
    SceneMotifBlock(52, 18, 8, 4, ink: 6),
    SceneMotifBlock(60, 18, 2, 4, ink: 1),
    SceneMotifBlock(62, 18, 4, 4, ink: 6),
    SceneMotifBlock(66, 18, 20, 4, ink: 1),
    SceneMotifBlock(0, 22, 6, 4, ink: 6),
    SceneMotifBlock(10, 22, 74, 2, ink: 6),
    SceneMotifBlock(10, 24, 72, 4, ink: 6),
  ],
);

/// Cloud, low on the right.
///
/// Generated by `art_src/gen_airfield.py`. Edit the grid
/// there, not the numbers here.
const SceneMotif _cloudD = SceneMotif(
  x: 0.94,
  y: 0.3,
  width: 52,
  height: 22,
  blocks: [
    SceneMotifBlock(20, 0, 2, 2, ink: 6),
    SceneMotifBlock(22, 0, 10, 2, ink: 1),
    SceneMotifBlock(18, 2, 18, 4, ink: 1),
    SceneMotifBlock(14, 6, 30, 4, ink: 1),
    SceneMotifBlock(10, 10, 38, 4, ink: 1),
    SceneMotifBlock(2, 14, 8, 4, ink: 6),
    SceneMotifBlock(10, 14, 8, 4, ink: 1),
    SceneMotifBlock(18, 14, 6, 4, ink: 6),
    SceneMotifBlock(24, 14, 16, 4, ink: 1),
    SceneMotifBlock(40, 14, 10, 4, ink: 6),
    SceneMotifBlock(6, 18, 38, 4, ink: 6),
  ],
);

/// Cloud, lowest of the five, just above the roofline. Five clouds at
/// three sizes is what gives a flat sky depth: the big ones read as
/// near, the small ones as far, and no two are the same shape.
///
/// Generated by `art_src/gen_airfield.py`. Edit the grid
/// there, not the numbers here.
const SceneMotif _cloudE = SceneMotif(
  x: 0.24,
  y: 0.62,
  width: 54,
  height: 24,
  blocks: [
    SceneMotifBlock(24, 2, 6, 2, ink: 1),
    SceneMotifBlock(22, 4, 8, 2, ink: 1),
    SceneMotifBlock(30, 4, 2, 2, ink: 6),
    SceneMotifBlock(20, 6, 16, 2, ink: 1),
    SceneMotifBlock(12, 8, 32, 4, ink: 1),
    SceneMotifBlock(8, 12, 40, 4, ink: 1),
    SceneMotifBlock(0, 16, 12, 4, ink: 1),
    SceneMotifBlock(12, 16, 6, 4, ink: 6),
    SceneMotifBlock(18, 16, 8, 4, ink: 1),
    SceneMotifBlock(26, 16, 4, 4, ink: 6),
    SceneMotifBlock(30, 16, 6, 4, ink: 1),
    SceneMotifBlock(36, 16, 16, 4, ink: 6),
    SceneMotifBlock(4, 20, 44, 4, ink: 6),
  ],
);

/// The airliner, and the subject of the scene.
///
/// Generated by `art_src/gen_airfield.py`. Edit the grid
/// there, not the numbers here.
const SceneMotif _plane = SceneMotif(
  x: 0.04,
  y: -0.5,
  width: 204,
  height: 86,
  blocks: [
    SceneMotifBlock(180, 0, 18, 2),
    SceneMotifBlock(178, 2, 2, 4),
    SceneMotifBlock(180, 2, 16, 4, ink: 2),
    SceneMotifBlock(196, 2, 2, 10),
    SceneMotifBlock(176, 6, 2, 2),
    SceneMotifBlock(178, 6, 18, 2, ink: 2),
    SceneMotifBlock(172, 8, 4, 2),
    SceneMotifBlock(176, 8, 20, 2, ink: 2),
    SceneMotifBlock(172, 10, 2, 2),
    SceneMotifBlock(174, 10, 22, 2, ink: 2),
    SceneMotifBlock(170, 12, 2, 4),
    SceneMotifBlock(172, 12, 22, 4, ink: 2),
    SceneMotifBlock(194, 12, 2, 6),
    SceneMotifBlock(168, 16, 2, 2),
    SceneMotifBlock(170, 16, 24, 2, ink: 2),
    SceneMotifBlock(166, 18, 2, 2),
    SceneMotifBlock(168, 18, 24, 2, ink: 2),
    SceneMotifBlock(192, 18, 4, 2),
    SceneMotifBlock(164, 20, 2, 2),
    SceneMotifBlock(166, 20, 24, 2, ink: 2),
    SceneMotifBlock(190, 20, 2, 8),
    SceneMotifBlock(162, 22, 2, 4),
    SceneMotifBlock(164, 22, 26, 4, ink: 2),
    SceneMotifBlock(158, 26, 4, 2),
    SceneMotifBlock(162, 26, 28, 2, ink: 2),
    SceneMotifBlock(156, 28, 2, 4),
    SceneMotifBlock(158, 28, 30, 4, ink: 2),
    SceneMotifBlock(188, 28, 2, 8),
    SceneMotifBlock(152, 32, 4, 2),
    SceneMotifBlock(156, 32, 32, 2, ink: 2),
    SceneMotifBlock(148, 34, 4, 2),
    SceneMotifBlock(152, 34, 36, 2, ink: 2),
    SceneMotifBlock(142, 36, 6, 2),
    SceneMotifBlock(148, 36, 38, 2, ink: 2),
    SceneMotifBlock(186, 36, 2, 2),
    SceneMotifBlock(142, 38, 2, 2),
    SceneMotifBlock(144, 38, 40, 2, ink: 2),
    SceneMotifBlock(184, 38, 2, 4),
    SceneMotifBlock(20, 40, 122, 2),
    SceneMotifBlock(142, 40, 42, 2, ink: 2),
    SceneMotifBlock(16, 42, 4, 2),
    SceneMotifBlock(20, 42, 120, 2, ink: 1),
    SceneMotifBlock(140, 42, 46, 2, ink: 2),
    SceneMotifBlock(186, 42, 4, 2),
    SceneMotifBlock(16, 44, 2, 2),
    SceneMotifBlock(18, 44, 122, 2, ink: 1),
    SceneMotifBlock(140, 44, 48, 2, ink: 2),
    SceneMotifBlock(188, 44, 2, 2),
    SceneMotifBlock(10, 46, 6, 2),
    SceneMotifBlock(16, 46, 124, 2, ink: 1),
    SceneMotifBlock(140, 46, 50, 2, ink: 2),
    SceneMotifBlock(190, 46, 2, 2),
    SceneMotifBlock(8, 48, 2, 2),
    SceneMotifBlock(10, 48, 10, 2, ink: 1),
    SceneMotifBlock(20, 48, 2, 6, ink: 3),
    SceneMotifBlock(22, 48, 118, 2, ink: 1),
    SceneMotifBlock(140, 48, 52, 2, ink: 2),
    SceneMotifBlock(192, 48, 8, 2),
    SceneMotifBlock(6, 50, 2, 4),
    SceneMotifBlock(8, 50, 12, 4, ink: 1),
    SceneMotifBlock(22, 50, 6, 2, ink: 1),
    SceneMotifBlock(28, 50, 2, 2, ink: 3),
    SceneMotifBlock(30, 50, 14, 2, ink: 1),
    SceneMotifBlock(44, 50, 2, 2, ink: 3),
    SceneMotifBlock(46, 50, 14, 2, ink: 1),
    SceneMotifBlock(60, 50, 2, 2, ink: 3),
    SceneMotifBlock(62, 50, 14, 2, ink: 1),
    SceneMotifBlock(76, 50, 2, 2, ink: 3),
    SceneMotifBlock(78, 50, 14, 2, ink: 1),
    SceneMotifBlock(92, 50, 2, 2, ink: 3),
    SceneMotifBlock(94, 50, 14, 2, ink: 1),
    SceneMotifBlock(108, 50, 2, 2, ink: 3),
    SceneMotifBlock(110, 50, 90, 2, ink: 1),
    SceneMotifBlock(200, 50, 2, 2),
    SceneMotifBlock(22, 52, 176, 2, ink: 1),
    SceneMotifBlock(198, 52, 6, 2),
    SceneMotifBlock(2, 54, 4, 2),
    SceneMotifBlock(6, 54, 60, 2, ink: 1),
    SceneMotifBlock(66, 54, 84, 12, ink: 2),
    SceneMotifBlock(150, 54, 36, 2, ink: 1),
    SceneMotifBlock(186, 54, 2, 2),
    SceneMotifBlock(188, 54, 8, 2, ink: 1),
    SceneMotifBlock(196, 54, 2, 2),
    SceneMotifBlock(0, 56, 2, 10),
    SceneMotifBlock(2, 56, 64, 10, ink: 1),
    SceneMotifBlock(150, 56, 34, 2, ink: 1),
    SceneMotifBlock(184, 56, 2, 2),
    SceneMotifBlock(188, 56, 8, 2),
    SceneMotifBlock(150, 58, 26, 2, ink: 1),
    SceneMotifBlock(176, 58, 8, 2),
    SceneMotifBlock(150, 60, 18, 2, ink: 1),
    SceneMotifBlock(168, 60, 8, 2),
    SceneMotifBlock(150, 62, 16, 2, ink: 1),
    SceneMotifBlock(166, 62, 2, 2),
    SceneMotifBlock(150, 64, 6, 2, ink: 1),
    SceneMotifBlock(156, 64, 10, 2),
    SceneMotifBlock(2, 66, 4, 2),
    SceneMotifBlock(6, 66, 60, 2, ink: 1),
    SceneMotifBlock(66, 66, 80, 2, ink: 2),
    SceneMotifBlock(146, 66, 10, 2),
    SceneMotifBlock(6, 68, 2, 2),
    SceneMotifBlock(8, 68, 136, 2, ink: 2),
    SceneMotifBlock(144, 68, 2, 2),
    SceneMotifBlock(8, 70, 8, 2),
    SceneMotifBlock(16, 70, 118, 2, ink: 2),
    SceneMotifBlock(134, 70, 10, 2),
    SceneMotifBlock(16, 72, 60, 2),
    SceneMotifBlock(76, 72, 48, 2, ink: 2),
    SceneMotifBlock(124, 72, 10, 2),
    SceneMotifBlock(76, 74, 2, 8),
    SceneMotifBlock(78, 74, 42, 2, ink: 2),
    SceneMotifBlock(120, 74, 4, 2),
    SceneMotifBlock(78, 76, 40, 2, ink: 2),
    SceneMotifBlock(118, 76, 2, 2),
    SceneMotifBlock(78, 78, 34, 2, ink: 2),
    SceneMotifBlock(112, 78, 8, 2),
    SceneMotifBlock(78, 80, 26, 2, ink: 2),
    SceneMotifBlock(104, 80, 8, 2),
    SceneMotifBlock(78, 82, 2, 2),
    SceneMotifBlock(80, 82, 22, 2, ink: 2),
    SceneMotifBlock(102, 82, 2, 2),
    SceneMotifBlock(80, 84, 24, 2),
  ],
);

/// The low building at the left-hand end of the field.
///
/// Generated by `art_src/gen_airfield.py`. Edit the grid
/// there, not the numbers here.
const SceneMotif _leftBuilding = SceneMotif(
  x: -0.92,
  y: 1.0,
  width: 60,
  height: 20,
  blocks: [
    SceneMotifBlock(6, 4, 54, 2),
    SceneMotifBlock(6, 6, 2, 10),
    SceneMotifBlock(8, 6, 44, 2, ink: 7),
    SceneMotifBlock(52, 6, 6, 2, ink: 2),
    SceneMotifBlock(58, 6, 2, 12),
    SceneMotifBlock(8, 8, 2, 6, ink: 7),
    SceneMotifBlock(10, 8, 8, 6, ink: 3),
    SceneMotifBlock(18, 8, 12, 2, ink: 2),
    SceneMotifBlock(30, 8, 6, 6, ink: 3),
    SceneMotifBlock(36, 8, 2, 2, ink: 8),
    SceneMotifBlock(38, 8, 8, 6, ink: 3),
    SceneMotifBlock(46, 8, 2, 2, ink: 8),
    SceneMotifBlock(48, 8, 8, 6, ink: 3),
    SceneMotifBlock(56, 8, 2, 6, ink: 7),
    SceneMotifBlock(18, 10, 2, 4, ink: 2),
    SceneMotifBlock(20, 10, 8, 4, ink: 3),
    SceneMotifBlock(28, 10, 2, 4),
    SceneMotifBlock(36, 10, 2, 4),
    SceneMotifBlock(46, 10, 2, 4),
    SceneMotifBlock(8, 14, 50, 2, ink: 7),
    SceneMotifBlock(0, 16, 16, 2),
    SceneMotifBlock(16, 16, 42, 2, ink: 8),
    SceneMotifBlock(0, 18, 60, 2),
  ],
);

/// The control tower, standing on the horizon.
///
/// Generated by `art_src/gen_airfield.py`. Edit the grid
/// there, not the numbers here.
const SceneMotif _tower = SceneMotif(
  x: -0.66,
  y: 1.0,
  width: 20,
  height: 72,
  blocks: [
    SceneMotifBlock(8, 6, 2, 10),
    SceneMotifBlock(0, 14, 2, 2),
    SceneMotifBlock(4, 14, 2, 2),
    SceneMotifBlock(0, 16, 12, 2),
    SceneMotifBlock(0, 18, 2, 4),
    SceneMotifBlock(2, 18, 10, 2, ink: 2),
    SceneMotifBlock(12, 18, 2, 4),
    SceneMotifBlock(2, 20, 10, 2, ink: 7),
    SceneMotifBlock(0, 22, 14, 2),
    SceneMotifBlock(0, 24, 4, 4),
    SceneMotifBlock(4, 24, 2, 4, ink: 3),
    SceneMotifBlock(6, 24, 2, 4),
    SceneMotifBlock(8, 24, 2, 4, ink: 3),
    SceneMotifBlock(10, 24, 4, 4),
    SceneMotifBlock(0, 28, 12, 2),
    SceneMotifBlock(0, 30, 2, 40),
    SceneMotifBlock(2, 30, 6, 6, ink: 2),
    SceneMotifBlock(8, 30, 2, 38),
    SceneMotifBlock(2, 36, 2, 32, ink: 2),
    SceneMotifBlock(4, 36, 4, 32, ink: 7),
    SceneMotifBlock(18, 64, 2, 4),
    SceneMotifBlock(2, 68, 4, 2, ink: 8),
    SceneMotifBlock(6, 68, 14, 2),
    SceneMotifBlock(0, 70, 20, 2),
  ],
);

/// The terminal.
///
/// Generated by `art_src/gen_airfield.py`. Edit the grid
/// there, not the numbers here.
const SceneMotif _terminal = SceneMotif(
  x: -0.16,
  y: 1.0,
  width: 148,
  height: 30,
  blocks: [
    SceneMotifBlock(8, 4, 18, 2),
    SceneMotifBlock(42, 4, 36, 2),
    SceneMotifBlock(90, 4, 28, 2),
    SceneMotifBlock(8, 6, 2, 2),
    SceneMotifBlock(10, 6, 14, 2, ink: 7),
    SceneMotifBlock(24, 6, 20, 2),
    SceneMotifBlock(44, 6, 32, 2, ink: 7),
    SceneMotifBlock(76, 6, 16, 2),
    SceneMotifBlock(92, 6, 24, 2, ink: 7),
    SceneMotifBlock(116, 6, 2, 2),
    SceneMotifBlock(8, 8, 4, 2),
    SceneMotifBlock(12, 8, 102, 2, ink: 7),
    SceneMotifBlock(114, 8, 4, 2),
    SceneMotifBlock(6, 10, 2, 2),
    SceneMotifBlock(10, 10, 102, 2),
    SceneMotifBlock(112, 10, 2, 2, ink: 8),
    SceneMotifBlock(114, 10, 2, 8),
    SceneMotifBlock(10, 12, 2, 14),
    SceneMotifBlock(12, 12, 2, 14, ink: 7),
    SceneMotifBlock(14, 12, 2, 6),
    SceneMotifBlock(16, 12, 8, 4, ink: 8),
    SceneMotifBlock(24, 12, 2, 6),
    SceneMotifBlock(26, 12, 8, 4, ink: 8),
    SceneMotifBlock(34, 12, 2, 6),
    SceneMotifBlock(36, 12, 10, 4, ink: 8),
    SceneMotifBlock(46, 12, 2, 6),
    SceneMotifBlock(48, 12, 8, 4, ink: 8),
    SceneMotifBlock(56, 12, 2, 6),
    SceneMotifBlock(58, 12, 8, 4, ink: 8),
    SceneMotifBlock(66, 12, 2, 6),
    SceneMotifBlock(68, 12, 10, 4, ink: 8),
    SceneMotifBlock(78, 12, 2, 6),
    SceneMotifBlock(80, 12, 8, 4, ink: 8),
    SceneMotifBlock(88, 12, 2, 4),
    SceneMotifBlock(90, 12, 10, 4, ink: 8),
    SceneMotifBlock(100, 12, 2, 6),
    SceneMotifBlock(102, 12, 8, 4, ink: 8),
    SceneMotifBlock(110, 12, 2, 6),
    SceneMotifBlock(112, 12, 2, 8, ink: 7),
    SceneMotifBlock(134, 14, 6, 2),
    SceneMotifBlock(16, 16, 8, 2, ink: 3),
    SceneMotifBlock(26, 16, 8, 2, ink: 3),
    SceneMotifBlock(36, 16, 10, 2, ink: 3),
    SceneMotifBlock(48, 16, 8, 2, ink: 3),
    SceneMotifBlock(58, 16, 8, 2, ink: 3),
    SceneMotifBlock(68, 16, 10, 2, ink: 3),
    SceneMotifBlock(80, 16, 8, 2, ink: 3),
    SceneMotifBlock(88, 16, 2, 2, ink: 8),
    SceneMotifBlock(90, 16, 10, 2, ink: 3),
    SceneMotifBlock(102, 16, 8, 2, ink: 3),
    SceneMotifBlock(132, 16, 2, 2, ink: 2),
    SceneMotifBlock(134, 16, 2, 4, ink: 7),
    SceneMotifBlock(136, 16, 2, 4, ink: 6),
    SceneMotifBlock(138, 16, 2, 6),
    SceneMotifBlock(14, 18, 98, 2),
    SceneMotifBlock(114, 18, 2, 2, ink: 8),
    SceneMotifBlock(116, 18, 4, 2),
    SceneMotifBlock(130, 18, 4, 2, ink: 2),
    SceneMotifBlock(14, 20, 2, 6),
    SceneMotifBlock(16, 20, 2, 2, ink: 2),
    SceneMotifBlock(18, 20, 2, 2, ink: 8),
    SceneMotifBlock(20, 20, 24, 2, ink: 7),
    SceneMotifBlock(44, 20, 2, 4, ink: 8),
    SceneMotifBlock(46, 20, 2, 4, ink: 7),
    SceneMotifBlock(48, 20, 6, 2, ink: 8),
    SceneMotifBlock(54, 20, 18, 2, ink: 7),
    SceneMotifBlock(72, 20, 2, 2, ink: 8),
    SceneMotifBlock(74, 20, 6, 2, ink: 7),
    SceneMotifBlock(80, 20, 2, 2, ink: 2),
    SceneMotifBlock(82, 20, 32, 2, ink: 7),
    SceneMotifBlock(114, 20, 4, 2),
    SceneMotifBlock(118, 20, 2, 2, ink: 8),
    SceneMotifBlock(120, 20, 10, 2),
    SceneMotifBlock(130, 20, 2, 2, ink: 8),
    SceneMotifBlock(132, 20, 4, 2, ink: 7),
    SceneMotifBlock(136, 20, 2, 2, ink: 3),
    SceneMotifBlock(16, 22, 2, 6, ink: 7),
    SceneMotifBlock(18, 22, 4, 2),
    SceneMotifBlock(22, 22, 22, 2, ink: 7),
    SceneMotifBlock(48, 22, 2, 2, ink: 8),
    SceneMotifBlock(50, 22, 2, 2),
    SceneMotifBlock(52, 22, 2, 4, ink: 8),
    SceneMotifBlock(54, 22, 6, 4),
    SceneMotifBlock(60, 22, 2, 6, ink: 7),
    SceneMotifBlock(62, 22, 12, 2),
    SceneMotifBlock(74, 22, 2, 2, ink: 8),
    SceneMotifBlock(76, 22, 2, 6, ink: 7),
    SceneMotifBlock(78, 22, 6, 6),
    SceneMotifBlock(84, 22, 2, 6, ink: 2),
    SceneMotifBlock(86, 22, 10, 6),
    SceneMotifBlock(96, 22, 2, 6, ink: 7),
    SceneMotifBlock(98, 22, 14, 6),
    SceneMotifBlock(112, 22, 2, 6, ink: 7),
    SceneMotifBlock(114, 22, 2, 2, ink: 2),
    SceneMotifBlock(116, 22, 20, 2, ink: 7),
    SceneMotifBlock(136, 22, 4, 2),
    SceneMotifBlock(18, 24, 34, 2),
    SceneMotifBlock(62, 24, 14, 4),
    SceneMotifBlock(114, 24, 8, 2),
    SceneMotifBlock(122, 24, 2, 2, ink: 2),
    SceneMotifBlock(124, 24, 4, 2),
    SceneMotifBlock(128, 24, 2, 2, ink: 2),
    SceneMotifBlock(130, 24, 6, 2),
    SceneMotifBlock(0, 26, 16, 2),
    SceneMotifBlock(18, 26, 12, 2),
    SceneMotifBlock(30, 26, 2, 2, ink: 7),
    SceneMotifBlock(32, 26, 12, 2),
    SceneMotifBlock(44, 26, 2, 2, ink: 8),
    SceneMotifBlock(46, 26, 14, 2),
    SceneMotifBlock(114, 26, 4, 2, ink: 2),
    SceneMotifBlock(118, 26, 2, 2),
    SceneMotifBlock(120, 26, 4, 2, ink: 2),
    SceneMotifBlock(124, 26, 2, 2),
    SceneMotifBlock(126, 26, 2, 2, ink: 2),
    SceneMotifBlock(128, 26, 8, 2, ink: 3),
    SceneMotifBlock(136, 26, 12, 2),
    SceneMotifBlock(0, 28, 148, 2),
  ],
);

/// An airliner at a stand, off to the right.
///
/// Generated by `art_src/gen_airfield.py`. Edit the grid
/// there, not the numbers here.
const SceneMotif _standAircraft = SceneMotif(
  x: 0.95,
  y: 1.0,
  width: 80,
  height: 26,
  blocks: [
    SceneMotifBlock(52, 0, 6, 2),
    SceneMotifBlock(54, 2, 2, 10),
    SceneMotifBlock(32, 4, 4, 2),
    SceneMotifBlock(32, 6, 2, 6),
    SceneMotifBlock(34, 6, 4, 2, ink: 2),
    SceneMotifBlock(64, 6, 16, 2),
    SceneMotifBlock(8, 8, 2, 2),
    SceneMotifBlock(34, 8, 6, 2, ink: 2),
    SceneMotifBlock(64, 8, 2, 4),
    SceneMotifBlock(66, 8, 12, 2, ink: 7),
    SceneMotifBlock(78, 8, 2, 2),
    SceneMotifBlock(8, 10, 4, 2),
    SceneMotifBlock(34, 10, 8, 2, ink: 2),
    SceneMotifBlock(66, 10, 2, 2, ink: 7),
    SceneMotifBlock(68, 10, 12, 2),
    SceneMotifBlock(8, 12, 2, 4),
    SceneMotifBlock(10, 12, 2, 2, ink: 7),
    SceneMotifBlock(12, 12, 24, 2),
    SceneMotifBlock(36, 12, 6, 2, ink: 2),
    SceneMotifBlock(42, 12, 28, 2),
    SceneMotifBlock(70, 12, 4, 2, ink: 8),
    SceneMotifBlock(74, 12, 4, 2, ink: 3),
    SceneMotifBlock(78, 12, 2, 6),
    SceneMotifBlock(10, 14, 20, 2, ink: 7),
    SceneMotifBlock(30, 14, 2, 2),
    SceneMotifBlock(32, 14, 40, 2, ink: 1),
    SceneMotifBlock(72, 14, 2, 4, ink: 2),
    SceneMotifBlock(74, 14, 2, 4, ink: 3),
    SceneMotifBlock(76, 14, 2, 4, ink: 8),
    SceneMotifBlock(0, 16, 8, 2),
    SceneMotifBlock(8, 16, 4, 2, ink: 3),
    SceneMotifBlock(12, 16, 16, 2, ink: 8),
    SceneMotifBlock(28, 16, 4, 2, ink: 2),
    SceneMotifBlock(32, 16, 6, 2),
    SceneMotifBlock(38, 16, 6, 2, ink: 1),
    SceneMotifBlock(44, 16, 2, 2, ink: 2),
    SceneMotifBlock(46, 16, 2, 2, ink: 8),
    SceneMotifBlock(48, 16, 2, 2, ink: 1),
    SceneMotifBlock(50, 16, 2, 2, ink: 2),
    SceneMotifBlock(52, 16, 10, 2, ink: 1),
    SceneMotifBlock(62, 16, 6, 2, ink: 2),
    SceneMotifBlock(68, 16, 4, 2, ink: 1),
    SceneMotifBlock(0, 18, 2, 2),
    SceneMotifBlock(8, 18, 2, 2),
    SceneMotifBlock(10, 18, 2, 2, ink: 2),
    SceneMotifBlock(12, 18, 32, 2),
    SceneMotifBlock(44, 18, 4, 2, ink: 2),
    SceneMotifBlock(48, 18, 4, 2, ink: 3),
    SceneMotifBlock(52, 18, 8, 2),
    SceneMotifBlock(60, 18, 16, 2, ink: 2),
    SceneMotifBlock(76, 18, 4, 2),
    SceneMotifBlock(2, 20, 10, 2),
    SceneMotifBlock(42, 20, 12, 2),
    SceneMotifBlock(54, 20, 2, 2, ink: 2),
    SceneMotifBlock(56, 20, 4, 2, ink: 1),
    SceneMotifBlock(60, 20, 16, 2),
    SceneMotifBlock(12, 22, 4, 2),
    SceneMotifBlock(48, 22, 2, 2),
    SceneMotifBlock(52, 22, 8, 2),
    SceneMotifBlock(68, 22, 2, 2),
    SceneMotifBlock(16, 24, 8, 2),
    SceneMotifBlock(72, 24, 2, 2),
  ],
);

/// Apron paint, in white. The reference marks its apron in two colours
/// and a `SceneSpeck` can only carry one, so the yellow is specks and
/// the white is these.
///
/// Generated by `art_src/gen_airfield.py`. Edit the grid
/// there, not the numbers here.
const SceneMotif _dashA = SceneMotif(
  x: -0.42,
  y: -0.62,
  width: 16,
  height: 2,
  blocks: [
    SceneMotifBlock(0, 0, 16, 2, ink: 1),
  ],
);

///
///
/// Generated by `art_src/gen_airfield.py`. Edit the grid
/// there, not the numbers here.
const SceneMotif _dashB = SceneMotif(
  x: 0.46,
  y: -0.3,
  width: 16,
  height: 2,
  blocks: [
    SceneMotifBlock(0, 0, 16, 2, ink: 1),
  ],
);

///
///
/// Generated by `art_src/gen_airfield.py`. Edit the grid
/// there, not the numbers here.
const SceneMotif _dashC = SceneMotif(
  x: -0.5,
  y: 0.24,
  width: 16,
  height: 2,
  blocks: [
    SceneMotifBlock(0, 0, 16, 2, ink: 1),
  ],
);

///
///
/// Generated by `art_src/gen_airfield.py`. Edit the grid
/// there, not the numbers here.
const SceneMotif _dashD = SceneMotif(
  x: 0.5,
  y: 0.62,
  width: 16,
  height: 2,
  blocks: [
    SceneMotifBlock(0, 0, 16, 2, ink: 1),
  ],
);

/// The aircraft's shadow, thrown across the apron.
///
/// Generated by `art_src/gen_airfield.py`. Edit the grid
/// there, not the numbers here.
const SceneMotif _planeShadow = SceneMotif(
  x: -0.4,
  y: -0.5,
  width: 60,
  height: 27,
  blocks: [
    SceneMotifBlock(27, 0, 18, 3, ink: 5),
    SceneMotifBlock(21, 3, 21, 3, ink: 5),
    SceneMotifBlock(18, 6, 21, 3, ink: 5),
    SceneMotifBlock(0, 9, 54, 3, ink: 5),
    SceneMotifBlock(0, 12, 60, 3, ink: 5),
    SceneMotifBlock(0, 15, 54, 3, ink: 5),
    SceneMotifBlock(18, 18, 21, 3, ink: 5),
    SceneMotifBlock(21, 21, 21, 3, ink: 5),
    SceneMotifBlock(27, 24, 18, 3, ink: 5),
  ],
);

/// Everything in the sky, back to front: cloud, aircraft, then the
/// buildings standing on the horizon.
const List<SceneMotif> _airfieldSky = [
  _haze,
  _cloudA,
  _cloudB,
  _cloudC,
  _cloudD,
  _cloudE,
  _plane,
  _leftBuilding,
  _tower,
  _terminal,
  _standAircraft,
];

/// Everything on the apron.
const List<SceneMotif> _airfieldGround = [
  _dashA,
  _dashB,
  _dashC,
  _dashD,
  _planeShadow,
];

// --- END GENERATED ---

/// A sparse starfield. Two sizes so it does not read as a regular grid.
const List<SceneSpeck> _stars = [
  SceneSpeck(-0.8, -0.7, width: 4, height: 4),
  SceneSpeck(-0.35, -0.85, width: 3, height: 3),
  SceneSpeck(0.1, -0.6, width: 4, height: 4),
  SceneSpeck(0.55, -0.8, width: 3, height: 3),
  SceneSpeck(0.85, -0.45, width: 4, height: 4),
  SceneSpeck(-0.6, -0.15, width: 3, height: 3),
  SceneSpeck(0.3, -0.2, width: 4, height: 4),
  SceneSpeck(0.72, 0.15, width: 3, height: 3),
  SceneSpeck(-0.15, 0.3, width: 3, height: 3),
];

// --- The catalogue ----------------------------------------------------------

/// The scene every player starts in, and the one an unknown or unowned id
/// falls back to. Free: a pet has to stand somewhere.
const String kDefaultSceneId = kCozyRoomSceneId;

/// The cozy room: a picture of a room rather than a palette, and the home
/// screen every new player starts in.
const String kCozyRoomSceneId = 'bg_cozy_room';

/// The original hand-drawn meadow. It was the default until the room, and is
/// still free, so a player who liked it loses nothing by the change.
const String kMeadowSceneId = 'bg_meadow';

/// The enchanted meadow: a wizard's tower and giant mushrooms under a corner
/// moon, drawn as a picture like the room. Free, and a choice rather than a
/// default.
const String kEnchantedMeadowSceneId = 'bg_enchanted_meadow';

/// The mushroom glade: a clearing of giant toadstools on cool jade moss, drawn
/// as a picture like the room. Free, and a choice rather than a default.
const String kMushroomGladeSceneId = 'bg_mushroom_glade';

/// The airfield's id.
///
/// Named because two places outside this file have to agree on it and neither
/// is the shop: the season pass tier that hands it over, and the wardrobe
/// shelf that has to show it as pass content rather than as an unpriced
/// mistake.
const String kAirfieldSceneId = 'bg_airfield';

/// The pumpkin patch's id, for the same two places: the season two track that
/// hands it over, and the wardrobe shelf that has to show it as pass content.
const String kPumpkinPatchSceneId = 'bg_pumpkin_patch';

/// The outline colour of the picture scenes, which no time of day recolours.
/// Every picture is drawn in the same near-black, so one constant serves.
const Set<int> _ink = {0x14120E};

/// The cozy room: a window with curtains, a shelf with a plant, a pet bed and
/// a round rug, on a wooden floor.
///
/// The home screen every new player starts in, and a picture rather than a
/// palette — see [SceneTheme.asset]. The picture is exported once, in daylight,
/// from `art_src/cozy-room-selected.svg` by `art_src/clean_cozy_room.py`, which
/// also repairs the outlines the trace left behind; sunset and night are
/// computed from it.
///
/// The bands below are the fallback, and are made to look like the picture on
/// purpose: cream wall over a honey floor with the planks drawn in. They are
/// what shows for the frame or two before the asset resolves, so the room
/// should not flash a meadow-green sky at anyone.
const SceneTheme _cozyRoom = SceneTheme(
  id: kCozyRoomSceneId,
  name: 'Cozy Room',
  // The floor meets the wall 1054 rows down a 1846-row picture. Matching it
  // puts the pet's feet on the boards and the rug behind it.
  horizon: 1054 / 1846,
  asset: 'assets/svgs/cozy_room.svg',
  // A square tile of a picture twice its height: this slice runs from just
  // above the window to the top of the rug, so the tile shows the window, the
  // shelf and the bed as well as the boards.
  previewAlignment: Alignment(0, 0.05),
  // Warm light through the glass at dusk. The glass is the one fill that is a
  // light source rather than a surface, so it is named rather than tinted.
  sunsetTint: SceneTint(
    lightness: 0.94,
    hueShift: -4,
    towards: Color(0xFFE0663F),
    towardsAmount: 0.20,
    lights: {0xA8DCEF: 0xF2B36E},
    keep: _ink,
  ),
  // The room goes dim and blue, and the window turns into the brightest thing
  // in it: a pane of night sky, lighter than the wall around it.
  nightTint: SceneTint(
    lightness: 0.52,
    saturation: 0.55,
    towards: Color(0xFF18234F),
    towardsAmount: 0.55,
    lights: {0xA8DCEF: 0x3A5CA8},
    keep: _ink,
  ),
  day: ScenePalette(
    sky: Color(0xFFF2E3C6),
    ground: Color(0xFFC58C56),
    groundDetail: Color(0xFF6C4F32),
    groundSpecks: _floorBoards,
  ),
  sunset: ScenePalette(
    sky: Color(0xFFEABE9A),
    ground: Color(0xFFC77747),
    groundDetail: Color(0xFF814C2F),
    groundSpecks: _floorBoards,
  ),
  night: ScenePalette(
    sky: Color(0xFF524C4D),
    ground: Color(0xFF373444),
    groundDetail: Color(0xFF242539),
    groundSpecks: _floorBoards,
  ),
);

/// The light of the meadow's three mushrooms at night, in the picture's own
/// coordinates: each cap's centre, then a radius about 1.4 times its width and
/// 1.6 times its height. Read off the gold caps in `assets/svgs/enchanted_meadow.svg`
/// (the tower's roof, the stars and the flowers are gold too, and give off
/// nothing), so a re-export that moves a mushroom means moving its halo.
const SceneGlow _meadowMushroomGlow = SceneGlow(
  color: 0xF5BC52,
  // The off-white layer is the first of the objects: the stems, the tower.
  under: 0xF6F0DC,
  halos: [
    SceneHalo(641, 880, 165, 115),
    SceneHalo(728, 996, 78, 56),
    SceneHalo(556, 1010, 76, 58),
  ],
);

/// The light of the glade's seven toadstools at night: each cap's centre, then
/// a radius about 1.4 times its width and 1.6 times its height. Read off the
/// red caps in `assets/svgs/mushroom_glade.svg`.
const SceneGlow _gladeCapGlow = SceneGlow(
  color: 0xFF9AA0,
  // The cream layer is the first of the objects: the stems and the spots.
  under: 0xF6F0DC,
  halos: [
    SceneHalo(708, 785, 190, 130),
    SceneHalo(179, 903, 210, 135),
    SceneHalo(617, 947, 120, 85),
    SceneHalo(679, 1055, 75, 50),
    SceneHalo(119, 1061, 66, 44),
    SceneHalo(776, 1080, 50, 34),
    SceneHalo(205, 1082, 46, 32),
  ],
);

/// The enchanted meadow: a lavender sky with a corner moon and a scatter of
/// stars, floating crystals, a wizard's tower, curly trees and three giant
/// mushrooms along a ground line, with open violet ground below for the pet.
///
/// A picture rather than a palette. It is exported once from
/// `art_src/enchanted-meadow-editable.svg` by `art_src/build_enchanted_meadow.py`
/// and drawn on a 2px grid, so it stays crisp at any phone size.
///
/// Its sky is already a fantasy twilight, so the three times of day are moods
/// laid over it rather than different skies: sunset blushes the whole scene,
/// and night deepens it to indigo while the crystals, tower windows, and
/// everything gold light up.
const SceneTheme _enchantedMeadow = SceneTheme(
  id: kEnchantedMeadowSceneId,
  name: 'Enchanted Meadow',
  // The ground line is drawn 1080 rows down a 1872-row picture, but the home
  // screen shows the picture from the top and crops the empty ground off the
  // bottom, which pulls the line down to about two thirds of a phone's scene.
  // Only the stand-in bands use this, so it is matched to that, not to the art.
  horizon: 0.68,
  asset: 'assets/svgs/enchanted_meadow.svg',
  // The moon and the stars are the point of this picture, so the home screen
  // shows its top and gives up the bare ground at the bottom.
  homeAlignment: Alignment.topCenter,
  // The slice of a square tile that holds the floating crystals, the tower,
  // the mushrooms and the first flowers. The moon is left to the screen.
  previewAlignment: Alignment(0, -0.13),
  sunsetTint: SceneTint(
    lightness: 0.95,
    saturation: 1.05,
    hueShift: -10,
    towards: Color(0xFFFF8A5B),
    towardsAmount: 0.22,
    lights: {0x8FE3D0: 0xFFE0A8},
    keep: _ink,
  ),
  // Mint is the tower windows and every crystal, gold is the stars, caps and
  // roof: the two things that should be lit in an enchanted night.
  nightTint: SceneTint(
    lightness: 0.42,
    saturation: 0.80,
    hueShift: 4,
    towards: Color(0xFF0F1640),
    towardsAmount: 0.50,
    lights: {0x8FE3D0: 0xB4FFEA, 0xF0A93C: 0xF5BC52},
    keep: _ink,
    glow: _meadowMushroomGlow,
  ),
  day: ScenePalette(
    sky: Color(0xFFD9C8F0),
    ground: Color(0xFF9A7CC8),
    groundDetail: Color(0xFF70549B),
    skySpecks: _stars,
    skySpeckColor: Color(0xFFF0A93C),
    groundSpecks: _meadowFlowers,
  ),
  sunset: ScenePalette(
    sky: Color(0xFFD1ACCD),
    ground: Color(0xFF9E75AE),
    groundDetail: Color(0xFF825B88),
    skySpecks: _stars,
    skySpeckColor: Color(0xFFF68434),
    groundSpecks: _meadowFlowers,
  ),
  night: ScenePalette(
    sky: Color(0xFF352463),
    ground: Color(0xFF29224D),
    groundDetail: Color(0xFF201E3F),
    skySpecks: _stars,
    skySpeckColor: Color(0xFFF5BC52),
    groundSpecks: _meadowFlowers,
  ),
);

/// The mushroom glade: seven toadstools, red-capped and cream-spotted, standing
/// along a ground line with clumps of moss at the edges, and open jade moss
/// below for the pet.
///
/// A picture rather than a palette. It is exported once from
/// `art_src/mushroom-glade-editable.svg` by `art_src/build_mushroom_glade.py`
/// and drawn on a 2px grid, so it stays crisp at any phone size.
///
/// The moss is a cool jade (`#5db89a`) rather than a grass green, which is what
/// makes a clearing of giant mushrooms read as enchanted rather than as a lawn.
/// The caps are the one thing worth lighting: at night they glow against the
/// dark moss and throw a halo onto the sky and the ground around them, their
/// spots staying cream, while the stems go dim like everything else.
const SceneTheme _mushroomGlade = SceneTheme(
  id: kMushroomGladeSceneId,
  name: 'Mushroom Glade',
  // The ground line is drawn 1096 rows down a 1872-row picture. Bottom-anchored
  // like the room, so the stand-in bands are matched to the art's own horizon.
  horizon: 1096 / 1872,
  asset: 'assets/svgs/mushroom_glade.svg',
  // A square slice of the tall picture: from just above the tallest cap to well
  // below the ground line, so the tile shows the toadstools and the moss.
  previewAlignment: Alignment(0, 0.1),
  // Rose rather than orange, and no hue shift: an orange dusk over jade pulls it
  // back toward the yellow-green the glade was recoloured away from.
  sunsetTint: SceneTint(
    lightness: 0.96,
    saturation: 1.10,
    towards: Color(0xFFE0709A),
    towardsAmount: 0.28,
    keep: _ink,
  ),
  // Caps are the only light: a glowing toadstool in a dark glade. The blue
  // blend is strong and the saturation low so the cream stems go moonlit
  // grey-blue instead of brown. The spots on the caps are the exception: they
  // are part of what glows, so they go back to exactly the cream they were
  // drawn in. They are a fill of their own, `#f6f0dd`, one unit off the stems'
  // cream, which the build gives them for this (see `Palette.spots` in
  // `art_src/scene_art.py`); by day nobody can tell.
  nightTint: SceneTint(
    lightness: 0.46,
    saturation: 0.70,
    hueShift: 4,
    towards: Color(0xFF0F1A48),
    towardsAmount: 0.58,
    lights: {0xE8766A: 0xFF9AA0, 0xF6F0DD: 0xF6F0DC},
    keep: _ink,
    glow: _gladeCapGlow,
  ),
  day: ScenePalette(
    sky: Color(0xFFA8DCEF),
    ground: Color(0xFF5DB89A),
    groundDetail: Color(0xFF3F8F78),
    groundSpecks: _gladeMoss,
  ),
  // The bands are what the picture's own sky and moss become at each hour,
  // sampled from a render, so the swap when the asset resolves is invisible.
  sunset: ScenePalette(
    sky: Color(0xFFABBBD8),
    ground: Color(0xFF79A598),
    groundDetail: Color(0xFF5A8A7E),
    groundSpecks: _gladeMoss,
  ),
  night: ScenePalette(
    sky: Color(0xFF1D3D64),
    ground: Color(0xFF1C3148),
    groundDetail: Color(0xFF142638),
    groundSpecks: _gladeMoss,
  ),
);

/// The light of the pumpkin patch's six lit things at night: the tower's two
/// windows and the four jack-o'-lanterns with faces. Each is the centre of the
/// lit thing, then radii a little over its own width and height, read off the
/// yellow in `assets/svgs/pumpkin_patch.svg` (the small bubbles and leaves are
/// green and give off nothing), so a re-export that moves one means moving its
/// halo.
const SceneGlow _pumpkinGlow = SceneGlow(
  color: 0xFFB347,
  // The purple layer is the first of the objects: the tower, the cauldron and
  // the stars. Everything after it, the pumpkins and the outline too, covers
  // the light, which keeps it a halo rather than a wash over the lit thing.
  under: 0x58348D,
  cell: 3,
  halos: [
    SceneHalo(262, 501, 90, 100),
    SceneHalo(157, 718, 80, 90),
    SceneHalo(93, 822, 120, 100),
    SceneHalo(787, 966, 130, 110),
    SceneHalo(97, 1287, 215, 190),
    SceneHalo(754, 1293, 215, 190),
  ],
);

/// The pumpkin patch: a crooked witch's house, a bubbling cauldron and a crowd
/// of pumpkins on green grass under a lavender sky, with open grass between the
/// two drifts of pumpkins for the pet.
///
/// Season two's pass content, and not for sale — see
/// `constants/season_pass.dart`. It is named for what is in it, not for the
/// night it suggests: the pass has no expiry, and a world called after a date
/// is a world that visibly aged when somebody claims it in spring (the rule is
/// in SEASON_PASS.md).
///
/// A picture rather than a palette. It was drawn as a PNG, converted once by
/// `art_src/gen_pumpkin_patch.py` into `art_src/pumpkin-patch-editable.svg`,
/// and is built from that by `art_src/build_pumpkin_patch.py`. It is drawn on a
/// 3px grid, six colours, and the outline is two cells thick.
///
/// The sky is already a twilight, so sunset is a rose blush over all of it
/// rather than an orange one: orange over this green goes acid, which is the
/// look the glade's sunset was moved away from. At night the sky goes indigo
/// and the grass a deep green, and the things that are lit light up: the
/// windows, the faces, and the pumpkins themselves, which go to ember rather
/// than to the near-black the tint would leave them.
const SceneTheme _pumpkinPatch = SceneTheme(
  id: kPumpkinPatchSceneId,
  name: 'Pumpkin Patch',
  // The ground line is drawn 816 rows down a 1845-row picture, but the home
  // screen shows the picture from the top and crops the empty grass off the
  // bottom, so the line sits at about half of a phone's scene. Only the
  // stand-in bands use this, so it is matched to that, not to the art.
  horizon: 0.5,
  asset: 'assets/svgs/pumpkin_patch.svg',
  // The tower's hat, the stars and the leaves are the top third of this
  // picture, so the home screen shows its top and gives up bare grass below.
  homeAlignment: Alignment.topCenter,
  // The slice of a square tile that runs from just above the hat to the base
  // of the cauldron and the first pumpkins.
  previewAlignment: Alignment(0, -0.62),
  sunsetTint: SceneTint(
    lightness: 0.95,
    saturation: 1.05,
    towards: Color(0xFFE0709A),
    towardsAmount: 0.28,
    lights: {0xF9DF62: 0xFFE07A},
    keep: _ink,
  ),
  // Yellow is every window and every face, orange the pumpkins. The pumpkins
  // are named because a tint alone leaves them nearly black, and a candle-lit
  // pumpkin is the point of the scene after dark.
  nightTint: SceneTint(
    lightness: 0.50,
    saturation: 0.80,
    hueShift: 4,
    towards: Color(0xFF0F1640),
    towardsAmount: 0.42,
    lights: {0xF9DF62: 0xFFE98A, 0xFB8630: 0x8C4220},
    keep: _ink,
    glow: _pumpkinGlow,
  ),
  day: ScenePalette(
    sky: Color(0xFFB99CD8),
    ground: Color(0xFF88CA62),
    groundDetail: Color(0xFF5F9E45),
    skySpecks: _stars,
    skySpeckColor: Color(0xFF58348D),
    groundSpecks: _patchTufts,
  ),
  // The bands are what the picture's own sky and grass become at each hour,
  // so the swap when the asset resolves is invisible.
  sunset: ScenePalette(
    sky: Color(0xFFBD85C4),
    ground: Color(0xFF9AB068),
    groundDetail: Color(0xFF7F9556),
    skySpecks: _stars,
    skySpeckColor: Color(0xFF7B418D),
    groundSpecks: _patchTufts,
  ),
  night: ScenePalette(
    sky: Color(0xFF3E2C64),
    ground: Color(0xFF2B4635),
    groundDetail: Color(0xFF20382A),
    skySpecks: _stars,
    skySpeckColor: Color(0xFF221B41),
    groundSpecks: _patchTufts,
  ),
);

/// The original hand-drawn home screen, unchanged. Its numbers are the ones
/// the screen used to hold inline, so an untouched save looks identical.
const SceneTheme _meadow = SceneTheme(
  id: kMeadowSceneId,
  name: 'Meadow',
  day: ScenePalette(
    sky: AppTheme.retroSky,
    ground: AppTheme.retroGrass,
    groundDetail: AppTheme.retroGrassDark,
    celestial: AppTheme.retroAccent,
    groundSpecks: _grassTufts,
  ),
  sunset: ScenePalette(
    sky: Color(0xFFAD401B),
    ground: AppTheme.retroSunsetGrass,
    groundDetail: AppTheme.retroGrassDark,
    groundSpecks: _grassTufts,
  ),
  // No stars, though every bought world has them: the meadow is what the
  // screen looked like before any of this, and a player who has bought
  // nothing should see exactly that.
  night: ScenePalette(
    sky: AppTheme.retroNightSky,
    ground: AppTheme.retroNightGrass,
    groundDetail: AppTheme.retroGrassDark,
    celestial: AppTheme.retroMoon,
    celestialGlow: true,
    groundSpecks: _grassTufts,
  ),
);

/// Ocean Blue: a bright shore sky over deep water.
const SceneTheme _ocean = SceneTheme(
  id: 'bg_blue',
  name: 'Ocean Blue',
  day: ScenePalette(
    sky: Color(0xFF6DC2CA),
    ground: Color(0xFF1E3A8A),
    groundDetail: Color(0xFF597DCE),
    celestial: AppTheme.retroAccent,
    groundSpecks: _waveCrests,
  ),
  sunset: ScenePalette(
    sky: Color(0xFFE08050),
    ground: Color(0xFF23264D),
    groundDetail: Color(0xFFD2AA99),
    groundSpecks: _waveCrests,
  ),
  night: ScenePalette(
    sky: Color(0xFF0B1B3A),
    ground: Color(0xFF1B2A5E),
    groundDetail: Color(0xFF30346D),
    celestial: AppTheme.retroMoon,
    celestialGlow: true,
    skySpecks: _stars,
    groundSpecks: _waveCrests,
  ),
);

/// Forest Green: a pale sky over a shaded glade.
const SceneTheme _forest = SceneTheme(
  id: 'bg_forest',
  name: 'Forest Green',
  day: ScenePalette(
    sky: AppTheme.retroSkyLight,
    ground: Color(0xFF14532D),
    groundDetail: Color(0xFF6DAA2C),
    celestial: AppTheme.retroAccent,
    groundSpecks: _fernTufts,
  ),
  sunset: ScenePalette(
    sky: Color(0xFFC86A2A),
    ground: Color(0xFF123F23),
    groundDetail: Color(0xFF854C30),
    groundSpecks: _fernTufts,
  ),
  night: ScenePalette(
    sky: Color(0xFF140C1C),
    ground: Color(0xFF0D2A18),
    groundDetail: Color(0xFF346524),
    celestial: AppTheme.retroMoon,
    celestialGlow: true,
    skySpecks: _stars,
    groundSpecks: _fernTufts,
  ),
);

/// Sunset Orange: golden hour that keeps its warmth all day, and holds a
/// low sun instead of the bare sky the meadow's own dusk has.
const SceneTheme _dusk = SceneTheme(
  id: 'bg_sunset',
  name: 'Sunset Orange',
  day: ScenePalette(
    sky: Color(0xFFEA580C),
    ground: Color(0xFF9C5B37),
    groundDetail: Color(0xFFE8C39E),
    celestial: Color(0xFFDAD45E),
    groundSpecks: _duneRipples,
  ),
  sunset: ScenePalette(
    sky: Color(0xFFD04648),
    ground: Color(0xFF6E4026),
    groundDetail: Color(0xFFA9714B),
    celestial: AppTheme.retroSunOrange,
    groundSpecks: _duneRipples,
  ),
  night: ScenePalette(
    sky: Color(0xFF442434),
    ground: Color(0xFF46291A),
    groundDetail: Color(0xFF8A5A3B),
    celestial: AppTheme.retroMoon,
    celestialGlow: true,
    skySpecks: _stars,
    groundSpecks: _duneRipples,
  ),
);

/// Galaxy Purple: moon rock under a permanently starred sky. The one scene
/// whose "day" is not daylight — its whole appeal is that it never is.
const SceneTheme _galaxy = SceneTheme(
  id: 'bg_galaxy',
  name: 'Galaxy Purple',
  day: ScenePalette(
    sky: Color(0xFF4C1D95),
    ground: Color(0xFF2A1259),
    groundDetail: Color(0xFF7C4DD6),
    celestial: AppTheme.retroMoon,
    celestialGlow: true,
    skySpecks: _stars,
    groundSpecks: _craters,
  ),
  sunset: ScenePalette(
    sky: Color(0xFF6B2394),
    ground: Color(0xFF331466),
    groundDetail: Color(0xFF9D6BFF),
    celestial: AppTheme.retroMoon,
    celestialGlow: true,
    skySpecks: _stars,
    groundSpecks: _craters,
  ),
  night: ScenePalette(
    sky: Color(0xFF190B33),
    ground: Color(0xFF2E1554),
    groundDetail: Color(0xFF5B3399),
    celestial: AppTheme.retroMoon,
    celestialGlow: true,
    skySpecks: _stars,
    groundSpecks: _craters,
  ),
);

/// Departures: an airfield, under an aircraft that has just left it.
///
/// The season pass's last tier, and the only scene that is neither free nor
/// for sale — see `constants/season_pass.dart`. It is a new world rather than
/// a recolour of one the level ladder already gives away, which is the whole
/// reason a pass may carry it: nothing here is sold back to a player who was
/// going to earn it anyway.
///
/// The one world with a man-made ground and the one with a skyline. Flat
/// tarmac with painted marks reads as nothing else in a catalogue of meadow,
/// water, dunes and moon rock, which is what makes it feel like new content at
/// tile size rather than a fifth tint of an existing one.
///
/// Every drawing on it — aircraft, tower, terminal, clouds, the shadow on the
/// apron — is traced from `art_src/ref_airfield.png` by
/// `art_src/gen_airfield.py` and generated into the block above. The palettes
/// below are the only part written by hand, and the order of
/// [ScenePalette.motifInks] is fixed by that file: line, body, shade, glass,
/// trim, shadow, pale, stone, stoneShade, haze.
///
/// Two of those exist only because one palette has to dress two materials.
/// `body` is the aircraft's white hull and `stone` the terminal's tan
/// concrete; sharing one ink between them made either the aircraft tan or the
/// buildings white. `haze` is the pale band the reference lays along its
/// horizon — its sky runs from deep blue overhead to nearly white at the
/// skyline, and a scene painted in one flat blue loses the depth that gradient
/// was doing.
const SceneTheme _airfield = SceneTheme(
  id: kAirfieldSceneId,
  name: 'Departures',
  // The reference puts its horizon four fifths down and gives the apron the
  // last fifth. Matching that is what makes this read as an airfield seen
  // from the ground rather than as a terminal on a shelf.
  horizon: 0.78,
  day: ScenePalette(
    sky: Color(0xFF7EBDE8),
    ground: Color(0xFFB3A394),
    groundDetail: Color(0xFFE8C15C),
    groundSpecks: _apron,
    skyMotifs: _airfieldSky,
    groundMotifs: _airfieldGround,
    motifInks: [
      Color(0xFF2A2A30),
      Color(0xFFEFF9FD),
      Color(0xFFA0A4A5),
      Color(0xFF96A9B6),
      Color(0xFFC0392B),
      Color(0xFF8E8073),
      Color(0xFFD2ECFB),
      Color(0xFFB4A494),
      Color(0xFF8A7C73),
      Color(0xFFA0D7F6),
    ],
  ),
  // Warm light on everything that faces it, and the glazing goes dark: at this
  // hour a terminal's windows are the one thing on the field not lit yet, and
  // the haze at the horizon is the warmest colour in the scene.
  sunset: ScenePalette(
    sky: Color(0xFFE3664F),
    ground: Color(0xFF7A5A48),
    groundDetail: Color(0xFFF0C87A),
    groundSpecks: _apron,
    skyMotifs: _airfieldSky,
    groundMotifs: _airfieldGround,
    motifInks: [
      Color(0xFF2B2530),
      Color(0xFFF7DFC6),
      Color(0xFFB08D7E),
      Color(0xFF4A3B52),
      Color(0xFFE0663F),
      Color(0xFF6E5344),
      Color(0xFFF0C3A6),
      Color(0xFFC79A7F),
      Color(0xFF966E5C),
      Color(0xFFF0A882),
    ],
  ),
  // The inks swap jobs after dark rather than simply darkening: glass becomes
  // the brightest thing on the field, because a terminal at night *is* its
  // windows, and the hull drops to the grey a landing light leaves.
  night: ScenePalette(
    sky: Color(0xFF0D1B26),
    ground: Color(0xFF2A2F35),
    groundDetail: Color(0xFF7E93A0),
    celestial: AppTheme.retroMoon,
    celestialGlow: true,
    skySpecks: _stars,
    groundSpecks: _apron,
    skyMotifs: _airfieldSky,
    groundMotifs: _airfieldGround,
    motifInks: [
      // Darker than the night sky, not merely dark. The first night palette
      // put the line ink within a few points of the sky behind it, and every
      // drawing lost its outline and read as a soft blob.
      Color(0xFF05080D),
      Color(0xFF6C7883),
      Color(0xFF4A555F),
      Color(0xFFF2C14E),
      Color(0xFFE3664F),
      Color(0xFF1C2026),
      Color(0xFF3E4954),
      Color(0xFF48525C),
      Color(0xFF333C45),
      Color(0xFF1B2C3A),
    ],
  ),
);

/// Every scene, in the order the wardrobe shelves them: the free ones first,
/// then the shop's in catalogue order.
const List<SceneTheme> kSceneThemes = [
  _cozyRoom,
  _enchantedMeadow,
  _mushroomGlade,
  _meadow,
  _ocean,
  _forest,
  _dusk,
  _galaxy,
  // Last, and shelved last: these cannot be bought, so they sit at the end of
  // the row rather than interrupting the priced ones. Oldest pass first.
  _airfield,
  _pumpkinPatch,
];

const SceneTheme kDefaultScene = _cozyRoom;

/// The scene with [id], or null when the id is not in the catalogue — a
/// retired scene in an old save, most likely.
SceneTheme? sceneThemeById(String? id) {
  for (final scene in kSceneThemes) {
    if (scene.id == id) return scene;
  }
  return null;
}

/// The scene with [id], falling back to [kDefaultScene]. For the render path,
/// which must always have something to draw.
SceneTheme sceneThemeOrDefault(String? id) =>
    sceneThemeById(id) ?? kDefaultScene;

/// Whether [id] costs coins. Four scenes are free: the room, the meadow it
/// replaced as the starting look, the enchanted meadow, and the mushroom glade.
bool isFreeScene(String id) =>
    id == kCozyRoomSceneId ||
    id == kMeadowSceneId ||
    id == kEnchantedMeadowSceneId ||
    id == kMushroomGladeSceneId;

/// Whether [id] is season pass content, and therefore not for sale at any
/// price.
///
/// Answered here rather than by looking the id up in `seasonPasses` so the
/// render path never has to know what a pass is. The two lists are checked
/// against each other in `test/unit/constants/scenes_test.dart`.
bool isPassScene(String id) =>
    id == kAirfieldSceneId || id == kPumpkinPatchSceneId;
