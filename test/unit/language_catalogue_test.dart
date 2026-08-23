import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/language_names.dart';
import 'package:mojilearner_flutter/constants/pixel_flags.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The language list, its endonyms and its flags are three files that have to
/// agree. Adding a language to one and forgetting the others is the exact
/// drift that once left four shipped languages unreachable, so it is checked
/// rather than remembered.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  // The catalogue is a constant list; the provider is only the way to reach
  // it, and its constructor needs the mocked prefs above.
  List<String> shippedCodes() =>
      LanguageProvider().availableLanguages.map((l) => l.code).toList();

  group('language catalogue', () {
    test('every language names itself', () {
      for (final code in shippedCodes()) {
        expect(languageEndonyms, contains(code),
            reason: '$code would show its English name to everyone');
      }
    });

    test('every language has a flag', () {
      for (final code in shippedCodes()) {
        expect(pixelFlags, contains(code),
            reason: '$code would fall back to the blank plate');
      }
    });

    test('no orphan endonyms or flags', () {
      final shipped = shippedCodes().toSet();
      expect(languageEndonyms.keys.toSet().difference(shipped), isEmpty);
      expect(pixelFlags.keys.toSet().difference(shipped), isEmpty);
    });
  });

  group('flag art', () {
    test('every grid is 12x8 of known palette keys', () {
      final art = {...pixelFlags, 'fallback': pixelFlagFallback};
      for (final entry in art.entries) {
        expect(entry.value.length, pixelFlagRows,
            reason: '${entry.key} is not $pixelFlagRows rows tall');
        for (final row in entry.value) {
          expect(row.length, pixelFlagColumns,
              reason: '${entry.key} has a row of ${row.length} cells');
          for (final cell in row.split('')) {
            expect(pixelFlagPalette, contains(cell),
                reason: '${entry.key} uses unknown colour "$cell"');
          }
        }
      }
    });
  });

  group('endonyms', () {
    test('are not just the English names', () {
      // A regression where the endonym map is filled in by copying the
      // catalogue would be invisible on screen for Latin-script languages.
      final english = {
        for (final l in LanguageProvider().availableLanguages) l.code: l.name
      };
      final differing = languageEndonyms.entries
          .where((e) => e.value != english[e.key])
          .length;
      expect(differing, greaterThan(20));
    });

    test('Language.nativeName falls back to English for unknown codes', () {
      expect(const Language(code: 'es', name: 'Spanish').nativeName, 'Español');
      expect(const Language(code: 'xx', name: 'Xhosa').nativeName, 'Xhosa');
    });
  });
}
