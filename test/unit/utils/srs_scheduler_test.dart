import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/utils/srs_scheduler.dart';

void main() {
  group('ReviewGrade', () {
    test('maps onto SM-2 quality scores', () {
      expect(ReviewGrade.again.quality, equals(1));
      expect(ReviewGrade.hard.quality, equals(3));
      expect(ReviewGrade.good.quality, equals(4));
      expect(ReviewGrade.easy.quality, equals(5));
    });

    test('only "again" counts as a lapse', () {
      expect(ReviewGrade.again.isLapse, isTrue);
      expect(ReviewGrade.hard.isLapse, isFalse);
      expect(ReviewGrade.good.isLapse, isFalse);
      expect(ReviewGrade.easy.isLapse, isFalse);
    });
  });

  group('SrsScheduler - interval growth', () {
    SrsOutcome first(ReviewGrade grade) => SrsScheduler.next(
          repetitions: 0,
          easeFactor: SrsScheduler.defaultEaseFactor,
          intervalDays: 0,
          grade: grade,
        );

    test('first successful review schedules one day out', () {
      final outcome = first(ReviewGrade.good);

      expect(outcome.repetitions, equals(1));
      expect(outcome.intervalDays, equals(1));
    });

    test('second successful review schedules six days out', () {
      final outcome = SrsScheduler.next(
        repetitions: 1,
        easeFactor: SrsScheduler.defaultEaseFactor,
        intervalDays: 1,
        grade: ReviewGrade.good,
      );

      expect(outcome.repetitions, equals(2));
      expect(outcome.intervalDays, equals(6));
    });

    test('third and later reviews multiply by ease', () {
      final outcome = SrsScheduler.next(
        repetitions: 2,
        easeFactor: 2.5,
        intervalDays: 6,
        grade: ReviewGrade.good,
      );

      // 6 * 2.5 (ease is unchanged by a "good" grade)
      expect(outcome.repetitions, equals(3));
      expect(outcome.intervalDays, equals(15));
    });

    test('intervals grow monotonically across a run of good reviews', () {
      var repetitions = 0;
      var ease = SrsScheduler.defaultEaseFactor;
      var interval = 0;
      var previousInterval = 0;

      for (var i = 0; i < 8; i++) {
        final outcome = SrsScheduler.next(
          repetitions: repetitions,
          easeFactor: ease,
          intervalDays: interval,
          grade: ReviewGrade.good,
        );
        repetitions = outcome.repetitions;
        ease = outcome.easeFactor;
        interval = outcome.intervalDays;

        expect(interval, greaterThanOrEqualTo(previousInterval));
        previousInterval = interval;
      }

      // Eight clean reviews should push the item well out of daily rotation.
      expect(interval, greaterThan(100));
    });

    test('intervals are capped so items never disappear for years', () {
      final outcome = SrsScheduler.next(
        repetitions: 12,
        easeFactor: 2.5,
        intervalDays: 300,
        grade: ReviewGrade.easy,
      );

      expect(outcome.intervalDays, equals(SrsScheduler.maxIntervalDays));
    });

    test('a corrupt zero interval cannot produce a stuck item', () {
      final outcome = SrsScheduler.next(
        repetitions: 5,
        easeFactor: 2.5,
        intervalDays: 0,
        grade: ReviewGrade.good,
      );

      expect(outcome.intervalDays, greaterThanOrEqualTo(1));
    });
  });

  group('SrsScheduler - lapses', () {
    test('forgetting resets repetitions and reschedules for tomorrow', () {
      final outcome = SrsScheduler.next(
        repetitions: 6,
        easeFactor: 2.5,
        intervalDays: 90,
        grade: ReviewGrade.again,
      );

      expect(outcome.repetitions, equals(0));
      expect(outcome.intervalDays, equals(1));
    });

    test('forgetting penalises ease, so a problem word returns sooner', () {
      final outcome = SrsScheduler.next(
        repetitions: 6,
        easeFactor: 2.5,
        intervalDays: 90,
        grade: ReviewGrade.again,
      );

      expect(outcome.easeFactor, lessThan(2.5));
      expect(outcome.easeFactor, closeTo(1.96, 0.001));
    });

    test('ease never falls below the SM-2 floor', () {
      var ease = SrsScheduler.defaultEaseFactor;

      // Forget the same item over and over.
      for (var i = 0; i < 20; i++) {
        ease = SrsScheduler.next(
          repetitions: 0,
          easeFactor: ease,
          intervalDays: 1,
          grade: ReviewGrade.again,
        ).easeFactor;
      }

      expect(ease, equals(SrsScheduler.minEaseFactor));
    });
  });

  group('SrsScheduler - ease adjustment', () {
    double easeAfter(ReviewGrade grade) => SrsScheduler.next(
          repetitions: 2,
          easeFactor: 2.5,
          intervalDays: 6,
          grade: grade,
        ).easeFactor;

    test('easy raises ease, good holds it, hard lowers it', () {
      expect(easeAfter(ReviewGrade.easy), greaterThan(2.5));
      expect(easeAfter(ReviewGrade.good), closeTo(2.5, 0.001));
      expect(easeAfter(ReviewGrade.hard), lessThan(2.5));
    });

    test('a struggled item is scheduled sooner than an effortless one', () {
      final hard = SrsScheduler.next(
        repetitions: 2,
        easeFactor: 2.5,
        intervalDays: 6,
        grade: ReviewGrade.hard,
      );
      final easy = SrsScheduler.next(
        repetitions: 2,
        easeFactor: 2.5,
        intervalDays: 6,
        grade: ReviewGrade.easy,
      );

      expect(hard.intervalDays, lessThan(easy.intervalDays));
    });
  });
}
