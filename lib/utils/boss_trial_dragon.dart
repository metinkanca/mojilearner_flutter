/// Pyrewing's first round — trial 6, level 30, the last — in the forms under
/// test, each an attack of its own:
///
/// * **Parley.** It talks, in its language, three lines one after another,
///   and after each the player picks what to say back from three replies:
///   one that answers it, and two that do not. Each right reply stings; the
///   whole conversation lands a blow. A wrong reply stokes its fire; the fire
///   breaking loose scorches the pet and ends the parley.
/// * **Flame Link.** Two halves of a sentence burn either side of it, and
///   rune stones drift between them, each a linking word: "because",
///   "unless", "so". Throw the one that joins the halves into sense. It
///   scales from "and / but" to "whereas / so that" as the content does.
/// * **Ember Paraphrase.** It says a sentence; three embers rise, each
///   another sentence, and burn down with the clock — one of the wrong ones
///   goes out half way. Tap the one that means the same before the clock
///   does — an idiom and its plain meaning, at the top.
/// * **Hoard.** Coins in its hoard carry halves of everyday phrases: "take",
///   "a photo". Tap two halves that go together to pair them before it wakes.
///
/// Their content is written, for now, in English and Turkish only
/// (`constants/boss_trial_en_tr.dart`). Pure, like the rest of the trial's
/// rules: the screen owns time and layout.
library;

import 'dart:math';

import 'boss_trial.dart';

class DragonRules {
  DragonRules._();

  static Duration _tightening(int full, int patience) {
    final health = BossTrialRules.roundOneHealth(patience);
    return Duration(milliseconds: (full * (2 + health) / 3).round());
  }

  // ---- Parley ---------------------------------------------------------------

  /// How long its fire takes to break loose over one turn of [words] words,
  /// its line and the three replies together.
  static Duration parleyTime({required int words, required int patience}) =>
      _tightening(2500 + 300 * words, patience);

  /// How far a wrong reply stokes the fire.
  static const double parleyMistake = 0.3;

  // ---- Flame Link -----------------------------------------------------------

  /// How long its flames take to die over a pair of halves of [words] words
  /// in all.
  static Duration linkTime({required int words, required int patience}) =>
      _tightening(3500 + 350 * words, patience);

  /// How far a wrong rune stokes the fire.
  static const double linkMistake = 0.3;

  // ---- Ember Paraphrase -----------------------------------------------------

  /// How long the round lasts over a sentence and three others of [words]
  /// words in all.
  static Duration paraphraseTime({required int words, required int patience}) =>
      _tightening(3000 + 330 * words, patience);

  /// When one of the wrong embers burns out, as a share of the round; the
  /// other two last it out. Never the right one: the round is lost when its
  /// clock runs out, not with a quarter of it still showing — and with one
  /// wrong ember always left, waiting for them to go is still a gamble.
  static const double emberGoesAt = 0.5;

  /// How far a wrong ember burns the rest down.
  static const double paraphraseMistake = 0.15;

  // ---- Hoard ----------------------------------------------------------------

  /// Phrases broken up in one hoard.
  static const int hoardPairs = 4;

  /// How long it sleeps over a hoard: time to read eight coins and pair them.
  static Duration hoardTime(int patience) => _tightening(13000, patience);

  /// How far a wrong pair stirs it.
  static const double hoardMistake = 0.15;
}

int _wordCount(String s) => s.split(' ').where((w) => w.isNotEmpty).length;

TrialSentence _asSentence(String target, String meaning) => TrialSentence(
      tokens: target.split(' '),
      target: target,
      meaning: meaning,
    );

// ---- Parley -----------------------------------------------------------------

/// One turn of a parley: what it says, and three replies — the one that
/// answers it first, as written.
class ParleyTurn {
  const ParleyTurn({
    required this.line,
    required this.replies,
    required this.meaning,
  });

  final String line;
  final List<String> replies;

  /// Its line and the right reply, in the player's language.
  final String meaning;

  int get words =>
      _wordCount(line) + replies.map(_wordCount).fold(0, (a, b) => a + b);

  TrialSentence get asSentence =>
      _asSentence('$line — ${replies.first}', meaning);
}

/// A conversation, a turn at a time.
class ParleyScript {
  const ParleyScript(this.turns);

  final List<ParleyTurn> turns;
}

/// One parley: the script, and each turn's replies in the order they are
/// offered.
class ParleyWave {
  const ParleyWave({
    required this.script,
    required this.options,
    required this.answers,
  });

  final ParleyScript script;
  final List<List<String>> options;
  final List<int> answers;

  static bool isPlayable(List<ParleyScript> pool) => pool.length >= 2;

  static ParleyWave? build(
    List<ParleyScript> pool, {
    ParleyScript? previous,
    Random? random,
  }) {
    final rng = random ?? Random();
    final choices = pool.where((s) => s != previous).toList();
    if (choices.isEmpty) return null;
    final script = choices[rng.nextInt(choices.length)];
    final options = [
      for (final turn in script.turns) [...turn.replies]..shuffle(rng),
    ];
    return ParleyWave(
      script: script,
      options: options,
      answers: [
        for (var t = 0; t < script.turns.length; t++)
          options[t].indexOf(script.turns[t].replies.first),
      ],
    );
  }
}

// ---- Flame Link -------------------------------------------------------------

/// Two halves of a sentence and the words that could join them — the one
/// that makes sense first, as written.
class LinkItem {
  const LinkItem({
    required this.left,
    required this.right,
    required this.links,
    required this.meaning,
  });

  final String left;
  final String right;
  final List<String> links;

  /// The whole sentence in the player's language.
  final String meaning;

  String get joined => '$left ${links.first} $right';

  int get words => _wordCount(left) + _wordCount(right) + links.length;

  TrialSentence get asSentence => _asSentence(joined, meaning);
}

/// One pair of flames: the runes in the order they drift, and the right one.
class LinkWave {
  const LinkWave({
    required this.item,
    required this.runes,
    required this.answer,
  });

  final LinkItem item;
  final List<String> runes;
  final int answer;

  static bool isPlayable(List<LinkItem> pool) => pool.length >= 2;

  static LinkWave? build(
    List<LinkItem> pool, {
    LinkItem? previous,
    Random? random,
  }) {
    final rng = random ?? Random();
    final choices = pool.where((i) => i != previous).toList();
    if (choices.isEmpty) return null;
    final item = choices[rng.nextInt(choices.length)];
    final runes = [...item.links]..shuffle(rng);
    return LinkWave(
      item: item,
      runes: runes,
      answer: runes.indexOf(item.links.first),
    );
  }
}

// ---- Ember Paraphrase -------------------------------------------------------

/// A sentence, and three others: the one that means the same first.
class ParaphraseItem {
  const ParaphraseItem({
    required this.line,
    required this.options,
    required this.meaning,
  });

  final String line;
  final List<String> options;

  /// What [line] means, in the player's language.
  final String meaning;

  int get words =>
      _wordCount(line) + options.map(_wordCount).fold(0, (a, b) => a + b);

  TrialSentence get asSentence =>
      _asSentence('$line = ${options.first}', meaning);
}

/// One sentence said: the embers in the order they rise, the right one, and
/// when each burns out, as a share of the round.
class ParaphraseWave {
  const ParaphraseWave({
    required this.item,
    required this.embers,
    required this.answer,
    required this.lives,
  });

  final ParaphraseItem item;
  final List<String> embers;
  final int answer;
  final List<double> lives;

  static bool isPlayable(List<ParaphraseItem> pool) => pool.length >= 2;

  /// Which wrong ember goes out early is dealt at random.
  static ParaphraseWave? build(
    List<ParaphraseItem> pool, {
    ParaphraseItem? previous,
    Random? random,
  }) {
    final rng = random ?? Random();
    final choices = pool.where((i) => i != previous).toList();
    if (choices.isEmpty) return null;
    final item = choices[rng.nextInt(choices.length)];
    final embers = [...item.options]..shuffle(rng);
    final answer = embers.indexOf(item.options.first);
    final wrong = [
      for (var i = 0; i < embers.length; i++)
        if (i != answer) i,
    ];
    final goes = wrong[rng.nextInt(wrong.length)];
    return ParaphraseWave(
      item: item,
      embers: embers,
      answer: answer,
      lives: [
        for (var i = 0; i < embers.length; i++)
          i == goes ? DragonRules.emberGoesAt : 1.0,
      ],
    );
  }
}

// ---- Hoard ------------------------------------------------------------------

/// A phrase whose two halves go together: "take" and "a photo".
class Collocation {
  const Collocation(this.first, this.second, this.meaning);

  final String first;
  final String second;

  /// The whole phrase in the player's language.
  final String meaning;

  String get phrase => '$first $second';

  TrialWord get asWord => TrialWord(target: phrase, meaning: meaning);
}

/// A coin in the hoard: half a phrase.
class HoardCoin {
  const HoardCoin(this.text, {required this.first});

  final String text;

  /// Whether it is a phrase's first half.
  final bool first;
}

/// One hoard: the phrases broken up in it, and their halves as coins.
class HoardWave {
  const HoardWave({required this.phrases, required this.coins});

  final List<Collocation> phrases;
  final List<HoardCoin> coins;

  static bool isPlayable(List<Collocation> pool) =>
      pool.length >= DragonRules.hoardPairs;

  /// Whether [a] and [b], a first half and a second, make a phrase — one of
  /// [phrases], or one of the [alsoFit] a speaker would accept as well.
  static bool _fits(String a, String b, List<Collocation> phrases,
          Set<(String, String)> alsoFit) =>
      alsoFit.contains((a, b)) ||
      phrases.any((p) => p.first == a && p.second == b);

  /// A hoard from [pool], or null when it cannot make one.
  ///
  /// The phrases are picked so the halves only go together one way: no
  /// first half makes another phrase in [pool], or one of [alsoFit], with
  /// anything but its own second half — "make" and "a promise" never lie
  /// in the hoard beside "break". A half two phrases share, like "make" in
  /// "make a mistake" and "make a decision", or Turkish "vermek" in "söz
  /// vermek" and "karar vermek", is fine: its coins are the same coin twice,
  /// and either pairs with either.
  static HoardWave? build(
    List<Collocation> pool, {
    Set<(String, String)> alsoFit = const {},
    Random? random,
  }) {
    final rng = random ?? Random();
    for (var attempt = 0; attempt < 40; attempt++) {
      final picked = <Collocation>[];
      for (final p in [...pool]..shuffle(rng)) {
        if (picked.length == DragonRules.hoardPairs) break;
        final together = [...picked, p];
        // Halves with the same words are the same coin: only a first half
        // meeting a DIFFERENT second half can make a second answer.
        final clash = together.any((x) => together.any((y) =>
            x != y &&
            x.first != y.first &&
            x.second != y.second &&
            _fits(x.first, y.second, pool, alsoFit)));
        if (!clash) picked.add(p);
      }
      if (picked.length < DragonRules.hoardPairs) continue;
      final coins = [
        for (final p in picked) ...[
          HoardCoin(p.first, first: true),
          HoardCoin(p.second, first: false),
        ],
      ]..shuffle(rng);
      return HoardWave(phrases: picked, coins: coins);
    }
    return null;
  }
}

/// What a tap on a coin did.
enum HoardTap { held, dropped, matched, mismatched, ignored }

/// A hoard being paired up, a coin at a time.
class HoardPlay {
  HoardPlay(this.wave);

  final HoardWave wave;
  final Set<int> _paired = {};
  final Set<Collocation> _found = {};
  int? _held;

  int? get held => _held;
  bool isPaired(int coin) => _paired.contains(coin);
  bool get isCleared => _found.length == wave.phrases.length;

  /// The two coins of the last pair tried, and the phrase they made, if any.
  (int, int)? lastPair;
  Collocation? lastFound;

  HoardTap tap(int coin) {
    if (isCleared || coin < 0 || coin >= wave.coins.length) {
      return HoardTap.ignored;
    }
    if (_paired.contains(coin)) return HoardTap.ignored;
    final held = _held;
    if (held == null) {
      _held = coin;
      return HoardTap.held;
    }
    if (held == coin) {
      _held = null;
      return HoardTap.dropped;
    }
    _held = null;
    lastPair = (held, coin);
    final a = wave.coins[held];
    final b = wave.coins[coin];
    final (first, second) = a.first ? (a, b) : (b, a);
    final phrase = first.first == second.first
        ? null
        : wave.phrases
            .where((p) => !_found.contains(p))
            .where((p) => p.first == first.text && p.second == second.text)
            .firstOrNull;
    lastFound = phrase;
    if (phrase == null) return HoardTap.mismatched;
    _found.add(phrase);
    _paired
      ..add(held)
      ..add(coin);
    return HoardTap.matched;
  }

  /// The phrases not yet paired, for the results when it wakes.
  List<Collocation> get unfound => [
        for (final p in wave.phrases)
          if (!_found.contains(p)) p
      ];
}
