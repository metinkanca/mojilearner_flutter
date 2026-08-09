/// Spaced-repetition scheduling (SM-2).
///
/// Pure math, deliberately free of models and storage so the review curve can
/// be tuned and tested on its own — the same split as [ProgressionUtils].
library;

/// How well the learner recalled an item. Maps onto SM-2's 0-5 quality scale.
enum ReviewGrade {
  /// Couldn't recall it. Resets the item's progress.
  again,

  /// Recalled, but with real effort.
  hard,

  /// Recalled correctly.
  good,

  /// Recalled instantly.
  easy,
}

extension ReviewGradeQuality on ReviewGrade {
  /// SM-2 quality score. Anything below 3 counts as a failed recall.
  int get quality {
    switch (this) {
      case ReviewGrade.again:
        return 1;
      case ReviewGrade.hard:
        return 3;
      case ReviewGrade.good:
        return 4;
      case ReviewGrade.easy:
        return 5;
    }
  }

  bool get isLapse => quality < 3;
}

/// The scheduling state produced by a review.
class SrsOutcome {
  /// Consecutive successful recalls. Reset to 0 by a lapse.
  final int repetitions;

  /// SM-2 ease factor — how fast this item's intervals grow.
  final double easeFactor;

  /// Days until the item comes up again.
  final int intervalDays;

  const SrsOutcome({
    required this.repetitions,
    required this.easeFactor,
    required this.intervalDays,
  });
}

class SrsScheduler {
  SrsScheduler._();

  /// SM-2's floor. Below this, intervals stop growing meaningfully and the
  /// item would be shown forever.
  static const double minEaseFactor = 1.3;

  /// Ease a brand-new item starts at.
  static const double defaultEaseFactor = 2.5;

  /// First interval after a successful recall.
  static const int firstIntervalDays = 1;

  /// Second interval — SM-2's fixed step before ease takes over.
  static const int secondIntervalDays = 6;

  /// Intervals are capped so a casual learner never loses an item into a
  /// multi-year gap. A year is long enough to count as learned.
  static const int maxIntervalDays = 365;

  /// Applies one review to an item's scheduling state.
  ///
  /// A lapse (grade [ReviewGrade.again]) resets the repetition count and puts
  /// the item back tomorrow, but keeps the ease penalty so a repeatedly
  /// forgotten item keeps coming back sooner than a well-known one.
  static SrsOutcome next({
    required int repetitions,
    required double easeFactor,
    required int intervalDays,
    required ReviewGrade grade,
  }) {
    final quality = grade.quality;
    final updatedEase = _nextEaseFactor(easeFactor, quality);

    if (grade.isLapse) {
      return SrsOutcome(
        repetitions: 0,
        easeFactor: updatedEase,
        intervalDays: firstIntervalDays,
      );
    }

    final nextRepetitions = repetitions + 1;
    final int nextInterval;
    if (nextRepetitions == 1) {
      nextInterval = firstIntervalDays;
    } else if (nextRepetitions == 2) {
      nextInterval = secondIntervalDays;
    } else {
      // Guard against a zero/negative stored interval producing a stuck item.
      final previous = intervalDays < firstIntervalDays
          ? firstIntervalDays
          : intervalDays;
      nextInterval = (previous * updatedEase).round();
    }

    return SrsOutcome(
      repetitions: nextRepetitions,
      easeFactor: updatedEase,
      intervalDays: nextInterval.clamp(firstIntervalDays, maxIntervalDays),
    );
  }

  /// SM-2 ease update: rewards effortless recall, penalises struggle, and
  /// never falls below [minEaseFactor].
  static double _nextEaseFactor(double current, int quality) {
    final delta = 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02);
    final updated = current + delta;
    return updated < minEaseFactor ? minEaseFactor : updated;
  }
}
