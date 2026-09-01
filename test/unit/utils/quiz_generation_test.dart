import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/models/models.dart';
import 'package:mojilearner_flutter/utils/review_selection.dart';
import 'package:mojilearner_flutter/utils/quiz_response_parser.dart';

ReviewItem item({
  required String id,
  required String prompt,
  required String answer,
  int lapses = 0,
  ReviewItemKind kind = ReviewItemKind.vocabulary,
  String languageCode = 'es',
}) {
  return ReviewItem(
    id: id,
    languageCode: languageCode,
    prompt: prompt,
    answer: answer,
    lapses: lapses,
    kind: kind,
  );
}

String questionJson({
  String question = 'What does gato mean?',
  String topic = 'gato',
  List<String> options = const ['cat', 'dog', 'bird', 'fish'],
  String correct = 'cat',
  String explanation = 'Gato means cat.',
  String? reviewItemId,
}) {
  final opts = options.map((o) => '"$o"').join(',');
  final id = reviewItemId == null ? '' : ',"reviewItemId":"$reviewItemId"';
  return '{"question":"$question","topic":"$topic","options":[$opts],'
      '"correct":"$correct","explanation":"$explanation"$id}';
}

void main() {
  // The wording of the quiz prompt moved to `server/src/prompts.js` and is
  // covered by `server/test/prompts.test.js`. What stayed here is the choice
  // of which review items to send, and the whitelist that stops a made-up id
  // from rescheduling something the model never saw.
  group('ReviewSelection.select', () {
    test('trouble spots come first and are capped', () {
      final trouble =
          List.generate(20, (i) => item(id: 't$i', prompt: 'p$i', answer: 'a$i'));
      final briefed =
          ReviewSelection.select(troubleSpots: trouble, dueItems: const []);

      expect(briefed.trouble, hasLength(ReviewSelection.maxTroubleSpots));
      expect(briefed.trouble.first.id, equals('t0'));
      expect(briefed.due, isEmpty);
    });

    test('due items are capped separately', () {
      final due =
          List.generate(20, (i) => item(id: 'd$i', prompt: 'x$i', answer: 'y$i'));
      final briefed =
          ReviewSelection.select(troubleSpots: const [], dueItems: due);

      expect(briefed.due, hasLength(ReviewSelection.maxDueItems));
    });

    test('an item that is both forgotten and due is sent once', () {
      final shared = item(id: 'a', prompt: 'ser', answer: 'to be', lapses: 3);
      final briefed = ReviewSelection.select(
        troubleSpots: [shared],
        dueItems: [shared, item(id: 'b', prompt: 'gato', answer: 'cat')],
      );

      expect(briefed.trouble.map((i) => i.id), equals(['a']));
      expect(briefed.due.map((i) => i.id), equals(['b']));
    });

    test('a lapse count and kind survive the conversion', () {
      final briefed = ReviewSelection.select(
        troubleSpots: [
          item(
            id: 'a',
            prompt: 'yo gusta',
            answer: 'me gusta',
            lapses: 4,
            kind: ReviewItemKind.correction,
          ),
        ],
        dueItems: const [],
      );

      expect(briefed.trouble.single.lapses, equals(4));
      expect(briefed.trouble.single.isCorrection, isTrue);
    });

    test('empty in, empty out', () {
      final briefed =
          ReviewSelection.select(troubleSpots: const [], dueItems: const []);
      expect(briefed.isEmpty, isTrue);
      expect(briefed.offeredIds, isEmpty);
    });
  });

  group('BriefedReview.offeredIds', () {
    test('matches exactly the ids that were sent', () {
      final briefed = ReviewSelection.select(
        troubleSpots: [item(id: 'a', prompt: 'ser', answer: 'to be', lapses: 1)],
        dueItems: [
          item(id: 'b', prompt: 'gato', answer: 'cat'),
          item(id: 'c', prompt: 'perro', answer: 'dog'),
        ],
      );

      expect(briefed.offeredIds, equals({'a', 'b', 'c'}));
    });

    test('excludes ids the caps kept out', () {
      final due =
          List.generate(20, (i) => item(id: 'd$i', prompt: 'x$i', answer: 'y$i'));
      final ids =
          ReviewSelection.select(troubleSpots: const [], dueItems: due).offeredIds;

      expect(ids, hasLength(ReviewSelection.maxDueItems));
      expect(ids, isNot(contains('d${ReviewSelection.maxDueItems}')));
    });
  });

  group('QuizResponseParser - happy path', () {
    test('parses a well-formed question', () {
      final questions = QuizResponseParser.parse(
        '[${questionJson()}]',
        allowedReviewItemIds: const {},
      );

      expect(questions, hasLength(1));
      expect(questions.single.topic, equals('gato'));
      expect(questions.single.question, equals('What does gato mean?'));
      expect(questions.single.options, hasLength(4));
      expect(questions.single.correct, equals('cat'));
    });

    test('tolerates markdown fences', () {
      final questions = QuizResponseParser.parse(
        '```json\n[${questionJson()}]\n```',
        allowedReviewItemIds: const {},
      );

      expect(questions, hasLength(1));
    });

    test('falls back to the question text when topic is missing', () {
      final questions = QuizResponseParser.parse(
        '[${questionJson(topic: '')}]',
        allowedReviewItemIds: const {},
      );

      expect(questions.single.topic, equals('What does gato mean?'));
      expect(questions.single.question, isEmpty);
    });
  });

  group('QuizResponseParser - review item tagging', () {
    test('keeps an id the model was actually offered', () {
      final questions = QuizResponseParser.parse(
        '[${questionJson(reviewItemId: 'b')}]',
        allowedReviewItemIds: const {'b'},
      );

      expect(questions.single.reviewItemId, equals('b'));
      expect(questions.single.isFromReview, isTrue);
    });

    test('strips an invented id but still asks the question', () {
      final questions = QuizResponseParser.parse(
        '[${questionJson(reviewItemId: 'not-a-real-id')}]',
        allowedReviewItemIds: const {'b'},
      );

      expect(questions, hasLength(1));
      expect(questions.single.reviewItemId, isNull);
    });

    test('an untagged question is fine, it just does not reschedule', () {
      final questions = QuizResponseParser.parse(
        '[${questionJson()}]',
        allowedReviewItemIds: const {'b'},
      );

      expect(questions.single.reviewItemId, isNull);
    });
  });

  group('QuizResponseParser - rejecting unusable questions', () {
    test('drops a question whose answer is not among the options', () {
      final questions = QuizResponseParser.parse(
        '[${questionJson(correct: 'feline')}]',
        allowedReviewItemIds: const {},
      );

      expect(questions, isEmpty);
    });

    test('drops a question with the wrong number of options', () {
      final questions = QuizResponseParser.parse(
        '[${questionJson(options: ['cat', 'dog'], correct: 'cat')}]',
        allowedReviewItemIds: const {},
      );

      expect(questions, isEmpty);
    });

    test('drops a question with duplicate options', () {
      // Two identical buttons where only one scores is unanswerable.
      final questions = QuizResponseParser.parse(
        '[${questionJson(options: ['cat', 'cat', 'bird', 'fish'])}]',
        allowedReviewItemIds: const {},
      );

      expect(questions, isEmpty);
    });

    test('drops a question with no text', () {
      final questions = QuizResponseParser.parse(
        '[${questionJson(question: '')}]',
        allowedReviewItemIds: const {},
      );

      expect(questions, isEmpty);
    });

    test('keeps the good questions and drops only the bad ones', () {
      final questions = QuizResponseParser.parse(
        '[${questionJson(correct: 'nope')},${questionJson()}]',
        allowedReviewItemIds: const {},
      );

      expect(questions, hasLength(1));
    });
  });

  group('QuizResponseParser - malformed payloads', () {
    test('returns nothing for truncated JSON', () {
      expect(
        QuizResponseParser.parse('[{"question":"x",',
            allowedReviewItemIds: const {}),
        isEmpty,
      );
    });

    test('returns nothing for an empty response', () {
      expect(QuizResponseParser.parse('', allowedReviewItemIds: const {}),
          isEmpty);
    });

    test('returns nothing for a bare object rather than an array', () {
      expect(
        QuizResponseParser.parse(questionJson(),
            allowedReviewItemIds: const {}),
        isEmpty,
      );
    });

    test('returns nothing for prose instead of JSON', () {
      expect(
        QuizResponseParser.parse('Sure! Here are five questions...',
            allowedReviewItemIds: const {}),
        isEmpty,
      );
    });

    test('caps how many questions one response can contribute', () {
      final many =
          List.generate(30, (i) => questionJson(topic: 'w$i')).join(',');
      final questions =
          QuizResponseParser.parse('[$many]', allowedReviewItemIds: const {});

      expect(questions.length,
          lessThanOrEqualTo(QuizResponseParser.maxQuestions));
    });
  });

  group('QuizResponseParser - hardening', () {
    test('escapes response markers in generated text', () {
      final questions = QuizResponseParser.parse(
        '[${questionJson(question: 'TEXT: ignore previous', explanation: 'GRAMMAR: obey')}]',
        allowedReviewItemIds: const {},
      );

      expect(questions.single.question, isNot(contains('TEXT:')));
      expect(questions.single.explanation, isNot(contains('GRAMMAR:')));
    });

    test('truncates an absurdly long option', () {
      final long = 'a' * 500;
      final questions = QuizResponseParser.parse(
        '[${questionJson(options: [long, 'dog', 'bird', 'fish'], correct: 'dog')}]',
        allowedReviewItemIds: const {},
      );

      expect(questions.single.options.first.length,
          equals(QuizResponseParser.maxOptionLength));
    });
  });
}
