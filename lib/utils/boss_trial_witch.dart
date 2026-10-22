/// The witch's first round — trial 3, level 15 — in the forms under test
/// beside her Hexed Scroll, each an attack of her own, and all about
/// sentences:
///
/// * **Mirror Clones.** She splits into three owls that fly about the arena,
///   each saying a sentence in her language. The player is shown, in theirs,
///   what the real one says; each clone says it with one word hexed. Tapping
///   the real one hits her; a clone bursts into smoke and burns her fuse. The
///   fuse running out hexes the pet.
/// * **Tangled Spells.** She tangles two spells into one heap, and their words
///   bubble out one at a time. Two cauldrons are labelled with the two
///   meanings in the player's language; each word goes into the one whose
///   spell it belongs to. Words both spells share are left out, so every word
///   has one right cauldron — and the two spells are picked to share the most
///   they can, so "bebe" and "bebo" land in different pots.
/// * **Broom Chase.** The pet chases her on a broom through word gates coming
///   in from the right, two to a column: the next word of the sentence and
///   one spelled like it. Flying through the right gate adds the word; the
///   whole sentence fires at her. A wrong gate lets her get further away and
///   offers the word again; getting away altogether hexes the pet.
///
/// Pure, like the rest of the trial's rules: the screen owns time and layout.
library;

import 'dart:math';

import 'boss_trial.dart';

class WitchRules {
  WitchRules._();

  // ---- Mirror Clones --------------------------------------------------------

  /// Owls in the air, her among them.
  static const int owls = 3;

  /// How long her fuse burns while she has clones up, for a sentence of
  /// [words] words: three sentences to read on the move. Four words get 7.8
  /// seconds while she is fresh, tightening to two thirds of that.
  static Duration cloneTime({required int words, required int patience}) {
    final health = BossTrialRules.roundOneHealth(patience);
    final full = 3000 + 1200 * words;
    return Duration(milliseconds: (full * (2 + health) / 3).round());
  }

  /// How far a clone tapped burns her fuse along.
  static const double cloneMistakeBurn = 0.25;

  // ---- Tangled Spells -------------------------------------------------------

  /// How long her fuse burns for a tangle of [words] words to sort: six get
  /// 9.8 seconds while she is fresh, tightening to two thirds of that.
  static Duration tangleTime({required int words, required int patience}) {
    final health = BossTrialRules.roundOneHealth(patience);
    final full = 2000 + 1300 * words;
    return Duration(milliseconds: (full * (2 + health) / 3).round());
  }

  /// How far a word dropped in the wrong cauldron burns the fuse along.
  static const double tangleMistakeBurn = 0.2;

  /// Fewer words left once the shared ones are out is not worth sorting.
  static const int minTangleWords = 3;

  // ---- Broom Chase ----------------------------------------------------------

  /// How long a column of gates takes from the right edge to the pet: 3.2
  /// seconds while she is fresh, 2.2 by the end of the round.
  static Duration gateTravel(int patience) {
    final health = BossTrialRules.roundOneHealth(patience);
    return Duration(milliseconds: (2200 + 1000 * health).round());
  }

  /// The beat between one column and the next: 1.6 seconds, down to 1.1.
  static Duration gateInterval(int patience) {
    final health = BossTrialRules.roundOneHealth(patience);
    return Duration(milliseconds: (1100 + 500 * health).round());
  }

  /// How long she takes to get away over a sentence of [words] words: every
  /// column's flight with nothing missed, and three seconds to spare.
  static Duration chaseTime({required int words, required int patience}) =>
      gateTravel(patience) +
      gateInterval(patience) * max(0, words - 1) +
      const Duration(milliseconds: 3000);

  /// How much further away a wrong gate lets her get.
  static const double chaseMistakeBurn = 0.25;
}

// ---- Mirror Clones ----------------------------------------------------------

/// One flight of owls: what the real one says, and what each owl says.
class CloneWave {
  const CloneWave({
    required this.sentence,
    required this.owls,
    required this.real,
  });

  final TrialSentence sentence;

  /// What each owl says, word by word, in the order they fly.
  final List<List<String>> owls;

  /// Which owl is her.
  final int real;

  /// Hexed versions of [sentence], each with one word swapped for the same
  /// part of another sentence in [pool] — different slots first, so the
  /// clones are wrong in different places.
  static List<List<String>> _variants(
    TrialSentence sentence,
    List<TrialSentence> pool,
    Random rng,
    int count,
  ) {
    final swaps = HexScroll.swapsFor(sentence, pool);
    final bySlot = [
      for (final e in swaps.entries)
        [
          for (final word in e.value) (e.key.index, word),
        ]..shuffle(rng),
    ]..shuffle(rng);
    final picked = <(int, String)>[];
    // A word from each slot in turn, then a second from each, and so on.
    for (var round = 0; picked.length < count; round++) {
      var any = false;
      for (final options in bySlot) {
        if (round < options.length && picked.length < count) {
          picked.add(options[round]);
          any = true;
        }
      }
      if (!any) break;
    }
    return [
      for (final (index, word) in picked) [...sentence.tokens]..[index] = word,
    ];
  }

  /// Whether [sentence] can be split into a full flight.
  static bool canClone(TrialSentence sentence, List<TrialSentence> pool) {
    final swaps = HexScroll.swapsFor(sentence, pool);
    return swaps.values.fold(0, (n, words) => n + words.length) >=
        WitchRules.owls - 1;
  }

  /// A round needs two sentences she can clone, so she never says the same
  /// one twice running.
  static bool isPlayable(List<TrialSentence> pool) =>
      pool.toSet().where((s) => canClone(s, pool)).length >= 2;

  /// A flight from [pool], or null when the pool cannot make one. Never
  /// [previous] again straight away.
  static CloneWave? build(
    List<TrialSentence> pool, {
    TrialSentence? previous,
    Random? random,
  }) {
    final rng = random ?? Random();
    final choices =
        pool.where((s) => s != previous && canClone(s, pool)).toList();
    if (choices.isEmpty) return null;
    final sentence = choices[rng.nextInt(choices.length)];
    final clones = _variants(sentence, pool, rng, WitchRules.owls - 1);
    final owls = [sentence.tokens, ...clones]..shuffle(rng);
    return CloneWave(
      sentence: sentence,
      owls: owls,
      real: owls.indexOf(sentence.tokens),
    );
  }
}

// ---- Tangled Spells ---------------------------------------------------------

/// A word out of the tangle, and which spell it belongs to.
class TangleWord {
  const TangleWord({required this.word, required this.first});

  final String word;

  /// Whether it belongs to [TangleWave.first] rather than
  /// [TangleWave.second].
  final bool first;
}

/// Two spells tangled together, and their words in the order they come out.
class TangleWave {
  const TangleWave({
    required this.first,
    required this.second,
    required this.words,
  });

  final TrialSentence first;
  final TrialSentence second;
  final List<TangleWord> words;

  /// The words of [a] and [b] that only one of them has, shuffled.
  static List<TangleWord> _untangle(
    TrialSentence a,
    TrialSentence b,
    Random rng,
  ) {
    final inA = a.tokens.map((t) => t.toLowerCase()).toSet();
    final inB = b.tokens.map((t) => t.toLowerCase()).toSet();
    return [
      for (final t in a.tokens)
        if (!inB.contains(t.toLowerCase())) TangleWord(word: t, first: true),
      for (final t in b.tokens)
        if (!inA.contains(t.toLowerCase())) TangleWord(word: t, first: false),
    ]..shuffle(rng);
  }

  /// Whether [pool] can tangle two spells with enough words between them.
  static bool isPlayable(List<TrialSentence> pool) {
    final rng = Random(0);
    for (final a in pool) {
      for (final b in pool) {
        if (a.meaning.toLowerCase() == b.meaning.toLowerCase()) continue;
        if (_untangle(a, b, rng).length >= WitchRules.minTangleWords) {
          return true;
        }
      }
    }
    return false;
  }

  /// A tangle from [pool], or null when the pool cannot make one.
  ///
  /// The first spell is never [previous] again straight away; the second is
  /// the one sharing the most [TrialSentence.concepts] with it, so the two
  /// are about the same things and the words have to be read, not guessed
  /// from the topic. Equally near ones take turns.
  static TangleWave? build(
    List<TrialSentence> pool, {
    TrialSentence? previous,
    Random? random,
  }) {
    final rng = random ?? Random();
    final firsts = pool.where((s) => s != previous).toList()..shuffle(rng);
    for (final first in firsts) {
      final seconds = pool
          .where((s) => s.meaning.toLowerCase() != first.meaning.toLowerCase())
          .toList()
        ..shuffle(rng);
      int shared(TrialSentence s) =>
          s.concepts.intersection(first.concepts).length;
      final order = List.generate(seconds.length, (i) => i)
        ..sort((a, b) {
          final byShared = shared(seconds[b]).compareTo(shared(seconds[a]));
          return byShared != 0 ? byShared : a.compareTo(b);
        });
      for (final i in order) {
        final words = _untangle(first, seconds[i], rng);
        if (words.length >= WitchRules.minTangleWords) {
          return TangleWave(first: first, second: seconds[i], words: words);
        }
      }
    }
    return null;
  }
}

// ---- Broom Chase ------------------------------------------------------------

/// One column of gates: the word the sentence needs next, the one spelled
/// like it, and which lane the right one is in.
class ChaseGate {
  const ChaseGate({
    required this.word,
    required this.decoy,
    required this.upper,
  });

  final String word;
  final String decoy;

  /// Whether the right gate is the upper one.
  final bool upper;
}

/// A sentence to chase her down with, a column of gates for each word.
class ChaseWave {
  const ChaseWave({required this.sentence, required this.decoys});

  final TrialSentence sentence;

  /// For each word of the sentence, the word spelled most like it that the
  /// sentence does not have.
  final List<String> decoys;

  /// The column for word [index], its lanes dealt by [rng].
  ChaseGate gate(int index, Random rng) => ChaseGate(
        word: sentence.tokens[index],
        decoy: decoys[index],
        upper: rng.nextBool(),
      );

  static bool isPlayable(List<TrialSentence> pool) =>
      TrialSentencePool.isPlayable(pool);

  /// A chase from [pool], or null when the pool cannot make one.
  ///
  /// Never [previous] again straight away. Decoys come from the other
  /// sentences, never match a word of this one, and are the closest in
  /// spelling — "bebe" beside "bebo" — with ties broken by the shuffle.
  static ChaseWave? build(
    List<TrialSentence> pool, {
    TrialSentence? previous,
    Random? random,
  }) {
    final rng = random ?? Random();
    final choices = pool.where((s) => s != previous).toList();
    if (choices.isEmpty) return null;
    final sentence = choices[rng.nextInt(choices.length)];
    final own = sentence.tokens.map((t) => t.toLowerCase()).toSet();
    final candidates = {
      for (final s in pool)
        if (s != sentence)
          for (final t in s.tokens)
            if (!own.contains(t.toLowerCase())) t,
    }.toList()
      ..shuffle(rng);
    if (candidates.isEmpty) return null;
    String closest(String token) =>
        candidates.reduce((a, b) => SpellWave.spellingDistance(b, token) <
                SpellWave.spellingDistance(a, token)
            ? b
            : a);
    return ChaseWave(
      sentence: sentence,
      decoys: [for (final t in sentence.tokens) closest(t)],
    );
  }
}
