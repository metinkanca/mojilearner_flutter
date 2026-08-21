/// The bond axis: the slow, permanent half of the pet relationship.
///
/// The survival stats (hunger/happiness/health) decay in hours and are bought
/// back with coins, so they only ever measure whether you opened the app and
/// could afford food. Bond measures whether you *learned*. It is earned from
/// learning events alone, and it is never taken away.
///
/// Feeding, petting, shopping and daily-login rewards deliberately pay nothing
/// here. The premise of the game is that the relationship grows through the
/// language, so anything the player can buy has to stay on the survival side
/// of the line or the premise stops being true.
library;

/// A kind of learning event that grows the bond.
///
/// Every member is something the player did *in the target language*. There is
/// deliberately no member for feeding, petting or purchases.
enum BondSource {
  /// One exchange with the pet in the target language.
  conversation,

  /// Finishing a quiz. Worth more the better it went — see
  /// [BondConstants.quizBase] and [BondConstants.quizAccuracyBonus].
  quiz,

  /// Reviewing an item the player previously got wrong. Worth the most per
  /// unit: acting on a correction is the event most likely to be actual
  /// learning rather than exposure.
  correction,

  /// Clearing a role-play scenario — the longest single stretch of target
  /// language the app asks for.
  scenario,
}

class BondConstants {
  BondConstants._();

  static const int conversation = 2;
  static const int correction = 3;
  static const int scenario = 8;

  /// A quiz always pays [quizBase], plus up to [quizAccuracyBonus] scaled by
  /// accuracy. Finishing a quiz badly still grows the bond a little — the pet
  /// cares that you showed up and tried, which is also what keeps a struggling
  /// learner in the app.
  static const int quizBase = 2;
  static const int quizAccuracyBonus = 6;

  /// Most bond a single day can pay, across all sources.
  ///
  /// Without a ceiling the fastest route to a grown pet is a long grinding
  /// session rather than a habit, which is the opposite of what a language app
  /// wants. Roughly two solid days of engaged study reach it; a normal session
  /// does not come close.
  static const int dailyCap = 40;

  /// Days of no learning before the pet reads as missing the player.
  static const int missingYouAfterDays = 2;

  /// Days of no learning before it reads as lonely — the strongest state
  /// there is. It costs the player nothing; see [PetWarmth].
  static const int lonelyAfterDays = 7;
}

/// How close the pet has grown. Ordered; index is meaningful.
///
/// These are relationship stages, not new artwork — the sprite is unchanged at
/// every stage. When per-stage art exists, [PetStage] is what selects it.
enum PetStage { curious, friendly, attached, devoted, inseparable }

/// The app stores proficiency as beginner/intermediate/advanced
/// ([LevelValidator]) while assessments talk in CEFR bands. This is the single
/// ordered ladder both map onto.
enum FluencyTier { beginner, intermediate, advanced }

/// What a stage costs: bond points *and* a floor on the player's fluency.
///
/// Both are required, which is the whole point. Bond alone would let a player
/// grind the pet to its final stage without their language moving; fluency
/// alone would evolve the pet off a single calibration and then never again.
class PetStageGate {
  const PetStageGate({
    required this.stage,
    required this.bondPoints,
    required this.minTier,
  });

  final PetStage stage;
  final int bondPoints;
  final FluencyTier minTier;
}

/// The stage ladder, in order. The first gate is the starting state and costs
/// nothing.
///
/// Point costs are set against [BondConstants.dailyCap]: friendly lands in
/// about a week of real use, attached about a month, and inseparable is a
/// season-long arc that no amount of grinding can shorten past the cap.
const List<PetStageGate> petStageGates = [
  PetStageGate(
    stage: PetStage.curious,
    bondPoints: 0,
    minTier: FluencyTier.beginner,
  ),
  PetStageGate(
    stage: PetStage.friendly,
    bondPoints: 100,
    minTier: FluencyTier.beginner,
  ),
  PetStageGate(
    stage: PetStage.attached,
    bondPoints: 300,
    minTier: FluencyTier.intermediate,
  ),
  PetStageGate(
    stage: PetStage.devoted,
    bondPoints: 700,
    minTier: FluencyTier.intermediate,
  ),
  PetStageGate(
    stage: PetStage.inseparable,
    bondPoints: 1500,
    minTier: FluencyTier.advanced,
  ),
];

/// How long it has been since the player last learned anything.
///
/// This is the softened failure state. It never touches bond, never touches
/// coins and never scales a reward — an absence costs the player nothing but
/// the pet saying it noticed, and the first learning event back clears it.
/// Absence in a language app is usually life getting in the way, and charging
/// for it is how people decide not to come back at all.
enum PetWarmth { warm, missingYou, lonely }
