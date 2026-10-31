import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/boss_trial/arena_pieces.dart';
import 'package:mojilearner_flutter/components/play/play_kit.dart';
import 'package:mojilearner_flutter/components/play/play_props.dart';
import 'package:mojilearner_flutter/constants/boss_trial_sentences.dart';
import 'package:mojilearner_flutter/constants/boss_trial_words.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/screens/play/bubble_bath_screen.dart';
import 'package:mojilearner_flutter/screens/play/fetch_words_screen.dart';
import 'package:mojilearner_flutter/screens/play/pond_hop_screen.dart';
import 'package:mojilearner_flutter/screens/play/pounce_screen.dart';
import 'package:mojilearner_flutter/utils/pet_recolor.dart';
import 'package:mojilearner_flutter/utils/play_games.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// The four toy chest games after Catch, each played through: a clean game
/// pays in full, a round let go is listed to practise, and nothing is lost.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final stock = bossTrialStockWords(targetCode: 'es', nativeCode: 'en');
  final sentences =
      bossTrialStockSentences(targetCode: 'es', nativeCode: 'en');

  late MockCharacterProvider character;
  late MockLanguageProvider language;
  late MockUserProvider user;

  setUp(() {
    character = MockCharacterProvider();
    language = MockLanguageProvider();
    user = MockUserProvider();
    when(() => character.currentCharacterType).thenReturn('cat');
    when(() => character.currentCharacterAsset)
        .thenReturn('assets/svgs/cat.svg');
    when(() => character.colorSpecFor(any())).thenReturn(const PetColorSpec(
      bodyColor: '#959379',
      eyeMode: EyeMode.solid,
      eyeColor1: '#F4C430',
      eyeColor2: '#5AA0E0',
    ));
    when(() => character.equippedAccessoriesFor(any())).thenReturn(const []);
    when(() => character.rewardPlay(
          right: any(named: 'right'),
          rounds: any(named: 'rounds'),
        )).thenAnswer((i) => PlayRewards.happiness(
          right: i.namedArguments[#right] as int,
          rounds: i.namedArguments[#rounds] as int,
        ));
    when(() => language.targetLanguage)
        .thenReturn(const Language(code: 'es', name: 'Spanish'));
    when(() => language.nativeLanguage)
        .thenReturn(const Language(code: 'en', name: 'English'));
  });

  Future<void> pumpGame(WidgetTester tester, Widget game) => pumpApp(
        tester,
        game,
        characterProvider: character,
        languageProvider: language,
        userProvider: user,
        vocabProvider: VocabProvider(),
      );

  /// Frame by frame: the game clock caps a frame at 50ms.
  Future<void> until(WidgetTester tester, bool Function() done,
      {int maxMs = 15000}) async {
    for (var t = 0; t < maxMs && !done(); t += 16) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(done(), isTrue, reason: 'waited ${maxMs}ms');
  }

  Future<void> advance(WidgetTester tester, int ms) async {
    for (var t = 0; t < ms; t += 16) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  /// The word the pet is calling for: Bubble Bath's bubble is the house one,
  /// the others still draw the boss trials'.
  String asked(WidgetTester tester) {
    final house = find.byType(PlayBubble);
    return house.evaluate().isNotEmpty
        ? tester.widget<PlayBubble>(house).word
        : tester.widget<ShoutBubble>(find.byType(ShoutBubble)).word;
  }

  void expectPaidInFull(WidgetTester tester, int rounds) {
    expect(find.text('$rounds/$rounds'), findsOneWidget);
    verify(() => character.rewardPlay(right: rounds, rounds: rounds))
        .called(1);
    expect(user.addedXp, [PlayRewards.fullGameXp]);
    expect(character.learningMoments, 1);
  }

  // ---------------------------------------------------------- Bubble Bath --

  group('bubble bath', () {
    bool spelling() => find.byType(PlayLetterBubble).evaluate().isNotEmpty;

    Future<void> spell(WidgetTester tester) async {
      await until(tester, spelling);
      final word = stock.firstWhere((w) => w.meaning == asked(tester));
      for (final letter in word.target.split('')) {
        tester
            .widgetList<PlayLetterBubble>(find.byType(PlayLetterBubble))
            .firstWhere((b) => b.label == letter)
            .onTapDown!();
        await tester.pump();
      }
    }

    testWidgets('spelling every word is a clean game', (tester) async {
      await pumpGame(tester, BubbleBathScreen(random: Random(1)));

      for (var i = 0; i < BubbleBathRules.wordsPerGame; i++) {
        await spell(tester);
      }
      await advance(tester, 2000);

      expectPaidInFull(tester, BubbleBathRules.wordsPerGame);
    });

    testWidgets('a wrong letter spoils the word, which is still spelled',
        (tester) async {
      await pumpGame(tester, BubbleBathScreen(random: Random(2)));
      await until(tester, spelling);
      final word = stock.firstWhere((w) => w.meaning == asked(tester));
      final stray = tester
          .widgetList<PlayLetterBubble>(find.byType(PlayLetterBubble))
          .firstWhere((b) => !word.target.contains(b.label));
      stray.onTapDown!();
      await tester.pump();
      for (final letter in word.target.split('')) {
        tester
            .widgetList<PlayLetterBubble>(find.byType(PlayLetterBubble))
            .firstWhere((b) => b.label == letter)
            .onTapDown!();
        await tester.pump();
      }
      for (var i = 1; i < BubbleBathRules.wordsPerGame; i++) {
        await spell(tester);
      }
      await advance(tester, 2000);

      expect(find.text('5/6'), findsOneWidget);
      expect(find.text('= ${word.meaning}'), findsOneWidget);
    });

    testWidgets('a word left to drain is shown, and the game goes on',
        (tester) async {
      await pumpGame(tester, BubbleBathScreen(random: Random(3)));
      await until(tester, spelling);
      final word = stock.firstWhere((w) => w.meaning == asked(tester));

      // Drained: the bubbles burst, and the tub fills for the next word.
      await until(tester, () => !spelling(), maxMs: 20000);
      await until(tester, spelling);
      for (var i = 1; i < BubbleBathRules.wordsPerGame; i++) {
        await spell(tester);
      }
      await advance(tester, 2000);

      expect(find.text('5/6'), findsOneWidget);
      expect(find.text(word.target), findsOneWidget);
      verify(() => character.rewardPlay(right: 5, rounds: 6)).called(1);
    });
  });

  // --------------------------------------------------------------- Pounce --

  group('pounce', () {
    Iterable<MoleSign> upMoles(WidgetTester tester) => tester
        .widgetList<MoleSign>(find.byType(MoleSign))
        .where((m) => m.onTapDown != null);

    String target(WidgetTester tester) =>
        stock.firstWhere((w) => w.meaning == asked(tester)).target;

    Future<void> pounce(WidgetTester tester) async {
      await until(tester, () =>
          find.byType(PlayBubble).evaluate().isNotEmpty &&
          upMoles(tester).any((m) => m.label == target(tester)));
      upMoles(tester).firstWhere((m) => m.label == target(tester)).onTapDown!();
      await tester.pump();
      // Out of the wave before looking for the next.
      await advance(tester, 1200);
    }

    testWidgets('pouncing on every right mole is a clean game',
        (tester) async {
      await pumpGame(tester, PounceScreen(random: Random(1)));

      for (var i = 0; i < PounceRules.wavesPerGame; i++) {
        await pounce(tester);
      }
      await advance(tester, 1500);

      expectPaidInFull(tester, PounceRules.wavesPerGame);
    });

    testWidgets('a wave let go by is lost, and listed', (tester) async {
      await pumpGame(tester, PounceScreen(random: Random(2)));
      await until(tester, () => upMoles(tester).isNotEmpty);
      final word = stock.firstWhere((w) => w.meaning == asked(tester));

      // Every mole goes by, then the right one comes up lit.
      await until(
          tester,
          () => tester
              .widgetList<MoleSign>(find.byType(MoleSign))
              .any((m) => m.state == PropState.right && m.label == word.target));
      await advance(tester, 1500);
      for (var i = 1; i < PounceRules.wavesPerGame; i++) {
        await pounce(tester);
      }
      await advance(tester, 1500);

      expect(find.text('7/8'), findsOneWidget);
      expect(find.text(word.target), findsOneWidget);
    });
  });

  // ------------------------------------------------------------- Pond Hop --

  group('pond hop', () {
    Iterable<LilyPad> openPads(WidgetTester tester) => tester
        .widgetList<LilyPad>(find.byType(LilyPad))
        .where((p) => p.onTapDown != null);

    String meaning(WidgetTester tester) =>
        stock.firstWhere((w) => w.target == asked(tester)).meaning;

    Future<void> hop(WidgetTester tester, {bool right = true}) async {
      await until(tester, () => openPads(tester).isNotEmpty);
      final m = meaning(tester);
      openPads(tester)
          .firstWhere((p) => right ? p.label == m : p.label != m)
          .onTapDown!();
      await tester.pump();
      // Landed, or dunked and shown across.
      await until(tester, () => openPads(tester).isEmpty);
    }

    testWidgets('two ponds crossed on the right pads is a clean game',
        (tester) async {
      await pumpGame(tester, PondHopScreen(random: Random(1)));

      for (var i = 0; i < PondHopRules.rowsPerGame; i++) {
        await hop(tester);
      }
      await advance(tester, 2500);

      expectPaidInFull(tester, PondHopRules.rowsPerGame);
    });

    testWidgets('a wrong pad dunks the pet but it still gets across',
        (tester) async {
      await pumpGame(tester, PondHopScreen(random: Random(2)));
      await until(tester, () => openPads(tester).isNotEmpty);
      final word = stock.firstWhere((w) => w.target == asked(tester));

      await hop(tester, right: false);
      for (var i = 1; i < PondHopRules.rowsPerGame; i++) {
        await hop(tester);
      }
      await advance(tester, 2500);

      expect(find.text('7/8'), findsOneWidget);
      expect(find.text('= ${word.meaning}'), findsOneWidget);
    });
  });

  // ------------------------------------------------------ Fetch the Words --

  group('fetch the words', () {
    bool fetching() => find
        .byWidgetPredicate((w) => w is WordStick && w.onTapDown != null)
        .evaluate()
        .isNotEmpty;

    Future<void> fetch(WidgetTester tester) async {
      await until(tester, fetching);
      final sentence =
          sentences.firstWhere((s) => s.meaning == asked(tester));
      for (final word in sentence.tokens) {
        await tester.tap(find
            .byWidgetPredicate((w) =>
                w is WordStick &&
                w.label == word &&
                !w.used &&
                w.onTapDown != null)
            .first);
        await tester.pump();
      }
      await until(tester, () => !fetching());
    }

    testWidgets('building every sentence is a clean game', (tester) async {
      await pumpGame(tester, FetchWordsScreen(random: Random(1)));

      for (var i = 0; i < FetchRules.sentencesPerGame; i++) {
        await fetch(tester);
      }
      await advance(tester, 2000);

      expectPaidInFull(tester, FetchRules.sentencesPerGame);
    });

    testWidgets('no sentence comes up twice in a game', (tester) async {
      await pumpGame(tester, FetchWordsScreen(random: Random(4)));

      final seen = <String>{};
      for (var i = 0; i < FetchRules.sentencesPerGame; i++) {
        await until(tester, fetching);
        expect(seen.add(asked(tester)), isTrue);
        await fetch(tester);
      }
    });

    testWidgets('running out of patience shows the sentence',
        (tester) async {
      await pumpGame(tester, FetchWordsScreen(random: Random(2)));
      await until(tester, fetching);
      final sentence =
          sentences.firstWhere((s) => s.meaning == asked(tester));

      await until(tester, () => !fetching(), maxMs: 20000);
      for (var i = 1; i < FetchRules.sentencesPerGame; i++) {
        await fetch(tester);
      }
      await advance(tester, 2000);

      expect(find.text('4/5'), findsOneWidget);
      expect(find.text(sentence.target), findsOneWidget);
    });

    testWidgets('play again starts a fresh game', (tester) async {
      await pumpGame(tester, FetchWordsScreen(random: Random(3)));
      for (var i = 0; i < FetchRules.sentencesPerGame; i++) {
        await fetch(tester);
      }
      await advance(tester, 2000);
      expect(find.text('5/5'), findsOneWidget);

      await tester.tap(find.byWidgetPredicate(
          (w) => w is PlaySquareButton && w.icon == PlayIcon.play));
      await tester.pump();

      expect(find.text('5/5'), findsNothing);
      await until(tester, fetching);
    });
  });
}
