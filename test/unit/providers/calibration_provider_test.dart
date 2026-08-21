import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/models/models.dart';
import 'package:mojilearner_flutter/providers/calibration_provider.dart';
import 'package:mojilearner_flutter/utils/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SecureStorage.deleteAll();
  });

  group('CalibrationProvider', () {
    test('starts empty when nothing is persisted', () async {
      final provider = CalibrationProvider();
      await provider.loadFuture;

      expect(provider.hasAnyCalibratedLanguage, isFalse);
      expect(provider.isLanguageCalibrated('es'), isFalse);
      expect(provider.getLanguageProficiency('es'), isNull);
      expect(provider.isLoading, isFalse);
    });

    test('save and reload round-trips proficiency with conversation', () async {
      final provider = CalibrationProvider();
      await provider.loadFuture;

      await provider.completeCalibration(
        languageCode: 'es',
        finalLevel: 'intermediate',
        conversation: [
          ChatAssessmentMessage(
            id: 'm1',
            content: 'Hola, me llamo Bob',
            sender: 'user',
            timestamp: DateTime(2026, 8, 1, 12),
          ),
        ],
        quizScore: 4,
        totalQuestions: 5,
      );

      expect(provider.isLanguageCalibrated('es'), isTrue);
      expect(provider.hasAnyCalibratedLanguage, isTrue);

      // A fresh provider must reconstruct the same state from storage.
      final reloaded = CalibrationProvider();
      await reloaded.loadFuture;

      final proficiency = reloaded.getLanguageProficiency('es');
      expect(proficiency, isNotNull);
      expect(proficiency!.aiDeterminedLevel, equals('intermediate'));
      expect(proficiency.quizScore, equals(4));
      expect(proficiency.isCalibrated, isTrue);
      expect(proficiency.assessmentConversation, hasLength(1));
      expect(proficiency.assessmentConversation.first.content,
          equals('Hola, me llamo Bob'));
    });

    test('conversation is stored encrypted, not in SharedPreferences',
        () async {
      final provider = CalibrationProvider();
      await provider.loadFuture;

      await provider.completeCalibration(
        languageCode: 'fr',
        finalLevel: 'beginner',
        conversation: [
          ChatAssessmentMessage(
            id: 'm1',
            content: 'Bonjour, je suis Bob',
            sender: 'user',
            timestamp: DateTime(2026, 8, 1, 12),
          ),
        ],
        quizScore: 2,
        totalQuestions: 5,
      );

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('calibration_fr');
      expect(stored, isNotNull);
      expect(stored, isNot(contains('Bonjour, je suis Bob')));
    });

    test('updateSelfAssessment creates an uncalibrated entry', () async {
      final provider = CalibrationProvider();
      await provider.loadFuture;

      await provider.updateSelfAssessment('ja', 'advanced');

      final proficiency = provider.getLanguageProficiency('ja');
      expect(proficiency, isNotNull);
      expect(proficiency!.selfAssessedLevel, equals('advanced'));
      expect(proficiency.isCalibrated, isFalse);
      expect(provider.hasAnyCalibratedLanguage, isFalse);
    });

    test('migrates legacy entries with plaintext conversations', () async {
      // Old format: conversation embedded in the SharedPreferences JSON.
      SharedPreferences.setMockInitialValues({
        'calibration_de': jsonEncode({
          'languageCode': 'de',
          'selfAssessedLevel': 'beginner',
          'aiDeterminedLevel': 'intermediate',
          'calibratedAt': '2026-01-15T10:00:00.000',
          'quizScore': 3,
          'totalQuizQuestions': 5,
          'isCalibrated': true,
          'assessmentConversation': [
            {
              'id': 'legacy1',
              'content': 'Guten Tag, ich bin Bob',
              'sender': 'user',
              'timestamp': '2026-01-15T09:55:00.000',
            },
          ],
        }),
      });

      final provider = CalibrationProvider();
      await provider.loadFuture;

      // Data fully loaded, including the conversation.
      final proficiency = provider.getLanguageProficiency('de');
      expect(proficiency, isNotNull);
      expect(proficiency!.isCalibrated, isTrue);
      expect(proficiency.assessmentConversation, hasLength(1));

      // Plaintext conversation removed from SharedPreferences.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('calibration_de'),
          isNot(contains('Guten Tag, ich bin Bob')));
    });
  });
}
