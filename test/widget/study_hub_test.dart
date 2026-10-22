import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/study_hub.dart';
import 'package:mojilearner_flutter/models/models.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

class MockVocabProvider extends Mock implements VocabProvider {}

/// The study button's dialog: the one way into the review queue and the list of
/// mistakes, neither of which has a tab any more.
void main() {
  late MockVocabProvider vocab;
  late MockMistakesProvider mistakes;
  late MockLanguageProvider language;
  late MockSettingsProvider settings;

  setUp(() {
    vocab = MockVocabProvider();
    mistakes = MockMistakesProvider();
    language = MockLanguageProvider();
    settings = MockSettingsProvider();
    when(() => settings.usePixelFont).thenReturn(true);
    when(() => language.targetLanguage)
        .thenReturn(const Language(code: 'en', name: 'English'));
    when(() => vocab.dueCount(languageCode: any(named: 'languageCode')))
        .thenReturn(0);
    when(() => mistakes.mistakes).thenReturn(const []);
  });

  GoRouter router() => GoRouter(routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => StudyHub.show(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/review',
          name: 'review',
          builder: (_, __) => const Text('the review page'),
        ),
        GoRoute(
          path: '/mistakes',
          name: 'mistakes',
          builder: (_, __) => const Text('the mistakes page'),
        ),
      ]);

  Future<void> open(WidgetTester tester) async {
    await pumpAppWithRouter(
      tester,
      router(),
      vocabProvider: vocab,
      mistakesProvider: mistakes,
      languageProvider: language,
      settingsProvider: settings,
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('offers review and mistakes', (tester) async {
    await open(tester);

    expect(find.byKey(const ValueKey('study-review')), findsOneWidget);
    expect(find.byKey(const ValueKey('study-mistakes')), findsOneWidget);
    expect(find.text('REVIEW'), findsOneWidget);
  });

  testWidgets('each row carries its count, and nothing when there is none',
      (tester) async {
    when(() => vocab.dueCount(languageCode: any(named: 'languageCode')))
        .thenReturn(12);
    when(() => mistakes.mistakes).thenReturn([
      for (var i = 0; i < 3; i++)
        Mistake(
          id: '$i',
          original: 'I goed home.',
          correction: 'I went home.',
          explanation: 'Düzensiz fiil.',
          type: 'grammar',
          timestamp: DateTime(2026, 10, 22),
        ),
    ]);
    await open(tester);

    expect(
        find.descendant(
            of: find.byKey(const ValueKey('study-review')),
            matching: find.text('12')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('study-mistakes')),
            matching: find.text('3')),
        findsOneWidget);
  });

  testWidgets('an empty queue and list show no counts', (tester) async {
    await open(tester);

    expect(find.text('0'), findsNothing);
  });

  testWidgets('review goes to the review page, and closes the dialog',
      (tester) async {
    await open(tester);

    await tester.tap(find.byKey(const ValueKey('study-review')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('the review page'), findsOneWidget);
    expect(find.byType(StudyHub), findsNothing);
  });

  testWidgets('mistakes goes to the mistakes page', (tester) async {
    await open(tester);

    await tester.tap(find.byKey(const ValueKey('study-mistakes')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('the mistakes page'), findsOneWidget);
  });
}
