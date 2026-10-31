import 'dart:io';
import 'dart:math';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/play/play_kit.dart';
import 'package:mojilearner_flutter/constants/boss_trial_words.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/screens/play_catch_screen.dart';
import 'package:mojilearner_flutter/utils/pet_recolor.dart';
import 'package:mojilearner_flutter/utils/play_catch.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// A camera on catch at home: a ball in the air, a header back to its spot,
/// a bonk, and the results. Same idea as
/// `boss_trial_capture_test.dart`.
///
/// Skipped unless told where to write:
///
///     flutter test test/widget/play_catch_capture_test.dart \
///         --dart-define=CAPTURE_DIR=<somewhere>
void main() {
  const dir = String.fromEnvironment('CAPTURE_DIR');

  testWidgets('draw catch at home', (tester) async {
    await tester.runAsync(() async {
      final loader = FontLoader('PressStart2P')
        ..addFont(rootBundle.load('assets/fonts/PressStart2P-Regular.ttf'));
      await loader.load();
      // The room's picture, read once outside the test's fake clock.
      await rootBundle.loadString('assets/svgs/cozy_room.svg');
    });

    final character = MockCharacterProvider();
    final language = MockLanguageProvider();
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
    final stock = bossTrialStockWords(targetCode: 'es', nativeCode: 'en');

    await pumpApp(
      tester,
      PlayCatchScreen(random: Random(3)),
      characterProvider: character,
      languageProvider: language,
      vocabProvider: VocabProvider(),
    );

    Future<void> advance(int ms) async {
      for (var t = 0; t < ms; t += 16) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    Future<void> settleArt() async {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 600)));
      await tester.pump();
    }

    String askedMeaning() {
      final word = tester.widget<PlayBubble>(find.byType(PlayBubble)).word;
      return stock.firstWhere((w) => w.target == word).meaning;
    }

    Future<void> tapMeaning(String meaning) async {
      await tester.tap(find.ancestor(
          of: find.text(meaning), matching: find.byType(PlayTile)));
      await tester.pump();
    }

    Future<void> untilThrown() async {
      while (!tester
          .widgetList<PlayTile>(find.byType(PlayTile))
          .every((t) => t.face == PlayTile.open) ||
          find.byType(PlayTile).evaluate().length != 4) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    // The first ball a third of the way to the pet.
    await untilThrown();
    await advance(2000);
    await settleArt();
    await settleArt();
    await _shoot(tester, '$dir/catch_flying.png');

    // Answered right: the pet on its way up to meet the ball.
    await tapMeaning(askedMeaning());
    await advance(220);
    await _shoot(tester, '$dir/catch_jump.png');

    // The hit itself, hearts coming off it, the pet still in the air.
    await advance(220);
    await _shoot(tester, '$dir/catch_hit.png');

    // The next one answered wrong: bonk, stars, the ball away over its head.
    await untilThrown();
    await advance(1200);
    final right = askedMeaning();
    final wrong = tester
        .widgetList<PlayTile>(find.byType(PlayTile))
        .map((t) => t.label)
        .firstWhere((l) => l != right);
    await tapMeaning(wrong);
    await advance(250 + 300);
    await _shoot(tester, '$dir/catch_bonk.png');

    // The rest caught, then the results.
    for (var i = 2; i < PlayCatchRules.throwsPerGame; i++) {
      await untilThrown();
      await tapMeaning(askedMeaning());
    }
    await advance(2000);
    await _shoot(tester, '$dir/catch_results.png');

    await tester.pumpWidget(const SizedBox());
  }, skip: dir.isEmpty);
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
