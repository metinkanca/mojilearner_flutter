/// Pure bond arithmetic: which stage a pet has reached, and how far it is from
/// the next one.
///
/// Kept out of [CharacterProvider] for the same reason [PetCareStatus] is —
/// the numbers are the part most likely to be tuned, and they should be
/// tunable and testable without a widget or a provider in the way.
///
/// There is no longer any *earning* arithmetic here. Learning events pay XP
/// and only XP; see `constants/bond.dart` for why the second ledger went away.
library;

import '../constants/bond.dart';
import 'progression_utils.dart';

/// Where the pet is on the stage ladder, and what the next step needs.
class BondStatus {
  const BondStatus({
    required this.stage,
    required this.totalXP,
    required this.level,
    required this.nextGate,
    required this.stageFloorLevel,
  });

  final PetStage stage;

  /// The player's lifetime XP — the ledger the whole ladder now reads.
  final int totalXP;

  /// [totalXP] resolved to a level, carried so callers and the progress
  /// arithmetic below cannot disagree about which level that is.
  final int level;

  /// The gate that has not been met yet, or null at the final stage.
  final PetStageGate? nextGate;

  /// Level of the stage currently held — the bottom of the progress bar.
  final int stageFloorLevel;

  bool get isFinalStage => nextGate == null;

  /// XP still owed for the next stage, or 0 at the final one.
  ///
  /// Reported in XP rather than levels because XP is the number that moves
  /// every session. "Two levels to Attached" is true for a month at a time,
  /// which is how a player concludes nothing is happening.
  int get xpToNextStage {
    final gate = nextGate;
    if (gate == null) return 0;
    final remaining = ProgressionUtils.getTotalXPForLevel(gate.minLevel) -
        totalXP;
    return remaining > 0 ? remaining : 0;
  }

  /// 0.0-1.0 across the current stage, measured in XP rather than whole
  /// levels so the bar moves within a session.
  double get progress {
    final gate = nextGate;
    if (gate == null) return 1.0;
    final floor = ProgressionUtils.getTotalXPForLevel(stageFloorLevel);
    final ceiling = ProgressionUtils.getTotalXPForLevel(gate.minLevel);
    final span = ceiling - floor;
    if (span <= 0) return 1.0;
    return ((totalXP - floor) / span).clamp(0.0, 1.0);
  }
}

class BondProgress {
  BondProgress._();

  /// Walks the ladder in order and stops at the first gate not met.
  ///
  /// Only [totalXP] decides it — see [PetStageGate] for why the player's
  /// language level no longer does.
  static BondStatus statusFor({required int totalXP}) {
    final level = ProgressionUtils.getLevelFromTotalXP(totalXP);
    var reached = petStageGates.first;

    for (var i = 1; i < petStageGates.length; i++) {
      final gate = petStageGates[i];
      if (level < gate.minLevel) {
        return BondStatus(
          stage: reached.stage,
          totalXP: totalXP,
          level: level,
          nextGate: gate,
          stageFloorLevel: reached.minLevel,
        );
      }
      reached = gate;
    }

    return BondStatus(
      stage: reached.stage,
      totalXP: totalXP,
      level: level,
      nextGate: null,
      stageFloorLevel: reached.minLevel,
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
