import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/providers/user_provider.dart';
import 'package:mojilearner_flutter/utils/play_games.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The toy chest's games pay XP, a little, and no more than their daily cap
/// however many are played: they are the one XP source a player could repeat
/// for an hour without tiring.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<UserProvider> buildProvider() async {
    final provider = UserProvider();
    await Future.delayed(const Duration(milliseconds: 50));
    return provider;
  }

  test('a game pays its XP into the ledger', () async {
    final provider = await buildProvider();
    final before = provider.totalXP;

    expect(await provider.awardPlayXp(8), 8);

    expect(provider.totalXP, before + 8);
    expect(provider.playXpRemainingToday, PlayRewards.dailyXpCap - 8);
  });

  test('games stop paying at the daily cap', () async {
    final provider = await buildProvider();
    final before = provider.totalXP;

    var paid = 0;
    for (var i = 0; i < 10; i++) {
      paid += await provider.awardPlayXp(PlayRewards.fullGameXp);
    }

    expect(paid, PlayRewards.dailyXpCap);
    expect(provider.totalXP, before + PlayRewards.dailyXpCap);
    expect(provider.playXpRemainingToday, 0);
  });

  test('the game that reaches the cap is paid only what fits', () async {
    final provider = await buildProvider();
    await provider.awardPlayXp(PlayRewards.dailyXpCap - 3);

    expect(await provider.awardPlayXp(10), 3);
    expect(await provider.awardPlayXp(10), 0);
  });

  test('a game with nothing right pays nothing', () async {
    final provider = await buildProvider();

    expect(await provider.awardPlayXp(0), 0);
    expect(provider.playXpRemainingToday, PlayRewards.dailyXpCap);
  });

  test('a restart does not reset the cap', () async {
    final first = await buildProvider();
    await first.awardPlayXp(PlayRewards.dailyXpCap);

    final second = await buildProvider();

    expect(second.playXpRemainingToday, 0);
    expect(await second.awardPlayXp(10), 0);
  });

  test('yesterday\'s games do not count against today', () async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    SharedPreferences.setMockInitialValues({
      'play_xp_day': yesterday.millisecondsSinceEpoch,
      'play_xp_today': PlayRewards.dailyXpCap,
    });
    final provider = await buildProvider();

    expect(provider.playXpRemainingToday, PlayRewards.dailyXpCap);
    expect(await provider.awardPlayXp(10), 10);
  });
}
