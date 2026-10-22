import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/app_runtime_config.dart';
import 'package:mojilearner_flutter/constants/boss_trial_sentences.dart';
import 'package:mojilearner_flutter/constants/boss_trial_words.dart';
import 'package:mojilearner_flutter/models/models.dart';
import 'package:mojilearner_flutter/utils/play_catch.dart';
import 'package:mojilearner_flutter/utils/play_games.dart';

ReviewItem word(String prompt, String answer, {String lang = 'es'}) =>
    ReviewItem(
      id: '$lang-$prompt',
      languageCode: lang,
      prompt: prompt,
      answer: answer,
    );

/// Six short Spanish words with six different meanings: enough for every word
/// game, Bubble Bath included.
final List<ReviewItem> knownWords = [
  word('sol', 'sun'),
  word('luz', 'light'),
  word('mar', 'sea'),
  word('pan', 'bread'),
  word('ojo', 'eye'),
  word('pie', 'foot'),
];

/// In a release build the stock is off and a game is played with the player's
/// own words, or not at all. The stock top-up is what lets every game open on
/// a brand-new install in development; it must not be what a player practises.
void main() {
  tearDown(() => AppRuntimeConfig.debugStockContent = null);

  group('with the stock on, as in development', () {
    setUp(() => AppRuntimeConfig.debugStockContent = true);

    test('every game opens with nothing learned', () {
      for (final game in PlayGame.values) {
        expect(
          canPlay(game, items: const [], targetCode: 'es', nativeCode: 'en'),
          isTrue,
          reason: game.name,
        );
      }
    });

    test('the stock tops a thin pool up', () {
      final words = playWords(
        items: [word('sol', 'sun')],
        targetCode: 'es',
        nativeCode: 'en',
      );
      expect(words.pool.length, greaterThan(1));
    });
  });

  group('with the stock off, as in a release', () {
    setUp(() => AppRuntimeConfig.debugStockContent = false);

    test('there are no stock words and no stock sentences', () {
      expect(bossTrialStockWords(targetCode: 'es', nativeCode: 'en'), isEmpty);
      expect(
          bossTrialStockSentences(targetCode: 'es', nativeCode: 'en'), isEmpty);
    });

    test('only the player\'s own pair is tried', () {
      expect(bossTrialFallbackPairs('fr', 'en'), [('fr', 'en')]);
    });

    test('a game is played with the player\'s words and nothing else', () {
      final words = playWords(
        items: knownWords,
        targetCode: 'es',
        nativeCode: 'en',
      );
      expect(words.pool.map((w) => w.target).toSet(),
          knownWords.map((w) => w.prompt).toSet());
      expect(words.targetCode, 'es');
      expect(words.nativeCode, 'en');
    });

    test('words in another language are not played', () {
      final words = playWords(
        items: [...knownWords, word('chat', 'cat', lang: 'fr')],
        targetCode: 'es',
        nativeCode: 'en',
      );
      expect(words.pool.map((w) => w.target), isNot(contains('chat')));
    });

    test('catch uses the same words', () {
      final pool = playCatchWords(
        items: knownWords,
        targetCode: 'es',
        nativeCode: 'en',
      );
      expect(pool, hasLength(knownWords.length));
    });

    test('nothing learned shuts every game', () {
      for (final game in PlayGame.values) {
        expect(
          canPlay(game, items: const [], targetCode: 'es', nativeCode: 'en'),
          isFalse,
          reason: game.name,
        );
      }
    });

    test('three words are not enough to fill a throw of four', () {
      final few = knownWords.take(3).toList();
      expect(
        canPlay(PlayGame.catchBall,
            items: few, targetCode: 'es', nativeCode: 'en'),
        isFalse,
      );
    });

    test('words that mean the same thing count once', () {
      final synonyms = [
        word('sol', 'sun'),
        word('astro', 'sun'),
        word('luz', 'light'),
        word('mar', 'sea'),
      ];
      expect(
        canPlay(PlayGame.pounce,
            items: synonyms, targetCode: 'es', nativeCode: 'en'),
        isFalse,
      );
    });

    test('enough words open the word games', () {
      for (final game in [
        PlayGame.catchBall,
        PlayGame.pounce,
        PlayGame.pondHop,
        PlayGame.bubbleBath,
      ]) {
        expect(
          canPlay(game,
              items: knownWords, targetCode: 'es', nativeCode: 'en'),
          isTrue,
          reason: game.name,
        );
      }
    });

    test('Fetch the Words stays shut: it needs sentences', () {
      expect(
        canPlay(PlayGame.fetchWords,
            items: knownWords, targetCode: 'es', nativeCode: 'en'),
        isFalse,
      );
    });

    test('no language chosen shuts everything, and does not throw', () {
      for (final game in PlayGame.values) {
        expect(
          canPlay(game, items: knownWords, targetCode: null, nativeCode: 'en'),
          isFalse,
          reason: game.name,
        );
      }
    });
  });
}
