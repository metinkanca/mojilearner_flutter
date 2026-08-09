/// Decides what the app should notify about, and when.
///
/// Pure date math over the pet's decay curve and the review queue, so the
/// nag schedule can be tuned and tested without a plugin, a device, or a
/// clock — the same split as [SrsScheduler] and [ProgressionUtils].
///
/// The whole design rests on one rule: a pet game earns its return visits by
/// being missed, not by being loud. Everything here is about firing rarely
/// and at a defensible moment.
library;

/// What a scheduled notification is about. Doubles as its plugin id, so a
/// reschedule replaces the previous one of the same kind instead of stacking.
enum NotificationKind {
  /// The pet has become hungry or unhappy enough to need attention.
  petNeedsCare,

  /// Review items have come due.
  reviewDue,

  /// The daily reward is claimable again.
  dailyReward,
}

extension NotificationKindId on NotificationKind {
  /// Stable plugin notification id. Fixed per kind so scheduling the same
  /// kind twice overwrites rather than duplicates.
  int get id {
    switch (this) {
      case NotificationKind.petNeedsCare:
        return 1001;
      case NotificationKind.reviewDue:
        return 1002;
      case NotificationKind.dailyReward:
        return 1003;
    }
  }
}

/// One notification the service should schedule.
class PlannedNotification {
  const PlannedNotification({required this.kind, required this.fireAt});

  final NotificationKind kind;
  final DateTime fireAt;

  int get id => kind.id;

  @override
  String toString() => 'PlannedNotification($kind at $fireAt)';
}

class NotificationPlanner {
  NotificationPlanner._();

  // ---- Quiet hours ----
  //
  // Mirrors the pet's own sleep window in CharacterProvider. A "Moji is
  // hungry" at 3am is how an app gets uninstalled, and it would be lying
  // anyway — the pet is asleep.

  /// Notifications never fire at or after this hour...
  static const int quietStartHour = 22;

  /// ...and never before this one. Anything landing in the gap is pushed to
  /// [quietEndHour] the same morning.
  static const int quietEndHour = 8;

  // ---- Pet decay, mirrored from CharacterProvider ----
  static const int hungerGainPerHour = 3;
  static const int happinessLossPerHour = 2;

  /// Hunger above this reads as starving.
  static const int criticalHunger = 80;

  /// Happiness below this reads as sad.
  static const int lowHappiness = 30;

  /// Never nag about the pet sooner than this. Without a floor, a player who
  /// closes the app with an already-hungry pet gets pinged immediately, which
  /// feels like surveillance rather than a reminder.
  static const Duration minimumPetDelay = Duration(hours: 2);

  /// Nor later than this. A perfectly-fed pet would otherwise not be
  /// mentioned for ~27 hours (hunger 0 climbing 3/hr to 80), which drifts the
  /// reminder a little later every day until it lands at an hour the player
  /// never opens the app. Capping at a day keeps it anchored.
  static const Duration maximumPetDelay = Duration(hours: 24);

  /// How long after items fall due to wait before mentioning reviews. Long
  /// enough that a learner who is mid-session isn't interrupted by a reminder
  /// about the thing they are already doing.
  static const Duration reviewGrace = Duration(hours: 3);

  /// Builds the full schedule. Only kinds with something to say appear.
  ///
  /// [now] is injectable so the whole plan is testable.
  static List<PlannedNotification> plan({
    required DateTime now,
    required int hunger,
    required int happiness,
    required DateTime? nextReviewDueAt,
    required int dueReviewCount,
    required bool dailyRewardAvailable,
    required DateTime? nextDailyRewardAt,
  }) {
    final planned = <PlannedNotification>[];

    final pet = _planPetCare(now: now, hunger: hunger, happiness: happiness);
    if (pet != null) planned.add(pet);

    final review = _planReview(
      now: now,
      nextReviewDueAt: nextReviewDueAt,
      dueReviewCount: dueReviewCount,
    );
    if (review != null) planned.add(review);

    final reward = _planDailyReward(
      now: now,
      dailyRewardAvailable: dailyRewardAvailable,
      nextDailyRewardAt: nextDailyRewardAt,
    );
    if (reward != null) planned.add(reward);

    return planned;
  }

  /// When the pet will next cross into needing attention.
  ///
  /// Uses whichever of hunger or happiness degrades first, clamped into the
  /// [minimumPetDelay]..[maximumPetDelay] window and pushed clear of quiet
  /// hours.
  static PlannedNotification? _planPetCare({
    required DateTime now,
    required int hunger,
    required int happiness,
  }) {
    final hoursToStarving = _hoursUntil(
      current: hunger,
      threshold: criticalHunger,
      ratePerHour: hungerGainPerHour,
      rising: true,
    );
    final hoursToSad = _hoursUntil(
      current: happiness,
      threshold: lowHappiness,
      ratePerHour: happinessLossPerHour,
      rising: false,
    );

    final hours = [hoursToStarving, hoursToSad].reduce((a, b) => a < b ? a : b);

    var fireAt = now.add(Duration(minutes: (hours * 60).round()));

    // Clamp before the quiet-hour shift, so the floor can't be swallowed by a
    // push into the morning and the ceiling still bounds the final time.
    final earliest = now.add(minimumPetDelay);
    final latest = now.add(maximumPetDelay);
    if (fireAt.isBefore(earliest)) fireAt = earliest;
    if (fireAt.isAfter(latest)) fireAt = latest;

    return PlannedNotification(
      kind: NotificationKind.petNeedsCare,
      fireAt: shiftOutOfQuietHours(fireAt),
    );
  }

  static PlannedNotification? _planReview({
    required DateTime now,
    required DateTime? nextReviewDueAt,
    required int dueReviewCount,
  }) {
    // Nothing learned yet, nothing to remind about.
    if (nextReviewDueAt == null && dueReviewCount == 0) return null;

    // Already overdue: the grace period starts now, not retroactively, so
    // closing the app on a full queue doesn't ping instantly.
    final base = dueReviewCount > 0
        ? now
        : (nextReviewDueAt!.isBefore(now) ? now : nextReviewDueAt);

    return PlannedNotification(
      kind: NotificationKind.reviewDue,
      fireAt: shiftOutOfQuietHours(base.add(reviewGrace)),
    );
  }

  static PlannedNotification? _planDailyReward({
    required DateTime now,
    required bool dailyRewardAvailable,
    required DateTime? nextDailyRewardAt,
  }) {
    // Claimable right now: no point scheduling: the player is holding the
    // phone. The reminder is for the next one.
    if (dailyRewardAvailable) return null;
    if (nextDailyRewardAt == null) return null;
    if (!nextDailyRewardAt.isAfter(now)) return null;

    return PlannedNotification(
      kind: NotificationKind.dailyReward,
      fireAt: shiftOutOfQuietHours(nextDailyRewardAt),
    );
  }

  /// Hours until [current] reaches [threshold] at [ratePerHour].
  ///
  /// Returns 0 when already past it, and [double.infinity] when the rate is
  /// zero, so a stat that never moves simply loses the race in [plan].
  static double _hoursUntil({
    required int current,
    required int threshold,
    required int ratePerHour,
    required bool rising,
  }) {
    if (ratePerHour <= 0) return double.infinity;

    final gap = rising ? threshold - current : current - threshold;
    if (gap <= 0) return 0;

    return gap / ratePerHour;
  }

  /// Moves [moment] out of the quiet window.
  ///
  /// Late-evening times roll to the next morning; small-hours times move up to
  /// the same morning. Anything already in daylight is returned untouched.
  static DateTime shiftOutOfQuietHours(DateTime moment) {
    if (!isQuiet(moment)) return moment;

    // Before the morning boundary: same calendar day.
    if (moment.hour < quietEndHour) {
      return DateTime(
          moment.year, moment.month, moment.day, quietEndHour);
    }

    // At or after the evening boundary: tomorrow morning.
    final tomorrow = DateTime(moment.year, moment.month, moment.day)
        .add(const Duration(days: 1));
    return DateTime(
        tomorrow.year, tomorrow.month, tomorrow.day, quietEndHour);
  }

  static bool isQuiet(DateTime moment) =>
      moment.hour >= quietStartHour || moment.hour < quietEndHour;
}
