import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/scene_backdrop.dart';
import 'package:mojilearner_flutter/components/scene_thumbnail.dart';
import 'package:mojilearner_flutter/constants/scenes.dart';

import '../helpers/scene_capture.dart';

/// The cozy room through the real renderer.
///
/// The unit tests pin the catalogue and the recolour; this is the check that
/// the picture actually loads from the bundle, survives flutter_svg, and comes
/// out in the colours the tints promise at each time of day.
///
///     flutter test test/widget/cozy_room_render_test.dart \
///       --dart-define=SHOT_DIR=shots
void main() {
  const shotDir = String.fromEnvironment('SHOT_DIR');
  final scene = sceneThemeById(kCozyRoomSceneId)!;
  final asset = scene.asset!;

  // The room as the home screen lays it out: a phone-width box, the picture
  // covering it and anchored to the bottom.
  const phone = Size(390, 845);
  const scale = 390 / 852; // width-bound: the picture is 852 across

  // Art coordinates -> screen, for the width-bound fit above.
  Offset onScreen(double artX, double artY) =>
      Offset(artX * scale, phone.height - (1846 - artY) * scale);

  // Spots that are flat colour in the daylight art.
  final wall = onScreen(420, 300);
  final floor = onScreen(420, 1700);
  final rug = onScreen(420, 1360);
  final glass = onScreen(190, 670);

  Future<SceneFrame> room(WidgetTester tester, SceneTime time) => captureScene(
        tester,
        SceneBackdrop(scene: scene, time: time),
        phone,
        asset: asset,
        // Nothing but the picture is drawn here, so any opaque pixel is it.
        ready: (f) => f.at(wall).a > 0,
      );

  testWidgets('the room paints in the colours the art was drawn in',
      (tester) async {
    final frame = await room(tester, SceneTime.day);
    saveShot(shotDir, 'room_day', frame);

    expect(frame.at(wall), const Color(0xFFF2E3C6));
    expect(frame.at(floor), const Color(0xFFC58C56));
    expect(frame.at(rug), const Color(0xFFE98A7B));
    expect(frame.at(glass), const Color(0xFFA8DCEF));
  });

  testWidgets('sunset and night recolour it, and the glass stays a light',
      (tester) async {
    final day = await room(tester, SceneTime.day);
    final sunset = await room(tester, SceneTime.sunset);
    final night = await room(tester, SceneTime.night);
    saveShot(shotDir, 'room_sunset', sunset);
    saveShot(shotDir, 'room_night', night);

    expect(sunset.at(wall), isNot(day.at(wall)));
    expect(night.at(wall), isNot(day.at(wall)));

    // The named lights, exactly, not merely "different".
    expect(sunset.at(glass), const Color(0xFFF2B36E));
    expect(night.at(glass), const Color(0xFF3A5CA8));

    // At night the window is a pane of sky, so it must be the brightest thing
    // in the room, brighter than the wall around it.
    expect(night.at(glass).computeLuminance(),
        greaterThan(night.at(wall).computeLuminance()));

    // The outline has to stay darker than what it outlines, or the drawing
    // loses its line. Sampled in the floor's top joint, where wall meets wood.
    final joint = onScreen(300, 1051);
    // ...and it is the same black it was drawn in, not dusk-brown or night-navy.
    expect(sunset.at(joint), const Color(0xFF14120E));
    expect(night.at(joint), const Color(0xFF14120E));
    expect(night.at(joint).computeLuminance(),
        lessThan(night.at(wall).computeLuminance()));
    expect(night.at(joint).computeLuminance(),
        lessThan(night.at(floor).computeLuminance()));
  });

  // The tile is a square slice of a tall picture. The room asks for the slice
  // that holds the window, the shelf and the bed (see `previewAlignment`), so
  // the window glass is the probe: the fallback bands have no sky-blue in them,
  // so seeing it means the picture is there and is cropped where it was asked.
  testWidgets('the wardrobe tile shows the window and the rug', (tester) async {
    const tile = 110.0;
    // Alignment(0, 0.05) on a square tile: the slice starts this far down.
    const top = (1846 - 852) * (0.05 + 1) / 2;
    Offset inTile(double artX, double artY) =>
        Offset(artX * tile / 852, (artY - top) * tile / 852);

    final frame = await captureScene(
      tester,
      SceneThumbnail(scene: scene, size: tile),
      const Size(tile, tile),
      asset: asset,
      ready: (f) => f.at(inTile(190, 670)) == const Color(0xFFA8DCEF),
    );
    saveShot(shotDir, 'room_tile', frame);

    expect(frame.at(inTile(190, 670)), const Color(0xFFA8DCEF)); // glass
    expect(frame.at(inTile(426, 1300)), const Color(0xFFE98A7B)); // rug
  });
}
