import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/models/models.dart';
import 'package:mojilearner_flutter/utils/level_validator.dart';

void main() {
  group('LanguageProficiency', () {
    test('constructor normalizes invalid levels', () {
      final proficiency = LanguageProficiency(
        languageCode: 'es',
        selfAssessedLevel: 'STARTER',
        aiDeterminedLevel: 'expert',
      );

      expect(proficiency.selfAssessedLevel, LevelValidator.beginner);
      expect(proficiency.aiDeterminedLevel, LevelValidator.beginner);
    });

    test('fromJson normalizes invalid levels', () {
      final proficiency = LanguageProficiency.fromJson({
        'languageCode': 'fr',
        'selfAssessedLevel': 'INTERMEDIATE',
        'aiDeterminedLevel': 'not-a-level',
        'calibratedAt': DateTime(2026, 1, 1).toIso8601String(),
        'assessmentConversation': <Map<String, dynamic>>[],
        'quizScore': 3,
        'totalQuizQuestions': 5,
        'isCalibrated': true,
      });

      expect(proficiency.selfAssessedLevel, LevelValidator.intermediate);
      expect(proficiency.aiDeterminedLevel, LevelValidator.beginner);
    });

    test('copyWith keeps valid fallback when new level is invalid', () {
      final proficiency = LanguageProficiency(
        languageCode: 'de',
        selfAssessedLevel: LevelValidator.advanced,
        aiDeterminedLevel: LevelValidator.intermediate,
      );

      final updated = proficiency.copyWith(aiDeterminedLevel: 'bad-level');

      expect(updated.selfAssessedLevel, LevelValidator.advanced);
      expect(updated.aiDeterminedLevel, LevelValidator.intermediate);
    });
  });
}
