class ProgressionConstants {
  /// The XP from level 1 to 2, and what each level after adds to the step.
  static const int baseXP = 30;

  /// The growth rate of the XP curve: level n to n+1 costs baseXP · n^rate.
  ///
  /// Was 1.8, which put level 20 at 146,115 XP — around 1.4 years for a
  /// committed daily learner and effectively never for anyone else. Then 1.5
  /// on a base of 100, which still left level 20 a year away and the boss
  /// trials months apart: levelling felt like it had stopped. Now linear on a
  /// base of 30 (owner's call, 2026-09-18): against the ~184 XP/day a daily
  /// learner earns, the bosses at 5/10/15/20/25/30 land at about 2, 7, 17,
  /// 31, 49 and 71 days, and every level costs the same 30 XP more than the
  /// last, so the later ones never drag.
  ///
  /// Levels follow activity, never how good someone already is at the
  /// language: everyone climbs this same ladder at the same price.
  static const double growthRate = 1.0;

  /// Max level cap. Raised from 20 to make room for more boss trials, one
  /// every five levels.
  static const int maxLevel = 30;

  /// The first entry in [levelRewards], granted once at the start of a new
  /// game.
  ///
  /// Level-up rewards are handed out when the level *changes*, and a player
  /// starts at level 1 — so this one could never fire that way. It is a
  /// welcome gift rather than a level-up, and `UserProvider` grants it on
  /// first load instead.
  static const int welcomeRewardLevel = 1;
}

enum RewardType {
  coins,
  item,
  unlock,
  cosmetic
}

class RewardDef {
  final int level;
  final RewardType type;
  final int value;
  final String description;
  final String? itemId;

  const RewardDef({
    required this.level,
    required this.type,
    required this.value,
    required this.description,
    this.itemId,
  });
}

const List<RewardDef> levelRewards = [
  // Level 1-5: Quick wins, establish the loop
  RewardDef(level: 1, type: RewardType.coins, value: 100, description: 'Welcome! 100 gold'),
  RewardDef(level: 2, type: RewardType.coins, value: 150, description: '150 gold'),
  RewardDef(level: 3, type: RewardType.item, value: 3, description: 'Apple x3', itemId: 'apple'),
  RewardDef(level: 4, type: RewardType.coins, value: 200, description: '200 gold'),
  // MILESTONE Level 5
  RewardDef(level: 5, type: RewardType.item, value: 2, description: 'Donut x2', itemId: 'donut'),
  
  // Level 6-10: Moderate progression
  RewardDef(level: 6, type: RewardType.coins, value: 300, description: '300 gold'),
  RewardDef(level: 7, type: RewardType.item, value: 2, description: 'Coffee x2', itemId: 'coffee'),
  RewardDef(level: 8, type: RewardType.coins, value: 350, description: '350 gold'),
  RewardDef(level: 9, type: RewardType.item, value: 1, description: 'Pizza Slice', itemId: 'pizza'),
  // MILESTONE Level 10
  RewardDef(level: 10, type: RewardType.unlock, value: 0, description: 'Ocean Blue Background', itemId: 'bg_blue'),
  
  // Level 11-15: Longer commitment
  RewardDef(level: 11, type: RewardType.coins, value: 400, description: '400 gold'),
  RewardDef(level: 12, type: RewardType.item, value: 1, description: 'Sushi Set', itemId: 'sushi'),
  RewardDef(level: 13, type: RewardType.coins, value: 500, description: '500 gold'),
  RewardDef(level: 14, type: RewardType.item, value: 2, description: 'Pizza x2', itemId: 'pizza'),
  // MILESTONE Level 15
  RewardDef(level: 15, type: RewardType.unlock, value: 0, description: 'Forest Green Background', itemId: 'bg_forest'),
  
  // Level 16-20: Endgame prestige
  RewardDef(level: 16, type: RewardType.coins, value: 600, description: '600 gold'),
  RewardDef(level: 17, type: RewardType.item, value: 2, description: 'Sushi x2', itemId: 'sushi'),
  RewardDef(level: 18, type: RewardType.coins, value: 800, description: '800 gold'),
  RewardDef(level: 19, type: RewardType.unlock, value: 0, description: 'Sunset Orange', itemId: 'bg_sunset'),
  // MILESTONE Level 20
  RewardDef(level: 20, type: RewardType.unlock, value: 0, description: 'Galaxy Purple + 1000 gold', itemId: 'bg_galaxy'),

  // Levels 21-30: nothing yet. The cap went from 20 to 30 for more boss
  // trials; what these levels pay is still to be decided.
];

/// Daily rewards schedule (cycles every 7 days with bonuses)
///
/// This cycle feeds the pet; it does not fund the wardrobe. It used to pay
/// 375 coins a week, which was 52% of an average player's income and 84% of a
/// light one's — opening the app was by far the best-paid thing in the game,
/// and the pet's upkeep was really being bought with login money rather than
/// earned. Two consequences followed: learning barely mattered to the
/// economy, and for a light player *neglecting* the pet paid better than
/// feeding it, because skipping food saved more than sickness cost.
///
/// So the cycle now hands out food directly — about 300 hunger a week against
/// the 336 a fed pet burns — plus 45 coins. Survival is nearly free for
/// anyone who shows up, the small shortfall keeps feeding a real act rather
/// than an automatic one, and every coin that buys a hat is earned by
/// learning. See `gold.dart`.
const List<RewardDef> dailyRewards = [
  // Day 1: a greeting, not an income.
  RewardDef(level: 1, type: RewardType.coins, value: 12, description: 'Day 1: 12 coins'),
  // Day 2: two days of light rations.
  RewardDef(level: 2, type: RewardType.item, value: 2, description: 'Day 2: Donut x2', itemId: 'donut'),
  RewardDef(level: 3, type: RewardType.coins, value: 15, description: 'Day 3: 15 coins'),
  // Day 4: the week's bulk of the pet's food.
  RewardDef(level: 4, type: RewardType.item, value: 2, description: 'Day 4: Pizza x2', itemId: 'pizza'),
  RewardDef(level: 5, type: RewardType.coins, value: 18, description: 'Day 5: 18 coins'),
  RewardDef(level: 6, type: RewardType.item, value: 1, description: 'Day 6: Sushi Set', itemId: 'sushi'),
  // Day 7: the streak payoff — a fortnight of dinners in one go.
  RewardDef(level: 7, type: RewardType.item, value: 2, description: 'Day 7: Sushi x2!', itemId: 'sushi'),
];
