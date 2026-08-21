import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/bond.dart';
import 'package:mojilearner_flutter/utils/bond_progress.dart';

void main() {
  group('tierFromLevel', () {
    test('reads the stored beginner/intermediate/advanced values', () {
      expect(BondProgress.tierFromLevel('beginner'), FluencyTier.beginner);
      expect(
          BondProgress.tierFromLevel('intermediate'), FluencyTier.intermediate);
      expect(BondProgress.tierFromLevel('advanced'), FluencyTier.advanced);
    });

    test('reads the CEFR bands assessments speak in', () {
      expect(BondProgress.tierFromLevel('A1'), FluencyTier.beginner);
      expect(BondProgress.tierFromLevel('A2'), FluencyTier.beginner);
      expect(BondProgress.tierFromLevel('B1'), FluencyTier.intermediate);
      expect(BondProgress.tierFromLevel('B2'), FluencyTier.intermediate);
      expect(BondProgress.tierFromLevel('C1'), FluencyTier.advanced);
      expect(BondProgress.tierFromLevel('C2'), FluencyTier.advanced);
    });

    test('is case and whitespace insensitive', () {
      expect(BondProgress.tierFromLevel('  b2 '), FluencyTier.intermediate);
      expect(BondProgress.tierFromLevel('ADVANCED'), FluencyTier.advanced);
    });

    // A bad value must never hand out a stage the player has not earned.
    test('falls back to beginner for null, empty and junk', () {
      expect(BondProgress.tierFromLevel(null), FluencyTier.beginner);
      expect(BondProgress.tierFromLevel(''), FluencyTier.beginner);
      expect(BondProgress.tierFromLevel('fluent'), FluencyTier.beginner);
    });
  });

  group('quizPoints', () {
    test('scales with accuracy', () {
      expect(
        BondProgress.quizPoints(correctAnswers: 0, totalQuestions: 10),
        BondConstants.quizBase,
      );
      expect(
        BondProgress.quizPoints(correctAnswers: 10, totalQuestions: 10),
        BondConstants.quizBase + BondConstants.quizAccuracyBonus,
      );
      expect(
        BondProgress.quizPoints(correctAnswers: 5, totalQuestions: 10),
        BondConstants.quizBase + (BondConstants.quizAccuracyBonus / 2).round(),
      );
    });

    // Zeroing a failed quiz would make "attempt nothing hard" the safest way
    // to protect the bond.
    test('never pays zero, however badly it went', () {
      expect(
        BondProgress.quizPoints(correctAnswers: 0, totalQuestions: 20),
        greaterThan(0),
      );
      expect(
        BondProgress.quizPoints(correctAnswers: 0, totalQuestions: 0),
        greaterThan(0),
      );
    });
  });

  group('statusFor', () {
    test('a new pet starts curious', () {
      final status = BondProgress.statusFor(
        bondPoints: 0,
        tier: FluencyTier.beginner,
      );
      expect(status.stage, PetStage.curious);
      expect(status.nextGate?.stage, PetStage.friendly);
      expect(status.progress, 0.0);
      expect(status.isFinalStage, isFalse);
    });

    test('bond alone carries a beginner to friendly', () {
      final status = BondProgress.statusFor(
        bondPoints: 100,
        tier: FluencyTier.beginner,
      );
      expect(status.stage, PetStage.friendly);
    });

    // The whole point of the two-part gate: grinding cannot evolve the pet
    // past the point where the player's language has to move.
    test('a beginner cannot grind past friendly', () {
      final status = BondProgress.statusFor(
        bondPoints: 99999,
        tier: FluencyTier.beginner,
      );
      expect(status.stage, PetStage.friendly);
      expect(status.nextGate?.stage, PetStage.attached);
      expect(status.isFluencyBlocked, isTrue);
      expect(status.pointsToNextStage, 0);
      expect(status.progress, 1.0);
    });

    // ...and neither can fluency on its own.
    test('fluency cannot evolve a pet the player never bonded with', () {
      final status = BondProgress.statusFor(
        bondPoints: 0,
        tier: FluencyTier.advanced,
      );
      expect(status.stage, PetStage.curious);
      expect(status.isFluencyBlocked, isFalse);
      expect(status.pointsToNextStage, 100);
    });

    test('both together reach the later stages', () {
      expect(
        BondProgress.statusFor(
          bondPoints: 300,
          tier: FluencyTier.intermediate,
        ).stage,
        PetStage.attached,
      );
      expect(
        BondProgress.statusFor(
          bondPoints: 700,
          tier: FluencyTier.intermediate,
        ).stage,
        PetStage.devoted,
      );
      expect(
        BondProgress.statusFor(
          bondPoints: 1500,
          tier: FluencyTier.advanced,
        ).stage,
        PetStage.inseparable,
      );
    });

    // A player blocked at attached must not reappear at devoted later just
    // because devoted happens to share attached's tier requirement.
    test('a blocked gate is not skipped by a later one with the same tier', () {
      final status = BondProgress.statusFor(
        bondPoints: 700,
        tier: FluencyTier.beginner,
      );
      expect(status.stage, PetStage.friendly);
      expect(status.nextGate?.stage, PetStage.attached);
    });

    test('the final stage has nothing left to ask for', () {
      final status = BondProgress.statusFor(
        bondPoints: 99999,
        tier: FluencyTier.advanced,
      );
      expect(status.stage, PetStage.inseparable);
      expect(status.isFinalStage, isTrue);
      expect(status.nextGate, isNull);
      expect(status.progress, 1.0);
      expect(status.isFluencyBlocked, isFalse);
      expect(status.pointsToNextStage, 0);
    });

    test('progress measures across the current stage, not from zero', () {
      // Half way from friendly (100) to attached (300).
      final status = BondProgress.statusFor(
        bondPoints: 200,
        tier: FluencyTier.intermediate,
      );
      expect(status.stage, PetStage.friendly);
      expect(status.progress, closeTo(0.5, 0.001));
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
