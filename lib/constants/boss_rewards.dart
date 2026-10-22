/// What clearing a boss level pays, the first time and never again.
///
/// A fight costs almost nothing to run, so there is no daily limit on
/// entering one. That makes a reward that repeats a coin farm: the same level
/// cleared again and again. So only the first clear of each level pays, and
/// the level gate on the climb is what paces them.
///
/// Sized against `gold.dart`: a casual player earns about 20 coins a day, an
/// accessory costs 100 to 200 and a pet 300. All six bosses once come to 960
/// coins across the 30 levels, one-off — about 6.5% of the catalogue the
/// economy model counts (`test/unit/economy_curve_test.dart` holds it under 8%).
///
/// It pays on a *clear*, never on the grade. The economy rewards activity, not
/// proficiency (`MONETISATION.md`), and a fight's difficulty already follows
/// the player, so a clear means the same thing for everyone.
///
/// Coins go through `UserProvider.addCoins`, not the learning ledger, as ad
/// coins do (`ADS.md`): a fight neither advances the daily taper nor is cut by
/// it.
library;

import 'progression.dart';

class BossRewards {
  BossRewards._();

  /// Coins for the first clear of one of a boss's four openings.
  static const int openingCoins = 15;

  /// Coins for the first clear of a boss's finale.
  static const int finaleCoins = 100;

  /// The care item an opening hands over with its coins, by the opening's place
  /// in its boss's list. One of each, so a boss's four openings stock a little
  /// of everything a pet eats.
  static const List<String> openingItems = ['apple', 'coffee', 'donut', 'pizza'];

  /// What a finale hands over besides its coins: a cure and a proper meal.
  static const List<({String id, int count, String name})> finaleItems = [
    (id: 'medicine', count: 1, name: 'Medicine'),
    (id: 'pizza', count: 1, name: 'Pizza Slice'),
  ];

  static const Map<String, String> _names = {
    'apple': 'Apple',
    'coffee': 'Coffee',
    'donut': 'Donut',
    'pizza': 'Pizza Slice',
    'medicine': 'Medicine',
  };

  /// The first-clear rewards of [step] (counted from 0) of a boss's levels,
  /// which is [level] of the 30. The finale is the last step.
  static List<RewardDef> firstClear({
    required int level,
    required int step,
    required bool finale,
  }) {
    if (finale) {
      return [
        RewardDef(
          level: level,
          type: RewardType.coins,
          value: finaleCoins,
          description: '$finaleCoins coins',
        ),
        for (final item in finaleItems)
          RewardDef(
            level: level,
            type: RewardType.item,
            value: item.count,
            description: item.count > 1 ? '${item.name} x${item.count}' : item.name,
            itemId: item.id,
          ),
      ];
    }
    final id = openingItems[step % openingItems.length];
    return [
      RewardDef(
        level: level,
        type: RewardType.coins,
        value: openingCoins,
        description: '$openingCoins coins',
      ),
      RewardDef(
        level: level,
        type: RewardType.item,
        value: 1,
        description: _names[id] ?? id,
        itemId: id,
      ),
    ];
  }

  /// The coins every first clear pays, level by level, for the economy model.
  /// Index 0 is level 1.
  static List<int> coinsByLevel({
    required int levelsPerBoss,
    required int bosses,
  }) =>
      [
        for (var boss = 0; boss < bosses; boss++)
          for (var step = 0; step < levelsPerBoss; step++)
            step == levelsPerBoss - 1 ? finaleCoins : openingCoins,
      ];
}
