import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owning a season pass: the purchase record, and what survives a restart.
///
/// The shipping catalogue is empty until the art lands, so a pass id here
/// resolves to nothing and the *progress* side is covered by
/// `test/unit/utils/season_pass_progress_test.dart`. What is pinned here is
/// the half that has to be right regardless of what is on sale — a purchase
/// recorded once, baselined on the XP at the time, and never quietly reset.
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

  test('a new player owns nothing', () async {
    final provider = await buildProvider();

    expect(provider.ownedPasses, isEmpty);
    expect(provider.ownsPass('season-1'), isFalse);
    expect(provider.claimedPassItemIds, isEmpty);
  });

  test('buying records the pass against the XP at the time', () async {
    final provider = await buildProvider();
    await provider.addXp(1200);

    expect(await provider.grantPass('season-1'), isTrue);

    expect(provider.ownsPass('season-1'), isTrue);
    expect(provider.ownedPasses.single.xpAtPurchase, 1200);
    expect(provider.ownedPasses.single.claimedThroughTier, -1);
  });

  // Both stores replay purchases on a restore. Re-baselining on the replay
  // would silently take back everything the player had worked through.
  test('a replayed purchase does not reset the baseline', () async {
    final provider = await buildProvider();
    await provider.addXp(500);
    await provider.grantPass('season-1');

    await provider.addXp(2000);
    expect(await provider.grantPass('season-1'), isFalse);

    expect(provider.ownedPasses, hasLength(1));
    expect(provider.ownedPasses.single.xpAtPurchase, 500);
  });

  test('a purchase survives a restart', () async {
    final provider = await buildProvider();
    await provider.addXp(300);
    await provider.grantPass('season-1');

    final reloaded = await buildProvider();

    expect(reloaded.ownsPass('season-1'), isTrue);
    expect(reloaded.ownedPasses.single.xpAtPurchase, 300);
  });

  test('several passes are kept side by side', () async {
    final provider = await buildProvider();
    await provider.grantPass('season-1');
    await provider.addXp(4000);
    await provider.grantPass('season-2');

    expect(provider.ownedPasses.map((p) => p.passId), ['season-1', 'season-2']);
    expect(provider.ownedPasses.first.xpAtPurchase, 0);
    expect(provider.ownedPasses.last.xpAtPurchase, 4000);
  });

  // A pass whose season is long over may still have tiers waiting, so nothing
  // here prunes. This is the storage half of "nothing expires".
  test('an old pass is never dropped', () async {
    SharedPreferences.setMockInitialValues({
      'season_passes': json.encode([
        {'id': 'season-ancient', 'xp': 10, 'claimed': 3},
      ]),
    });

    final provider = await buildProvider();

    expect(provider.ownsPass('season-ancient'), isTrue);
    expect(provider.ownedPasses.single.claimedThroughTier, 3);
  });

  // A parse bug must not be a way to lose a purchase: the record is left
  // alone rather than overwritten with an empty one.
  test('an unreadable record does not throw', () async {
    SharedPreferences.setMockInitialValues({
      'season_passes': 'not json at all',
    });

    final provider = await buildProvider();

    expect(provider.ownedPasses, isEmpty);
    expect(provider.claimedPassItemIds, isEmpty);
  });

  test('claiming a pass that is not owned does nothing', () async {
    final provider = await buildProvider();

    expect(await provider.claimPassTiers('season-1'), isEmpty);
  });
}
