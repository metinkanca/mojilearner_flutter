import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/boss_trial/climb_map.dart';
import 'package:mojilearner_flutter/components/boss_trial/trial_boss.dart';
import 'package:mojilearner_flutter/constants/boss_climb_art.dart';

import '../helpers/scene_capture.dart';

/// The climb's floors through the real renderer.
///
/// The unit test pins the table against the pictures' headers; this is the
/// check that matters to a player: each picture loads from the bundle, survives
/// flutter_svg, and has a pad of stone exactly where the map puts a stop's
/// number. A stop that landed beside its pad would be a button on bare ground.
///
///     flutter test test/widget/boss_climb_render_test.dart \
///       --dart-define=SHOT_DIR=shots
void main() {
  const shotDir = String.fromEnvironment('SHOT_DIR');

  for (final (i, art) in climbFloorArt.indexed) {
    testWidgets('floor ${i + 1}: every stop is over a pad of stone',
        (tester) async {
      const width = 390.0;
      final cell = width / art.width;
      final size = Size(width, ClimbFloorView.extentFor(width, art));
      final ground = Color(art.ground);
      Offset onScreen(double x, double y) => Offset(x * cell, y * cell);

      // The start stone, at the foot of every floor, is the first thing to
      // tell the picture from the ground it is laid on.
      final start = onScreen(art.width / 2, art.height - 8);

      final frame = await captureScene(
        tester,
        ClimbFloorView(
          art: art,
          boss: TrialBosses.all[i],
          floor: i + 1,
          playerLevel: 1,
          onStop: (_, __) {},
        ),
        size,
        asset: art.asset,
        ready: (f) => f.at(start) != ground,
      );
      saveShot(shotDir, 'climb_floor_${i + 1}', frame);

      // Inside the pad but clear of the number on it: most of the way to its
      // edge on the right. Its colour is the stone's, or the moss's, and in
      // either case not the ground's.
      for (final (k, (x, y)) in art.stops.indexed) {
        final inside = onScreen(x + art.pad / 2 * 0.7, y);
        expect(frame.at(inside), isNot(ground),
            reason: 'floor ${i + 1}, stop ${k + 1} is not over its pad');
      }

      // And the picture has drawn its outline in the scenes' ink, not in a
      // blend of it and the ground: straight above the first pad's middle,
      // within a couple of cells of where the table puts its top edge (a pad is
      // an ellipse of its own size, which is the table's only for the widest),
      // there is a pixel of pure ink.
      final (x, y) = art.stops.first;
      var darkest = 1.0;
      for (var dy = -3.0; dy <= 3.0; dy += 0.25) {
        final here = frame.at(onScreen(x, y - art.pad / 2 + dy));
        darkest = math.min(darkest, here.computeLuminance());
      }
      expect(darkest, lessThan(0.05),
          reason: 'floor ${i + 1}: the first pad has no outline where the '
              'table says its edge is');
    });
  }
}
