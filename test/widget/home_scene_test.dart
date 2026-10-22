import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/character_sprite.dart';
import 'package:mojilearner_flutter/components/home_action_bar.dart';
import 'package:mojilearner_flutter/components/play/toy_chest.dart';
import 'package:mojilearner_flutter/components/scene_backdrop.dart';
import 'package:mojilearner_flutter/constants/scenes.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/screens/home_screen.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';
import '../helpers/test_fixtures.dart';

class MockVocabProvider extends Mock implements VocabProvider {}

/// Where the pet stands in its world.
///
/// A scene is a sky band over a ground band, split at the scene's own horizon,
/// and the pet is planted a fixed clearance above the bottom of the layer it
/// lives in. Those two are only in agreement if the scene is measured against
/// that same layer. Measured against the window instead, the ground band runs
/// on behind the nav bar, the horizon rides up to where the
/// pet's feet are, and the pet reads as standing on the skyline rather than on
/// the ground -- which is the state these tests exist to keep the screen out of.
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
    when(() => mockDailyReward.checkDailyReward())
        .thenAnswer((_) async => null);
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
    when(() => mockLanguage.targetLanguage)
        .thenReturn(const Language(code: 'es', name: 'Spanish'));
    when(() => mockSettings.usePixelFont).thenReturn(true);
    when(() => mockVocab.dueCount(languageCode: any(named: 'languageCode')))
        .thenReturn(0);
  });

  Future<void> pumpHome(WidgetTester tester) async {
    await pumpApp(
      tester,
      HomeScreen(key: UniqueKey()),
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

  /// The ground band, found by its paint: it is the one box filled with the
  /// scene's ground colour.
  Rect groundBand(WidgetTester tester) {
    final palette = mockCharacter.scene.paletteFor(sceneTimeAt(DateTime.now()));
    return tester.getRect(
      find
          .byWidgetPredicate((w) => w is Container && w.color == palette.ground)
          .first,
    );
  }

  /// The pet's box as actually painted -- see the note in
  /// `home_arrival_test.dart`, which takes it the same way and for the same
  /// reason.
  Rect paintedPet(WidgetTester tester) {
    final finder = find.byType(CharacterSprite);
    return Rect.fromPoints(
      tester.getTopLeft(finder),
      tester.getBottomRight(finder),
    );
  }

  testWidgets('the pet stands on the ground, not on the horizon',
      (tester) async {
    await pumpHome(tester);

    final ground = groundBand(tester);
    final pet = paintedPet(tester);

    expect(pet.bottom, greaterThan(ground.top),
        reason: 'the feet must be below the horizon');
    expect(pet.bottom, lessThanOrEqualTo(ground.bottom),
        reason: 'and above the near edge of the ground');
  });

  testWidgets('and there is ground left under its feet', (tester) async {
    await pumpHome(tester);

    final ground = groundBand(tester);
    final pet = paintedPet(tester);

    // The clearance the pet is planted at. Anything less and the pet is
    // standing on the very last row of pixels in the scene.
    expect(ground.bottom - pet.bottom, greaterThanOrEqualTo(24));
  });

  // A picture is usually taller than the space it gets, so something is
  // cropped. The room gives up its bare wall; the enchanted meadow's moon and
  // stars are the point of it, so it gives up bare ground instead. The home
  // screen has to pass that on, or every picture is bottom-anchored again.
  testWidgets('a scene picture is anchored where its scene asks',
      (tester) async {
    for (final id in [
      kCozyRoomSceneId,
      kEnchantedMeadowSceneId,
      kMushroomGladeSceneId,
    ]) {
      mockCharacter.scene = sceneThemeById(id)!;
      await pumpHome(tester);

      final backdrop = tester.widget<SceneBackdrop>(find.byType(SceneBackdrop));
      expect(backdrop.alignment, mockCharacter.scene.homeAlignment,
          reason: '$id is anchored somewhere other than it asked');
    }
    expect(sceneThemeById(kEnchantedMeadowSceneId)!.homeAlignment,
        Alignment.topCenter);
    expect(sceneThemeById(kCozyRoomSceneId)!.homeAlignment,
        Alignment.bottomCenter);
    // The glade's sky is plain and its toadstools stand on the horizon, so it
    // gives up sky like the room does.
    expect(sceneThemeById(kMushroomGladeSceneId)!.homeAlignment,
        Alignment.bottomCenter);
  });

  // Showing the top of a picture takes ground off the bottom of it, and the
  // pet is planted a fixed distance above the bottom. It still has to be
  // standing on ground.
  testWidgets('the pet still stands on the ground in the enchanted meadow',
      (tester) async {
    mockCharacter.scene = sceneThemeById(kEnchantedMeadowSceneId)!;
    await pumpHome(tester);

    final ground = groundBand(tester);
    final pet = paintedPet(tester);

    expect(pet.bottom, greaterThan(ground.top),
        reason: 'the feet must be below the horizon');
    expect(ground.bottom - pet.bottom, greaterThanOrEqualTo(24));
  });

  testWidgets('the things on the ground stand clear of the pet',
      (tester) async {
    await pumpHome(tester);

    final ground = groundBand(tester);
    final pet = tester.getRect(find.byType(CharacterSprite));
    final toys = tester.getRect(find.byType(ToyChest));
    final books = tester.getRect(find.byKey(HomeActionBar.mistakesKey));

    for (final rect in [toys, books]) {
      expect(rect.top, greaterThan(ground.top),
          reason: 'they rest on the ground, not in the sky');
      expect(rect.bottom, lessThanOrEqualTo(ground.bottom));
    }
    // The chest is in the margin beside the pet, the books in front of it.
    expect(toys.left, greaterThanOrEqualTo(pet.right));
    expect(books.top, greaterThanOrEqualTo(pet.bottom),
        reason: 'the low books stand in front of the feet, never over the pet');
  });
}
