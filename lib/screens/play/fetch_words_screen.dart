import 'dart:math';

import 'package:flutter/material.dart';

import '../../components/play/play_kit.dart';
import '../../components/play/play_props.dart';
import '../../components/play/toy_chest_art.dart';
import '../../utils/boss_trial.dart';
import '../../utils/play_games.dart';
import 'play_game_state.dart';

/// Fetch the Words: the Spells round, played as fetch in the park.
///
/// The pet wants to say a sentence, shown in the player's language. Sticks
/// lie on the grass, each with a word of it in the language being learned —
/// and one that is not in it. Tap them in order: each is tossed to the pet,
/// which catches it, and the sentence builds along the line on the grass.
/// The pet's patience, a row of hearts, is the clock; a wrong stick uses
/// some of it up. Built with no slips, the pet is delighted; out of patience,
/// the line shows the sentence and the next is laid out. See [FetchRules].
///
/// The stock has six sentences a language until the AI writes more, so a
/// game deals five of them without repeats.
///
/// The park is flat colours on the pet's cells: glass sky, leaf grass under an
/// ink line, a tree and a bush on the line, and a few flowers lower down.
class FetchWordsScreen extends StatefulWidget {
  const FetchWordsScreen({super.key, this.random});

  /// Fixed in tests, so the sentences are known.
  final Random? random;

  @override
  State<FetchWordsScreen> createState() => _FetchWordsScreenState();
}

enum _Stage {
  /// A beat before the next sentence.
  waiting,

  /// The sticks are out and the pet is waiting for them.
  fetching,

  /// The sentence built: the line lit.
  built,

  /// Out of patience: the sentence shown.
  tooSlow,
}

/// Scene geometry for one layout: sky across the top with the pet's sentence
/// in it, the pet on the grass to the left with its patience beside it, the
/// line the sentence builds along on the grass under it, and the sticks
/// below that, where the thumb is.
class _Geo {
  _Geo(this.w, this.h) {
    petBox = min(min(h * 0.2, w * 0.34), 130.0).roundToDouble();
    horizon = max(h * 0.42, petBox + _promptBottom + 10).roundToDouble();
    petX = (w * 0.27).roundToDouble();
    petFeet = horizon + 6;
    petTop = petFeet - petBox;
    mouth = Offset(petX + petBox * 0.28, petFeet - petBox * 0.45);
    lineTop = horizon + 18;
    sticksTop = lineTop + lineH + 18;
  }

  static const double promptTop = 8;
  static const double promptH = 54;
  static const double _promptBottom = promptTop + promptH + 12;
  static const double lineH = 46;

  final double w, h;
  late final double petBox, horizon, petX, petFeet, petTop;
  late final double lineTop, sticksTop;

  /// Where the pet catches a stick.
  late final Offset mouth;
}

/// A stick on its way to the pet.
class _Toss {
  _Toss(this.label, this.from);

  final String label;
  final Offset from;
  double t = 0;
}

class _FetchWordsScreenState extends PlayGameState<FetchWordsScreen> {
  static const double _firstWait = 0.9;
  static const double _wait = 0.5;
  static const double _tossSeconds = 0.32;
  static const double _builtHold = 1.4;
  static const double _tooSlowHold = 1.9;

  final GlobalKey _sceneKey = GlobalKey();

  List<TrialSentence> _pool = const [];
  _Geo? _geo;

  _Stage _stage = _Stage.waiting;
  double _stageTime = 0;
  double _waitSeconds = _firstWait;

  SpellWave? _wave;
  SpellCast? _cast;
  TrialSentence? _last;
  final Set<TrialSentence> _asked = {};
  double _fetchSeconds = 10;

  /// The pet's patience: 1 full, 0 out.
  double _patience = 1;

  /// Whether this sentence has been built without a wrong stick so far.
  bool _clean = true;
  int? _flashing;
  double _flashAt = -1;
  double _time = 0;

  final List<_Toss> _tosses = [];

  @override
  Random? get seed => widget.random;

  @override
  int get rounds => FetchRules.sentencesPerGame;

  @override
  double get particleFloor => _geo?.h ?? 0;

  @override
  bool loadContent() {
    final sentences =
        playSentences(targetCode: targetCode, nativeCode: nativeCode);
    _pool = sentences.pool;
    targetCode = sentences.targetCode;
    nativeCode = sentences.nativeCode;
    return TrialSentencePool.isPlayable(_pool);
  }

  @override
  void resetGame() {
    _wave = null;
    _cast = null;
    _last = null;
    _asked.clear();
    _tosses.clear();
    _flashing = null;
    _waitSeconds = _firstWait;
    _stage = _Stage.waiting;
    _stageTime = 0;
  }

  @override
  void step(double dt) {
    _time += dt;
    _stageTime += dt;
    for (final toss in _tosses) {
      toss.t += dt;
    }
    final caught = _tosses.where((t) => t.t >= _tossSeconds).toList();
    if (caught.isNotEmpty) {
      _tosses.removeWhere((t) => t.t >= _tossSeconds);
      // Caught: a hop, and the word goes onto the line.
      if (!reduceMotion && petHop < 0) petHop = 0;
      refresh();
    }
    switch (_stage) {
      case _Stage.waiting:
        if (_stageTime >= _waitSeconds) _beginSentence();
      case _Stage.fetching:
        _patience = max(0.0, _patience - dt / _fetchSeconds);
        if (_patience <= 0) _outOfPatience();
      case _Stage.built:
        if (_stageTime >= _builtHold) _next();
      case _Stage.tooSlow:
        if (_stageTime >= _tooSlowHold) _next();
    }
  }

  void _beginSentence() {
    final wave =
        FetchRules.deal(_pool, asked: _asked, previous: _last, random: rng);
    if (wave == null) {
      finish();
      return;
    }
    refresh(() {
      _wave = wave;
      _cast = SpellCast(wave);
      _last = wave.sentence;
      _asked.add(wave.sentence);
      // Fixed for the sentence, so the hearts never empty faster halfway.
      _fetchSeconds = FetchRules.fetchTime(
                  words: wave.sentence.tokens.length, combo: score.combo)
              .inMicroseconds /
          1e6;
      _patience = 1;
      _clean = true;
      _flashing = null;
      _stage = _Stage.fetching;
      _stageTime = 0;
    });
    if (!reduceMotion) petHop = 0;
  }

  Offset _local(Offset global) {
    final box = _sceneKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.globalToLocal(global) ?? global;
  }

  void _tapStick(int index, Offset global) {
    final wave = _wave, cast = _cast, geo = _geo;
    if (_stage != _Stage.fetching ||
        wave == null ||
        cast == null ||
        geo == null) {
      return;
    }
    final at = _local(global);
    switch (cast.tap(index)) {
      case SpellTap.ignored:
        return;
      case SpellTap.fizzle:
        _clean = false;
        _flashing = index;
        _flashAt = _time;
        _patience = max(0.02, _patience - FetchRules.mistakeCost);
        slip(PlayPractice.sentence(wave.sentence), at: at);
      case SpellTap.placed:
        refresh(() => _tosses.add(_Toss(wave.stones[index], at)));
      case SpellTap.complete:
        _tosses.add(_Toss(wave.stones[index], at));
        final head = Offset(geo.petX, geo.petTop + geo.petBox * 0.3);
        if (_clean) {
          scoreRight(at: head, petBox: geo.petBox);
        } else {
          scoreMissed(PlayPractice.sentence(wave.sentence));
        }
        refresh(() {
          _stage = _Stage.built;
          _stageTime = 0;
        });
    }
  }

  void _outOfPatience() {
    final wave = _wave, geo = _geo;
    if (wave == null || geo == null) return;
    scoreMissed(PlayPractice.sentence(wave.sentence));
    bonk(at: Offset(geo.petX, geo.petTop + geo.petBox * 0.2));
    refresh(() {
      _tosses.clear();
      _stage = _Stage.tooSlow;
      _stageTime = 0;
    });
  }

  void _next() {
    if (score.played >= rounds) {
      finish();
      return;
    }
    refresh(() {
      _wave = null;
      _cast = null;
      _tosses.clear();
      _waitSeconds = _wait;
      _stage = _Stage.waiting;
      _stageTime = 0;
    });
  }

  // ---------------------------------------------------------------- build --

  @override
  Widget buildScene(BoxConstraints box) {
    final old = _geo;
    final geo = old != null && old.w == box.maxWidth && old.h == box.maxHeight
        ? old
        : _geo = _Geo(box.maxWidth, box.maxHeight);
    final wave = _wave, cast = _cast;
    final placed = cast?.placed ?? const <int>[];
    // A word is on the line once its stick is caught.
    final shown = wave == null
        ? const <String>[]
        : _stage == _Stage.tooSlow
            ? wave.sentence.tokens
            : [
                for (final i in placed.take(placed.length - _tosses.length))
                  wave.stones[i],
              ];

    return Stack(
      key: _sceneKey,
      children: [
        const Positioned.fill(child: ColoredBox(color: PlayPalette.glass)),
        Positioned(
          left: 0,
          right: 0,
          top: geo.horizon,
          bottom: 0,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: PlayPalette.leaf,
              border: Border(
                  top: BorderSide(color: PlayPalette.ink, width: 3)),
            ),
          ),
        ),
        ..._buildPark(geo),
        particleLayer(front: false),
        if (wave != null)
          Positioned(
            left: geo.petX + geo.petBox * 0.55,
            top: geo.horizon - 34,
            child: IgnorePointer(child: PatienceHearts(left: _patience)),
          ),
        positionedPet(
          feet: Offset(geo.petX, geo.petFeet),
          size: geo.petBox,
        ),
        ...dizzyStars(
            Offset(geo.petX, geo.petTop + geo.petBox * 0.2), geo.petBox),
        ...buildHearts(geo.petBox),
        if (wave != null)
          Positioned(
            left: 12,
            right: 12,
            top: geo.lineTop,
            height: _Geo.lineH,
            child: IgnorePointer(
              child: Center(
                child: PlaySpellLine(
                  slots: wave.sentence.tokens.length,
                  filled: shown,
                  style: pixelTarget(11, PlayPalette.ink),
                  glow: _stage == _Stage.built && _tosses.isEmpty,
                  textDirection: targetDirection,
                ),
              ),
            ),
          ),
        if (wave != null && cast != null)
          Positioned(
            left: 12,
            right: 12,
            top: geo.sticksTop,
            bottom: 8,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < wave.stones.length; i++)
                    WordStick(
                      label: wave.stones[i],
                      style: pixelTarget(12, PlayPalette.ink),
                      used: placed.contains(i) || _stage == _Stage.tooSlow,
                      flashing: _flashing == i && _time - _flashAt < 0.3,
                      onTapDown: _stage == _Stage.fetching
                          ? (global) => _tapStick(i, global)
                          : null,
                    ),
                ],
              ),
            ),
          ),
        for (final toss in _tosses) _buildToss(geo, toss),
        if (wave != null)
          Positioned(
            left: 12,
            top: _Geo.promptTop,
            width: geo.w - 24,
            height: _Geo.promptH + PlayBubble.tailH,
            child: IgnorePointer(
              child: PlayBubble(
                word: wave.sentence.meaning,
                style: pixelNative(14, PlayGameState.ink),
                tailX: (geo.petX - 12).clamp(24.0, geo.w - 48),
              ),
            ),
          ),
        particleLayer(front: true),
        ...buildPopups(),
      ],
    );
  }

  /// The tree and the bush on the grass line, the flowers lower down.
  List<Widget> _buildPark(_Geo geo) {
    Widget art(List<String> rows, Map<String, Color> inks) => IgnorePointer(
          child: SizedBox(
            width: rows.first.length * PlayPalette.cell,
            height: rows.length * PlayPalette.cell,
            child: CustomPaint(painter: PixelPatternPainter(rows, inks)),
          ),
        );
    final treeH = parkTreeArtRows.length * PlayPalette.cell;
    final bushH = parkBushArtRows.length * PlayPalette.cell;
    final flowerH = parkFlowerArtRows.length * PlayPalette.cell;
    // Where the flowers grow: whole cells, below the sticks.
    const spots = [
      Offset(0.08, 0.90),
      Offset(0.24, 0.80),
      Offset(0.37, 0.95),
      Offset(0.55, 0.84),
      Offset(0.70, 0.93),
      Offset(0.88, 0.82),
    ];
    return [
      Positioned(
        right: 8,
        top: geo.horizon + 3 - treeH,
        child: art(parkTreeArtRows, parkTreeArtInks),
      ),
      Positioned(
        left: 4,
        top: geo.horizon + 2 - bushH,
        child: art(parkBushArtRows, parkBushArtInks),
      ),
      for (final spot in spots)
        Positioned(
          left: (geo.w * spot.dx / PlayPalette.cell).roundToDouble() *
              PlayPalette.cell,
          top: ((geo.h * spot.dy - flowerH) / PlayPalette.cell)
                  .roundToDouble() *
              PlayPalette.cell,
          child: art(parkFlowerArtRows, parkFlowerArtInks),
        ),
    ];
  }

  /// A stick in the air, turning end over end on its way to the pet.
  Widget _buildToss(_Geo geo, _Toss toss) {
    final k = (toss.t / _tossSeconds).clamp(0.0, 1.0);
    final to = geo.mouth;
    final lift = geo.petBox * 0.6 * 4 * k * (1 - k);
    final at = Offset(
      toss.from.dx + (to.dx - toss.from.dx) * k,
      toss.from.dy + (to.dy - toss.from.dy) * k - lift,
    );
    final turns = reduceMotion ? 0 : (k * 4).floor() % 4;
    return Positioned(
      left: (at.dx / 2).roundToDouble() * 2,
      top: (at.dy / 2).roundToDouble() * 2,
      child: IgnorePointer(
        child: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: Transform.rotate(
            angle: turns * pi / 2,
            child: Transform.scale(
              scale: 1 - 0.35 * k,
              child: WordStick(
                label: toss.label,
                style: pixelTarget(12, PlayPalette.ink),
                onTapDown: null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
