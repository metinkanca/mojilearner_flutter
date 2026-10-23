import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/utils/secure_storage.dart';
import 'package:mojilearner_flutter/utils/vocab_extractor.dart';
import 'package:shared_preferences/shared_preferences.dart';

ExtractedVocab suggested(String term, String meaning) =>
    ExtractedVocab(term: term, meaning: meaning, related: true);

/// Words the tutor only suggested about the topic live in a pile of their own.
/// They are for the games, and must never turn up as cards to review.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SecureStorage.deleteAll();
  });

  Future<VocabProvider> loaded() async {
    final provider = VocabProvider();
    await provider.load();
    return provider;
  }

  test('a suggested word is in the pile and not in the review queue',
      () async {
    final vocab = await loaded();

    vocab.addSuggested([suggested('tarde', 'afternoon')], languageCode: 'es');

    expect(vocab.suggestedItems.map((i) => i.prompt), ['tarde']);
    expect(vocab.items, isEmpty);
    expect(vocab.dueItems(languageCode: 'es'), isEmpty);
    expect(vocab.nextSession(languageCode: 'es'), isEmpty);
  });

  test("the games see the player's own words and then the suggested ones",
      () async {
    final vocab = await loaded();
    vocab.addVocabulary(languageCode: 'es', prompt: 'sol', answer: 'sun');
    vocab.addSuggested([suggested('tarde', 'afternoon')], languageCode: 'es');

    expect(vocab.practiseItems.map((i) => i.prompt), ['sol', 'tarde']);
  });

  test('a word already known is not suggested again', () async {
    final vocab = await loaded();
    vocab.addVocabulary(languageCode: 'es', prompt: 'sol', answer: 'sun');

    final added = vocab.addSuggested(
      [suggested('Sol', 'sun'), suggested('tarde', 'afternoon')],
      languageCode: 'es',
    );
    expect(added.map((i) => i.prompt), ['tarde']);

    final again = vocab
        .addSuggested([suggested('tarde', 'afternoon')], languageCode: 'es');
    expect(again, isEmpty);
    expect(vocab.suggestedItems, hasLength(1));
  });

  test('met properly, a suggested word leaves the pile and joins the queue',
      () async {
    final vocab = await loaded();
    vocab.addSuggested([suggested('tarde', 'afternoon')], languageCode: 'es');

    vocab.addVocabulary(
        languageCode: 'es', prompt: 'tarde', answer: 'afternoon');

    expect(vocab.suggestedItems, isEmpty);
    expect(vocab.items.map((i) => i.prompt), ['tarde']);
    expect(vocab.practiseItems, hasLength(1));
  });

  test('the same word in another language is a different word', () async {
    final vocab = await loaded();
    vocab.addVocabulary(languageCode: 'es', prompt: 'sol', answer: 'sun');

    final added =
        vocab.addSuggested([suggested('sol', 'sun')], languageCode: 'pt');

    expect(added, hasLength(1));
  });

  test('knowsVocabulary sees both the queue and the pile', () async {
    final vocab = await loaded();
    vocab.addVocabulary(languageCode: 'es', prompt: 'sol', answer: 'sun');
    vocab.addSuggested([suggested('tarde', 'afternoon')], languageCode: 'es');

    expect(vocab.knowsVocabulary('es', 'sol'), isTrue);
    expect(vocab.knowsVocabulary('es', 'TARDE'), isTrue);
    expect(vocab.knowsVocabulary('es', 'noche'), isFalse);
    expect(vocab.knowsVocabulary('fr', 'sol'), isFalse);
  });

  test('only the newest are kept', () async {
    final vocab = await loaded();
    final many = [
      for (var i = 0; i < VocabProvider.maxSuggested + 20; i++)
        suggested('word$i', 'meaning$i'),
    ];

    vocab.addSuggested(many, languageCode: 'es');

    expect(vocab.suggestedItems, hasLength(VocabProvider.maxSuggested));
    expect(vocab.suggestedItems.first.prompt, 'word20');
    expect(vocab.suggestedItems.last.prompt,
        'word${VocabProvider.maxSuggested + 19}');
  });

  test('the pile survives a restart', () async {
    final first = await loaded();
    first.addSuggested([suggested('tarde', 'afternoon')], languageCode: 'es');
    // The write follows the add without being waited on.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final restarted = await loaded();

    expect(restarted.suggestedItems.map((i) => i.prompt), ['tarde']);
    expect(restarted.suggestedItems.single.answer, 'afternoon');
    expect(restarted.items, isEmpty);
  });

  test('a corrupt saved pile is ignored, not fatal', () async {
    SharedPreferences.setMockInitialValues({'suggested_words': '{not json'});

    final vocab = await loaded();

    expect(vocab.suggestedItems, isEmpty);
    expect(vocab.isLoaded, isTrue);
  });
}
