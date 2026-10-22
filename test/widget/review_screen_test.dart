import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/constants/gold.dart';
import 'package:mojilearner_flutter/models/models.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/screens/review_screen.dart';
import 'package:mojilearner_flutter/utils/srs_scheduler.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockUserProvider mockUser;
  late MockCharacterProvider mockCharacter;
  late MockLanguageProvider mockLanguage;
  late MockSettingsProvider mockSettings;

  setUp(() {
    mockUser = MockUserProvider();
    mockCharacter = MockCharacterProvider();
    mockLanguage = MockLanguageProvider();
    mockSettings = MockSettingsProvider();

    when(() => mockCharacter.scaleReward(any())).thenReturn(3);
    when(() => mockCharacter.rewardChat()).thenReturn(null);
    when(() => mockLanguage.targetLanguage).thenReturn(
      const Language(code: 'es', name: 'Spanish'),
    );
    when(() => mockSettings.usePixelFont).thenReturn(true);
  });

  /// Built synchronously and never loaded from storage: `testWidgets` runs
  /// under FakeAsync, so awaiting a platform-channel call (which is what
  /// SecureStorage does) would block forever. Writes are fire-and-forget, so
  /// adding items is safe here.
  VocabProvider buildVocab({int itemCount = 1}) {
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

  Future<void> pumpReview(WidgetTester tester, VocabProvider vocab) async {
    await pumpApp(
      tester,
      const ReviewScreen(),
      userProvider: mockUser,
      characterProvider: mockCharacter,
      languageProvider: mockLanguage,
      settingsProvider: mockSettings,
      vocabProvider: vocab,
    );
    await tester.pump();
  }

  testWidgets('shows the empty state when nothing is due', (tester) async {
    final vocab = VocabProvider();

    await pumpReview(tester, vocab);

    expect(find.text('All caught up!'), findsOneWidget);
    expect(find.text('Show answer'), findsNothing);
  });

  testWidgets('hides the answer until it is asked for', (tester) async {
    final vocab = buildVocab();

    await pumpReview(tester, vocab);

    expect(find.text('palabra_0'), findsOneWidget);
    expect(find.text('word_0'), findsNothing);
    expect(find.text('Show answer'), findsOneWidget);
  });

  testWidgets('reveals the answer and the four grades', (tester) async {
    final vocab = buildVocab();

    await pumpReview(tester, vocab);
    await tester.tap(find.text('Show answer'));
    await tester.pump();

    expect(find.text('word_0'), findsOneWidget);
    expect(find.text('Again'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);
  });

  testWidgets('grading advances to the next card with the answer re-hidden',
      (tester) async {
    final vocab = buildVocab(itemCount: 2);

    await pumpReview(tester, vocab);
    await tester.tap(find.text('Show answer'));
    await tester.pump();
    await tester.tap(find.text('Good'));
    await tester.pumpAndSettle();

    expect(find.text('palabra_1'), findsOneWidget);
    expect(find.text('word_1'), findsNothing);
    expect(find.text('Show answer'), findsOneWidget);
  });

  testWidgets('grading reschedules the item out of the due queue',
      (tester) async {
    final vocab = buildVocab();
    expect(vocab.dueCount(languageCode: 'es'), equals(1));

    await pumpReview(tester, vocab);
    await tester.tap(find.text('Show answer'));
    await tester.pump();
    await tester.tap(find.text('Good'));
    await tester.pumpAndSettle();

    expect(vocab.dueCount(languageCode: 'es'), equals(0));
    expect(vocab.items.first.repetitions, equals(1));
  });

  // Coins go through the sickness scaling; XP deliberately does not. XP is
  // what the pet's bond stage is projected from, and a sick pet slowing its
  // own closeness would make the relationship something the player buys back
  // with food rather than earns with the language.
  testWidgets('grading pays XP unscaled by the pet being sick',
      (tester) async {
    final vocab = buildVocab();

    await pumpReview(tester, vocab);
    await tester.tap(find.text('Show answer'));
    await tester.pump();
    await tester.tap(find.text('Again'));
    await tester.pumpAndSettle();

    // Once, for the coins.
    verify(() => mockCharacter.scaleReward(any())).called(1);
    expect(mockUser.addedXp, [3]);
  });

  // Reviewing paid no coins at all before, which put the app's most valuable
  // learning act level with idling. It pays per card now, capped for the day
  // (see `gold.dart`).
  testWidgets('grading pays coins as well as XP', (tester) async {
    final vocab = buildVocab();

    await pumpReview(tester, vocab);
    await tester.tap(find.text('Show answer'));
    await tester.pump();
    await tester.tap(find.text('Again'));
    await tester.pumpAndSettle();

    // The amount is whatever the sickness scaling returned (stubbed to 3
    // here); what this pins is that one review paid once, from the review
    // source, so the day's cap counts it against the right ceiling.
    expect(mockUser.awardedGold.map((a) => a.source),
        equals([GoldSource.review]));
    expect(mockUser.goldFrom(GoldSource.review), greaterThan(0));
  });

  // Grading a card is the event this app most wants to reward, so it counts
  // per card rather than once per session.
  testWidgets('grading tells the pet it was studied with, per card',
      (tester) async {
    final vocab = buildVocab(itemCount: 2);

    await pumpReview(tester, vocab);
    await tester.tap(find.text('Show answer'));
    await tester.pump();
    await tester.tap(find.text('Again'));
    await tester.pumpAndSettle();

    expect(mockCharacter.learningMoments, 1);

    await tester.tap(find.text('Show answer'));
    await tester.pump();
    await tester.tap(find.text('Good'));
    await tester.pumpAndSettle();

    expect(mockCharacter.learningMoments, 2);
  });

  testWidgets('finishing the last card shows the session summary',
      (tester) async {
    final vocab = buildVocab(itemCount: 2);

    await pumpReview(tester, vocab);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Show answer'));
      await tester.pump();
      await tester.tap(find.text('Good'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Review complete!'), findsOneWidget);
    expect(find.text('2 reviewed'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('the session does not reshuffle as items are graded',
      (tester) async {
    // Grading removes an item from the due queue; if the screen read the
    // queue live, the remaining cards would shift under the user.
    final vocab = buildVocab(itemCount: 3);

    await pumpReview(tester, vocab);
    final seen = <String>[];
    for (var i = 0; i < 3; i++) {
      seen.add(
        (tester.widget<Text>(find.textContaining('palabra_')).data)!,
      );
      await tester.tap(find.text('Show answer'));
      await tester.pump();
      await tester.tap(find.text('Good'));
      await tester.pumpAndSettle();
    }

    expect(seen, equals(['palabra_0', 'palabra_1', 'palabra_2']));
  });

  testWidgets('a long backlog is capped to one finishable session',
      (tester) async {
    final vocab = buildVocab(
      itemCount: VocabProvider.maxSessionSize + 5,
    );

    await pumpReview(tester, vocab);

    expect(
      find.text('1 of ${VocabProvider.maxSessionSize}'),
      findsOneWidget,
    );
  });

  testWidgets('a correction asks for the correction, not the meaning',
      (tester) async {
    final vocab = VocabProvider();
    vocab.addFromMistake(
      Mistake(
        id: 'm1',
        original: 'yo tiene',
        correction: 'yo tengo',
        explanation: 'tener is irregular in the first person',
        type: 'grammar',
        timestamp: DateTime.now(),
      ),
      languageCode: 'es',
    );

    await pumpReview(tester, vocab);

    expect(find.text("What's the correction?"), findsOneWidget);
    expect(find.text('yo tiene'), findsOneWidget);
  });

  testWidgets('an item forgotten in review comes back due tomorrow',
      (tester) async {
    final vocab = buildVocab();

    await pumpReview(tester, vocab);
    await tester.tap(find.text('Show answer'));
    await tester.pump();
    await tester.tap(find.text('Again'));
    await tester.pumpAndSettle();

    final item = vocab.items.first;
    expect(item.lapses, equals(1));
    expect(item.repetitions, equals(0));
    expect(item.intervalDays, equals(SrsScheduler.firstIntervalDays));
  });
}
