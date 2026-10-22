import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/accessories.dart';
import 'package:mojilearner_flutter/constants/scenes.dart';
import 'package:mojilearner_flutter/constants/season_pass.dart';

/// The pass catalogue is append-only and a claim is an index into a track, so
/// the things worth pinning are the ones a later edit could quietly break:
/// every rung points at something that exists, the XP only goes up, and a
/// second pass does not disturb the first.
void main() {
  test('pass ids and store product ids are unique', () {
    final ids = seasonPasses.map((p) => p.id).toList();
    final products = seasonPasses.map((p) => p.productId).toList();
    expect(ids.toSet().length, ids.length);
    expect(products.toSet().length, products.length);
  });

  test('season one stays first, so "the pass on sale" is still season one', () {
    expect(seasonPasses.first.id, kSeasonOneId);
  });

  test('every rung hands over something that exists, for more XP each time',
      () {
    for (final pass in seasonPasses) {
      var previous = 0;
      for (final tier in pass.tiers) {
        expect(tier.xpFromPurchase, greaterThan(previous),
            reason: '${pass.id} does not rise at ${tier.itemId}');
        previous = tier.xpFromPurchase;
        if (tier.isScene) {
          expect(sceneThemeById(tier.sceneId), isNotNull,
              reason: '${tier.sceneId} is a rung that paints nothing');
        } else {
          expect(accessoryById(tier.accessoryId!), isNotNull,
              reason: '${tier.accessoryId} is a rung that wears nothing');
        }
      }
    }
  });

  // Season two is, for now, one world and no pieces: the pumpkin patch is drawn
  // and wired, the ten rungs that will lead up to it are not. It sits at the
  // XP the finale of an eleven-rung track has, so adding them later does not
  // move it.
  test('season two carries the pumpkin patch, at the finale\'s XP', () {
    final two = seasonPassById(kSeasonTwoId)!;
    expect(two.sceneIds, [kPumpkinPatchSceneId]);
    expect(two.accessoryIds, isEmpty);
    expect(two.tiers.single.xpFromPurchase,
        seasonPassById(kSeasonOneId)!.tiers.last.xpFromPurchase);
    expect(seasonPassForScene(kPumpkinPatchSceneId)?.id, kSeasonTwoId);
    expect(seasonPassForScene(kAirfieldSceneId)?.id, kSeasonOneId);
  });
}
