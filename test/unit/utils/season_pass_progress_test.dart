import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/season_pass.dart';
import 'package:mojilearner_flutter/utils/season_pass_progress.dart';

/// The season pass, and specifically the three properties that make it *not* a
/// battle pass.
///
/// Buying late is never worse than buying early, nothing is lost by being
/// away, and a track already in hand cannot be taken back. Each of those is a
/// deliberate departure from the usual shape, so each gets a test — a version
/// of this that quietly measured progress against the calendar would pass a
/// naive "does it unlock tiers" test and be the wrong product.
void main() {
  const passId = 'season-test';

  // A local definition rather than the shipping catalogue, which is empty
  // until the art lands. What is under test is the arithmetic, not the drop.
  final pass = SeasonPassDef(
    id: passId,
    name: 'Test Season',
    productId: 'mimikin_pass_test',
    tiers: seasonPassTrack(const ['a', 'b', 'c']),
  );

  /// [SeasonPassProgress] resolves through the real catalogue, so these tests
  /// exercise [PassProgress] against the local definition directly.
  PassProgress progressOf(OwnedPass owned, int totalXP) {
    final since = totalXP - owned.xpAtPurchase;
    return PassProgress(
      pass: pass,
      owned: owned,
      xpSincePurchase: since > 0 ? since : 0,
    );
  }

  group('the track', () {
    test('spaces tiers evenly and knows what finishing costs', () {
      expect(pass.tiers, hasLength(3));
      expect(pass.tiers.first.xpFromPurchase, 500);
      expect(pass.tiers.last.xpFromPurchase, 1500);
      expect(pass.xpToComplete, 1500);
      expect(pass.accessoryIds, ['a', 'b', 'c']);
    });

    test('a fresh pass has reached nothing', () {
      expect(pass.reachedTierIndex(0), -1);
      expect(pass.reachedTierIndex(499), -1);
    });

    test('tiers are reached in order as XP accumulates', () {
      expect(pass.reachedTierIndex(500), 0);
      expect(pass.reachedTierIndex(1499), 1);
      expect(pass.reachedTierIndex(1500), 2);
      expect(pass.reachedTierIndex(999999), 2);
    });
  });

  // The property the whole design turns on. A pass bought on the last day of a
  // season has to be worth what one bought on the first day was.
  group('buying late costs nothing', () {
    test('progress is measured from the purchase, not from a total', () {
      const earlyBuyer = OwnedPass(passId: passId, xpAtPurchase: 0);
      const lateBuyer = OwnedPass(passId: passId, xpAtPurchase: 40000);

      // Each has earned 700 XP since buying.
      expect(progressOf(earlyBuyer, 700).reachedTierIndex, 0);
      expect(progressOf(lateBuyer, 40700).reachedTierIndex, 0);
    });

    // ...and the mirror of it: a long-time player with a big balance must not
    // unlock the whole track the instant they pay.
    test('a large existing balance unlocks nothing on its own', () {
      const owned = OwnedPass(passId: passId, xpAtPurchase: 50000);

      expect(progressOf(owned, 50000).reachedTierIndex, -1);
      expect(progressOf(owned, 50000).hasClaimable, isFalse);
    });
  });

  group('claiming', () {
    test('a reached tier waits to be taken', () {
      const owned = OwnedPass(passId: passId, xpAtPurchase: 0);
      final progress = progressOf(owned, 1100);

      expect(progress.reachedTierIndex, 1);
      expect(progress.claimableTierIndexes, [0, 1]);
      expect(progress.hasClaimable, isTrue);
    });

    test('what has been claimed is not offered again', () {
      const owned = OwnedPass(
        passId: passId,
        xpAtPurchase: 0,
        claimedThroughTier: 0,
      );

      expect(progressOf(owned, 1100).claimableTierIndexes, [1]);
    });

    // The whole point of no expiry: coming back after a long gap finds the
    // track waiting rather than gone.
    test('a long absence leaves everything still claimable', () {
      const owned = OwnedPass(passId: passId, xpAtPurchase: 0);
      final progress = progressOf(owned, 1500);

      expect(progress.claimableTierIndexes, [0, 1, 2]);
      expect(progress.isComplete, isFalse);
    });

    test('a finished track has nothing left to give', () {
      const owned = OwnedPass(
        passId: passId,
        xpAtPurchase: 0,
        claimedThroughTier: 2,
      );
      final progress = progressOf(owned, 999999);

      expect(progress.isComplete, isTrue);
      expect(progress.hasClaimable, isFalse);
      expect(progress.xpToNextTier, 0);
      expect(progress.tierProgress, 1.0);
    });
  });

  group('the bar', () {
    test('counts down XP to the next tier', () {
      const owned = OwnedPass(passId: passId, xpAtPurchase: 0);

      expect(progressOf(owned, 0).xpToNextTier, 500);
      expect(progressOf(owned, 200).xpToNextTier, 300);
      // Tier 0 (500) is behind them, so the countdown is to tier 1 at 1000.
      expect(progressOf(owned, 600).xpToNextTier, 400);
    });

    // Measured in XP rather than whole tiers so it moves every session, the
    // same reason the bond bar is.
    test('moves within a tier', () {
      const owned = OwnedPass(passId: passId, xpAtPurchase: 0);

      expect(progressOf(owned, 0).tierProgress, 0.0);
      expect(progressOf(owned, 250).tierProgress, closeTo(0.5, 0.001));
      expect(progressOf(owned, 750).tierProgress, closeTo(0.5, 0.001));
    });

    // A total that has somehow gone backwards reads as no progress, never as
    // a debt the player has to earn their way out of.
    test('an XP total below the baseline is not negative progress', () {
      const owned = OwnedPass(passId: passId, xpAtPurchase: 1000);
      final progress = progressOf(owned, 400);

      expect(progress.xpSincePurchase, 0);
      expect(progress.reachedTierIndex, -1);
      expect(progress.tierProgress, 0.0);
    });
  });

  group('the catalogue lookup', () {
    test('an unknown pass id resolves to nothing rather than throwing', () {
      const owned = OwnedPass(passId: 'never-existed', xpAtPurchase: 0);

      expect(SeasonPassProgress.progressFor(owned, totalXP: 5000), isNull);
      expect(SeasonPassProgress.claimedAccessoryIds([owned]), isEmpty);
      expect(seasonPassById('never-existed'), isNull);
      expect(seasonPassById(null), isNull);
    });
  });
}
