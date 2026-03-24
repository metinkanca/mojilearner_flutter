import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../utils/progression_utils.dart';
import '../utils/secure_storage.dart';
import '../constants/progression.dart';

class UserProvider extends ChangeNotifier {
  String _username = 'Learner';
  int _coins = 999999; // Testing mode: infinite gold
  int _streak = 0;
  int _totalXP = 0;
  bool _isPremium = false;
  bool _isLoading = true;
  
  // Daily rewards tracking
  DateTime? _lastRewardClaimDate;
  DateTime? _lastLoginDate;

  // Onboarding tracking
  bool _hasCompletedOnboarding = false;

  // Language calibration data
  Map<String, LanguageProficiency> _languageProficiencies = {};

  final StreamController<int> _levelUpController = StreamController<int>.broadcast();
  Stream<int> get onLevelUp => _levelUpController.stream;
  
  final StreamController<RewardDef> _rewardController = StreamController<RewardDef>.broadcast();
  Stream<RewardDef> get onReward => _rewardController.stream;

  String get username => _username;
  int get coins => _coins;
  int get streak => _streak;
  int get dailyRewardClaimCount => _streak;
  int get completedRewardCycleDay {
    if (_streak == 0) {
      return 0;
    }
    final remainder = _streak % dailyRewards.length;
    return remainder == 0 ? dailyRewards.length : remainder;
  }

  int get nextRewardCycleDay {
    final nextClaimCount = _streak + 1;
    final remainder = nextClaimCount % dailyRewards.length;
    return remainder == 0 ? dailyRewards.length : remainder;
  }

  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get hasAnyCalibratedLanguage =>
      _languageProficiencies.values.any((p) => p.isCalibrated);

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
    
    // Load onboarding status
    _hasCompletedOnboarding = prefs.getBool('onboarding_complete') ?? false;
    
    // Load date tracking
    final lastRewardStr = prefs.getString('last_reward_claim_date');
    if (lastRewardStr != null) {
      _lastRewardClaimDate = DateTime.parse(lastRewardStr);
    }

    final lastLoginStr = prefs.getString('last_login_date');
    if (lastLoginStr != null) {
      _lastLoginDate = DateTime.parse(lastLoginStr);
    }
    
    // Load calibration data
    await _loadCalibrationData();

    // Recovery path for users with valid calibration but missing onboarding flag.
    if (!_hasCompletedOnboarding && hasAnyCalibratedLanguage) {
      _hasCompletedOnboarding = true;
      await prefs.setBool('onboarding_complete', true);
    }
    
    _pendingDailyReward = await checkDailyReward();

    _isLoading = false;
    notifyListeners();
  }

  DailyRewardInfo? _pendingDailyReward;
  DailyRewardInfo? get pendingDailyReward => _pendingDailyReward;

  void clearPendingReward() {
    _pendingDailyReward = null;
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

  /// Check if a daily reward is available.
  /// Rewards advance one step per claim, up to once per calendar day.
  /// Missing days does not reset progress.
  Future<DailyRewardInfo?> checkDailyReward() async {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    // Backward compatibility: if legacy data has reward date but no login date,
    // infer last login from the reward date.
    if (_lastLoginDate == null && _lastRewardClaimDate != null) {
      _lastLoginDate = _lastRewardClaimDate;
    }

    // First-ever launch: initialize login date and do not show reward yet.
    if (_lastLoginDate == null) {
      _lastLoginDate = today;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_login_date', today.toIso8601String());
      return null;
    }

    final lastLoginDay = DateTime(
      _lastLoginDate!.year,
      _lastLoginDate!.month,
      _lastLoginDate!.day,
    );

    final daysSinceLastLogin = today.difference(lastLoginDay).inDays;

    // Same-day login: do nothing.
    if (daysSinceLastLogin == 0) {
      return null;
    }

    if (_lastRewardClaimDate != null) {
      final lastRewardDay = DateTime(
        _lastRewardClaimDate!.year,
        _lastRewardClaimDate!.month,
        _lastRewardClaimDate!.day,
      );

      // Already claimed today.
      if (today == lastRewardDay) {
        return null;
      }
    }

    final streakReset = daysSinceLastLogin > 1;
    final nextClaimCount = streakReset ? 1 : _streak + 1;
    final rewardIndex = (nextClaimCount - 1) % dailyRewards.length;
    final reward = dailyRewards[rewardIndex];

    return DailyRewardInfo(
      dayNumber: rewardIndex + 1,
      reward: reward,
      streakReset: streakReset,
      currentStreak: nextClaimCount,
    );
  }
  
  /// Claim the daily reward.
  /// Grants coins/items, advances progress by one step, and locks claims for the day.
  Future<void> claimDailyReward() async {
    final rewardInfo = await checkDailyReward();
    if (rewardInfo == null) return; // No reward available
    
    final RewardDef reward = rewardInfo.reward as RewardDef;
    
    // Grant reward
    if (reward.type == RewardType.coins) {
      await addCoins(reward.value);
    } else if (reward.type == RewardType.item) {
      // Emit reward event for CharacterProvider to handle
      _rewardController.add(reward);
    }
    
    // Advance the reward progression by one claim.
    _streak = rewardInfo.currentStreak;
    
    // Update dates
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    _lastRewardClaimDate = today;
    _lastLoginDate = today;
    
    // Save state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('streak', _streak);
    await prefs.setString('last_reward_claim_date', today.toIso8601String());
    await prefs.setString('last_login_date', today.toIso8601String());
    
    notifyListeners();
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

  // ==================== CALIBRATION METHODS ====================

  /// Check if a language has been calibrated
  bool isLanguageCalibrated(String languageCode) {
    return _languageProficiencies.containsKey(languageCode) && 
           (_languageProficiencies[languageCode]?.isCalibrated ?? false);
  }

  /// Get proficiency data for a language (returns null if not calibrated)
  LanguageProficiency? getLanguageProficiency(String languageCode) {
    return _languageProficiencies[languageCode];
  }

  /// Save calibration data for a language
  /// 
  /// STORAGE STRATEGY:
  /// - SharedPreferences: Non-sensitive gamification data (levels, scores, flags)
  /// - SecureStorage: Sensitive assessment conversation data (encrypted)
  Future<void> saveLanguageProficiency(LanguageProficiency proficiency) async {
    _languageProficiencies[proficiency.languageCode] = proficiency;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'calibration_${proficiency.languageCode}';
      
      // Save non-sensitive data to SharedPreferences (for performance)
      final nonSensitiveData = {
        'languageCode': proficiency.languageCode,
        'selfAssessedLevel': proficiency.selfAssessedLevel,
        'aiDeterminedLevel': proficiency.aiDeterminedLevel,
        'calibratedAt': proficiency.calibratedAt.toIso8601String(),
        'quizScore': proficiency.quizScore,
        'totalQuizQuestions': proficiency.totalQuizQuestions,
        'isCalibrated': proficiency.isCalibrated,
      };
      await prefs.setString(key, jsonEncode(nonSensitiveData));
      
      // Save sensitive assessment conversation to SecureStorage (encrypted)
      if (proficiency.assessmentConversation.isNotEmpty) {
        final secureKey = 'assessment_conversation_${proficiency.languageCode}';
        final conversationData = proficiency.assessmentConversation
            .map((m) => m.toJson())
            .toList();
        await SecureStorage.saveEncrypted(secureKey, conversationData);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Error saving language proficiency for ${proficiency.languageCode}: $e');
      // Gracefully handle error - data remains in memory
      rethrow;
    }
  }

  /// Load calibration data for a specific language
  /// 
  /// Loads from split storage:
  /// - Non-sensitive data from SharedPreferences
  /// - Sensitive conversation from SecureStorage (encrypted)
  Future<LanguageProficiency?> loadLanguageProficiency(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'calibration_$languageCode';
      final jsonStr = prefs.getString(key);
      
      if (jsonStr != null) {
        final json = jsonDecode(jsonStr);
        
        // Load non-sensitive data from SharedPreferences
        final nonSensitiveData = {
          'languageCode': json['languageCode'],
          'selfAssessedLevel': json['selfAssessedLevel'] ?? 'beginner',
          'aiDeterminedLevel': json['aiDeterminedLevel'] ?? 'beginner',
          'calibratedAt': json['calibratedAt'],
          'quizScore': json['quizScore'] ?? 0,
          'totalQuizQuestions': json['totalQuizQuestions'] ?? 5,
          'isCalibrated': json['isCalibrated'] ?? false,
        };
        
        // Load sensitive conversation from SecureStorage
        final secureKey = 'assessment_conversation_$languageCode';
        final conversationData = await SecureStorage.readEncrypted<List>(secureKey);
        final conversation = conversationData
            ?.map((m) => ChatAssessmentMessage.fromJson(m as Map<String, dynamic>))
            .toList() ?? [];
        
        // Reconstruct complete LanguageProficiency object
        final proficiency = LanguageProficiency(
          languageCode: nonSensitiveData['languageCode'],
          selfAssessedLevel: nonSensitiveData['selfAssessedLevel'],
          aiDeterminedLevel: nonSensitiveData['aiDeterminedLevel'],
          calibratedAt: DateTime.parse(nonSensitiveData['calibratedAt']),
          assessmentConversation: conversation,
          quizScore: nonSensitiveData['quizScore'],
          totalQuizQuestions: nonSensitiveData['totalQuizQuestions'],
          isCalibrated: nonSensitiveData['isCalibrated'],
        );
        
        _languageProficiencies[languageCode] = proficiency;
        return proficiency;
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ Error loading calibration for $languageCode: $e');
      return null;
    }
  }

  /// Load all calibration data on app start
  /// 
  /// MIGRATION LOGIC:
  /// 1. Check SharedPreferences for calibration data
  /// 2. If old format (has assessmentConversation), migrate to new split storage
  /// 3. Load non-sensitive data from SharedPreferences
  /// 4. Load sensitive conversation data from SecureStorage
  Future<void> _loadCalibrationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (var key in keys) {
        if (key.startsWith('calibration_')) {
          final languageCode = key.replaceFirst('calibration_', '');
          final jsonStr = prefs.getString(key);
          
          if (jsonStr != null) {
            try {
              final json = jsonDecode(jsonStr);
              
              // MIGRATION: Check if this is old format (contains assessmentConversation)
              if (json.containsKey('assessmentConversation') && 
                  json['assessmentConversation'] != null &&
                  (json['assessmentConversation'] as List).isNotEmpty) {
                
                debugPrint('🔄 Migrating calibration data for $languageCode to encrypted storage');
                
                // Extract and save conversation to SecureStorage
                final conversationData = json['assessmentConversation'] as List;
                final secureKey = 'assessment_conversation_$languageCode';
                await SecureStorage.saveEncrypted(secureKey, conversationData);
                
                // Remove from SharedPreferences (keep only non-sensitive data)
                final migratedData = {
                  'languageCode': json['languageCode'],
                  'selfAssessedLevel': json['selfAssessedLevel'] ?? 'beginner',
                  'aiDeterminedLevel': json['aiDeterminedLevel'] ?? 'beginner',
                  'calibratedAt': json['calibratedAt'],
                  'quizScore': json['quizScore'] ?? 0,
                  'totalQuizQuestions': json['totalQuizQuestions'] ?? 5,
                  'isCalibrated': json['isCalibrated'] ?? false,
                };
                await prefs.setString(key, jsonEncode(migratedData));
                
                debugPrint('✅ Migration complete for $languageCode');
              }
              
              // Load non-sensitive data from SharedPreferences
              final nonSensitiveJson = jsonDecode(prefs.getString(key)!);
              
              // Load sensitive conversation from SecureStorage
              final secureKey = 'assessment_conversation_$languageCode';
              final conversationData = await SecureStorage.readEncrypted<List>(secureKey);
              final conversation = conversationData
                  ?.map((m) => ChatAssessmentMessage.fromJson(m as Map<String, dynamic>))
                  .toList() ?? [];
              
              // Reconstruct complete LanguageProficiency object
              _languageProficiencies[languageCode] = LanguageProficiency(
                languageCode: nonSensitiveJson['languageCode'],
                selfAssessedLevel: nonSensitiveJson['selfAssessedLevel'] ?? 'beginner',
                aiDeterminedLevel: nonSensitiveJson['aiDeterminedLevel'] ?? 'beginner',
                calibratedAt: DateTime.parse(nonSensitiveJson['calibratedAt']),
                assessmentConversation: conversation,
                quizScore: nonSensitiveJson['quizScore'] ?? 0,
                totalQuizQuestions: nonSensitiveJson['totalQuizQuestions'] ?? 5,
                isCalibrated: nonSensitiveJson['isCalibrated'] ?? false,
              );
              
            } catch (e) {
              debugPrint('⚠️ Error loading calibration for $languageCode: $e');
              // Continue loading other languages even if one fails
            }
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error loading calibration data: $e');
      // Gracefully handle - app can continue without calibration data
    }
  }

  /// Update self-assessed level for a language (before AI assessment)
  Future<void> updateSelfAssessment(String languageCode, String level) async {
    final existing = _languageProficiencies[languageCode];
    final proficiency = existing?.copyWith(selfAssessedLevel: level) ?? 
        LanguageProficiency(
          languageCode: languageCode,
          selfAssessedLevel: level,
        );
    
    await saveLanguageProficiency(proficiency);
  }

  /// Complete calibration with final results
  Future<void> completeCalibration({
    required String languageCode,
    required String finalLevel,
    required List<ChatAssessmentMessage> conversation,
    required int quizScore,
    required int totalQuestions,
  }) async {
    final existing = _languageProficiencies[languageCode];
    final proficiency = (existing ?? LanguageProficiency(languageCode: languageCode)).copyWith(
      aiDeterminedLevel: finalLevel,
      assessmentConversation: conversation,
      quizScore: quizScore,
      totalQuizQuestions: totalQuestions,
      isCalibrated: true,
      calibratedAt: DateTime.now(),
    );
    
    await saveLanguageProficiency(proficiency);
  }
}
