import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/boss_trial_sentences.dart';
import 'package:mojilearner_flutter/constants/boss_trial_words.dart';
import 'package:mojilearner_flutter/utils/boss_trial.dart';
import 'package:mojilearner_flutter/utils/boss_trial_angler.dart';
import 'package:mojilearner_flutter/utils/boss_trial_crystal.dart';
import 'package:mojilearner_flutter/utils/boss_trial_sphinx.dart';

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

/// The fourth games of Amethyst, Lanternmaw and Sableth — the Vein, the Net
/// and the Sandstorm — which work in every language the app teaches.
void main() {
  group('Vein', () {
    test('the sentence runs through neighbouring crystals, in order', () {
      final pool = sentencesFor('es');
      final rng = Random(1);
      for (var i = 0; i < 80; i++) {
        final wave = VeinWave.build(pool, random: rng)!;
        expect(wave.cells, hasLength(VeinWave.side * VeinWave.side));
        expect(wave.path.toSet(), hasLength(wave.path.length),
            reason: 'the vein crosses itself');
        for (var k = 0; k < wave.path.length; k++) {
          expect(wave.cells[wave.path[k]], wave.sentence.tokens[k]);
          if (k > 0) {
            expect(
                VeinWave.neighbours(wave.path[k - 1]), contains(wave.path[k]));
          }
        }
        // Off the vein, no crystal has one of the sentence's words.
        final own = wave.sentence.tokens.map((t) => t.toLowerCase()).toSet();
        for (var c = 0; c < wave.cells.length; c++) {
          if (wave.path.contains(c)) continue;
          expect(own.contains(wave.cells[c].toLowerCase()), isFalse,
              reason: wave.cells[c]);
        }
      }
    });

    test(
        'a word the sentence has twice never sits beside the step before '
        'its first', () {
      // Italian says "il" twice in "il gatto beve il latte".
      final pool = sentencesFor('it');
      final rng = Random(2);
      for (var i = 0; i < 120; i++) {
        final wave = VeinWave.build(pool, random: rng)!;
        final t = wave.sentence.tokens;
        for (var k = 1; k < wave.path.length; k++) {
          for (var j = 0; j < wave.path.length; j++) {
            if (j == k || t[j] != t[k]) continue;
            expect(VeinWave.neighbours(wave.path[k - 1]),
                isNot(contains(wave.path[j])));
          }
        }
      }
    });

    test('only the next crystal of the vein lights', () {
      final wave = VeinWave.build(sentencesFor('en'), random: Random(3))!;
      final play = VeinPlay(wave);
      final stray =
          List.generate(16, (i) => i).firstWhere((c) => !wave.path.contains(c));
      expect(play.tap(stray), VeinTap.wrong);
      expect(play.tap(wave.path.last), VeinTap.wrong);
      for (var k = 0; k < wave.path.length; k++) {
        expect(play.tap(wave.path[k]),
            k == wave.path.length - 1 ? VeinTap.done : VeinTap.next);
      }
      expect(play.isDone, isTrue);
    });

    test('every language the app teaches has a vein', () {
      for (final code in bossTrialSentenceLanguages) {
        final pool = sentencesFor(code);
        expect(VeinWave.isPlayable(pool), isTrue, reason: code);
        expect(VeinWave.build(pool, random: Random(4)), isNotNull,
            reason: code);
      }
    });
  });

  group('Net', () {
    test('every word of the sentence swims, with strays that are not in it',
        () {
      final pool = sentencesFor('es');
      final rng = Random(5);
      for (var i = 0; i < 60; i++) {
        final wave = NetWave.build(pool, random: rng)!;
        expect(wave.fish.length, lessThanOrEqualTo(AnglerRules.netMostFish));
        final own = [
          for (final (w, inIt) in wave.fish)
            if (inIt) w
        ];
        expect([...own]..sort(), [...wave.sentence.tokens]..sort());
        final strays = [
          for (final (w, inIt) in wave.fish)
            if (!inIt) w
        ];
        expect(strays.length, greaterThanOrEqualTo(AnglerRules.netStrays));
        for (final s in strays) {
          expect(wave.sentence.tokens.map((t) => t.toLowerCase()),
              isNot(contains(s.toLowerCase())));
        }
      }
    });

    test('netting a stray scares it off; netting them all is done', () {
      final wave = NetWave.build(sentencesFor('en'), random: Random(6))!;
      final play = NetPlay(wave);
      final stray = wave.fish.indexWhere((f) => !f.$2);
      expect(play.tap(stray), NetTap.stray);
      expect(play.tap(stray), NetTap.ignored);
      final own = [
        for (var i = 0; i < wave.fish.length; i++)
          if (wave.fish[i].$2) i,
      ];
      for (final i in own) {
        expect(play.tap(i), i == own.last ? NetTap.done : NetTap.netted);
      }
    });

    test('every language the app teaches can be netted', () {
      for (final code in bossTrialSentenceLanguages) {
        expect(NetWave.isPlayable(sentencesFor(code)), isTrue, reason: code);
      }
    });
  });

  group('Sandstorm', () {
    test('the word lies once along a row or down a column', () {
      final pool = wordsFor('tr');
      final rng = Random(7);
      for (var i = 0; i < 80; i++) {
        final wave = StormWave.build(pool, random: rng)!;
        expect(wave.grid, hasLength(StormWave.cols * StormWave.rows));
        final letters = BubbleWave.lettersOf(wave.word.target)!;
        expect([for (final c in wave.cells) wave.grid[c]], letters);
        expect(StormWave.line(wave.cells.first, wave.cells.last), wave.cells);
      }
    });

    test('a swipe finds it either way, and only exactly over it', () {
      final wave = StormWave.build(wordsFor('en'), random: Random(8))!;
      expect(wave.found(wave.cells), isTrue);
      expect(wave.found(wave.cells.reversed.toList()), isTrue);
      expect(wave.found(wave.cells.sublist(1)), isFalse);
      expect(StormWave.line(0, StormWave.cols + 1), isNull,
          reason: 'diagonals are not a line');
    });

    test('every language the app teaches has words to find', () {
      for (final code in bossTrialStockLanguages) {
        final pool = wordsFor(code);
        expect(StormWave.isPlayable(pool), isTrue, reason: code);
        expect(StormWave.build(pool, random: Random(9)), isNotNull,
            reason: code);
      }
    });
  });
}
