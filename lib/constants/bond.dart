/// The bond axis: how close the pet has grown, and how long since the player
/// last showed up.
///
/// Bond used to be its own point ledger, earned from four learning events and
/// capped daily. It no longer is. Every event that paid bond also paid XP, at
/// the same call sites, within a line or two — bond was XP at a second
/// exchange rate, and two ledgers over one stream of events can only drift.
/// So the ladder below reads the player's level instead, and this file keeps
/// only what level cannot say: which rung the *pet* is on, and whether it has
/// been waiting.
///
/// The premise survives the merge because XP is already the learning ledger:
/// nothing in the app grants XP for feeding, petting, shopping or logging in.
/// Anything the player can buy still stays on the survival side of the line.
library;

class BondConstants {
  BondConstants._();

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

/// What a stage costs: a player level, and nothing else.
///
/// It also used to need a floor on the player's assessed fluency, so that
/// grinding could not carry a pet past the point where their language had to
/// move. That made the later stages — and the wardrobe pieces they unlock — a
/// reward for already being good at the language, which an active beginner
/// could never reach however much they played. The owner's rule since
/// 2026-09-18 is the opposite: activity is rewarded, language level never is.
/// Everyone climbs the same ladder at the same price, and XP is what they
/// climb it with.
class PetStageGate {
  const PetStageGate({
    required this.stage,
    required this.minLevel,
  });

  final PetStage stage;
  final int minLevel;
}

/// The stage ladder, in order. The first gate is the starting state and costs
/// nothing.
///
/// The levels are deliberately offset from the milestones every five levels
/// in `progression.dart`, so a stage-up is its own moment rather than a
/// footnote on a background unlock or a boss trial. They sit where they did
/// on the old 20-level ladder, scaled to the 30-level one (4/8/13/18 became
/// 6/12/19/27). Against the ~184 XP/day the XP curve is tuned for (see
/// [ProgressionConstants.growthRate]), they land at roughly two days, a week
/// and a half, four weeks and eight weeks.
const List<PetStageGate> petStageGates = [
  PetStageGate(stage: PetStage.curious, minLevel: 1),
  PetStageGate(stage: PetStage.friendly, minLevel: 6),
  PetStageGate(stage: PetStage.attached, minLevel: 12),
  PetStageGate(stage: PetStage.devoted, minLevel: 19),
  PetStageGate(stage: PetStage.inseparable, minLevel: 27),
];

/// How long it has been since the player last learned anything.
///
/// This is the softened failure state. It never touches the level, never
/// touches coins and never scales a reward — an absence costs the player
/// nothing but the pet saying it noticed, and the first learning event back
/// clears it. Absence in a language app is usually life getting in the way,
/// and charging for it is how people decide not to come back at all.
enum PetWarmth { warm, missingYou, lonely }
