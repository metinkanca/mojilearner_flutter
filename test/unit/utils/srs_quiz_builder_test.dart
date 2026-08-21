import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/models/models.dart';
import 'package:mojilearner_flutter/utils/srs_quiz_builder.dart';

ReviewItem item({
  required String prompt,
  required String answer,
  ReviewItemKind kind = ReviewItemKind.vocabulary,
  String? context,
  String languageCode = 'es',
}) {
  return ReviewItem(
    id: 'id-$prompt',
    languageCode: languageCode,
    prompt: prompt,
    answer: answer,
    kind: kind,
    context: context,
  );
}

List<ReviewItem> poolOf(int count) => List.generate(
      count,
      (i) => item(prompt: 'word$i', answer: 'meaning$i'),
    );

List<QuizQuestion> build({
  required List<ReviewItem> due,
  required List<ReviewItem> pool,
}) {
  return SrsQuizBuilder.build(
    due: due,
    pool: pool,
    vocabularyPrompt: 'What does this mean?',
    correctionPrompt: "What's the correction?",
    random: Random(7),
  );
}

void main() {
  group('SrsQuizBuilder.build - fallback conditions', () {
    test('returns nothing when nothing is due', () {
      expect(build(due: [], pool: poolOf(10)), isEmpty);
    });

    test('returns nothing when the pool cannot supply distractors', () {
      final pool = poolOf(SrsQuizBuilder.minPoolSize - 1);
      expect(build(due: pool, pool: pool), isEmpty);
    });

    test('builds once the pool is just large enough', () {
      final pool = poolOf(SrsQuizBuilder.minPoolSize);
      expect(build(due: pool, pool: pool), isNotEmpty);
    });

    test('counts distinct answers, not items, when sizing the pool', () {
      // Five items that all mean the same thing can only ever produce one
      // option, so this must not be treated as a usable pool.
      final pool = List.generate(
        5,
        (i) => item(prompt: 'word$i', answer: 'same'),
      );
      expect(build(due: pool, pool: pool), isEmpty);
    });
  });

  group('SrsQuizBuilder.build - question shape', () {
    late List<QuizQuestion> questions;
    late List<ReviewItem> pool;

    setUp(() {
      pool = poolOf(10);
      questions = build(due: pool, pool: pool);
    });

    test('caps the number of questions', () {
      expect(questions, hasLength(SrsQuizBuilder.maxQuestions));
    });

    test('every question has the right number of distinct options', () {
      for (final q in questions) {
        expect(q.options, hasLength(SrsQuizBuilder.optionCount));
        expect(q.options.toSet(), hasLength(SrsQuizBuilder.optionCount));
      }
    });

    test('the correct answer is always among the options', () {
      for (final q in questions) {
        expect(q.options, contains(q.correct));
      }
    });

    test('distractors are drawn from words the learner has met', () {
      final known = pool.map((i) => i.answer).toSet();
      for (final q in questions) {
        expect(known.containsAll(q.options), isTrue);
      }
    });

    test('the prompt is the term and the answer is its meaning', () {
      final first = questions.first;
      final source = pool.firstWhere((i) => i.id == first.reviewItemId);
      expect(first.topic, equals(source.prompt));
      expect(first.correct, equals(source.answer));
    });

    test('carries the review item id so answers can reschedule it', () {
      for (final q in questions) {
        expect(q.reviewItemId, isNotNull);
        expect(q.isFromReview, isTrue);
      }
    });

    test('the correct answer is not always in the same slot', () {
      final positions =
          questions.map((q) => q.options.indexOf(q.correct)).toSet();
      expect(positions.length, greaterThan(1));
    });
  });

  group('SrsQuizBuilder.build - phrasing', () {
    test('vocabulary and corrections get different framing', () {
      final pool = [
        ...poolOf(6),
        item(
          prompt: 'yo tengo hambre mucho',
          answer: 'yo tengo mucha hambre',
          kind: ReviewItemKind.correction,
        ),
      ];
      final questions = build(due: pool.reversed.toList(), pool: pool);

      final correction =
          questions.firstWhere((q) => q.reviewItemId!.contains('hambre'));
      expect(correction.question, equals("What's the correction?"));
      expect(correction.explanation, contains('→'));

      final vocabulary = questions.firstWhere((q) => q != correction);
      expect(vocabulary.question, equals('What does this mean?'));
      expect(vocabulary.explanation, contains('='));
    });

    test('an example sentence is appended to the explanation', () {
      final pool = [
        item(prompt: 'gato', answer: 'cat', context: 'El gato duerme.'),
        ...poolOf(6),
      ];
      final questions = build(due: pool, pool: pool);
      final gato = questions.firstWhere((q) => q.topic == 'gato');

      expect(gato.explanation, contains('"gato" = "cat"'));
      expect(gato.explanation, contains('El gato duerme.'));
    });

    test('no trailing newline when the item has no example', () {
      final pool = poolOf(6);
      final questions = build(due: pool, pool: pool);

      expect(questions.first.explanation, isNot(contains('\n')));
    });
  });

  group('QuizQuestion.fromStock', () {
    test('reads the legacy map shape and marks it as not from review', () {
      final q = QuizQuestion.fromStock({
        'question': "How do you say 'Hello' in Spanish?",
        'topic': 'Greetings',
        'options': ['Adiós', 'Hola', 'Gracias', 'Por favor'],
        'correct': 'Hola',
        'explanation': 'Hola is the standard greeting.',
      });

      expect(q.topic, equals('Greetings'));
      expect(q.options, hasLength(4));
      expect(q.correct, equals('Hola'));
      expect(q.reviewItemId, isNull);
      expect(q.isFromReview, isFalse);
    });
  });
}
