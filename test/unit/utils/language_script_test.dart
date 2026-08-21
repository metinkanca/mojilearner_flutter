import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/utils/language_script.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // LanguageProvider reads prefs in its constructor, so the binding and a
  // mock store have to exist before the catalogue can be inspected.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));
  group('LanguageScript.guideFor', () {
    test('maps each language to the system its learners expect', () {
      expect(LanguageScript.guideFor('ja'), equals(ScriptGuide.romaji));
      expect(LanguageScript.guideFor('zh'), equals(ScriptGuide.pinyin));
      expect(LanguageScript.guideFor('ko'), equals(ScriptGuide.romaja));
    });

    test('falls back to generic romanization for the rest', () {
      for (final code in ['ar', 'hi', 'th', 'ru', 'el', 'uk']) {
        expect(LanguageScript.guideFor(code),
            equals(ScriptGuide.romanization),
            reason: '$code should use generic romanization');
      }
    });

    test('Latin-script languages get nothing', () {
      for (final code in ['en', 'es', 'fr', 'de', 'it', 'pt', 'tr', 'vi']) {
        expect(LanguageScript.guideFor(code), isNull,
            reason: '$code is Latin script and needs no reading');
        expect(LanguageScript.needsReading(code), isFalse);
      }
    });

    test('is case-insensitive and null-safe', () {
      expect(LanguageScript.guideFor('JA'), equals(ScriptGuide.romaji));
      expect(LanguageScript.guideFor(null), isNull);
      expect(LanguageScript.needsReading(null), isFalse);
    });

    test('an unknown code is treated as Latin script', () {
      expect(LanguageScript.guideFor('xx'), isNull);
    });
  });

  group('LanguageScript - catalogue coverage', () {
    test('every code needing a reading is actually offered as a target', () {
      final offered = LanguageProvider()
          .availableLanguages
          .map((l) => l.code)
          .toSet();

      for (final code in LanguageScript.codesNeedingReading) {
        expect(offered, contains(code),
            reason: '$code needs a reading but is not a selectable language');
      }
    });

    test('no non-Latin target language is left without a guide', () {
      // Guards against adding, say, Hebrew or Bengali to the picker and
      // silently shipping it with no pronunciation support.
      const knownLatinScript = {
        'en', 'es', 'fr', 'de', 'it', 'pt', 'tr', 'nl', 'sv', 'pl',
        'id', 'vi', 'da', 'fi', 'no', 'cs', 'ro', 'hu',
      };

      for (final language in LanguageProvider().availableLanguages) {
        final covered = knownLatinScript.contains(language.code) ||
            LanguageScript.needsReading(language.code);
        expect(covered, isTrue,
            reason: '${language.name} (${language.code}) is neither known '
                'Latin script nor given a reading guide');
      }
    });
  });

  group('ScriptGuide labels and instructions', () {
    test('labels use the name learners actually search for', () {
      expect(ScriptGuide.romaji.label, equals('Romaji'));
      expect(ScriptGuide.pinyin.label, equals('Pinyin'));
      expect(ScriptGuide.romaja.label, equals('Romaja'));
      expect(ScriptGuide.romanization.label, equals('Reading'));
    });

    test('labelFor degrades to the generic label, never throws', () {
      expect(LanguageScript.labelFor('ja'), equals('Romaji'));
      expect(LanguageScript.labelFor('es'), equals('Reading'));
      expect(LanguageScript.labelFor(null), equals('Reading'));
    });

    test('each guide names a concrete system in its prompt instruction', () {
      expect(ScriptGuide.romaji.promptInstruction, contains('Hepburn'));
      expect(ScriptGuide.pinyin.promptInstruction, contains('tone marks'));
      expect(ScriptGuide.romaja.promptInstruction,
          contains('Revised Romanization'));

      for (final guide in ScriptGuide.values) {
        expect(guide.promptInstruction, isNotEmpty);
        expect(guide.label, isNotEmpty);
      }
    });
  });
}
