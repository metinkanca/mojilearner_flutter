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

  /// Every language the player has actually been assessed in.
  ///
  /// The pet's bond stage reads this rather than only the current language:
  /// its fluency gate ratchets on the best level ever reached, so switching
  /// target language cannot walk the pet back down the ladder. See
  /// `utils/bond_context.dart`.
  Iterable<LanguageProficiency> get calibratedProficiencies =>
      _languageProficiencies.values.where((p) => p.isCalibrated);

  /// Every assessed level on record, one per language that has been
  /// calibrated.
  ///
  /// Exposed for callers that care about the player rather than about one
  /// language. The bond ladder is the case: gating the pet's stage on the
  /// currently selected language would un-grow the pet the moment its owner
  /// started a second one. See `utils/bond_context.dart`.
  Iterable<String?> get assessedLevels =>
      _languageProficiencies.values.map((p) => p.aiDeterminedLevel);

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
