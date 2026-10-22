import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/scene_backdrop.dart';
import 'package:mojilearner_flutter/components/scene_thumbnail.dart';
import 'package:mojilearner_flutter/constants/scenes.dart';

import '../helpers/scene_capture.dart';

/// The pumpkin patch through the real renderer: that the picture loads from
/// the bundle, comes out in the colours it was drawn in, and that sunset and
/// night light the things they promise to - the windows, the faces and the
/// pumpkins themselves.
///
///     flutter test test/widget/pumpkin_patch_render_test.dart \
///       --dart-define=SHOT_DIR=shots
void main() {
  const shotDir = String.fromEnvironment('SHOT_DIR');
  final scene = sceneThemeById(kPumpkinPatchSceneId)!;
  final asset = scene.asset!;

  // A phone-width box with the picture covering it, top-anchored like the home
  // screen. The picture is 852 across and 1845 down, which is this box's
  // proportion, so the whole of it shows.
  const phone = Size(390, 845);
  const scale = 845 / 1845;
  Offset onScreen(double artX, double artY) =>
      Offset(artX * scale, artY * scale);

  // Spots that are flat colour in the daylight art, each at least a few
  // cells from anything else so a fractional scale still lands inside.
  final sky = onScreen(430, 100);
  final grass = onScreen(430, 1700);
  final wall = onScreen(266, 643); // the tower
  final pumpkin = onScreen(60, 1230); // the big pumpkin on the left
  final pane = onScreen(246, 486); // one pane of the tower's round window
  final outline = onScreen(480, 813); // the ground line, six pixels of ink

  Future<SceneFrame> patch(WidgetTester tester, SceneTime time) => captureScene(
        tester,
        SceneBackdrop(
          scene: scene,
          time: time,
          alignment: scene.homeAlignment,
        ),
        phone,
        asset: asset,
        ready: (f) => f.at(sky).a > 0,
      );

  testWidgets('the patch paints in the colours the art was drawn in',
      (tester) async {
    final frame = await patch(tester, SceneTime.day);
    saveShot(shotDir, 'patch_day', frame);

    expect(frame.at(sky), const Color(0xFFB99CD8));
    expect(frame.at(grass), const Color(0xFF88CA62));
    expect(frame.at(wall), const Color(0xFF58348D));
    expect(frame.at(pumpkin), const Color(0xFFFB8630));
    expect(frame.at(pane), const Color(0xFFF9DF62));
    expect(frame.at(outline), const Color(0xFF14120E));
  });

  testWidgets('sunset and night recolour it, and the lit things light up',
      (tester) async {
    final day = await patch(tester, SceneTime.day);
    final sunset = await patch(tester, SceneTime.sunset);
    final night = await patch(tester, SceneTime.night);
    saveShot(shotDir, 'patch_sunset', sunset);
    saveShot(shotDir, 'patch_night', night);

    for (final at in [sky, grass, wall]) {
      expect(sunset.at(at), isNot(day.at(at)));
      expect(night.at(at), isNot(day.at(at)));
    }

    // The window is a named light at both hours, not a tinted yellow.
    expect(sunset.at(pane), const Color(0xFFFFE07A));
    expect(night.at(pane), const Color(0xFFFFE98A));
    expect(night.at(pane).computeLuminance(),
        greaterThan(night.at(sky).computeLuminance()));
    expect(night.at(pane).computeLuminance(),
        greaterThan(night.at(grass).computeLuminance()));

    // The pumpkins are named too: left to the tint they go nearly black, and
    // the point of the scene after dark is a pumpkin with a candle in it. They
    // are warm and brighter than the ground they sit on, and not as bright as
    // a lit window.
    expect(night.at(pumpkin), const Color(0xFF8C4220));
    expect(night.at(pumpkin).computeLuminance(),
        greaterThan(night.at(grass).computeLuminance()));
    expect(night.at(pumpkin).computeLuminance(),
        lessThan(night.at(pane).computeLuminance()));

    // The outline is the drawing: the same black at every hour.
    for (final frame in [day, sunset, night]) {
      expect(frame.at(outline), const Color(0xFF14120E));
    }
  });

  // A pumpkin that is lit is flat colour; one that shines lights the grass
  // round it. This is open grass beside the big pumpkin on the left, inside the
  // first two rings of its halo, against grass the same height and nowhere near
  // either of the big pumpkins.
  testWidgets('at night the faces light the grass around them, and only then',
      (tester) async {
    final halo = onScreen(270, 1290);
    final far = onScreen(430, 1290);

    final day = await patch(tester, SceneTime.day);
    final sunset = await patch(tester, SceneTime.sunset);
    final night = await patch(tester, SceneTime.night);

    expect(day.at(halo), day.at(far));
    expect(sunset.at(halo), sunset.at(far));

    expect(night.at(halo).computeLuminance(),
        greaterThan(night.at(far).computeLuminance()));
    // It is warm light: it adds red, and more of it than blue.
    expect(night.at(halo).r, greaterThan(night.at(far).r));
    expect(night.at(halo).r - night.at(far).r,
        greaterThan(night.at(halo).b - night.at(far).b));
  });

  // Outlines this thin cover only part of a screen pixel at phone size, so
  // their edges are antialiased against whatever is painted under them. The
  // picture is built so that is the neighbouring fill; when it was every fill
  // stacked up, the topmost showed as a pale line along every border.
  //
  // The stretch of ground line between the tower and the cauldron is the place
  // to look: at night it is nothing but dark sky, dark grass and black, with no
  // light anywhere near it, so anything bright there can only be a leak.
  testWidgets('no pale fringe hugs the ground line at night', (tester) async {
    final night = await patch(tester, SceneTime.night);

    final from = onScreen(450, 795);
    final to = onScreen(510, 825);
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

  // The tile is a square slice of a tall picture; the patch asks for the one
  // from just above the hat to the base of the cauldron. The tower and the
  // grass are both in it, and the fallback bands have neither.
  testWidgets('the wardrobe tile shows the tower and the grass',
      (tester) async {
    const tile = 110.0;
    // Alignment(0, -0.62) on a square tile: the slice starts this far down.
    const top = (1845 - 852) * (-0.62 + 1) / 2;
    Offset inTile(double artX, double artY) =>
        Offset(artX * tile / 852, (artY - top) * tile / 852);

    final frame = await captureScene(
      tester,
      SceneThumbnail(scene: scene, size: tile),
      const Size(tile, tile),
      asset: asset,
      ready: (f) => f.at(inTile(266, 643)) == const Color(0xFF58348D),
    );
    saveShot(shotDir, 'patch_tile', frame);

    expect(frame.at(inTile(266, 643)), const Color(0xFF58348D)); // tower
    expect(frame.at(inTile(430, 900)), const Color(0xFF88CA62)); // grass
  });
}
