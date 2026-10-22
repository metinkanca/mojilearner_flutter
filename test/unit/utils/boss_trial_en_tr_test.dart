import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/boss_trial_en_tr.dart';
import 'package:mojilearner_flutter/utils/boss_trial.dart';
import 'package:mojilearner_flutter/utils/boss_trial_angler.dart';
import 'package:mojilearner_flutter/utils/boss_trial_dragon.dart';
import 'package:mojilearner_flutter/utils/boss_trial_sphinx.dart';

/// The openers whose content is English and Turkish only — Lanternmaw's
/// Shoal, Sableth's three and Pyrewing's three — and that content.
void main() {
  final learningTr = EnTrContent.of('tr', 'en')!;
  final learningEn = EnTrContent.of('en', 'tr')!;
  final both = {'tr': learningTr, 'en': learningEn};

  group('the pair', () {
    test('is English and Turkish, either way round, and nothing else', () {
      expect(isEnTrPair('tr', 'en'), isTrue);
      expect(isEnTrPair('en', 'tr'), isTrue);
      expect(isEnTrPair('es', 'en'), isFalse);
      expect(isEnTrPair('en', 'en'), isFalse);
      expect(EnTrContent.of('es', 'en'), isNull);
    });

    test(
        'a player on another pair fights in it, learning English if they '
        'were', () {
      expect(enTrStandIn('en'), ('en', 'tr'));
      expect(enTrStandIn('es'), ('tr', 'en'));
      expect(enTrStandIn(null), ('tr', 'en'));
    });

    test('each way round shows the learned language and means the other', () {
      final tr = learningTr.categories['animals']!.first;
      final en = learningEn.categories['animals']!.first;
      expect((tr.target, tr.meaning), ('köpek', 'dog'));
      expect((en.target, en.meaning), ('dog', 'köpek'));
      expect(learningTr.riddles.first.passage, contains('kırmızı'));
      expect(learningTr.riddles.first.meaning, contains('red bike'));
    });
  });

  group('content, both ways round', () {
    test('no word is in two groups, and every group can fill a school', () {
      for (final MapEntry(key: code, value: c) in both.entries) {
        final seen = <String>{};
        for (final e in c.categories.entries) {
          expect(e.value.length, greaterThanOrEqualTo(AnglerRules.shoalFish),
              reason: '$code ${e.key}');
          for (final w in e.value) {
            expect(seen.add(w.target.toLowerCase()), isTrue,
                reason: '$code: "${w.target}" is in two groups');
          }
        }
      }
    });

    test('riddles, doors, stories and replies each have one right answer', () {
      for (final MapEntry(key: code, value: c) in both.entries) {
        for (final r in c.riddles) {
          expect(r.answers.toSet(), hasLength(3),
              reason: '$code ${r.question}');
        }
        for (final d in c.doors) {
          expect(d.forms.toSet(), hasLength(3), reason: '$code ${d.base}');
          // The dictionary form can be a wrong turn of the dial ("I go"),
          // never the answer: the dial's own label would give it away.
          expect(d.answer, isNot(d.base), reason: '$code ${d.base}');
        }
        for (final s in c.stories) {
          expect(s.lines, hasLength(3), reason: code);
          expect(s.meanings, hasLength(3), reason: code);
        }
        for (final p in c.parleys) {
          for (final turn in p.turns) {
            expect(turn.replies.toSet(), hasLength(3), reason: turn.line);
          }
        }
      }
    });

    test(
        'every link offers three runes, and every paraphrase three '
        'embers, all different', () {
      for (final c in both.values) {
        for (final l in c.links) {
          expect(l.links.toSet(), hasLength(3), reason: l.left);
          expect(l.joined, contains(l.links.first));
        }
        for (final p in c.paraphrases) {
          expect(p.options.toSet(), hasLength(3), reason: p.line);
          expect(p.options, isNot(contains(p.line)), reason: p.line);
        }
      }
    });

    test('every round is playable', () {
      for (final c in both.values) {
        expect(ShoalWave.isPlayable(c.categories), isTrue);
        expect(RiddleWave.isPlayable(c.riddles), isTrue);
        expect(DoorWave.isPlayable(c.doors), isTrue);
        expect(TabletWave.isPlayable(c.stories), isTrue);
        expect(ParleyWave.isPlayable(c.parleys), isTrue);
        expect(LinkWave.isPlayable(c.links), isTrue);
        expect(ParaphraseWave.isPlayable(c.paraphrases), isTrue);
        expect(HoardWave.isPlayable(c.phrases), isTrue);
      }
    });
  });

  group('ShoalWave', () {
    test('four of one group and a stray from another', () {
      final rng = Random(4);
      for (var i = 0; i < 60; i++) {
        final wave = ShoalWave.build(learningTr.categories, random: rng)!;
        expect(wave.fish, hasLength(AnglerRules.shoalFish));
        final group = learningTr.categories[wave.category]!;
        for (var f = 0; f < wave.fish.length; f++) {
          expect(group.contains(wave.fish[f]), f != wave.stray,
              reason: wave.fish[f].target);
        }
      }
    });

    test('never the same stray twice running', () {
      final rng = Random(6);
      var last = ShoalWave.build(learningTr.categories, random: rng)!.strayWord;
      for (var i = 0; i < 40; i++) {
        final next =
            ShoalWave.build(learningTr.categories, previous: last, random: rng)!
                .strayWord;
        expect(next, isNot(last));
        last = next;
      }
    });
  });

  group('Sableth', () {
    test('a riddle\'s right answer is among its three, wherever it lands', () {
      final rng = Random(1);
      for (var i = 0; i < 30; i++) {
        final wave = RiddleWave.build(learningTr.riddles, random: rng)!;
        expect(wave.options[wave.answer], wave.riddle.answers.first);
      }
    });

    test('the dial never starts on the right form', () {
      final rng = Random(2);
      for (var i = 0; i < 60; i++) {
        final wave = DoorWave.build(learningEn.doors, random: rng)!;
        expect(wave.forms[wave.answer], wave.door.answer);
        expect(wave.start, isNot(wave.answer));
      }
    });

    test('tablets are never laid out in order, and lift only in order', () {
      final rng = Random(3);
      for (var i = 0; i < 40; i++) {
        final wave = TabletWave.build(learningTr.stories, random: rng)!;
        expect(wave.tablets, isNot([0, 1, 2]));
        final play = TabletPlay(wave);
        final second = wave.tablets.indexOf(1);
        expect(play.tap(second), TabletTap.wrong);
        expect(play.tap(wave.tablets.indexOf(0)), TabletTap.next);
        expect(play.tap(second), TabletTap.next);
        expect(play.tap(wave.tablets.indexOf(2)), TabletTap.done);
        expect(play.isDone, isTrue);
      }
    });
  });

  group('Pyrewing', () {
    test('a parley offers each turn\'s replies with the right one marked', () {
      final wave = ParleyWave.build(learningTr.parleys, random: Random(5))!;
      for (var t = 0; t < wave.script.turns.length; t++) {
        expect(wave.options[t][wave.answers[t]],
            wave.script.turns[t].replies.first);
      }
    });

    test('a flame link\'s right rune is among the three', () {
      final rng = Random(7);
      for (var i = 0; i < 30; i++) {
        final wave = LinkWave.build(learningTr.links, random: rng)!;
        expect(wave.runes[wave.answer], wave.item.links.first);
      }
    });

    test('one wrong ember goes out half way; the right one lasts the clock',
        () {
      final rng = Random(11);
      final early = <int>{};
      for (var i = 0; i < 60; i++) {
        final wave = ParaphraseWave.build(learningEn.paraphrases, random: rng)!;
        expect(wave.embers[wave.answer], wave.item.options.first);
        // The round is only lost when its clock runs out.
        expect(wave.lives[wave.answer], 1.0);
        expect([...wave.lives]..sort(), [DragonRules.emberGoesAt, 1.0, 1.0]);
        early.add(wave.lives.indexOf(DragonRules.emberGoesAt));
      }
      // Which one goes is dealt, not always the same place.
      expect(early.length, greaterThan(1));
    });

    test('a hoard pairs up only one way', () {
      for (final c in both.values) {
        final rng = Random(8);
        for (var i = 0; i < 80; i++) {
          final wave =
              HoardWave.build(c.phrases, alsoFit: c.alsoFit, random: rng)!;
          expect(wave.phrases, hasLength(DragonRules.hoardPairs));
          // Any first half with any second half it is not paired with in
          // this hoard must be no phrase at all.
          for (final a in wave.phrases) {
            for (final b in wave.phrases) {
              if (a.first == b.first || a.second == b.second) continue;
              final fits = c.alsoFit.contains((a.first, b.second)) ||
                  c.phrases
                      .any((p) => p.first == a.first && p.second == b.second);
              expect(fits, isFalse,
                  reason: '"${a.first} ${b.second}" would pair too');
            }
          }
        }
      }
    });

    test('a pair is tried on its words: a half two phrases share fits both',
        () {
      const wave = HoardWave(
        phrases: [
          Collocation('söz', 'vermek', 'make a promise'),
          Collocation('karar', 'vermek', 'make a decision'),
        ],
        coins: [
          HoardCoin('söz', first: true),
          HoardCoin('vermek', first: false),
          HoardCoin('karar', first: true),
          HoardCoin('vermek', first: false),
        ],
      );
      final play = HoardPlay(wave);
      // "karar" with the first "vermek", then "söz" with the second.
      expect(play.tap(2), HoardTap.held);
      expect(play.tap(1), HoardTap.matched);
      expect(play.tap(0), HoardTap.held);
      expect(play.tap(0), HoardTap.dropped);
      expect(play.tap(3), HoardTap.held);
      expect(play.tap(0), HoardTap.matched);
      expect(play.isCleared, isTrue);
    });

    test('two first halves never pair, nor two seconds', () {
      final wave = HoardWave.build(learningEn.phrases,
          alsoFit: learningEn.alsoFit, random: Random(9))!;
      final play = HoardPlay(wave);
      final firsts = [
        for (var i = 0; i < wave.coins.length; i++)
          if (wave.coins[i].first) i,
      ];
      play.tap(firsts[0]);
      expect(play.tap(firsts[1]), HoardTap.mismatched);
      expect(play.unfound, hasLength(DragonRules.hoardPairs));
    });
  });

  group('what a miss leaves to practise', () {
    test('reads as a sentence with its meaning', () {
      final door = learningTr.doors.first;
      expect(door.asSentence.target, 'Dün pazara gittim');
      expect(door.asSentence.meaning, 'Yesterday I went to the market.');
      final phrase = learningEn.phrases.first.asWord;
      expect(
          (phrase.target, phrase.meaning), ('make a mistake', 'hata yapmak'));
      expect(
        const TrialRun().castFailed(learningTr.stories.first.asSentence).hearts,
        BossTrialRules.maxHearts - 1,
      );
    });
  });
}
