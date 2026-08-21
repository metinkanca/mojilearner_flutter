import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/utils/notification_planner.dart';

/// Mid-afternoon, comfortably outside quiet hours, so tests that aren't about
/// the quiet window aren't perturbed by it.
final DateTime midday = DateTime(2026, 5, 10, 14);

List<PlannedNotification> plan({
  DateTime? now,
  int hunger = 50,
  int happiness = 70,
  DateTime? nextReviewDueAt,
  int dueReviewCount = 0,
  bool dailyRewardAvailable = false,
  DateTime? nextDailyRewardAt,
}) {
  return NotificationPlanner.plan(
    now: now ?? midday,
    hunger: hunger,
    happiness: happiness,
    nextReviewDueAt: nextReviewDueAt,
    dueReviewCount: dueReviewCount,
    dailyRewardAvailable: dailyRewardAvailable,
    nextDailyRewardAt: nextDailyRewardAt,
  );
}

PlannedNotification? kind(
  List<PlannedNotification> planned,
  NotificationKind wanted,
) {
  for (final entry in planned) {
    if (entry.kind == wanted) return entry;
  }
  return null;
}

void main() {
  group('NotificationPlanner - pet care timing', () {
    test('fires when hunger is projected to cross into starving', () {
      // hunger 65, +3/hr, critical at 80 → 5 hours.
      final pet = kind(plan(hunger: 65, happiness: 100),
          NotificationKind.petNeedsCare)!;

      expect(pet.fireAt, equals(midday.add(const Duration(hours: 5))));
    });

    test('fires when happiness is projected to cross into sad', () {
      // happiness 42, -2/hr, low at 30 → 6 hours. Hunger kept far away.
      final pet =
          kind(plan(hunger: 0, happiness: 42), NotificationKind.petNeedsCare)!;

      expect(pet.fireAt, equals(midday.add(const Duration(hours: 6))));
    });

    test('uses whichever need arrives first', () {
      // Hunger in 10h vs happiness in 5h.
      final pet = kind(plan(hunger: 50, happiness: 40),
          NotificationKind.petNeedsCare)!;

      expect(pet.fireAt, equals(midday.add(const Duration(hours: 5))));
    });

    test('an already-neglected pet still waits out the minimum delay', () {
      // Both stats already past their thresholds: without a floor this would
      // fire the instant the app is backgrounded.
      final pet = kind(plan(hunger: 95, happiness: 5),
          NotificationKind.petNeedsCare)!;

      expect(pet.fireAt,
          equals(midday.add(NotificationPlanner.minimumPetDelay)));
    });

    test('a perfectly-tended pet is capped at the maximum delay', () {
      // Hunger alone would put this ~27 hours out; the cap pulls it back so
      // the reminder does not drift later each day.
      final pet = kind(plan(hunger: 0, happiness: 100),
          NotificationKind.petNeedsCare)!;

      expect(pet.fireAt,
          equals(midday.add(NotificationPlanner.maximumPetDelay)));
    });

    test('no pet reminder is ever scheduled beyond the cap', () {
      for (var hunger = 0; hunger <= 100; hunger += 10) {
        for (var happiness = 0; happiness <= 100; happiness += 10) {
          final pet = kind(plan(hunger: hunger, happiness: happiness),
              NotificationKind.petNeedsCare)!;

          // Quiet-hour shifts can push past the raw cap, but never by more
          // than one night.
          expect(
            pet.fireAt.difference(midday),
            lessThanOrEqualTo(
                NotificationPlanner.maximumPetDelay + const Duration(hours: 24)),
            reason: 'hunger $hunger / happiness $happiness',
          );
        }
      }
    });
  });

  group('NotificationPlanner - quiet hours', () {
    test('a late-evening time rolls to the next morning', () {
      final shifted = NotificationPlanner.shiftOutOfQuietHours(
          DateTime(2026, 5, 10, 23, 30));

      expect(shifted,
          equals(DateTime(2026, 5, 11, NotificationPlanner.quietEndHour)));
    });

    test('a small-hours time moves up to the same morning', () {
      final shifted = NotificationPlanner.shiftOutOfQuietHours(
          DateTime(2026, 5, 10, 3, 15));

      expect(shifted,
          equals(DateTime(2026, 5, 10, NotificationPlanner.quietEndHour)));
    });

    test('a daylight time is left alone', () {
      final moment = DateTime(2026, 5, 10, 14, 37);

      expect(NotificationPlanner.shiftOutOfQuietHours(moment), equals(moment));
    });

    test('the boundaries themselves are handled consistently', () {
      expect(NotificationPlanner.isQuiet(DateTime(2026, 5, 10, 22)), isTrue);
      expect(NotificationPlanner.isQuiet(DateTime(2026, 5, 10, 21, 59)),
          isFalse);
      expect(
        NotificationPlanner.isQuiet(
            DateTime(2026, 5, 10, NotificationPlanner.quietEndHour)),
        isFalse,
      );
      expect(
        NotificationPlanner.isQuiet(
            DateTime(2026, 5, 10, NotificationPlanner.quietEndHour - 1)),
        isTrue,
      );
    });

    test('no planned notification ever lands inside quiet hours', () {
      // Sweep every start hour, with a pet due to need care almost at once.
      for (var hour = 0; hour < 24; hour++) {
        final now = DateTime(2026, 5, 10, hour);
        final planned = plan(
          now: now,
          hunger: 95,
          happiness: 5,
          dueReviewCount: 4,
          nextReviewDueAt: now,
          nextDailyRewardAt: now.add(const Duration(hours: 6)),
        );

        expect(planned, isNotEmpty, reason: 'nothing planned at hour $hour');
        for (final entry in planned) {
          expect(NotificationPlanner.isQuiet(entry.fireAt), isFalse,
              reason: '${entry.kind} fired at ${entry.fireAt} (start $hour)');
        }
      }
    });
  });

  group('NotificationPlanner - reviews', () {
    test('says nothing when the learner has no items at all', () {
      expect(kind(plan(), NotificationKind.reviewDue), isNull);
    });

    test('waits out the grace period on an already-full queue', () {
      final review = kind(
        plan(dueReviewCount: 6, nextReviewDueAt: midday.subtract(
            const Duration(days: 1))),
        NotificationKind.reviewDue,
      )!;

      expect(review.fireAt,
          equals(midday.add(NotificationPlanner.reviewGrace)));
    });

    test('schedules from the due time when nothing is due yet', () {
      // Chosen so the grace period still lands in daylight.
      final due = midday.add(const Duration(hours: 2));
      final review = kind(
        plan(dueReviewCount: 0, nextReviewDueAt: due),
        NotificationKind.reviewDue,
      )!;

      expect(review.fireAt, equals(due.add(NotificationPlanner.reviewGrace)));
    });

    test('never schedules in the past for an overdue-but-uncounted item', () {
      final review = kind(
        plan(
          dueReviewCount: 0,
          nextReviewDueAt: midday.subtract(const Duration(days: 3)),
        ),
        NotificationKind.reviewDue,
      )!;

      expect(review.fireAt.isAfter(midday), isTrue);
    });
  });

  group('NotificationPlanner - daily reward', () {
    test('says nothing when the reward is already claimable', () {
      final planned = plan(
        dailyRewardAvailable: true,
        nextDailyRewardAt: midday.add(const Duration(hours: 10)),
      );

      expect(kind(planned, NotificationKind.dailyReward), isNull);
    });

    test('schedules for the next reset', () {
      final next = DateTime(2026, 5, 11, 9);
      final reward = kind(
        plan(nextDailyRewardAt: next),
        NotificationKind.dailyReward,
      )!;

      expect(reward.fireAt, equals(next));
    });

    test('pushes a midnight reset into the morning', () {
      final midnight = DateTime(2026, 5, 11);
      final reward = kind(
        plan(nextDailyRewardAt: midnight),
        NotificationKind.dailyReward,
      )!;

      expect(reward.fireAt,
          equals(DateTime(2026, 5, 11, NotificationPlanner.quietEndHour)));
    });

    test('ignores a reset time already in the past', () {
      final planned =
          plan(nextDailyRewardAt: midday.subtract(const Duration(hours: 2)));

      expect(kind(planned, NotificationKind.dailyReward), isNull);
    });
  });

  group('NotificationPlanner - plan composition', () {
    test('a brand-new player only hears about the pet', () {
      final planned = plan(dailyRewardAvailable: true);

      expect(planned.map((p) => p.kind),
          equals([NotificationKind.petNeedsCare]));
    });

    test('an established player can get all three', () {
      final planned = plan(
        dueReviewCount: 5,
        nextReviewDueAt: midday,
        nextDailyRewardAt: DateTime(2026, 5, 11, 9),
      );

      expect(planned, hasLength(3));
    });

    test('each kind has a distinct, stable notification id', () {
      final ids = NotificationKind.values.map((k) => k.id).toList();

      expect(ids.toSet(), hasLength(ids.length));
      expect(NotificationKind.petNeedsCare.id, equals(1001));
      expect(NotificationKind.reviewDue.id, equals(1002));
      expect(NotificationKind.dailyReward.id, equals(1003));
    });

    test('every planned notification is in the future', () {
      final planned = plan(
        hunger: 100,
        happiness: 0,
        dueReviewCount: 9,
        nextReviewDueAt: midday.subtract(const Duration(days: 5)),
        nextDailyRewardAt: midday.add(const Duration(minutes: 30)),
      );

      for (final entry in planned) {
        expect(entry.fireAt.isAfter(midday), isTrue,
            reason: '${entry.kind} was scheduled in the past');
      }
    });
  });
}
