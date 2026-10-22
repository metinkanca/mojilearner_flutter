import 'dart:math';

import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/boss_trial_sentences.dart';
import 'package:mojilearner_flutter/constants/boss_trial_words.dart';
import 'package:mojilearner_flutter/utils/boss_trial.dart';
import 'package:mojilearner_flutter/utils/boss_trial_angler.dart';

String nativeFor(String target) => target == 'en' ? 'es' : 'en';

List<TrialSentence> sentencesFor(String target) => TrialSentencePool.build(
      bossTrialStockSentences(
          targetCode: target, nativeCode: nativeFor(target)),
    );

List<TrialWord> wordsFor(String target) => TrialWordPool.build(
      items: const [],
      languageCode: target,
      stock: bossTrialStockWords(
          targetCode: target, nativeCode: nativeFor(target)),
    );

void main() {
  final es = sentencesFor('es');
  final esWords = wordsFor('es');

  group('AnglerRules clocks', () {
    test('tighten from fresh to the end of the round', () {
      expect(
          AnglerRules.lureTime(words: 4, patience: 100).inMilliseconds, 7000);
      expect(AnglerRules.lureTime(words: 4, patience: 50).inMilliseconds, 4667);
      expect(
          AnglerRules.gulpTime(letters: 5, patience: 100).inMilliseconds, 9500);
      expect(
          AnglerRules.gulpTime(letters: 5, patience: 50).inMilliseconds, 7125);
    });

    test('guessing through the fish or the letters runs the clock out', () {
      // Every wrong fish there is costs less than the whole light...
      expect(AnglerRules.lureMistakeDim * (AnglerRules.fish - 1), lessThan(1));
      // ...but four wrong letters in a row are the gulp.
      expect(AnglerRules.bubbleMistakeGulp * 5, greaterThanOrEqualTo(1));
    });
  });

  group('LureWave', () {
    test('three fish: the missing word, and two that play its part', () {
      final rng = Random(3);
      for (var i = 0; i < 60; i++) {
        final wave = LureWave.build(es, random: rng)!;
        expect(wave.fish, hasLength(AnglerRules.fish));
        expect(wave.fish.toSet(), hasLength(AnglerRules.fish),
            reason: 'two fish carrying one word');
        expect(wave.fish[wave.answer], wave.missing);

        // The gap is a slot a hex could take, and every wrong fish is a word
        // a hex could put there.
        final slot = wave.sentence.slots.firstWhere((s) => s.index == wave.gap);
        final swaps = HexScroll.swapsFor(wave.sentence, es)[slot]!;
        for (var f = 0; f < wave.fish.length; f++) {
          if (f == wave.answer) continue;
          expect(swaps, contains(wave.fish[f]));
          expect(wave.sentence.tokens, isNot(contains(wave.fish[f])),
              reason: 'a stray the sentence already has would fit too');
        }
      }
    });

    test('leaves out verbs as well as objects', () {
      final rng = Random(5);
      final roles = <HexRole>{};
      for (var i = 0; i < 80; i++) {
        final wave = LureWave.build(es, random: rng)!;
        roles.add(
            wave.sentence.slots.firstWhere((s) => s.index == wave.gap).role);
      }
      expect(roles, containsAll([HexRole.verb, HexRole.object]));
    });

    test('never lights the same sentence twice running', () {
      final rng = Random(7);
      var last = LureWave.build(es, random: rng)!.sentence;
      for (var i = 0; i < 40; i++) {
        final next = LureWave.build(es, previous: last, random: rng)!.sentence;
        expect(next, isNot(last));
        last = next;
      }
    });

    test('every language the app teaches can be lured', () {
      for (final code in bossTrialSentenceLanguages) {
        expect(LureWave.isPlayable(sentencesFor(code)), isTrue, reason: code);
      }
    });
  });

  group('BubbleWave', () {
    test('the word\'s letters, spares of them and two strays, never already '
        'spelled', () {
      final rng = Random(11);
      for (var i = 0; i < 80; i++) {
        final wave = BubbleWave.build(esWords, random: rng)!;
        expect(wave.letters.join(), wave.word.target);
        expect(
            wave.bubbles,
            hasLength(min(
              AnglerRules.bubbles,
              wave.letters.length * (1 + AnglerRules.maxSpares) +
                  AnglerRules.decoyLetters,
            )));

        // Every letter the word needs is up there, and no letter is up
        // there more than its own count and its spares.
        for (final l in wave.letters.toSet()) {
          final needed = wave.letters.where((x) => x == l).length;
          final up = wave.bubbles.where((x) => x == l).length;
          expect(up, greaterThanOrEqualTo(needed));
          expect(up, lessThanOrEqualTo(needed * (1 + AnglerRules.maxSpares)));
        }

        final own = wave.letters.map((l) => l.toLowerCase()).toSet();
        final strays = [
          for (final b in wave.bubbles)
            if (!own.contains(b.toLowerCase())) b,
        ];
        expect(strays, hasLength(AnglerRules.decoyLetters),
            reason: 'a stray the word has would be right and marked wrong');

        final readInOrder = [
          for (final b in wave.bubbles)
            if (own.contains(b.toLowerCase())) b,
        ].join();
        if (wave.letters.toSet().length > 1) {
          expect(readInOrder, isNot(wave.word.target),
              reason: 'laid out already spelled');
        }
      }
    });

    test('spells on the letter, so a double letter takes either bubble', () {
      const word = TrialWord(target: 'kiss', meaning: 'beso');
      const other = TrialWord(target: 'dog', meaning: 'perro');
      final wave = BubbleWave.build(const [word, other], random: Random(1))!;
      final cast = SpellCast(wave.spell);
      int bubble(String letter, {int skip = 0}) {
        var seen = 0;
        for (var i = 0; i < wave.bubbles.length; i++) {
          if (wave.bubbles[i] == letter && !cast.placed.contains(i)) {
            if (seen++ == skip) return i;
          }
        }
        return -1;
      }

      expect(cast.tap(bubble('i')), SpellTap.fizzle, reason: 'k comes first');
      expect(cast.tap(bubble('k')), SpellTap.placed);
      expect(cast.tap(bubble('i')), SpellTap.placed);
      // The second "s" bubble first: either will do.
      expect(cast.tap(bubble('s', skip: 1)), SpellTap.placed);
      expect(cast.tap(bubble('s')), SpellTap.complete);
    });

    test('splits a word into the letters a reader sees', () {
      expect(BubbleWave.lettersOf('étoile'), ['é', 't', 'o', 'i', 'l', 'e']);
      expect(BubbleWave.lettersOf('고양이'), ['고', '양', '이']);
      expect(BubbleWave.lettersOf('ともだち'), ['と', 'も', 'だ', 'ち']);
      // A phrase, and a word too short to spell, are left out.
      expect(BubbleWave.lettersOf('bánh mì'), isNull);
      expect(BubbleWave.lettersOf('狗'), isNull);
    });

    test('never asks the same word twice running', () {
      final rng = Random(13);
      var last = BubbleWave.build(esWords, random: rng)!.word;
      for (var i = 0; i < 40; i++) {
        final next =
            BubbleWave.build(esWords, previous: last, random: rng)!.word;
        expect(next, isNot(last));
        last = next;
      }
    });

    test('every language the app teaches has words to spell', () {
      for (final code in bossTrialStockLanguages) {
        final pool = wordsFor(code);
        expect(BubbleWave.isPlayable(pool), isTrue, reason: code);
        final wave = BubbleWave.build(pool, random: Random(2))!;
        expect(wave.letters.join(), wave.word.target, reason: code);
        expect(wave.word.target.characters.length,
            inInclusiveRange(AnglerRules.minLetters, AnglerRules.maxLetters),
            reason: code);
      }
    });
  });
}
