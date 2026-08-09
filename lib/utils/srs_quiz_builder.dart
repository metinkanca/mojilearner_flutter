/// Builds quiz questions out of the learner's review queue.
///
/// This is what closes the SRS loop in the other direction: [SrsBriefing]
/// pushes the queue into conversation, this pulls it into active recall, and
/// the answers grade the items back through [VocabProvider.grade].
///
/// Pure and provider-free so the distractor rules can be tested directly.
library;

import 'dart:math';

import '../models/models.dart';

/// One multiple-choice question, either generated from a review item or taken
/// from the stock set.
class QuizQuestion {
  const QuizQuestion({
    required this.topic,
    required this.question,
    required this.options,
    required this.correct,
    required this.explanation,
    this.reviewItemId,
  });

  /// The prominent line — the word being tested, or the stock topic label.
  final String topic;

  /// The smaller framing line above it.
  final String question;

  final List<String> options;
  final String correct;
  final String explanation;

  /// The review item this came from, or null for a stock question. Present
  /// means answering it should reschedule the item.
  final String? reviewItemId;

  bool get isFromReview => reviewItemId != null;

  /// Builds a question from the legacy stock map format.
  factory QuizQuestion.fromStock(Map<String, dynamic> data) {
    return QuizQuestion(
      topic: data['topic'] as String? ?? '',
      question: data['question'] as String? ?? '',
      options: (data['options'] as List).cast<String>(),
      correct: data['correct'] as String? ?? '',
      explanation: data['explanation'] as String? ?? '',
    );
  }
}

class SrsQuizBuilder {
  SrsQuizBuilder._();

  /// Options per question, including the correct one.
  static const int optionCount = 4;

  /// Matches the stock quiz length, so rewards stay calibrated.
  static const int maxQuestions = 5;

  /// A question needs [optionCount] - 1 plausible wrong answers drawn from
  /// the learner's own items. Below this the pool can't produce them and the
  /// caller should fall back to the stock set.
  static int get minPoolSize => optionCount;

  /// Turns due review items into questions.
  ///
  /// [pool] is every item in the language, not just the due ones — distractors
  /// come from words the learner has actually met, which makes a wrong answer
  /// informative rather than obviously absurd.
  ///
  /// Returns an empty list when the pool is too small to build a fair
  /// question; the caller falls back to stock questions in that case.
  static List<QuizQuestion> build({
    required List<ReviewItem> due,
    required List<ReviewItem> pool,
    required String vocabularyPrompt,
    required String correctionPrompt,
    Random? random,
  }) {
    if (due.isEmpty) return const [];

    final rng = random ?? Random();
    final answers = pool.map((item) => item.answer.trim()).toSet();
    if (answers.length < minPoolSize) return const [];

    final questions = <QuizQuestion>[];
    for (final item in due) {
      if (questions.length >= maxQuestions) break;

      final correct = item.answer.trim();
      final distractors = answers.where((a) => a != correct).toList()
        ..shuffle(rng);
      if (distractors.length < optionCount - 1) continue;

      final options = [correct, ...distractors.take(optionCount - 1)]
        ..shuffle(rng);

      questions.add(QuizQuestion(
        reviewItemId: item.id,
        topic: item.prompt,
        question: item.kind == ReviewItemKind.correction
            ? correctionPrompt
            : vocabularyPrompt,
        options: options,
        correct: correct,
        explanation: _explanation(item),
      ));
    }

    return questions;
  }

  static String _explanation(ReviewItem item) {
    final base = item.kind == ReviewItemKind.correction
        ? '"${item.prompt}" \u2192 "${item.answer}"'
        : '"${item.prompt}" = "${item.answer}"';

    final parts = <String>[base];

    // The explanation appears only after answering, so the reading teaches
    // pronunciation without handing over the multiple choice.
    final reading = item.reading?.trim();
    if (reading != null && reading.isNotEmpty) parts.add('($reading)');

    final context = item.context?.trim();
    if (context != null && context.isNotEmpty) parts.add(context);

    return parts.join('\n');
  }
}
