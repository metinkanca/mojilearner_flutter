import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/scenario_city.dart';
import 'package:mojilearner_flutter/components/scenario_stage.dart';
import 'package:mojilearner_flutter/constants/scenarios.dart';

void main() {
  const layout = CityLayout(6);

  /// How far [p] is from the segment [a]-[b].
  double distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final t = (((p - a).dx * ab.dx + (p - a).dy * ab.dy) /
            (ab.dx * ab.dx + ab.dy * ab.dy))
        .clamp(0.0, 1.0);
    return (p - (a + ab * t)).distance;
  }

  bool isLink(Offset a, Offset b) => layout.pathLinks
      .any((link) => (link.$1 == a && link.$2 == b) || (link.$1 == b && link.$2 == a));

  test('no two places claim the same patch of the town', () {
    for (var i = 0; i < layout.places; i++) {
      for (var j = i + 1; j < layout.places; j++) {
        expect(layout.lot(i).overlaps(layout.lot(j)), isFalse,
            reason: 'places $i and $j');
      }
    }
  });

  test('a place\'s door is inside it, and on its own side of the footpath', () {
    for (var i = 0; i < layout.places; i++) {
      final lot = layout.lot(i);
      expect(layout.doorX(i), greaterThan(lot.left), reason: 'place $i');
      expect(layout.doorX(i), lessThan(lot.right), reason: 'place $i');
      expect(layout.doorX(i) < CityLayout.avenueX, CityLayout.isLeftLot(i),
          reason: 'place $i');
    }
  });

  test('the pet stops in front of the door, on the paving', () {
    for (var i = 0; i < layout.places; i++) {
      final spot = layout.doorSpot(i);

      expect(spot.dx, layout.doorX(i), reason: 'place $i');
      expect(spot.dy, layout.pavementLine(i), reason: 'place $i');
      // Below its own building, not on top of it.
      expect(spot.dy, greaterThan(layout.lot(i).top), reason: 'place $i');
    }
  });

  test('every walk goes along the paths, and round the fountain', () {
    final spots = [
      layout.start,
      layout.schoolDoorSpot,
      for (var i = 0; i < layout.places; i++) layout.doorSpot(i),
    ];
    for (final from in spots) {
      for (final to in spots) {
        final legs = layout.route(from, to);
        if (from == to) {
          expect(legs, isEmpty);
          continue;
        }
        expect(legs.last, to, reason: '$from -> $to');
        var at = from;
        for (final next in legs) {
          // Every leg is a whole link between two junctions...
          expect(isLink(at, next), isTrue,
              reason: '$from -> $to leaves the paths at $at -> $next');
          // ...and none of them cuts through the basin.
          expect(distanceToSegment(layout.fountain, at, next),
              greaterThan(100),
              reason: '$from -> $to walks through the fountain at $at -> $next');
          at = next;
        }
      }
    }
  });

  test('a walk can start anywhere: it joins the nearest path first', () {
    // Mid-way along the avenue, and off it on the grass, as when a walk is
    // interrupted by another tap.
    for (final from in [const Offset(512, 1300), const Offset(300, 1300)]) {
      for (var i = 0; i < layout.places; i++) {
        final legs = layout.route(from, layout.doorSpot(i));
        expect(legs.last, layout.doorSpot(i), reason: '$from -> place $i');
        // After the first leg, which reaches the paths, it stays on them.
        var at = legs.first;
        for (final next in legs.skip(1)) {
          expect(
              layout.pathLinks.any((link) =>
                  distanceToSegment(at, link.$1, link.$2) < 0.5 &&
                  distanceToSegment(next, link.$1, link.$2) < 0.5),
              isTrue,
              reason: '$from -> place $i leaves the paths at $at -> $next');
          at = next;
        }
      }
    }
  });

  test('every junction is on the map, and every door is joined to the rest', () {
    final world = Offset.zero & layout.world;
    for (final link in layout.pathLinks) {
      expect(world.contains(link.$1), isTrue, reason: '${link.$1}');
      expect(world.contains(link.$2), isTrue, reason: '${link.$2}');
    }
    for (var i = 0; i < layout.places; i++) {
      expect(
          layout.pathLinks
              .any((link) => link.$1 == layout.doorSpot(i) || link.$2 == layout.doorSpot(i)),
          isTrue,
          reason: 'place $i has no path to its door');
    }
  });

  /// The two numbers off an SVG's viewBox.
  Size viewBoxOf(String asset) {
    final svg = File(asset).readAsStringSync();
    final m = RegExp(r'viewBox="0 0 (\d+) (\d+)"').firstMatch(svg);
    expect(m, isNotNull, reason: asset);
    return Size(double.parse(m!.group(1)!), double.parse(m.group(2)!));
  }

  test("a building's lot is exactly its picture", () {
    // One cell of a building's art is two world units, so the lot is the
    // picture's own size: a lot that drifted from it would squash the art.
    for (var i = 0; i < layout.places; i++) {
      final asset = layout.artAsset(i);
      expect(File(asset).existsSync(), isTrue, reason: asset);
      final cells = viewBoxOf(asset);
      expect(Size(cells.width * 2, cells.height * 2), layout.lot(i).size,
          reason: asset);
    }
  });


  group('the school', () {
    test('stands beside the town hall, on the far side of the avenue from it', () {
      final hall = layout.lot(
          ScenarioCatalog.all.indexWhere((s) => s.id == 'job_interview'));
      final school = layout.schoolLot;

      expect(school.left, greaterThan(CityLayout.avenueX));
      expect(hall.right, lessThan(CityLayout.avenueX));
      // Side by side: the same row, standing on the same sidewalk.
      expect((school.bottom - hall.bottom).abs(), lessThan(4));
      expect(school.overlaps(hall), isFalse);
    });

    test('claims no patch of the town a scenario\'s place has', () {
      for (var i = 0; i < layout.places; i++) {
        expect(layout.schoolLot.overlaps(layout.lot(i)), isFalse,
            reason: 'the school and place $i');
      }
    });

    test('has a door inside it on its own side, and a pavement below it', () {
      final lot = layout.schoolLot;
      final door = layout.schoolDoorSpot;

      expect(door.dx, greaterThan(lot.left));
      expect(door.dx, lessThan(lot.right));
      expect(door.dx > CityLayout.avenueX, !CityLayout.schoolIsLeft);
      expect(door.dy, greaterThan(lot.top));
      expect((Offset.zero & layout.world).contains(door), isTrue);
    });

    test('is joined to the paths, and every place can be walked to from it', () {
      final door = layout.schoolDoorSpot;
      expect(
          layout.pathLinks.any((link) => link.$1 == door || link.$2 == door),
          isTrue,
          reason: 'the school has no path to its door');
      for (var i = 0; i < layout.places; i++) {
        final there = layout.route(door, layout.doorSpot(i));
        final back = layout.route(layout.doorSpot(i), door);
        expect(there.last, layout.doorSpot(i), reason: 'school -> place $i');
        expect(back.last, door, reason: 'place $i -> school');
      }
    });

    test("its lot is exactly its picture, and the picture ships", () {
      final asset = layout.schoolArt;
      expect(File(asset).existsSync(), isTrue, reason: asset);
      final cells = viewBoxOf(asset);
      expect(Size(cells.width * 2, cells.height * 2), layout.schoolLot.size);
    });

    test('is never mistaken for a scenario', () {
      expect(ScenarioCatalog.byId(CityLayout.schoolId), isNull);
    });
  });

  test('the ground picture is the world, 2 units to a cell', () {
    final cells = viewBoxOf(CityLayout.groundAsset);
    expect(Size(cells.width * 2, cells.height * 2), CityLayout.mapSize);
    // The avenue is down the exact middle, which is what the art is mirrored
    // about.
    expect(CityLayout.avenueX * 2, CityLayout.mapSize.width);
  });

  test('every scenario with a place has its room drawn', () {
    for (final scenario in ScenarioCatalog.all) {
      final room = scenarioRoomBackdrop(scenario.id);
      expect(room, isNotNull, reason: scenario.id);
      expect(File(room!).existsSync(), isTrue, reason: room);
    }
  });

  test("a place's card colour is the wall of its room", () {
    // The stage shows this colour until the room's picture has drawn, so a
    // mismatch would flash a different wall for a frame or two.
    for (final scenario in ScenarioCatalog.all) {
      final svg = File(scenarioRoomBackdrop(scenario.id)!).readAsStringSync();
      final wall = RegExp(r'<rect [^>]*fill="#([0-9a-f]{6})"').firstMatch(svg);
      expect(wall, isNotNull, reason: scenario.id);
      expect(scenarioPlaceColor(scenario.id).toARGB32() & 0xFFFFFF,
          int.parse(wall!.group(1)!, radix: 16),
          reason: scenario.id);
    }
  });

  test('the whole town fits on the artwork', () {
    final world = Offset.zero & layout.world;
    expect(layout.world, CityLayout.mapSize);
    for (var i = 0; i < layout.places; i++) {
      // A lot may end on the world's own edge (Rect.contains leaves the far
      // edges out), but never go past it.
      expect(world.contains(layout.lot(i).topLeft), isTrue);
      expect(layout.lot(i).right, lessThanOrEqualTo(world.right));
      expect(layout.lot(i).bottom, lessThanOrEqualTo(world.bottom));
      expect(world.contains(layout.doorSpot(i)), isTrue, reason: 'place $i');
    }
    expect(world.contains(layout.start), isTrue);
    expect(world.contains(layout.fountain), isTrue);
  });
}
