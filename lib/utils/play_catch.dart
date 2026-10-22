/// Catch at home: the boss trial's first round as a game played with the pet,
/// with nothing to lose.
///
/// The pet calls out a word in the language being learned and the ball is
/// thrown to it. While the ball is in the air, the player picks which of four
/// toy blocks carries the word's meaning in their own language. Right, and the
/// pet jumps up, knocks the ball back to its spot and drops down again; wrong,
/// or still unanswered when the ball arrives, and it bonks off the pet's head
/// and bounces away. A game is a
/// fixed number of throws; a miss costs nothing but the streak, and the right
/// block is lit so the word is learned rather than just lost.
///
/// Words and waves are the trial's own — [TrialWordPool] and [TrialWave] —
/// so this file only holds what is different about playing instead of
/// fighting. Pure and provider-free, like the rules it borrows from.
library;

import 'dart:math';

import '../constants/boss_trial_words.dart';
import '../models/models.dart';
import 'boss_trial.dart';
import 'play_games.dart';

/// The words a game of catch is played with, which are never too few to play.
///
/// The player's own words for [targetCode] come first, topped up with the
/// stock words, exactly as a trial builds its pool. Unlike a trial, a game
/// that cannot fill a wave does not refuse to start: the ball is always lying
/// there, and a toy that does nothing when tapped reads as broken. So when
/// that pool is too thin — no language chosen yet, a language without stock
/// words, or the same language on both sides, where every word would be its
/// own answer — it falls back to stock pairings that always work, ending at
/// Spanish with English meanings, the app's own default pair.
List<TrialWord> playCatchWords({
  required List<ReviewItem> items,
  required String? targetCode,
  required String? nativeCode,
}) {
  var pool = const <TrialWord>[];
  for (final (target, native) in bossTrialFallbackPairs(targetCode, nativeCode)) {
    pool = TrialWordPool.build(
      items: items,
      languageCode: target ?? '',
      stock: bossTrialStockWords(targetCode: target, nativeCode: native),
    );
    if (TrialWordPool.isPlayable(pool)) return pool;
  }
  return pool;
}

class PlayCatchRules {
  PlayCatchRules._();

  static const int throwsPerGame = 10;

  /// How long a throw takes to reach the pet — the time there is to answer.
  /// Generous from a cold start, quicker with every catch in a row, and
  /// generous again after a miss.
  ///
  /// The trial tightens its clock as the boss weakens. There is no boss here,
  /// so the streak is what the player is proving: a word known instantly is
  /// rewarded with the next one coming sooner, and a word not known slows the
  /// game back down instead of punishing anything.
  ///
  /// Four and a half seconds down to two and a half: long enough to read four
  /// short words, short enough that the ball crossing the sky is felt as a
  /// clock rather than watched as one.
  static const Duration readTimeStart = Duration(milliseconds: 4500);
  static const Duration readTimeFastest = Duration(milliseconds: 2500);
  static const Duration readTimeStep = Duration(milliseconds: 500);

  /// Flight time for a throw made with the streak at [combo].
  static Duration readTime(int combo) {
    final ms = readTimeStart.inMilliseconds -
        max(0, combo) * readTimeStep.inMilliseconds;
    return Duration(milliseconds: max(readTimeFastest.inMilliseconds, ms));
  }

  /// Happiness on top of a catch for every throw of the game.
  static const int cleanGameBonus = PlayRewards.cleanGameBonus;

  /// Happiness a game is worth: a point a catch, plus [cleanGameBonus] for
  /// catching every throw — every toy chest game's formula, which on ten
  /// throws comes out at exactly that. See [PlayRewards.happiness].
  static int happiness({required int caught, required int throws}) =>
      PlayRewards.happiness(right: caught, rounds: throws);
}

/// How one throw ended.
enum CatchResult {
  /// The right block, picked in time.
  caught,

  /// A wrong block.
  missed,

  /// Nothing picked before the ball reached the pet.
  dropped,
}

/// The score of one game, advanced one throw at a time.
class CatchGame {
  const CatchGame({
    this.results = const [],
    this.combo = 0,
    this.bestCombo = 0,
    this.toPractise = const [],
  });

  /// Every throw so far, in order.
  final List<CatchResult> results;
  final int combo;
  final int bestCombo;

  /// Words not caught, in order, without repeats — picked wrong or left
  /// unanswered alike. Unlike the trial, an unanswered word counts: this is
  /// practice, and a word the player could not place in a whole flight is one
  /// worth seeing again.
  final List<TrialWord> toPractise;

  int get thrown => results.length;
  int get caught => results.where((r) => r == CatchResult.caught).length;
  bool get isOver => thrown >= PlayCatchRules.throwsPerGame;

  CatchGame caughtIt() {
    final streak = combo + 1;
    return CatchGame(
      results: [...results, CatchResult.caught],
      combo: streak,
      bestCombo: max(bestCombo, streak),
      toPractise: toPractise,
    );
  }

  CatchGame missed(TrialWord asked) => _notCaught(CatchResult.missed, asked);

  CatchGame dropped(TrialWord asked) => _notCaught(CatchResult.dropped, asked);

  CatchGame _notCaught(CatchResult result, TrialWord asked) => CatchGame(
        results: [...results, result],
        combo: 0,
        bestCombo: bestCombo,
        toPractise:
            toPractise.contains(asked) ? toPractise : [...toPractise, asked],
      );
}
