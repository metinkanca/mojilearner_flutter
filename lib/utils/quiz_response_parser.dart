/// Turns the model's quiz JSON into questions the app can actually show.
///
/// Everything here treats the payload as untrusted: it is model output that
/// decides what the learner sees *and*, through `reviewItemId`, what happens
/// to their review schedule. A malformed question is dropped rather than
/// rendered, and an unrecognised id is stripped rather than obeyed.
///
/// Pure, so the tolerance rules can be tested without an API call.
library;

import 'dart:convert';

import 'input_sanitizer.dart';
import 'srs_quiz_builder.dart';

class QuizResponseParser {
  QuizResponseParser._();

  /// Options per question. A question with any other count is unshowable —
  /// the grid renders in pairs and the reward maths assumes four.
  static const int optionCount = 4;

  /// Upper bound on questions accepted from one response.
  static const int maxQuestions = 10;

  static const int maxQuestionLength = 300;
  static const int maxOptionLength = 120;
  static const int maxExplanationLength = 400;

  /// Parses [response] into questions.
  ///
  /// [allowedReviewItemIds] is the whitelist from [QuizBriefing.offeredIds].
  /// A question tagged with anything else keeps its content but loses the
  /// tag, so it still gets asked and simply doesn't touch the schedule.
  ///
  /// Returns an empty list when nothing usable came back, which is the
  /// caller's signal to fall back to a locally-built quiz.
  static List<QuizQuestion> parse(
    String response, {
    required Set<String> allowedReviewItemIds,
  }) {
    final cleaned = response
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
    if (cleaned.isEmpty) return const [];

    final Object? decoded;
    try {
      decoded = json.decode(cleaned);
    } catch (_) {
      return const [];
    }
    if (decoded is! List) return const [];

    final questions = <QuizQuestion>[];
    for (final element in decoded) {
      if (questions.length >= maxQuestions) break;
      if (element is! Map) continue;

      final question = _parseOne(element, allowedReviewItemIds);
      if (question != null) questions.add(question);
    }
    return questions;
  }

  static QuizQuestion? _parseOne(Map<Object?, Object?> raw, Set<String> allowed) {
    final text = _field(raw['question'], maxQuestionLength);
    if (text.isEmpty) return null;

    final rawOptions = raw['options'];
    if (rawOptions is! List) return null;

    final options = <String>[];
    for (final option in rawOptions) {
      final cleaned = _field(option, maxOptionLength);
      // Duplicate options make a question unanswerable: two identical
      // buttons where only one is scored correct.
      if (cleaned.isEmpty || options.contains(cleaned)) continue;
      options.add(cleaned);
    }
    if (options.length != optionCount) return null;

    final correct = _field(raw['correct'], maxOptionLength);
    // The answer must actually be on screen. Models occasionally return a
    // paraphrase, which would make the question impossible to get right.
    if (!options.contains(correct)) return null;

    final topic = _field(raw['topic'], maxOptionLength);
    final explanation = _field(raw['explanation'], maxExplanationLength);

    final claimedId = _field(raw['reviewItemId'], 120);
    final reviewItemId = allowed.contains(claimedId) ? claimedId : null;

    return QuizQuestion(
      // The prominent line: the word under test, falling back to the question
      // itself so the card is never blank.
      topic: topic.isEmpty ? text : topic,
      question: topic.isEmpty ? '' : text,
      options: options,
      correct: correct,
      explanation: explanation,
      reviewItemId: reviewItemId,
    );
  }

  /// Normalises one field: response markers escaped so a generated question
  /// cannot forge a section, whitespace collapsed, length capped.
  static String _field(Object? value, int maxLength) {
    if (value is! String) return '';
    final cleaned = InputSanitizer.escapeSpecialMarkers(value)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.length <= maxLength
        ? cleaned
        : cleaned.substring(0, maxLength).trim();
  }
}
