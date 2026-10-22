import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/character_sprite.dart';
import 'package:mojilearner_flutter/components/chat_header.dart';
import 'package:mojilearner_flutter/components/sleep_zs.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:mojilearner_flutter/utils/pixel_clock.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pet_art.dart';
import '../helpers/pump_app.dart';

/// The pixel-stepped idle motion — the pet's breath and blink, the sleep
/// trail, the chat's online dot — runs on one 8 fps clock rather than on
/// animation controllers.
///
/// What is held here is the reason it exists. An animation controller asks
/// for a frame at every refresh of the display, and every frame redraws the
/// whole screen, whether or not the picture changed. The clock asks for one a
/// step. So each of these counts the frames actually drawn over two seconds,
/// and fails if any of them goes back to a controller: that would draw one at
/// every pump.
void main() {
  late MockSettingsProvider mockSettings;

  // Counted by a frame callback that lives as long as the binding, so it only
  // counts while a test says so.
  var frames = 0;
  var counting = false;
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .addPersistentFrameCallback((_) {
      if (counting) frames++;
    });
  });

  setUp(() {
    mockSettings = MockSettingsProvider();
    when(() => mockSettings.usePixelFont).thenReturn(true);
  });

  CharacterProvider buildCharacter() {
    SharedPreferences.setMockInitialValues({
      'pet_hunger': 20,
      'pet_happiness': 50,
      'pet_health': 100,
    });
    return CharacterProvider(
        startDecayTimer: false, now: () => DateTime(2026, 3, 1, 15, 0));
  }

  /// Frames drawn over [span], pumped a few milliseconds at a time: far finer
  /// than a step, so a frame asked for at every refresh is one at every pump.
  Future<int> framesOver(WidgetTester tester, Duration span) async {
    frames = 0;
    counting = true;
    const tick = Duration(milliseconds: 4);
    for (var t = Duration.zero; t < span; t += tick) {
      await tester.pump(tick);
    }
    counting = false;
    return frames;
  }

  // Two seconds is 16 steps; a step or two either side for where the window
  // falls against the clock.
  const twoSeconds = Duration(seconds: 2);
  final aStepEach = inInclusiveRange(2 * PixelClock.fps - 2,
      2 * PixelClock.fps + 2);

  Widget pet({double size = 120}) =>
      CharacterSprite(width: size, height: size, previewType: 'cat');

  testWidgets('an idle pet asks for a frame a step, not one a refresh',
      (tester) async {
    await pumpApp(tester, Center(child: pet()),
        settingsProvider: mockSettings, characterProvider: buildCharacter());
    await settlePet(tester);

    expect(await framesOver(tester, twoSeconds), aStepEach);
  });

  testWidgets('and seven pets step together, not seven times as often',
      (tester) async {
    await pumpApp(
      tester,
      Wrap(children: [for (var i = 0; i < 7; i++) pet(size: 60)]),
      settingsProvider: mockSettings,
      characterProvider: buildCharacter(),
    );
    await settlePet(tester);

    expect(await framesOver(tester, twoSeconds), aStepEach);
  });

  testWidgets('the pet still breathes, and still blinks', (tester) async {
    await pumpApp(tester, Center(child: pet()),
        settingsProvider: mockSettings, characterProvider: buildCharacter());
    await settlePet(tester);

    // The breath is the one transform in the sprite anchored at its feet; the
    // blink squashes the eye layer about its own pivot.
    Iterable<Transform> transforms() => tester.widgetList<Transform>(
        find.descendant(
            of: find.byType(CharacterSprite),
            matching: find.byType(Transform)));
    final breaths = <double>{};
    var shutest = 1.0;
    // Long enough for a breath and for any blink: they come every 2.2-5.8s.
    for (var i = 0; i < 7000 ~/ 50; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      for (final t in transforms()) {
        final scaleY = t.transform.getRow(1)[1];
        if (t.alignment == Alignment.bottomCenter) breaths.add(scaleY);
        if (t.alignment == eyesPivotFor('cat') && scaleY < shutest) {
          shutest = scaleY;
        }
      }
    }

    expect(breaths.length, greaterThanOrEqualTo(3),
        reason: 'the body should rise and fall through several poses');
    expect(shutest, lessThan(0.2), reason: 'the eyes should close in a blink');
  });

  testWidgets('the sleep trail asks for a frame a step', (tester) async {
    await pumpApp(tester, const Center(child: SleepZs(baseSize: 24)),
        settingsProvider: mockSettings);
    await tester.pump();

    expect(await framesOver(tester, twoSeconds), aStepEach);
  });

  testWidgets('so does the chat\'s online dot', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Center(child: BlinkingDot())));
    await tester.pump();

    expect(await framesOver(tester, twoSeconds), aStepEach);
  });

  // The home screen stays mounted under a pushed route. Its pet must not go
  // on stepping there, asking for frames for a screen nobody can see.
  testWidgets('a pet on a hidden route stops the clock', (tester) async {
    await pumpApp(tester, TickerMode(enabled: false, child: Center(child: pet())),
        settingsProvider: mockSettings, characterProvider: buildCharacter());
    await tester.pump();

    expect(PixelClock.instance.isRunning, isFalse);
    expect(await framesOver(tester, twoSeconds), 0);
  });

  testWidgets('and so does reduce-motion', (tester) async {
    await pumpApp(
      tester,
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Center(child: pet()),
      ),
      settingsProvider: mockSettings,
      characterProvider: buildCharacter(),
    );
    await tester.pump();

    expect(PixelClock.instance.isRunning, isFalse);
  });

  testWidgets('the clock stops when the last thing on it goes',
      (tester) async {
    await pumpApp(tester, Center(child: pet()),
        settingsProvider: mockSettings, characterProvider: buildCharacter());
    await tester.pump();
    expect(PixelClock.instance.isRunning, isTrue);

    await tester.pumpWidget(const SizedBox());
    expect(PixelClock.instance.isRunning, isFalse);
  });
}
