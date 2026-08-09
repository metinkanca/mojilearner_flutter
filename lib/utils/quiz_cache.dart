/// Decides when a generated quiz may be reused instead of re-requested.
///
/// Without this, opening the quiz screen costs an API call every time —
/// including the bounce-in-and-out case, which multiplies spend by however
/// many times someone taps the tab. A generated set stays valid for the rest
/// of the day *and* only while the learner's state hasn't moved.
///
/// Pure, so the invalidation rules can be tested without storage or a clock.
library;

import 'dart:convert';

import '../models/models.dart';
import 'srs_quiz_builder.dart';

/// A generated quiz plus the conditions under which it may be reused.
class CachedQuiz {
  const CachedQuiz({
    required this.languageCode,
    required this.fingerprint,
    required this.generatedAt,
    required this.questions,
  });

  final String languageCode;

  /// Digest of the learner state the quiz was built from. Any change and the
  /// cached set no longer reflects what they need to practise.
  final String fingerprint;

  final DateTime generatedAt;
  final List<QuizQuestion> questions;

  Map<String, dynamic> toJson() => {
        'languageCode': languageCode,
        'fingerprint': fingerprint,
        'generatedAt': generatedAt.toIso8601String(),
        'questions': questions.map(QuizCache.questionToJson).toList(),
      };

  static CachedQuiz? fromJson(Map<String, dynamic> json) {
    final generatedAt =
        DateTime.tryParse(json['generatedAt'] as String? ?? '');
    final rawQuestions = json['questions'];
    if (generatedAt == null || rawQuestions is! List) return null;

    final questions = <QuizQuestion>[];
    for (final raw in rawQuestions) {
      if (raw is! Map) continue;
      final question = QuizCache.questionFromJson(
          Map<String, dynamic>.from(raw));
      if (question != null) questions.add(question);
    }
    if (questions.isEmpty) return null;

    return CachedQuiz(
      languageCode: json['languageCode'] as String? ?? '',
      fingerprint: json['fingerprint'] as String? ?? '',
      generatedAt: generatedAt,
      questions: questions,
    );
  }
}

class QuizCache {
  QuizCache._();

  /// Summarises the learner state a quiz was generated for.
  ///
  /// Deliberately built from the *ids* offered to the model plus the level,
  /// because those are exactly the inputs [QuizBriefing] uses. Grading an
  /// item changes which items are due, which changes this, which correctly
  /// invalidates the cache.
  static String fingerprint({
    required String languageCode,
    required String level,
    required List<ReviewItem> troubleSpots,
    required List<ReviewItem> dueItems,
  }) {
    // Sorted so an ordering difference alone never forces a regeneration.
    final ids = <String>{
      ...troubleSpots.map((i) => i.id),
      ...dueItems.map((i) => i.id),
    }.toList()
      ..sort();

    return '$languageCode|$level|${ids.join(",")}';
  }

  /// True when [cached] can still be shown.
  ///
  /// Same language, same learner state, and generated on the same local day —
  /// a day boundary forces at least one fresh quiz so the set never goes
  /// stale for a learner whose queue happens not to have changed.
  static bool isUsable(
    CachedQuiz? cached, {
    required String languageCode,
    required String fingerprint,
    required DateTime now,
  }) {
    if (cached == null) return false;
    if (cached.questions.isEmpty) return false;
    if (cached.languageCode != languageCode) return false;
    if (cached.fingerprint != fingerprint) return false;
    return _isSameDay(cached.generatedAt, now);
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ==================== SERIALIZATION ====================

  static Map<String, dynamic> questionToJson(QuizQuestion question) => {
        'topic': question.topic,
        'question': question.question,
        'options': question.options,
        'correct': question.correct,
        'explanation': question.explanation,
        'reviewItemId': question.reviewItemId,
      };

  /// Rebuilds a question, or null when the stored shape is unusable.
  ///
  /// Applies the same "answer must be among the options" rule the parser
  /// does, so corrupted storage can't produce an unanswerable question.
  static QuizQuestion? questionFromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    if (rawOptions is! List) return null;

    final options = rawOptions.whereType<String>().toList();
    final correct = json['correct'] as String? ?? '';
    if (options.isEmpty || !options.contains(correct)) return null;

    return QuizQuestion(
      topic: json['topic'] as String? ?? '',
      question: json['question'] as String? ?? '',
      options: options,
      correct: correct,
      explanation: json['explanation'] as String? ?? '',
      reviewItemId: json['reviewItemId'] as String?,
    );
  }

  static String encode(CachedQuiz cached) => json.encode(cached.toJson());

  static CachedQuiz? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = json.decode(raw);
      if (decoded is! Map) return null;
      return CachedQuiz.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }
}
