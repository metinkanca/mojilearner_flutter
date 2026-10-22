/// Mossback's first round — trial 1, level 5 — in the forms under test beside
/// its Catch, each an attack of its own:
///
/// * **Shell Game.** It shouts a word and three stone cups flash up their
///   meanings for a moment, then flip face-down and shuffle, more and faster
///   as it tires. Follow the right cup: a pick only counts once the cups
///   stop, and is worth the most made the moment they do. A wrong cup costs
///   a heart, like a wrong piece in Catch; never picking costs only the
///   streak.
/// * **Pebble Pop.** A meaning in the player's language is shown, and pebbles
///   pop up out of holes in the moss carrying words in the boss's, ducking
///   back after a moment. Bonk the one that says it — it comes up twice. A
///   wrong pebble costs a heart; letting every pop go by costs the streak.
/// * **Stepping Stones.** The pet crosses a river to Mossback a row at a time.
///   For each row it shouts a word and three stones show meanings; hopping
///   onto the right one banks a small hit, and the stone the pet stands on
///   starts to sink. The far bank lands every banked hit at once as a
///   headbutt. A wrong stone costs a heart and dunks the pet back to the
///   start, the bank lost; a stone sinking under it dunks it for the streak.
///
/// Word rounds, like Catch, on the same pool: the player's own words first.
/// Pure, like the rest of the trial's rules: the screen owns time and layout.
library;

import 'dart:math';

import 'boss_trial.dart';

class MossRules {
  MossRules._();

  // ---- Shell Game -----------------------------------------------------------

  static const int cups = 3;

  /// How long the cups show their meanings before they flip: 2.4 seconds
  /// while the boss is fresh, 1.6 by the end of the round.
  static Duration revealTime(int patience) {
    final health = BossTrialRules.roundOneHealth(patience);
    return Duration(milliseconds: (1600 + 800 * health).round());
  }

  /// Swaps in the shuffle: three while it is fresh, up to six.
  static int swapCount(int patience) =>
      (6 - 3 * BossTrialRules.roundOneHealth(patience)).round();

  /// How long one swap takes: half a second, down to a third.
  static Duration swapTime(int patience) {
    final health = BossTrialRules.roundOneHealth(patience);
    return Duration(milliseconds: (330 + 170 * health).round());
  }

  /// After the shuffle, how long the cups wait for a pick.
  static const Duration pickTime = Duration(milliseconds: 4000);

  // ---- Pebble Pop -----------------------------------------------------------

  /// Holes in the moss, in two rows of three.
  static const int holes = 6;

  /// Pebbles popped in one wave. The one asked for is two of them.
  static const int popsPerWave = 7;

  /// How long a pebble stays up: 1.8 seconds, down to 1.1.
  static Duration popUp(int patience) {
    final health = BossTrialRules.roundOneHealth(patience);
    return Duration(milliseconds: (1100 + 700 * health).round());
  }

  /// The beat between one pop and the next: 0.9 seconds, down to 0.6. With
  /// the time up, two are up at once.
  static Duration popInterval(int patience) {
    final health = BossTrialRules.roundOneHealth(patience);
    return Duration(milliseconds: (600 + 300 * health).round());
  }

  // ---- Stepping Stones ------------------------------------------------------

  /// Rows of stones between the bank and the ledge.
  static const int rows = 4;

  static const int stonesPerRow = 3;

  /// How long the pet has to choose each hop before the stone under it — or,
  /// for the first, the tide on the bank — takes it: five seconds, down to
  /// 3.2.
  static Duration sinkTime(int patience) {
    final health = BossTrialRules.roundOneHealth(patience);
    return Duration(milliseconds: (3200 + 1800 * health).round());
  }
}

/// [pool]'s words with a meaning other than [word]'s, and [count] of them at
/// most, each meaning once.
List<TrialWord> _others(
  TrialWord word,
  List<TrialWord> pool,
  Random rng,
  int count,
) {
  final meanings = {word.meaning.toLowerCase()};
  final picked = <TrialWord>[];
  for (final w in [...pool]..shuffle(rng)) {
    if (picked.length == count) break;
    if (w.target.toLowerCase() == word.target.toLowerCase()) continue;
    if (meanings.add(w.meaning.toLowerCase())) picked.add(w);
  }
  return picked;
}

// ---- Shell Game -------------------------------------------------------------

/// One shell game: the word shouted, the meanings under the cups, and the
/// shuffle.
class ShellGame {
  const ShellGame({
    required this.prompt,
    required this.cups,
    required this.swaps,
  });

  final TrialWord prompt;

  /// What is under each cup, by cup, in the places they start in.
  final List<TrialWord> cups;

  /// The shuffle: pairs of places whose cups trade, in order.
  final List<(int, int)> swaps;

  /// The cup hiding the meaning of what was shouted.
  int get answer => cups.indexOf(prompt);

  /// Where each cup is after the first [done] swaps: `places[cup]`.
  List<int> placesAfter(int done) {
    final places = List.generate(cups.length, (i) => i);
    for (final (a, b) in swaps.take(done)) {
      final atA = places.indexOf(a);
      final atB = places.indexOf(b);
      places[atA] = b;
      places[atB] = a;
    }
    return places;
  }

  /// A game from [pool], or null when the pool cannot make a fair one.
  ///
  /// Never shouts [previous] again straight away. The cup hiding the answer
  /// is in two swaps out of three, so following it is the game, and a swap
  /// never trades a place with itself.
  static ShellGame? build(
    List<TrialWord> pool, {
    TrialWord? previous,
    Random? random,
    int swaps = 3,
  }) {
    final rng = random ?? Random();
    final prompts = pool.where((w) => w != previous).toList();
    if (prompts.isEmpty) return null;
    final prompt = prompts[rng.nextInt(prompts.length)];
    final others = _others(prompt, pool, rng, MossRules.cups - 1);
    if (others.length < MossRules.cups - 1) return null;
    final cups = [prompt, ...others]..shuffle(rng);

    final moves = <(int, int)>[];
    var at = cups.indexOf(prompt);
    for (var i = 0; i < swaps; i++) {
      final withAnswer = rng.nextInt(3) < 2;
      final a = withAnswer ? at : rng.nextInt(MossRules.cups);
      var b = rng.nextInt(MossRules.cups - 1);
      if (b >= a) b++;
      moves.add((a, b));
      if (a == at) {
        at = b;
      } else if (b == at) {
        at = a;
      }
    }
    return ShellGame(prompt: prompt, cups: cups, swaps: moves);
  }
}

// ---- Pebble Pop -------------------------------------------------------------

/// One pebble popping up: the word it carries, and the hole it comes out of.
class PebblePop {
  const PebblePop({required this.word, required this.hole});

  final TrialWord word;
  final int hole;
}

/// One wave of pebbles: the meaning asked for, and every pop in order.
class PebbleWave {
  const PebbleWave({required this.prompt, required this.pops});

  /// The word whose meaning is shown; its pebble is the one to bonk.
  final TrialWord prompt;
  final List<PebblePop> pops;

  bool isRight(PebblePop pop) => pop.word == prompt;

  /// A wave from [pool], or null when the pool cannot make a fair one.
  ///
  /// The word asked for pops up twice — once early, once late — so missing
  /// it once is not the end; it is never the first pop, so the player reads
  /// a decoy first. No decoy means the same as it. A pebble never comes out
  /// of a hole either of the two before it used, since those may still be
  /// up.
  static PebbleWave? build(
    List<TrialWord> pool, {
    TrialWord? previous,
    Random? random,
    int count = MossRules.popsPerWave,
  }) {
    final rng = random ?? Random();
    final prompts = pool.where((w) => w != previous).toList();
    if (prompts.isEmpty || count < 4) return null;
    final prompt = prompts[rng.nextInt(prompts.length)];
    final decoys = _others(prompt, pool, rng, count);
    if (decoys.length < 2) return null;

    final early = 1 + rng.nextInt(2);
    final late = count ~/ 2 + 1 + rng.nextInt(count - count ~/ 2 - 1);
    final words = <TrialWord>[];
    var d = 0;
    for (var i = 0; i < count; i++) {
      if (i == early || i == late) {
        words.add(prompt);
      } else {
        words.add(decoys[d++ % decoys.length]);
      }
    }

    final pops = <PebblePop>[];
    for (final word in words) {
      final busy = pops.reversed.take(2).map((p) => p.hole).toSet();
      final free = [
        for (var h = 0; h < MossRules.holes; h++)
          if (!busy.contains(h)) h,
      ];
      pops.add(PebblePop(word: word, hole: free[rng.nextInt(free.length)]));
    }
    return PebbleWave(prompt: prompt, pops: pops);
  }
}

// ---- Stepping Stones --------------------------------------------------------

/// One row of the river: the word shouted, and the stones offered for it.
class CrossingRow {
  const CrossingRow({
    required this.prompt,
    required this.stones,
    required this.lanes,
  });

  final TrialWord prompt;

  /// The meanings on the stones, left to right.
  final List<TrialWord> stones;

  /// The lane (of [BossTrialRules.wordsPerWave]) each stone sits in.
  final List<int> lanes;

  int get answer => stones.indexOf(prompt);
}

/// A way across the river, bank to ledge.
class Crossing {
  const Crossing(this.rows);

  final List<CrossingRow> rows;

  /// A crossing from [pool], or null when the pool cannot make one.
  ///
  /// Each row shouts a different word while the pool allows. Its stones take
  /// three of the four lanes, and the right one is never in the lane of the
  /// row before's — the pet should have to move, not just hop straight up.
  static Crossing? build(
    List<TrialWord> pool, {
    Random? random,
    int rows = MossRules.rows,
  }) {
    final rng = random ?? Random();
    if (pool.isEmpty) return null;
    final deck = [...pool]..shuffle(rng);
    const lanes = BossTrialRules.wordsPerWave;
    final built = <CrossingRow>[];
    int? lastLane;
    for (var r = 0; r < rows; r++) {
      final prompt = deck[r % deck.length];
      final others = _others(prompt, pool, rng, MossRules.stonesPerRow - 1);
      if (others.length < MossRules.stonesPerRow - 1) return null;
      final stones = [prompt, ...others]..shuffle(rng);
      List<int> places;
      do {
        places = (List.generate(lanes, (i) => i)..shuffle(rng))
            .take(MossRules.stonesPerRow)
            .toList()
          ..sort();
      } while (places[stones.indexOf(prompt)] == lastLane);
      lastLane = places[stones.indexOf(prompt)];
      built.add(CrossingRow(prompt: prompt, stones: stones, lanes: places));
    }
    return Crossing(built);
  }
}
