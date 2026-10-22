import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/play/toy_chest.dart';
import 'package:mojilearner_flutter/constants/app_runtime_config.dart';
import 'package:mojilearner_flutter/models/models.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// A vocabulary that is just the list it is given, so no storage is touched.
class _FixedVocab extends VocabProvider {
  _FixedVocab(this._items);
  final List<ReviewItem> _items;

  @override
  List<ReviewItem> get items => _items;
}

ReviewItem word(String prompt, String answer) => ReviewItem(
      id: prompt,
      languageCode: 'es',
      prompt: prompt,
      answer: answer,
    );

/// The chest in a release build: the stock is off, so a toy opens only when the
/// player has learned enough to fill it, and says so when it does not.
void main() {
  late MockLanguageProvider language;
  late MockSettingsProvider settings;
  const hint = 'Learn a few more words to play';

  setUp(() {
    AppRuntimeConfig.debugStockContent = false;
    language = MockLanguageProvider();
    settings = MockSettingsProvider();
    when(() => language.targetLanguage)
        .thenReturn(const Language(code: 'es', name: 'Spanish'));
    when(() => language.nativeLanguage)
        .thenReturn(const Language(code: 'en', name: 'English'));
    when(() => settings.usePixelFont).thenReturn(true);
  });

  tearDown(() => AppRuntimeConfig.debugStockContent = null);

  Future<List<String>> openChest(
    WidgetTester tester,
    List<ReviewItem> words,
  ) async {
    final visited = <String>[];
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => ToyChestPicker.show(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      for (final toy in ChestToy.all)
        GoRoute(
          path: '/${toy.routeName}',
          name: toy.routeName,
          builder: (_, __) {
            visited.add(toy.routeName);
            return const Scaffold(body: Text('a game'));
          },
        ),
    ]);
    await pumpAppWithRouter(
      tester,
      router,
      languageProvider: language,
      settingsProvider: settings,
      vocabProvider: _FixedVocab(words),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return visited;
  }

  testWidgets('with nothing learned every toy says what it needs',
      (tester) async {
    await openChest(tester, const []);

    expect(find.text(hint), findsNWidgets(ChestToy.all.length));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a shut toy does not open, and the chest stays up',
      (tester) async {
    final visited = await openChest(tester, const []);

    await tester.tap(find.text('Pounce'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(visited, isEmpty);
    expect(find.text('TOY CHEST'), findsOneWidget);
  });

  testWidgets('enough words open the word games, and Fetch stays shut',
      (tester) async {
    final visited = await openChest(tester, [
      word('sol', 'sun'),
      word('luz', 'light'),
      word('mar', 'sea'),
      word('pan', 'bread'),
      word('ojo', 'eye'),
      word('pie', 'foot'),
    ]);

    // Only Fetch the Words, which needs sentences, still says it is shut.
    expect(find.text(hint), findsOneWidget);

    await tester.tap(find.text('Pounce'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(visited, ['play_pounce']);
  });

  testWidgets('in development, with the stock on, nothing is shut',
      (tester) async {
    AppRuntimeConfig.debugStockContent = true;
    await openChest(tester, const []);

    expect(find.text(hint), findsNothing);
  });
}
