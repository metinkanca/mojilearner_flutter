/// Amethyst's first round — trial 2, level 10 — in the three forms under
/// test, each an attack of its own rather than another boss's in new art:
///
/// * **Crystal Spikes.** It slams the ledge and roars four words, and a
///   crystal spike hangs from the ledge for each, its shaft growing in toward
///   the pet at its own speed until all four close on it. The pet holds a gem
///   for every meaning. A spike and its gem, tapped in either order, shatter
///   together; a wrong pair makes the spike lurch on. The first spike to
///   reach the pet traps it in amethyst — a heart — and the rest crumble.
///   Every word in the wave is asked, not one of four.
/// * **Crystal Echo.** It roars a whole sentence, and three crystals rise
///   carrying meanings in the player's language: the one it said, and the
///   two that share the most with it. A wrong crystal makes the amethyst
///   creeping up the pet jump on; the pet sealed in costs a heart.
/// * **Shard Volley.** It hurls shards one after another, each claiming a
///   word means something. A lie smashed is swatted back at it; a true one
///   let through is caught and thrown back. A true one smashed costs the
///   streak; a lie let through traps the pet — a heart — and ends the volley.
///
/// Pure, like the rest of the trial's rules in `boss_trial.dart`: the screen
/// owns time and layout, this file owns what an answer is.
library;

import 'dart:math';

import 'boss_trial.dart';

class CrystalRules {
  CrystalRules._();

  // ---- Crystal Spikes -------------------------------------------------------

  /// How long the spike ranked [rank] (0 = the fastest) takes to reach the
  /// pet, at [patience].
  ///
  /// The first gets eight and a half seconds while the boss is fresh and each
  /// after it 2.2 more: four words and four meanings to read, and two taps a
  /// pair. Both tighten along the round, to 6.5 seconds and 1.6. (The first
  /// cut, 5.5 and 1.6, was far too quick in the owner's hands.)
  static Duration spikeTime({required int rank, required int patience}) {
    final health = BossTrialRules.roundOneHealth(patience);
    final first = 6500 + 2000 * health;
    final step = 1600 + 600 * health;
    return Duration(milliseconds: (first + step * rank).round());
  }

  /// How far a spike lurches when paired with the wrong meaning, as a share
  /// of its way to the pet. Guessing through a wave brings it down; one slip never
  /// does on its own.
  static const double spikeLurch = 0.2;

  // ---- Crystal Echo ---------------------------------------------------------

  /// Crystals offered: the meaning it roared and two others.
  static const int echoOptions = 3;

  /// How long the amethyst takes to close over the pet, for a roar of
  /// [words] words at [patience].
  ///
  /// A roar to read in one language and three answers in another: four words
  /// get 6.3 seconds while the boss is fresh, tightening to two thirds of
  /// that, the way the witch's fuse does.
  static Duration echoTime({required int words, required int patience}) {
    final health = BossTrialRules.roundOneHealth(patience);
    final full = 3500 + 700 * words;
    return Duration(milliseconds: (full * (2 + health) / 3).round());
  }

  /// How far a wrong crystal pushes the amethyst up the pet. Guessing
  /// through all three seals it; one slip never does.
  static const double echoMistakeCreep = 0.25;

  // ---- Shard Volley ---------------------------------------------------------

  /// Shards in one volley.
  static const int volleyShards = 6;

  /// How long a shard takes from the boss's mouth to the pet: 3.4 seconds
  /// while it is fresh, 2.4 by the end of the round.
  static Duration shardFlight(int patience) {
    final health = BossTrialRules.roundOneHealth(patience);
    return Duration(milliseconds: (2400 + 1000 * health).round());
  }

  /// The beat between one shard and the next: 1.3 seconds, down to 0.9. With
  /// the flight time, two or three are in the air at once.
  static Duration shardInterval(int patience) {
    final health = BossTrialRules.roundOneHealth(patience);
    return Duration(milliseconds: (900 + 400 * health).round());
  }

  // ---- Vein -----------------------------------------------------------------

  /// The crystal wall, a side of it.
  static const int veinSide = 4;

  /// How long the amethyst takes to close over the pet while it follows a
  /// vein of [words] words: time to read the prompt and find each crystal.
  /// Four words get eight seconds while it is fresh, down to two thirds.
  static Duration veinTime({required int words, required int patience}) {
    final health = BossTrialRules.roundOneHealth(patience);
    final full = 3000 + 1250 * words;
    return Duration(milliseconds: (full * (2 + health) / 3).round());
  }

  /// How far a crystal off the vein lets the amethyst creep on.
  static const double veinMistakeCreep = 0.2;
}

// ---- Crystal Spikes ---------------------------------------------------------

/// One wave of spikes: the words roared, and the gems that answer them.
class SpikeWave {
  const SpikeWave({
    required this.spikes,
    required this.gems,
    required this.ranks,
  });

  /// The words it roared, one a spike, in lane order.
  final List<TrialWord> spikes;

  /// The same words, their meanings showing, as the pet holds them — one a
  /// lane, and never under their own spike, so no answer is straight down.
  final List<TrialWord> gems;

  /// How soon each lane's spike arrives: 0 is the first to reach the pet.
  final List<int> ranks;

  /// The lane of the gem that answers the spike in [lane].
  int gemFor(int lane) => gems.indexOf(spikes[lane]);

  /// A wave from [pool], or null when the pool cannot make a fair one.
  ///
  /// Every spike carries a different meaning, or two gems would read the
  /// same. Words not in [previous] come first, so two waves running share as
  /// few as the pool allows.
  static SpikeWave? build(
    List<TrialWord> pool, {
    List<TrialWord> previous = const [],
    Random? random,
  }) {
    final rng = random ?? Random();
    const count = BossTrialRules.wordsPerWave;
    final fresh = pool.where((w) => !previous.contains(w)).toList()
      ..shuffle(rng);
    final stale = pool.where(previous.contains).toList()..shuffle(rng);
    final meanings = <String>{};
    final spikes = <TrialWord>[];
    for (final w in [...fresh, ...stale]) {
      if (spikes.length == count) break;
      if (meanings.add(w.meaning.toLowerCase())) spikes.add(w);
    }
    if (spikes.length < count) return null;
    return SpikeWave(
      spikes: spikes,
      gems: _deranged(spikes, rng),
      ranks: List.generate(count, (i) => i)..shuffle(rng),
    );
  }

  /// [items] shuffled so that none stays where it was.
  static List<T> _deranged<T>(List<T> items, Random rng) {
    for (var tries = 0; tries < 20; tries++) {
      final order = [...items]..shuffle(rng);
      var moved = true;
      for (var i = 0; i < items.length && moved; i++) {
        moved = order[i] != items[i];
      }
      if (moved) return order;
    }
    // Rotating by one never leaves anything in place.
    return [...items.skip(1), items.first];
  }
}

/// What a tap on a spike or a gem did.
enum SpikeTap {
  /// Picked up, waiting for its other half.
  held,

  /// Put down again: the same one tapped twice.
  dropped,

  /// A spike and its own meaning: both shatter.
  matched,

  /// A spike and another word's meaning.
  mismatched,

  /// Nothing: a spike already shattered, or a gem already thrown.
  ignored,
}

/// A wave of spikes being answered, one pair at a time. Lives as long as the
/// wave.
class SpikeRush {
  SpikeRush(this.wave);

  final SpikeWave wave;
  final Set<int> _shattered = {};
  int? _spike;
  int? _gem;

  /// The spike and gem of the last pair tried, for the screen to flash.
  (int spike, int gem)? lastPair;

  /// Whichever half of a pair is waiting for the other.
  int? get heldSpike => _spike;
  int? get heldGem => _gem;

  bool isShattered(int lane) => _shattered.contains(lane);
  bool isGemUsed(int gem) => _shattered.any((lane) => wave.gemFor(lane) == gem);
  bool get isCleared => _shattered.length == wave.spikes.length;

  /// Taps the spike in [lane]: holds it, or pairs it with the gem held.
  /// Tapping another spike while one is held holds that one instead.
  SpikeTap tapSpike(int lane) {
    if (lane < 0 || lane >= wave.spikes.length || isShattered(lane)) {
      return SpikeTap.ignored;
    }
    if (_spike == lane) {
      _spike = null;
      return SpikeTap.dropped;
    }
    final gem = _gem;
    if (gem == null) {
      _spike = lane;
      return SpikeTap.held;
    }
    return _pair(lane, gem);
  }

  /// Taps gem [gem]: holds it, or pairs it with the spike held.
  SpikeTap tapGem(int gem) {
    if (gem < 0 || gem >= wave.gems.length || isGemUsed(gem)) {
      return SpikeTap.ignored;
    }
    if (_gem == gem) {
      _gem = null;
      return SpikeTap.dropped;
    }
    final spike = _spike;
    if (spike == null) {
      _gem = gem;
      return SpikeTap.held;
    }
    return _pair(spike, gem);
  }

  SpikeTap _pair(int spike, int gem) {
    _spike = null;
    _gem = null;
    lastPair = (spike, gem);
    if (wave.gemFor(spike) != gem) return SpikeTap.mismatched;
    _shattered.add(spike);
    return SpikeTap.matched;
  }
}

// ---- Crystal Echo -----------------------------------------------------------

/// One roar: the sentence it said, and the meanings offered for it.
class EchoWave {
  const EchoWave({required this.sentence, required this.options});

  final TrialSentence sentence;

  /// The meanings on the crystals, in the order they stand: the sentence's
  /// own and the ones most like it.
  final List<TrialSentence> options;

  int get answer => options.indexOf(sentence);

  /// Whether [pool] can offer [options] different meanings, and so never
  /// roar the same sentence twice running.
  static bool isPlayable(
    List<TrialSentence> pool, {
    int options = CrystalRules.echoOptions,
  }) =>
      pool.map((s) => s.meaning.toLowerCase()).toSet().length >=
      max(options, 2);

  /// A roar from [pool], or null when the pool cannot make one.
  ///
  /// Never repeats [previous]. The wrong meanings are the sentences sharing
  /// the most [TrialSentence.concepts] with it — "I drink water" offered
  /// beside "the cat drinks milk" and "I read a book" — so one word known is
  /// rarely enough. Equally near ones take turns.
  static EchoWave? build(
    List<TrialSentence> pool, {
    TrialSentence? previous,
    Random? random,
    int count = CrystalRules.echoOptions,
  }) {
    final rng = random ?? Random();
    final choices = pool.where((s) => s != previous).toList();
    if (choices.isEmpty) return null;
    final sentence = choices[rng.nextInt(choices.length)];

    final others = pool.where((s) => s != sentence).toList()..shuffle(rng);
    int shared(TrialSentence s) =>
        s.concepts.intersection(sentence.concepts).length;
    // Sorted by index on a tie, since a sort is not promised to be stable
    // and the shuffle is what makes equally near sentences take turns.
    final order = List.generate(others.length, (i) => i)
      ..sort((a, b) {
        final byShared = shared(others[b]).compareTo(shared(others[a]));
        return byShared != 0 ? byShared : a.compareTo(b);
      });

    final meanings = {sentence.meaning.toLowerCase()};
    final options = [sentence];
    for (final i in order) {
      if (options.length == count) break;
      if (meanings.add(others[i].meaning.toLowerCase())) options.add(others[i]);
    }
    if (options.length < count) return null;
    options.shuffle(rng);
    return EchoWave(sentence: sentence, options: options);
  }
}

/// What a tap on a crystal of the echo did.
enum EchoTap {
  /// The meaning it roared.
  heard,

  /// Another meaning.
  wrong,

  /// Nothing: a crystal already tried, or the roar already answered.
  ignored,
}

/// A roar being answered, one tap at a time. Lives as long as the roar.
class EchoListen {
  EchoListen(this.wave);

  final EchoWave wave;
  final Set<int> _wrong = {};
  bool _heard = false;

  /// Crystals tapped that were not what it said.
  Set<int> get wrong => Set.unmodifiable(_wrong);
  bool get isHeard => _heard;

  EchoTap tap(int index) {
    if (_heard || index < 0 || index >= wave.options.length) {
      return EchoTap.ignored;
    }
    if (_wrong.contains(index)) return EchoTap.ignored;
    if (index == wave.answer) {
      _heard = true;
      return EchoTap.heard;
    }
    _wrong.add(index);
    return EchoTap.wrong;
  }
}

// ---- Shard Volley -----------------------------------------------------------

/// One shard of a volley: a word, and the meaning it claims.
class VolleyShard {
  const VolleyShard({required this.word, required this.claim});

  final TrialWord word;

  /// The meaning written under the word, in the player's language: its own,
  /// or another word's.
  final String claim;

  bool get isTrue => claim.toLowerCase() == word.meaning.toLowerCase();
}

/// How a shard was called.
enum ShardCall {
  /// A lie, smashed: swatted back at the boss.
  smashedLie,

  /// A true one, smashed: the streak goes with it.
  smashedTruth,

  /// A true one, let through: caught and thrown back.
  caughtTruth,

  /// A lie, let through: it hits the pet.
  lieLanded,
}

/// One volley: the shards in the order they are thrown.
class ShardVolley {
  const ShardVolley(this.shards);

  final List<VolleyShard> shards;

  /// What [shard] being [smashed] — or reaching the pet untouched — counts
  /// as.
  static ShardCall call(VolleyShard shard, {required bool smashed}) =>
      switch ((shard.isTrue, smashed)) {
        (true, true) => ShardCall.smashedTruth,
        (true, false) => ShardCall.caughtTruth,
        (false, true) => ShardCall.smashedLie,
        (false, false) => ShardCall.lieLanded,
      };

  /// A volley of [count] from [pool], or null when the pool cannot make a
  /// fair one.
  ///
  /// Half true and half lies, dealt in any order, so counting them does not
  /// help. As many different words as the pool has, never the same word twice
  /// running. A lie claims another word's meaning — never one that reads the
  /// same as the word's own.
  static ShardVolley? build(
    List<TrialWord> pool, {
    Random? random,
    int count = CrystalRules.volleyShards,
  }) {
    if (!TrialWordPool.isPlayable(pool)) return null;
    final rng = random ?? Random();
    final truths = List.generate(count, (i) => i < (count + 1) ~/ 2)
      ..shuffle(rng);

    final words = <TrialWord>[];
    var deck = <TrialWord>[];
    for (var i = 0; i < count; i++) {
      final last = words.isEmpty ? null : words.last;
      // Dealt from a shuffled deck of the whole pool, topped up whenever
      // nothing is left in it but the word just thrown.
      if (deck.every((w) => w == last)) {
        deck = [...deck, ...([...pool]..shuffle(rng))];
      }
      words.add(deck.removeAt(deck.lastIndexWhere((w) => w != last)));
    }

    return ShardVolley([
      for (var i = 0; i < count; i++)
        VolleyShard(
          word: words[i],
          claim: truths[i] ? words[i].meaning : _lie(words[i], pool, rng),
        ),
    ]);
  }

  static String _lie(TrialWord word, List<TrialWord> pool, Random rng) {
    final own = word.meaning.toLowerCase();
    final others = {
      for (final w in pool)
        if (w.meaning.toLowerCase() != own) w.meaning,
    }.toList();
    return others[rng.nextInt(others.length)];
  }
}

// ---- Vein -------------------------------------------------------------------

/// A crystal wall with a sentence running through it: its words on a path of
/// neighbouring crystals, and the rest of the wall other sentences' words.
class VeinWave {
  const VeinWave({
    required this.sentence,
    required this.cells,
    required this.path,
  });

  final TrialSentence sentence;

  /// Every crystal's word, row by row.
  final List<String> cells;

  /// The crystals the vein runs through, in sentence order.
  final List<int> path;

  static const int side = CrystalRules.veinSide;

  /// The crystals sharing an edge with [cell].
  static List<int> neighbours(int cell) {
    final x = cell % side, y = cell ~/ side;
    return [
      if (x > 0) cell - 1,
      if (x < side - 1) cell + 1,
      if (y > 0) cell - side,
      if (y < side - 1) cell + side,
    ];
  }

  static bool isPlayable(List<TrialSentence> pool) =>
      TrialSentencePool.isPlayable(pool) &&
      pool.any((s) => s.tokens.length <= side * side);

  /// A wall from [pool], or null when the pool cannot make one. Never
  /// [previous] again straight away.
  ///
  /// The vein is a random walk that never crosses itself. A word the
  /// sentence has twice is never laid where it would sit next to the step
  /// before its first — the wrong one of the two would be next to the vein
  /// and marked wrong for no reason. The wall around it is other sentences'
  /// words, never one of this sentence's.
  static VeinWave? build(
    List<TrialSentence> pool, {
    TrialSentence? previous,
    Random? random,
  }) {
    final rng = random ?? Random();
    final choices = pool
        .where((s) => s != previous && s.tokens.length <= side * side)
        .toList();
    if (choices.isEmpty) return null;
    final sentence = choices[rng.nextInt(choices.length)];
    final tokens = sentence.tokens;

    List<int>? walk() {
      final path = [rng.nextInt(side * side)];
      bool extend() {
        if (path.length == tokens.length) return true;
        final next = neighbours(path.last).where((c) => !path.contains(c))
            .toList()
          ..shuffle(rng);
        for (final c in next) {
          path.add(c);
          if (extend()) return true;
          path.removeLast();
        }
        return false;
      }

      return extend() ? path : null;
    }

    bool fair(List<int> path) {
      for (var i = 1; i < path.length; i++) {
        final around = neighbours(path[i - 1]);
        for (var j = 0; j < path.length; j++) {
          if (j != i &&
              tokens[j] == tokens[i] &&
              around.contains(path[j])) {
            return false;
          }
        }
      }
      return true;
    }

    List<int>? path;
    for (var attempt = 0; attempt < 60 && path == null; attempt++) {
      final p = walk();
      if (p != null && fair(p)) path = p;
    }
    if (path == null) return null;

    final own = tokens.map((t) => t.toLowerCase()).toSet();
    final strays = {
      for (final s in pool)
        if (s != sentence)
          for (final t in s.tokens)
            if (!own.contains(t.toLowerCase())) t,
    }.toList()
      ..shuffle(rng);
    if (strays.isEmpty) return null;
    final cells = List.generate(side * side, (i) => strays[i % strays.length]);
    for (var i = 0; i < path.length; i++) {
      cells[path[i]] = tokens[i];
    }
    return VeinWave(sentence: sentence, cells: cells, path: path);
  }
}

/// What a tap on a crystal of the wall did.
enum VeinTap { next, done, wrong, ignored }

/// A vein being followed, a crystal at a time.
class VeinPlay {
  VeinPlay(this.wave);

  final VeinWave wave;
  int _followed = 0;

  /// How many crystals of the vein are lit.
  int get followed => _followed;
  bool get isDone => _followed == wave.path.length;
  bool isLit(int cell) => wave.path.take(_followed).contains(cell);

  VeinTap tap(int cell) {
    if (isDone || cell < 0 || cell >= wave.cells.length) return VeinTap.ignored;
    if (isLit(cell)) return VeinTap.ignored;
    if (cell != wave.path[_followed]) return VeinTap.wrong;
    _followed++;
    return isDone ? VeinTap.done : VeinTap.next;
  }
}
