import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/scenes.dart';
import 'package:mojilearner_flutter/constants/shop.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:mojilearner_flutter/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_fixtures.dart';

/// Backgrounds were sellable long before they were visible: buying one
/// unlocked an id nothing ever read. These hold the two halves that fixes —
/// a bought scene is actually put up, and one that was never bought cannot
/// be, however the save gets there.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<CharacterProvider> buildProvider() async {
    final provider = CharacterProvider(startDecayTimer: false);
    await Future.delayed(const Duration(milliseconds: 50));
    return provider;
  }

  Future<UserProvider> buildUser() async {
    final user = UserProvider();
    await Future.delayed(const Duration(milliseconds: 50));
    return user;
  }

  group('the scene on screen', () {
    test('a new player starts in the free cozy room', () async {
      final provider = await buildProvider();

      expect(provider.sceneId, kDefaultSceneId);
      expect(provider.ownsScene(kDefaultSceneId), isTrue);
    });

    // The room replaced the meadow as the starting look. The meadow has to
    // stay a choice, or the change quietly took a free scene away.
    test('the meadow is still free to put up, and the room to come back to',
        () async {
      final provider = await buildProvider();

      expect(provider.ownsScene(kMeadowSceneId), isTrue);
      expect(provider.equipScene(kMeadowSceneId), isTrue);
      expect(provider.sceneId, kMeadowSceneId);

      expect(provider.equipScene(kCozyRoomSceneId), isTrue);
      expect(provider.sceneId, kCozyRoomSceneId);
    });

    test('an unbought scene cannot be put up', () async {
      final provider = await buildProvider();

      expect(provider.ownsScene('bg_galaxy'), isFalse);
      expect(provider.equipScene('bg_galaxy'), isFalse);
      expect(provider.sceneId, kDefaultSceneId);
    });

    test('an unknown id is refused', () async {
      final provider = await buildProvider();

      expect(provider.equipScene('bg_atlantis'), isFalse);
      expect(provider.sceneId, kDefaultSceneId);
    });
  });

  group('buying', () {
    test('a bought scene goes up straight away', () async {
      SharedPreferences.setMockInitialValues({
        ...TestFixtures.welcomeGiftAlreadyGiven,
        'coins': 500,
      });
      final provider = await buildProvider();
      final user = await buildUser();

      final item = shopItemById('bg_galaxy')!;
      expect(await provider.purchaseItem(item, user), isTrue);

      expect(provider.sceneId, 'bg_galaxy');
      expect(provider.scene.id, 'bg_galaxy');
    });

    test('a purchase that cannot be afforded changes nothing', () async {
      SharedPreferences.setMockInitialValues({
        ...TestFixtures.welcomeGiftAlreadyGiven,
        'coins': 0,
      });
      final provider = await buildProvider();
      final user = await buildUser();

      final item = shopItemById('bg_galaxy')!;
      expect(await provider.purchaseItem(item, user), isFalse);
      expect(provider.ownsScene('bg_galaxy'), isFalse);
      expect(provider.sceneId, kDefaultSceneId);
    });

    test('an owned scene can be swapped back and forth', () async {
      SharedPreferences.setMockInitialValues({
        ...TestFixtures.welcomeGiftAlreadyGiven,
        'coins': 500,
      });
      final provider = await buildProvider();
      final user = await buildUser();

      await provider.purchaseItem(shopItemById('bg_forest')!, user);
      expect(provider.sceneId, 'bg_forest');

      expect(provider.equipScene(kDefaultSceneId), isTrue);
      expect(provider.sceneId, kDefaultSceneId);

      expect(provider.equipScene('bg_forest'), isTrue);
      expect(provider.sceneId, 'bg_forest');
    });
  });

  group('across restarts', () {
    test('the scene the player chose is still up', () async {
      SharedPreferences.setMockInitialValues({
        'unlocked_items': ['bg_blue'],
        'scene_id': 'bg_blue',
      });
      final provider = await buildProvider();

      expect(provider.sceneId, 'bg_blue');
    });

    // A hand-edited save, or a purchase record lost some other way. The pet
    // goes home rather than living somewhere it never paid for.
    test('a saved scene with no purchase behind it falls back', () async {
      SharedPreferences.setMockInitialValues({
        'scene_id': 'bg_galaxy',
      });
      final provider = await buildProvider();

      expect(provider.sceneId, kDefaultSceneId);
    });

    test('a scene that has left the catalogue falls back', () async {
      SharedPreferences.setMockInitialValues({
        'unlocked_items': ['bg_atlantis'],
        'scene_id': 'bg_atlantis',
      });
      final provider = await buildProvider();

      expect(provider.sceneId, kDefaultSceneId);
    });
  });
}
