/// Chooses which review items are worth putting in front of the model.
///
/// The prose that wraps these lives in `server/src/prompts.js` now, but the
/// choosing cannot: it needs the learner's queue, which only the app has. So
/// the split is that this side decides *which* items go, and the server
/// decides how they read.
///
/// Both sides cap. This one caps because a brief that is re-sent on every
/// turn has to stay small enough not to crowd out the format rules above it;
/// the server caps because a caller that skips the app entirely must not be
/// able to send four hundred items. The numbers agree, and neither depends on
/// the other being right.
library;

import '../models/models.dart';
import '../services/ai_prompt_spec.dart';

/// The trimmed queue, plus the ids the model may legitimately cite back.
class BriefedReview {
  const BriefedReview({required this.trouble, required this.due});

  /// Items the learner keeps forgetting. Prioritised in the prompt.
  final List<AiReviewItem> trouble;

  /// Items merely due, minus anything already listed as a trouble spot.
  final List<AiReviewItem> due;

  bool get isEmpty => trouble.isEmpty && due.isEmpty;

  /// Every id the model was actually shown, in the order it saw them.
  ///
  /// The quiz parser whitelists returned ids against this, so a hallucinated
  /// id cannot reschedule an unrelated item.
  Set<String> get offeredIds =>
      {...trouble.map((i) => i.id), ...due.map((i) => i.id)};
}

class ReviewSelection {
  ReviewSelection._();

  /// Caps on how much of the queue reaches a prompt.
  static const int maxTroubleSpots = 5;
  static const int maxDueItems = 8;

  /// Trims and de-duplicates the two lists.
  ///
  /// [troubleSpots] takes precedence: an item that is both overdue and
  /// repeatedly forgotten is sent once, as a trouble spot. De-duplication is
  /// by [ReviewItem.key] rather than by id, because the same word learned
  /// twice is two records of one thing.
  static BriefedReview select({
    required List<ReviewItem> troubleSpots,
    required List<ReviewItem> dueItems,
  }) {
    final trouble = troubleSpots.take(maxTroubleSpots).toList();
    final troubleKeys = trouble.map((item) => item.key).toSet();
    final due = dueItems
        .where((item) => !troubleKeys.contains(item.key))
        .take(maxDueItems)
        .toList();

    return BriefedReview(
      trouble: trouble.map(AiReviewItem.from).toList(),
      due: due.map(AiReviewItem.from).toList(),
    );
  }
}
