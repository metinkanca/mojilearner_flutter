import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/play/play_kit.dart';
import 'package:mojilearner_flutter/components/play/toy_chest_art.dart';
import 'package:mojilearner_flutter/constants/boss_trial_words.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/screens/play_catch_screen.dart';
import 'package:mojilearner_flutter/utils/boss_trial.dart';
import 'package:mojilearner_flutter/utils/pet_recolor.dart';
import 'package:mojilearner_flutter/utils/play_catch.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCharacterProvider character;
  late MockLanguageProvider language;
  final stock = bossTrialStockWords(targetCode: 'es', nativeCode: 'en');

  setUp(() {
    character = MockCharacterProvider();
    language = MockLanguageProvider();
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
        )).thenAnswer((i) => PlayCatchRules.happiness(
          caught: i.namedArguments[#right] as int,
          throws: i.namedArguments[#rounds] as int,
        ));
    when(() => language.targetLanguage)
        .thenReturn(const Language(code: 'es', name: 'Spanish'));
    when(() => language.nativeLanguage)
        .thenReturn(const Language(code: 'en', name: 'English'));
  });

  Future<void> pumpGame(WidgetTester tester) => pumpApp(
        tester,
        PlayCatchScreen(random: Random(7)),
        characterProvider: character,
        languageProvider: language,
        vocabProvider: VocabProvider(),
      );

  /// Time a frame at a time: the game clock caps a frame at 50ms.
  Future<void> advance(WidgetTester tester, int ms) async {
    for (var t = 0; t < ms; t += 50) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  List<PlayTile> blocks(WidgetTester tester) =>
      tester.widgetList<PlayTile>(find.byType(PlayTile)).toList();

  PlayTile block(WidgetTester tester, String meaning) =>
      blocks(tester).firstWhere((b) => b.label == meaning);

  /// Pumps until a ball is in the air: four answers up, none answered yet.
  Future<void> untilThrown(WidgetTester tester) async {
    for (var i = 0; i < 300; i++) {
      final up = blocks(tester);
      if (up.length == BossTrialRules.wordsPerWave &&
          up.every((b) => b.face == PlayTile.open)) {
        return;
      }
      await tester.pump(const Duration(milliseconds: 50));
    }
    fail('no ball was thrown');
  }

  /// The word the pet is calling for, read off its bubble.
  TrialWord asked(WidgetTester tester) {
    final word = tester.widget<PlayBubble>(find.byType(PlayBubble)).word;
    return stock.firstWhere((w) => w.target == word);
  }

  Future<void> tapBlock(WidgetTester tester, String meaning) async {
    await tester.tap(find.ancestor(
      of: find.text(meaning),
      matching: find.byType(PlayTile),
    ));
    await tester.pump();
  }

  /// Answers the throw in the air wrongly, and returns the block picked.
  Future<String> tapWrong(WidgetTester tester) async {
    await untilThrown(tester);
    final right = asked(tester).meaning;
    final wrong = blocks(tester).map((b) => b.label).firstWhere((l) => l != right);
    await tapBlock(tester, wrong);
    return wrong;
  }

  Future<void> untilResults(WidgetTester tester, String score) async {
    for (var i = 0; i < 600 && find.text(score).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Rect ball(WidgetTester tester) => tester.getRect(find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          w.painter is PixelPatternPainter &&
          (w.painter! as PixelPatternPainter).rows == toyCatchArtRows));

  testWidgets('catching every throw finishes a clean game', (tester) async {
    await pumpGame(tester);

    for (var i = 0; i < PlayCatchRules.throwsPerGame; i++) {
      await untilThrown(tester);
      await tapBlock(tester, asked(tester).meaning);
    }
    await untilResults(tester, '10/10');

    expect(find.text('10/10'), findsOneWidget);
    expect(find.text('+${10 + PlayCatchRules.cleanGameBonus}'), findsOneWidget);
    verify(() => character.rewardPlay(right: 10, rounds: 10)).called(1);
    expect(character.learningMoments, 1);
  });

  testWidgets('a caught ball goes back to its spot', (tester) async {
    await pumpGame(tester);
    await untilThrown(tester);
    final spot = ball(tester).center;

    await tapBlock(tester, asked(tester).meaning);
    // The rest of the flight, the header, the flight back and the landing.
    await advance(tester, 1400);

    expect(ball(tester).center.dx, closeTo(spot.dx, 1));
    expect(ball(tester).center.dy, closeTo(spot.dy, 1));
  });

  testWidgets('a wrong answer bonks the pet, and the ball bounces away',
      (tester) async {
    await pumpGame(tester);
    await untilThrown(tester);
    final word = asked(tester);
    final spot = ball(tester).center;

    final wrong = await tapWrong(tester);
    await tester.pump(const Duration(milliseconds: 50));

    // The right block lit, the wrong pick marked apart from it.
    final right = block(tester, word.meaning).face;
    expect(right, isNot(PlayTile.open));
    expect(block(tester, wrong).face, isNot(right));

    // Into the pet, then up and back over it: left of where it was thrown
    // from, not on its way home.
    await advance(tester, 600);
    expect(ball(tester).center.dx, lessThan(spot.dx / 2));

    for (var i = 1; i < PlayCatchRules.throwsPerGame; i++) {
      await tapWrong(tester);
    }
    await untilResults(tester, '0/10');

    expect(find.text('= ${word.meaning}'), findsOneWidget);
    verify(() => character.rewardPlay(right: 0, rounds: 10)).called(1);
    expect(character.learningMoments, 0);
  });

  testWidgets('a ball left unanswered bonks the pet too', (tester) async {
    await pumpGame(tester);
    await untilThrown(tester);
    final word = asked(tester);

    // Past the longest flight, without touching anything.
    await advance(tester, PlayCatchRules.readTimeStart.inMilliseconds + 300);

    // The right block lit; nothing marked as a wrong pick.
    final faces = blocks(tester).map((b) => b.face).toList();
    final right = block(tester, word.meaning).face;
    expect(right, isNot(PlayTile.open));
    expect(faces.where((f) => f == right), hasLength(1));
    expect(faces.toSet(), hasLength(2));

    for (var i = 1; i < PlayCatchRules.throwsPerGame; i++) {
      await tapWrong(tester);
    }
    await untilResults(tester, '0/10');
    expect(find.text('= ${word.meaning}'), findsOneWidget);
  });

  testWidgets('play again starts a fresh game', (tester) async {
    await pumpGame(tester);
    for (var i = 0; i < PlayCatchRules.throwsPerGame; i++) {
      await tapWrong(tester);
    }
    await untilResults(tester, '0/10');

    await tester.tap(find.bySemanticsLabel('Play again'));
    await tester.pump();

    expect(find.text('0/10'), findsNothing);
    await untilThrown(tester);
  });
}
