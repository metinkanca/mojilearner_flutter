import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/bond.dart';
import 'package:mojilearner_flutter/utils/bond_progress.dart';
import 'package:mojilearner_flutter/utils/progression_utils.dart';

/// The XP at which [stage]'s level gate opens, off the real curve and gates,
/// so retuning either does not mean rewriting these tests.
int xpFor(PetStage stage) => ProgressionUtils.getTotalXPForLevel(
    petStageGates.firstWhere((g) => g.stage == stage).minLevel);

void main() {
  group('statusFor', () {
    final friendlyXP = xpFor(PetStage.friendly);
    final attachedXP = xpFor(PetStage.attached);
    final devotedXP = xpFor(PetStage.devoted);
    final inseparableXP = xpFor(PetStage.inseparable);

    test('a new pet starts curious', () {
      final status = BondProgress.statusFor(totalXP: 0);
      expect(status.stage, PetStage.curious);
      expect(status.level, 1);
      expect(status.nextGate?.stage, PetStage.friendly);
      expect(status.xpToNextStage, friendlyXP);
      expect(status.progress, 0.0);
      expect(status.isFinalStage, isFalse);
    });

    test('reaching a stage\'s level reaches the stage', () {
      final status = BondProgress.statusFor(totalXP: friendlyXP);
      expect(status.stage, PetStage.friendly);
      expect(status.level,
          petStageGates.firstWhere((g) => g.stage == PetStage.friendly).minLevel);
    });

    // Activity is what is rewarded, never how good someone already is at the
    // language: XP alone carries every player up the whole ladder.
    test('XP alone reaches every later stage', () {
      expect(BondProgress.statusFor(totalXP: attachedXP).stage,
          PetStage.attached);
      expect(BondProgress.statusFor(totalXP: devotedXP).stage,
          PetStage.devoted);
      expect(BondProgress.statusFor(totalXP: inseparableXP).stage,
          PetStage.inseparable);
    });

    test('one XP short of a stage is the stage before it', () {
      expect(BondProgress.statusFor(totalXP: attachedXP - 1).stage,
          PetStage.friendly);
      expect(BondProgress.statusFor(totalXP: inseparableXP - 1).stage,
          PetStage.devoted);
    });

    test('the final stage has nothing left to ask for', () {
      final status = BondProgress.statusFor(totalXP: 999999);
      expect(status.stage, PetStage.inseparable);
      expect(status.isFinalStage, isTrue);
      expect(status.nextGate, isNull);
      expect(status.progress, 1.0);
      expect(status.xpToNextStage, 0);
    });

    // The reason progress is measured in XP rather than whole levels: it has
    // to move within a session, not four times a year.
    test('progress measures across the current stage, not from zero', () {
      final status = BondProgress.statusFor(
        totalXP: friendlyXP + ((attachedXP - friendlyXP) ~/ 2),
      );
      expect(status.stage, PetStage.friendly);
      expect(status.progress, closeTo(0.5, 0.01));
    });

    test('progress moves on XP that has not yet earned a level', () {
      final before = BondProgress.statusFor(totalXP: friendlyXP + 10);
      // Still short of the next level: its step is at least baseXP.
      final after = BondProgress.statusFor(totalXP: friendlyXP + 25);
      expect(after.level, before.level);
      expect(after.progress, greaterThan(before.progress));
      expect(after.xpToNextStage, lessThan(before.xpToNextStage));
    });
  });

  group('warmthFor', () {
    // A player who has not started has not neglected anyone.
    test('never-learned reads as warm, not lonely', () {
      expect(BondProgress.warmthFor(null), PetWarmth.warm);
    });

    test('recent learning is warm', () {
      expect(BondProgress.warmthFor(Duration.zero), PetWarmth.warm);
      expect(
        BondProgress.warmthFor(const Duration(days: 1, hours: 23)),
        PetWarmth.warm,
      );
    });

    test('crosses to missing-you and then lonely', () {
      expect(
        BondProgress.warmthFor(const Duration(days: 2)),
        PetWarmth.missingYou,
      );
      expect(
        BondProgress.warmthFor(const Duration(days: 6, hours: 23)),
        PetWarmth.missingYou,
      );
      expect(BondProgress.warmthFor(const Duration(days: 7)), PetWarmth.lonely);
      expect(
          BondProgress.warmthFor(const Duration(days: 90)), PetWarmth.lonely);
    });
  });
}
