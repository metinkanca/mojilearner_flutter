import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/boss_trial_sentences.dart';
import 'package:mojilearner_flutter/utils/boss_trial.dart';

/// A sentence hexable at [slots], each (index, role, concept).
TrialSentence sentence(
  List<String> tokens, [
  List<(int, HexRole, String)> slots = const [],
]) =>
    TrialSentence(
      tokens: tokens,
      target: tokens.join(' '),
      meaning: 'means ${tokens.join(' ')}',
      slots: [
        for (final (index, role, concept) in slots)
          HexSlot(index: index, role: role, concept: concept),
      ],
    );

final List<TrialSentence> pool = [
  sentence(['el', 'gato', 'bebe', 'leche'], [
    (1, HexRole.subject, 'cat'),
    (2, HexRole.verb, 'drink'),
    (3, HexRole.object, 'milk'),
  ]),
  sentence(['el', 'perro', 'come', 'pan'], [
    (1, HexRole.subject, 'dog'),
    (2, HexRole.verb, 'eat'),
    (3, HexRole.object, 'bread'),
  ]),
  sentence(['yo', 'bebo', 'agua'], [
    (1, HexRole.verb, 'drink'),
    (2, HexRole.object, 'water'),
  ]),
];

/// The indices where [scroll] differs from what it should say.
List<int> differences(HexScroll scroll) => [
      for (var i = 0; i < scroll.words.length; i++)
        if (scroll.words[i] != scroll.sentence.tokens[i]) i,
    ];

List<TrialSentence> stockFor(String target) => TrialSentencePool.build(
      bossTrialStockSentences(
        targetCode: target,
        nativeCode: target == 'en' ? 'es' : 'en',
      ),
    );

void main() {
  group('BossTrialRules.fuseTime', () {
    test('gives four words six seconds, tightening to four', () {
      expect(
        BossTrialRules.fuseTime(words: 4, patience: 100).inMilliseconds,
        6000,
      );
      expect(
        BossTrialRules.fuseTime(
          words: 4,
          patience: BossTrialRules.spellPhaseAt,
        ).inMilliseconds,
        4000,
      );
    });

    test('gives a longer scroll longer', () {
      expect(
        BossTrialRules.fuseTime(words: 6, patience: 80) >
            BossTrialRules.fuseTime(words: 3, patience: 80),
        isTrue,
      );
    });

    test('a guess through four words burns the fuse out; one slip does not',
        () {
      expect(3 * BossTrialRules.hexMistakeBurn, lessThan(1));
      expect(BossTrialRules.hexMistakeBurn, lessThan(0.5));
      // Three wrong words plus the time taken to tap them runs it out.
      expect(3 * BossTrialRules.hexMistakeBurn + 0.25, greaterThanOrEqualTo(1));
    });
  });

  group('HexScroll.build', () {
    test('swaps exactly one word, at the slot it says', () {
      for (var seed = 0; seed < 80; seed++) {
        final scroll = HexScroll.build(pool, random: Random(seed))!;
        expect(differences(scroll), [scroll.hexed], reason: 'seed $seed');
        expect(scroll.trueWord, scroll.sentence.tokens[scroll.hexed]);
      }
    });

    test('swaps in the same part of another sentence, never a synonym', () {
      for (var seed = 0; seed < 120; seed++) {
        final scroll = HexScroll.build(pool, random: Random(seed))!;
        final slot =
            scroll.sentence.slots.firstWhere((s) => s.index == scroll.hexed);
        final donors = [
          for (final other in pool)
            if (other != scroll.sentence)
              for (final theirs in other.slots)
                if (other.tokens[theirs.index] == scroll.hexWord) theirs,
        ];
        expect(donors, isNotEmpty, reason: 'seed $seed');
        for (final donor in donors) {
          expect(donor.role, slot.role, reason: 'seed $seed');
          expect(donor.concept, isNot(slot.concept), reason: 'seed $seed');
        }
      }
    });

    test('never swaps "bebo" for "bebe": the same verb is not a hex', () {
      for (var seed = 0; seed < 120; seed++) {
        final scroll = HexScroll.build(pool, random: Random(seed))!;
        if (scroll.sentence.tokens.contains('bebo')) {
          expect(scroll.words, isNot(contains('bebe')), reason: 'seed $seed');
        }
      }
    });

    test('never swaps in a word the sentence already has', () {
      for (var seed = 0; seed < 120; seed++) {
        final scroll = HexScroll.build(pool, random: Random(seed))!;
        final own = scroll.sentence.tokens.map((t) => t.toLowerCase());
        expect(own, isNot(contains(scroll.hexWord.toLowerCase())),
            reason: 'seed $seed');
      }
    });

    test('hexes verbs and subjects as well as objects', () {
      final roles = <HexRole>{};
      for (var seed = 0; seed < 200; seed++) {
        final scroll = HexScroll.build(pool, random: Random(seed))!;
        roles.add(scroll.sentence.slots
            .firstWhere((s) => s.index == scroll.hexed)
            .role);
      }
      expect(roles, HexRole.values.toSet());
    });

    test('never reads the same sentence twice running', () {
      var previous = pool.first;
      for (var seed = 0; seed < 40; seed++) {
        final scroll =
            HexScroll.build(pool, previous: previous, random: Random(seed))!;
        expect(scroll.sentence, isNot(previous));
        previous = scroll.sentence;
      }
    });

    test('needs two hexable sentences to play', () {
      expect(HexScroll.isPlayable(pool.take(1).toList()), isFalse);
      expect(HexScroll.isPlayable(pool), isTrue);
      // Sentences with no slots can be cast but never hexed.
      final plain = [
        sentence(['el', 'gato', 'bebe', 'leche']),
        sentence(['yo', 'bebo', 'agua']),
      ];
      expect(HexScroll.isPlayable(plain), isFalse);
      expect(HexScroll.build(plain), isNull);
    });
  });

  group('HexRead', () {
    final scroll = HexScroll(
      sentence: pool.first,
      words: ['el', 'gato', 'bebe', 'pan'],
      hexed: 3,
    );

    test('a wrong word is marked once, then the hex breaks', () {
      final read = HexRead(scroll);
      expect(read.tap(1), HexTap.wrong);
      expect(read.tap(1), HexTap.ignored);
      expect(read.wrong, {1});
      expect(read.isBroken, isFalse);
      expect(read.tap(3), HexTap.broken);
      expect(read.isBroken, isTrue);
    });

    test('ignores everything once broken, and stray indices', () {
      final read = HexRead(scroll);
      expect(read.tap(9), HexTap.ignored);
      expect(read.tap(-1), HexTap.ignored);
      expect(read.tap(3), HexTap.broken);
      expect(read.tap(0), HexTap.ignored);
      expect(read.wrong, isEmpty);
    });
  });

  group('TrialRun in the Hexed Scroll round', () {
    final scroll = HexScroll(
      sentence: pool.first,
      words: ['el', 'gato', 'bebe', 'pan'],
      hexed: 3,
    );

    test('a broken hex is worth a catch, and counts on its own', () {
      final run = const TrialRun().hexBroken(earliness: 1);
      expect(run.lastDamage, BossTrialRules.damage(combo: 1, earliness: 1));
      expect(run.patience,
          BossTrialRules.maxPatience - BossTrialRules.damage(combo: 1, earliness: 1));
      expect(run.broken, 1);
      expect(run.caught, 0);
      expect(run.combo, 1);
    });

    test('the streak carries on from a catch', () {
      final run = const TrialRun()
          .answerRight(earliness: 0)
          .hexBroken(earliness: 0)
          .hexBroken(earliness: 0);
      expect(run.combo, 3);
      expect(run.bestCombo, 3);
    });

    test('a fuse running out costs a heart and records the scroll once', () {
      final other = HexScroll(
        sentence: pool.first,
        words: ['el', 'perro', 'bebe', 'leche'],
        hexed: 1,
      );
      final run = const TrialRun().hexLanded(scroll).hexLanded(other);
      expect(run.hearts, BossTrialRules.maxHearts - 2);
      expect(run.missedScrolls, [scroll]);
      expect(run.combo, 0);
    });
  });

  group('near-miss decoys', () {
    test('spellingDistance', () {
      expect(SpellWave.spellingDistance('bebo', 'bebo'), 0);
      expect(SpellWave.spellingDistance('Bebo', 'bebo'), 0);
      expect(SpellWave.spellingDistance('bebo', 'bebe'), 0.25);
      expect(SpellWave.spellingDistance('trinke', 'trinkt'), closeTo(1 / 6, 1e-9));
      expect(SpellWave.spellingDistance('ab', 'cd'), 1);
      expect(SpellWave.spellingDistance('', 'abc'), 1);
    });

    test('lays out as many decoys as asked, none matching a word', () {
      final stock = stockFor('es');
      for (var seed = 0; seed < 40; seed++) {
        final wave = SpellWave.build(
          stock,
          random: Random(seed),
          decoys: BossTrialRules.nearMissDecoyStones,
          nearMiss: true,
        )!;
        final own = wave.sentence.tokens.map((t) => t.toLowerCase()).toSet();
        final extra = [...wave.stones];
        for (final t in wave.sentence.tokens) {
          extra.remove(t);
        }
        expect(extra, hasLength(BossTrialRules.nearMissDecoyStones));
        expect(extra.where((d) => own.contains(d.toLowerCase())), isEmpty,
            reason: 'seed $seed');
      }
    });

    test('lays the other form of the verb beside the real one', () {
      const expected = {
        'es': ('bebo', 'bebe'),
        'de': ('trinke', 'trinkt'),
        'fr': ('bois', 'boit'),
        'it': ('bevo', 'beve'),
        'pt': ('bebo', 'bebe'),
        'ru': ('пью', 'пьёт'),
      };
      for (final MapEntry(key: code, value: (verb, trap))
          in expected.entries) {
        final stock = stockFor(code);
        final drinking = stock.firstWhere((s) => s.tokens.contains(verb));
        var seen = 0;
        for (var seed = 0; seed < 200; seed++) {
          final wave = SpellWave.build(
            stock,
            random: Random(seed),
            decoys: BossTrialRules.nearMissDecoyStones,
            nearMiss: true,
          )!;
          if (wave.sentence != drinking) continue;
          seen++;
          expect(wave.stones, contains(trap), reason: '$code seed $seed');
        }
        expect(seen, greaterThan(0), reason: code);
      }
    });

    test('without nearMiss, decoys are still one and random', () {
      final stock = stockFor('es');
      final wave = SpellWave.build(stock, random: Random(3))!;
      expect(wave.stones,
          hasLength(wave.sentence.tokens.length + BossTrialRules.decoyStones));
    });
  });

  group('the stock sentences as scrolls', () {
    test('every language can be hexed, from every other', () {
      for (final target in bossTrialSentenceLanguages) {
        for (final native in bossTrialSentenceLanguages) {
          if (native == target) continue;
          final built = TrialSentencePool.build(
            bossTrialStockSentences(targetCode: target, nativeCode: native),
          );
          expect(HexScroll.isPlayable(built), isTrue,
              reason: '$target from $native');
        }
      }
    });

    test('every row marks a verb and an object, and a subject where it has one',
        () {
      for (final target in bossTrialSentenceLanguages) {
        final stock = stockFor(target);
        expect(stock, hasLength(6), reason: target);
        for (var row = 0; row < stock.length; row++) {
          final roles = stock[row].slots.map((s) => s.role).toList();
          expect(roles, contains(HexRole.verb), reason: '$target row $row');
          expect(roles, contains(HexRole.object), reason: '$target row $row');
          // Rows 0, 1 and 3 have a noun subject: the cat, the dog, a friend.
          expect(roles.contains(HexRole.subject), {0, 1, 3}.contains(row),
              reason: '$target row $row');
        }
      }
    });

    test('marks each part on a different word', () {
      for (final target in bossTrialSentenceLanguages) {
        for (final s in stockFor(target)) {
          final at = s.slots.map((slot) => slot.index).toList();
          expect(at.toSet(), hasLength(at.length), reason: s.target);
        }
      }
    });

    test('every scroll in every language differs by exactly one word', () {
      for (final target in bossTrialSentenceLanguages) {
        final stock = stockFor(target);
        for (var seed = 0; seed < 20; seed++) {
          final scroll = HexScroll.build(stock, random: Random(seed))!;
          expect(differences(scroll), [scroll.hexed],
              reason: '$target seed $seed');
        }
      }
    });
  });
}
