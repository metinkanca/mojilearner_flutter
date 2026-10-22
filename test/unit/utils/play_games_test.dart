import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/boss_trial_sentences.dart';
import 'package:mojilearner_flutter/utils/boss_trial.dart';
import 'package:mojilearner_flutter/utils/boss_trial_angler.dart';
import 'package:mojilearner_flutter/utils/play_catch.dart';
import 'package:mojilearner_flutter/utils/play_games.dart';

void main() {
  group('rewards', () {
    test('a game of catch pays what it always did', () {
      for (var caught = 0; caught <= 10; caught++) {
        expect(
          PlayRewards.happiness(right: caught, rounds: 10),
          caught + (caught == 10 ? PlayCatchRules.cleanGameBonus : 0),
          reason: '$caught of 10',
        );
      }
    });

    test('every game pays the same for the same share of right answers', () {
      // Five sentences are not worth half of ten quick words.
      expect(PlayRewards.happiness(right: 5, rounds: 5),
          PlayRewards.happiness(right: 10, rounds: 10));
      expect(PlayRewards.happiness(right: 3, rounds: 6),
          PlayRewards.happiness(right: 4, rounds: 8));
      expect(PlayRewards.xp(right: 6, rounds: 6),
          PlayRewards.xp(right: 8, rounds: 8));
    });

    test('only a clean game gets the bonus', () {
      expect(PlayRewards.happiness(right: 7, rounds: 8),
          lessThan(PlayRewards.fullGameHappiness));
      expect(PlayRewards.happiness(right: 8, rounds: 8),
          PlayRewards.fullGameHappiness + PlayRewards.cleanGameBonus);
    });

    test('nothing right pays nothing', () {
      expect(PlayRewards.happiness(right: 0, rounds: 6), 0);
      expect(PlayRewards.xp(right: 0, rounds: 6), 0);
      expect(PlayRewards.xp(right: 0, rounds: 0), 0);
    });

    test('XP is a little: a whole game is under two chat messages', () {
      expect(PlayRewards.xp(right: 8, rounds: 8), PlayRewards.fullGameXp);
      expect(PlayRewards.fullGameXp, lessThan(2 * 5 + 1));
    });

    test('the cap takes only what fits', () {
      expect(PlayRewards.xpAllowed(earned: 10, paidToday: 0), 10);
      expect(
          PlayRewards.xpAllowed(
              earned: 10, paidToday: PlayRewards.dailyXpCap - 4),
          4);
      expect(
          PlayRewards.xpAllowed(earned: 10, paidToday: PlayRewards.dailyXpCap),
          0);
      expect(PlayRewards.xpAllowed(earned: 0, paidToday: 0), 0);
    });
  });

  group('pace', () {
    test('quickens with the streak, never under three quarters', () {
      expect(PlayPace.factor(0), 1);
      expect(PlayPace.factor(2), closeTo(0.9, 1e-9));
      expect(PlayPace.factor(5), closeTo(0.75, 1e-9));
      expect(PlayPace.factor(50), 0.75);
      expect(PlayPace.factor(-3), 1);
    });

    test('every game\'s clock starts at its boss round\'s fresh one', () {
      expect(BubbleBathRules.drainTime(letters: 5, combo: 0),
          const Duration(milliseconds: 9500));
      expect(PounceRules.popUp(0), const Duration(milliseconds: 1800));
      expect(PondHopRules.sinkTime(0), const Duration(milliseconds: 5000));
      expect(FetchRules.fetchTime(words: 4, combo: 0),
          const Duration(milliseconds: 10600));
    });
  });

  group('score', () {
    const casa = PlayPractice(target: 'casa', meaning: 'house');

    test('a slip costs the streak at once but settles nothing', () {
      final score = const PlayScore().scored().scored().slipped(casa);

      expect(score.combo, 0);
      expect(score.played, 2);
      expect(score.toPractise, [casa]);
    });

    test('lists what to practise once', () {
      final score = const PlayScore().slipped(casa).missed(casa).missed(casa);

      expect(score.toPractise, [casa]);
      expect(score.results, [false, false]);
    });

    test('keeps the best streak', () {
      final score =
          const PlayScore().scored().scored().scored().missed(casa).scored();

      expect(score.right, 4);
      expect(score.combo, 1);
      expect(score.bestCombo, 3);
    });
  });

  group('content', () {
    test('words come in the player\'s own pair when it works', () {
      final words =
          playWords(items: const [], targetCode: 'fr', nativeCode: 'en');

      expect(words.targetCode, 'fr');
      expect(words.nativeCode, 'en');
      expect(TrialWordPool.isPlayable(words.pool), isTrue);
    });

    test('and fall back to a pair that works, saying which', () {
      final words =
          playWords(items: const [], targetCode: 'en', nativeCode: 'en');

      expect(TrialWordPool.isPlayable(words.pool), isTrue);
      expect(words.targetCode, isNot(words.nativeCode));
      expect(words.pool.every((w) => w.target != w.meaning), isTrue);
    });

    test('bubble bath can spell in every script, Chinese included', () {
      for (final code in ['zh', 'ja', 'ko', 'th', 'ar', 'ru', 'es']) {
        final words =
            bubbleBathWords(items: const [], targetCode: code, nativeCode: 'en');

        expect(words.targetCode, code, reason: code);
        expect(BubbleWave.isPlayable(words.pool), isTrue, reason: code);
      }
    });

    test('sentences fall back like the words', () {
      final ok = playSentences(targetCode: 'de', nativeCode: 'en');
      expect(ok.targetCode, 'de');
      expect(TrialSentencePool.isPlayable(ok.pool), isTrue);

      final same = playSentences(targetCode: 'en', nativeCode: 'en');
      expect(TrialSentencePool.isPlayable(same.pool), isTrue);
      expect(same.targetCode, isNot(same.nativeCode));
    });

    test('a game of fetch deals every sentence before any comes twice', () {
      final pool = TrialSentencePool.build(
          bossTrialStockSentences(targetCode: 'es', nativeCode: 'en'));
      for (var seed = 0; seed < 20; seed++) {
        final rng = Random(seed);
        final asked = <TrialSentence>{};
        TrialSentence? last;
        for (var i = 0; i < FetchRules.sentencesPerGame; i++) {
          final wave = FetchRules.deal(pool,
              asked: asked, previous: last, random: rng)!;
          expect(asked.add(wave.sentence), isTrue,
              reason: 'seed $seed, sentence $i repeated');
          last = wave.sentence;
        }
      }
    });
  });
}
