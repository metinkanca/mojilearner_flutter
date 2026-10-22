/// Lanternmaw's first round — trial 4, level 20 — in the forms under test,
/// each an attack of its own:
///
/// * **Lure.** Its lantern lights up a sentence in its language with one word
///   missing, and the player is shown the whole of it in theirs. Three fish
///   swim past carrying words for the gap: the one it needs, and two that
///   play the same part in other sentences, so the gap can only be filled by
///   what it means. The right fish is hooked and flung back; a wrong one
///   darts off and dims the lantern; the lantern going out means the gulp.
/// * **Bubbles.** It breathes out a word's meaning in the player's language,
///   and bubbles rise off the seabed carrying the letters of the word in its
///   own — spares of them too, when the word is short — with two letters it
///   does not have. Popping them in order spells it
///   and fires it back; a wrong letter feeds its gulp; the gulp landing
///   traps the pet in a bubble.
/// * **Shoal.** A school of five fish swims in, each carrying a word in its
///   language. Four belong together — animals, food, colours — and one does
///   not: tapping the stray hits it; tapping one of the four scares it off
///   and feeds its gulp. Its words come in categories, which the stock only
///   has for English and Turkish so far.
///
/// Pure, like the rest of the trial's rules: the screen owns time and layout.
library;

import 'dart:math';

// Grapheme clusters, for splitting a word into the letters a reader sees:
// "é" is one bubble however it is encoded, and so is a Korean syllable.
import 'package:flutter/widgets.dart' show StringCharacters;

import 'boss_trial.dart';

class AnglerRules {
  AnglerRules._();

  // ---- Lure -----------------------------------------------------------------

  /// Fish swimming past, the right one among them.
  static const int fish = 3;

  /// How long the lantern stays lit over a sentence of [words] words: a
  /// sentence to read and three moving fish to read after it. Four words get
  /// seven seconds while it is fresh, tightening to two thirds of that.
  static Duration lureTime({required int words, required int patience}) {
    final health = BossTrialRules.roundOneHealth(patience);
    final full = 3000 + 1000 * words;
    return Duration(milliseconds: (full * (2 + health) / 3).round());
  }

  /// How far a wrong fish dims the lantern.
  static const double lureMistakeDim = 0.25;

  // ---- Bubbles --------------------------------------------------------------

  /// Letters of the wrong word mixed in with the right ones.
  static const int decoyLetters = 2;

  /// Words spelled in fewer letters than this are not worth spelling, and
  /// more than this do not fit the water.
  static const int minLetters = 2;
  static const int maxLetters = 8;

  /// Bubbles in the water, when the word is short enough to leave room: the
  /// rest are spares of its own letters, so the one wanted next is seldom
  /// the single bubble just wrapping off the top. As many as the longest
  /// word and its strays, so the water holds them on every screen.
  static const int bubbles = maxLetters + decoyLetters;

  /// Spares of any one letter, at most: a short word is not a screen of
  /// its two letters.
  static const int maxSpares = 2;

  /// How long it takes to gulp over a word of [letters] letters: time to read
  /// the meaning, then time to find each bubble on the move. Five letters get
  /// 9.5 seconds while it is fresh, tightening to three quarters of that —
  /// moving letters are harder to find than the Spells round's still stones,
  /// so this tightens less than the other openers.
  static Duration gulpTime({required int letters, required int patience}) {
    final health = BossTrialRules.roundOneHealth(patience);
    final full = 4000 + 1100 * letters;
    return Duration(milliseconds: (full * (3 + health) / 4).round());
  }

  /// How far a wrong letter feeds the gulp.
  static const double bubbleMistakeGulp = 0.2;

  // ---- Shoal ----------------------------------------------------------------

  /// Fish in a school: the ones that belong together, and the stray.
  static const int shoalFish = 5;

  /// How long it takes to gulp a school: five words to read on the move.
  /// Seven seconds while it is fresh, tightening to two thirds of that.
  static Duration shoalTime(int patience) {
    final health = BossTrialRules.roundOneHealth(patience);
    return Duration(milliseconds: (7000 * (2 + health) / 3).round());
  }

  /// How far scaring off a fish that belonged feeds the gulp.
  static const double shoalMistakeGulp = 0.25;

  // ---- Net ------------------------------------------------------------------

  /// The most fish a school can hold, the sentence's and the strays.
  static const int netMostFish = 8;

  /// Strays in a school, at least: fewer and the net is a formality.
  static const int netStrays = 2;

  /// How long it takes to gulp a school of [fish] fish. Six get 8.4 seconds
  /// while it is fresh, tightening to two thirds of that.
  static Duration netTime({required int fish, required int patience}) {
    final health = BossTrialRules.roundOneHealth(patience);
    final full = 3000 + 900 * fish;
    return Duration(milliseconds: (full * (2 + health) / 3).round());
  }

  /// How far netting a stray feeds the gulp.
  static const double netMistakeGulp = 0.2;
}

// ---- Lure -------------------------------------------------------------------

/// One sentence on the lantern: which word is missing, and the fish that
/// could fill it.
class LureWave {
  const LureWave({
    required this.sentence,
    required this.gap,
    required this.fish,
    required this.answer,
  });

  final TrialSentence sentence;

  /// Which of its words is missing.
  final int gap;

  /// What each fish carries, in the order they swim.
  final List<String> fish;

  /// Which fish carries the missing word.
  final int answer;

  String get missing => sentence.tokens[gap];

  /// The slots of [sentence] with enough stand-ins from [pool] to fill a
  /// school: another sentence's word in the same part, meaning something
  /// else — the hex's rule, so a wrong fish always reads as a sentence.
  static List<HexSlot> _gaps(TrialSentence sentence, List<TrialSentence> pool) {
    final swaps = HexScroll.swapsFor(sentence, pool);
    return [
      for (final e in swaps.entries)
        if (e.value.length >= AnglerRules.fish - 1) e.key,
    ];
  }

  static bool canLure(TrialSentence sentence, List<TrialSentence> pool) =>
      _gaps(sentence, pool).isNotEmpty;

  /// A round needs two sentences it can lure with, so it never lights the
  /// same one twice running.
  static bool isPlayable(List<TrialSentence> pool) =>
      pool.toSet().where((s) => canLure(s, pool)).length >= 2;

  /// A lure from [pool], or null when the pool cannot make one. Never
  /// [previous] again straight away. The gap is chosen before the fish, so a
  /// verb is as likely to be missing as an object.
  static LureWave? build(
    List<TrialSentence> pool, {
    TrialSentence? previous,
    Random? random,
  }) {
    final rng = random ?? Random();
    final choices =
        pool.where((s) => s != previous && canLure(s, pool)).toList();
    if (choices.isEmpty) return null;
    final sentence = choices[rng.nextInt(choices.length)];
    final gaps = _gaps(sentence, pool);
    final gap = gaps[rng.nextInt(gaps.length)];
    final strays = [...HexScroll.swapsFor(sentence, pool)[gap]!]..shuffle(rng);
    final fish = [
      sentence.tokens[gap.index],
      ...strays.take(AnglerRules.fish - 1),
    ]..shuffle(rng);
    return LureWave(
      sentence: sentence,
      gap: gap.index,
      fish: fish,
      answer: fish.indexOf(sentence.tokens[gap.index]),
    );
  }
}

// ---- Bubbles ----------------------------------------------------------------

/// One word to spell in bubbles.
///
/// Spelled with a [SpellCast] on [spell]: the word's letters are its stones
/// in order and the bubbles are the stones on the table, so a letter the
/// word has twice can be popped from either bubble.
class BubbleWave {
  const BubbleWave({required this.word, required this.spell});

  final TrialWord word;
  final SpellWave spell;

  List<String> get letters => spell.sentence.tokens;
  List<String> get bubbles => spell.stones;

  /// The letters [target] is spelled in, as a reader sees them, or null when
  /// it cannot be spelled in bubbles: a phrase with a space in it, or too
  /// short or too long.
  static List<String>? lettersOf(String target) {
    if (target.trim() != target || target.contains(' ')) return null;
    final letters = target.characters.toList();
    if (letters.length < AnglerRules.minLetters ||
        letters.length > AnglerRules.maxLetters) {
      return null;
    }
    return letters;
  }

  static List<TrialWord> _spellable(List<TrialWord> pool) => [
        for (final w in pool)
          if (lettersOf(w.target) != null) w,
      ];

  /// A round needs two words it can spell, so the same one is never asked
  /// twice running — and letters from other words to mix in.
  static bool isPlayable(List<TrialWord> pool) =>
      _spellable(pool).toSet().length >= 2;

  /// A word from [pool] to spell, or null when the pool has none.
  ///
  /// Never [previous] again straight away. Its [AnglerRules.decoyLetters]
  /// strays are letters from the pool's other words that this word does not
  /// have — a second "a" would be a right answer marked wrong — and the rest
  /// of the room is spares of its own letters, which are right answers too.
  /// The bubbles are never laid out already spelled.
  static BubbleWave? build(
    List<TrialWord> pool, {
    TrialWord? previous,
    Random? random,
  }) {
    final rng = random ?? Random();
    final choices = _spellable(pool).where((w) => w != previous).toList();
    if (choices.isEmpty) return null;
    final word = choices[rng.nextInt(choices.length)];
    final letters = lettersOf(word.target)!;

    final own = letters.map((l) => l.toLowerCase()).toSet();
    final strays = {
      for (final w in pool)
        if (w != word)
          for (final l in w.target.characters)
            if (l.trim().isNotEmpty && !own.contains(l.toLowerCase())) l,
    }.toList()
      ..shuffle(rng);

    // Spares a pass of the word's letters at a time, so every letter has one
    // before any has two.
    final room = AnglerRules.bubbles - letters.length - AnglerRules.decoyLetters;
    final spares = [
      for (var pass = 0; pass < AnglerRules.maxSpares; pass++)
        ...([...letters]..shuffle(rng)),
    ].take(max(0, room));

    final bubbles = [
      ...letters,
      ...spares,
      ...strays.take(AnglerRules.decoyLetters),
    ]..shuffle(rng);
    // Read left to right, its own letters must not already spell it.
    List<int> real() => [
          for (var i = 0; i < bubbles.length; i++)
            if (own.contains(bubbles[i].toLowerCase())) i,
        ];
    if (real().map((i) => bubbles[i]).join() == letters.join()) {
      final idx = real();
      for (var j = 1; j < idx.length; j++) {
        if (bubbles[idx[j]] != bubbles[idx[0]]) {
          final tmp = bubbles[idx[0]];
          bubbles[idx[0]] = bubbles[idx[j]];
          bubbles[idx[j]] = tmp;
          break;
        }
      }
    }
    return BubbleWave(
      word: word,
      spell: SpellWave(
        sentence: TrialSentence(
          tokens: letters,
          target: word.target,
          meaning: word.meaning,
        ),
        stones: bubbles,
      ),
    );
  }
}

// ---- Shoal ------------------------------------------------------------------

/// One school: its fish in the order they swim, and which one is the stray.
class ShoalWave {
  const ShoalWave({
    required this.fish,
    required this.stray,
    required this.category,
  });

  final List<TrialWord> fish;
  final int stray;

  /// What the others have in common, for the results screen.
  final String category;

  TrialWord get strayWord => fish[stray];

  /// Whether [categories] can make a school: one category with enough words
  /// for the fish that belong, and another to take the stray from.
  static bool isPlayable(Map<String, List<TrialWord>> categories) =>
      categories.length >= 2 &&
      categories.values.any((w) => w.length >= AnglerRules.shoalFish - 1);

  /// A school from [categories], or null when they cannot make one.
  ///
  /// Never the same stray as [previous] straight away. A word listed under
  /// two categories never swims in a school where it could be read either
  /// way: the stray is only a stray when it belongs to none of the others'.
  static ShoalWave? build(
    Map<String, List<TrialWord>> categories, {
    TrialWord? previous,
    Random? random,
  }) {
    if (!isPlayable(categories)) return null;
    final rng = random ?? Random();
    final names = [
      for (final e in categories.entries)
        if (e.value.length >= AnglerRules.shoalFish - 1) e.key,
    ]..shuffle(rng);
    for (final name in names) {
      final members = categories[name]!;
      final strays = [
        for (final e in categories.entries)
          if (e.key != name)
            for (final w in e.value)
              if (w != previous &&
                  !members.any(
                      (m) => m.target.toLowerCase() == w.target.toLowerCase()))
                w,
      ];
      if (strays.isEmpty) continue;
      final school =
          ([...members]..shuffle(rng)).take(AnglerRules.shoalFish - 1).toList();
      final stray = strays[rng.nextInt(strays.length)];
      final fish = [...school, stray]..shuffle(rng);
      return ShoalWave(
        fish: fish,
        stray: fish.indexOf(stray),
        category: name,
      );
    }
    return null;
  }
}

// ---- Net --------------------------------------------------------------------

/// A school of fish for a sentence: every word of it, and strays that play
/// its words' parts in other sentences.
class NetWave {
  const NetWave({required this.sentence, required this.fish});

  final TrialSentence sentence;

  /// Each fish's word, and whether it belongs in the net.
  final List<(String, bool)> fish;

  int get toNet => sentence.tokens.length;

  static bool isPlayable(List<TrialSentence> pool) =>
      pool.toSet().where((s) => _fits(s)).length >= 2;

  static bool _fits(TrialSentence s) =>
      s.tokens.length + AnglerRules.netStrays <= AnglerRules.netMostFish;

  /// A school from [pool], or null when it cannot make one. Never
  /// [previous] again straight away.
  ///
  /// Strays are words a hex could swap in — the same part, meaning
  /// something else — so a stray can only be told apart by what it means,
  /// topped up with any other sentence's words the sentence does not have.
  static NetWave? build(
    List<TrialSentence> pool, {
    TrialSentence? previous,
    Random? random,
  }) {
    final rng = random ?? Random();
    final choices = pool.where((s) => s != previous && _fits(s)).toList();
    if (choices.isEmpty) return null;
    final sentence = choices[rng.nextInt(choices.length)];
    final own = sentence.tokens.map((t) => t.toLowerCase()).toSet();
    final room = AnglerRules.netMostFish - sentence.tokens.length;
    final wanted = min(room, AnglerRules.netStrays + 1);

    final swaps = [
      for (final words in HexScroll.swapsFor(sentence, pool).values) ...words,
    ]..shuffle(rng);
    final others = {
      for (final s in pool)
        if (s != sentence)
          for (final t in s.tokens)
            if (!own.contains(t.toLowerCase())) t,
    }.toList()
      ..shuffle(rng);
    final strays = <String>[];
    for (final w in [...swaps, ...others]) {
      if (strays.length == wanted) break;
      if (!strays.contains(w)) strays.add(w);
    }
    if (strays.length < AnglerRules.netStrays) return null;
    final fish = [
      for (final t in sentence.tokens) (t, true),
      for (final t in strays) (t, false),
    ]..shuffle(rng);
    return NetWave(sentence: sentence, fish: fish);
  }
}

/// What a tap on a fish did.
enum NetTap { netted, done, stray, ignored }

/// A school being netted.
class NetPlay {
  NetPlay(this.wave);

  final NetWave wave;
  final Set<int> _netted = {};
  final Set<int> _fled = {};

  bool isNetted(int fish) => _netted.contains(fish);
  bool hasFled(int fish) => _fled.contains(fish);
  int get netted => _netted.length;
  bool get isDone => _netted.length == wave.toNet;

  NetTap tap(int fish) {
    if (isDone || fish < 0 || fish >= wave.fish.length) return NetTap.ignored;
    if (_netted.contains(fish) || _fled.contains(fish)) return NetTap.ignored;
    if (!wave.fish[fish].$2) {
      _fled.add(fish);
      return NetTap.stray;
    }
    _netted.add(fish);
    return isDone ? NetTap.done : NetTap.netted;
  }
}
