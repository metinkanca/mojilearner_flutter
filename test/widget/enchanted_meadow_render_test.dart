import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/scene_backdrop.dart';
import 'package:mojilearner_flutter/components/scene_thumbnail.dart';
import 'package:mojilearner_flutter/constants/scenes.dart';

import '../helpers/scene_capture.dart';

/// The enchanted meadow through the real renderer: that the picture loads from
/// the bundle, comes out in the colours it was drawn in, and that sunset and
/// night light the things they promise to.
///
///     flutter test test/widget/enchanted_meadow_render_test.dart \
///       --dart-define=SHOT_DIR=shots
void main() {
  const shotDir = String.fromEnvironment('SHOT_DIR');
  final scene = sceneThemeById(kEnchantedMeadowSceneId)!;
  final asset = scene.asset!;

  // A phone-width box with the picture covering it, bottom-anchored. The
  // picture is 864 across and 1872 down, which is this box's proportion, so
  // the whole of it shows.
  const phone = Size(390, 845);
  const scale = 390 / 864;
  Offset onScreen(double artX, double artY) =>
      Offset(artX * scale, phone.height - (1872 - artY) * scale);

  // Spots that are flat colour in the daylight art, each at least a few
  // pixels from anything else so a fractional scale still lands inside.
  final sky = onScreen(640, 250);
  final ground = onScreen(432, 1600);
  final crater = onScreen(280, 90);
  final stem = onScreen(644, 1047); // a mushroom stem: the off-white
  final cap = onScreen(640, 860); // a mushroom cap: the gold
  final window = onScreen(215, 832); // a tower window: the mint
  final outline = onScreen(432, 1083); // the ground line, six pixels of ink

  Future<SceneFrame> meadow(WidgetTester tester, SceneTime time) =>
      captureScene(
        tester,
        SceneBackdrop(scene: scene, time: time),
        phone,
        asset: asset,
        ready: (f) => f.at(sky).a > 0,
      );

  testWidgets('the meadow paints in the colours the art was drawn in',
      (tester) async {
    final frame = await meadow(tester, SceneTime.day);
    saveShot(shotDir, 'meadow_day', frame);

    expect(frame.at(sky), const Color(0xFFD9C8F0));
    expect(frame.at(ground), const Color(0xFF9A7CC8));
    expect(frame.at(crater), const Color(0xFF70549B));
    expect(frame.at(stem), const Color(0xFFF6F0DC));
    expect(frame.at(cap), const Color(0xFFF0A93C));
    expect(frame.at(window), const Color(0xFF8FE3D0));
  });

  testWidgets('sunset and night recolour it, and the crystals light up',
      (tester) async {
    final day = await meadow(tester, SceneTime.day);
    final sunset = await meadow(tester, SceneTime.sunset);
    final night = await meadow(tester, SceneTime.night);
    saveShot(shotDir, 'meadow_sunset', sunset);
    saveShot(shotDir, 'meadow_night', night);

    expect(sunset.at(sky), isNot(day.at(sky)));
    expect(night.at(sky), isNot(day.at(sky)));

    // The named lights, exactly: mint (windows, crystals) and gold (stars,
    // caps) are what an enchanted night has lit.
    expect(sunset.at(window), const Color(0xFFFFE0A8));
    expect(night.at(window), const Color(0xFFB4FFEA));
    expect(night.at(cap), const Color(0xFFF5BC52));

    // The window is the brightest thing in the dark, not just a different
    // colour: lighter than the sky and the ground around it.
    expect(night.at(window).computeLuminance(),
        greaterThan(night.at(sky).computeLuminance()));
    expect(night.at(window).computeLuminance(),
        greaterThan(night.at(ground).computeLuminance()));

    // The outline is the drawing: the same black at every hour, not
    // dusk-brown or night-navy.
    for (final frame in [day, sunset, night]) {
      expect(frame.at(outline), const Color(0xFF14120E));
    }

    // The stone is not a light, so it goes dark with the rest. If it stayed as
    // bright as the lit gold the night would have no depth.
    expect(night.at(stem).computeLuminance(),
        lessThan(night.at(cap).computeLuminance()));
  });

  // A cap that is lit is flat colour; a cap that shines lights the air round
  // it. This is bare sky just above the big mushroom's cap, well clear of its
  // outline and inside the first two rings of its halo.
  testWidgets('at night the mushrooms light the sky around them, and only then',
      (tester) async {
    final halo = onScreen(641, 790);

    final day = await meadow(tester, SceneTime.day);
    final sunset = await meadow(tester, SceneTime.sunset);
    final night = await meadow(tester, SceneTime.night);

    expect(day.at(halo), day.at(sky));
    expect(sunset.at(halo), sunset.at(sky));

    expect(night.at(halo).computeLuminance(),
        greaterThan(night.at(sky).computeLuminance()));
    // Gold light on violet: warmer, so red and green rise further than blue.
    expect(night.at(halo).g - night.at(sky).g,
        greaterThan(night.at(halo).b - night.at(sky).b));
  });

  // Outlines this thin cover only part of a screen pixel at phone size, so
  // their edges are antialiased against whatever is painted under them. The
  // picture is built so that is the neighbouring fill. When it was instead
  // every fill stacked up, the topmost of them - the mint of the crystals,
  // `#b4ffea` at night - showed as a pale line along every border.
  //
  // The moon's corner is the place to look: at night it is nothing but dark
  // violet and black, with no star or crystal anywhere near it, so anything
  // bright there can only be a leak.
  testWidgets('no pale fringe hugs the outlines at night', (tester) async {
    final night = await meadow(tester, SceneTime.night);

    // Art (0,0)..(200,200) is well inside the moon: its radius is ~390.
    final to = onScreen(200, 200);
    var brightest = 0.0;
    var where = Offset.zero;
    for (var y = 0; y < to.dy - 1; y++) {
      for (var x = 0; x < to.dx - 1; x++) {
        final l =
            night.at(Offset(x.toDouble(), y.toDouble())).computeLuminance();
        if (l > brightest) {
          brightest = l;
          where = Offset(x.toDouble(), y.toDouble());
        }
      }
    }
    expect(brightest, lessThan(0.06),
        reason: 'a pale pixel at $where on the moon at night: '
            '${night.at(where)}');
  });

  // The tile is a square slice of a tall picture; the meadow asks for the one
  // holding the crystals, the tower and the mushrooms. A mushroom cap is gold
  // and the fallback bands have no gold ground in them, so it is the probe.
  testWidgets('the wardrobe tile shows the mushrooms', (tester) async {
    const tile = 110.0;
    // Alignment(0, -0.13) on a square tile: the slice starts this far down.
    const top = (1872 - 864) * (-0.13 + 1) / 2;
    Offset inTile(double artX, double artY) =>
        Offset(artX * tile / 864, (artY - top) * tile / 864);

    final frame = await captureScene(
      tester,
      SceneThumbnail(scene: scene, size: tile),
      const Size(tile, tile),
      asset: asset,
      ready: (f) => f.at(inTile(640, 860)) == const Color(0xFFF0A93C),
    );
    saveShot(shotDir, 'meadow_tile', frame);

    expect(frame.at(inTile(640, 860)), const Color(0xFFF0A93C)); // cap
    expect(frame.at(inTile(215, 832)), const Color(0xFF8FE3D0)); // window
  });
}
