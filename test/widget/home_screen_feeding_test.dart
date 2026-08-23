import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/bond_meter.dart';
import 'package:mojilearner_flutter/components/carried_food.dart';
import 'package:mojilearner_flutter/components/character_sprite.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/screens/home_screen.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';
import '../helpers/test_fixtures.dart';

class MockVocabProvider extends Mock implements VocabProvider {}

/// Feeding, as it reaches the home screen.
///
/// Carried food used to live inside the pet layer, pinned to the very bottom
/// of the scene. Two later siblings then painted over it — the pet itself and
/// the bond strip — so the moment the player picked something up, the thing
/// they were holding was half hidden behind the animal they were offering it
/// to. These tests pin that it now floats clear, on top, and reachable.
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

    // A contented pet, so no care badge shares the top row with the feed
    // button and the geometry under test is the plain case.
    when(() => mockCharacter.hunger).thenReturn(10);
    when(() => mockCharacter.happiness).thenReturn(90);
    when(() => mockCharacter.health).thenReturn(100);
    when(() => mockCharacter.inventory).thenReturn(const ['apple']);
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
    when(() => mockCharacter.putDownFood()).thenReturn(null);
    when(() => mockCharacter.offerFood(any()))
        .thenAnswer((_) async => true);

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

  /// Puts an apple in the player's hand.
  void holdFood() {
    when(() => mockCharacter.heldFoodId).thenReturn('apple');
  }

  testWidgets('nothing is carried until a food is picked up', (tester) async {
    await pumpHome(tester);

    expect(find.text('🍎'), findsOneWidget); // the feed button, not held food
    expect(find.textContaining('Drag onto Moji'), findsNothing);
  });

  testWidgets('carried food floats clear of the bond strip', (tester) async {
    holdFood();
    await pumpHome(tester);

    final food = tester.getRect(find.byType(CarriedFood));
    final bond = tester.getRect(find.byType(BondMeter));

    expect(
      food.bottom,
      lessThanOrEqualTo(bond.top),
      reason: 'carried food overlapped the bond strip',
    );
  });

  // The occlusion regression, stated as behaviour rather than geometry: a tap
  // where the food is drawn has to reach the food. When it sat under the pet
  // layer this petted the cat instead.
  testWidgets('a tap on the carried food reaches the food, not the pet',
      (tester) async {
    holdFood();
    await pumpHome(tester);

    await tester.tap(find.descendant(
      of: find.byType(CarriedFood),
      matching: find.text('🍎'),
    ));
    await tester.pump();

    verify(() => mockCharacter.offerFood('apple')).called(1);
    verifyNever(() => mockCharacter.petThePet());
  });

  group('the feed button', () {
    testWidgets('opens the food shelf directly, not the stat panel',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpHome(tester);

      await tester.tap(find.bySemanticsLabel('Feed Moji'));
      // Not pumpAndSettle: the pet keeps breathing behind the dialog.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('FEED MOJI'), findsOneWidget);
      // The care panel's own heading, which this route deliberately skips.
      expect(find.text('HOW IS MOJI?'), findsNothing);
      semantics.dispose();
    });

    testWidgets('is there even when the pet is perfectly well', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpHome(tester);

      // No care badge — the pet is fine — and the feed button is still up.
      expect(find.text('!'), findsNothing);
      expect(find.bySemanticsLabel('Feed Moji'), findsOneWidget);
      semantics.dispose();
    });
  });

  // The pet stands on the ground, and it fills the box it is given.
  //
  // Both halves regressed silently once: wrapping the sprite in a Stack handed
  // it loose constraints, and the sprite falls back to the art's intrinsic
  // 222x328 viewBox whenever its constraints are not tight. It shrank to two
  // thirds and floated up off the grass, with the drop shadow left behind on
  // the ground below it. Nothing threw — it just looked wrong.
  group('the pet in the scene', () {
    testWidgets('fills its box rather than the art viewBox', (tester) async {
      await pumpHome(tester);

      final sprite = tester.getRect(find.byType(CharacterSprite));

      // 0.86 of a 400pt handset, and the height that aspect implies.
      expect(sprite.width, closeTo(344, 1));
      expect(sprite.height, closeTo(344 * 328 / 222, 1));
    });

    testWidgets('stands on the ground, above the bond strip', (tester) async {
      await pumpHome(tester);

      final sprite = tester.getRect(find.byType(CharacterSprite));
      final bond = tester.getRect(find.byType(BondMeter));
      final horizon = handset.height * 5 / 9;

      expect(
        sprite.bottom,
        greaterThan(horizon),
        reason: 'the pet was left floating in the sky',
      );
      expect(sprite.bottom, lessThan(bond.top));
    });
  });
}
