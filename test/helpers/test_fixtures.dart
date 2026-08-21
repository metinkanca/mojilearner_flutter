import 'package:mojilearner_flutter/models/models.dart';
import 'package:mojilearner_flutter/constants/progression.dart';

/// Test fixtures and sample data for testing
/// 
/// Provides consistent test data across all tests
class TestFixtures {
  // User test data
  static const int testTotalXP = 250;
  static const int testLevel = 3;
  static const int testCoins = 500;
  static const int testStreak = 5;
  
  // Pet test data
  static const int testHunger = 50;
  static const int testHappiness = 70;
  static const int testHealth = 100;
  
  // Sample inventory
  static const List<String> testInventory = ['apple', 'coffee', 'croissant'];
  static const Set<String> testUnlockedItems = {'apple', 'coffee', 'croissant'};
  
  // Time constants
  static DateTime testNow = DateTime(2026, 2, 11, 12, 0, 0);
  static DateTime testYesterday = DateTime(2026, 2, 10, 12, 0, 0);
  static DateTime testTwoDaysAgo = DateTime(2026, 2, 9, 12, 0, 0);
  static DateTime testThreeDaysAgo = DateTime(2026, 2, 8, 12, 0, 0);
  
  /// Creates a sample DailyRewardInfo for testing
  static DailyRewardInfo createTestReward({
    int dayNumber = 2,
    bool streakReset = false,
    int? currentStreak,
  }) {
    final streak = currentStreak ?? dayNumber;
    final rewardIndex = (streak - 1) % dailyRewards.length;
    
    return DailyRewardInfo(
      dayNumber: dayNumber,
      reward: dailyRewards[rewardIndex],
      streakReset: streakReset,
      currentStreak: streak,
    );
  }
  
  /// Builder for UserStats with customizable values
  static UserStats buildUserStats({
    int level = 1,
    int totalXP = 0,
    int currentLevelXP = 0,
    int nextLevelXP = 100,
    int streak = 0,
    int coins = 100,
    double progress = 0.0,
  }) {
    return UserStats(
      level: level,
      totalXP: totalXP,
      currentLevelXP: currentLevelXP,
      nextLevelXP: nextLevelXP,
      streak: streak,
      coins: coins,
      progress: progress,
    );
  }
  
  /// Builder for CharacterCustomization
  static CharacterCustomization buildCustomization({
    String? openFace,
    String? closedFace,
    String? color,
    String? backgroundColor,
  }) {
    return CharacterCustomization(
      openFace: openFace ?? '(•_•)',
      closedFace: closedFace ?? '(-_-)',
      color: color ?? '#FFFFFF',
      backgroundColor: backgroundColor ?? '#60A5FA',
    );
  }
  
  /// Creates a sample Message for testing
  static Message createTestMessage({
    String? id,
    String? content,
    String? sender,
    DateTime? timestamp,
    String? translation,
    String? grammarAnalysis,
  }) {
    return Message(
      id: id ?? 'msg_1',
      content: content ?? 'Hola, ¿cómo estás?',
      sender: sender ?? 'user',
      timestamp: timestamp ?? testNow,
      translation: translation,
      grammarAnalysis: grammarAnalysis,
    );
  }
  
  /// Creates a sample Chat for testing
  static Chat createTestChat({
    String? id,
    String? title,
    DateTime? createdAt,
    Message? lastMessage,
    String? type,
  }) {
    return Chat(
      id: id ?? 'chat_1',
      title: title ?? 'Test Chat',
      createdAt: createdAt ?? testNow,
      lastMessage: lastMessage,
      type: type ?? 'free_chat',
    );
  }
  
  /// Creates a sample Mistake for testing
  static Mistake createTestMistake({
    String? id,
    String? original,
    String? correction,
    String? explanation,
    String? type,
    DateTime? timestamp,
  }) {
    return Mistake(
      id: id ?? 'mistake_1',
      original: original ?? 'yo hablo inglés',
      correction: correction ?? 'yo hablo inglés',
      explanation: explanation ?? 'Capitalize language names',
      type: type ?? 'grammar',
      timestamp: timestamp ?? testNow,
    );
  }
  
  /// Sample XP values for different levels
  static const Map<int, int> levelToTotalXP = {
    1: 0,
    2: 100,
    3: 280,
    4: 540,
    5: 892,
    10: 4350,
    20: 32000,
  };
  
  /// Sample reward data for testing
  static const RewardDef testCoinReward = RewardDef(
    level: 1,
    type: RewardType.coins,
    value: 100,
    description: 'Test Coins',
  );
  
  static const RewardDef testItemReward = RewardDef(
    level: 3,
    type: RewardType.item,
    value: 3,
    description: 'Test Item',
    itemId: 'apple',
  );
  
  static const RewardDef testUnlockReward = RewardDef(
    level: 10,
    type: RewardType.unlock,
    value: 0,
    description: 'Test Unlock',
    itemId: 'bg_blue',
  );
}
