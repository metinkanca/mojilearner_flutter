import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../constants/app_runtime_config.dart';
import '../repositories/calibration_repository.dart';
import '../utils/level_validator.dart';

/// Owns language-calibration state: which languages the user has been
/// assessed in and at what proficiency. Extracted from UserProvider so the
/// onboarding/assessment flow has a single, focused owner.
class CalibrationProvider extends ChangeNotifier {
  CalibrationProvider({CalibrationRepository? repository})
      : _repository = repository ?? CalibrationRepository() {
    loadFuture = _load();
  }

  final CalibrationRepository _repository;
  final Map<String, LanguageProficiency> _languageProficiencies = {};
  bool _isLoading = true;

  late final Future<void> loadFuture;

  bool get isLoading => _isLoading;

  bool get hasAnyCalibratedLanguage =>
      _languageProficiencies.values.any((p) => p.isCalibrated);

  bool isLanguageCalibrated(String languageCode) =>
      _languageProficiencies[languageCode]?.isCalibrated ?? false;

  LanguageProficiency? getLanguageProficiency(String languageCode) =>
      _languageProficiencies[languageCode];

  /// Language seeded by [AppRuntimeConfig.skipOnboarding]. Matches
  /// `LanguageProvider`'s default target language, so the seeded proficiency
  /// describes the language the rest of the app will actually be using.
  static const String _skipOnboardingLanguage = 'es';

  Future<void> _load() async {
    _languageProficiencies.addAll(await _repository.loadAll());
    if (AppRuntimeConfig.skipOnboarding && !hasAnyCalibratedLanguage) {
      // Held in memory and deliberately not saved: the point is to reach the
      // home screen, not to write a fake assessment into the user's history.
      _languageProficiencies[_skipOnboardingLanguage] = LanguageProficiency(
        languageCode: _skipOnboardingLanguage,
        selfAssessedLevel: LevelValidator.beginner,
        aiDeterminedLevel: LevelValidator.beginner,
        isCalibrated: true,
      );
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveLanguageProficiency(LanguageProficiency proficiency) async {
    _languageProficiencies[proficiency.languageCode] = proficiency;
    try {
      await _repository.save(proficiency);
      notifyListeners();
    } catch (e) {
      debugPrint(
          '⚠️ Error saving language proficiency for ${proficiency.languageCode}: $e');
      // Data remains available in memory.
      rethrow;
    }
  }

  /// Update self-assessed level for a language (before AI assessment).
  Future<void> updateSelfAssessment(String languageCode, String level) async {
    final existing = _languageProficiencies[languageCode];
    final proficiency = existing?.copyWith(selfAssessedLevel: level) ??
        LanguageProficiency(
          languageCode: languageCode,
          selfAssessedLevel: level,
        );
    await saveLanguageProficiency(proficiency);
  }

  /// Complete calibration with final results.
  Future<void> completeCalibration({
    required String languageCode,
    required String finalLevel,
    required List<ChatAssessmentMessage> conversation,
    required int quizScore,
    required int totalQuestions,
  }) async {
    final existing = _languageProficiencies[languageCode];
    final proficiency =
        (existing ?? LanguageProficiency(languageCode: languageCode)).copyWith(
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
