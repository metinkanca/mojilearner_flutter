import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../utils/progression_utils.dart';
import '../constants/gold.dart';
import '../constants/progression.dart';
import '../constants/app_runtime_config.dart';

class UserProvider extends ChangeNotifier {
  /// Coins a brand-new player starts with: roughly one day of food, so the
  /// first session can feed the pet before any reward has been earned.
  static const int startingCoins = 50;

  static const String _premiumKey = 'is_premium';

  String _username = 'Learner';
  int _coins = startingCoins;
  int _streak = 0;
  int _totalXP = 0;

  /// Whether the player holds a membership.
  ///
  /// What it buys is the absence of the automatic interstitials after a quiz
  /// or a scenario — see `constants/ads.dart`. Deliberately *not* the
  /// rewarded ads: taking those away would remove a coin source and leave a
  /// paying player worse off than a free one.
  bool _isPremium = false;
  bool _isLoading = true;

  /// Today's learning-coin earnings, for the source caps and the daily taper.
  /// See `gold.dart` for what those are and why.
  GoldLedger _goldLedger = const GoldLedger();

  /// The calendar day [_goldLedger] belongs to. Persisted, so closing the app
  /// cannot be used to reset the taper.
  DateTime? _goldDay;

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
    _isPremium = prefs.getBool(_premiumKey) ?? false;
    _loadGoldLedger(prefs);
    await _grantWelcomeReward(prefs);

    // Load onboarding status
    _hasCompletedOnboarding = prefs.getBool('onboarding_complete') ?? false;
    // In-memory only: never persisted, so a test run cannot silently mark a
    // real player as onboarded.
    if (AppRuntimeConfig.skipOnboarding) {
      _hasCompletedOnboarding = true;
    }

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

  /// Grants the level-1 entry of [levelRewards], once ever.
  ///
  /// [_handleLevelUpRewards] only fires when the level *changes*, and every
  /// player starts at level 1 — so this reward was shown on the rewards
  /// screen and could never actually be given. It is a welcome gift rather
  /// than a level-up, so it belongs here on first load.
  ///
  /// Existing players get it too, on their next launch. They were owed it and
  /// never received it, and the flag makes sure that happens exactly once.
  Future<void> _grantWelcomeReward(SharedPreferences prefs) async {
    const grantedKey = 'welcome_reward_granted';
    if (prefs.getBool(grantedKey) ?? false) return;
    await prefs.setBool(grantedKey, true);

    for (final reward in levelRewards) {
      if (reward.level != ProgressionConstants.welcomeRewardLevel) continue;
      await grantReward(reward);
    }
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

  /// Coins the player has already earned from learning today, before the
  /// taper. Read by the UI to explain a reduced payout.
  int get learningGoldEarnedToday => _goldLedger.rawEarnedToday;

  /// What [source] has left today, or null when it is bounded by the taper
  /// rather than a cap of its own.
  int? learningGoldRemainingFor(GoldSource source) =>
      _goldLedger.remainingFor(source);

  /// Pays out [raw] coins earned from [source], after the per-source daily
  /// cap and the day's taper.
  ///
  /// This is the only way learning should add coins — [addCoins] is for
  /// grants that are not earned by playing (the daily login cycle, level-up
  /// rewards, and later anything bought or granted by a membership), which
  /// deliberately bypass the taper because they are already bounded by their
  /// own schedule.
  ///
  /// Returns what was actually paid, which callers show to the player rather
  /// than the number they asked for.
  Future<GoldAward> awardLearningGold(int raw, GoldSource source) async {
    _rolloverGoldDayIfNeeded();

    final award = _goldLedger.award(raw, source);
    if (award.raw <= 0) return GoldAward.none;

    _goldLedger = _goldLedger.recording(award, source);
    _coins += award.paid;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coins', _coins);
    await _saveGoldLedger(prefs);

    notifyListeners();
    return award;
  }

  /// Clears the ledger when the calendar day has turned over.
  void _rolloverGoldDayIfNeeded() {
    final now = DateTime.now();
    final day = _goldDay;
    final sameDay = day != null &&
        day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;
    if (sameDay) return;

    _goldDay = now;
    _goldLedger = const GoldLedger();
  }

  Future<void> _saveGoldLedger(SharedPreferences prefs) async {
    await prefs.setInt('gold_day', _goldDay!.millisecondsSinceEpoch);
    await prefs.setInt('gold_raw_today', _goldLedger.rawEarnedToday);
    for (final source in GoldSource.values) {
      if (GoldConstants.dailyCapFor(source) == null) continue;
      await prefs.setInt(
        'gold_raw_${source.name}',
        _goldLedger.rawEarnedFrom(source),
      );
    }
  }

  void _loadGoldLedger(SharedPreferences prefs) {
    final dayMs = prefs.getInt('gold_day');
    if (dayMs == null) return;

    _goldDay = DateTime.fromMillisecondsSinceEpoch(dayMs);
    _goldLedger = GoldLedger(
      rawEarnedToday: prefs.getInt('gold_raw_today') ?? 0,
      rawPerSourceToday: {
        for (final source in GoldSource.values)
          if (GoldConstants.dailyCapFor(source) != null)
            source: prefs.getInt('gold_raw_${source.name}') ?? 0,
      },
    );

    // A stored ledger from a previous day is spent the moment anything is
    // awarded; rolling over here too keeps the getters honest in the
    // meantime, so the UI never opens showing yesterday's caps.
    _rolloverGoldDayIfNeeded();
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

  /// Sets and persists the membership flag.
  ///
  /// The seam a purchase will drive. Nothing calls this yet: the store
  /// products, the receipt check and the restore-purchases flow are their own
  /// piece of work, and the ad system needed the flag to exist before then so
  /// it had something to gate on. When in-app purchases land, this is the
  /// only line that has to change hands — everything downstream already reads
  /// [isPremium].
  Future<void> setPremium(bool value) async {
    if (_isPremium == value) return;
    _isPremium = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, value);
    notifyListeners();
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
