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
