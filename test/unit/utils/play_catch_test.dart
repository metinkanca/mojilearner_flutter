import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/models/models.dart';
import 'package:mojilearner_flutter/utils/boss_trial.dart';
import 'package:mojilearner_flutter/utils/play_catch.dart';

void main() {
  const casa = TrialWord(target: 'casa', meaning: 'house');
  const perro = TrialWord(target: 'perro', meaning: 'dog');

  group('words', () {
    test('are the stock words of the language being learned', () {
      final pool =
          playCatchWords(items: const [], targetCode: 'fr', nativeCode: 'en');

      expect(TrialWordPool.isPlayable(pool), isTrue);
      expect(pool.map((w) => w.target), contains('pomme'));
      expect(pool.map((w) => w.meaning), contains('apple'));
    });

    test('put the player\'s own words first', () {
      final pool = playCatchWords(
        items: [
          ReviewItem(
            id: 'v1',
            languageCode: 'fr',
            kind: ReviewItemKind.vocabulary,
            prompt: 'fromage',
            answer: 'cheese',
            createdAt: DateTime(2026),
            dueAt: DateTime(2026),
          ),
        ],
        targetCode: 'fr',
        nativeCode: 'en',
      );

      expect(pool.first.target, 'fromage');
    });

    test('still fill a game with no language chosen yet', () {
      final pool =
          playCatchWords(items: const [], targetCode: null, nativeCode: 'en');

      expect(TrialWordPool.isPlayable(pool), isTrue);
    });

    test('still fill a game with the same language on both sides', () {
      final pool =
          playCatchWords(items: const [], targetCode: 'en', nativeCode: 'en');

      expect(TrialWordPool.isPlayable(pool), isTrue);
      expect(pool.every((w) => w.target != w.meaning), isTrue);
    });

    test('still fill a game for a language with no stock words', () {
      final pool =
          playCatchWords(items: const [], targetCode: 'xx', nativeCode: 'yy');

      expect(TrialWordPool.isPlayable(pool), isTrue);
    });
  });

  group('read time', () {
    test('starts generous and quickens with the streak', () {
      expect(PlayCatchRules.readTime(0), PlayCatchRules.readTimeStart);
      expect(PlayCatchRules.readTime(2),
          lessThan(PlayCatchRules.readTime(1)));
    });

    test('never drops below the fastest clock', () {
      expect(PlayCatchRules.readTime(100), PlayCatchRules.readTimeFastest);
      expect(PlayCatchRules.readTime(-3), PlayCatchRules.readTimeStart);
    });
  });

  group('happiness', () {
    test('a point a catch, and a bonus for a clean game', () {
      expect(PlayCatchRules.happiness(caught: 7, throws: 10), 7);
      expect(PlayCatchRules.happiness(caught: 10, throws: 10),
          10 + PlayCatchRules.cleanGameBonus);
    });

    test('a game with no catches is worth nothing', () {
      expect(PlayCatchRules.happiness(caught: 0, throws: 10), 0);
    });

    test('is worth no more than two pettings at best', () {
      final best = PlayCatchRules.happiness(
        caught: PlayCatchRules.throwsPerGame,
        throws: PlayCatchRules.throwsPerGame,
      );
      expect(best, lessThanOrEqualTo(16));
    });
  });

  group('a game', () {
    test('counts catches and keeps the best streak', () {
      final game = const CatchGame()
          .caughtIt()
          .caughtIt()
          .missed(casa)
          .caughtIt();

      expect(game.thrown, 4);
      expect(game.caught, 3);
      expect(game.combo, 1);
      expect(game.bestCombo, 2);
    });

    test('lists every word that got away once, dropped or missed', () {
      final game = const CatchGame()
          .missed(casa)
          .dropped(perro)
          .missed(casa);

      expect(game.toPractise, [casa, perro]);
      expect(game.results,
          [CatchResult.missed, CatchResult.dropped, CatchResult.missed]);
    });

    test('ends after its throws, win or lose', () {
      var game = const CatchGame();
      for (var i = 0; i < PlayCatchRules.throwsPerGame - 1; i++) {
        game = game.dropped(casa);
      }
      expect(game.isOver, isFalse);
      expect(game.caughtIt().isOver, isTrue);
    });
  });
}
