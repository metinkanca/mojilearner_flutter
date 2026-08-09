import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/quiz_cache.dart';

class QuizProvider extends ChangeNotifier {
  static const String _cacheKey = 'quiz_cached_set';

  int? _savedQuestionIndex;
  int? _savedScore;
  bool _hasSavedProgress = false;
  CachedQuiz? _cachedQuiz;

  int? get savedQuestionIndex => _savedQuestionIndex;
  int? get savedScore => _savedScore;
  bool get hasSavedProgress => _hasSavedProgress;

  QuizProvider() {
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    _savedQuestionIndex = prefs.getInt('quiz_saved_index');
    _savedScore = prefs.getInt('quiz_saved_score');
    _cachedQuiz = QuizCache.decode(prefs.getString(_cacheKey));
    
    if (_savedQuestionIndex != null && _savedScore != null) {
      _hasSavedProgress = true;
    } else {
      _hasSavedProgress = false;
    }
    notifyListeners();
  }

  Future<void> saveProgress(int index, int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quiz_saved_index', index);
    await prefs.setInt('quiz_saved_score', score);
    
    _savedQuestionIndex = index;
    _savedScore = score;
    _hasSavedProgress = true;
    notifyListeners();
  }

  Future<void> clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('quiz_saved_index');
    await prefs.remove('quiz_saved_score');
    
    _savedQuestionIndex = null;
    _savedScore = null;
    _hasSavedProgress = false;
    notifyListeners();
  }

  // ==================== GENERATED QUIZ CACHE ====================

  /// The cached set, if one is still valid for this learner state today.
  ///
  /// Returns null whenever the language, the review queue, or the day has
  /// changed — the caller then pays for a fresh generation.
  CachedQuiz? usableCachedQuiz({
    required String languageCode,
    required String fingerprint,
    DateTime? now,
  }) {
    final usable = QuizCache.isUsable(
      _cachedQuiz,
      languageCode: languageCode,
      fingerprint: fingerprint,
      now: now ?? DateTime.now(),
    );
    return usable ? _cachedQuiz : null;
  }

  Future<void> cacheQuiz(CachedQuiz cached) async {
    _cachedQuiz = cached;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, QuizCache.encode(cached));
    } catch (e) {
      // A cache that fails to persist just costs one more generation.
      debugPrint('⚠️ QUIZ: Failed to cache generated quiz - $e');
    }
  }

  Future<void> clearCachedQuiz() async {
    _cachedQuiz = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (e) {
      debugPrint('⚠️ QUIZ: Failed to clear cached quiz - $e');
    }
  }
}
