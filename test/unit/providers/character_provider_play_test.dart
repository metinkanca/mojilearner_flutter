import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:mojilearner_flutter/utils/play_catch.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A game of catch pays happiness the way petting does: always played in
/// full, paid at most once a cooldown, and the cooldown survives a restart.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var clock = DateTime(2026, 9, 17, 12);

  setUp(() {
    clock = DateTime(2026, 9, 17, 12);
    SharedPreferences.setMockInitialValues({'pet_happiness': 40});
  });

  Future<CharacterProvider> build() async {
    final provider =
        CharacterProvider(startDecayTimer: false, now: () => clock);
    await Future.delayed(const Duration(milliseconds: 50));
    return provider;
  }

  test('a game pays a point a catch', () async {
    final provider = await build();

    expect(provider.rewardPlay(right: 6, rounds: 10), 6);
    expect(provider.happiness, 46);
  });

  test('a clean game pays the bonus too', () async {
    final provider = await build();

    final gained = provider.rewardPlay(right: 10, rounds: 10);

    expect(gained, 10 + PlayCatchRules.cleanGameBonus);
    expect(provider.happiness, 40 + gained);
  });

  test('a game with no catches pays nothing and starts no cooldown',
      () async {
    final provider = await build();

    expect(provider.rewardPlay(right: 0, rounds: 10), 0);
    expect(provider.canEarnFromPlay, isTrue);
  });

  test('a second game inside the cooldown pays nothing', () async {
    final provider = await build();
    provider.rewardPlay(right: 5, rounds: 10);

    clock = clock.add(const Duration(minutes: 10));

    expect(provider.canEarnFromPlay, isFalse);
    expect(provider.rewardPlay(right: 10, rounds: 10), 0);
    expect(provider.happiness, 45);
  });

  test('pays again once the cooldown has passed', () async {
    final provider = await build();
    provider.rewardPlay(right: 5, rounds: 10);

    clock = clock.add(CharacterProvider.playCooldown);

    expect(provider.rewardPlay(right: 5, rounds: 10), 5);
  });

  test('reports only what fits under a full bar', () async {
    SharedPreferences.setMockInitialValues({'pet_happiness': 95});
    final provider = await build();

    expect(provider.rewardPlay(right: 10, rounds: 10), 5);
    expect(provider.happiness, 100);
  });

  test('a restart does not reset the cooldown', () async {
    final provider = await build();
    provider.rewardPlay(right: 5, rounds: 10);
    await Future.delayed(const Duration(milliseconds: 50));

    final restarted = await build();

    expect(restarted.canEarnFromPlay, isFalse);
  });
}
