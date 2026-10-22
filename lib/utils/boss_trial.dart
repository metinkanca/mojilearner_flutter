/// Milestone boss trials: the rules of every round.
///
/// A trial is the player proving a level band, in the boss's own language —
/// the language being learned — and it comes in two rounds: one where the
/// player shows they *understand*, from full patience down to
/// [BossTrialRules.spellPhaseAt], and one where they *answer*, for the rest.
/// Each boss asks its own version of the two.
///
/// A boss spans five levels ([TrialPlan]): each of its four openings alone,
/// after which it gets away — and then its finale, every opening a round and
/// then the Spells round. Each round has its own patience, laid over the
/// whole fight's for its clocks.
///
/// * **Catch** (Mossback's first round). The boss shouts a word and four
///   pieces of rubble fall, each carrying a meaning in the player's language.
///   Picking the one that means what was shouted gets it thrown back. A wrong
///   piece costs a heart; letting a wave land costs only the combo.
/// * **Hexed Scroll** (the witch's first round, level 15). The boss reads a
///   whole sentence in its language with one word swapped for another, and
///   the player, shown what it should say in their own, taps the swapped word
///   before a fuse burns down. A wrong word burns the fuse; the fuse running
///   out costs a heart.
/// * **The openers under test**, beside the two above: Mossback's Shell
///   Game, Pebble Pop and Stepping Stones in `boss_trial_moss.dart`,
///   Amethyst's Crystal Spikes, Crystal Echo and Shard Volley in
///   `boss_trial_crystal.dart`, and the witch's Mirror Clones, Tangled Spells
///   and Broom Chase in `boss_trial_witch.dart`.
/// * **Spells** (every boss's second round). The player is given a sentence
///   in their own language and word stones in the boss's, and casts it back by
///   tapping the stones in order. The boss charges an attack meanwhile. A
///   wrong stone fizzles and feeds the charge; the charge landing costs a
///   heart. Amethyst lays out two decoys; the witch lays out two picked to
///   look like the real words.
///
/// Pure and provider-free, like the bond and gold rules, so the curves can be
/// tuned and tested without a widget tree. The screen owns time and layout;
/// this file owns what an answer is worth.
library;

import 'dart:math';

import '../models/models.dart';

class BossTrialRules {
  BossTrialRules._();

  static const int maxHearts = 3;
  static const int maxPatience = 100;
  static const int wordsPerWave = 4;

  /// The patience the Catch clock is read down to: an opening's clocks tighten
  /// from [maxPatience] to here across the round, however long it is (see
  /// [TrialPlan.clockPatience]).
  static const int spellPhaseAt = 50;

  /// How long a wave takes to land, at the start of the Catch round and at
  /// its end.
  ///
  /// The clock tightens as the boss weakens, so each round gets harder exactly
  /// as the player starts winning it and the last hits are the ones earned.
  /// Five seconds is enough to read four short words; three is enough only
  /// for a word the player actually knows.
  static const Duration readTimeFresh = Duration(milliseconds: 5000);
  static const Duration readTimeNearlyBeaten = Duration(milliseconds: 3000);

  /// The beat between one wave resolving and the next jump starting.
  ///
  /// Shorter than it looks: the boss's jump and shout take most of another
  /// second before the next rubble breaks loose, and that is a beat too.
  static const Duration waveGap = Duration(milliseconds: 600);

  /// Damage is [baseDamage], plus [comboDamage] per catch in the current
  /// streak, plus up to [quickDamage] for answering while the wave is still
  /// high. Knowing a word instantly is worth more than working it out, but a
  /// slow right answer is never worth less than the base.
  static const int baseDamage = 10;
  static const int comboDamage = 2;
  static const int quickDamage = 8;

  /// The streak counts toward damage up to here and no further: a round is
  /// many answers long, and a bonus that kept growing would make a long
  /// streak end it in half the time a slower player takes.
  static const int maxComboBonus = 5;

  /// Words longer than this — on either side — are left out of the pool: a
  /// tile is a quarter of a phone's width, and a word shrunk to fit it stops
  /// being readable at a glance, which is the whole test.
  static const int maxWordLength = 12;

  /// Read time for a wave thrown at [patience].
  ///
  /// Spread over the Catch round's own band of patience, not the whole bar,
  /// so the round really does reach its tightest clock before it ends.
  static Duration readTime(int patience) {
    final health = roundOneHealth(patience);
    final fresh = readTimeFresh.inMilliseconds;
    final beaten = readTimeNearlyBeaten.inMilliseconds;
    return Duration(milliseconds: (beaten + (fresh - beaten) * health).round());
  }

  /// How much of the first round's band of patience the boss still has, from
  /// 1 at full patience to 0 at [spellPhaseAt]. Every first-round clock
  /// tightens along it.
  static double roundOneHealth(int patience) =>
      ((patience - spellPhaseAt) / (maxPatience - spellPhaseAt))
          .clamp(0.0, 1.0);

  // ---- the Spells round ---------------------------------------------------

  /// Word stones laid out that are not in the sentence.
  static const int decoyStones = 1;

  /// Sentences longer than this many stones are left out: two rows of stones
  /// on a phone is the most that still reads as one sentence.
  static const int maxSentenceWords = 6;

  /// Damage for a catch that brings the streak to [combo], committed with
  /// [earliness] of the fall still to go (1 = the moment it was thrown).
  ///
  /// A broken hex is worth the same, with [earliness] the fuse left.
  static int damage({required int combo, required double earliness}) =>
      baseDamage +
      min(combo, maxComboBonus) * comboDamage +
      (earliness.clamp(0.0, 1.0) * quickDamage).round();

  /// Damage for one of many small answers in an attack that asks several at
  /// once — a spike matched, a shard called — bringing the streak to [combo]
  /// with [earliness] of its clock to go.
  ///
  /// Worth about a third of a catch, because a wave asks four and a volley
  /// six: the first round still takes two attacks or so, the way Mossback's
  /// takes three or four catches.
  static int shardDamage({required int combo, required double earliness}) =>
      shardBaseDamage +
      min(combo, maxComboBonus) * shardComboDamage +
      (earliness.clamp(0.0, 1.0) * shardQuickDamage).round();

  static const int shardBaseDamage = 3;
  static const int shardComboDamage = 1;
  static const int shardQuickDamage = 2;

  // ---- the Hexed Scroll ---------------------------------------------------

  /// How long the fuse on a scroll of [words] words burns, at [patience].
  ///
  /// Two seconds to take in the scroll plus one a word while the boss is
  /// fresh, tightening to two thirds of that by the end of the round: four
  /// words go from six seconds to four. Spread over the round's own band of
  /// patience, the way the Catch clock is.
  static Duration fuseTime({required int words, required int patience}) {
    final health = ((patience - spellPhaseAt) / (maxPatience - spellPhaseAt))
        .clamp(0.0, 1.0);
    final full = 2000 + 1000 * words;
    return Duration(milliseconds: (full * (2 + health) / 3).round());
  }

  /// How far one wrong word burns the fuse along.
  ///
  /// A wrong word is a guess among a handful, so it costs more than a wrong
  /// stone: guessing through a four-word scroll burns it out, one slip
  /// never does.
  static const double hexMistakeBurn = 0.25;

  /// Word stones laid out for the witch's spells: more than Mossback's one,
  /// and chosen by [SpellWave.build] to look like the real words.
  static const int nearMissDecoyStones = 2;

  // ---- the levels ---------------------------------------------------------

  /// Levels each boss spans: one for each of its four openings, fought
  /// alone — it gets away at the end — and then its finale, where it fights
  /// with all four in a row and is beaten for good.
  static const int levelsPerBoss = 5;

  /// Hearts given back as each later round of a finale begins, up to
  /// [maxHearts], so a slip in its first round does not decide its fifth.
  static const int finaleHeartsBack = 1;

  /// How long each round of a finale is, as a share of the same opening's
  /// own level: four rounds back to back stay brisk.
  static const double finaleRoundShare = 0.5;
}

/// One round of a trial: what it is fought with, and the stretch of the
/// boss's patience it takes.
class TrialRound {
  const TrialRound({required this.opening, required this.from, required this.to});

  /// Which of the boss's openings it is fought with, by its place in the
  /// boss's list.
  final int opening;

  /// The patience it starts at, and the patience it is won at.
  final int from;
  final int to;

  int get hp => from - to;
}

/// The rounds of one trial, from where it sits among its boss's levels.
///
/// A boss's first levels are its openings, one each, and the boss gets away
/// when its round is won. Its last level is its finale: every opening a
/// round, one after another, and it is beaten for good. Every round has
/// its own patience, and its clocks run from fresh to tightest across it
/// whatever its length ([clockPatience]).
class TrialPlan {
  const TrialPlan._(this.rounds);

  /// The plan for [step] of a boss's levels, counted from 0, for a boss
  /// whose openings take [openingHp] patience each: one of them alone, or
  /// past them the finale, where each round is [finaleRoundShare] of its
  /// full length.
  factory TrialPlan.forStep(int step, {required List<int> openingHp}) {
    if (step < openingHp.length) {
      return TrialPlan._([
        TrialRound(opening: step, from: openingHp[step], to: 0),
      ]);
    }
    int finale(int hp) => (hp * BossTrialRules.finaleRoundShare).round();
    return TrialPlan._([
      for (var i = 0; i < openingHp.length; i++)
        TrialRound(opening: i, from: finale(openingHp[i]), to: 0),
    ]);
  }

  /// [patience] in [round], as the clocks read it.
  ///
  /// Every clock was written for one whole fight: an opening's tightening
  /// from [BossTrialRules.maxPatience] down to
  /// [BossTrialRules.spellPhaseAt]. A round of any length is laid over that
  /// stretch, so its clocks run from fresh to tightest across it.
  int clockPatience(int round, int patience) {
    final here = rounds[round];
    final left = ((patience - here.to) / here.hp).clamp(0.0, 1.0);
    const half = BossTrialRules.spellPhaseAt;
    return (half + (BossTrialRules.maxPatience - half) * left).round();
  }

  final List<TrialRound> rounds;

  /// Whether the boss is beaten for good at the end, rather than getting
  /// away.
  bool get isFinale => rounds.length > 1;

  int get lastRound => rounds.length - 1;

  /// Patience over the whole trial.
  int get totalHp => rounds.fold(0, (sum, r) => sum + r.hp);

  /// Patience the boss has left over the whole trial, at [patience] in
  /// [round].
  int hpLeft(int round, int patience) {
    final here = rounds[round];
    var left = (patience - here.to).clamp(0, here.hp);
    for (final later in rounds.skip(round + 1)) {
      left += later.hp;
    }
    return left;
  }

  /// A fresh run, starting at [round].
  TrialRun start({int round = 0}) => TrialRun(
        patience: rounds[round].from,
        endsAt: rounds[round].to,
        last: round == lastRound,
      );

  /// [run], its last round won, carried into [round].
  TrialRun enter(TrialRun run, int round) => run.intoRound(
        patience: rounds[round].from,
        endsAt: rounds[round].to,
        last: round == lastRound,
        heartsBack: BossTrialRules.finaleHeartsBack,
      );
}

/// One word the boss can throw.
class TrialWord {
  const TrialWord({required this.target, required this.meaning, this.reading});

  /// What the boss shouts: the word in the language being learned.
  final String target;

  /// What the rubble carries: the word in the player's own language.
  final String meaning;

  /// Romanised pronunciation for non-Latin scripts. Shown on the results
  /// screen only, the way the quiz holds it back until after the answer.
  final String? reading;

  @override
  bool operator ==(Object other) =>
      other is TrialWord && other.target == target && other.meaning == meaning;

  @override
  int get hashCode => Object.hash(target, meaning);
}

/// Builds the pool a trial draws from.
class TrialWordPool {
  TrialWordPool._();

  /// The player's own vocabulary first, topped up with [stock].
  ///
  /// Only vocabulary items qualify: a correction is a whole sentence and will
  /// not fit a tile. Both lists are de-duplicated on the target word, so a
  /// word the player has already met is never thrown twice in one wave. A
  /// word spelled the same in both languages is left out too — the rubble
  /// would simply repeat the shout, which tests nothing.
  static List<TrialWord> build({
    required List<ReviewItem> items,
    required String languageCode,
    List<TrialWord> stock = const [],
  }) {
    final seen = <String>{};
    final pool = <TrialWord>[];

    void add(TrialWord word) {
      final target = word.target.trim();
      final meaning = word.meaning.trim();
      if (target.isEmpty || meaning.isEmpty) return;
      if (target.runes.length > BossTrialRules.maxWordLength) return;
      if (meaning.runes.length > BossTrialRules.maxWordLength) return;
      if (target.toLowerCase() == meaning.toLowerCase()) return;
      if (!seen.add(target.toLowerCase())) return;
      pool.add(TrialWord(target: target, meaning: meaning, reading: word.reading));
    }

    for (final item in items) {
      if (item.languageCode != languageCode) continue;
      if (item.kind != ReviewItemKind.vocabulary) continue;
      add(TrialWord(
        target: item.prompt,
        meaning: item.answer,
        reading: item.reading,
      ));
    }
    stock.forEach(add);
    return pool;
  }

  /// Whether [pool] can keep throwing fair waves.
  ///
  /// Counted on meanings, not words: a wave never holds two tiles that mean
  /// the same thing, so four words where two are synonyms cannot fill one —
  /// and a count on words alone would start the fight and end it on the
  /// first throw.
  static bool isPlayable(List<TrialWord> pool) =>
      pool.map((w) => w.meaning.toLowerCase()).toSet().length >=
      BossTrialRules.wordsPerWave;
}

/// One throw: the word asked for, and the four tiles in lane order.
class TrialWave {
  const TrialWave({required this.prompt, required this.lanes});

  final TrialWord prompt;
  final List<TrialWord> lanes;

  int get answerLane => lanes.indexOf(prompt);

  /// A wave from [pool], or null when the pool cannot make a fair one.
  ///
  /// Never repeats [previous] as the prompt, so a wrong guess is not simply
  /// asked again. Every tile carries a different meaning: the rubble shows
  /// meanings, so two pieces both reading "house" would either make a right
  /// answer count as wrong or show the same tile twice.
  static TrialWave? build(
    List<TrialWord> pool, {
    TrialWord? previous,
    Random? random,
  }) {
    final rng = random ?? Random();
    final prompts = pool.where((w) => w != previous).toList();
    if (prompts.isEmpty) return null;
    final prompt = prompts[rng.nextInt(prompts.length)];

    final meanings = {prompt.meaning.toLowerCase()};
    final lanes = [prompt];
    for (final w in pool.where((w) => w != prompt).toList()..shuffle(rng)) {
      if (lanes.length == BossTrialRules.wordsPerWave) break;
      if (meanings.add(w.meaning.toLowerCase())) lanes.add(w);
    }
    if (lanes.length < BossTrialRules.wordsPerWave) return null;

    lanes.shuffle(rng);
    return TrialWave(prompt: prompt, lanes: lanes);
  }
}

// ---- the Spells round -------------------------------------------------------

/// A sentence the player casts back at the boss.
class TrialSentence {
  const TrialSentence({
    required this.tokens,
    required this.target,
    required this.meaning,
    this.slots = const [],
    this.concepts = const {},
  });

  /// The word stones, in the order they must be cast, in the language being
  /// learned.
  final List<String> tokens;

  /// The same sentence written out, for the results screen — joined the way
  /// its language joins words, which is not always with spaces.
  final String target;

  /// What the player is asked to say, in their own language.
  final String meaning;

  /// The words a hex may swap out, and what they mean. Empty for a sentence
  /// that can only be cast, never hexed.
  final List<HexSlot> slots;

  /// What it is about, the same in every language — who, doing what, to
  /// what: {"me", "drink", "water"}. Amethyst's echo offers meanings that
  /// share the most of these as its wrong answers. Empty when unknown.
  final Set<String> concepts;

  @override
  bool operator ==(Object other) =>
      other is TrialSentence && other.target == target;

  @override
  int get hashCode => target.hashCode;
}

/// Builds the sentence pool a Spells round draws from.
class TrialSentencePool {
  TrialSentencePool._();

  /// [sentences] that fit the stones: between two and
  /// [BossTrialRules.maxSentenceWords] of them, each short enough for a stone.
  static List<TrialSentence> build(List<TrialSentence> sentences) => [
        for (final s in sentences)
          if (s.tokens.length >= 2 &&
              s.tokens.length <= BossTrialRules.maxSentenceWords &&
              s.meaning.trim().isNotEmpty &&
              s.tokens.every((t) =>
                  t.trim().isNotEmpty &&
                  t.runes.length <= BossTrialRules.maxWordLength))
            s,
      ];

  /// A round needs two sentences, so the same one is never cast twice in a
  /// row.
  static bool isPlayable(List<TrialSentence> pool) => pool.toSet().length >= 2;
}

/// One spell to cast: its sentence and the stones laid out for it.
class SpellWave {
  const SpellWave({required this.sentence, required this.stones});

  final TrialSentence sentence;

  /// Every stone on the table, shuffled: the sentence's own and the decoys.
  final List<String> stones;

  /// A spell from [pool], or null when the pool cannot make one.
  ///
  /// Never repeats [previous]. [decoys] decoys come from the other sentences,
  /// and never match any word of this one — a decoy "the" beside a real "the"
  /// would be a right answer marked wrong. With [nearMiss] they are the words
  /// spelled most like this sentence's own, so "bebe" lies beside "bebo" and
  /// a half-known ending is a trap; without it they are drawn at random. The
  /// stones are never laid out already in order, which would cast the spell
  /// for the player.
  static SpellWave? build(
    List<TrialSentence> pool, {
    TrialSentence? previous,
    Random? random,
    int decoys = BossTrialRules.decoyStones,
    bool nearMiss = false,
  }) {
    final rng = random ?? Random();
    final choices = pool.where((s) => s != previous).toList();
    if (choices.isEmpty) return null;
    final sentence = choices[rng.nextInt(choices.length)];

    final own = sentence.tokens.map((t) => t.toLowerCase()).toSet();
    var decoyPool = {
      for (final s in pool)
        if (s != sentence)
          for (final t in s.tokens)
            if (!own.contains(t.toLowerCase())) t,
    }.toList()
      ..shuffle(rng);
    if (nearMiss) {
      // Closest first, and among equally close words the one sharing the
      // longest start with a real word — a stem, since these languages mostly
      // inflect at the end: for "я пью воду", "пьёт" before "вижу". The
      // shuffle above breaks what ties remain, so they take turns.
      final likeness = [
        for (final t in decoyPool)
          sentence.tokens
              .map((s) => (spellingDistance(t, s), -_sharedStart(t, s)))
              .reduce((a, b) =>
                  a.$1 < b.$1 || (a.$1 == b.$1 && a.$2 <= b.$2) ? a : b),
      ];
      final order = List.generate(decoyPool.length, (i) => i)
        ..sort((a, b) {
          final byDistance = likeness[a].$1.compareTo(likeness[b].$1);
          if (byDistance != 0) return byDistance;
          final byStart = likeness[a].$2.compareTo(likeness[b].$2);
          return byStart != 0 ? byStart : a.compareTo(b);
        });
      decoyPool = [for (final i in order) decoyPool[i]];
    }
    final picked = decoyPool.take(decoys);

    final stones = [...sentence.tokens, ...picked]..shuffle(rng);
    // Decoys never match the sentence, so the sentence's own stones, read in
    // layout order, are exactly what a player tapping left to right would
    // cast.
    List<int> real() => [
          for (var i = 0; i < stones.length; i++)
            if (own.contains(stones[i].toLowerCase())) i,
        ];
    bool solved() =>
        real().map((i) => stones[i]).join(' ') ==
        sentence.tokens.join(' ');
    if (solved()) {
      // Swap the first two of its stones that differ.
      final idx = real();
      for (var j = 1; j < idx.length; j++) {
        if (stones[idx[j]] != stones[idx[0]]) {
          final tmp = stones[idx[0]];
          stones[idx[0]] = stones[idx[j]];
          stones[idx[j]] = tmp;
          break;
        }
      }
    }
    return SpellWave(sentence: sentence, stones: stones);
  }

  /// How unlike [a] and [b] are to spell: the edits between them over the
  /// longer one's length, so 0 is the same word and 1 is nothing in common.
  ///
  /// Counted on characters, ignoring case. It knows nothing of grammar, which
  /// is fine: two forms of one verb are close because they share a stem, and
  /// that is exactly the mistake worth laying a trap for.
  static double spellingDistance(String a, String b) {
    final x = a.toLowerCase().runes.toList();
    final y = b.toLowerCase().runes.toList();
    if (x.isEmpty && y.isEmpty) return 0;
    var row = List.generate(y.length + 1, (j) => j);
    for (var i = 1; i <= x.length; i++) {
      final next = [i, ...List.filled(y.length, 0)];
      for (var j = 1; j <= y.length; j++) {
        next[j] = min(
          min(next[j - 1] + 1, row[j] + 1),
          row[j - 1] + (x[i - 1] == y[j - 1] ? 0 : 1),
        );
      }
      row = next;
    }
    return row[y.length] / max(x.length, y.length);
  }

  /// How many characters [a] and [b] start with in common, ignoring case.
  static int _sharedStart(String a, String b) {
    final x = a.toLowerCase().runes.toList();
    final y = b.toLowerCase().runes.toList();
    var n = 0;
    while (n < x.length && n < y.length && x[n] == y[n]) {
      n++;
    }
    return n;
  }
}

/// What a tap on a stone did.
enum SpellTap {
  /// Wrong stone for this point in the sentence.
  fizzle,

  /// Right stone; the sentence goes on.
  placed,

  /// Right stone, and the last one.
  complete,

  /// Nothing: a stone already used, or the spell already cast.
  ignored,
}

/// A spell being cast, one stone at a time.
///
/// The one piece of rules state that changes in place, because it lives only
/// as long as a single spell and the screen reads it every frame.
class SpellCast {
  SpellCast(this.wave);

  final SpellWave wave;
  final List<int> _placed = [];
  int _fizzles = 0;

  /// Indices into [SpellWave.stones], in the order they were cast.
  List<int> get placed => List.unmodifiable(_placed);
  int get fizzles => _fizzles;
  bool get isComplete => _placed.length == wave.sentence.tokens.length;

  /// Taps stone [index].
  ///
  /// Checked on the word, not the stone: a sentence with the same word twice
  /// can take either stone first.
  SpellTap tap(int index) {
    if (isComplete || index < 0 || index >= wave.stones.length) {
      return SpellTap.ignored;
    }
    if (_placed.contains(index)) return SpellTap.ignored;
    if (wave.stones[index] != wave.sentence.tokens[_placed.length]) {
      _fizzles++;
      return SpellTap.fizzle;
    }
    _placed.add(index);
    return isComplete ? SpellTap.complete : SpellTap.placed;
  }
}

// ---- the Hexed Scroll -------------------------------------------------------

/// The part a word plays in its sentence.
///
/// A hex only swaps a word for another sentence's word in the same part, so
/// the scroll still reads as a sentence and the swap can only be found by
/// what the word means.
enum HexRole { subject, verb, object }

/// A word in a sentence that a hex may swap out.
class HexSlot {
  const HexSlot({
    required this.index,
    required this.role,
    required this.concept,
  });

  /// Where it is in the sentence's tokens.
  final int index;
  final HexRole role;

  /// What it means, the same in every language — "drink", "milk".
  ///
  /// Two sentences sharing a meaning never swap one for the other: "I drink
  /// water" hexed with the "drinks" from "the cat drinks milk" would be a
  /// grammar slip, not a different spell, and the prompt would still be true.
  final String concept;
}

/// A spell the witch reads out: a sentence with one word hexed.
class HexScroll {
  const HexScroll({
    required this.sentence,
    required this.words,
    required this.hexed,
  });

  /// What the spell should say; its meaning is the prompt.
  final TrialSentence sentence;

  /// What the scroll does say: the sentence's words with one swapped.
  final List<String> words;

  /// Which word was swapped.
  final int hexed;

  String get hexWord => words[hexed];
  String get trueWord => sentence.tokens[hexed];

  /// Every swap [sentence] can take from the rest of [pool], per slot.
  ///
  /// A swap is another sentence's word in the same part with a different
  /// meaning, and never a word this sentence already has — a scroll with the
  /// same word twice would have two answers, or none.
  static Map<HexSlot, List<String>> _swaps(
    TrialSentence sentence,
    List<TrialSentence> pool,
  ) {
    final own = sentence.tokens.map((t) => t.toLowerCase()).toSet();
    final swaps = <HexSlot, List<String>>{};
    for (final slot in sentence.slots) {
      if (slot.index < 0 || slot.index >= sentence.tokens.length) continue;
      final words = <String>{
        for (final other in pool)
          if (other != sentence)
            for (final theirs in other.slots)
              if (theirs.role == slot.role &&
                  theirs.concept != slot.concept &&
                  theirs.index >= 0 &&
                  theirs.index < other.tokens.length &&
                  !own.contains(other.tokens[theirs.index].toLowerCase()))
                other.tokens[theirs.index],
      };
      if (words.isNotEmpty) swaps[slot] = words.toList();
    }
    return swaps;
  }

  /// Whether [sentence] can be hexed from [pool].
  static bool canHex(TrialSentence sentence, List<TrialSentence> pool) =>
      _swaps(sentence, pool).isNotEmpty;

  /// Every swap [sentence] can take from [pool], per slot: the words each of
  /// its hexable slots could be hexed into.
  static Map<HexSlot, List<String>> swapsFor(
    TrialSentence sentence,
    List<TrialSentence> pool,
  ) =>
      _swaps(sentence, pool);

  /// A round needs two sentences it can hex, so the same one is never read
  /// twice in a row.
  static bool isPlayable(List<TrialSentence> pool) =>
      pool.toSet().where((s) => canHex(s, pool)).length >= 2;

  /// A scroll from [pool], or null when the pool cannot make one.
  ///
  /// Never repeats [previous]. The slot is chosen first and then the word, so
  /// a sentence's verb is as likely to be hexed as its object, however many
  /// objects the pool has to swap in.
  static HexScroll? build(
    List<TrialSentence> pool, {
    TrialSentence? previous,
    Random? random,
  }) {
    final rng = random ?? Random();
    final choices =
        pool.where((s) => s != previous && canHex(s, pool)).toList();
    if (choices.isEmpty) return null;
    final sentence = choices[rng.nextInt(choices.length)];

    final swaps = _swaps(sentence, pool);
    final slot = swaps.keys.elementAt(rng.nextInt(swaps.length));
    final options = swaps[slot]!;
    final words = [...sentence.tokens];
    words[slot.index] = options[rng.nextInt(options.length)];
    return HexScroll(sentence: sentence, words: words, hexed: slot.index);
  }
}

/// What a tap on a word of the scroll did.
enum HexTap {
  /// The hexed word: the curse is broken.
  broken,

  /// A word that was right all along.
  wrong,

  /// Nothing: a word already tried, or the hex already broken.
  ignored,
}

/// A scroll being read, one tap at a time. Lives as long as the scroll.
class HexRead {
  HexRead(this.scroll);

  final HexScroll scroll;
  final Set<int> _wrong = {};
  bool _broken = false;

  /// Words tapped that were not the hex.
  Set<int> get wrong => Set.unmodifiable(_wrong);
  bool get isBroken => _broken;

  HexTap tap(int index) {
    if (_broken || index < 0 || index >= scroll.words.length) {
      return HexTap.ignored;
    }
    if (_wrong.contains(index)) return HexTap.ignored;
    if (index == scroll.hexed) {
      _broken = true;
      return HexTap.broken;
    }
    _wrong.add(index);
    return HexTap.wrong;
  }
}

enum TrialGrade { s, a, b }

/// The score of one run, advanced one answer at a time.
class TrialRun {
  const TrialRun({
    this.hearts = BossTrialRules.maxHearts,
    this.patience = BossTrialRules.maxPatience,
    this.combo = 0,
    this.bestCombo = 0,
    this.caught = 0,
    this.broken = 0,
    this.letSlip = 0,
    this.lastDamage = 0,
    this.missed = const [],
    this.missedSentences = const [],
    this.missedScrolls = const [],
    this.endsAt = 0,
    this.last = true,
  });

  final int hearts;
  final int patience;

  /// The patience this round of the fight is won at: 0 for a whole fight,
  /// more for a finale's round that hands over to the next, or a level's
  /// that the boss gets away at the end of. No answer takes it lower.
  final int endsAt;

  /// Whether winning this round wins the trial.
  final bool last;
  final int combo;
  final int bestCombo;
  final int caught;

  /// Hexes found on the witch's scrolls.
  final int broken;

  /// Waves that landed without an answer.
  final int letSlip;

  /// What the most recent answer took off the boss, for the damage pop-up.
  final int lastDamage;

  /// Words the player got wrong, in order, without repeats. Letting a wave
  /// land is not a mistake about any particular word, so it adds nothing.
  final List<TrialWord> missed;

  /// Sentences the boss's attack beat, in order, without repeats.
  final List<TrialSentence> missedSentences;

  /// Scrolls whose fuse ran out, in order, one per sentence.
  final List<HexScroll> missedScrolls;

  /// This round of the fight won.
  bool get cleared => patience <= endsAt;

  bool get won => last && cleared;
  bool get lost => !won && hearts <= 0;
  bool get isOver => won || lost;

  /// Hearts kept, which is the whole of the grade: a trial is about getting
  /// words right, not about speed.
  TrialGrade get grade => switch (BossTrialRules.maxHearts - hearts) {
        0 => TrialGrade.s,
        1 => TrialGrade.a,
        _ => TrialGrade.b,
      };

  TrialRun answerRight({required double earliness}) {
    final streak = combo + 1;
    final dealt = BossTrialRules.damage(combo: streak, earliness: earliness);
    return _copy(
      patience: max(endsAt, patience - dealt),
      combo: streak,
      bestCombo: max(bestCombo, streak),
      caught: caught + 1,
      lastDamage: dealt,
    );
  }

  TrialRun answerWrong(TrialWord asked) => _copy(
        hearts: max(0, hearts - 1),
        combo: 0,
        lastDamage: 0,
        missed: missed.contains(asked) ? missed : [...missed, asked],
      );

  TrialRun letLand() => _copy(combo: 0, letSlip: letSlip + 1, lastDamage: 0);

  /// One of many small answers in an attack that asks several at once — a
  /// spike matched, a shard called right — with [earliness] of its clock to
  /// go.
  TrialRun shardHit({required double earliness}) {
    final streak = combo + 1;
    final dealt =
        BossTrialRules.shardDamage(combo: streak, earliness: earliness);
    return _copy(
      patience: max(endsAt, patience - dealt),
      combo: streak,
      bestCombo: max(bestCombo, streak),
      caught: caught + 1,
      lastDamage: dealt,
    );
  }

  /// A slip over [word] that the boss's clock pays for rather than a heart:
  /// a spike paired with the wrong meaning, or a true shard smashed.
  TrialRun wordSlip(TrialWord word) => _copy(
        combo: 0,
        lastDamage: 0,
        missed: missed.contains(word) ? missed : [...missed, word],
      );

  /// Amethyst's attack getting through to the pet over [word]: a spike
  /// nobody matched, or a lying shard let through.
  TrialRun struck(TrialWord word) => _copy(
        hearts: max(0, hearts - 1),
        combo: 0,
        lastDamage: 0,
        missed: missed.contains(word) ? missed : [...missed, word],
      );

  /// A wrong stone, or a wrong word on a scroll. It breaks the streak and
  /// nothing else — the cost is the charge or the fuse it hands the boss,
  /// which the screen's clock owns.
  TrialRun fizzle() => _copy(combo: 0, lastDamage: 0);

  /// The hex on a scroll found with [earliness] of its fuse left.
  TrialRun hexBroken({required double earliness}) {
    final streak = combo + 1;
    final dealt = BossTrialRules.damage(combo: streak, earliness: earliness);
    return _copy(
      patience: max(endsAt, patience - dealt),
      combo: streak,
      bestCombo: max(bestCombo, streak),
      broken: broken + 1,
      lastDamage: dealt,
    );
  }

  /// A scroll's fuse ran out before its hex was found.
  TrialRun hexLanded(HexScroll scroll) => _copy(
        hearts: max(0, hearts - 1),
        combo: 0,
        lastDamage: 0,
        missedScrolls:
            missedScrolls.any((s) => s.sentence == scroll.sentence)
                ? missedScrolls
                : [...missedScrolls, scroll],
      );

  /// The boss's attack landed before [sentence] was cast — or, in Amethyst's
  /// echo, before the player found what it meant.
  ///
  /// [also] are more sentences the same failure leaves to practise — the
  /// witch's tangle has two — without costing more than the one heart.
  TrialRun castFailed(
    TrialSentence sentence, {
    List<TrialSentence> also = const [],
  }) {
    final missed = [...missedSentences];
    for (final s in [sentence, ...also]) {
      if (!missed.contains(s)) missed.add(s);
    }
    return _copy(
      hearts: max(0, hearts - 1),
      combo: 0,
      lastDamage: 0,
      missedSentences: missed,
    );
  }

  /// Mossback's river crossed: every hop's small hit, each worth what
  /// [BossTrialRules.shardDamage] gives for its place in the streak and the
  /// [earliness] it was made with, lands at once in the headbutt.
  TrialRun crossed(List<double> earliness) {
    var streak = combo;
    var dealt = 0;
    for (final e in earliness) {
      streak++;
      dealt += BossTrialRules.shardDamage(combo: streak, earliness: e);
    }
    return _copy(
      patience: max(endsAt, patience - dealt),
      combo: streak,
      bestCombo: max(bestCombo, streak),
      caught: caught + earliness.length,
      lastDamage: dealt,
    );
  }

  /// Carried into the next round of a fight: [patience] down to [endsAt],
  /// and [heartsBack] hearts given back. The streak and everything to
  /// practise come along.
  TrialRun intoRound({
    required int patience,
    required int endsAt,
    required bool last,
    int heartsBack = 0,
  }) =>
      _copy(
        hearts: min(BossTrialRules.maxHearts, hearts + heartsBack),
        patience: patience,
        endsAt: endsAt,
        last: last,
        lastDamage: 0,
      );

  TrialRun _copy({
    int? hearts,
    int? patience,
    int? endsAt,
    bool? last,
    int? combo,
    int? bestCombo,
    int? caught,
    int? broken,
    int? letSlip,
    int? lastDamage,
    List<TrialWord>? missed,
    List<TrialSentence>? missedSentences,
    List<HexScroll>? missedScrolls,
  }) =>
      TrialRun(
        hearts: hearts ?? this.hearts,
        patience: patience ?? this.patience,
        combo: combo ?? this.combo,
        bestCombo: bestCombo ?? this.bestCombo,
        caught: caught ?? this.caught,
        broken: broken ?? this.broken,
        letSlip: letSlip ?? this.letSlip,
        lastDamage: lastDamage ?? this.lastDamage,
        missed: missed ?? this.missed,
        missedSentences: missedSentences ?? this.missedSentences,
        missedScrolls: missedScrolls ?? this.missedScrolls,
        endsAt: endsAt ?? this.endsAt,
        last: last ?? this.last,
      );
}
