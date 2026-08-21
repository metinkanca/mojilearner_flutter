import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/models/models.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/screens/quiz_screen.dart';
import 'package:mojilearner_flutter/utils/srs_quiz_builder.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockUserProvider mockUser;
  late MockCharacterProvider mockCharacter;
  late MockLanguageProvider mockLanguage;
  late MockSettingsProvider mockSettings;
  late MockQuizProvider mockQuiz;

  setUp(() {
    mockUser = MockUserProvider();
    mockCharacter = MockCharacterProvider();
    mockLanguage = MockLanguageProvider();
    mockSettings = MockSettingsProvider();
    mockQuiz = MockQuizProvider();

    when(() => mockUser.stats).thenReturn(UserStats());
    when(() => mockCharacter.scaleReward(any())).thenReturn(3);
    when(() => mockLanguage.targetLanguage).thenReturn(
      const Language(code: 'es', name: 'Spanish', flag: '🇪🇸'),
    );
    when(() => mockSettings.usePixelFont).thenReturn(true);
    when(() => mockQuiz.hasSavedProgress).thenReturn(false);
  });

  /// Built synchronously and never loaded from storage — `testWidgets` runs
  /// under FakeAsync and awaiting SecureStorage would deadlock. Same reason
  /// as review_screen_test.
  VocabProvider buildVocab({required int itemCount}) {
    final vocab = VocabProvider();
    for (var i = 0; i < itemCount; i++) {
      vocab.addVocabulary(
        languageCode: 'es',
        prompt: 'palabra_$i',
        answer: 'word_$i',
      );
    }
    return vocab;
  }

  Future<void> pumpQuiz(WidgetTester tester, VocabProvider vocab) async {
    // The four options are shuffled, so the correct one can land in the lower
    // row. The default 800x600 surface cuts that row off and the tap misses.
    tester.view.physicalSize = const Size(1200, 2700);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(
      tester,
      const QuizScreen(),
      userProvider: mockUser,
      characterProvider: mockCharacter,
      languageProvider: mockLanguage,
      settingsProvider: mockSettings,
      quizProvider: mockQuiz,
      vocabProvider: vocab,
    );
    await tester.pump();
  }

  testWidgets('falls back to stock questions when the queue is empty',
      (tester) async {
    await pumpQuiz(tester, VocabProvider());

    expect(find.text('Greetings'), findsOneWidget);
    expect(find.text('palabra_0'), findsNothing);
  });

  testWidgets('falls back when the queue is too thin for distractors',
      (tester) async {
    await pumpQuiz(
      tester,
      buildVocab(itemCount: SrsQuizBuilder.minPoolSize - 1),
    );

    expect(find.text('Greetings'), findsOneWidget);
  });

  testWidgets('asks about a due review item once the queue is big enough',
      (tester) async {
    await pumpQuiz(tester, buildVocab(itemCount: 8));

    expect(find.text('Greetings'), findsNothing);
    expect(find.text('What does this mean?'), findsOneWidget);
    expect(find.textContaining('palabra_'), findsOneWidget);
  });

  testWidgets('a correct answer reschedules the item out of the queue',
      (tester) async {
    final vocab = buildVocab(itemCount: 8);
    expect(vocab.dueCount(languageCode: 'es'), equals(8));

    await pumpQuiz(tester, vocab);

    // The prominent line is the term being tested; find its answer.
    final term = tester
        .widgetList<Text>(find.textContaining('palabra_'))
        .first
        .data!;
    final item = vocab.items.firstWhere((i) => i.prompt == term);

    await tester.tap(find.text(item.answer));
    await tester.pump();

    final graded = vocab.byId(item.id)!;
    expect(graded.repetitions, equals(1));
    expect(graded.lapses, equals(0));
    expect(graded.isDue(), isFalse);
  });

  testWidgets('a wrong answer counts as a lapse and stays due', (tester) async {
    final vocab = buildVocab(itemCount: 8);

    await pumpQuiz(tester, vocab);

    final term = tester
        .widgetList<Text>(find.textContaining('palabra_'))
        .first
        .data!;
    final item = vocab.items.firstWhere((i) => i.prompt == term);

    // Any option that isn't the right one.
    final wrong = vocab.items
        .map((i) => i.answer)
        .firstWhere((a) => a != item.answer && find.text(a).evaluate().isNotEmpty);

    await tester.tap(find.text(wrong));
    await tester.pump();

    final graded = vocab.byId(item.id)!;
    expect(graded.lapses, equals(1));
    expect(graded.repetitions, equals(0));
  });

  testWidgets('stock questions do not touch the review queue', (tester) async {
    final vocab = VocabProvider();

    await pumpQuiz(tester, vocab);
    await tester.tap(find.text('Hola'));
    await tester.pump();

    expect(vocab.items, isEmpty);
  });

  // The bond half of the quiz payout. Unlike XP and coins it is not scaled by
  // sickness and cannot be bought, so it is settled once, at the end, from the
  // whole score rather than per answer.
  testWidgets('finishing a quiz credits the bond once, with the score',
      (tester) async {
    // The stock quiz, used whenever the review queue is too thin.
    const stockQuestionCount = 5;

    when(() => mockUser.addXp(any())).thenAnswer((_) async {});
    when(() => mockUser.addCoins(any())).thenAnswer((_) async {});
    when(() => mockCharacter.isSick).thenReturn(false);
    when(() => mockCharacter.applyQuizRewards(
          happinessDelta: any(named: 'happinessDelta'),
          hungerDelta: any(named: 'hungerDelta'),
        )).thenReturn(null);
    when(() => mockQuiz.clearProgress()).thenAnswer((_) async {});

    await pumpQuiz(tester, VocabProvider());

    // Plays the whole quiz taking whichever option comes first, so the score
    // lands where it lands — this is about when bond is credited, not about
    // accuracy.
    for (var i = 0; i < stockQuestionCount; i++) {
      expect(
        mockCharacter.recordedQuizzes,
        isEmpty,
        reason: 'bond must not be credited before the last question',
      );

      await tester.tap(find.byType(AspectRatio).first);
      await tester.pump();
      await tester.tap(find.text('CONTINUE'));
      // Not pumpAndSettle: the last CONTINUE opens the rewards popup, whose
      // confetti never settles.
      await tester.pump(const Duration(milliseconds: 500));
    }

    expect(mockCharacter.recordedQuizzes, hasLength(1));
    expect(mockCharacter.recordedQuizzes.single.total, stockQuestionCount);
  });
}
