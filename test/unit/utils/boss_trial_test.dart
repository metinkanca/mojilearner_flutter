import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/boss_trial_words.dart';
import 'package:mojilearner_flutter/models/models.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/utils/boss_trial.dart';
import 'package:shared_preferences/shared_preferences.dart';

ReviewItem item(
  String prompt,
  String answer, {
  String languageCode = 'es',
  ReviewItemKind kind = ReviewItemKind.vocabulary,
}) =>
    ReviewItem(
      id: 'id-$prompt',
      languageCode: languageCode,
      prompt: prompt,
      answer: answer,
      kind: kind,
    );

List<TrialWord> words(int n) => List.generate(
      n,
      (i) => TrialWord(target: 'word$i', meaning: 'meaning$i'),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BossTrialRules.readTime', () {
    test('is generous at full patience and tight by the end of the round', () {
      expect(BossTrialRules.readTime(100), BossTrialRules.readTimeFresh);
      expect(BossTrialRules.readTime(BossTrialRules.spellPhaseAt),
          BossTrialRules.readTimeNearlyBeaten);
    });

    test('tightens steadily across the Catch round', () {
      expect(BossTrialRules.readTime(75).inMilliseconds, 4000);
      expect(
        BossTrialRules.readTime(90) > BossTrialRules.readTime(60),
        isTrue,
      );
    });

    test('clamps patience outside the bar', () {
      expect(BossTrialRules.readTime(-30), BossTrialRules.readTimeNearlyBeaten);
      expect(BossTrialRules.readTime(250), BossTrialRules.readTimeFresh);
    });
  });

  group('BossTrialRules.damage', () {
    test('a slow first catch deals the base plus one combo step', () {
      expect(BossTrialRules.damage(combo: 1, earliness: 0), 12);
    });

    test('answering the moment it is thrown adds the full quick bonus', () {
      expect(BossTrialRules.damage(combo: 1, earliness: 1), 20);
    });

    test('earliness is clamped', () {
      expect(
        BossTrialRules.damage(combo: 1, earliness: 3),
        BossTrialRules.damage(combo: 1, earliness: 1),
      );
    });
  });

  group('TrialWordPool.build', () {
    test('puts the player\'s own words before the stock set', () {
      final pool = TrialWordPool.build(
        items: [item('ratón', 'mouse')],
        languageCode: 'es',
        stock: bossTrialStockWords(targetCode: 'es', nativeCode: 'en'),
      );
      expect(pool.first.target, 'ratón');
      expect(pool.length, 13);
    });

    test('drops a stock word the player already has', () {
      final pool = TrialWordPool.build(
        items: [item('Gato', 'cat')],
        languageCode: 'es',
        stock: bossTrialStockWords(targetCode: 'es', nativeCode: 'en'),
      );
      expect(pool.where((w) => w.target.toLowerCase() == 'gato'), hasLength(1));
    });

    test('ignores other languages, corrections and over-long words', () {
      final pool = TrialWordPool.build(
        items: [
          item('chat', 'cat', languageCode: 'fr'),
          item('Yo soy fue', 'Yo fui', kind: ReviewItemKind.correction),
          item('desafortunadamente', 'unfortunately'),
          item('pez', 'fish (that is alive)'),
          item('sol', 'sun'),
        ],
        languageCode: 'es',
      );
      expect(pool.map((w) => w.target), ['sol']);
    });

    test('leaves out a word whose meaning is spelled the same', () {
      final pool = TrialWordPool.build(
        items: [item('hotel', 'Hotel'), item('sol', 'sun')],
        languageCode: 'es',
      );
      expect(pool.map((w) => w.target), ['sol']);
    });

    test('is playable only with a full wave of words', () {
      expect(TrialWordPool.isPlayable(words(3)), isFalse);
      expect(TrialWordPool.isPlayable(words(4)), isTrue);
    });

    test('counts synonyms once, since a wave cannot hold both', () {
      final pool = [
        const TrialWord(target: 'casa', meaning: 'house'),
        const TrialWord(target: 'hogar', meaning: 'House'),
        ...words(2),
      ];
      expect(TrialWordPool.isPlayable(pool), isFalse);
    });
  });

  group('TrialWave.build', () {
    test('holds the prompt once among four distinct tiles', () {
      final wave = TrialWave.build(words(12), random: Random(1))!;
      expect(wave.lanes, hasLength(BossTrialRules.wordsPerWave));
      expect(wave.lanes.toSet(), hasLength(BossTrialRules.wordsPerWave));
      expect(wave.lanes.where((w) => w == wave.prompt), hasLength(1));
      expect(wave.lanes[wave.answerLane], wave.prompt);
    });

    test('never asks the same word twice in a row', () {
      final pool = words(5);
      var previous = pool.first;
      for (var seed = 0; seed < 50; seed++) {
        final wave = TrialWave.build(pool, previous: previous, random: Random(seed))!;
        expect(wave.prompt, isNot(previous));
        previous = wave.prompt;
      }
    });

    test('never shows the same meaning on two pieces of rubble', () {
      final pool = [
        const TrialWord(target: 'casa', meaning: 'house'),
        const TrialWord(target: 'hogar', meaning: 'House'),
        const TrialWord(target: 'vivienda', meaning: 'house'),
        ...words(3),
      ];
      for (var seed = 0; seed < 50; seed++) {
        final wave = TrialWave.build(pool, random: Random(seed))!;
        final meanings = wave.lanes.map((w) => w.meaning.toLowerCase());
        expect(meanings.toSet(), hasLength(BossTrialRules.wordsPerWave),
            reason: 'seed $seed');
      }
    });

    test('builds a wave from every pool isPlayable accepts', () {
      final pool = [
        const TrialWord(target: 'casa', meaning: 'house'),
        const TrialWord(target: 'hogar', meaning: 'house'),
        ...words(3),
      ];
      expect(TrialWordPool.isPlayable(pool), isTrue);
      var previous = pool.first;
      for (var seed = 0; seed < 50; seed++) {
        final wave =
            TrialWave.build(pool, previous: previous, random: Random(seed));
        expect(wave, isNotNull, reason: 'seed $seed');
        previous = wave!.prompt;
      }
    });

    test('refuses a pool that cannot fill a fair wave', () {
      expect(TrialWave.build(words(3)), isNull);
    });
  });

  group('TrialRun', () {
    test('a right answer drains patience and builds the combo', () {
      final run = const TrialRun()
          .answerRight(earliness: 0)
          .answerRight(earliness: 0);
      expect(run.combo, 2);
      expect(run.bestCombo, 2);
      expect(run.caught, 2);
      expect(run.patience, 100 - 12 - 14);
      expect(run.lastDamage, 14);
    });

    test('a wrong answer costs a heart, the combo, and records the word', () {
      const asked = TrialWord(target: 'perro', meaning: 'dog');
      final run = const TrialRun().answerRight(earliness: 0).answerWrong(asked);
      expect(run.hearts, BossTrialRules.maxHearts - 1);
      expect(run.combo, 0);
      expect(run.bestCombo, 1);
      expect(run.missed, [asked]);
    });

    test('missing the same word twice lists it once', () {
      const asked = TrialWord(target: 'perro', meaning: 'dog');
      final run = const TrialRun().answerWrong(asked).answerWrong(asked);
      expect(run.missed, [asked]);
    });

    test('letting a wave land costs only the combo', () {
      final run = const TrialRun().answerRight(earliness: 0).letLand();
      expect(run.combo, 0);
      expect(run.hearts, BossTrialRules.maxHearts);
      expect(run.letSlip, 1);
      expect(run.missed, isEmpty);
    });

    test('is won when patience runs out, and graded on hearts kept', () {
      var run = const TrialRun();
      run = run.answerWrong(const TrialWord(target: 'a', meaning: 'b'));
      while (!run.isOver) {
        run = run.answerRight(earliness: 1);
      }
      expect(run.won, isTrue);
      expect(run.patience, 0);
      expect(run.grade, TrialGrade.a);
    });

    test('is lost when the hearts run out', () {
      var run = const TrialRun();
      for (var i = 0; i < BossTrialRules.maxHearts; i++) {
        run = run.answerWrong(TrialWord(target: 't$i', meaning: 'm$i'));
      }
      expect(run.lost, isTrue);
      expect(run.won, isFalse);
    });
  });

  group('TrialPlan', () {
    /// Four openings, each with its own patience.
    const hp = [210, 115, 165, 145];

    test('a level before the finale is one opening, with its own patience',
        () {
      for (var step = 0; step < 4; step++) {
        final plan = TrialPlan.forStep(step, openingHp: hp);
        expect(plan.isFinale, isFalse);
        expect(plan.rounds, hasLength(1));
        final round = plan.rounds.single;
        expect(round.opening, step);
        expect(round.from, hp[step]);
        expect(round.to, 0);
      }
    });

    test('a level is won when its patience runs out', () {
      var run = TrialPlan.forStep(0, openingHp: hp).start();
      var hits = 0;
      while (!run.isOver) {
        run = run.answerRight(earliness: 1);
        hits++;
      }
      expect(run.won, isTrue);
      expect(run.patience, 0);
      // Even the quickest catches, every one, take a good many.
      expect(hits, greaterThanOrEqualTo(8));
    });

    test('every round runs its clocks from fresh to tightest', () {
      final plan = TrialPlan.forStep(4, openingHp: hp);
      for (var r = 0; r <= plan.lastRound; r++) {
        final round = plan.rounds[r];
        expect(plan.clockPatience(r, round.from), BossTrialRules.maxPatience);
        expect(plan.clockPatience(r, round.to), BossTrialRules.spellPhaseAt);
        expect(
            BossTrialRules.roundOneHealth(
                plan.clockPatience(r, (round.from + round.to) ~/ 2)),
            closeTo(0.5, 0.02));
      }
      final last = plan.rounds.last;
      expect(plan.clockPatience(plan.lastRound, last.from),
          BossTrialRules.maxPatience);
      expect(plan.clockPatience(plan.lastRound, 0),
          BossTrialRules.spellPhaseAt);
    });

    test('the finale is every opening a round, and nothing after them', () {
      final plan = TrialPlan.forStep(4, openingHp: hp);
      expect(plan.isFinale, isTrue);
      expect([for (final r in plan.rounds) r.opening], [0, 1, 2, 3]);
      // Each round a share of its opening's own length.
      int share(int full) => (full * BossTrialRules.finaleRoundShare).round();
      for (var i = 0; i < 4; i++) {
        expect(plan.rounds[i].hp, share(hp[i]));
        expect(plan.rounds[i].hp, lessThan(hp[i]));
      }
      expect(plan.totalHp, hp.map(share).reduce((a, b) => a + b));
      expect(plan.hpLeft(0, plan.rounds.first.from), plan.totalHp);
      expect(plan.hpLeft(3, 0), 0);
    });

    test('a finale round handed on keeps the streak and gives a heart back',
        () {
      final plan = TrialPlan.forStep(4, openingHp: hp);
      var run = plan.start();
      expect(run.last, isFalse);
      run = run.answerWrong(const TrialWord(target: 'a', meaning: 'b'));
      run = run.answerWrong(const TrialWord(target: 'c', meaning: 'd'));
      while (!run.cleared) {
        run = run.answerRight(earliness: 1);
      }
      expect(run.won, isFalse, reason: 'four rounds still to go');
      expect(run.isOver, isFalse);

      final next = plan.enter(run, 1);
      expect(next.patience, plan.rounds[1].from);
      expect(next.cleared, isFalse);
      expect(next.combo, run.combo);
      expect(next.missed, hasLength(2));
      expect(next.hearts, run.hearts + BossTrialRules.finaleHeartsBack);
      // Never past full.
      expect(plan.enter(plan.start(), 1).hearts, BossTrialRules.maxHearts);

      // Only the last round wins it.
      final last = plan.enter(next, plan.lastRound);
      expect(last.last, isTrue);
      expect(last.patience, plan.rounds.last.from);
    });
  });

  test('a streak adds damage up to its cap, and no more', () {
    int at(int combo) => BossTrialRules.damage(combo: combo, earliness: 0);
    expect(at(BossTrialRules.maxComboBonus) - at(0),
        BossTrialRules.maxComboBonus * BossTrialRules.comboDamage);
    expect(at(BossTrialRules.maxComboBonus + 10),
        at(BossTrialRules.maxComboBonus));
  });

  group('bossTrialStockWords', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('covers every language the app teaches', () {
      // A language added to the catalogue without a stock row would open the
      // trial on "not enough words" for anyone learning it.
      final shipped =
          LanguageProvider().availableLanguages.map((l) => l.code).toSet();
      expect(bossTrialStockLanguages.toSet(), shipped);
    });

    test('every pairing is a full, playable, tile-sized set', () {
      for (final target in bossTrialStockLanguages) {
        for (final native in bossTrialStockLanguages) {
          if (native == target) continue;
          final pool = TrialWordPool.build(
            items: const [],
            languageCode: target,
            stock: bossTrialStockWords(targetCode: target, nativeCode: native),
          );
          // Words spelled the same on both sides drop out — Swedish and
          // Norwegian share half the set — but every pairing must still fight.
          expect(TrialWordPool.isPlayable(pool), isTrue,
              reason: '$target from $native');
        }
      }
    });

    test('the prompt is in the player\'s own language', () {
      final words = bossTrialStockWords(targetCode: 'en', nativeCode: 'tr');
      expect(
        words.firstWhere((w) => w.target == 'dog').meaning,
        'köpek',
      );
    });

    test('an unknown native language falls back to English meanings', () {
      final words = bossTrialStockWords(targetCode: 'es', nativeCode: 'xx');
      expect(words.firstWhere((w) => w.target == 'perro').meaning, 'dog');
    });

    test('gives nothing rather than the wrong thing', () {
      expect(bossTrialStockWords(targetCode: 'xx', nativeCode: 'en'), isEmpty);
      expect(bossTrialStockWords(targetCode: null, nativeCode: 'en'), isEmpty);
      // Every prompt would be its own answer.
      expect(bossTrialStockWords(targetCode: 'es', nativeCode: 'es'), isEmpty);
    });
  });
}
