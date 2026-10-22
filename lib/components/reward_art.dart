import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/progression.dart';
import '../constants/shop.dart';
import '../screens/coin_shop_screen.dart' show kCoinAsset;
import 'shop_item_icon.dart';

/// The wrapped present: what a reward looks like when the catalogue has no
/// picture of the thing itself.
///
/// Drawn by `art_src/gen_icons.py`, which builds it through the same function
/// the food goes through so it lands in the same art set.
const String kGiftAsset = 'assets/svgs/gift.svg';

/// The streak's flame. Not a reward and never drawn by [RewardArt] - it marks
/// the run of days on the daily dialog's pill - but it comes off the same
/// generator, so its path lives with the other one rather than alone.
const String kFlameAsset = 'assets/svgs/flame.svg';

/// The catalogue entry a reward hands over, or null when the reward is not an
/// item at all - or names one the shop has since dropped.
///
/// The daily dialog's old lookup fell back to `shopItems.first` on a miss,
/// which drew an apple for a reward that was not one. A miss now falls through
/// to the reward's own description instead.
ShopItem? rewardShopItem(RewardDef reward) {
  final id = reward.itemId;
  if (reward.type != RewardType.item || id == null) return null;
  for (final item in shopItems) {
    if (item.id == id) return item;
  }
  return null;
}

/// One reward drawn as the app's own pixel art rather than a platform emoji.
///
/// The coin is struck art, and every food the cycle hands out has a sprite on
/// the pet's 7-unit grid - the same set the shop and the pet's paws draw from.
/// A reward with no art of its own falls back to the wrapped present, drawn
/// on the same grid by the same generator - so the fallback belongs to the set
/// rather than being the one platform emoji left standing in it.
///
/// It lives out here rather than inside the daily dialog because the same
/// cycle is drawn twice: once on the dialog's row of boxes, and once on the
/// profile's weekly sheet. Those were two separate hand-written emoji maps,
/// and the profile's had gone stale - it knew the apple, the coffee and the
/// pizza, so the donut and both sushi days were drawn as a generic gift box.
/// One widget reading the catalogue cannot fall behind it.
class RewardArt extends StatelessWidget {
  const RewardArt({super.key, required this.reward, required this.size});

  final RewardDef reward;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (reward.type == RewardType.coins) {
      return SvgPicture.asset(kCoinAsset, width: size, height: size);
    }

    final item = rewardShopItem(reward);
    if (item != null) {
      return ShopItemIcon(item: item, size: size);
    }

    return SvgPicture.asset(kGiftAsset, width: size, height: size);
  }
}
