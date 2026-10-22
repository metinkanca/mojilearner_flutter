import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/scenes.dart';
import 'package:mojilearner_flutter/constants/season_pass.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:mojilearner_flutter/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The one world that is neither free nor for sale.
///
/// A scene claimed off a pass track is owned the way every other world is —
/// through the unlocked set — because the home screen has to answer "which
/// world am I painting" with no pass record in reach. The pass record stays
/// the durable one, so the two halves have to be able to find each other
/// whichever order they load in, which is what most of this file is about.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final pass = seasonPassById(kSeasonOneId)!;

  /// A save in which the whole of [pass] has been claimed.
  String claimedThrough(int tier) => json.encode([
        {'id': pass.id, 'xp': 0, 'claimed': tier},
      ]);

  Future<CharacterProvider> buildCharacter() async {
    final provider = CharacterProvider();
    await Future.delayed(const Duration(milliseconds: 50));
    return provider;
  }

  Future<UserProvider> buildUser() async {
    final provider = UserProvider();
    await Future.delayed(const Duration(milliseconds: 50));
    return provider;
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the airfield is the last tier of season one', () {
    final finale = pass.tiers.last;

    expect(finale.isScene, isTrue);
    expect(finale.sceneId, kAirfieldSceneId);
    expect(finale.accessoryId, isNull);
    // Everything before it is something to wear, so the finale is the only
    // rung that changes the screen rather than the pet.
    for (final tier in pass.tiers.take(pass.tiers.length - 1)) {
      expect(tier.isScene, isFalse);
    }
  });

  test('a new player does not own it', () async {
    final character = await buildCharacter();

    expect(character.ownsScene(kAirfieldSceneId), isFalse);
    expect(character.equipScene(kAirfieldSceneId), isFalse);
    expect(character.sceneId, kDefaultSceneId);
  });

  // The claim is the hand-over, and it moves the pet in — the same beat
  // buying a scene has, for a rung that cost 5,500 XP rather than 200 coins.
  test('granting it hands the world over and moves the pet in', () async {
    final character = await buildCharacter();

    expect(character.grantScene(kAirfieldSceneId), isTrue);

    expect(character.ownsScene(kAirfieldSceneId), isTrue);
    expect(character.sceneId, kAirfieldSceneId);
  });

  // A re-claim, or the reconciliation below, must not move a player who has
  // since gone back to the meadow.
  test('granting it twice does not move the pet again', () async {
    final character = await buildCharacter();
    character.grantScene(kAirfieldSceneId);
    character.equipScene(kDefaultSceneId);

    expect(character.grantScene(kAirfieldSceneId), isFalse);
    expect(character.sceneId, kDefaultSceneId);
  });

  test('an unknown id grants nothing', () async {
    final character = await buildCharacter();

    expect(character.grantScene('bg_atlantis'), isFalse);
    expect(character.ownsScene('bg_atlantis'), isFalse);
  });

  test('the world survives a restart', () async {
    final first = await buildCharacter();
    first.grantScene(kAirfieldSceneId);
    await Future.delayed(const Duration(milliseconds: 50));

    final second = await buildCharacter();

    expect(second.ownsScene(kAirfieldSceneId), isTrue);
    expect(second.sceneId, kAirfieldSceneId);
  });

  // The claim writes two saves — the pass record and the pet state — and a
  // player killed between them would otherwise be left with a tier marked
  // claimed and no world to show for it.
  test('a claim whose unlock never landed is put back', () async {
    SharedPreferences.setMockInitialValues({
      'season_passes': claimedThrough(pass.tiers.length - 1),
    });

    final user = await buildUser();
    final character = await buildCharacter();
    character.updateFromUser(user);

    expect(character.ownsScene(kAirfieldSceneId), isTrue);
    // Put back, not re-staged: the hand-over already happened, and moving the
    // pet on a later launch would read as a bug.
    expect(character.sceneId, kDefaultSceneId);
  });

  // The two providers load independently, so the pass record can arrive
  // either side of the pet state.
  test('the record arriving before the save is still applied', () async {
    SharedPreferences.setMockInitialValues({
      'season_passes': claimedThrough(pass.tiers.length - 1),
    });

    final user = await buildUser();
    // Reported to a provider that has not finished reading its own save,
    // which is what the proxy in `main.dart` does on a cold start.
    final character = CharacterProvider();
    character.updateFromUser(user);
    await Future.delayed(const Duration(milliseconds: 50));

    expect(character.ownsScene(kAirfieldSceneId), isTrue);
  });

  // A track claimed up to the rung *before* the finale hands over ten pieces
  // and no world.
  test('an unfinished track grants no world', () async {
    SharedPreferences.setMockInitialValues({
      'season_passes': claimedThrough(pass.tiers.length - 2),
    });

    final user = await buildUser();
    final character = await buildCharacter();
    character.updateFromUser(user);

    expect(user.claimedPassSceneIds, isEmpty);
    expect(character.ownsScene(kAirfieldSceneId), isFalse);
  });

  // The wardrobe reads this to decide it may not put a price on the tile.
  test('the pass scene is not claimed as an accessory', () async {
    SharedPreferences.setMockInitialValues({
      'season_passes': claimedThrough(pass.tiers.length - 1),
    });

    final user = await buildUser();

    expect(user.claimedPassSceneIds, {kAirfieldSceneId});
    expect(user.claimedPassItemIds, isNot(contains(kAirfieldSceneId)));
    expect(user.claimedPassItemIds, hasLength(pass.tiers.length - 1));
  });
}
