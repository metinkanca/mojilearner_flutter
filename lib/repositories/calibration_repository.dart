import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../utils/secure_storage.dart';

/// Persists language-calibration data across split storage:
/// - SharedPreferences holds the non-sensitive gamification fields
///   (levels, scores, flags) under `calibration_<code>`.
/// - SecureStorage holds the encrypted assessment conversation under
///   `assessment_conversation_<code>`.
class CalibrationRepository {
  static const String _prefsKeyPrefix = 'calibration_';
  static const String _secureKeyPrefix = 'assessment_conversation_';

  /// Loads every stored language proficiency, migrating any legacy entries
  /// that still carry their assessment conversation in SharedPreferences.
  Future<Map<String, LanguageProficiency>> loadAll() async {
    final result = <String, LanguageProficiency>{};
    try {
      final prefs = await SharedPreferences.getInstance();

      for (final key in prefs.getKeys()) {
        if (!key.startsWith(_prefsKeyPrefix)) continue;
        final languageCode = key.substring(_prefsKeyPrefix.length);

        try {
          final jsonStr = prefs.getString(key);
          if (jsonStr == null) continue;
          var json = jsonDecode(jsonStr) as Map<String, dynamic>;

          // MIGRATION: old format stored the conversation in plaintext prefs.
          final legacyConversation = json['assessmentConversation'];
          if (legacyConversation is List && legacyConversation.isNotEmpty) {
            debugPrint(
                '🔄 Migrating calibration data for $languageCode to encrypted storage');
            await SecureStorage.saveEncrypted(
                '$_secureKeyPrefix$languageCode', legacyConversation);
            json = _nonSensitiveFields(json);
            await prefs.setString(key, jsonEncode(json));
            debugPrint('✅ Migration complete for $languageCode');
          }

          result[languageCode] = LanguageProficiency(
            languageCode: json['languageCode'] ?? languageCode,
            selfAssessedLevel: json['selfAssessedLevel'] ?? 'beginner',
            aiDeterminedLevel: json['aiDeterminedLevel'] ?? 'beginner',
            calibratedAt: DateTime.parse(json['calibratedAt']),
            assessmentConversation: await _loadConversation(languageCode),
            quizScore: json['quizScore'] ?? 0,
            totalQuizQuestions: json['totalQuizQuestions'] ?? 5,
            isCalibrated: json['isCalibrated'] ?? false,
          );
        } catch (e) {
          debugPrint('⚠️ Error loading calibration for $languageCode: $e');
          // Continue loading other languages even if one fails.
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error loading calibration data: $e');
      // App can continue without calibration data.
    }
    return result;
  }

  /// Saves a proficiency, splitting sensitive and non-sensitive fields.
  Future<void> save(LanguageProficiency proficiency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefsKeyPrefix${proficiency.languageCode}',
      jsonEncode(_nonSensitiveFields(proficiency.toJson())),
    );

    if (proficiency.assessmentConversation.isNotEmpty) {
      await SecureStorage.saveEncrypted(
        '$_secureKeyPrefix${proficiency.languageCode}',
        proficiency.assessmentConversation.map((m) => m.toJson()).toList(),
      );
    }
  }

  Future<List<ChatAssessmentMessage>> _loadConversation(
      String languageCode) async {
    final data = await SecureStorage.readEncrypted<List>(
        '$_secureKeyPrefix$languageCode');
    return data
            ?.map((m) => ChatAssessmentMessage.fromJson(
                Map<String, dynamic>.from(m as Map)))
            .toList() ??
        [];
  }

  Map<String, dynamic> _nonSensitiveFields(Map<String, dynamic> json) => {
        'languageCode': json['languageCode'],
        'selfAssessedLevel': json['selfAssessedLevel'] ?? 'beginner',
        'aiDeterminedLevel': json['aiDeterminedLevel'] ?? 'beginner',
        'calibratedAt': json['calibratedAt'],
        'quizScore': json['quizScore'] ?? 0,
        'totalQuizQuestions': json['totalQuizQuestions'] ?? 5,
        'isCalibrated': json['isCalibrated'] ?? false,
      };
}
