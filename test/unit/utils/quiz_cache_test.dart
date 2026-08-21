import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/models/models.dart';
import 'package:mojilearner_flutter/services/ai_service.dart';
import 'package:mojilearner_flutter/utils/quiz_cache.dart';
import 'package:mojilearner_flutter/utils/srs_quiz_builder.dart';

ReviewItem item(String id) => ReviewItem(
      id: id,
      languageCode: 'es',
      prompt: 'p$id',
      answer: 'a$id',
    );

QuizQuestion question({String topic = 'gato', String? reviewItemId}) =>
    QuizQuestion(
      topic: topic,
      question: 'What does it mean?',
      options: const ['cat', 'dog', 'bird', 'fish'],
      correct: 'cat',
      explanation: 'Gato means cat.',
      reviewItemId: reviewItemId,
    );

String print2(String languageCode, String level, List<String> ids) =>
    QuizCache.fingerprint(
      languageCode: languageCode,
      level: level,
      troubleSpots: const [],
      dueItems: ids.map(item).toList(),
    );

final DateTime noon = DateTime(2026, 5, 10, 12);

CachedQuiz cached({
  String languageCode = 'es',
  String? fingerprint,
  DateTime? generatedAt,
  List<QuizQuestion>? questions,
}) {
  return CachedQuiz(
    languageCode: languageCode,
    fingerprint: fingerprint ?? print2('es', 'beginner', ['1', '2']),
    generatedAt: generatedAt ?? noon,
    questions: questions ?? [question()],
  );
}

void main() {
  group('QuizCache.fingerprint', () {
    test('is stable across reorderings of the same items', () {
      expect(
        print2('es', 'beginner', ['1', '2', '3']),
        equals(print2('es', 'beginner', ['3', '1', '2'])),
      );
    });

    test('changes when the queue changes', () {
      expect(
        print2('es', 'beginner', ['1', '2']),
        isNot(equals(print2('es', 'beginner', ['1', '2', '3']))),
      );
    });

    test('changes when the level changes', () {
      expect(
        print2('es', 'beginner', ['1']),
        isNot(equals(print2('es', 'advanced', ['1']))),
      );
    });

    test('changes when the language changes', () {
      expect(
        print2('es', 'beginner', ['1']),
        isNot(equals(print2('ja', 'beginner', ['1']))),
      );
    });

    test('de-duplicates an item that is both due and troubled', () {
      final one = item('1');
      final a = QuizCache.fingerprint(
        languageCode: 'es',
        level: 'beginner',
        troubleSpots: [one],
        dueItems: [one],
      );
      final b = QuizCache.fingerprint(
        languageCode: 'es',
        level: 'beginner',
        troubleSpots: const [],
        dueItems: [one],
      );

      expect(a, equals(b));
    });
  });

  group('QuizCache.isUsable', () {
    final fp = print2('es', 'beginner', ['1', '2']);

    test('reuses a set generated earlier the same day', () {
      expect(
        QuizCache.isUsable(cached(),
            languageCode: 'es',
            fingerprint: fp,
            now: noon.add(const Duration(hours: 6))),
        isTrue,
      );
    });

    test('rejects a set from yesterday', () {
      expect(
        QuizCache.isUsable(cached(),
            languageCode: 'es',
            fingerprint: fp,
            now: noon.add(const Duration(days: 1))),
        isFalse,
      );
    });

    test('rejects a set whose learner state has moved', () {
      // Grading an item changes what is due, which must force a new quiz.
      expect(
        QuizCache.isUsable(cached(),
            languageCode: 'es',
            fingerprint: print2('es', 'beginner', ['1', '2', '3']),
            now: noon),
        isFalse,
      );
    });

    test('rejects a set for a different language', () {
      expect(
        QuizCache.isUsable(cached(),
            languageCode: 'ja', fingerprint: fp, now: noon),
        isFalse,
      );
    });

    test('rejects nothing cached', () {
      expect(
        QuizCache.isUsable(null,
            languageCode: 'es', fingerprint: fp, now: noon),
        isFalse,
      );
    });

    test('rejects an empty question set', () {
      expect(
        QuizCache.isUsable(cached(questions: const []),
            languageCode: 'es', fingerprint: fp, now: noon),
        isFalse,
      );
    });
  });

  group('QuizCache serialization', () {
    test('a cached quiz survives a round trip', () {
      final original = cached(
        questions: [question(reviewItemId: 'r1'), question(topic: 'perro')],
      );

      final restored = QuizCache.decode(QuizCache.encode(original))!;

      expect(restored.languageCode, equals(original.languageCode));
      expect(restored.fingerprint, equals(original.fingerprint));
      expect(restored.generatedAt, equals(original.generatedAt));
      expect(restored.questions, hasLength(2));
      expect(restored.questions.first.reviewItemId, equals('r1'));
      expect(restored.questions.first.options, hasLength(4));
    });

    test('corrupt storage decodes to null rather than throwing', () {
      expect(QuizCache.decode('not json'), isNull);
      expect(QuizCache.decode(''), isNull);
      expect(QuizCache.decode(null), isNull);
      expect(QuizCache.decode('[]'), isNull);
    });

    test('a stored question whose answer is not an option is dropped', () {
      const raw = '{"languageCode":"es","fingerprint":"f",'
          '"generatedAt":"2026-05-10T12:00:00.000",'
          '"questions":[{"topic":"t","question":"q",'
          '"options":["a","b"],"correct":"zzz","explanation":"e"}]}';

      expect(QuizCache.decode(raw), isNull);
    });
  });

  group('AiGenerationConfig presets', () {
    test('structured JSON disables thinking and caps output', () {
      const config = AiGenerationConfig.structuredJson;

      expect(config.thinkingBudget, equals(0));
      expect(config.maxOutputTokens, isNotNull);
      expect(config.temperature, lessThan(1.0));
      expect(config.isEmpty, isFalse);
    });

    test('classification disables thinking and pins temperature', () {
      const config = AiGenerationConfig.classification;

      expect(config.thinkingBudget, equals(0));
      expect(config.temperature, equals(0));
    });

    test('conversational keeps every model default', () {
      const config = AiGenerationConfig.conversational;

      expect(config.isEmpty, isTrue);
      expect(config.thinkingBudget, isNull);
      expect(config.maxOutputTokens, isNull);
    });

    test('only set fields are sent, so a proxy sees no stray nulls', () {
      expect(
        AiGenerationConfig.structuredJson.toJson().keys,
        containsAll(['maxOutputTokens', 'temperature', 'thinkingBudget']),
      );
      expect(AiGenerationConfig.conversational.toJson(), isEmpty);
      expect(
        const AiGenerationConfig(thinkingBudget: 0).toJson(),
        equals({'thinkingBudget': 0}),
      );
    });
  });
}
