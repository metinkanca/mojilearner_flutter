import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/models/models.dart';
import 'package:mojilearner_flutter/providers/mistakes_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/utils/secure_storage.dart';
import 'package:mojilearner_flutter/utils/srs_scheduler.dart';
import 'package:mojilearner_flutter/utils/vocab_extractor.dart';

Mistake buildMistake({
  String original = 'yo tiene',
  String correction = 'yo tengo',
  String explanation = 'tener is irregular in the first person',
}) {
  return Mistake(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    original: original,
    correction: correction,
    explanation: explanation,
    type: 'grammar',
    timestamp: DateTime.now(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // SecureStorage falls back to an in-memory map under test; clear it so
    // items don't leak between cases.
    await SecureStorage.deleteAll();
  });

  group('VocabProvider - capture', () {
    test('records vocabulary and makes it due immediately', () async {
      final provider = VocabProvider();
      await provider.load();

      final item = provider.addVocabulary(
        languageCode: 'es',
        prompt: 'la manzana',
        answer: 'apple',
      );

      expect(provider.items, hasLength(1));
      expect(item.isDue(), isTrue);
      expect(item.kind, equals(ReviewItemKind.vocabulary));
      expect(item.repetitions, equals(0));
    });

    test('meeting a known word again does not reset its progress', () async {
      final provider = VocabProvider();
      await provider.load();

      final item = provider.addVocabulary(
        languageCode: 'es',
        prompt: 'la manzana',
        answer: 'apple',
      );
      provider.grade(item.id, ReviewGrade.good);
      provider.grade(item.id, ReviewGrade.good);
      final progressed = provider.byId(item.id)!;
      expect(progressed.repetitions, equals(2));

      provider.addVocabulary(
        languageCode: 'es',
        prompt: 'La Manzana', // same word, different casing
        answer: 'apple (fruit)',
      );

      expect(provider.items, hasLength(1));
      final after = provider.byId(item.id)!;
      expect(after.repetitions, equals(2));
      expect(after.answer, equals('apple (fruit)'));
    });

    test('the same word in two languages stays two items', () async {
      final provider = VocabProvider();
      await provider.load();

      provider.addVocabulary(
        languageCode: 'es',
        prompt: 'no',
        answer: 'no',
      );
      provider.addVocabulary(
        languageCode: 'fr',
        prompt: 'no',
        answer: 'no',
      );

      expect(provider.items, hasLength(2));
    });

    test('repeating a mistake pulls it back to the front of the queue',
        () async {
      final provider = VocabProvider();
      await provider.load();

      final item = provider.addFromMistake(buildMistake(), languageCode: 'es');
      // Push it far into the future.
      provider.grade(item.id, ReviewGrade.easy);
      provider.grade(item.id, ReviewGrade.easy);
      provider.grade(item.id, ReviewGrade.easy);
      expect(provider.byId(item.id)!.isDue(), isFalse);

      // Making the same mistake again means it isn't learned after all.
      provider.addFromMistake(buildMistake(), languageCode: 'es');

      expect(provider.items, hasLength(1));
      final after = provider.byId(item.id)!;
      expect(after.isDue(), isTrue);
      expect(after.repetitions, equals(0));
    });

    test('mistakes are captured automatically via the subscription', () async {
      final mistakes = MistakesProvider();
      final provider = VocabProvider();
      await provider.load();
      provider.subscribeToMistakes(mistakes, languageCode: () => 'es');

      mistakes.addMistake(
        'yo tiene',
        'yo tengo',
        'tener is irregular',
        'grammar',
      );
      await Future.delayed(const Duration(milliseconds: 10));

      expect(provider.items, hasLength(1));
      expect(provider.items.first.kind, equals(ReviewItemKind.correction));
      expect(provider.items.first.languageCode, equals('es'));
      expect(provider.items.first.answer, equals('yo tengo'));

      mistakes.dispose();
    });

    test('a batch of words from one reply saves and notifies once', () async {
      final provider = VocabProvider();
      await provider.load();

      var notifications = 0;
      provider.addListener(() => notifications++);

      final added = provider.addVocabularyBatch(
        const [
          ExtractedVocab(term: 'el perro', meaning: 'dog'),
          ExtractedVocab(term: 'el gato', meaning: 'cat'),
          ExtractedVocab(term: 'el pájaro', meaning: 'bird'),
        ],
        languageCode: 'es',
      );

      expect(added, hasLength(3));
      expect(provider.items, hasLength(3));

      // The point of the batch. One notify per word meant one full re-encode
      // of the learner's whole item list per word, several times a message.
      expect(notifications, 1,
          reason: 'one flush for the reply, not one per word');
    });

    test('an empty batch does not touch storage at all', () async {
      final provider = VocabProvider();
      await provider.load();

      var notifications = 0;
      provider.addListener(() => notifications++);

      expect(
        provider.addVocabularyBatch(const [], languageCode: 'es'),
        isEmpty,
      );
      expect(notifications, 0);
    });
  });

  group('VocabProvider - the queue', () {
    test('only due items appear, most overdue first', () async {
      final provider = VocabProvider();
      await provider.load();

      final soon = provider.addVocabulary(
        languageCode: 'es',
        prompt: 'uno',
        answer: 'one',
      );
      final later = provider.addVocabulary(
        languageCode: 'es',
        prompt: 'dos',
        answer: 'two',
      );

      // Schedule `later` out; `soon` stays due.
      provider.grade(later.id, ReviewGrade.good);

      final due = provider.dueItems(languageCode: 'es');
      expect(due, hasLength(1));
      expect(due.first.id, equals(soon.id));
      expect(provider.dueCount(languageCode: 'es'), equals(1));
    });

    test('the queue is scoped to the language being studied', () async {
      final provider = VocabProvider();
      await provider.load();

      provider.addVocabulary(
          languageCode: 'es', prompt: 'uno', answer: 'one');
      provider.addVocabulary(languageCode: 'fr', prompt: 'un', answer: 'one');

      expect(provider.dueCount(languageCode: 'es'), equals(1));
      expect(provider.dueCount(languageCode: 'fr'), equals(1));
      expect(provider.dueCount(), equals(2));
    });

    test('a long backlog is capped to a finishable session', () async {
      final provider = VocabProvider();
      await provider.load();

      for (var i = 0; i < VocabProvider.maxSessionSize + 15; i++) {
        provider.addVocabulary(
          languageCode: 'es',
          prompt: 'word_$i',
          answer: 'meaning_$i',
        );
      }

      expect(provider.dueCount(languageCode: 'es'),
          equals(VocabProvider.maxSessionSize + 15));
      expect(provider.nextSession(languageCode: 'es'),
          hasLength(VocabProvider.maxSessionSize));
    });

    test('surfaces the items the learner keeps forgetting', () async {
      final provider = VocabProvider();
      await provider.load();

      final easy = provider.addVocabulary(
          languageCode: 'es', prompt: 'uno', answer: 'one');
      final hard = provider.addVocabulary(
          languageCode: 'es', prompt: 'dos', answer: 'two');

      provider.grade(easy.id, ReviewGrade.good);
      provider.grade(hard.id, ReviewGrade.again);
      provider.grade(hard.id, ReviewGrade.again);

      final trouble = provider.troubleSpots(languageCode: 'es');
      expect(trouble, hasLength(1));
      expect(trouble.first.id, equals(hard.id));
      expect(trouble.first.lapses, equals(2));
    });
  });

  group('VocabProvider - reviewing', () {
    test('grading reschedules the item', () async {
      final provider = VocabProvider();
      await provider.load();

      final item = provider.addVocabulary(
        languageCode: 'es',
        prompt: 'la manzana',
        answer: 'apple',
      );

      final updated = provider.grade(item.id, ReviewGrade.good);

      expect(updated, isNotNull);
      expect(updated!.repetitions, equals(1));
      expect(updated.isDue(), isFalse);
      expect(updated.lastReviewedAt, isNotNull);
    });

    test('grading an unknown id is a no-op', () async {
      final provider = VocabProvider();
      await provider.load();

      expect(provider.grade('nope', ReviewGrade.good), isNull);
    });

    test('an item counts as learned after three clean reviews', () async {
      final provider = VocabProvider();
      await provider.load();

      final item = provider.addVocabulary(
        languageCode: 'es',
        prompt: 'la manzana',
        answer: 'apple',
      );

      expect(provider.learnedCount(languageCode: 'es'), equals(0));
      provider.grade(item.id, ReviewGrade.good);
      provider.grade(item.id, ReviewGrade.good);
      provider.grade(item.id, ReviewGrade.good);
      expect(provider.learnedCount(languageCode: 'es'), equals(1));
    });
  });

  group('VocabProvider - persistence', () {
    test('items and their schedules survive a restart', () async {
      final provider = VocabProvider();
      await provider.load();

      final item = provider.addVocabulary(
        languageCode: 'es',
        prompt: 'la manzana',
        answer: 'apple',
        context: 'Como una manzana.',
      );
      provider.grade(item.id, ReviewGrade.good);
      provider.grade(item.id, ReviewGrade.good);
      await Future.delayed(const Duration(milliseconds: 20));

      final restarted = VocabProvider();
      await restarted.load();

      expect(restarted.items, hasLength(1));
      final restored = restarted.items.first;
      expect(restored.prompt, equals('la manzana'));
      expect(restored.answer, equals('apple'));
      expect(restored.context, equals('Como una manzana.'));
      expect(restored.repetitions, equals(2));
      expect(restored.intervalDays, equals(6));
      expect(restored.isDue(), isFalse);
    });

    test('round-trips through JSON without drift', () {
      final original = ReviewItem(
        id: 'abc',
        languageCode: 'ja',
        prompt: 'りんご',
        answer: 'apple',
        context: 'りんごを食べる。',
        kind: ReviewItemKind.correction,
        easeFactor: 2.36,
        intervalDays: 15,
        repetitions: 4,
        lapses: 2,
        dueAt: DateTime(2026, 9, 1),
        createdAt: DateTime(2026, 8, 1),
        lastReviewedAt: DateTime(2026, 8, 17),
      );

      final restored = ReviewItem.fromJson(original.toJson());

      expect(restored.id, equals(original.id));
      expect(restored.languageCode, equals(original.languageCode));
      expect(restored.prompt, equals(original.prompt));
      expect(restored.answer, equals(original.answer));
      expect(restored.context, equals(original.context));
      expect(restored.kind, equals(original.kind));
      expect(restored.easeFactor, equals(original.easeFactor));
      expect(restored.intervalDays, equals(original.intervalDays));
      expect(restored.repetitions, equals(original.repetitions));
      expect(restored.lapses, equals(original.lapses));
      expect(restored.dueAt, equals(original.dueAt));
      expect(restored.createdAt, equals(original.createdAt));
      expect(restored.lastReviewedAt, equals(original.lastReviewedAt));
    });

    test('a malformed stored item does not take down the whole store', () {
      final restored = ReviewItem.fromJson({
        'id': 'partial',
        'prompt': 'hola',
        // everything else missing
      });

      expect(restored.languageCode, equals('en'));
      expect(restored.answer, isEmpty);
      expect(restored.kind, equals(ReviewItemKind.vocabulary));
      expect(restored.easeFactor, equals(SrsScheduler.defaultEaseFactor));
      expect(restored.isDue(), isTrue);
    });
  });
}
