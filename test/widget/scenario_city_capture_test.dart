import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/scenario_city.dart';
import 'package:mojilearner_flutter/components/scenario_stage.dart';
import 'package:mojilearner_flutter/constants/scenarios.dart';
import 'package:mojilearner_flutter/constants/shop.dart';
import 'package:mojilearner_flutter/providers/scenario_provider.dart';
import 'package:mojilearner_flutter/screens/scenarios_screen.dart';
import 'package:mojilearner_flutter/utils/pet_recolor.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// A camera on the scenario town and the scene above a scenario chat, for
/// judging the layout by eye and lining the lots and doors up with the art
/// (`art_src/gen_city.py` prints the numbers). Same idea as
/// `boss_trial_capture_test.dart`.
///
/// Skipped unless told where to write:
///
///     flutter test test/widget/scenario_city_capture_test.dart \
///         --dart-define=CAPTURE_DIR=<somewhere>
void main() {
  const dir = String.fromEnvironment('CAPTURE_DIR');

  testWidgets('draw the scenario town', (tester) async {
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
    when(() => character.colorSpecFor(any())).thenReturn(const PetColorSpec(
      bodyColor: '#959379',
      eyeMode: EyeMode.solid,
      eyeColor1: '#F4C430',
      eyeColor2: '#5AA0E0',
    ));
    when(() => character.equippedAccessoriesFor(any())).thenReturn(const []);

    final progress = ScenarioProvider()
      ..completeRun(ScenarioCatalog.byId('doctor')!)
      ..markObjectives(ScenarioCatalog.byId('shopping')!, ['find']);

    Future<void> settle(int ms) async {
      for (var t = 0; t < ms; t += 50) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      // SVG layers decode off the fake clock.
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump();
    }

    await pumpApp(
      tester,
      const ScenariosScreen(),
      characterProvider: character,
      settingsProvider: settings,
      scenarioProvider: progress,
    );
    await settle(300);
    await _shoot(tester, '$dir/city_open.png');

    // By widget, not by sign text: a building with art has no text on it.
    await tester.tap(find.byWidgetPredicate(
        (w) => w is CityBuilding && w.scenario?.id == 'shopping'));
    await tester.pump();
    await settle(400);
    await _shoot(tester, '$dir/city_walking.png');

    await settle(4000);
    await _shoot(tester, '$dir/city_arrived.png');

    // The scene above the chat: thinking, then the keyboard-up strip.
    Widget stage({
      required bool thinking,
      bool compact = false,
      String scenario = 'coffee',
      ShopItem? offer,
      ShopItem? lastBought,
      int bought = 0,
    }) =>
        Column(
          children: [
            ScenarioStage(
              scenario: ScenarioCatalog.byId(scenario)!,
              learnerTurns: 1,
              hostTurns: 1,
              hostThinking: thinking,
              compact: compact,
              offer: offer,
              canAffordOffer: true,
              lastBought: lastBought,
              servicesBought: bought,
            ),
            const Spacer(),
          ],
        );

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpApp(tester, stage(thinking: true),
        characterProvider: character, settingsProvider: settings);
    await settle(700);
    await _shoot(tester, '$dir/stage_thinking.png');

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpApp(tester, stage(thinking: true, compact: true),
        characterProvider: character, settingsProvider: settings);
    await settle(700);
    await _shoot(tester, '$dir/stage_compact.png');

    // Every place's interior: the picture is what to check, so these are the
    // full strip, without a ticket over it.
    for (final scenario in ScenarioCatalog.all) {
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpApp(tester, stage(thinking: false, scenario: scenario.id),
          characterProvider: character, settingsProvider: settings);
      await settle(700);
      await _shoot(tester, '$dir/stage_${scenario.id}.png');
    }

    // A service on the table, full and compact, then the pet eating it.
    final pizza = shopItemById('pizza')!;
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpApp(
        tester, stage(thinking: false, scenario: 'restaurant', offer: pizza),
        characterProvider: character, settingsProvider: settings);
    await settle(300);
    await _shoot(tester, '$dir/stage_offer.png');

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpApp(
        tester,
        stage(
            thinking: false,
            scenario: 'doctor',
            compact: true,
            offer: shopItemById('medicine')),
        characterProvider: character,
        settingsProvider: settings);
    await settle(300);
    await _shoot(tester, '$dir/stage_offer_compact.png');

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpApp(tester, stage(thinking: false, scenario: 'restaurant'),
        characterProvider: character, settingsProvider: settings);
    await settle(100);
    await pumpApp(
        tester,
        stage(
            thinking: false,
            scenario: 'restaurant',
            lastBought: pizza,
            bought: 1),
        characterProvider: character,
        settingsProvider: settings);
    await tester.pump(const Duration(milliseconds: 420));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
    await _shoot(tester, '$dir/stage_eating.png');
    await tester.pump(const Duration(seconds: 2));

    await tester.pumpWidget(const SizedBox.shrink());
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
