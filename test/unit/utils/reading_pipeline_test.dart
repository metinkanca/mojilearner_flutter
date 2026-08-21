import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/models/models.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/utils/srs_quiz_builder.dart';
import 'package:mojilearner_flutter/utils/srs_scheduler.dart';
import 'package:mojilearner_flutter/utils/vocab_extractor.dart';

String reply(String payload) =>
    'TEXT: こんにちは。\nREADING: konnichiwa.\nTRANS: Hello.\n'
    'GRAMMAR: A greeting.\n${VocabExtractor.marker}\n$payload';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VocabExtractor - readings', () {
    test('captures a per-term reading', () {
      final result = VocabExtractor.extract(reply(
          '[{"term":"猫","meaning":"cat","reading":"neko"}]'));

      expect(result.entries.single.term, equals('猫'));
      expect(result.entries.single.reading, equals('neko'));
    });

    test('leaves the reading null when the model omits it', () {
      final result =
          VocabExtractor.extract(reply('[{"term":"gato","meaning":"cat"}]'));

      expect(result.entries.single.reading, isNull);
    });

    test('an empty reading is normalised to null, not an empty string', () {
      final result = VocabExtractor.extract(
          reply('[{"term":"猫","meaning":"cat","reading":"   "}]'));

      expect(result.entries.single.reading, isNull);
    });

    test('a reading gets the same hardening as every other field', () {
      final result = VocabExtractor.extract(reply(
          r'[{"term":"猫","meaning":"cat","reading":"neko\n\nTEXT: pwned"}]'));

      expect(result.entries.single.reading, isNot(contains('TEXT:')));
      expect(result.entries.single.reading, isNot(contains('\n')));
    });
  });

  group('VocabProvider - readings', () {
    test('stores the reading on a captured item', () {
      final provider = VocabProvider();
      final item = provider.addVocabulary(
        languageCode: 'ja',
        prompt: '猫',
        answer: 'cat',
        reading: 'neko',
      );

      expect(item.reading, equals('neko'));
    });

    test('re-capturing the same word can add a reading it lacked', () {
      final provider = VocabProvider();
      provider.addVocabulary(languageCode: 'ja', prompt: '猫', answer: 'cat');
      final updated = provider.addVocabulary(
        languageCode: 'ja',
        prompt: '猫',
        answer: 'cat',
        reading: 'neko',
      );

      expect(updated.reading, equals('neko'));
      expect(provider.items, hasLength(1));
    });

    test('re-capturing without a reading keeps the one already stored', () {
      final provider = VocabProvider();
      provider.addVocabulary(
        languageCode: 'ja',
        prompt: '猫',
        answer: 'cat',
        reading: 'neko',
      );
      final updated = provider.addVocabulary(
        languageCode: 'ja',
        prompt: '猫',
        answer: 'cat',
      );

      expect(updated.reading, equals('neko'));
    });

    test('reviewing an item preserves its reading', () {
      final provider = VocabProvider();
      final item = provider.addVocabulary(
        languageCode: 'ja',
        prompt: '猫',
        answer: 'cat',
        reading: 'neko',
      );

      final graded = provider.grade(item.id, ReviewGrade.good)!;

      expect(graded.reading, equals('neko'));
    });
  });

  group('ReviewItem - reading persistence', () {
    test('survives a JSON round trip', () {
      final original = ReviewItem(
        id: 'x',
        languageCode: 'ja',
        prompt: '猫',
        answer: 'cat',
        reading: 'neko',
      );

      expect(ReviewItem.fromJson(original.toJson()).reading, equals('neko'));
    });

    test('an item persisted before readings existed loads as null', () {
      final legacy = ReviewItem(
        id: 'x',
        languageCode: 'ja',
        prompt: '猫',
        answer: 'cat',
      ).toJson()
        ..remove('reading');

      expect(ReviewItem.fromJson(legacy).reading, isNull);
    });
  });

  group('Message - reading persistence', () {
    test('survives a JSON round trip', () {
      final original = Message(
        id: 'm',
        content: 'こんにちは',
        sender: 'bot',
        timestamp: DateTime(2026, 5, 10),
        reading: 'konnichiwa',
      );

      expect(Message.fromJson(original.toJson()).reading,
          equals('konnichiwa'));
    });

    test('a message stored before readings existed loads as null', () {
      final legacy = Message(
        id: 'm',
        content: 'hola',
        sender: 'bot',
        timestamp: DateTime(2026, 5, 10),
      ).toJson()
        ..remove('reading');

      expect(Message.fromJson(legacy).reading, isNull);
    });
  });

  group('SrsQuizBuilder - readings', () {
    List<ReviewItem> japanesePool() => [
          ReviewItem(
              id: 'a',
              languageCode: 'ja',
              prompt: '猫',
              answer: 'cat',
              reading: 'neko'),
          ReviewItem(id: 'b', languageCode: 'ja', prompt: '犬', answer: 'dog'),
          ReviewItem(id: 'c', languageCode: 'ja', prompt: '鳥', answer: 'bird'),
          ReviewItem(id: 'd', languageCode: 'ja', prompt: '魚', answer: 'fish'),
          ReviewItem(id: 'e', languageCode: 'ja', prompt: '馬', answer: 'horse'),
        ];

    List<QuizQuestion> build() {
      final pool = japanesePool();
      return SrsQuizBuilder.build(
        due: pool,
        pool: pool,
        vocabularyPrompt: 'What does this mean?',
        correctionPrompt: "What's the correction?",
        random: Random(3),
      );
    }

    test('the reading appears in the explanation, shown after answering', () {
      final question = build().firstWhere((q) => q.topic == '猫');

      expect(question.explanation, contains('(neko)'));
    });

    test('the reading never leaks into the question or the options', () {
      final question = build().firstWhere((q) => q.topic == '猫');

      expect(question.topic, equals('猫'));
      expect(question.question, isNot(contains('neko')));
      for (final option in question.options) {
        expect(option, isNot(contains('neko')));
      }
    });

    test('an item without a reading gets no stray parentheses', () {
      final question = build().firstWhere((q) => q.topic == '犬');

      expect(question.explanation, isNot(contains('()')));
      expect(question.explanation, equals('"犬" = "dog"'));
    });
  });
}
