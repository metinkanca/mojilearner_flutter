import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/scenes.dart';
import 'package:mojilearner_flutter/constants/season_pass.dart';
import 'package:mojilearner_flutter/constants/shop.dart';
import 'package:mojilearner_flutter/utils/scene_recolor.dart';

/// The catalogue has to line up with the shop's on both sides: a background
/// on sale with no scene behind it is a purchase that does nothing — which is
/// exactly the state these scenes were added to fix — and a scene with no way
/// to reach it is one nobody can ever have.
void main() {
  final soldBackgrounds =
      shopItems.where((i) => i.type == 'background').toList();

  test('every background on sale has a scene to show', () {
    for (final item in soldBackgrounds) {
      expect(sceneThemeById(item.id), isNotNull,
          reason: '${item.id} is sold but paints nothing');
    }
  });

  // Three routes and no fourth: free, bought, or claimed off a pass track.
  // A world reachable by none of them is art nobody will ever see, and one
  // reachable by two is the lane confusion `passLocked` exists to prevent —
  // a pass tier that hands over something the player could have bought.
  test('every scene is free, buyable or pass content, and only one of them',
      () {
    for (final scene in kSceneThemes) {
      final routes = [
        if (isFreeScene(scene.id)) 'free',
        if (shopItemById(scene.id) != null) 'shop',
        if (seasonPassForScene(scene.id) != null) 'pass',
      ];
      expect(routes, hasLength(1),
          reason: '${scene.id} is reachable by $routes');
    }
  });

  // The pass says which scene it hands over; this file says which scenes are
  // pass content. Neither can be edited alone.
  test('the pass scenes and isPassScene agree', () {
    final onATrack = {
      for (final pass in seasonPasses) ...pass.sceneIds,
    };
    expect(onATrack, isNotEmpty);
    for (final id in onATrack) {
      expect(sceneThemeById(id), isNotNull,
          reason: '$id is a pass tier but paints nothing');
      expect(isPassScene(id), isTrue,
          reason: '$id is on a track but not gated');
    }
    for (final scene in kSceneThemes) {
      if (!isPassScene(scene.id)) continue;
      expect(onATrack, contains(scene.id),
          reason: '${scene.id} is gated behind a pass no track carries');
    }
  });

  test('the default scene is free, and no free scene is for sale', () {
    expect(isFreeScene(kDefaultSceneId), isTrue);
    expect(kDefaultScene.id, kDefaultSceneId);
    for (final scene in kSceneThemes.where((s) => isFreeScene(s.id))) {
      expect(shopItemById(scene.id), isNull, reason: '${scene.id} is free');
    }
  });

  // The room replaced the meadow as the starting look, not as a free option:
  // a player who liked the old home screen can still put it back.
  test('the cozy room is the default and the meadow is still free', () {
    expect(kDefaultSceneId, kCozyRoomSceneId);
    expect(kDefaultScene.asset, isNotNull);
    expect(isFreeScene(kMeadowSceneId), isTrue);
    expect(sceneThemeById(kMeadowSceneId), isNotNull);
    // Free means these four and no others: the room, the meadow it replaced,
    // the enchanted meadow, and the mushroom glade. A fifth would be a
    // decision, not a drift.
    expect(
      kSceneThemes.where((s) => isFreeScene(s.id)).map((s) => s.id).toSet(),
      {
        kCozyRoomSceneId,
        kMeadowSceneId,
        kEnchantedMeadowSceneId,
        kMushroomGladeSceneId,
      },
    );
  });

  // The room is a picture, so its bands are only a stand-in: they should be
  // the same wall and floor, not the meadow's sky and grass.
  test('the cozy room horizon sits where the picture\'s floor does', () {
    expect(kDefaultScene.horizon, closeTo(1054 / 1846, 1e-9));
  });

  // Two worlds are pass content, one per season, and neither is for sale.
  test('the pumpkin patch is season two\'s world and cannot be bought', () {
    final patch = sceneThemeById(kPumpkinPatchSceneId)!;
    expect(isPassScene(patch.id), isTrue);
    expect(isFreeScene(patch.id), isFalse);
    expect(shopItemById(patch.id), isNull);
    expect(seasonPassForScene(patch.id)?.id, kSeasonTwoId);
    expect(
      kSceneThemes.where((s) => isPassScene(s.id)).map((s) => s.id).toSet(),
      {kAirfieldSceneId, kPumpkinPatchSceneId},
    );
  });

  // The faces are what make the patch worth visiting at night, so night has to
  // name them: the yellow in the windows and faces, the orange pumpkins, and a
  // halo at each lit thing. A re-export that drops one is a dark patch.
  test('the pumpkin patch lights its windows, faces and pumpkins at night', () {
    final night = sceneThemeById(kPumpkinPatchSceneId)!.nightTint;
    expect(night.lights.keys, containsAll([0xF9DF62, 0xFB8630]));
    expect(night.glow, isNotNull);
    expect(night.glow!.halos, hasLength(6));
    // The first layer the halo sits behind must be one the art draws, or it is
    // spliced nowhere and nothing glows.
    final svg =
        File('assets/svgs/pumpkin_patch.svg').readAsStringSync();
    expect(
      svg.contains(
          '<path fill="#${night.glow!.under.toRadixString(16).padLeft(6, '0')}"'),
      isTrue,
    );
  });

  test('scene ids are unique', () {
    final ids = kSceneThemes.map((s) => s.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('an unknown id still gives the render path something to draw', () {
    expect(sceneThemeById('bg_atlantis'), isNull);
    expect(sceneThemeOrDefault('bg_atlantis').id, kDefaultSceneId);
    expect(sceneThemeOrDefault(null).id, kDefaultSceneId);
  });

  // Every scene keeps the day/night cycle rather than freezing one mood, so
  // buying a world never costs the player the sky they already had.
  test('every scene has all three times of day', () {
    for (final scene in kSceneThemes) {
      for (final time in SceneTime.values) {
        final palette = scene.paletteFor(time);
        expect(palette.groundSpecks, isNotEmpty,
            reason: '${scene.id} at $time has no ground decor');
      }
    }
  });

  // The drawings are the one thing on any scene that is not a scatter, and
  // the reason `SceneMotif` exists: their parts are placed inside their own
  // canvas so they cannot drift apart on a wider screen. Everything here is
  // generated by `art_src/gen_airfield.py`, so what these pin is that the
  // generator and the palettes still agree.
  test('the airfield draws the same scene at every time of day', () {
    final airfield = sceneThemeById(kAirfieldSceneId)!;
    for (final time in SceneTime.values) {
      final palette = airfield.paletteFor(time);
      expect(palette.skyMotifs, isNotEmpty,
          reason: 'the airfield at $time has an empty sky');
      expect(palette.groundMotifs, isNotEmpty,
          reason: 'the airfield at $time has nothing on the apron');

      for (final motif in [...palette.skyMotifs, ...palette.groundMotifs]) {
        expect(motif.blocks, isNotEmpty);
        for (final block in motif.blocks) {
          expect(block.x + block.width, lessThanOrEqualTo(motif.width),
              reason: 'a block runs off the motif canvas');
          expect(block.y + block.height, lessThanOrEqualTo(motif.height),
              reason: 'a block runs off the motif canvas');
          // An ink past the end of the list draws nothing, so a palette that
          // is short of one silently loses part of a drawing. Better to hear
          // about it here than to wonder where the windows went.
          expect(block.ink, lessThan(palette.motifInks.length),
              reason: 'ink ${block.ink} at $time has no colour');
        }
      }
    }
  });

  // The whole point of taking colour from the palette rather than from the
  // art: one set of drawings, three times of day, no second copy to keep in
  // step.
  test('the airfield redraws nothing between times of day', () {
    final airfield = sceneThemeById(kAirfieldSceneId)!;
    final day = airfield.day;
    for (final time in SceneTime.values) {
      final palette = airfield.paletteFor(time);
      expect(identical(palette.skyMotifs, day.skyMotifs), isTrue,
          reason: '$time flies a different aircraft');
      expect(identical(palette.groundMotifs, day.groundMotifs), isTrue);
      // ...and the inks differ, or there was no reason to index them.
      if (time != SceneTime.day) {
        expect(palette.motifInks, isNot(day.motifInks), reason: '$time');
      }
    }
  });

  test('no other scene carries a motif', () {
    for (final scene in kSceneThemes) {
      if (scene.id == kAirfieldSceneId) continue;
      for (final time in SceneTime.values) {
        expect(scene.paletteFor(time).skyMotifs, isEmpty,
            reason: '${scene.id} at $time');
        expect(scene.paletteFor(time).groundMotifs, isEmpty,
            reason: '${scene.id} at $time');
      }
    }
  });

  // A world that is a picture still has to be a palette underneath: the bands
  // are what paints while the asset loads and if it is ever missing, so the
  // one must not be deleted in favour of the other.
  test('a scene with an asset still has bands to fall back to', () {
    for (final scene in kSceneThemes) {
      if (scene.asset == null) continue;
      expect(scene.asset, startsWith('assets/'));
      for (final time in SceneTime.values) {
        expect(scene.paletteFor(time).groundSpecks, isNotEmpty,
            reason: '${scene.id} at $time has no fallback');
      }
      // Daylight is what the art is drawn in; the other two are computed.
      expect(scene.tintFor(SceneTime.day).isIdentity, isTrue);
      expect(scene.tintFor(SceneTime.sunset).isIdentity, isFalse);
      expect(scene.tintFor(SceneTime.night).isIdentity, isFalse);
      // ...and night has to put the lights on, or a terminal reads as a ruin.
      expect(scene.tintFor(SceneTime.night).lights, isNotEmpty);
    }
  });

  // A horizon is where a world stops being sky and starts being somewhere the
  // pet stands. It has to leave room for both.
  test('every horizon leaves sky above and ground below', () {
    for (final scene in kSceneThemes) {
      expect(scene.horizon, greaterThan(0.3), reason: scene.id);
      expect(scene.horizon, lessThan(0.9), reason: scene.id);
    }
  });

  test('the time bands match the ones the home screen used to compute', () {
    expect(sceneTimeAt(DateTime(2026, 1, 1, 5)), SceneTime.night);
    expect(sceneTimeAt(DateTime(2026, 1, 1, 6)), SceneTime.day);
    expect(sceneTimeAt(DateTime(2026, 1, 1, 16)), SceneTime.day);
    expect(sceneTimeAt(DateTime(2026, 1, 1, 17)), SceneTime.sunset);
    expect(sceneTimeAt(DateTime(2026, 1, 1, 19)), SceneTime.sunset);
    expect(sceneTimeAt(DateTime(2026, 1, 1, 20)), SceneTime.night);
    expect(sceneTimeAt(DateTime(2026, 1, 1, 23)), SceneTime.night);
  });

  // A tint names its lights by colour, so it only works while the art still
  // contains that colour. Re-export the picture with a different glass and the
  // window quietly stops glowing at night; this is where that gets noticed.
  group('a scene picture', () {
    final fill = RegExp(r'fill="#([0-9a-fA-F]{6})"');

    for (final scene in kSceneThemes.where((s) => s.asset != null)) {
      final svg = File(scene.asset!).readAsStringSync();
      final fills = {
        for (final m in fill.allMatches(svg)) int.parse(m[1]!, radix: 16),
      };

      test('${scene.id}: the file exists and has fills to recolour', () {
        expect(fills, isNotEmpty);
      });

      test('${scene.id}: every light is a colour the art really uses', () {
        for (final time in SceneTime.values) {
          for (final lit in scene.tintFor(time).lights.keys) {
            expect(fills, contains(lit),
                reason: '${scene.id} at $time lights 0x'
                    '${lit.toRadixString(16)}, which is not in the picture');
          }
        }
      });

      // A glow is spliced in ahead of the layer it names, so that layer has to
      // exist, and the outline has to come after it or the light would wash
      // the outline too.
      test('${scene.id}: every glow sits behind a layer the art really has',
          () {
        for (final time in SceneTime.values) {
          final glow = scene.tintFor(time).glow;
          if (glow == null) continue;
          final under = svg.indexOf(
              '<path fill="#${glow.under.toRadixString(16).padLeft(6, '0')}"');
          expect(under, greaterThan(0),
              reason: '${scene.id} at $time puts its light behind 0x'
                  '${glow.under.toRadixString(16)}, which is not in the picture');
          expect(svg.indexOf('<path fill="#14120e"'), greaterThan(under),
              reason: '${scene.id}: the outline must be painted after the light');
          expect(glow.halos, isNotEmpty);
        }
      });

      test('${scene.id}: only night has a glow', () {
        expect(scene.tintFor(SceneTime.day).glow, isNull);
        expect(scene.tintFor(SceneTime.sunset).glow, isNull);
      });

      // The outline is the drawing. Pushed toward dusk it turns brown and at
      // night navy, which reads as the art having changed rather than the time.
      test('${scene.id}: the outline is the same black at every time of day',
          () {
        expect(svg, contains('fill="#14120e"'));
        for (final time in SceneTime.values) {
          final out = recolorSceneSvg(svg, scene.tintFor(time));
          expect(out, contains('fill="#14120e"'),
              reason: '${scene.id} at $time recoloured its outline');
        }
      });

      test('${scene.id}: recolouring leaves well-formed fills only', () {
        for (final time in SceneTime.values) {
          final out = recolorSceneSvg(svg, scene.tintFor(time));
          // Same number of fills in, same number out, each still six digits:
          // a light written with an alpha byte would come out as eight. The
          // only fills added are the rings of a glow, one path per ring.
          final rings = scene.tintFor(time).glow?.steps.length ?? 0;
          expect(RegExp(r'fill="#').allMatches(out).length,
              RegExp(r'fill="#').allMatches(svg).length + rings);
          expect(fill.allMatches(out).length,
              fill.allMatches(svg).length + rings,
              reason: '${scene.id} at $time produced a malformed fill');
        }
      });
    }
  });
}
