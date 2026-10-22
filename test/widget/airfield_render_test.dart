import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/scene_thumbnail.dart';
import 'package:mojilearner_flutter/constants/scenes.dart';

/// The airfield through the real renderer.
///
/// `art_src/preview_airfield.py` is the loop the art is iterated in, and it
/// reimplements what `SceneThumbnail` does rather than calling it. This is the
/// check that the reimplementation is honest: set SHOT_DIR and compare.
///
///     flutter test test/widget/airfield_render_test.dart \
///       --dart-define=SHOT_DIR=shots
void main() {
  const shotDir = String.fromEnvironment('SHOT_DIR');

  testWidgets('every time of day paints something', (tester) async {
    final airfield = sceneThemeById(kAirfieldSceneId)!;
    for (final time in SceneTime.values) {
      final key = GlobalKey();
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: key,
          child: SceneThumbnail(scene: airfield, size: 360, time: time),
        ),
      ));
      await tester.pump();

      // `toImage` waits on the engine, which never ticks under FakeAsync —
      // run it on the real clock or the test hangs rather than failing.
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ImageByteFormat.png);
        expect(bytes, isNotNull);
        if (shotDir.isNotEmpty) {
          Directory(shotDir).createSync(recursive: true);
          File('$shotDir/real_${time.name}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        }
        image.dispose();
      });
    }
  });
}
