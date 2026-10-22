import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/boss_trial_sentences.dart';
import 'package:mojilearner_flutter/utils/boss_trial.dart';
import 'package:mojilearner_flutter/utils/boss_trial_witch.dart';

List<TrialSentence> stockFor(String target) => TrialSentencePool.build(
      bossTrialStockSentences(
        targetCode: target,
        nativeCode: target == 'en' ? 'es' : 'en',
      ),
    );

void main() {
  final es = stockFor('es');

  group('WitchRules clocks', () {
    test('tighten from fresh to the end of the round', () {
      expect(
          WitchRules.cloneTime(words: 4, patience: 100).inMilliseconds, 7800);
      expect(WitchRules.cloneTime(words: 4, patience: 50).inMilliseconds, 5200);
      expect(
          WitchRules.tangleTime(words: 6, patience: 100).inMilliseconds, 9800);
      expect(WitchRules.gateTravel(100).inMilliseconds, 3200);
      expect(WitchRules.gateTravel(50).inMilliseconds, 2200);
      expect(WitchRules.gateInterval(100).inMilliseconds, 1600);
      expect(WitchRules.gateInterval(50).inMilliseconds, 1100);
      // Every column's flight, nothing missed, and three seconds spare.
      expect(WitchRules.chaseTime(words: 4, patience: 100).inMilliseconds,
          3200 + 3 * 1600 + 3000);
    });
  });

  group('CloneWave', () {
    test('three owls: her, and two each one word off', () {
      for (var seed = 0; seed < 50; seed++) {
        final wave = CloneWave.build(es, random: Random(seed))!;
        expect(wave.owls, hasLength(WitchRules.owls));
        expect(wave.owls[wave.real], wave.sentence.tokens);
        final clones = [
          for (var i = 0; i < wave.owls.length; i++)
            if (i != wave.real) wave.owls[i],
        ];
        for (final clone in clones) {
          expect(clone, hasLength(wave.sentence.tokens.length));
          final off = [
            for (var i = 0; i < clone.length; i++)
              if (clone[i] != wave.sentence.tokens[i]) i,
          ];
          expect(off, hasLength(1), reason: '$clone');
        }
        expect(clones.first.join(' '), isNot(clones.last.join(' ')));
      }
    });

    test('never says the same sentence twice running', () {
      for (var seed = 0; seed < 50; seed++) {
        final wave =
            CloneWave.build(es, previous: es.first, random: Random(seed))!;
        expect(wave.sentence, isNot(es.first));
      }
    });

    test('every language the app teaches can be cloned', () {
      for (final code in bossTrialSentenceLanguages) {
        expect(CloneWave.isPlayable(stockFor(code)), isTrue, reason: code);
      }
    });
  });

  group('TangleWave', () {
    test('every word goes to exactly one of the two spells', () {
      for (var seed = 0; seed < 50; seed++) {
        final wave = TangleWave.build(es, random: Random(seed))!;
        expect(wave.first.meaning, isNot(wave.second.meaning));
        expect(
            wave.words.length, greaterThanOrEqualTo(WitchRules.minTangleWords));
        for (final w in wave.words) {
          final inFirst = wave.first.tokens.contains(w.word);
          final inSecond = wave.second.tokens.contains(w.word);
          expect(inFirst != inSecond, isTrue, reason: w.word);
          expect(w.first, inFirst);
        }
      }
    });

    test('the second spell shares the most it can with the first', () {
      for (var seed = 0; seed < 50; seed++) {
        final wave = TangleWave.build(es, random: Random(seed))!;
        final shared =
            wave.second.concepts.intersection(wave.first.concepts).length;
        final best = es
            .where((s) => s.meaning != wave.first.meaning)
            .map((s) => s.concepts.intersection(wave.first.concepts).length)
            .reduce(max);
        expect(shared, best);
      }
    });

    test('every language the app teaches can be tangled', () {
      for (final code in bossTrialSentenceLanguages) {
        expect(TangleWave.isPlayable(stockFor(code)), isTrue, reason: code);
      }
    });
  });

  group('ChaseWave', () {
    test('a decoy for every word, never one of the sentence\'s own', () {
      for (var seed = 0; seed < 50; seed++) {
        final wave = ChaseWave.build(es, random: Random(seed))!;
        final own = wave.sentence.tokens.map((t) => t.toLowerCase()).toSet();
        expect(wave.decoys, hasLength(wave.sentence.tokens.length));
        for (final d in wave.decoys) {
          expect(own, isNot(contains(d.toLowerCase())));
        }
        final rng = Random(seed);
        for (var i = 0; i < wave.sentence.tokens.length; i++) {
          final gate = wave.gate(i, rng);
          expect(gate.word, wave.sentence.tokens[i]);
          expect(gate.decoy, wave.decoys[i]);
        }
      }
    });

    test('decoys are the closest spelling on offer', () {
      final wave = ChaseWave.build(es, random: Random(0))!;
      final own = wave.sentence.tokens.map((t) => t.toLowerCase()).toSet();
      final offered = {
        for (final s in es)
          if (s != wave.sentence)
            for (final t in s.tokens)
              if (!own.contains(t.toLowerCase())) t,
      };
      for (var i = 0; i < wave.decoys.length; i++) {
        final token = wave.sentence.tokens[i];
        final best = offered
            .map((t) => SpellWave.spellingDistance(t, token))
            .reduce(min);
        expect(SpellWave.spellingDistance(wave.decoys[i], token), best);
      }
    });
  });

  group('TrialRun.castFailed', () {
    test('a tangle left undone costs one heart and lists both spells', () {
      final run = const TrialRun().castFailed(es[0], also: [es[1]]);
      expect(run.hearts, BossTrialRules.maxHearts - 1);
      expect(run.missedSentences, [es[0], es[1]]);
      final again = run.castFailed(es[1], also: [es[0]]);
      expect(again.missedSentences, [es[0], es[1]]);
    });
  });
}
