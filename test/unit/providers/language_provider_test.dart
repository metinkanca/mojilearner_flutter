import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LanguageProvider', () {
    test('should use default values when no persisted data', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      
      // Act
      final provider = LanguageProvider();
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Assert
      expect(provider.nativeLanguage.code, equals('en'));
      expect(provider.targetLanguage?.code, equals('es'));
      expect(provider.isLoading, isFalse);
    });

    test('should load persisted languages from SharedPreferences', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'native_language_code': 'fr',
        'target_language_code': 'de',
      });
      
      // Act
      final provider = LanguageProvider();
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Assert
      expect(provider.nativeLanguage.code, equals('fr'));
      expect(provider.targetLanguage?.code, equals('de'));
      expect(provider.isLoading, isFalse);
    });

    test('should fall back to defaults for unsupported saved language codes',
        () async {
      // Arrange ('he' was removed from availableLanguages)
      SharedPreferences.setMockInitialValues({
        'native_language_code': 'he',
        'target_language_code': 'he',
      });

      // Act
      final provider = LanguageProvider();
      await Future.delayed(const Duration(milliseconds: 150));

      // Assert: unknown codes are ignored, defaults retained
      expect(provider.nativeLanguage.code, equals('en'));
      expect(provider.targetLanguage?.code, equals('es'));
    });

    test('should update native language and persist', () async {
      // Arrange
      final provider = LanguageProvider();
      await Future.delayed(const Duration(milliseconds: 150));
      const french = Language(code: 'fr', name: 'French', flag: '🇫🇷');
      
      // Act
      await provider.setNativeLanguage(french);
      
      // Assert
      expect(provider.nativeLanguage, equals(french));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('native_language_code'), equals('fr'));
    });

    test('should update target language and persist', () async {
      // Arrange
      final provider = LanguageProvider();
      await Future.delayed(const Duration(milliseconds: 150));
      const german = Language(code: 'de', name: 'German', flag: '🇩🇪');
      
      // Act
      await provider.setTargetLanguage(german);
      
      // Assert
      expect(provider.targetLanguage, equals(german));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('target_language_code'), equals('de'));
    });

    test('should provide 27 available languages', () {
      // Arrange & Act
      final provider = LanguageProvider();
      
      // Assert
      expect(provider.availableLanguages.length, equals(27));
      expect(provider.availableLanguages.any((l) => l.code == 'es'), isTrue);
      expect(provider.availableLanguages.any((l) => l.code == 'ja'), isTrue);
      expect(provider.availableLanguages.any((l) => l.code == 'hu'), isTrue);
      expect(provider.availableLanguages.any((l) => l.code == 'he'), isFalse);
    });
  });
}
