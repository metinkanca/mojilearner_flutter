import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/sleep_zs.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/screens/home_screen.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';
import '../helpers/test_fixtures.dart';

class MockVocabProvider extends Mock implements VocabProvider {}

/// The sleep trail: three z's that drift off the pet while it is asleep.
///
/// Two things are worth holding. It has to be tied to the pet actually being
/// asleep — a trail on a wide-awake pet is worse than no trail at all — and
/// the three glyphs have to stay visible rather than all pulsing to nothing
/// together, which is what a naive stagger produces at the loop boundary.
void main() {
  const handset = Size(400, 844);

  group('the trail itself', () {
    Future<void> pumpTrail(WidgetTester tester) async {
      final settings = MockSettingsProvider();
      when(() => settings.usePixelFont).thenReturn(true);

      await pumpApp(
        tester,
        const Center(child: SleepZs(baseSize: 24)),
        settingsProvider: settings,
      );
      await tester.pump();
    }

    testWidgets('is three white z glyphs', (tester) async {
      await pumpTrail(tester);

      expect(find.text('z'), findsNWidgets(3));
      // White on a dark outline: the trail is read against the night sky as
      // often as the day one.
      for (final text in tester.widgetList<Text>(find.text('z'))) {
        expect(text.style?.color, Colors.white);
      }
    });

    List<double> opacities(WidgetTester tester) => tester
        .widgetList<Opacity>(find.ancestor(
          of: find.text('z'),
          matching: find.byType(Opacity),
        ))
        .map((o) => o.opacity)
        .toList();

    // Sampled across the loop rather than at one frame, because what is being
    // checked is the shape of the whole cycle: every z has to reach full and
    // then reach nothing, and at some point the trail has to be entirely gone.
    testWidgets('every z fades right up and right back out', (tester) async {
      await pumpTrail(tester);

      final peak = <double>[0, 0, 0];
      final trough = <double>[1, 1, 1];
      var sawEmptyTrail = false;

      for (var step = 0; step < 26; step++) {
        await tester.pump(const Duration(milliseconds: 100));
        final now = opacities(tester);
        expect(now, hasLength(3));

        for (var i = 0; i < 3; i++) {
          if (now[i] > peak[i]) peak[i] = now[i];
          if (now[i] < trough[i]) trough[i] = now[i];
        }
        if (now.every((o) => o == 0.0)) sawEmptyTrail = true;
      }

      for (var i = 0; i < 3; i++) {
        expect(peak[i], greaterThan(0.9), reason: 'z$i never reached full');
        expect(trough[i], 0.0, reason: 'z$i never disappeared');
      }
      expect(
        sawEmptyTrail,
        isTrue,
        reason: 'the trail never cleared completely within a cycle',
      );
    });

    testWidgets('climbs to the right, smallest at the top', (tester) async {
      await pumpTrail(tester);

      final rects =
          tester.widgetList<Text>(find.text('z')).toList().asMap().entries.map(
                (e) => tester.getRect(find.text('z').at(e.key)),
              );

      final ordered = rects.toList();
      // Each z is further right and higher than the one before it.
      for (var i = 1; i < ordered.length; i++) {
        expect(ordered[i].left, greaterThan(ordered[i - 1].left));
        expect(ordered[i].top, lessThan(ordered[i - 1].top));
        expect(ordered[i].height, lessThan(ordered[i - 1].height));
      }
    });
  });

  group('on the home screen', () {
    late MockUserProvider mockUser;
    late MockDailyRewardProvider mockDailyReward;
    late MockCharacterProvider mockCharacter;
    late MockLanguageProvider mockLanguage;
    late MockSettingsProvider mockSettings;
    late MockVocabProvider mockVocab;

    setUp(() {
      mockUser = MockUserProvider();
      mockDailyReward = MockDailyRewardProvider();
      mockCharacter = MockCharacterProvider();
      mockLanguage = MockLanguageProvider();
      mockSettings = MockSettingsProvider();
      mockVocab = MockVocabProvider();

      when(() => mockUser.stats).thenReturn(TestFixtures.buildUserStats());
      when(() => mockUser.isLoading).thenReturn(false);

      when(() => mockDailyReward.checkDailyReward())
          .thenAnswer((_) async => null);
      when(() => mockDailyReward.pendingDailyReward).thenReturn(null);

      when(() => mockCharacter.hunger).thenReturn(10);
      when(() => mockCharacter.happiness).thenReturn(90);
      when(() => mockCharacter.health).thenReturn(100);
      when(() => mockCharacter.inventory).thenReturn(const []);
      when(() => mockCharacter.currentCharacterAsset)
          .thenReturn('assets/svgs/cat.svg');
      when(() => mockCharacter.customization)
          .thenReturn(TestFixtures.buildCustomization());
      when(() => mockCharacter.isSleeping).thenReturn(false);
      when(() => mockCharacter.isAiIssueSleepMode).thenReturn(false);
      when(() => mockCharacter.isTemporarilyAwake).thenReturn(false);
      when(() => mockCharacter.isSleepingForNight).thenReturn(false);
      when(() => mockCharacter.awakeUntil).thenReturn(null);
      when(() => mockCharacter.heldFoodId).thenReturn(null);

      when(() => mockLanguage.targetLanguage).thenReturn(
        const Language(code: 'es', name: 'Spanish'),
      );
      when(() => mockSettings.usePixelFont).thenReturn(true);
      when(() => mockVocab.dueCount(languageCode: any(named: 'languageCode')))
          .thenReturn(0);
    });

    Future<void> pumpHome(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(handset);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpApp(
        tester,
        const HomeScreen(),
        userProvider: mockUser,
        dailyRewardProvider: mockDailyReward,
        characterProvider: mockCharacter,
        languageProvider: mockLanguage,
        settingsProvider: mockSettings,
        vocabProvider: mockVocab,
      );
      // Not pumpAndSettle: the pet's breathing animation never settles.
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('an awake pet has no trail', (tester) async {
      await pumpHome(tester);

      expect(find.byType(SleepZs), findsNothing);
    });

    testWidgets('a pet asleep for the night gets one', (tester) async {
      when(() => mockCharacter.isSleeping).thenReturn(true);
      when(() => mockCharacter.isSleepingForNight).thenReturn(true);

      await pumpHome(tester);

      expect(find.byType(SleepZs), findsOneWidget);
    });

    // Reconnect-dozing is the other half of `isSleeping`, and the bubble
    // already calls it dozing, so the trail belongs there too.
    testWidgets('so does a pet dozing through a reconnect', (tester) async {
      when(() => mockCharacter.isSleeping).thenReturn(true);
      when(() => mockCharacter.isAiIssueSleepMode).thenReturn(true);

      await pumpHome(tester);

      expect(find.byType(SleepZs), findsOneWidget);
    });

    // Up and to the right of the pet's head, in the headroom the art's viewBox
    // already reserves — not floating out over the sky somewhere.
    testWidgets('sits at the top right of the pet', (tester) async {
      when(() => mockCharacter.isSleeping).thenReturn(true);
      when(() => mockCharacter.isSleepingForNight).thenReturn(true);

      await pumpHome(tester);

      final trail = tester.getRect(find.byType(SleepZs));
      final pet = tester.getRect(find.byType(HomeScreen));

      expect(trail.center.dx, greaterThan(pet.center.dx));
      expect(trail.top, lessThan(pet.center.dy));
    });

    // The lid closes downward from a pivot at the eyes' bottom edge, so a
    // fully shut eye is a near-zero vertical scale on that Transform. The
    // pivot is what identifies it among the sprite's other Transforms.
    //
    // The literal tracks `eyesPivot` in character_sprite.dart, which is derived
    // from the art canvas -- so growing the canvas moves it. It cannot be
    // imported: the pivot lives in a private map.
    Iterable<double> eyeScales(WidgetTester tester) => tester
        .widgetList<Transform>(find.byType(Transform))
        .where((t) => t.alignment == const Alignment(0.248, 0.091))
        .map((t) => t.transform.getRow(1)[1]);

    testWidgets('a sleeping pet holds its eyes shut', (tester) async {
      when(() => mockCharacter.isSleeping).thenReturn(true);
      when(() => mockCharacter.isSleepingForNight).thenReturn(true);

      await pumpHome(tester);

      final scales = eyeScales(tester);
      expect(scales, isNotEmpty, reason: 'no eye layer found on the sprite');
      expect(scales.first, lessThan(0.2));
    });

    // The eyes have to reopen, or the pet looks asleep for the rest of the
    // session. An awake pet blinks, so this samples the resting frame.
    testWidgets('and opens them again once awake', (tester) async {
      await pumpHome(tester);

      expect(eyeScales(tester).first, greaterThan(0.9));
    });

    group('the awake countdown', () {
      setUp(() {
        when(() => mockCharacter.isTemporarilyAwake).thenReturn(true);
        when(() => mockCharacter.awakeUntil).thenReturn(
          // The badge rounds up, so ten and a half minutes reads as eleven
          // and the assertion cannot race the clock.
          DateTime.now().add(const Duration(minutes: 10, seconds: 30)),
        );
      });

      testWidgets('counts down the snooze', (tester) async {
        await pumpHome(tester);

        expect(find.text('Awake for 11 min'), findsOneWidget);
      });

      // It used to be the one hardcoded English string left on the screen.
      testWidgets('is localized', (tester) async {
        await tester.binding.setSurfaceSize(handset);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await pumpApp(
          tester,
          const HomeScreen(),
          userProvider: mockUser,
          dailyRewardProvider: mockDailyReward,
          characterProvider: mockCharacter,
          languageProvider: mockLanguage,
          settingsProvider: mockSettings,
          vocabProvider: mockVocab,
          locale: const Locale('de'),
        );
        await tester.pump(const Duration(seconds: 1));

        expect(find.text('Noch 11 Min wach'), findsOneWidget);
      });
    });
  });
}
