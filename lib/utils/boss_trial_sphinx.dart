/// Sableth's first round — trial 5, level 25 — in the forms under test, each
/// an attack of its own:
///
/// * **Riddle.** It tells a little of a story in its language and asks a
///   question about it; three answers are carved in its language too. The
///   right one hits it; a wrong one runs its sand on; the sand running out
///   buries the pet.
/// * **Sealed Door.** A sentence in its language with one word left as it
///   stands in the dictionary — "(go)" — and a stone dial on the door turning
///   through forms of it. Turn the dial to the form the sentence needs and
///   push the door. A wrong push runs the sand on.
/// * **Tablets.** Three lines of a little story, broken onto tablets and
///   shuffled. Lift them in the order the story happens.
///
/// Their content is written, for now, in English and Turkish only
/// (`constants/boss_trial_en_tr.dart`). Pure, like the rest of the trial's
/// rules: the screen owns time and layout.
library;

import 'dart:math';

import 'boss_trial.dart';
import 'boss_trial_angler.dart' show BubbleWave;

class SphinxRules {
  SphinxRules._();

  /// A clock spread over the first round's band of patience: [full] while it
  /// is fresh, two thirds of that by the end of the round.
  static Duration _tightening(int full, int patience) {
    final health = BossTrialRules.roundOneHealth(patience);
    return Duration(milliseconds: (full * (2 + health) / 3).round());
  }

  // ---- Riddle ---------------------------------------------------------------

  /// How long its sand runs over a riddle of [words] words, question and
  /// answers included: three seconds to take it in and a third of one a word.
  static Duration riddleTime({required int words, required int patience}) =>
      _tightening(3000 + 330 * words, patience);

  /// How far a wrong answer runs the sand on.
  static const double riddleMistake = 0.3;

  // ---- Sealed Door ----------------------------------------------------------

  /// How long the sand runs over a door whose sentence has [words] words.
  static Duration doorTime({required int words, required int patience}) =>
      _tightening(3500 + 500 * words, patience);

  /// How far a wrong push runs the sand on.
  static const double doorMistake = 0.25;

  // ---- Tablets --------------------------------------------------------------

  /// How long the sand runs over a story of [words] words in all.
  static Duration tabletTime({required int words, required int patience}) =>
      _tightening(3000 + 450 * words, patience);

  /// How far a tablet lifted out of turn runs the sand on.
  static const double tabletMistake = 0.2;

  // ---- Sandstorm ------------------------------------------------------------

  /// The letter grid in the sand.
  static const int stormCols = 6;
  static const int stormRows = 5;

  /// How long the storm takes to bury the grid over a word of [letters]
  /// letters. Five get 7.5 seconds while it is fresh, down to two thirds.
  static Duration stormTime({required int letters, required int patience}) =>
      _tightening(4000 + 700 * letters, patience);

  /// How far a wrong swipe blows the storm on.
  static const double stormMistake = 0.2;
}

/// Anything of the sphinx's that can end up on the results screen, as a
/// sentence: what was said, and what it means.
TrialSentence _asSentence(String target, String meaning) => TrialSentence(
      tokens: target.split(' '),
      target: target,
      meaning: meaning,
    );

int _wordCount(String s) => s.split(' ').where((w) => w.isNotEmpty).length;

// ---- Riddle -----------------------------------------------------------------

/// A riddle: a little story, a question about it, and three answers — the
/// right one first, as written.
class TrialRiddle {
  const TrialRiddle({
    required this.passage,
    required this.question,
    required this.answers,
    required this.meaning,
  });

  final String passage;
  final String question;
  final List<String> answers;

  /// The story and its question in the player's language.
  final String meaning;

  int get words =>
      _wordCount(passage) +
      _wordCount(question) +
      answers.map(_wordCount).fold(0, (a, b) => a + b);

  TrialSentence get asSentence =>
      _asSentence('$passage $question ${answers.first}', meaning);
}

/// One riddle asked: its answers in the order they are carved.
class RiddleWave {
  const RiddleWave({
    required this.riddle,
    required this.options,
    required this.answer,
  });

  final TrialRiddle riddle;
  final List<String> options;
  final int answer;

  static bool isPlayable(List<TrialRiddle> pool) => pool.length >= 2;

  static RiddleWave? build(
    List<TrialRiddle> pool, {
    TrialRiddle? previous,
    Random? random,
  }) {
    final rng = random ?? Random();
    final choices = pool.where((r) => r != previous).toList();
    if (choices.isEmpty) return null;
    final riddle = choices[rng.nextInt(choices.length)];
    final options = [...riddle.answers]..shuffle(rng);
    return RiddleWave(
      riddle: riddle,
      options: options,
      answer: options.indexOf(riddle.answers.first),
    );
  }
}

// ---- Sealed Door ------------------------------------------------------------

/// A sentence with one word left in its dictionary form, and the forms the
/// dial turns through — the right one first, as written.
class GrammarDoor {
  const GrammarDoor({
    required this.before,
    required this.after,
    required this.base,
    required this.forms,
    required this.meaning,
  });

  /// The sentence either side of the gap. Either may be empty.
  final String before;
  final String after;

  /// The word as a dictionary gives it: "go", "gitmek".
  final String base;
  final List<String> forms;

  /// The whole sentence in the player's language.
  final String meaning;

  String get answer => forms.first;

  String get solved =>
      [before, answer, after].where((p) => p.isNotEmpty).join(' ');

  int get words => _wordCount(before) + 1 + _wordCount(after);

  TrialSentence get asSentence => _asSentence(solved, meaning);
}

/// One door: the forms in the order the dial turns through them, and where
/// the dial starts — never on the right one.
class DoorWave {
  const DoorWave({
    required this.door,
    required this.forms,
    required this.answer,
    required this.start,
  });

  final GrammarDoor door;
  final List<String> forms;
  final int answer;
  final int start;

  static bool isPlayable(List<GrammarDoor> pool) => pool.length >= 2;

  static DoorWave? build(
    List<GrammarDoor> pool, {
    GrammarDoor? previous,
    Random? random,
  }) {
    final rng = random ?? Random();
    final choices = pool.where((d) => d != previous).toList();
    if (choices.isEmpty) return null;
    final door = choices[rng.nextInt(choices.length)];
    final forms = [...door.forms]..shuffle(rng);
    final answer = forms.indexOf(door.answer);
    final wrong = [
      for (var i = 0; i < forms.length; i++)
        if (i != answer) i,
    ];
    return DoorWave(
      door: door,
      forms: forms,
      answer: answer,
      start: wrong[rng.nextInt(wrong.length)],
    );
  }
}

// ---- Tablets ----------------------------------------------------------------

/// A little story in three lines, in the order they happen, and what each
/// means.
class TrialStory {
  const TrialStory({required this.lines, required this.meanings});

  final List<String> lines;
  final List<String> meanings;

  int get words => lines.map(_wordCount).fold(0, (a, b) => a + b);

  TrialSentence get asSentence =>
      _asSentence(lines.join(' '), meanings.join(' '));
}

/// One story broken onto tablets: which line each tablet carries, never
/// already in order.
class TabletWave {
  const TabletWave({required this.story, required this.tablets});

  final TrialStory story;

  /// For each tablet, left to right, the line of the story it carries.
  final List<int> tablets;

  static bool isPlayable(List<TrialStory> pool) => pool.length >= 2;

  static TabletWave? build(
    List<TrialStory> pool, {
    TrialStory? previous,
    Random? random,
  }) {
    final rng = random ?? Random();
    final choices = pool.where((s) => s != previous).toList();
    if (choices.isEmpty) return null;
    final story = choices[rng.nextInt(choices.length)];
    final tablets = List.generate(story.lines.length, (i) => i);
    do {
      tablets.shuffle(rng);
    } while (tablets.length > 1 &&
        List.generate(tablets.length, (i) => i).join() == tablets.join());
    return TabletWave(story: story, tablets: tablets);
  }
}

/// What a tap on a tablet did.
enum TabletTap { next, wrong, done, ignored }

/// A story being put in order, one tablet at a time.
class TabletPlay {
  TabletPlay(this.wave);

  final TabletWave wave;
  final List<int> _lifted = [];

  /// Tablets lifted, in the order they were.
  List<int> get lifted => List.unmodifiable(_lifted);
  bool get isDone => _lifted.length == wave.tablets.length;

  TabletTap tap(int tablet) {
    if (isDone || tablet < 0 || tablet >= wave.tablets.length) {
      return TabletTap.ignored;
    }
    if (_lifted.contains(tablet)) return TabletTap.ignored;
    if (wave.tablets[tablet] != _lifted.length) return TabletTap.wrong;
    _lifted.add(tablet);
    return isDone ? TabletTap.done : TabletTap.next;
  }
}

// ---- Sandstorm --------------------------------------------------------------

/// A word hidden in a grid of letters in the sand, running left to right or
/// top to bottom.
class StormWave {
  const StormWave({
    required this.word,
    required this.grid,
    required this.cells,
  });

  final TrialWord word;

  /// Every letter of the grid, row by row.
  final List<String> grid;

  /// Where the word's letters lie, in order.
  final List<int> cells;

  static const int cols = SphinxRules.stormCols;
  static const int rows = SphinxRules.stormRows;

  /// A word fits the grid lying across it, [least] letters or more.
  static List<String>? _letters(TrialWord w, {int least = 3}) {
    final letters = BubbleWave.lettersOf(w.target);
    if (letters == null || letters.length < least || letters.length > cols) {
      return null;
    }
    return letters;
  }

  /// The fewest letters a word may have: three, unless the pool has too few
  /// that long — Chinese and Korean words are mostly two characters, and a
  /// character is a syllable, not a letter.
  static int _least(List<TrialWord> pool) =>
      pool.where((w) => _letters(w) != null).toSet().length >= 2 ? 3 : 2;

  static bool isPlayable(List<TrialWord> pool) =>
      pool.where((w) => _letters(w, least: _least(pool)) != null)
          .toSet()
          .length >=
      2;

  /// The cells from [from] to [to] along a row or a column, either way, or
  /// null when they are not in one line.
  static List<int>? line(int from, int to) {
    final fx = from % cols, fy = from ~/ cols;
    final tx = to % cols, ty = to ~/ cols;
    if (fx != tx && fy != ty) return null;
    final steps = max((tx - fx).abs(), (ty - fy).abs());
    final dx = (tx - fx).sign, dy = (ty - fy).sign;
    return [
      for (var i = 0; i <= steps; i++) (fy + dy * i) * cols + fx + dx * i,
    ];
  }

  /// Whether a swipe over [cells] found the word: exactly its letters' cells,
  /// read either way.
  bool found(List<int> cells) =>
      cells.length == this.cells.length &&
      (List.generate(cells.length, (i) => cells[i] == this.cells[i])
              .every((x) => x) ||
          List.generate(cells.length,
                  (i) => cells[i] == this.cells[cells.length - 1 - i])
              .every((x) => x));

  /// A grid from [pool], or null when it cannot make one. Never
  /// [previous] again straight away.
  ///
  /// The letters around the word are the pool's other words' letters, so
  /// they look like the language; a grid where the word could also be read
  /// somewhere else is thrown away and dealt again.
  static StormWave? build(
    List<TrialWord> pool, {
    TrialWord? previous,
    Random? random,
  }) {
    final rng = random ?? Random();
    final least = _least(pool);
    final choices = pool
        .where((w) => w != previous && _letters(w, least: least) != null)
        .toList();
    if (choices.isEmpty) return null;
    final word = choices[rng.nextInt(choices.length)];
    final letters = _letters(word, least: least)!;
    final filler = [
      for (final w in pool)
        if (w != word) ...?BubbleWave.lettersOf(w.target),
    ];
    if (filler.isEmpty) return null;

    for (var attempt = 0; attempt < 40; attempt++) {
      final down = letters.length <= rows && rng.nextBool();
      final x = rng.nextInt((down ? cols : cols - letters.length + 1));
      final y = rng.nextInt((down ? rows - letters.length + 1 : rows));
      final cells = [
        for (var i = 0; i < letters.length; i++)
          down ? (y + i) * cols + x : y * cols + x + i,
      ];
      final grid = List.generate(
          cols * rows, (_) => filler[rng.nextInt(filler.length)]);
      for (var i = 0; i < cells.length; i++) {
        grid[cells[i]] = letters[i];
      }
      if (_readings(grid, letters) == 1) {
        return StormWave(word: word, grid: grid, cells: cells);
      }
    }
    return null;
  }

  /// How many times [letters] can be read in [grid], along rows and columns,
  /// either way.
  static int _readings(List<String> grid, List<String> letters) {
    final n = letters.length;
    final word = letters.join();
    final back = letters.reversed.join();
    var count = 0;
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x + n <= cols; x++) {
        final s = [for (var i = 0; i < n; i++) grid[y * cols + x + i]].join();
        if (s == word) count++;
        if (s == back && back != word) count++;
      }
    }
    for (var x = 0; x < cols; x++) {
      for (var y = 0; y + n <= rows; y++) {
        final s = [for (var i = 0; i < n; i++) grid[(y + i) * cols + x]].join();
        if (s == word) count++;
        if (s == back && back != word) count++;
      }
    }
    return count;
  }
}
