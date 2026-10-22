import 'dart:io';
import 'dart:math';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/boss_trial/angler_pieces.dart';
import 'package:mojilearner_flutter/components/boss_trial/arena_pieces.dart';
import 'package:mojilearner_flutter/components/play/play_props.dart';
import 'package:mojilearner_flutter/components/play/toy_chest.dart';
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

/// A camera on the toy chest and its games, the way
/// `play_catch_capture_test.dart` is on Catch: each game mid-round, at the
/// moment it reacts, and finished, on a tall phone and an iPhone SE.
///
/// Skipped unless told where to write:
///
///     flutter test test/widget/toy_chest_capture_test.dart \
///         --dart-define=CAPTURE_DIR=<somewhere>
void main() {
  const dir = String.fromEnvironment('CAPTURE_DIR');
  final stock = bossTrialStockWords(targetCode: 'es', nativeCode: 'en');
  final sentences =
      bossTrialStockSentences(targetCode: 'es', nativeCode: 'en');

  late MockCharacterProvider character;
  late MockLanguageProvider language;
  late MockSettingsProvider settings;

  setUp(() {
    character = MockCharacterProvider();
    language = MockLanguageProvider();
    settings = MockSettingsProvider();
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
    when(() => settings.usePixelFont).thenReturn(true);
  });

  Future<void> loadFont(WidgetTester tester) => tester.runAsync(() async {
        final loader = FontLoader('PressStart2P')
          ..addFont(rootBundle.load('assets/fonts/PressStart2P-Regular.ttf'));
        await loader.load();
      });

  Future<void> advance(WidgetTester tester, int ms) async {
    for (var t = 0; t < ms; t += 16) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  Future<void> settleArt(WidgetTester tester) async {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
  }

  Future<void> until(WidgetTester tester, bool Function() done,
      {int maxMs = 8000}) async {
    for (var t = 0; t < maxMs && !done(); t += 16) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  String? bubbleWord(WidgetTester tester) {
    final found = find.byType(ShoutBubble);
    if (found.evaluate().isEmpty) return null;
    return tester.widget<ShoutBubble>(found.first).word;
  }

  const sizes = {'tall': kHandsetSurface, 'se': Size(375, 667)};

  for (final MapEntry(key: size, value: surface) in sizes.entries) {
    testWidgets('draw the toy chest ($size)', (tester) async {
      await loadFont(tester);
      await pumpApp(
        tester,
        Scaffold(
          backgroundColor: const Color(0xFF6ABE30),
          body: Stack(
            children: [
              Positioned(
                left: 40,
                top: 40,
                child: ToyChest(semanticLabel: 'Toy chest', onTap: () {}, size: 84),
              ),
              Positioned(
                left: 200,
                top: 60,
                child: ToyChest(semanticLabel: 'Toy chest', onTap: () {}, size: 42),
              ),
              const Positioned.fill(top: 160, child: ToyChestPicker()),
            ],
          ),
        ),
        settingsProvider: settings,
        surfaceSize: surface,
      );
      await tester.pump();
      await _shoot(tester, '$dir/chest_$size.png');
      await tester.pumpWidget(const SizedBox());
    }, skip: dir.isEmpty);

    testWidgets('draw bubble bath ($size)', (tester) async {
      await loadFont(tester);
      await pumpApp(
        tester,
        BubbleBathScreen(random: Random(4)),
        characterProvider: character,
        languageProvider: language,
        vocabProvider: VocabProvider(),
        surfaceSize: surface,
      );

      List<String> letters() {
        final meaning = bubbleWord(tester)!;
        final word = stock.firstWhere((w) => w.meaning == meaning);
        return word.target.split('');
      }

      Future<void> tapLetter(String letter) async {
        final bubble = tester
            .widgetList<LetterBubble>(find.byType(LetterBubble))
            .firstWhere((b) => b.label == letter);
        bubble.onTapDown!();
        await tester.pump();
      }

      await until(tester, () => find.byType(LetterBubble).evaluate().isNotEmpty);
      await advance(tester, 1500);
      final first = letters();
      await tapLetter(first[0]);
      await tapLetter(first[1]);
      await advance(tester, 300);
      await settleArt(tester);
      await _shoot(tester, '$dir/bath_spelling_$size.png');

      for (final l in first.skip(2)) {
        await tapLetter(l);
      }
      await advance(tester, 200);
      await _shoot(tester, '$dir/bath_spelled_$size.png');

      // The next one left to drain.
      await until(tester, () => find.byType(LetterBubble).evaluate().isNotEmpty);
      await advance(tester, 6000);
      await _shoot(tester, '$dir/bath_draining_$size.png');
      await until(tester, () => find.byType(LetterBubble).evaluate().isEmpty,
          maxMs: 12000);
      await advance(tester, 300);
      await _shoot(tester, '$dir/bath_drained_$size.png');

      for (var i = 2; i < BubbleBathRules.wordsPerGame; i++) {
        await until(
            tester, () => find.byType(LetterBubble).evaluate().isNotEmpty,
            maxMs: 12000);
        for (final l in letters()) {
          await tapLetter(l);
        }
      }
      await advance(tester, 2500);
      await _shoot(tester, '$dir/bath_results_$size.png');
      await tester.pumpWidget(const SizedBox());
    }, skip: dir.isEmpty);

    testWidgets('draw pounce ($size)', (tester) async {
      await loadFont(tester);
      await pumpApp(
        tester,
        PounceScreen(random: Random(5)),
        characterProvider: character,
        languageProvider: language,
        vocabProvider: VocabProvider(),
        surfaceSize: surface,
      );

      String target() {
        final meaning = bubbleWord(tester)!;
        return stock.firstWhere((w) => w.meaning == meaning).target;
      }

      Iterable<MoleSign> upMoles() => tester
          .widgetList<MoleSign>(find.byType(MoleSign))
          .where((m) => m.onTapDown != null);

      await until(tester, () => upMoles().length >= 2);
      await advance(tester, 200);
      await settleArt(tester);
      await _shoot(tester, '$dir/pounce_moles_$size.png');

      // A wrong one first, then the right one.
      final wrong = upMoles().firstWhere((m) => m.label != target(),
          orElse: () => upMoles().first);
      wrong.onTapDown!();
      await tester.pump();
      await advance(tester, 120);
      await _shoot(tester, '$dir/pounce_wrong_$size.png');
      await until(tester, () => upMoles().any((m) => m.label == target()));
      upMoles().firstWhere((m) => m.label == target()).onTapDown!();
      await tester.pump();
      await advance(tester, 330);
      await _shoot(tester, '$dir/pounce_landed_$size.png');

      // The next wave let go by: the right one comes up lit.
      await until(tester, () => upMoles().isNotEmpty, maxMs: 4000);
      await until(
          tester,
          () => tester
              .widgetList<MoleSign>(find.byType(MoleSign))
              .any((m) => m.state == PropState.right),
          maxMs: 15000);
      await advance(tester, 300);
      await _shoot(tester, '$dir/pounce_reveal_$size.png');

      for (var i = 2; i < PounceRules.wavesPerGame; i++) {
        await until(tester,
            () => upMoles().any((m) => m.label == target()), maxMs: 15000);
        upMoles().firstWhere((m) => m.label == target()).onTapDown!();
        await tester.pump();
        await advance(tester, 100);
      }
      await advance(tester, 2500);
      await _shoot(tester, '$dir/pounce_results_$size.png');
      await tester.pumpWidget(const SizedBox());
    }, skip: dir.isEmpty);

    testWidgets('draw pond hop ($size)', (tester) async {
      await loadFont(tester);
      await pumpApp(
        tester,
        PondHopScreen(random: Random(6)),
        characterProvider: character,
        languageProvider: language,
        vocabProvider: VocabProvider(),
        surfaceSize: surface,
      );

      Iterable<LilyPad> openPads() => tester
          .widgetList<LilyPad>(find.byType(LilyPad))
          .where((p) => p.onTapDown != null);

      String meaning() {
        final word = bubbleWord(tester)!;
        return stock.firstWhere((w) => w.target == word).meaning;
      }

      await until(tester, () => openPads().isNotEmpty);
      await advance(tester, 2400);
      await settleArt(tester);
      await _shoot(tester, '$dir/pond_tide_$size.png');

      openPads().firstWhere((p) => p.label == meaning()).onTapDown!();
      await tester.pump();
      await advance(tester, 160);
      await _shoot(tester, '$dir/pond_hop_$size.png');
      await until(tester, () => openPads().isNotEmpty);
      await advance(tester, 3600);
      await _shoot(tester, '$dir/pond_sinking_$size.png');

      openPads().firstWhere((p) => p.label != meaning()).onTapDown!();
      await tester.pump();
      await advance(tester, 520);
      await _shoot(tester, '$dir/pond_splash_$size.png');

      for (var i = 0; i < 2; i++) {
        await until(tester, () => openPads().isNotEmpty, maxMs: 4000);
        openPads().firstWhere((p) => p.label == meaning()).onTapDown!();
        await tester.pump();
      }
      await advance(tester, 500);
      await _shoot(tester, '$dir/pond_crossed_$size.png');

      for (var i = 0; i < PondHopRules.rowsPerPond; i++) {
        await until(tester, () => openPads().isNotEmpty, maxMs: 6000);
        openPads().firstWhere((p) => p.label == meaning()).onTapDown!();
        await tester.pump();
      }
      await advance(tester, 2500);
      await _shoot(tester, '$dir/pond_results_$size.png');
      await tester.pumpWidget(const SizedBox());
    }, skip: dir.isEmpty);

    testWidgets('draw fetch the words ($size)', (tester) async {
      await loadFont(tester);
      await pumpApp(
        tester,
        FetchWordsScreen(random: Random(7)),
        characterProvider: character,
        languageProvider: language,
        vocabProvider: VocabProvider(),
        surfaceSize: surface,
      );

      List<String> tokens() {
        final meaning = bubbleWord(tester)!;
        return sentences.firstWhere((s) => s.meaning == meaning).tokens;
      }

      Future<void> tapStick(String word) async {
        final finder = find.byWidgetPredicate(
            (w) => w is WordStick && w.label == word && !w.used && w.onTapDown != null);
        await tester.tap(finder.first);
        await tester.pump();
      }

      await until(tester, () => find.byType(WordStick).evaluate().isNotEmpty);
      await advance(tester, 1500);
      await settleArt(tester);
      await _shoot(tester, '$dir/fetch_sticks_$size.png');

      final first = tokens();
      await tapStick(first[0]);
      await advance(tester, 140);
      await _shoot(tester, '$dir/fetch_toss_$size.png');
      for (final word in first.skip(1)) {
        await tapStick(word);
        await advance(tester, 60);
      }
      await advance(tester, 400);
      await _shoot(tester, '$dir/fetch_built_$size.png');

      // The next one left to run out.
      await until(tester,
          () => find.byWidgetPredicate((w) => w is WordStick && w.onTapDown != null)
              .evaluate()
              .isNotEmpty,
          maxMs: 4000);
      await advance(tester, 7000);
      await _shoot(tester, '$dir/fetch_waiting_$size.png');
      await until(tester,
          () => find.byWidgetPredicate((w) => w is WordStick && w.onTapDown != null)
              .evaluate()
              .isEmpty,
          maxMs: 10000);
      await advance(tester, 300);
      await _shoot(tester, '$dir/fetch_too_slow_$size.png');

      for (var i = 2; i < FetchRules.sentencesPerGame; i++) {
        await until(tester,
            () => find.byWidgetPredicate((w) => w is WordStick && w.onTapDown != null)
                .evaluate()
                .isNotEmpty,
            maxMs: 15000);
        for (final word in tokens()) {
          await tapStick(word);
        }
      }
      await advance(tester, 2500);
      await _shoot(tester, '$dir/fetch_results_$size.png');
      await tester.pumpWidget(const SizedBox());
    }, skip: dir.isEmpty);
  }
}

Future<void> _shoot(WidgetTester tester, String path) async {
  await tester.runAsync(() async {
    final repaint =
        _firstBoundary(tester.binding.rootElement!.findRenderObject()!)!;
    final image = await repaint.toImage(pixelRatio: 2);
    final png = await image.toByteData(format: ImageByteFormat.png);
    File(path).writeAsBytesSync(png!.buffer.asUint8List());
  });
}

RenderRepaintBoundary? _firstBoundary(RenderObject node) {
  if (node is RenderRepaintBoundary) return node;
  RenderRepaintBoundary? found;
  node.visitChildren((child) {
    found ??= _firstBoundary(child);
  });
  return found;
}
