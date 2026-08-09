import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../utils/progression_utils.dart';
import '../constants/progression.dart';

class UserProvider extends ChangeNotifier {
  /// Coins a brand-new player starts with: roughly one day of food, so the
  /// first session can feed the pet before any reward has been earned.
  static const int startingCoins = 50;

  String _username = 'Learner';
  int _coins = startingCoins;
  int _streak = 0;
  int _totalXP = 0;
  bool _isPremium = false;
  bool _isLoading = true;

  // Onboarding tracking
  bool _hasCompletedOnboarding = false;

  final StreamController<int> _levelUpController = StreamController<int>.broadcast();
  Stream<int> get onLevelUp => _levelUpController.stream;
  
  final StreamController<RewardDef> _rewardController = StreamController<RewardDef>.broadcast();
  Stream<RewardDef> get onReward => _rewardController.stream;

  String get username => _username;
  int get coins => _coins;
  int get streak => _streak;
  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  UserStats get stats {
    int level = ProgressionUtils.getLevelFromTotalXP(_totalXP);
    int startOfLevel = ProgressionUtils.getTotalXPForLevel(level);
    int endOfLevel = ProgressionUtils.getTotalXPForLevel(level + 1);
    
    return UserStats(
      level: level,
      totalXP: _totalXP,
      currentLevelXP: _totalXP - startOfLevel,
      nextLevelXP: endOfLevel - startOfLevel,
      streak: _streak,
      coins: _coins,
      progress: ProgressionUtils.getLevelProgress(_totalXP),
    );
  }

  UserProvider() {
    _loadUserData();
  }

  @override
  void dispose() {
    _levelUpController.close();
    _rewardController.close();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username') ?? 'Learner';
    _coins = prefs.getInt('coins') ?? startingCoins;
    await _migrateTestingModeCoins(prefs);
    _streak = prefs.getInt('streak') ?? 0;
    _totalXP = prefs.getInt('total_xp') ?? 0;
    
    // Load onboarding status
    _hasCompletedOnboarding = prefs.getBool('onboarding_complete') ?? false;

    _isLoading = false;
    notifyListeners();
  }

  /// Earlier builds seeded every player with 999999 coins ("testing mode:
  /// infinite gold"). Those balances persist across an update and would make
  /// the shop meaningless — and any economy feedback from existing testers
  /// worthless — so retire the sentinel exactly once.
  Future<void> _migrateTestingModeCoins(SharedPreferences prefs) async {
    const legacyTestingCoins = 999999;
    const migrationKey = 'coins_testing_mode_migrated';

    if (prefs.getBool(migrationKey) ?? false) return;
    await prefs.setBool(migrationKey, true);

    if (_coins != legacyTestingCoins) return;

    _coins = startingCoins;
    await prefs.setInt('coins', _coins);
  }

  Future<void> updateUsername(String name) async {
    _username = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', name);
    notifyListeners();
  }

  Future<void> addCoins(int amount) async {
    _coins += amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coins', _coins);
    notifyListeners();
  }

  Future<void> addXp(int amount) async {
    int oldLevel = ProgressionUtils.getLevelFromTotalXP(_totalXP);
    _totalXP += amount;
    int newLevel = ProgressionUtils.getLevelFromTotalXP(_totalXP);

    if (newLevel > oldLevel) {
      // Level Up!
      _levelUpController.add(newLevel);
      _handleLevelUpRewards(newLevel);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_xp', _totalXP);
    
    notifyListeners();
  }

  void _handleLevelUpRewards(int level) {
    // Find if there's a reward for this level
    for (var reward in levelRewards) {
      if (reward.level == level) {
        // Grant coins automatically
        if (reward.type == RewardType.coins) {
          addCoins(reward.value);
        }
        
        // Emit reward event for items/unlocks (CharacterProvider will listen)
        if (reward.type == RewardType.item || reward.type == RewardType.unlock) {
          _rewardController.add(reward);
        }
        
        // Level 20 special case: also grant 1000 coins
        if (level == 20) {
          addCoins(1000);
        }
      }
    }
  }

  Future<void> spendCoins(int amount) async {
    if (_coins >= amount) {
      _coins -= amount;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('coins', _coins);
      notifyListeners();
    }
  }

  /// Set and persist the streak counter (advanced by DailyRewardProvider).
  Future<void> setStreak(int value) async {
    _streak = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('streak', _streak);
    notifyListeners();
  }

  /// Grant a reward: coins are added directly, items/unlocks are emitted on
  /// [onReward] for CharacterProvider to consume.
  Future<void> grantReward(RewardDef reward) async {
    if (reward.type == RewardType.coins) {
      await addCoins(reward.value);
    } else {
      _rewardController.add(reward);
    }
  }

  // ==================== ONBOARDING METHODS ====================

  /// Mark onboarding as complete (call after user finishes farewell screen)
  Future<void> markOnboardingComplete() async {
    _hasCompletedOnboarding = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    notifyListeners();
  }

  /// Check if this is a first-time user
  bool isFirstTimeUser() {
    return !_hasCompletedOnboarding;
  }
}
