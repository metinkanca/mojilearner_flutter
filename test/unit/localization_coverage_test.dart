import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/scenarios.dart';
import 'package:mojilearner_flutter/l10n/app_localizations.dart';

/// Guards the translation catalogue itself.
///
/// A missing key does not fail the build — gen-l10n silently falls back to
/// English — so without a test like this a new string ships untranslated to
/// every locale and nobody notices until a user complains.
void main() {
  final arbDir = Directory('lib/l10n');

  Map<String, dynamic> readArb(String locale) {
    final file = File('${arbDir.path}/app_$locale.arb');
    return json.decode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  /// Real message keys, excluding the `@`-prefixed metadata entries.
  Set<String> messageKeys(Map<String, dynamic> arb) =>
      arb.keys.where((k) => !k.startsWith('@')).toSet();

  final template = readArb('en');
  final templateKeys = messageKeys(template);

  final locales = AppLocalizations.supportedLocales
      .map((l) => l.languageCode)
      .where((code) => code != 'en')
      .toList();

  group('translation coverage', () {
    test('the app ships more than one locale', () {
      expect(locales, isNotEmpty);
      expect(templateKeys, isNotEmpty);
    });

    test('every locale defines every key in the template', () {
      final gaps = <String, List<String>>{};

      for (final locale in locales) {
        final missing =
            templateKeys.difference(messageKeys(readArb(locale))).toList()
              ..sort();
        if (missing.isNotEmpty) gaps[locale] = missing;
      }

      expect(gaps, isEmpty,
          reason: 'these locales would silently fall back to English: $gaps');
    });

    test('no locale defines a key the template does not', () {
      // A stale key is dead weight and usually means a rename went half-done.
      final strays = <String, List<String>>{};

      for (final locale in locales) {
        final extra =
            messageKeys(readArb(locale)).difference(templateKeys).toList()
              ..sort();
        if (extra.isNotEmpty) strays[locale] = extra;
      }

      expect(strays, isEmpty);
    });
  });

  group('character encoding', () {
    /// Bytes that are valid UTF-8 but were written by something that read the
    /// file as cp1252 first. The result is the "Ã©" family of garbage, and it
    /// has shipped to users twice: 215 strings in one round of repairs, 28
    /// more that survived it.
    ///
    /// The check is mechanical rather than a blocklist of bad glyphs. A
    /// mangled string round-trips back to bytes and decodes as *valid, and
    /// different*, UTF-8. Healthy text cannot: it either holds a character
    /// the byte map has no slot for, or the decode fails.
    List<int>? toBytes(String s) {
      final out = <int>[];
      for (final rune in s.runes) {
        if (rune <= 0xFF) {
          out.add(rune);
          continue;
        }
        final slot = _cp1252High[rune];
        if (slot == null) return null; // Not representable: text is fine.
        out.add(slot);
      }
      return out;
    }

    bool looksMangled(String value) {
      final bytes = toBytes(value);
      if (bytes == null) return false;

      final String decoded;
      try {
        decoded = utf8.decode(bytes);
      } on FormatException {
        return false;
      }
      if (decoded == value) return false;

      // The round trip alone is not proof. Czech "JAK HODNOTIS" with its
      // real diacritics is I-acute followed by S-caron, which happens to be
      // a valid two-byte sequence and decodes to a combining mark -- healthy
      // text that the arithmetic cannot tell from garbage.
      //
      // What separates them is the *result*. Un-mangling real mojibake gives
      // back ordinary composed letters; a coincidence like the Czech one
      // gives back a bare combining mark, a control character, or U+FFFD,
      // none of which any translation is written with.
      return !decoded.runes.any((r) =>
          (r >= 0x0300 && r <= 0x036F) || // combining diacritics
          (r < 0x20 && r != 0x0A) || // C0 controls
          (r >= 0x7F && r <= 0x9F) || // DEL and C1 controls
          r == 0xFFFD); // replacement character
    }

    test('no locale ships mis-encoded text', () {
      final broken = <String>[];

      for (final locale in [...locales, 'en']) {
        final arb = readArb(locale);
        for (final key in messageKeys(arb)) {
          final value = arb[key];
          if (value is String && looksMangled(value)) {
            broken.add('$locale/$key: $value');
          }
        }
      }

      expect(broken, isEmpty,
          reason: 'these strings were written UTF-8 and read back as cp1252');
    });
  });

  group('placeholder integrity', () {
    /// Placeholders are `{name}` — a translation that drops or renames one
    /// produces a literal brace on screen or a build failure.
    Set<String> placeholders(String value) => RegExp(r'\{(\w+)\}')
        .allMatches(value)
        .map((m) => m.group(1)!)
        .where((name) => name != 'count')
        .toSet();

    test('every translation keeps the template placeholders', () {
      final broken = <String>[];

      for (final locale in locales) {
        final arb = readArb(locale);
        for (final key in templateKeys) {
          final source = template[key];
          final translated = arb[key];
          if (source is! String || translated is! String) continue;

          final expected = placeholders(source);
          if (expected.isEmpty) continue;

          final actual = placeholders(translated);
          if (!actual.containsAll(expected)) {
            broken.add('$locale/$key: expected $expected, got $actual');
          }
        }
      }

      expect(broken, isEmpty);
    });

    test('plural messages stay plural in every locale', () {
      final pluralKeys = templateKeys.where((key) {
        final value = template[key];
        return value is String && value.contains(', plural,');
      }).toList();

      expect(pluralKeys, isNotEmpty,
          reason: 'expected at least one ICU plural in the template');

      final broken = <String>[];
      for (final locale in locales) {
        final arb = readArb(locale);
        for (final key in pluralKeys) {
          final value = arb[key];
          if (value is! String || !value.contains(', plural,')) {
            broken.add('$locale/$key');
            continue;
          }
          // ICU requires an `other` branch; without it gen-l10n throws.
          if (!value.contains('other{')) broken.add('$locale/$key (no other)');
        }
      }

      expect(broken, isEmpty);
    });
  });

  group('scenario objectives resolve in every locale', () {
    testWidgets('no objective or title falls through to an empty string',
        (tester) async {
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = await AppLocalizations.delegate.load(locale);

        for (final scenario in ScenarioCatalog.all) {
          expect(scenario.title(l10n).trim(), isNotEmpty,
              reason: '${scenario.id} title empty in ${locale.languageCode}');

          for (final objective in scenario.objectives) {
            expect(objective.label(l10n).trim(), isNotEmpty,
                reason: '${scenario.id}/${objective.id} empty in '
                    '${locale.languageCode}');
          }
        }
      }
    });

    testWidgets('objectives are actually localized, not English everywhere',
        (tester) async {
      // Catches the failure mode this test exists for: keys present only in
      // the template, silently falling back to English in every locale.
      final english = await AppLocalizations.delegate.load(const Locale('en'));
      final coffee = ScenarioCatalog.byId('coffee')!;
      final objective = coffee.objectives.first;

      for (final code in ['ja', 'de', 'tr', 'ru', 'ar']) {
        final l10n = await AppLocalizations.delegate.load(Locale(code));
        expect(objective.label(l10n), isNot(equals(objective.label(english))),
            reason: '$code still shows the English objective');
      }
    });
  });
}

/// The characters cp1252 puts in 0x80..0x9F, which is the whole reason a
/// mangled string can carry a curly quote where a raw byte belongs. Latin-1
/// covers everything below 0x100, so only these need naming.
const Map<int, int> _cp1252High = {
  0x20AC: 0x80, 0x201A: 0x82, 0x0192: 0x83, 0x201E: 0x84, 0x2026: 0x85,
  0x2020: 0x86, 0x2021: 0x87, 0x02C6: 0x88, 0x2030: 0x89, 0x0160: 0x8A,
  0x2039: 0x8B, 0x0152: 0x8C, 0x017D: 0x8E, 0x2018: 0x91, 0x2019: 0x92,
  0x201C: 0x93, 0x201D: 0x94, 0x2022: 0x95, 0x2013: 0x96, 0x2014: 0x97,
  0x02DC: 0x98, 0x2122: 0x99, 0x0161: 0x9A, 0x203A: 0x9B, 0x0153: 0x9C,
  0x017E: 0x9E, 0x0178: 0x9F,
};
