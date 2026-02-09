import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class UserProvider extends ChangeNotifier {
  String _username = 'Learner';
  int _coins = 100;
  int _streak = 0;
  int _level = 1;
  int _xp = 0;
  bool _isPremium = false;
  bool _isLoading = true;

  String get username => _username;
  int get coins => _coins;
  int get streak => _streak;
  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;

  UserStats get stats => UserStats(
    level: _level,
    xp: _xp,
    streak: _streak,
    coins: _coins,
    xpToNextLevel: 100 * _level, // Simple formula
  );

  UserProvider() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username') ?? 'Learner';
    _coins = prefs.getInt('coins') ?? 100;
    _streak = prefs.getInt('streak') ?? 0;
    _level = prefs.getInt('level') ?? 1;
    _xp = prefs.getInt('xp') ?? 0;
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
    // Save to prefs...
  }

  void addXp(int amount) {
    _xp += amount;
    int nextLevel = 100 * _level;
    if (_xp >= nextLevel) {
      _level++;
      _xp -= nextLevel;
      // Level up celebration?
    }
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('xp', _xp);
      prefs.setInt('level', _level);
    });
  }
}
