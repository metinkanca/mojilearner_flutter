import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/utils/boss_trial.dart';
import 'package:mojilearner_flutter/utils/boss_trial_moss.dart';

TrialWord word(String target, String meaning) =>
    TrialWord(target: target, meaning: meaning);

final List<TrialWord> words = [
  word('gato', 'cat'),
  word('perro', 'dog'),
  word('casa', 'house'),
  word('agua', 'water'),
  word('pan', 'bread'),
  word('libro', 'book'),
];

void main() {
  group('MossRules clocks', () {
    test('tighten from fresh to the end of the round', () {
      expect(MossRules.revealTime(100).inMilliseconds, 2400);
      expect(MossRules.revealTime(50).inMilliseconds, 1600);
      expect(MossRules.swapCount(100), 3);
      expect(MossRules.swapCount(50), 6);
      expect(MossRules.swapTime(100).inMilliseconds, 500);
      expect(MossRules.swapTime(50).inMilliseconds, 330);
      expect(MossRules.popUp(100).inMilliseconds, 1800);
      expect(MossRules.popUp(50).inMilliseconds, 1100);
      expect(MossRules.popInterval(100).inMilliseconds, 900);
      expect(MossRules.popInterval(50).inMilliseconds, 600);
      expect(MossRules.sinkTime(100).inMilliseconds, 5000);
      expect(MossRules.sinkTime(50).inMilliseconds, 3200);
    });
  });

  group('ShellGame', () {
    test('three cups with different meanings, one the word shouted', () {
      for (var seed = 0; seed < 50; seed++) {
        final game = ShellGame.build(words, random: Random(seed), swaps: 4)!;
        expect(game.cups, hasLength(MossRules.cups));
        expect(game.cups.map((w) => w.meaning).toSet(), hasLength(3));
        expect(game.cups[game.answer], game.prompt);
        expect(game.swaps, hasLength(4));
        for (final (a, b) in game.swaps) {
          expect(a, isNot(b));
          expect([a, b].every((p) => p >= 0 && p < MossRules.cups), isTrue);
        }
      }
    });

    test('follows the cups through the shuffle', () {
      final game = ShellGame(
        prompt: words[0],
        cups: words.take(3).toList(),
        swaps: const [(0, 1), (1, 2)],
      );
      expect(game.placesAfter(0), [0, 1, 2]);
      expect(game.placesAfter(1), [1, 0, 2]);
      // Places 1 and 2 trade: cup 0 was in 1, cup 2 in 2.
      expect(game.placesAfter(2), [2, 0, 1]);
    });

    test('the shuffle always ends with every cup in a place of its own', () {
      for (var seed = 0; seed < 50; seed++) {
        final game = ShellGame.build(words, random: Random(seed), swaps: 6)!;
        expect(game.placesAfter(6).toSet(), {0, 1, 2});
      }
    });

    test('never shouts the same word twice running', () {
      for (var seed = 0; seed < 50; seed++) {
        final game =
            ShellGame.build(words, previous: words[0], random: Random(seed))!;
        expect(game.prompt, isNot(words[0]));
      }
    });

    test('needs three different meanings', () {
      expect(ShellGame.build(words.take(2).toList()), isNull);
    });
  });

  group('PebbleWave', () {
    test('the word asked for pops twice, never first', () {
      for (var seed = 0; seed < 100; seed++) {
        final wave = PebbleWave.build(words, random: Random(seed))!;
        expect(wave.pops, hasLength(MossRules.popsPerWave));
        final right = [
          for (var i = 0; i < wave.pops.length; i++)
            if (wave.isRight(wave.pops[i])) i,
        ];
        expect(right, hasLength(2));
        expect(right.first, isNot(0));
      }
    });

    test('no decoy means the same as the word asked for', () {
      final pool = [...words, word('hogar', 'house')];
      for (var seed = 0; seed < 100; seed++) {
        final wave = PebbleWave.build(pool, random: Random(seed))!;
        for (final pop in wave.pops) {
          if (wave.isRight(pop)) continue;
          expect(pop.word.meaning, isNot(wave.prompt.meaning));
        }
      }
    });

    test('never pops out of a hole either of the two before used', () {
      for (var seed = 0; seed < 100; seed++) {
        final pops = PebbleWave.build(words, random: Random(seed))!.pops;
        for (var i = 1; i < pops.length; i++) {
          expect(pops[i].hole, isNot(pops[i - 1].hole));
          if (i > 1) expect(pops[i].hole, isNot(pops[i - 2].hole));
        }
      }
    });
  });

  group('Crossing', () {
    test('rows of three stones with different meanings', () {
      for (var seed = 0; seed < 50; seed++) {
        final crossing = Crossing.build(words, random: Random(seed))!;
        expect(crossing.rows, hasLength(MossRules.rows));
        for (final row in crossing.rows) {
          expect(row.stones, hasLength(MossRules.stonesPerRow));
          expect(row.stones.map((w) => w.meaning).toSet(), hasLength(3));
          expect(row.stones[row.answer], row.prompt);
          expect(row.lanes, [...row.lanes]..sort());
          expect(row.lanes.toSet(), hasLength(3));
        }
      }
    });

    test('the right stone is never straight up from the last one', () {
      for (var seed = 0; seed < 100; seed++) {
        final rows = Crossing.build(words, random: Random(seed))!.rows;
        for (var r = 1; r < rows.length; r++) {
          expect(
            rows[r].lanes[rows[r].answer],
            isNot(rows[r - 1].lanes[rows[r - 1].answer]),
          );
        }
      }
    });

    test('each row shouts a different word while the pool allows', () {
      for (var seed = 0; seed < 50; seed++) {
        final rows = Crossing.build(words, random: Random(seed))!.rows;
        expect(rows.map((r) => r.prompt).toSet(), hasLength(rows.length));
      }
    });
  });

  group('TrialRun.crossed', () {
    test('lands every hop at once, each worth its place in the streak', () {
      final run = const TrialRun().crossed(const [1, 1, 0, 0]);
      final expected = [
        for (final (i, e) in const [1.0, 1.0, 0.0, 0.0].indexed)
          BossTrialRules.shardDamage(combo: i + 1, earliness: e),
      ].reduce((a, b) => a + b);
      expect(run.lastDamage, expected);
      expect(run.patience, 100 - expected);
      expect(run.caught, 4);
      expect(run.combo, 4);
      expect(run.bestCombo, 4);
    });
  });
}
