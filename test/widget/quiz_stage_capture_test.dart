import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/quiz_stage.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';
import '../helpers/test_fixtures.dart';

/// A camera on the quiz classroom, for judging the layout by eye on a few
/// phone sizes, before and after an answer. Same idea as
/// `scenario_city_capture_test.dart`.
///
/// Skipped unless told where to write:
///
///     flutter test test/widget/quiz_stage_capture_test.dart \
///         --dart-define=CAPTURE_DIR=<somewhere>
void main() {
  const dir = String.fromEnvironment('CAPTURE_DIR');

  testWidgets('draw the quiz classroom', (tester) async {
    await tester.runAsync(() async {
      final loader = FontLoader('PressStart2P')
        ..addFont(rootBundle.load('assets/fonts/PressStart2P-Regular.ttf'));
      await loader.load();
    });

    final character = MockCharacterProvider();
    final settings = MockSettingsProvider();
    when(() => settings.usePixelFont).thenReturn(true);
    when(() => character.currentCharacterType).thenReturn('cat');
    when(() => character.currentCharacterAsset)
        .thenReturn('assets/svgs/cat.svg');
    when(() => character.customization)
        .thenReturn(TestFixtures.buildCustomization());
    when(() => character.isSleeping).thenReturn(false);

    // Phones, with the insets a real one would hand the safe area.
    const phones = {
      'iphone_390x844': (Size(390, 844), EdgeInsets.fromLTRB(0, 47, 0, 34)),
      'reno2z_360x780': (Size(360, 780), EdgeInsets.fromLTRB(0, 28, 0, 16)),
      'small_320x568': (Size(320, 568), EdgeInsets.fromLTRB(0, 20, 0, 0)),
      'tall_430x932': (Size(430, 932), EdgeInsets.fromLTRB(0, 59, 0, 34)),
      // Long and narrow: the most spare height a phone gives the board.
      'long_360x900': (Size(360, 900), EdgeInsets.fromLTRB(0, 28, 0, 16)),
    };

    for (final MapEntry(key: name, value: (size, insets)) in phones.entries) {
      for (final answered in [false, true]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpApp(
          tester,
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(padding: insets),
              child: RepaintBoundary(
                child: QuizStage(
                  header: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                          width: 130, height: 48, color: Colors.white),
                      Container(width: 48, height: 48, color: Colors.white),
                    ],
                  ),
                  badgeLabel: 'QUESTION 2/5',
                  prompt: 'Which word means \'Cat\'?',
                  topic: 'Animals',
                  options: const ['Perro', 'Gato', 'Pájaro', 'Conejo'],
                  stateOf: (option) => !answered
                      ? QuizOptionState.idle
                      : option == 'Gato'
                          ? QuizOptionState.correct
                          : option == 'Perro'
                              ? QuizOptionState.wrong
                              : QuizOptionState.idle,
                  onAnswer: answered ? null : (_) {},
                  bubbleText: answered
                      ? 'Gato means Cat. Perro is Dog, Pájaro is Bird, and '
                          'Conejo is Rabbit, so only one of these purrs.'
                      : 'You got this!',
                  heartBurstId: answered ? 1 : 0,
                  continueLabel: 'CONTINUE',
                  onContinue: answered ? () {} : null,
                ),
              ),
            ),
          ),
          characterProvider: character,
          settingsProvider: settings,
          surfaceSize: size,
        );
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 50));
          // SVG layers decode off the fake clock.
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 150)));
        }
        await tester.pump();
        await _shoot(tester, '$dir/quiz_${name}_${answered ? 'answered' : 'asking'}.png');
      }
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  }, skip: dir.isEmpty);
}

Future<void> _shoot(WidgetTester tester, String path) async {
  await tester.runAsync(() async {
    final repaint =
        _firstBoundary(tester.binding.rootElement!.findRenderObject()!)!;
    final image = await repaint.toImage(pixelRatio: 1);
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
