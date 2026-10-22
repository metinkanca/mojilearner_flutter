import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/scene_backdrop.dart';
import 'package:mojilearner_flutter/components/scene_thumbnail.dart';
import 'package:mojilearner_flutter/constants/scenes.dart';

import '../helpers/scene_capture.dart';

/// The mushroom glade through the real renderer: that the picture loads from
/// the bundle, comes out in the colours it was drawn in (the jade moss above
/// all), and that sunset and night light the things they promise to.
///
///     flutter test test/widget/mushroom_glade_render_test.dart \
///       --dart-define=SHOT_DIR=shots
void main() {
  const shotDir = String.fromEnvironment('SHOT_DIR');
  final scene = sceneThemeById(kMushroomGladeSceneId)!;
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
  final sky = onScreen(432, 300);
  final ground = onScreen(432, 1600);
  final cap = onScreen(700, 820); // the tall mushroom's red cap
  final spot = onScreen(727, 752); // one of its cream spots
  final stem = onScreen(720, 1000); // its cream stem
  final outline = onScreen(432, 1099); // the ground line, six pixels of ink

  Future<SceneFrame> glade(WidgetTester tester, SceneTime time) => captureScene(
        tester,
        SceneBackdrop(scene: scene, time: time),
        phone,
        asset: asset,
        ready: (f) => f.at(sky).a > 0,
      );

  testWidgets('the glade paints in the colours the art was drawn in',
      (tester) async {
    final frame = await glade(tester, SceneTime.day);
    saveShot(shotDir, 'glade_day', frame);

    expect(frame.at(sky), const Color(0xFFA8DCEF));
    // The point of the recolour: jade, not the yellow-green it started as.
    expect(frame.at(ground), const Color(0xFF5DB89A));
    expect(frame.at(cap), const Color(0xFFE8766A));
    // The spots are a fill of their own in the app's copy, one unit of blue
    // off the stems' cream so that night can tell them apart. Not visible.
    expect(frame.at(spot), const Color(0xFFF6F0DD));
    expect(frame.at(stem), const Color(0xFFF6F0DC));
  });

  testWidgets('the moss is cooler than a lawn', (tester) async {
    final frame = await glade(tester, SceneTime.day);
    final hsl = HSLColor.fromColor(frame.at(ground));
    // Yellow-green is ~97 degrees; jade is well into the greens-toward-blue.
    expect(hsl.hue, inInclusiveRange(140, 175));
  });

  testWidgets('sunset and night recolour it, and the caps light up',
      (tester) async {
    final day = await glade(tester, SceneTime.day);
    final sunset = await glade(tester, SceneTime.sunset);
    final night = await glade(tester, SceneTime.night);
    saveShot(shotDir, 'glade_sunset', sunset);
    saveShot(shotDir, 'glade_night', night);

    expect(sunset.at(sky), isNot(day.at(sky)));
    expect(night.at(sky), isNot(day.at(sky)));
    expect(sunset.at(ground), isNot(day.at(ground)));
    expect(night.at(ground), isNot(day.at(ground)));

    // The cap is the one named light: exactly its lit colour at night, and
    // brighter than the dark glade it stands in.
    expect(night.at(cap), const Color(0xFFFF9AA0));
    expect(night.at(cap).computeLuminance(),
        greaterThan(night.at(sky).computeLuminance()));
    expect(night.at(cap).computeLuminance(),
        greaterThan(night.at(ground).computeLuminance()));

    // The outline is the drawing: the same black at every hour, not
    // dusk-brown or night-navy.
    for (final frame in [day, sunset, night]) {
      expect(frame.at(outline), const Color(0xFF14120E));
    }

    // Cream is not a light, so the stems go dark with the rest. If they stayed
    // bright the night would have no depth.
    expect(night.at(stem).computeLuminance(),
        lessThan(night.at(cap).computeLuminance()));
  });

  // The spots are part of the cap, so they are not dimmed with the stems: at
  // night they are the cream they were drawn in, exactly, and so the brightest
  // thing on the cap. By day and at dusk they are tinted like everything else.
  testWidgets('the spots on the caps keep their colour at night',
      (tester) async {
    final day = await glade(tester, SceneTime.day);
    final sunset = await glade(tester, SceneTime.sunset);
    final night = await glade(tester, SceneTime.night);

    expect(night.at(spot), const Color(0xFFF6F0DC));
    expect(night.at(spot).computeLuminance(),
        greaterThan(night.at(cap).computeLuminance()));
    // ...while the stem under them is still dark.
    expect(night.at(stem), isNot(night.at(spot)));
    expect(night.at(stem).computeLuminance(), lessThan(0.1));

    expect(sunset.at(spot), isNot(day.at(spot)));
  });

  // A cap that is lit is flat colour; a cap that shines lights the air round
  // it. This is bare sky just above the tall cap, well clear of its outline and
  // inside the first two rings of its halo.
  testWidgets('at night the caps light the sky around them, and only then',
      (tester) async {
    final halo = onScreen(708, 680);
    final far = onScreen(432, 680); // the same height, nowhere near a cap

    final day = await glade(tester, SceneTime.day);
    final sunset = await glade(tester, SceneTime.sunset);
    final night = await glade(tester, SceneTime.night);

    expect(day.at(halo), day.at(far));
    expect(sunset.at(halo), sunset.at(far));

    expect(night.at(halo).computeLuminance(),
        greaterThan(night.at(far).computeLuminance()));
    // It is the cap's own colour showing through, not some other light.
    expect(night.at(halo).r, greaterThan(night.at(far).r));
    expect(night.at(halo).r - night.at(far).r,
        greaterThan(night.at(halo).b - night.at(far).b));
  });

  // Outlines this thin cover only part of a screen pixel at phone size, so
  // their edges are antialiased against whatever is painted under them. The
  // picture is built so that is the neighbouring fill. When it was instead
  // every fill stacked up, the topmost of them - here the caps, lit pink at
  // night - showed as a pale line along every border.
  //
  // The stretch of ground line between the two mushroom clusters is the place
  // to look: at night it is nothing but dark sky, dark moss and black, with no
  // cap anywhere near it, so anything bright there can only be a leak.
  testWidgets('no pale fringe hugs the ground line at night', (tester) async {
    final night = await glade(tester, SceneTime.night);

    final from = onScreen(360, 1060);
    final to = onScreen(480, 1110);
    var brightest = 0.0;
    var where = Offset.zero;
    for (var y = from.dy.ceil(); y < to.dy.floor(); y++) {
      for (var x = from.dx.ceil(); x < to.dx.floor(); x++) {
        final l =
            night.at(Offset(x.toDouble(), y.toDouble())).computeLuminance();
        if (l > brightest) {
          brightest = l;
          where = Offset(x.toDouble(), y.toDouble());
        }
      }
    }
    expect(brightest, lessThan(0.08),
        reason: 'a pale pixel at $where on the ground line at night: '
            '${night.at(where)}');
  });

  // The tile is a square slice of a tall picture; the glade asks for the one
  // from just above the tallest cap to well below the ground line. A red cap
  // and the jade moss are both in it, and the fallback bands have neither.
  testWidgets('the wardrobe tile shows the toadstools and the moss',
      (tester) async {
    const tile = 110.0;
    // Alignment(0, 0.1) on a square tile: the slice starts this far down.
    const top = (1872 - 864) * (0.1 + 1) / 2;
    Offset inTile(double artX, double artY) =>
        Offset(artX * tile / 864, (artY - top) * tile / 864);

    final frame = await captureScene(
      tester,
      SceneThumbnail(scene: scene, size: tile),
      const Size(tile, tile),
      asset: asset,
      ready: (f) => f.at(inTile(700, 820)) == const Color(0xFFE8766A),
    );
    saveShot(shotDir, 'glade_tile', frame);

    expect(frame.at(inTile(700, 820)), const Color(0xFFE8766A)); // cap
    expect(frame.at(inTile(432, 1300)), const Color(0xFF5DB89A)); // moss
  });
}
