import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/providers/quiz_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('QuizProvider', () {
    test('should start with no saved progress', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      
      // Act
      final provider = QuizProvider();
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Assert
      expect(provider.hasSavedProgress, isFalse);
      expect(provider.savedQuestionIndex, isNull);
      expect(provider.savedScore, isNull);
    });

    test('should load saved progress from SharedPreferences', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'quiz_saved_index': 5,
        'quiz_saved_score': 3,
      });
      
      // Act
      final provider = QuizProvider();
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Assert
      expect(provider.hasSavedProgress, isTrue);
      expect(provider.savedQuestionIndex, equals(5));
      expect(provider.savedScore, equals(3));
    });

    test('should save quiz progress and persist', () async {
      // Arrange
      final provider = QuizProvider();
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Act
      await provider.saveProgress(7, 4);
      
      // Assert
      expect(provider.savedQuestionIndex, equals(7));
      expect(provider.savedScore, equals(4));
      expect(provider.hasSavedProgress, isTrue);
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('quiz_saved_index'), equals(7));
      expect(prefs.getInt('quiz_saved_score'), equals(4));
    });

    test('should clear quiz progress', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'quiz_saved_index': 5,
        'quiz_saved_score': 3,
      });
      final provider = QuizProvider();
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Act
      await provider.clearProgress();
      
      // Assert
      expect(provider.hasSavedProgress, isFalse);
      expect(provider.savedQuestionIndex, isNull);
      expect(provider.savedScore, isNull);
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('quiz_saved_index'), isNull);
      expect(prefs.getInt('quiz_saved_score'), isNull);
    });

    test('should update state when saving progress multiple times', () async {
      // Arrange
      final provider = QuizProvider();
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Act
      await provider.saveProgress(1, 0);
      await provider.saveProgress(2, 1);
      await provider.saveProgress(3, 2);
      
      // Assert
      expect(provider.savedQuestionIndex, equals(3));
      expect(provider.savedScore, equals(2));
      expect(provider.hasSavedProgress, isTrue);
    });
  });
}
