/// Pure bond arithmetic: what a learning event is worth, which stage a pet has
/// reached, and how far it is from the next one.
///
/// Kept out of [CharacterProvider] for the same reason [PetCareStatus] is —
/// the numbers are the part most likely to be tuned, and they should be
/// tunable and testable without a widget or a provider in the way.
library;

import '../constants/bond.dart';

/// Where the pet is on the stage ladder, and what the next step needs.
class BondStatus {
  const BondStatus({
    required this.stage,
    required this.bondPoints,
    required this.tier,
    required this.nextGate,
    required this.stageFloorPoints,
  });

  final PetStage stage;
  final int bondPoints;
  final FluencyTier tier;

  /// The gate that has not been met yet, or null at the final stage.
  final PetStageGate? nextGate;

  /// Bond cost of the stage currently held — the bottom of the progress bar.
  final int stageFloorPoints;

  bool get isFinalStage => nextGate == null;

  /// Bond still owed for the next stage, or 0 when bond is no longer what is
  /// holding the pet back.
  int get pointsToNextStage {
    final gate = nextGate;
    if (gate == null) return 0;
    final remaining = gate.bondPoints - bondPoints;
    return remaining > 0 ? remaining : 0;
  }

  /// True when the player has banked enough bond and it is their language
  /// that has to move next.
  ///
  /// Worth distinguishing in the UI: "20 more" and "your Spanish needs to
  /// reach intermediate" are different instructions, and showing a bar that
  /// sits full while nothing happens is how a player concludes the feature is
  /// broken.
  bool get isFluencyBlocked {
    final gate = nextGate;
    if (gate == null) return false;
    return bondPoints >= gate.bondPoints && tier.index < gate.minTier.index;
  }

  /// 0.0-1.0 across the current stage. Full and holding while fluency-blocked,
  /// which is accurate — the bond half of the requirement really is done.
  double get progress {
    final gate = nextGate;
    if (gate == null) return 1.0;
    final span = gate.bondPoints - stageFloorPoints;
    if (span <= 0) return 1.0;
    return ((bondPoints - stageFloorPoints) / span).clamp(0.0, 1.0);
  }
}

class BondProgress {
  BondProgress._();

  /// Maps whatever proficiency string is on hand onto the fluency ladder.
  ///
  /// Accepts both vocabularies in use: the stored beginner/intermediate/
  /// advanced values and the CEFR bands the assessment and quiz results speak
  /// in. Anything unrecognised reads as beginner, so a bad value can never
  /// hand out a stage the player has not earned.
  static FluencyTier tierFromLevel(String? level) {
    final value = level?.trim().toLowerCase();
    if (value == null || value.isEmpty) return FluencyTier.beginner;

    switch (value) {
      case 'advanced':
        return FluencyTier.advanced;
      case 'intermediate':
        return FluencyTier.intermediate;
      case 'beginner':
        return FluencyTier.beginner;
    }

    // CEFR bands: A* beginner, B* intermediate, C* advanced.
    switch (value[0]) {
      case 'c':
        return FluencyTier.advanced;
      case 'b':
        return FluencyTier.intermediate;
      default:
        return FluencyTier.beginner;
    }
  }

  /// Bond earned by finishing a quiz, scaled by accuracy.
  ///
  /// Never zero: a quiz the player got nothing right on is still a quiz they
  /// sat, and zeroing it would make the safest way to protect the bond not
  /// attempting anything hard.
  static int quizPoints({
    required int correctAnswers,
    required int totalQuestions,
  }) {
    if (totalQuestions <= 0) return BondConstants.quizBase;
    final accuracy = (correctAnswers / totalQuestions).clamp(0.0, 1.0);
    return BondConstants.quizBase +
        (BondConstants.quizAccuracyBonus * accuracy).round();
  }

  /// Bond earned by one unit of [source]. Quiz uses [quizPoints] instead,
  /// since its value depends on how it went.
  static int pointsFor(BondSource source) {
    switch (source) {
      case BondSource.conversation:
        return BondConstants.conversation;
      case BondSource.correction:
        return BondConstants.correction;
      case BondSource.scenario:
        return BondConstants.scenario;
      case BondSource.quiz:
        return BondConstants.quizBase;
    }
  }

  /// Walks the ladder in order and stops at the first gate not met.
  ///
  /// Stopping rather than scanning for the best match is deliberate: a player
  /// who is fluency-blocked at [PetStage.attached] must not skip to
  /// [PetStage.devoted] later just because they banked enough points to clear
  /// its (identical) tier requirement.
  static BondStatus statusFor({
    required int bondPoints,
    required FluencyTier tier,
  }) {
    var reached = petStageGates.first;

    for (var i = 1; i < petStageGates.length; i++) {
      final gate = petStageGates[i];
      final met =
          bondPoints >= gate.bondPoints && tier.index >= gate.minTier.index;
      if (!met) {
        return BondStatus(
          stage: reached.stage,
          bondPoints: bondPoints,
          tier: tier,
          nextGate: gate,
          stageFloorPoints: reached.bondPoints,
        );
      }
      reached = gate;
    }

    return BondStatus(
      stage: reached.stage,
      bondPoints: bondPoints,
      tier: tier,
      nextGate: null,
      stageFloorPoints: reached.bondPoints,
    );
  }

  /// How the pet reads the gap since the player last learned something.
  ///
  /// Null (nothing learned yet) is [PetWarmth.warm], not lonely — a brand-new
  /// player has not neglected anyone.
  static PetWarmth warmthFor(Duration? sinceLastLearning) {
    if (sinceLastLearning == null) return PetWarmth.warm;
    final days = sinceLastLearning.inDays;
    if (days >= BondConstants.lonelyAfterDays) return PetWarmth.lonely;
    if (days >= BondConstants.missingYouAfterDays) return PetWarmth.missingYou;
    return PetWarmth.warm;
  }
}
