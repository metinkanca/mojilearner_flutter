import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/services/ai_prompt_spec.dart';
import 'package:mojilearner_flutter/services/starter_words.dart';
import 'package:mojilearner_flutter/utils/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

String starterReply(int count, {String prefix = 'palabra'}) => jsonEncode([
      for (var i = 0; i < count; i++)
        {'term': '$prefix$i', 'meaning': 'word $i', 'example': 'Ejemplo $i.'},
    ]);

/// Words for a player who has few: asked for when onboarding ends and when the
/// games run thin, kept in the suggested pile, and never allowed to nag.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VocabProvider vocab;
  late List<AiPromptSpec> asked;
  var clock = DateTime(2026, 10, 23, 9);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SecureStorage.deleteAll();
    vocab = VocabProvider();
    await vocab.load();
    asked = [];
    clock = DateTime(2026, 10, 23, 9);
  });

  Future<int> ensure(
    String reply, {
    String language = 'es',
    bool fails = false,
  }) =>
      StarterWords.ensure(
        vocab: vocab,
        languageCode: language,
        nativeCode: 'en',
        level: 'beginner',
        now: () => clock,
        generate: (spec) async {
          asked.add(spec);
          if (fails) throw Exception('offline');
          return reply;
        },
      );

  test('a player with no words is given a dozen, in the suggested pile',
      () async {
    final added = await ensure(starterReply(12));

    expect(added, 12);
    expect(vocab.suggestedItems, hasLength(12));
    expect(vocab.items, isEmpty, reason: 'not review cards: never met');
    expect(vocab.dueItems(languageCode: 'es'), isEmpty);
  });

  test('asks for the right thing: the language, the level, what they have',
      () async {
    vocab.addVocabulary(languageCode: 'es', prompt: 'sol', answer: 'sun');

    await ensure(starterReply(3));

    final spec = asked.single;
    expect(spec.mode, AiPromptMode.starter);
    expect(spec.params['targetCode'], 'es');
    expect(spec.params['nativeCode'], 'en');
    expect(spec.params['level'], 'beginner');
    expect(spec.params['exclude'], ['sol']);
  });

  test('a player who already has enough words is not asked for more',
      () async {
    for (var i = 0; i < StarterWords.thinBelow; i++) {
      vocab.addVocabulary(languageCode: 'es', prompt: 'w$i', answer: 'm$i');
    }

    expect(await ensure(starterReply(12)), 0);
    expect(asked, isEmpty);
  });

  test('the suggested words count toward having enough', () async {
    await ensure(starterReply(12));
    asked.clear();
    clock = clock.add(const Duration(hours: 5));

    expect(await ensure(starterReply(12, prefix: 'otra')), 0);
    expect(asked, isEmpty);
  });

  test('another language is counted on its own', () async {
    for (var i = 0; i < StarterWords.thinBelow; i++) {
      vocab.addVocabulary(languageCode: 'fr', prompt: 'w$i', answer: 'm$i');
    }

    expect(await ensure(starterReply(5), language: 'es'), 5);
  });

  test('does not ask twice inside an hour, then may', () async {
    await ensure(starterReply(2));
    asked.clear();

    clock = clock.add(const Duration(minutes: 59));
    expect(await ensure(starterReply(2, prefix: 'b')), 0);
    expect(asked, isEmpty);

    clock = clock.add(const Duration(minutes: 2));
    expect(await ensure(starterReply(2, prefix: 'c')), 2);
    expect(asked, hasLength(1));
  });

  test('a failed ask still waits its turn, and adds nothing', () async {
    expect(await ensure('', fails: true), 0);
    asked.clear();

    expect(await ensure(starterReply(12)), 0, reason: 'an hour has not passed');
    expect(asked, isEmpty);
  });

  test('an empty or nonsense reply adds nothing and does not throw', () async {
    expect(await ensure(''), 0);
    clock = clock.add(const Duration(hours: 2));
    expect(await ensure('I am sorry, I cannot do that.'), 0);
    clock = clock.add(const Duration(hours: 2));
    expect(await ensure('{"term": "no meaning"}'), 0);
    expect(vocab.suggestedItems, isEmpty);
  });

  test('words the player already has are not added again', () async {
    vocab.addVocabulary(languageCode: 'es', prompt: 'palabra0', answer: 'x');

    final added = await ensure(starterReply(3));

    expect(added, 2);
    expect(vocab.suggestedItems.map((i) => i.prompt), ['palabra1', 'palabra2']);
  });

  test('no more than a dozen come back from one ask', () async {
    expect(await ensure(starterReply(30)), 12);
  });

  test('the words keep the reading the model gave for a non-Latin script',
      () async {
    final reply = jsonEncode([
      {'term': 'ねこ', 'meaning': 'cat', 'reading': 'neko'},
    ]);

    await ensure(reply, language: 'ja');

    expect(vocab.suggestedItems.single.reading, 'neko');
  });
}
