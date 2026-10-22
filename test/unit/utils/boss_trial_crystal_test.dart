import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/boss_trial_advanced.dart';
import 'package:mojilearner_flutter/constants/boss_trial_sentences.dart';
import 'package:mojilearner_flutter/constants/boss_trial_words.dart';
import 'package:mojilearner_flutter/utils/boss_trial.dart';
import 'package:mojilearner_flutter/utils/boss_trial_crystal.dart';

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

TrialSentence sentence(String meaning, Set<String> concepts) => TrialSentence(
      tokens: meaning.split(' '),
      target: meaning,
      meaning: meaning,
      concepts: concepts,
    );

final List<TrialSentence> sentences = [
  sentence('the cat drinks milk', {'cat', 'drink', 'milk'}),
  sentence('the dog eats bread', {'dog', 'eat', 'bread'}),
  sentence('I read a book', {'me', 'read', 'book'}),
  sentence('my friend has a house', {'friend', 'have', 'house'}),
  sentence('I drink water', {'me', 'drink', 'water'}),
  sentence('I see a star', {'me', 'see', 'star'}),
];

void main() {
  group('CrystalRules clocks', () {
    test('the first spike takes 8.5s fresh and each after it 2.2s more', () {
      expect(
        CrystalRules.spikeTime(rank: 0, patience: 100).inMilliseconds,
        8500,
      );
      expect(
        CrystalRules.spikeTime(rank: 3, patience: 100).inMilliseconds,
        15100,
      );
    });

    test('spikes tighten to 6.5s and 1.6s by the end of the round', () {
      expect(
        CrystalRules.spikeTime(rank: 0, patience: 50).inMilliseconds,
        6500,
      );
      expect(
        CrystalRules.spikeTime(rank: 3, patience: 50).inMilliseconds,
        11300,
      );
      // And never past it, whatever the patience.
      expect(
        CrystalRules.spikeTime(rank: 0, patience: 10).inMilliseconds,
        6500,
      );
    });

    test('a four-word echo gives 6.3s, tightening to 4.2s', () {
      expect(
        CrystalRules.echoTime(words: 4, patience: 100).inMilliseconds,
        6300,
      );
      expect(
        CrystalRules.echoTime(words: 4, patience: 50).inMilliseconds,
        4200,
      );
    });

    test('shards fly 3.4s and come every 1.3s, down to 2.4s and 0.9s', () {
      expect(CrystalRules.shardFlight(100).inMilliseconds, 3400);
      expect(CrystalRules.shardFlight(50).inMilliseconds, 2400);
      expect(CrystalRules.shardInterval(100).inMilliseconds, 1300);
      expect(CrystalRules.shardInterval(50).inMilliseconds, 900);
    });
  });

  group('SpikeWave.build', () {
    test('four spikes with different meanings, and a gem for each', () {
      for (var seed = 0; seed < 50; seed++) {
        final wave = SpikeWave.build(words, random: Random(seed))!;
        expect(wave.spikes, hasLength(BossTrialRules.wordsPerWave));
        expect(
          wave.spikes.map((w) => w.meaning).toSet(),
          hasLength(BossTrialRules.wordsPerWave),
        );
        expect(wave.gems.toSet(), wave.spikes.toSet());
        expect(wave.ranks.toSet(), {0, 1, 2, 3});
      }
    });

    test('never lays a gem straight under its own spike', () {
      for (var seed = 0; seed < 200; seed++) {
        final wave = SpikeWave.build(words, random: Random(seed))!;
        for (var lane = 0; lane < wave.spikes.length; lane++) {
          expect(wave.gemFor(lane), isNot(lane), reason: 'seed $seed');
        }
      }
    });

    test('prefers words the last wave did not have', () {
      final last = words.take(4).toList();
      for (var seed = 0; seed < 50; seed++) {
        final wave =
            SpikeWave.build(words, previous: last, random: Random(seed))!;
        // Six words, four of them just thrown: both fresh ones are in.
        expect(wave.spikes, containsAll(words.skip(4)));
      }
    });

    test('needs four different meanings', () {
      expect(SpikeWave.build(words.take(3).toList()), isNull);
      expect(
        SpikeWave.build([...words.take(3), word('hogar', 'house')]),
        isNull,
      );
    });
  });

  group('SpikeRush', () {
    SpikeRush rush() => SpikeRush(SpikeWave.build(words, random: Random(1))!);

    test('a spike and its gem, in either order, shatter together', () {
      final r = rush();
      expect(r.tapSpike(0), SpikeTap.held);
      expect(r.heldSpike, 0);
      expect(r.tapGem(r.wave.gemFor(0)), SpikeTap.matched);
      expect(r.isShattered(0), isTrue);
      expect(r.isGemUsed(r.wave.gemFor(0)), isTrue);

      expect(r.tapGem(r.wave.gemFor(1)), SpikeTap.held);
      expect(r.tapSpike(1), SpikeTap.matched);
      expect(r.lastPair, (1, r.wave.gemFor(1)));
      expect(r.heldSpike, isNull);
      expect(r.heldGem, isNull);
    });

    test('a wrong pair shatters nothing and lets go of both', () {
      final r = rush();
      final wrong = r.wave.gemFor(1);
      r.tapSpike(0);
      expect(r.tapGem(wrong), SpikeTap.mismatched);
      expect(r.lastPair, (0, wrong));
      expect(r.isShattered(0), isFalse);
      expect(r.isGemUsed(wrong), isFalse);
      expect(r.heldSpike, isNull);
      expect(r.heldGem, isNull);
    });

    test('tapping the held one again puts it down; another swaps it', () {
      final r = rush();
      r.tapSpike(0);
      expect(r.tapSpike(0), SpikeTap.dropped);
      expect(r.heldSpike, isNull);
      r.tapSpike(0);
      expect(r.tapSpike(2), SpikeTap.held);
      expect(r.heldSpike, 2);
    });

    test('shattered spikes and thrown gems take no more taps', () {
      final r = rush();
      r.tapSpike(0);
      r.tapGem(r.wave.gemFor(0));
      expect(r.tapSpike(0), SpikeTap.ignored);
      expect(r.tapGem(r.wave.gemFor(0)), SpikeTap.ignored);
      expect(r.tapSpike(9), SpikeTap.ignored);
    });

    test('is cleared once every spike is matched', () {
      final r = rush();
      for (var lane = 0; lane < r.wave.spikes.length; lane++) {
        expect(r.isCleared, isFalse);
        r.tapSpike(lane);
        r.tapGem(r.wave.gemFor(lane));
      }
      expect(r.isCleared, isTrue);
    });
  });

  group('EchoWave.build', () {
    test('offers three different meanings, one of them what it said', () {
      for (var seed = 0; seed < 50; seed++) {
        final wave = EchoWave.build(sentences, random: Random(seed))!;
        expect(wave.options, hasLength(CrystalRules.echoOptions));
        expect(wave.options.map((s) => s.meaning).toSet(), hasLength(3));
        expect(wave.options[wave.answer], wave.sentence);
      }
    });

    test('the wrong meanings share the most with what it said', () {
      final drinkWater = sentences[4];
      var seen = 0;
      for (var seed = 0; seed < 200; seed++) {
        final wave = EchoWave.build(sentences, random: Random(seed))!;
        if (wave.sentence != drinkWater) continue;
        seen++;
        // "I drink water" shares one concept with the cat's milk and the two
        // other "I" sentences, none with the dog's bread or the friend's
        // house.
        for (final option in wave.options) {
          expect(option.meaning, isNot(contains('dog')));
          expect(option.meaning, isNot(contains('friend')));
        }
      }
      expect(seen, greaterThan(10));
    });

    test('never roars the same sentence twice running', () {
      for (var seed = 0; seed < 50; seed++) {
        final wave = EchoWave.build(
          sentences,
          previous: sentences[0],
          random: Random(seed),
        )!;
        expect(wave.sentence, isNot(sentences[0]));
      }
    });

    test('needs three different meanings', () {
      expect(EchoWave.isPlayable(sentences.take(2).toList()), isFalse);
      expect(EchoWave.isPlayable(sentences.take(3).toList()), isTrue);
      expect(EchoWave.build(sentences.take(2).toList()), isNull);
    });

    test('every stock sentence knows what it is about', () {
      final stock = bossTrialStockSentences(targetCode: 'es', nativeCode: 'en');
      expect(stock.first.concepts, {'cat', 'drink', 'milk'});
      expect(
        stock.firstWhere((s) => s.meaning == 'I drink water').concepts,
        {'me', 'drink', 'water'},
      );
      expect(stock.every((s) => s.concepts.length == 3), isTrue);
    });
  });

  group('EchoListen', () {
    test('a wrong crystal is refused once; the right one is heard', () {
      final wave = EchoWave.build(sentences, random: Random(3))!;
      final listen = EchoListen(wave);
      final wrong = (wave.answer + 1) % wave.options.length;
      expect(listen.tap(wrong), EchoTap.wrong);
      expect(listen.tap(wrong), EchoTap.ignored);
      expect(listen.wrong, {wrong});
      expect(listen.tap(wave.answer), EchoTap.heard);
      expect(listen.isHeard, isTrue);
      expect(listen.tap(wave.answer), EchoTap.ignored);
    });
  });

  group('ShardVolley', () {
    test('half the shards are true and the rest lie', () {
      for (var seed = 0; seed < 50; seed++) {
        final volley = ShardVolley.build(words, random: Random(seed))!;
        expect(volley.shards, hasLength(CrystalRules.volleyShards));
        expect(volley.shards.where((s) => s.isTrue), hasLength(3));
      }
    });

    test('a lie claims another word\'s meaning', () {
      final meanings = words.map((w) => w.meaning).toSet();
      for (var seed = 0; seed < 50; seed++) {
        final volley = ShardVolley.build(words, random: Random(seed))!;
        for (final lie in volley.shards.where((s) => !s.isTrue)) {
          expect(lie.claim, isNot(lie.word.meaning));
          expect(meanings, contains(lie.claim));
        }
      }
    });

    test('never throws the same word twice running', () {
      // Four words dealt six times: the deck runs out and is topped up.
      final four = words.take(4).toList();
      for (var seed = 0; seed < 200; seed++) {
        final shards = ShardVolley.build(four, random: Random(seed))!.shards;
        for (var i = 1; i < shards.length; i++) {
          expect(shards[i].word, isNot(shards[i - 1].word),
              reason: 'seed $seed');
        }
      }
    });

    test('needs a pool that can make fair waves', () {
      expect(ShardVolley.build(words.take(3).toList()), isNull);
    });

    test('calls a shard by whether it was smashed and whether it was true',
        () {
      final truth = VolleyShard(word: words[0], claim: 'cat');
      final lie = VolleyShard(word: words[0], claim: 'dog');
      expect(ShardVolley.call(lie, smashed: true), ShardCall.smashedLie);
      expect(ShardVolley.call(truth, smashed: true), ShardCall.smashedTruth);
      expect(ShardVolley.call(truth, smashed: false), ShardCall.caughtTruth);
      expect(ShardVolley.call(lie, smashed: false), ShardCall.lieLanded);
      // Case is not a lie.
      expect(VolleyShard(word: words[0], claim: 'Cat').isTrue, isTrue);
    });

    test('the stock words make volleys and spikes', () {
      final pool = TrialWordPool.build(
        items: const [],
        languageCode: 'es',
        stock: bossTrialStockWords(targetCode: 'es', nativeCode: 'en'),
      );
      expect(ShardVolley.build(pool, random: Random(0)), isNotNull);
      expect(SpikeWave.build(pool, random: Random(0)), isNotNull);
    });
  });

  group('the advanced English set', () {
    test('every word fits a tile, with a gloss unlike any other', () {
      final pool = TrialWordPool.build(
        items: const [],
        languageCode: 'en',
        stock: advancedEnglishWords,
      );
      expect(pool, hasLength(advancedEnglishWords.length));
      expect(
        advancedEnglishWords.map((w) => w.meaning.toLowerCase()).toSet(),
        hasLength(advancedEnglishWords.length),
      );
      expect(SpikeWave.build(pool, random: Random(0)), isNotNull);
      expect(ShardVolley.build(pool, random: Random(0)), isNotNull);
    });

    test('every sentence fits the stones, and means something different', () {
      final pool = TrialSentencePool.build(advancedEnglishSentences);
      expect(pool, hasLength(advancedEnglishSentences.length));
      expect(
        advancedEnglishSentences.map((s) => s.meaning).toSet(),
        hasLength(advancedEnglishSentences.length),
      );
      expect(EchoWave.isPlayable(pool), isTrue);
    });

    test('every sentence has two near misses for the echo to offer', () {
      for (final s in advancedEnglishSentences) {
        expect(s.concepts, hasLength(3), reason: s.target);
        final near = advancedEnglishSentences.where((o) =>
            o != s && o.concepts.intersection(s.concepts).isNotEmpty);
        expect(near.length, greaterThanOrEqualTo(2), reason: s.target);
      }
    });
  });

  group('TrialRun in Amethyst\'s first round', () {
    test('a small hit is worth about a third of a catch', () {
      final run = const TrialRun().shardHit(earliness: 1);
      expect(run.lastDamage, 3 + 1 + 2);
      expect(run.caught, 1);
      expect(run.combo, 1);
      expect(run.patience, 100 - 6);
      expect(
        const TrialRun().shardHit(earliness: 0).lastDamage,
        BossTrialRules.shardBaseDamage + BossTrialRules.shardComboDamage,
      );
    });

    test('a slip breaks the streak and records the word, never a heart', () {
      final run =
          const TrialRun().shardHit(earliness: 1).wordSlip(words[0]).wordSlip(
                words[0],
              );
      expect(run.hearts, BossTrialRules.maxHearts);
      expect(run.combo, 0);
      expect(run.missed, [words[0]]);
    });

    test('getting through costs a heart and records the word', () {
      final run = const TrialRun().struck(words[1]);
      expect(run.hearts, BossTrialRules.maxHearts - 1);
      expect(run.missed, [words[1]]);
      final out = run.struck(words[2]).struck(words[3]);
      expect(out.lost, isTrue);
      expect(out.missed, words.sublist(1, 4));
    });
  });
}
