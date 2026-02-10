import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../utils/progression_utils.dart';
import '../constants/progression.dart';

class UserProvider extends ChangeNotifier {
  String _username = 'Learner';
  int _coins = 999999; // Testing mode: infinite gold
  int _streak = 0;
  int _totalXP = 0;
  bool _isPremium = false;
  bool _isLoading = true;

  final StreamController<int> _levelUpController = StreamController<int>.broadcast();
  Stream<int> get onLevelUp => _levelUpController.stream;
  
  final StreamController<RewardDef> _rewardController = StreamController<RewardDef>.broadcast();
  Stream<RewardDef> get onReward => _rewardController.stream;

  String get username => _username;
  int get coins => _coins;
  int get streak => _streak;
  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;

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
    _coins = prefs.getInt('coins') ?? 999999; // Testing mode: infinite gold
    _streak = prefs.getInt('streak') ?? 0;
    _totalXP = prefs.getInt('total_xp') ?? 0;
    _isLoading = false;
    notifyListeners();
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

  void incrementStreak() {
    _streak++;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('streak', _streak);
    });
  }
}
