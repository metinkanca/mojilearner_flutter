class ProgressionConstants {
  /// The starting XP for level 1 to 2
  static const int baseXP = 100;
  
  /// The exponential growth rate of the XP curve
  /// 2.0 is standard. 1.8 is slightly easier.
  static const double growthRate = 1.8;

  /// Max level cap
  static const int maxLevel = 20;
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
  RewardDef(level: 5, type: RewardType.item, value: 2, description: 'Croissant x2', itemId: 'croissant'),
  
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
];

/// Daily rewards schedule (cycles every 7 days with bonuses)
const List<RewardDef> dailyRewards = [
  // Day 1: Small welcome back
  RewardDef(level: 1, type: RewardType.coins, value: 50, description: 'Day 1: 50 coins'),
  // Day 2: Slightly better
  RewardDef(level: 2, type: RewardType.coins, value: 75, description: 'Day 2: 75 coins'),
  // Day 3: Food item
  RewardDef(level: 3, type: RewardType.item, value: 1, description: 'Day 3: Apple', itemId: 'apple'),
  // Day 4: More coins
  RewardDef(level: 4, type: RewardType.coins, value: 100, description: 'Day 4: 100 coins'),
  // Day 5: Coffee boost
  RewardDef(level: 5, type: RewardType.item, value: 2, description: 'Day 5: Coffee x2', itemId: 'coffee'),
  // Day 6: Big coin reward
  RewardDef(level: 6, type: RewardType.coins, value: 150, description: 'Day 6: 150 coins'),
  // Day 7: Special weekly reward
  RewardDef(level: 7, type: RewardType.item, value: 1, description: 'Day 7: Pizza!', itemId: 'pizza'),
];
