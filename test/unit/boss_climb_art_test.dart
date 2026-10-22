import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/boss_trial/climb_map.dart';
import 'package:mojilearner_flutter/components/boss_trial/trial_boss.dart';
import 'package:mojilearner_flutter/constants/boss_climb_art.dart';
import 'package:mojilearner_flutter/utils/boss_trial.dart';

/// The climb map's art and the numbers the screen lays its stops by are in two
/// places: the pictures under `assets/svgs`, made by `art_src/gen_climb.py`,
/// and the [climbFloorArt] table that file writes beside them. Nothing at run
/// time notices when the two disagree — a stop just lands off its pad, on
/// every screen — so the checks that would be silent are made loud here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<String> read(ClimbFloorArt art) => rootBundle.loadString(art.asset);

  test('every boss has a floor, and a floor has a stop for every level', () {
    expect(climbFloorArt, hasLength(TrialBosses.all.length));
    for (final art in climbFloorArt) {
      expect(art.stops, hasLength(BossTrialRules.levelsPerBoss),
          reason: '${art.asset}: a stop for each opening and the finale');
    }
  });

  test('every picture is the size its table says, on the ground it says',
      () async {
    for (final art in climbFloorArt) {
      final svg = await read(art);

      final box = RegExp(r'viewBox="0 0 (\d+) (\d+)"').firstMatch(svg);
      expect(box, isNotNull, reason: '${art.asset} has no whole-cell viewBox');
      expect((
        double.parse(box!.group(1)!),
        double.parse(box.group(2)!)
      ), (
        art.width,
        art.height
      ), reason: '${art.asset} is not the canvas the table says');

      // The first thing a scene's writer paints is the ground, over the whole
      // canvas: it is what shows before the picture has loaded.
      final ground = RegExp(r'<rect width="\d+" height="\d+" fill="(#\w{6})"')
          .firstMatch(svg);
      expect(ground, isNotNull, reason: '${art.asset} has no ground colour');
      expect(
        int.parse(ground!.group(1)!.substring(1), radix: 16) | 0xFF000000,
        art.ground,
        reason: '${art.asset}: the table has another ground colour',
      );
    }
  });

  test('every floor is a home scene\'s shape, with its pads the same size', () {
    // Each picture is drawn on a pixel grid of its own, so the cell counts
    // differ from floor to floor; what must not is the shape (the scenes' 864
    // by 1872) and how much of it a pad takes, or the stops, which the screen
    // sizes by the pad, would be bigger on one floor than the next.
    for (final art in climbFloorArt) {
      expect(art.height / art.width, closeTo(1872 / 864, 0.03),
          reason: '${art.asset} is not a home scene\'s shape');
      expect(art.pad / art.width,
          closeTo(climbFloorArt.first.pad / climbFloorArt.first.width, 0.01),
          reason: '${art.asset}: its pad is another size than the first\'s');
    }
  });

  test('the stops are on the picture and wind up it, a level a stop', () {
    for (final art in climbFloorArt) {
      var above = art.height;
      for (final (x, y) in art.stops) {
        expect(x - art.pad / 2, greaterThan(0),
            reason: '${art.asset}: a pad runs off the left');
        expect(x + art.pad / 2, lessThan(art.width),
            reason: '${art.asset}: a pad runs off the right');
        expect(y + art.pad / 2, lessThan(above),
            reason: '${art.asset}: a stop is not above the one before it');
        expect(y - art.pad / 2, greaterThan(0),
            reason: '${art.asset}: a pad runs off the top');
        above = y - art.pad / 2;
      }
    }
  });

  test('a stop has room beside it for its name, on the side it leans from', () {
    // A stop left of the middle puts its name on its left, and the other on
    // its right; the strip has to fit on the picture either way.
    for (final art in climbFloorArt) {
      // The strip's width is the pad's, scaled, so in cells it is the same
      // fraction of the pad as in points.
      final room = ClimbStop.roomFor(art.pad);
      for (final (x, _) in art.stops) {
        if (x < art.width / 2) {
          expect(x - art.pad / 2 - room, greaterThanOrEqualTo(0),
              reason: '${art.asset}: no room on the left for a name');
        } else {
          expect(x + art.pad / 2 + room, lessThanOrEqualTo(art.width),
              reason: '${art.asset}: no room on the right for a name');
        }
      }
    }
  });
}
