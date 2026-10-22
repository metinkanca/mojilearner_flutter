import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/character_sprite.dart';
import 'package:mojilearner_flutter/l10n/app_localizations.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/user_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/router.dart';
import 'package:mojilearner_flutter/screens/home_screen.dart';
import 'package:mojilearner_flutter/utils/intro_handoff.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';
import '../helpers/test_fixtures.dart';

class MockVocabProvider extends Mock implements VocabProvider {}

/// A user whose onboarding flag actually flips, so the router's redirect
/// behaves the way it does in the app.
///
/// This is the whole point of the test: [UserProvider.markOnboardingComplete]
/// notifies, the router is listening, and its redirect carries the player off
/// the last onboarding screen by itself. Anything the home screen needs has
/// to already be waiting for it when that happens — a `go()` afterwards is
/// too late.
class _OnboardingUser extends MockUserProvider {
  bool _complete = false;

  @override
  bool get hasCompletedOnboarding => _complete;

  @override
  Future<void> markOnboardingComplete() async {
    _complete = true;
    notifyListeners();
  }
}

void main() {
  late _OnboardingUser mockUser;
  late MockCharacterProvider mockCharacter;
  late MockLanguageProvider mockLanguage;
  late MockSettingsProvider mockSettings;
  late MockDailyRewardProvider mockDailyReward;
  late MockCalibrationProvider mockCalibration;
  late MockVocabProvider mockVocab;

  setUp(() {
    IntroHandoff.reset();

    mockUser = _OnboardingUser();
    mockCharacter = MockCharacterProvider();
    mockLanguage = MockLanguageProvider();
    mockSettings = MockSettingsProvider();
    mockDailyReward = MockDailyRewardProvider();
    mockCalibration = MockCalibrationProvider();
    mockVocab = MockVocabProvider();

    when(() => mockUser.stats).thenReturn(TestFixtures.buildUserStats());
    when(() => mockUser.username).thenReturn('Rin');
    when(() => mockUser.isLoading).thenReturn(false);

    when(() => mockCalibration.isLoading).thenReturn(false);
    when(() => mockCalibration.hasAnyCalibratedLanguage).thenReturn(false);

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
    when(() => mockCharacter.petThePet()).thenReturn(true);

    when(() => mockLanguage.targetLanguage).thenReturn(
      const Language(code: 'es', name: 'Spanish'),
    );
    when(() => mockSettings.usePixelFont).thenReturn(true);
    when(() => mockVocab.dueCount(languageCode: any(named: 'languageCode')))
        .thenReturn(0);
  });

  tearDown(IntroHandoff.reset);

  Future<void> rub(WidgetTester tester, Offset at, List<double> legs) async {
    const step = 8.0;
    final gesture = await tester.startGesture(at);
    for (final leg in legs) {
      final sign = leg.isNegative ? -1.0 : 1.0;
      var moved = 0.0;
      while (moved < leg.abs()) {
        final hop = (leg.abs() - moved).clamp(0.0, step);
        await gesture.moveBy(Offset(sign * hop, 0));
        await tester.pump();
        moved += hop;
      }
    }
    await gesture.up();
    await tester.pump();
  }

  Rect paintedPet(WidgetTester tester) {
    final finder = find.byType(CharacterSprite);
    return Rect.fromPoints(
      tester.getTopLeft(finder),
      tester.getBottomRight(finder),
    );
  }

  testWidgets('the pet does not jump between the last screen and home',
      (tester) async {
    final router = createRouter(refreshListenable: mockUser);
    router.go(petTutorialRoute);

    await pumpAppWithRouter(
      tester,
      router,
      userProvider: mockUser,
      characterProvider: mockCharacter,
      languageProvider: mockLanguage,
      settingsProvider: mockSettings,
      dailyRewardProvider: mockDailyReward,
      calibrationProvider: mockCalibration,
      vocabProvider: mockVocab,
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Meet the pet.
    final pet = tester.getRect(find.byType(CharacterSprite));
    await rub(
      tester,
      Offset(pet.center.dx, pet.top + pet.height * 0.4),
      const [60, -60, 60],
    );
    await tester.pump(const Duration(milliseconds: 300));

    final poseOnLeaving = paintedPet(tester);

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.tap(find.text(l10n.continueBtn));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // We are home, and the pet has not moved a pixel across the cut. This is
    // the assertion the whole handoff exists for.
    expect(find.byType(HomeScreen), findsOneWidget);
    final poseOnArriving = paintedPet(tester);
    expect(poseOnArriving.width, closeTo(poseOnLeaving.width, 1));
    expect(poseOnArriving.bottom, closeTo(poseOnLeaving.bottom, 1));

    // ...and then it walks into its own place.
    await tester.pump(const Duration(milliseconds: 800));
    final settled = paintedPet(tester);
    expect(settled.bottom, isNot(closeTo(poseOnLeaving.bottom, 2)),
        reason: 'the pet should have moved into its home pose by now');
  });

  testWidgets('a pose is never left lying around for the next visit',
      (tester) async {
    final router = createRouter(refreshListenable: mockUser);
    router.go(petTutorialRoute);

    await pumpAppWithRouter(
      tester,
      router,
      userProvider: mockUser,
      characterProvider: mockCharacter,
      languageProvider: mockLanguage,
      settingsProvider: mockSettings,
      dailyRewardProvider: mockDailyReward,
      calibrationProvider: mockCalibration,
      vocabProvider: mockVocab,
    );
    await tester.pump(const Duration(milliseconds: 300));

    final pet = tester.getRect(find.byType(CharacterSprite));
    await rub(
      tester,
      Offset(pet.center.dx, pet.top + pet.height * 0.4),
      const [60, -60, 60],
    );
    await tester.pump(const Duration(milliseconds: 300));

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.tap(find.text(l10n.continueBtn));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 800));

    // Claimed exactly once: the second home screen of the session is an
    // ordinary visit, not a replay of the intro.
    expect(IntroHandoff.claim(), isNull);
  });
}
