/// Reads the pet's raw stats and says what, if anything, needs doing.
///
/// Two jobs, both of which the UI kept getting wrong by doing ad hoc:
///
/// 1. Deciding *whether to say anything at all*. The home screen shows a care
///    prompt only when there is something actionable, so a healthy pet stays
///    a pet rather than a dashboard.
/// 2. Translating internal stats into displayable ones. Hunger is stored
///    inverted — high is bad — while happiness and health are high-is-good.
///    Showing all three raw would give one bar the opposite meaning from its
///    neighbours, which people misread every time.
///
/// Pure, so the thresholds can be tuned and tested without a widget.
library;

/// A stat as the player sees it: always high-is-good.
enum CareStat { fullness, happiness, health }

/// How badly a stat needs attention.
enum CareSeverity {
  /// Nothing to say.
  fine,

  /// Worth a nudge, not an alarm.
  low,

  /// Actively costing the player something.
  critical,
}

/// One stat's displayable state.
class CareReading {
  const CareReading({
    required this.stat,
    required this.value,
    required this.severity,
  });

  final CareStat stat;

  /// 0-100, always oriented so higher is better.
  final int value;

  final CareSeverity severity;

  bool get needsAttention => severity != CareSeverity.fine;

  /// 0.0-1.0, for bar widths.
  double get fraction => (value / 100).clamp(0.0, 1.0);
}

class PetCareStatus {
  PetCareStatus._();

  // Mirrors CharacterProvider's own thresholds, restated here in display
  // orientation so the UI never has to reason about inverted hunger.

  /// Fullness at or below this is critical (hunger above 80).
  static const int criticalFullness = 20;

  /// Fullness at or below this is worth mentioning (hunger above 60).
  static const int lowFullness = 40;

  /// Happiness below this reads as sad, and the pet's sprite shows it.
  static const int criticalHappiness = 20;
  static const int lowHappiness = 30;

  /// Below this the pet is sick and every reward is halved.
  static const int criticalHealth = 30;
  static const int lowHealth = 50;

  /// Builds all three readings, in a fixed order so the panel never reshuffles
  /// under the player's finger.
  static List<CareReading> readings({
    required int hunger,
    required int happiness,
    required int health,
  }) {
    return [
      reading(CareStat.fullness, hunger: hunger, happiness: happiness, health: health),
      reading(CareStat.happiness, hunger: hunger, happiness: happiness, health: health),
      reading(CareStat.health, hunger: hunger, happiness: happiness, health: health),
    ];
  }

  static CareReading reading(
    CareStat stat, {
    required int hunger,
    required int happiness,
    required int health,
  }) {
    switch (stat) {
      case CareStat.fullness:
        // The inversion lives here and nowhere else.
        final value = (100 - hunger).clamp(0, 100);
        return CareReading(
          stat: stat,
          value: value,
          severity: _severity(value, criticalFullness, lowFullness),
        );
      case CareStat.happiness:
        final value = happiness.clamp(0, 100);
        return CareReading(
          stat: stat,
          value: value,
          severity: _severity(value, criticalHappiness, lowHappiness),
        );
      case CareStat.health:
        final value = health.clamp(0, 100);
        return CareReading(
          stat: stat,
          value: value,
          severity: _severity(value, criticalHealth, lowHealth),
        );
    }
  }

  static CareSeverity _severity(int value, int critical, int low) {
    if (value <= critical) return CareSeverity.critical;
    if (value <= low) return CareSeverity.low;
    return CareSeverity.fine;
  }

  /// The single thing most worth telling the player about, or null when the
  /// pet is fine.
  ///
  /// Health wins ties because low health is the only stat that actively taxes
  /// the player — every reward is halved while sick, so saying "Moji is a bit
  /// peckish" while that is happening would bury the expensive news.
  static CareReading? topConcern({
    required int hunger,
    required int happiness,
    required int health,
  }) {
    final all = readings(hunger: hunger, happiness: happiness, health: health)
        .where((r) => r.needsAttention)
        .toList();
    if (all.isEmpty) return null;

    all.sort((a, b) {
      final bySeverity = b.severity.index.compareTo(a.severity.index);
      if (bySeverity != 0) return bySeverity;
      return _priority(a.stat).compareTo(_priority(b.stat));
    });
    return all.first;
  }

  static int _priority(CareStat stat) {
    switch (stat) {
      case CareStat.health:
        return 0;
      case CareStat.fullness:
        return 1;
      case CareStat.happiness:
        return 2;
    }
  }

  /// True when anything at all needs doing.
  static bool needsCare({
    required int hunger,
    required int happiness,
    required int health,
  }) =>
      topConcern(hunger: hunger, happiness: happiness, health: health) != null;
}
