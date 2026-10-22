/// The toy chest's games: boss trial rounds turned into games played with the
/// pet at home, with nothing to lose.
///
/// Catch was the first (`play_catch.dart`). The rest each borrow one of the
/// boss openers' rules wholesale and only change what losing means:
///
/// * **Bubble Bath** — Lanternmaw's Bubbles. The pet is in the bath and wants
///   a word; letters rise in bubbles, and popping them in order spells it
///   before the water drains.
/// * **Pounce** — Mossback's Pebble Pop. A meaning in the player's language
///   is up, moles pop out of molehills holding words in the language being
///   learned, and the pet pounces on the one that says it.
/// * **Pond Hop** — Mossback's Stepping Stones. The pet crosses a pond a row
///   of lily pads at a time; a frog on the far bank calls a word, and the pad
///   with its meaning is the one to hop onto.
/// * **Fetch the Words** — the Spells round. A sentence in the player's
///   language, word sticks in the language being learned on the grass, and
///   the pet fetches them in order.
///
/// The trial tightens its clocks as the boss weakens. There is no boss here,
/// so — as in Catch — the streak is what quickens the game, and a miss slows
/// it back down instead of costing anything.
///
/// Pure and provider-free, like the rules it borrows.
library;

import 'dart:math';

import '../constants/boss_trial_sentences.dart';
import '../constants/boss_trial_words.dart';
import '../models/models.dart';
import 'boss_trial.dart';
import 'boss_trial_angler.dart';

/// Every game in the toy chest, in the order the chest shows them.
enum PlayGame { catchBall, bubbleBath, pounce, pondHop, fetchWords }

/// What a finished game pays, whichever game it was.
class PlayRewards {
  PlayRewards._();

  /// Happiness for a whole game of right answers, before the clean bonus.
  ///
  /// Ten, so a game of catch is still a point a catch: games of different
  /// lengths all pay the same for the same share of right answers, and a
  /// game of five long sentences is not worth half a game of ten quick
  /// words.
  static const int fullGameHappiness = 10;

  /// Happiness on top for getting every round of a game right.
  static const int cleanGameBonus = 5;

  /// Happiness for [right] of [rounds]: fifteen at best, about two pettings.
  /// A minute of play should feel like attention, not like a meal. How often
  /// it pays is rationed by `CharacterProvider.playCooldown`, which is shared
  /// by every game, so more games in the chest are not more happiness.
  static int happiness({required int right, required int rounds}) {
    if (right <= 0 || rounds <= 0) return 0;
    return (fullGameHappiness * right / rounds).round() +
        (right >= rounds ? cleanGameBonus : 0);
  }

  /// XP for a whole game of right answers.
  ///
  /// A chat message is worth 5 and a reviewed card 3, so a whole game sits
  /// between two messages and three cards: practice, not a shortcut.
  static const int fullGameXp = 10;

  /// XP for [right] of [rounds], before the daily cap.
  static int xp({required int right, required int rounds}) {
    if (right <= 0 || rounds <= 0) return 0;
    return (fullGameXp * right / rounds).round();
  }

  /// The most XP the games pay in a day, all of them together: three perfect
  /// games.
  ///
  /// Levels — and the boss trials, level rewards and season pass tiers that
  /// hang off them — follow activity, and these games are activity, so they
  /// pay. But a day of quizzes, chat and reviews is around 180 XP, and the
  /// games are the one source a player could repeat for an hour without
  /// tiring, so they top a day up by a sixth rather than replacing it. See
  /// `economy_curve_test.dart`.
  static const int dailyXpCap = 30;

  /// What of [earned] XP still fits under [dailyXpCap], with [paidToday]
  /// already paid by the games today.
  static int xpAllowed({required int earned, required int paidToday}) =>
      max(0, min(earned, dailyXpCap - paidToday));
}

/// A clock that quickens with the streak.
class PlayPace {
  PlayPace._();

  /// How much of the full clock a round gets with the streak at [combo]: all
  /// of it from a cold start, a twentieth less per right answer in a row,
  /// never under three quarters.
  static double factor(int combo) => max(0.75, 1 - 0.05 * max(0, combo));

  /// [full], quickened for a streak of [combo].
  static Duration of(Duration full, int combo) =>
      Duration(microseconds: (full.inMicroseconds * factor(combo)).round());
}

class BubbleBathRules {
  BubbleBathRules._();

  static const int wordsPerGame = 6;

  /// How long the water takes to drain over a word of [letters] letters:
  /// Lanternmaw's gulp while it is fresh — time to read the meaning, then to
  /// find each letter on the move. Five letters get 9.5 seconds.
  static Duration drainTime({required int letters, required int combo}) =>
      PlayPace.of(Duration(milliseconds: 4000 + 1100 * letters), combo);

  /// How much of the water a wrong letter lets out.
  static const double mistakeDrain = 0.15;
}

class PounceRules {
  PounceRules._();

  static const int wavesPerGame = 8;

  /// How long a mole stays up: Pebble Pop's while the boss is fresh.
  static Duration popUp(int combo) =>
      PlayPace.of(const Duration(milliseconds: 1800), combo);

  /// The beat between one mole and the next. With the time up, two are up
  /// at once.
  static Duration popInterval(int combo) =>
      PlayPace.of(const Duration(milliseconds: 900), combo);
}

class PondHopRules {
  PondHopRules._();

  /// Rows of lily pads between the banks, and crossings in a game.
  static const int rowsPerPond = 4;
  static const int ponds = 2;
  static const int rowsPerGame = rowsPerPond * ponds;

  /// How long the pad under the pet — or, for the first hop, the bank —
  /// stays put before the pet gets splashed: Stepping Stones' while the boss
  /// is fresh.
  static Duration sinkTime(int combo) =>
      PlayPace.of(const Duration(milliseconds: 5000), combo);
}

class FetchRules {
  FetchRules._();

  static const int sentencesPerGame = 5;

  /// How long the pet waits for a sentence of [words] words: the Spells
  /// round's clock while the boss is fresh. Four words get 10.6 seconds.
  static Duration fetchTime({required int words, required int combo}) =>
      PlayPace.of(Duration(milliseconds: 3000 + 1900 * words), combo);

  /// How much of the wait a wrong stick uses up.
  static const double mistakeCost = 0.15;

  /// A spell from [pool] whose sentence is not one of [asked], while any is
  /// left. A game has five sentences and the stock has six, so each comes up
  /// once rather than the same two turning up twice.
  ///
  /// [SpellWave.build] only avoids the one before, so this deals until it
  /// draws a fresh one — a handful of draws at worst, and a repeat rather
  /// than no spell at all if the draws run out.
  static SpellWave? deal(
    List<TrialSentence> pool, {
    required Set<TrialSentence> asked,
    TrialSentence? previous,
    Random? random,
  }) {
    final rng = random ?? Random();
    SpellWave? wave;
    for (var draw = 0; draw < 24; draw++) {
      wave = SpellWave.build(pool, previous: previous, random: rng);
      if (wave == null || !asked.contains(wave.sentence)) return wave;
    }
    return wave;
  }
}

/// A game's words, and the pair of languages they ended up in.
///
/// The pair is the player's own unless it cannot fill a game, and the screen
/// needs to know which it got: a Japanese word drawn in a Latin font is a row
/// of boxes.
class PlayWords {
  const PlayWords(this.pool, {required this.targetCode, required this.nativeCode});

  final List<TrialWord> pool;
  final String? targetCode;
  final String? nativeCode;
}

/// The words a game is played with, which are never too few to play.
///
/// The player's own words for [targetCode] come first, topped up with the
/// stock, exactly as a trial builds its pool. A game that cannot be filled
/// does not refuse to start — a toy that does nothing when tapped reads as
/// broken — so a pool that fails [playable] falls back through the stock
/// pairings that always work. See [bossTrialFallbackPairs].
PlayWords playWords({
  required List<ReviewItem> items,
  required String? targetCode,
  required String? nativeCode,
  bool Function(List<TrialWord> pool) playable = TrialWordPool.isPlayable,
}) {
  var last = PlayWords(const [], targetCode: targetCode, nativeCode: nativeCode);
  for (final (target, native) in bossTrialFallbackPairs(targetCode, nativeCode)) {
    final pool = TrialWordPool.build(
      items: items,
      languageCode: target ?? '',
      stock: bossTrialStockWords(targetCode: target, nativeCode: native),
    );
    last = PlayWords(pool, targetCode: target, nativeCode: native);
    if (playable(pool)) return last;
  }
  return last;
}

/// Words Bubble Bath can spell: enough of them short enough for the water,
/// and without spaces.
PlayWords bubbleBathWords({
  required List<ReviewItem> items,
  required String? targetCode,
  required String? nativeCode,
}) =>
    playWords(
      items: items,
      targetCode: targetCode,
      nativeCode: nativeCode,
      playable: (pool) =>
          BubbleWave.isPlayable(pool) && TrialWordPool.isPlayable(pool),
    );

/// A game's sentences, and the pair of languages they ended up in.
class PlaySentences {
  const PlaySentences(this.pool,
      {required this.targetCode, required this.nativeCode});

  final List<TrialSentence> pool;
  final String? targetCode;
  final String? nativeCode;
}

/// The sentences Fetch the Words is played with, falling back through the
/// same pairings as the words when the player's own cannot fill a game.
PlaySentences playSentences({
  required String? targetCode,
  required String? nativeCode,
}) {
  var last =
      PlaySentences(const [], targetCode: targetCode, nativeCode: nativeCode);
  for (final (target, native) in bossTrialFallbackPairs(targetCode, nativeCode)) {
    final pool = TrialSentencePool.build(
      bossTrialStockSentences(targetCode: target, nativeCode: native),
    );
    last = PlaySentences(pool, targetCode: target, nativeCode: native);
    if (TrialSentencePool.isPlayable(pool)) return last;
  }
  return last;
}

/// Something not got right in a game, for the results: what it says, how it
/// is read when the script is not Latin, and what it means.
class PlayPractice {
  const PlayPractice({required this.target, required this.meaning, this.reading});

  PlayPractice.word(TrialWord word)
      : target = word.target,
        meaning = word.meaning,
        reading = word.reading;

  PlayPractice.sentence(TrialSentence sentence)
      : target = sentence.target,
        meaning = sentence.meaning,
        reading = null;

  final String target;
  final String meaning;
  final String? reading;

  @override
  bool operator ==(Object other) =>
      other is PlayPractice && other.target == target && other.meaning == meaning;

  @override
  int get hashCode => Object.hash(target, meaning);
}

/// The score of one game, a round at a time.
class PlayScore {
  const PlayScore({
    this.results = const [],
    this.combo = 0,
    this.bestCombo = 0,
    this.toPractise = const [],
  });

  /// Every round so far, in order: true for right.
  final List<bool> results;
  final int combo;
  final int bestCombo;

  /// What was not got right, in order, without repeats.
  final List<PlayPractice> toPractise;

  int get played => results.length;
  int get right => results.where((r) => r).length;

  /// A round won.
  PlayScore scored() {
    final streak = combo + 1;
    return PlayScore(
      results: [...results, true],
      combo: streak,
      bestCombo: max(bestCombo, streak),
      toPractise: toPractise,
    );
  }

  /// A round lost: the streak gone and [item] listed to practise.
  PlayScore missed(PlayPractice item) => PlayScore(
        results: [...results, false],
        bestCombo: bestCombo,
        toPractise: _listing(item),
      );

  /// A slip inside a round that is not over yet — a wrong letter, a wrong
  /// stick. The streak goes at once, so the counter says so, and [item] is
  /// listed; the round itself is settled when it ends.
  PlayScore slipped(PlayPractice item) => PlayScore(
        results: results,
        bestCombo: bestCombo,
        toPractise: _listing(item),
      );

  List<PlayPractice> _listing(PlayPractice item) =>
      toPractise.contains(item) ? toPractise : [...toPractise, item];
}
