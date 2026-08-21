import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/character_sprite.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/screens/home_screen.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';
import '../helpers/test_fixtures.dart';

class MockVocabProvider extends Mock implements VocabProvider {}

/// Scratching the pet's head is the physical way to pet it.
///
/// The care panel's PLAY button pets the pet from behind a dimmed dialog
/// barrier, so the reaction it pays for is invisible; this gesture happens on
/// the pet itself, where the reaction is the whole point. What these tests
/// pin down is that it stays a *rub* — back and forth over the head — and does
/// not decay into "any horizontal drag anywhere on the scene pets the pet",
/// which would fire every time a player flicked past the scene.
void main() {
  const handset = Size(400, 844);

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
    when(() => mockCharacter.isAiIssueSleepMode).thenReturn(false);
    when(() => mockCharacter.isTemporarilyAwake).thenReturn(false);
    when(() => mockCharacter.isSleepingForNight).thenReturn(false);
    when(() => mockCharacter.awakeUntil).thenReturn(null);
    when(() => mockCharacter.petThePet()).thenReturn(true);

    when(() => mockLanguage.targetLanguage).thenReturn(
      const Language(code: 'es', name: 'Spanish', flag: '🇪🇸'),
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

  /// A point on the pet's head, taken off the sprite box the same way the
  /// hitbox is: a fraction down from the top of the art, not a screen guess.
  Offset headPoint(WidgetTester tester) {
    final box = tester.getRect(find.byType(CharacterSprite));
    return Offset(box.center.dx, box.top + box.height * 0.4);
  }

  /// A point on the pet's paws, below the head band.
  Offset pawPoint(WidgetTester tester) {
    final box = tester.getRect(find.byType(CharacterSprite));
    return Offset(box.center.dx, box.top + box.height * 0.85);
  }

  /// Drags [legs] across the screen, each leg broken into finger-sized steps.
  ///
  /// The steps matter. A leg sent as one jump loses its whole first move to
  /// the drag recognizer's touch slop, which no real finger does — it crosses
  /// the slop a few pixels in and keeps reporting the rest of the sweep.
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

  testWidgets('rubbing back and forth across the head pets the pet',
      (tester) async {
    await pumpHome(tester);

    await rub(tester, headPoint(tester), const [60, -60, 60]);

    verify(() => mockCharacter.petThePet()).called(1);
  });

  testWidgets('a rub that carries on keeps petting, so the reaction holds',
      (tester) async {
    await pumpHome(tester);

    await rub(tester, headPoint(tester), const [60, -60, 60, -60, 60]);

    verify(() => mockCharacter.petThePet()).called(2);
  });

  // Otherwise every horizontal flick past the scene would pet the pet.
  testWidgets('one swipe across is not a scratch', (tester) async {
    await pumpHome(tester);

    await rub(tester, headPoint(tester), const [60, 60, 60]);

    verifyNever(() => mockCharacter.petThePet());
  });

  // A finger resting on the pet and jittering is not affection either.
  testWidgets('jittering in place is not a scratch', (tester) async {
    await pumpHome(tester);

    await rub(tester, headPoint(tester), const [30, -6, 6, -6, 6, -6]);

    verifyNever(() => mockCharacter.petThePet());
  });

  // The head is the part being scratched. Rubbing the paws is where food is
  // dragged in from, and that drag must not read as petting.
  testWidgets('rubbing below the head does not pet', (tester) async {
    await pumpHome(tester);

    await rub(tester, pawPoint(tester), const [60, -60, 60]);

    verifyNever(() => mockCharacter.petThePet());
  });

  // A pet dozing through an AI outage stays down: the provider refuses the
  // burst anyway, so firing at it would just be a lie in the call log.
  testWidgets('scratching a dozing pet does nothing', (tester) async {
    when(() => mockCharacter.isAiIssueSleepMode).thenReturn(true);
    when(() => mockCharacter.isSleeping).thenReturn(true);
    await pumpHome(tester);

    await rub(tester, headPoint(tester), const [60, -60, 60]);

    verifyNever(() => mockCharacter.petThePet());
  });

  // Scratching a sleeping pet wakes it, the same as tapping does. Waking is
  // the whole interaction — it does not also get petted through the yawn.
  testWidgets('scratching a sleeping pet wakes it instead', (tester) async {
    when(() => mockCharacter.isSleeping).thenReturn(true);
    when(() => mockCharacter.isSleepingForNight).thenReturn(true);
    when(() => mockCharacter.wakeUp()).thenReturn(null);
    await pumpHome(tester);

    await rub(tester, headPoint(tester), const [60, -60, 60]);

    verify(() => mockCharacter.wakeUp()).called(1);
    verifyNever(() => mockCharacter.petThePet());
  });
}
