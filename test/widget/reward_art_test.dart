import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/reward_art.dart';
import 'package:mojilearner_flutter/constants/progression.dart';

/// The daily cycle is drawn twice — the claim dialog's row of boxes and the
/// profile's weekly sheet — and it used to be drawn by two hand-written emoji
/// maps. The profile's had gone stale: it knew the apple, the coffee and the
/// pizza, so the donut and both sushi days came out as a generic gift box.
///
/// [RewardArt] replaced both by reading the catalogue, which is what stops it
/// falling behind again. These tests hold the two ends of that: every reward
/// the cycle can actually hand out resolves to art, and a reward naming
/// something the shop no longer sells falls back rather than mis-drawing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every daily reward resolves to art', () {
    for (final reward in dailyRewards) {
      if (reward.type == RewardType.coins) continue;
      expect(
        rewardShopItem(reward),
        isNotNull,
        reason: '${reward.description} names an item the shop does not sell, '
            'so it would be drawn as the generic present',
      );
      expect(
        rewardShopItem(reward)!.art,
        isNotNull,
        reason: '${reward.description} resolves to an item with no pixel art',
      );
    }
  });

  // Both come off `art_src/gen_icons.py`, which builds them through the food
  // generator so they land in the same art set. If either is ever redrawn
  // off-pipeline, this is what notices.
  test('the generated icons load and carry the set\'s ink', () async {
    for (final asset in [kGiftAsset, kFlameAsset]) {
      final svg = await rootBundle.loadString(asset);
      expect(svg, contains('#1f2223'),
          reason: '$asset is not outlined in the pets’ ink, so it '
              'will read as a sticker laid on the game');
      expect(svg, contains('shape-rendering="crispEdges"'), reason: asset);
    }
  });

  testWidgets('a reward the shop no longer sells falls back to the present',
      (tester) async {
    const orphan = RewardDef(
      level: 1,
      type: RewardType.item,
      value: 1,
      description: 'a thing the shop dropped',
      itemId: 'no_such_item',
    );

    await tester.pumpWidget(const MaterialApp(
      home: RewardArt(reward: orphan, size: 24),
    ));

    final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect((picture.bytesLoader as SvgAssetLoader).assetName, kGiftAsset);
  });
}
