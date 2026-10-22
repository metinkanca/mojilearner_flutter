import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../utils/play_games.dart';
import '../utils/progression_utils.dart';
import '../utils/season_pass_progress.dart';
import '../constants/entitlements.dart';
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
  /// Where the player is in the seven-step reward cycle, as a running count
  /// of claims. See [rewardClaims].
  int _rewardClaims = 0;

  /// Consecutive days claimed. See [loginStreak].
  int _loginStreak = 0;
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

  /// XP the toy chest's games have paid today, against
  /// [PlayRewards.dailyXpCap], and the calendar day that count belongs to.
  /// Persisted for the same reason as the gold day.
  int _playXpToday = 0;
  DateTime? _playXpDay;

  /// Season passes this player has bought, oldest first.
  ///
  /// Purchases rather than pet state, which is why they live here beside the
  /// coins and the XP their tracks are measured against. Never pruned: a pass
  /// whose season is long over may still have tiers waiting, and dropping it
  /// would be the expiry the design exists to avoid — see
  /// `constants/season_pass.dart`.
  List<OwnedPass> _ownedPasses = const [];

  /// Today's model spend, against the tier's allowance. See
  /// `constants/entitlements.dart` — and note that this copy is the meter and
  /// the wall, not the enforcement: the proxy holds the real allowance.
  AiUsageLedger _aiUsage = const AiUsageLedger();

  // Onboarding tracking
  bool _hasCompletedOnboarding = false;

  final StreamController<int> _levelUpController = StreamController<int>.broadcast();
  Stream<int> get onLevelUp => _levelUpController.stream;
  
  final StreamController<RewardDef> _rewardController = StreamController<RewardDef>.broadcast();
  Stream<RewardDef> get onReward => _rewardController.stream;

  String get username => _username;
  int get coins => _coins;

  /// Every pass the player owns, oldest first.
  List<OwnedPass> get ownedPasses => List.unmodifiable(_ownedPasses);

  bool ownsPass(String passId) =>
      _ownedPasses.any((p) => p.passId == passId);

  /// Every pass accessory actually claimed, which is what the wardrobe reads.
  Set<String> get claimedPassItemIds =>
      SeasonPassProgress.claimedAccessoryIds(_ownedPasses);

  /// Every pass *scene* actually claimed.
  ///
  /// Not how a scene is owned — that is `CharacterProvider`'s unlocked set,
  /// like every other world — but the durable record of what should be in it,
  /// which is what puts a world back if the unlock never landed.
  Set<String> get claimedPassSceneIds =>
      SeasonPassProgress.claimedSceneIds(_ownedPasses);

  /// Where the player is on [passId], or null when they do not own it.
  PassProgress? passProgress(String passId) {
    for (final owned in _ownedPasses) {
      if (owned.passId == passId) {
        return SeasonPassProgress.progressFor(owned, totalXP: _totalXP);
      }
    }
    return null;
  }

  /// Records a bought pass, baselined on the XP the player has right now.
  ///
  /// Idempotent: a store that replays a purchase — which both of them do on a
  /// restore — must not reset the baseline and take back the track. Returns
  /// whether anything was actually added.
  Future<bool> grantPass(String passId) async {
    if (ownsPass(passId)) return false;

    _ownedPasses = [
      ..._ownedPasses,
      OwnedPass(passId: passId, xpAtPurchase: _totalXP),
    ];
    await _savePasses();
    notifyListeners();
    return true;
  }

  /// Hands over every tier reached but not yet taken, and returns them.
  ///
  /// Claiming the whole run at once rather than one at a time because that is
  /// what coming back after a fortnight looks like, and making someone tap
  /// four times for four rungs they already earned is a chore, not a ceremony.
  Future<List<int>> claimPassTiers(String passId) async {
    final progress = passProgress(passId);
    if (progress == null || !progress.hasClaimable) return const [];

    final claimed = progress.claimableTierIndexes;
    _ownedPasses = [
      for (final owned in _ownedPasses)
        owned.passId == passId
            ? owned.copyWith(claimedThroughTier: claimed.last)
            : owned,
    ];
    await _savePasses();
    notifyListeners();
    return claimed;
  }

  Future<void> _savePasses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'season_passes',
      json.encode([
        for (final owned in _ownedPasses)
          {
            'id': owned.passId,
            'xp': owned.xpAtPurchase,
            'claimed': owned.claimedThroughTier,
          },
      ]),
    );
  }

  void _loadPasses(SharedPreferences prefs) {
    final raw = prefs.getString('season_passes');
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = json.decode(raw);
      if (decoded is! List) return;
      _ownedPasses = [
        for (final entry in decoded)
          if (entry is Map && entry['id'] is String)
            OwnedPass(
              passId: entry['id'] as String,
              xpAtPurchase: (entry['xp'] as num?)?.toInt() ?? 0,
              claimedThroughTier: (entry['claimed'] as num?)?.toInt() ?? -1,
            ),
      ];
    } catch (_) {
      // A record that cannot be read is left alone rather than overwritten:
      // the next save would otherwise erase a purchase over a parse bug.
      _ownedPasses = const [];
    }
  }

  /// The daily allowance this player is on.
  AiAllowance get aiAllowance =>
      EntitlementConstants.forTier(isPremium: _isPremium);

  /// How much of [spend] is left today.
  int aiRemaining(AiSpend spend) {
    _rolloverAiDayIfNeeded();
    return _aiUsage.remaining(spend, aiAllowance);
  }

  /// Everything [spend] may use today, including any quizzes ads have added.
  int aiLimit(AiSpend spend) {
    _rolloverAiDayIfNeeded();
    return _aiUsage.limitFor(spend, aiAllowance);
  }

  /// Quizzes rewarded ads have added today, shown alongside the allowance so
  /// a player can see what an ad bought them.
  int get aiBonusQuizzesToday {
    _rolloverAiDayIfNeeded();
    return _aiUsage.bonusQuizzesToday;
  }

  /// Unused quizzes carried in from earlier days and still unspent.
  ///
  /// Filled only while Mimikin Plus is active — see [aiBanking] — and
  /// included in [aiLimit] like any other quiz, so nothing has to add it back
  /// on to display an honest total.
  int get aiBankedQuizzes {
    _rolloverAiDayIfNeeded();
    return _aiUsage.bankedQuizzes;
  }

  /// The allowance whose leftovers carry forward, or null on a tier that does
  /// not bank.
  ///
  /// The one place membership decides what happens to a closing day. Free
  /// players do not bank: the bank is a Plus feature, and a free allowance
  /// small enough to be a real limit is not one there is much point saving.
  AiAllowance? get aiBanking => _isPremium ? aiAllowance : null;

  /// Whether one more [spend] is allowed right now.
  ///
  /// Ask before generating, not after: the point is to not make the call.
  bool canSpendAi(AiSpend spend) {
    _rolloverAiDayIfNeeded();
    return _aiUsage.canSpend(spend, aiAllowance);
  }

  /// Every XP the player has ever earned — the single learning ledger.
  ///
  /// Exposed raw as well as through [stats] because the pet's bond stage is a
  /// projection of it (see `utils/bond_progress.dart`), and that projection
  /// needs the running total rather than the level it rounds to.
  int get totalXP => _totalXP;
  /// How many daily rewards this player has claimed, ever.
  ///
  /// Nothing resets it, and a missed day leaves no mark. `DailyRewardProvider`
  /// reads it as the player's position in the seven-step reward cycle, which
  /// is the only thing it is used for.
  ///
  /// Still persisted under the key `streak`, which is what it was called when
  /// it was one. Renaming the key would cost every existing player their place
  /// in the cycle to fix a word only this file can see.
  int get rewardClaims => _rewardClaims;

  /// Days claimed in a row, and nothing more than that.
  ///
  /// Deliberately inert. It is a number the player is shown because a run of
  /// days is worth being proud of; it is attached to no reward, no multiplier
  /// and no penalty, and breaking it costs exactly nothing — see
  /// `DailyRewardProvider.checkDailyReward` for why the reward cycle stopped
  /// reading it.
  int get loginStreak => _loginStreak;
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
      streak: _loginStreak,
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
    _rewardClaims = prefs.getInt('streak') ?? 0;
    // Absent for anyone who was playing before the two were told apart. Their
    // claim count is the better guess of the pair: it is at least a number of
    // days they turned up, where zero would say they never had.
    _loginStreak = prefs.getInt('login_streak') ?? _rewardClaims;
    _totalXP = prefs.getInt('total_xp') ?? 0;
    _isPremium = prefs.getBool(_premiumKey) ?? false;
    _loadGoldLedger(prefs);
    _loadPlayXp(prefs);
    _loadAiUsage(prefs);
    _loadPasses(prefs);
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

  /// Records one [spend] against today, and returns whether it was allowed.
  ///
  /// Returns false without recording anything when the meter is spent, so a
  /// caller that ignores [canSpendAi] still cannot overspend.
  Future<bool> spendAi(AiSpend spend) async {
    _rolloverAiDayIfNeeded();
    if (!_aiUsage.canSpend(spend, aiAllowance)) return false;

    _aiUsage = _aiUsage.recording(spend, aiAllowance);
    await _saveAiUsage(await SharedPreferences.getInstance());
    notifyListeners();
    return true;
  }

  /// Adds the quizzes a finished rewarded ad bought.
  ///
  /// The route past the wall for a player who will not subscribe. Called only
  /// once the ad has reported an earned reward, so an ad that failed to load
  /// buys nothing.
  Future<void> addRewardedQuiz() async {
    _rolloverAiDayIfNeeded();
    _aiUsage = _aiUsage.recordingRewardedQuiz();
    await _saveAiUsage(await SharedPreferences.getInstance());
    notifyListeners();
  }

  /// Advances the ledger to today, banking whatever the closing day left.
  ///
  /// Deliberately does not persist: it is called from getters, which cannot
  /// await. That is safe because the result is a pure function of what is
  /// already on disk — the same rollover recomputes to the same bank on the
  /// next launch — and the first thing that actually spends writes the day,
  /// the spend and the bank back together.
  void _rolloverAiDayIfNeeded() {
    final rolled = _aiUsage.rolledOver(DateTime.now(), banking: aiBanking);
    if (identical(rolled, _aiUsage)) return;
    _aiUsage = rolled;
  }

  Future<void> _saveAiUsage(SharedPreferences prefs) async {
    await prefs.setInt('ai_day', _aiUsage.day!.millisecondsSinceEpoch);
    await prefs.setInt('ai_bonus_quizzes', _aiUsage.bonusQuizzesToday);
    await prefs.setInt('ai_banked_quizzes', _aiUsage.bankedQuizzes);
    await prefs.setInt('ai_banked_used', _aiUsage.bankedQuizzesUsedToday);
    for (final spend in AiSpend.values) {
      await prefs.setInt('ai_spent_${spend.name}', _aiUsage.spent(spend));
    }
  }

  void _loadAiUsage(SharedPreferences prefs) {
    final dayMs = prefs.getInt('ai_day');
    if (dayMs == null) return;

    _aiUsage = AiUsageLedger(
      day: DateTime.fromMillisecondsSinceEpoch(dayMs),
      spentToday: {
        for (final spend in AiSpend.values)
          spend: prefs.getInt('ai_spent_${spend.name}') ?? 0,
      },
      bonusQuizzesToday: prefs.getInt('ai_bonus_quizzes') ?? 0,
      bankedQuizzes: prefs.getInt('ai_banked_quizzes') ?? 0,
      bankedQuizzesUsedToday: prefs.getInt('ai_banked_used') ?? 0,
    );

    // Same reason the gold ledger rolls over on load: the getters have to be
    // honest before anything is spent, or the meter opens showing yesterday.
    _rolloverAiDayIfNeeded();
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

  /// XP the toy chest's games can still pay today.
  int get playXpRemainingToday {
    _rolloverPlayXpDayIfNeeded();
    return PlayRewards.xpAllowed(
      earned: PlayRewards.dailyXpCap,
      paidToday: _playXpToday,
    );
  }

  /// Pays [earned] XP for a finished toy chest game, after the games' daily
  /// cap, and returns what was actually paid — which is what the results
  /// show, so a capped game says +0 rather than promising XP that never
  /// arrived.
  ///
  /// The games' own path rather than [addXp], which is unbounded: every
  /// other XP source is rationed by something else (the review queue, the
  /// quiz allowance, how long a conversation takes), and a minute's game is
  /// not.
  Future<int> awardPlayXp(int earned) async {
    _rolloverPlayXpDayIfNeeded();
    final paid =
        PlayRewards.xpAllowed(earned: earned, paidToday: _playXpToday);
    if (paid <= 0) return 0;

    _playXpToday += paid;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('play_xp_day', _playXpDay!.millisecondsSinceEpoch);
    await prefs.setInt('play_xp_today', _playXpToday);
    await addXp(paid);
    return paid;
  }

  void _loadPlayXp(SharedPreferences prefs) {
    final dayMs = prefs.getInt('play_xp_day');
    if (dayMs == null) return;
    _playXpDay = DateTime.fromMillisecondsSinceEpoch(dayMs);
    _playXpToday = prefs.getInt('play_xp_today') ?? 0;
    _rolloverPlayXpDayIfNeeded();
  }

  /// Clears the games' XP count when the calendar day has turned over.
  void _rolloverPlayXpDayIfNeeded() {
    final now = DateTime.now();
    final day = _playXpDay;
    final sameDay = day != null &&
        day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;
    if (sameDay) return;

    _playXpDay = now;
    _playXpToday = 0;
  }

  Future<void> addXp(int amount) async {
    int oldLevel = ProgressionUtils.getLevelFromTotalXP(_totalXP);
    _totalXP += amount;
    int newLevel = ProgressionUtils.getLevelFromTotalXP(_totalXP);

    if (newLevel > oldLevel) {
      // Level Up!
      _levelUpController.add(newLevel);
      // Every level crossed pays, not just the one landed on: on a flat
      // curve a big enough grant can jump two.
      for (var level = oldLevel + 1; level <= newLevel; level++) {
        _handleLevelUpRewards(level);
      }
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

  /// Set and persist both daily-reward counters, which only ever move
  /// together — one claim advances the cycle and either extends the run of
  /// days or starts a new one. Advanced by DailyRewardProvider.
  Future<void> setRewardProgress({
    required int claims,
    required int loginStreak,
  }) async {
    _rewardClaims = claims;
    _loginStreak = loginStreak;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('streak', _rewardClaims);
    await prefs.setInt('login_streak', _loginStreak);
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
