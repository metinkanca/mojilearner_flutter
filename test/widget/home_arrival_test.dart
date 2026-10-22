import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/character_sprite.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/screens/home_screen.dart';
import 'package:mojilearner_flutter/utils/intro_handoff.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';
import '../helpers/test_fixtures.dart';

class MockVocabProvider extends Mock implements VocabProvider {}

/// Arriving home from the meet-your-pet screen.
///
/// The two screens draw the pet at different sizes in different places, and
/// the join between them must not read as a cut. Home is handed the pose the
/// tutorial left the pet in and walks it into its own — so what these tests
/// hold is that it *starts* where it was told to and *ends* exactly where it
/// would have been anyway.
void main() {
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

    when(() => mockDailyReward.checkDailyReward()).thenAnswer((_) async => null);
    when(() => mockDailyReward.pendingDailyReward).thenReturn(null);

    when(() => mockCharacter.hunger).thenReturn(90);
    when(() => mockCharacter.happiness).thenReturn(90);
    when(() => mockCharacter.health).thenReturn(100);
    when(() => mockCharacter.inventory).thenReturn(const []);
    when(() => mockCharacter.currentCharacterAsset)
        .thenReturn('assets/svgs/cat.svg');
    when(() => mockCharacter.customization)
        .thenReturn(TestFixtures.buildCustomization());
    when(() => mockCharacter.isSleeping).thenReturn(false);
    when(() => mockCharacter.isTemporarilyAwake).thenReturn(false);
    when(() => mockCharacter.isSleepingForNight).thenReturn(false);
    when(() => mockCharacter.awakeUntil).thenReturn(null);

    when(() => mockLanguage.targetLanguage).thenReturn(
      const Language(code: 'es', name: 'Spanish'),
    );
    when(() => mockSettings.usePixelFont).thenReturn(true);
    when(() => mockVocab.dueCount(languageCode: any(named: 'languageCode')))
        .thenReturn(0);
  });

  Future<void> pumpHome(WidgetTester tester, {IntroHandoff? handoff}) async {
    await pumpApp(
      tester,
      // A fresh key every time. The arrival is set up in initState, and
      // without this a second pump in the same test would reuse the first
      // screen's State and quietly skip it.
      HomeScreen(key: UniqueKey(), introHandoff: handoff),
      userProvider: mockUser,
      dailyRewardProvider: mockDailyReward,
      characterProvider: mockCharacter,
      languageProvider: mockLanguage,
      settingsProvider: mockSettings,
      vocabProvider: mockVocab,
    );
    // Not pumpAndSettle: the pet's breathing animation never settles.
    await tester.pump();
  }

  /// The pet's box as actually painted.
  ///
  /// [WidgetTester.getRect] reports the layout size, which is not what is on
  /// screen while a Transform is scaling the pet in. Taking both corners
  /// through localToGlobal runs them through that transform.
  Rect paintedPet(WidgetTester tester) {
    final finder = find.byType(CharacterSprite);
    return Rect.fromPoints(
      tester.getTopLeft(finder),
      tester.getBottomRight(finder),
    );
  }

  testWidgets('an ordinary visit puts the pet straight at its resting pose',
      (tester) async {
    await pumpHome(tester);
    final resting = paintedPet(tester);

    await tester.pump(const Duration(seconds: 1));

    expect(paintedPet(tester), resting, reason: 'nothing should be animating');
  });

  testWidgets('arriving from onboarding starts the pet where it was left',
      (tester) async {
    // Resting pose first, so the arrival can be compared against it.
    await pumpHome(tester);
    final resting = paintedPet(tester);

    // A deliberately different pose: bigger, and higher up the screen.
    final left = resting.center.dx - resting.width * 0.7;
    final handoff = IntroHandoff(Rect.fromLTWH(
      left,
      resting.top - 120,
      resting.width * 1.4,
      resting.height * 1.4,
    ));

    await pumpHome(tester, handoff: handoff);
    final first = paintedPet(tester);

    expect(first.width, closeTo(handoff.petRect.width, 1));
    expect(first.bottom, closeTo(handoff.petRect.bottom, 1));
  });

  testWidgets('and settles it exactly where it belongs', (tester) async {
    await pumpHome(tester);
    final resting = paintedPet(tester);

    await pumpHome(
      tester,
      handoff: IntroHandoff(Rect.fromLTWH(
        resting.center.dx - resting.width * 0.7,
        resting.top - 120,
        resting.width * 1.4,
        resting.height * 1.4,
      )),
    );

    // Mid-flight it is neither pose.
    await tester.pump(const Duration(milliseconds: 300));
    expect(paintedPet(tester).bottom, isNot(closeTo(resting.bottom, 1)));

    // Landed: the arrival must leave the screen in the state it would have
    // been in with no arrival at all, or the pet keeps a limp for the session.
    await tester.pump(const Duration(milliseconds: 700));
    final landed = paintedPet(tester);
    expect(landed.width, closeTo(resting.width, 0.5));
    expect(landed.bottom, closeTo(resting.bottom, 0.5));
  });

  testWidgets('the chrome fades up rather than blinking on', (tester) async {
    await pumpHome(tester);
    final resting = paintedPet(tester);

    await pumpHome(
      tester,
      handoff: IntroHandoff(Rect.fromLTWH(
        resting.center.dx - resting.width * 0.7,
        resting.top - 120,
        resting.width * 1.4,
        resting.height * 1.4,
      )),
    );

    // Counted rather than named: the screen carries other fades of its own
    // (the nav icons), and what this is about is the three pieces of chrome
    // the arrival holds back — the top bar, the pet's voice and the action
    // bar on the ground.
    int hidden() => tester
        .widgetList<FadeTransition>(find.byType(FadeTransition))
        .where((f) => f.opacity.value == 0)
        .length;

    expect(hidden(), 3, reason: 'chrome should start invisible, not half-drawn');

    await tester.pump(const Duration(milliseconds: 700));
    expect(hidden(), 0, reason: 'and nothing should still be hidden after');
  });
}
