import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/boss_trial_sentences.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/utils/boss_trial.dart';
import 'package:shared_preferences/shared_preferences.dart';

TrialSentence sentence(List<String> tokens, [String? meaning]) => TrialSentence(
      tokens: tokens,
      target: tokens.join(' '),
      meaning: meaning ?? 'means ${tokens.join(' ')}',
    );

final List<TrialSentence> pool = [
  sentence(['el', 'gato', 'bebe', 'leche']),
  sentence(['el', 'perro', 'come', 'pan']),
  sentence(['yo', 'leo', 'un', 'libro']),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SpellWave.build', () {
    test('lays out every word of the sentence and one decoy', () {
      final wave = SpellWave.build(pool, random: Random(4))!;
      final tokens = wave.sentence.tokens;
      expect(wave.stones, hasLength(tokens.length + BossTrialRules.decoyStones));
      for (final t in tokens) {
        expect(wave.stones, contains(t));
      }
    });

    test('never offers a decoy matching a word of the sentence', () {
      for (var seed = 0; seed < 60; seed++) {
        final wave = SpellWave.build(pool, random: Random(seed))!;
        final own = wave.sentence.tokens.map((t) => t.toLowerCase()).toSet();
        final extra = [...wave.stones];
        for (final t in wave.sentence.tokens) {
          extra.remove(t);
        }
        for (final decoy in extra) {
          expect(own.contains(decoy.toLowerCase()), isFalse,
              reason: 'seed $seed: "$decoy"');
        }
      }
    });

    test('never lays the stones out already in order', () {
      for (var seed = 0; seed < 200; seed++) {
        final wave = SpellWave.build(pool, random: Random(seed))!;
        final own = wave.sentence.tokens.toSet();
        final inLayout = wave.stones.where(own.contains).join(' ');
        expect(inLayout, isNot(wave.sentence.tokens.join(' ')),
            reason: 'seed $seed');
      }
    });

    test('never casts the same sentence twice running', () {
      var previous = pool.first;
      for (var seed = 0; seed < 40; seed++) {
        final wave =
            SpellWave.build(pool, previous: previous, random: Random(seed))!;
        expect(wave.sentence, isNot(previous));
        previous = wave.sentence;
      }
    });

    test('needs two sentences to play', () {
      expect(TrialSentencePool.isPlayable(pool.take(1).toList()), isFalse);
      expect(TrialSentencePool.isPlayable(pool), isTrue);
    });

    test('leaves out sentences that will not fit the stones', () {
      final built = TrialSentencePool.build([
        ...pool,
        sentence(['solo']),
        sentence(['a', 'b', 'c', 'd', 'e', 'f', 'g']),
        sentence(['un', 'desafortunadamente']),
      ]);
      expect(built, pool);
    });
  });

  group('SpellCast', () {
    SpellCast castFor(TrialSentence s, List<String> stones) =>
        SpellCast(SpellWave(sentence: s, stones: stones));

    test('casts stone by stone and completes on the last', () {
      final cast = castFor(
        sentence(['yo', 'bebo', 'agua']),
        ['agua', 'pan', 'yo', 'bebo'],
      );
      expect(cast.tap(2), SpellTap.placed);
      expect(cast.tap(3), SpellTap.placed);
      expect(cast.tap(0), SpellTap.complete);
      expect(cast.isComplete, isTrue);
      expect(cast.placed, [2, 3, 0]);
      expect(cast.fizzles, 0);
    });

    test('a wrong stone fizzles and changes nothing else', () {
      final cast = castFor(
        sentence(['yo', 'bebo', 'agua']),
        ['agua', 'pan', 'yo', 'bebo'],
      );
      expect(cast.tap(0), SpellTap.fizzle);
      expect(cast.tap(1), SpellTap.fizzle);
      expect(cast.placed, isEmpty);
      expect(cast.fizzles, 2);
      expect(cast.tap(2), SpellTap.placed);
    });

    test('a used stone, a stray index and a finished spell are ignored', () {
      final cast = castFor(sentence(['yo', 'bebo']), ['bebo', 'yo', 'pan']);
      expect(cast.tap(1), SpellTap.placed);
      expect(cast.tap(1), SpellTap.ignored);
      expect(cast.tap(7), SpellTap.ignored);
      expect(cast.tap(0), SpellTap.complete);
      expect(cast.tap(2), SpellTap.ignored);
      expect(cast.fizzles, 0);
    });

    test('a word that appears twice can take either stone first', () {
      final s = sentence(['il', 'gatto', 'beve', 'il', 'latte']);
      final stones = ['il', 'latte', 'il', 'beve', 'gatto'];
      final a = castFor(s, stones);
      expect(a.tap(2), SpellTap.placed);
      expect(a.tap(4), SpellTap.placed);
      expect(a.tap(3), SpellTap.placed);
      expect(a.tap(0), SpellTap.placed);
      expect(a.tap(1), SpellTap.complete);
    });
  });

  group('TrialRun after a sentence is beaten', () {
    test('a fizzle breaks the streak and costs nothing else', () {
      final run = const TrialRun().answerRight(earliness: 0).fizzle();
      expect(run.combo, 0);
      expect(run.bestCombo, 1);
      expect(run.hearts, BossTrialRules.maxHearts);
    });

    test('the attack landing costs a heart and records the sentence once', () {
      final s = pool.first;
      final run = const TrialRun().castFailed(s).castFailed(s);
      expect(run.hearts, BossTrialRules.maxHearts - 2);
      expect(run.missedSentences, [s]);
      expect(run.combo, 0);
    });
  });

  group('bossTrialStockSentences', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('covers every language the app teaches', () {
      final shipped =
          LanguageProvider().availableLanguages.map((l) => l.code).toSet();
      expect(bossTrialSentenceLanguages.toSet(), shipped);
    });

    test('every pairing gives six sentences that fit the stones', () {
      for (final target in bossTrialSentenceLanguages) {
        for (final native in bossTrialSentenceLanguages) {
          if (native == target) continue;
          final built = TrialSentencePool.build(
            bossTrialStockSentences(targetCode: target, nativeCode: native),
          );
          expect(built, hasLength(6), reason: '$target from $native');
          expect(TrialSentencePool.isPlayable(built), isTrue);
        }
      }
    });

    test('every language plays with its decoys never matching its words', () {
      for (final target in bossTrialSentenceLanguages) {
        final built = TrialSentencePool.build(bossTrialStockSentences(
          targetCode: target,
          nativeCode: target == 'en' ? 'es' : 'en',
        ));
        for (var seed = 0; seed < 12; seed++) {
          final wave = SpellWave.build(built, random: Random(seed))!;
          final own = wave.sentence.tokens.map((t) => t.toLowerCase()).toSet();
          final extra = [...wave.stones];
          for (final t in wave.sentence.tokens) {
            extra.remove(t);
          }
          expect(extra.where((d) => own.contains(d.toLowerCase())), isEmpty,
              reason: '$target seed $seed');
        }
      }
    });

    test('writes out unspaced scripts without spaces', () {
      final ja = bossTrialStockSentences(targetCode: 'ja', nativeCode: 'en');
      expect(ja.first.target, 'ねこはミルクをのむ');
      expect(ja.first.meaning, 'the cat drinks milk');
      final fromZh = bossTrialStockSentences(targetCode: 'en', nativeCode: 'zh');
      expect(fromZh.first.meaning, '猫喝牛奶');
    });

    test('gives nothing rather than the wrong thing', () {
      expect(bossTrialStockSentences(targetCode: 'xx', nativeCode: 'en'),
          isEmpty);
      expect(bossTrialStockSentences(targetCode: 'es', nativeCode: 'es'),
          isEmpty);
    });
  });
}
