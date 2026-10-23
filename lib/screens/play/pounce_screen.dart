import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/boss_trial/arena_pieces.dart' show ShoutBubble;
import '../../components/play/play_props.dart';
import '../../constants/theme.dart';
import '../../providers/vocab_provider.dart';
import '../../utils/boss_trial.dart';
import '../../utils/boss_trial_moss.dart';
import '../../utils/play_games.dart';
import 'play_game_state.dart';

/// Pounce: Mossback's Pebble Pop, played in the garden.
///
/// The pet wants a word by its meaning, in the player's language. Moles pop
/// out of six molehills holding up signs with words in the language being
/// learned, ducking back after a moment; tap the one that says it and the
/// pet pounces on it. The right word comes up twice, so missing it once is
/// not the end. A wrong mole costs the streak, never the round's chance;
/// letting every mole go by shows which one it was. See [PounceRules].
class PounceScreen extends StatefulWidget {
  const PounceScreen({super.key, this.random});

  /// Fixed in tests, so the waves are known.
  final Random? random;

  @override
  State<PounceScreen> createState() => _PounceScreenState();
}

enum _Stage {
  /// A beat between waves.
  waiting,

  /// Moles popping, and the signs open.
  popping,

  /// The right mole tapped: the pet in the air, then landed on it.
  pouncing,

  /// Every mole gone by: the right one comes up lit.
  revealing,
}

/// Scene geometry for one layout: sky across the top with the pet's word in
/// it, the pet on the edge of the grass, and the molehills in two rows of
/// three below it, where the thumb is.
class _Geo {
  _Geo(this.w, this.h) {
    petBox = min(min(h * 0.2, w * 0.36), 130.0).roundToDouble();
    horizon = max(h * 0.34, petBox + _promptBottom + 10).roundToDouble();
    petX = (w / 2).roundToDouble();
    petFeet = horizon + 6;
    petTop = petFeet - petBox;
    colW = (w - 16) / 3;
    signW = min(colW - 12, 150.0).roundToDouble();
    popH = (signH * (1 + MoleSign.headShare)).roundToDouble();
    moundW = (min(signW * 0.7, 92.0) / 4).roundToDouble() * 4;
    final block = popH + lipH;
    final gap = max(8.0, (h - horizon - 8 - 2 * block) / 3);
    holeY = [
      for (var r = 0; r < 2; r++)
        (horizon + gap * (r + 1) + block * r + popH).roundToDouble(),
    ];
  }

  static const double promptTop = 8;
  static const double promptH = 54;
  static const double _promptBottom = promptTop + promptH + 12;
  static const double signH = 40;
  static const double lipH = 24;

  /// The far side of a molehill, and how much of it stands above the line
  /// its mole comes out of: the dark of the hole shows there.
  static const double moundBackH = 20;
  static const double moundBackAbove = 16;

  final double w, h;
  late final double petBox, horizon, petX, petFeet, petTop;
  late final double colW, signW, popH, moundW;

  /// Where each row's moles come out: the line they rise from.
  late final List<double> holeY;

  double holeX(int hole) => (8 + colW * (hole % 3 + 0.5)).roundToDouble();
  double holeLine(int hole) => holeY[hole ~/ 3];

  /// Where the pet lands on a mole in [hole]: on its head.
  Offset pounceFeet(int hole) =>
      Offset(holeX(hole), holeLine(hole) - popH * 0.45);
}

class _PounceScreenState extends PlayGameState<PounceScreen> {
  static const double _firstWait = 0.9;
  static const double _wait = 0.5;

  /// The beat before the first mole, so the word is read first.
  static const double _lead = 0.55;

  /// How long a mole takes to come up out of its hill, or duck back in.
  static const double _rise = 0.14;

  static const double _leapSeconds = 0.32;
  static const double _sitSeconds = 0.45;
  static const double _revealSeconds = 1.2;

  List<TrialWord> _pool = const [];
  _Geo? _geo;

  _Stage _stage = _Stage.waiting;
  double _stageTime = 0;
  double _waitSeconds = _firstWait;

  PebbleWave? _wave;
  TrialWord? _lastPrompt;
  double _t = 0;
  double _interval = 0.9;
  double _upTime = 1.8;

  /// Whether this wave has been played without a wrong mole so far.
  bool _clean = true;

  /// Pops tapped wrong, and when, so they flash and duck.
  final Map<int, double> _wrongAt = {};

  /// The pop pounced on, once it has been.
  int? _hit;

  @override
  Random? get seed => widget.random;

  @override
  int get rounds => PounceRules.wavesPerGame;

  @override
  double get particleFloor => _geo?.h ?? 0;

  @override
  bool loadContent() {
    final words = playWords(
      items: context.read<VocabProvider>().practiseItems,
      targetCode: targetCode,
      nativeCode: nativeCode,
    );
    _pool = words.pool;
    targetCode = words.targetCode;
    nativeCode = words.nativeCode;
    return TrialWordPool.isPlayable(_pool);
  }

  @override
  void resetGame() {
    _wave = null;
    _lastPrompt = null;
    _wrongAt.clear();
    _hit = null;
    _waitSeconds = _firstWait;
    _stage = _Stage.waiting;
    _stageTime = 0;
  }

  @override
  void step(double dt) {
    _stageTime += dt;
    _t += dt;
    switch (_stage) {
      case _Stage.waiting:
        if (_stageTime >= _waitSeconds) _beginWave();
      case _Stage.popping:
        final wave = _wave;
        if (wave != null && _t >= _popStart(wave.pops.length - 1) + _upTime) {
          _reveal();
        }
      case _Stage.pouncing:
        if (_stageTime >= _leapSeconds && _hit != null && !_landed) _land();
        if (_stageTime >= 2 * _leapSeconds + _sitSeconds) _next();
      case _Stage.revealing:
        if (_stageTime >= _revealSeconds) _next();
    }
  }

  bool _landed = false;

  double _popStart(int i) => _lead + i * _interval;

  /// How far up pop [i] is: 0 in its hill, 1 right up.
  double _riseOf(int i) {
    if (i == _hit) return 1;
    final local = _t - _popStart(i);
    final wrongAt = _wrongAt[i];
    if (wrongAt != null) {
      // Tapped wrong: it flinches, then ducks.
      return (1 - (_t - wrongAt - 0.2) / _rise).clamp(0.0, 1.0);
    }
    if (_stage == _Stage.pouncing) {
      // Everything else ducks the moment the pet goes.
      final since = _stageTime;
      final up = _riseAt(local - since);
      return (up - since / _rise).clamp(0.0, 1.0);
    }
    if (_stage != _Stage.popping) return 0;
    return _riseAt(local);
  }

  double _riseAt(double local) {
    if (local < 0 || local > _upTime) return 0;
    if (local < _rise) return local / _rise;
    if (local > _upTime - _rise) return (_upTime - local) / _rise;
    return 1;
  }

  void _beginWave() {
    final wave = PebbleWave.build(_pool, previous: _lastPrompt, random: rng);
    if (wave == null) {
      finish();
      return;
    }
    refresh(() {
      _wave = wave;
      _lastPrompt = wave.prompt;
      // Fixed for the wave, so the moles never quicken halfway.
      _interval = PounceRules.popInterval(score.combo).inMicroseconds / 1e6;
      _upTime = PounceRules.popUp(score.combo).inMicroseconds / 1e6;
      _t = 0;
      _clean = true;
      _wrongAt.clear();
      _hit = null;
      _landed = false;
      _stage = _Stage.popping;
      _stageTime = 0;
    });
    if (!reduceMotion) petHop = 0;
  }

  void _tapMole(int i) {
    final wave = _wave, geo = _geo;
    if (_stage != _Stage.popping || wave == null || geo == null) return;
    // Any mole that shows can be had: one just coming up or just ducking is
    // still the word, and a tap on it that did nothing would read as broken.
    if (_wrongAt.containsKey(i) || _riseOf(i) <= 0) return;
    final pop = wave.pops[i];
    if (!wave.isRight(pop)) {
      _clean = false;
      _wrongAt[i] = _t;
      slip(PlayPractice.word(wave.prompt),
          at: Offset(geo.holeX(pop.hole), geo.holeLine(pop.hole) - geo.popH));
      return;
    }
    refresh(() {
      _hit = i;
      _stage = _Stage.pouncing;
      _stageTime = 0;
    });
  }

  /// The pet comes down on the mole.
  void _land() {
    final wave = _wave, geo = _geo, hit = _hit;
    if (wave == null || geo == null || hit == null) return;
    _landed = true;
    final hole = wave.pops[hit].hole;
    final at = geo.pounceFeet(hole);
    if (!reduceMotion) {
      particles.sparks(Offset(at.dx, geo.holeLine(hole)),
          count: 8, colors: MolehillPainter.dirt);
    }
    final head = at.translate(0, -geo.petBox * 0.7);
    if (_clean) {
      scoreRight(at: head, petBox: geo.petBox);
    } else {
      scoreMissed(PlayPractice.word(wave.prompt));
      if (!reduceMotion) petHop = 0;
    }
  }

  /// Every mole has been and gone: the right one comes up, lit.
  void _reveal() {
    final wave = _wave, geo = _geo;
    if (wave == null || geo == null) return;
    scoreMissed(PlayPractice.word(wave.prompt));
    bonk(at: Offset(geo.petX, geo.petTop + geo.petBox * 0.2));
    refresh(() {
      _stage = _Stage.revealing;
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
      _hit = null;
      _wrongAt.clear();
      _waitSeconds = _wait;
      _stage = _Stage.waiting;
      _stageTime = 0;
    });
  }

  /// Where the pet's feet are, and how high off its line it is: at its spot,
  /// or on its way to and from the mole it pounced on.
  (Offset, double) _petAt(_Geo geo) {
    final home = Offset(geo.petX, geo.petFeet);
    final wave = _wave, hit = _hit;
    if (_stage != _Stage.pouncing || wave == null || hit == null) {
      return (home, 0);
    }
    final target = geo.pounceFeet(wave.pops[hit].hole);
    final s = _stageTime;
    double k;
    Offset from, to;
    if (s < _leapSeconds) {
      k = s / _leapSeconds;
      from = home;
      to = target;
    } else if (s < _leapSeconds + _sitSeconds) {
      return (target, 0);
    } else {
      k = ((s - _leapSeconds - _sitSeconds) / _leapSeconds).clamp(0.0, 1.0);
      from = target;
      to = home;
    }
    // In whole steps of two pixels, like every other move the pet makes.
    final lift = geo.petBox * 0.5 * 4 * k * (1 - k);
    final at = Offset.lerp(from, to, k)!;
    return (
      Offset((at.dx / 2).roundToDouble() * 2, (at.dy / 2).roundToDouble() * 2),
      (lift / 2).roundToDouble() * 2,
    );
  }

  // ---------------------------------------------------------------- build --

  @override
  Widget buildScene(BoxConstraints box) {
    final old = _geo;
    final geo = old != null && old.w == box.maxWidth && old.h == box.maxHeight
        ? old
        : _geo = _Geo(box.maxWidth, box.maxHeight);
    final wave = _wave;
    final (feet, lift) = _petAt(geo);
    final airborne = lift > 2;

    return Stack(
      children: [
        Positioned.fill(child: Container(color: AppTheme.retroSky)),
        Positioned(
          left: 0,
          right: 0,
          top: geo.horizon,
          bottom: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.retroGrass,
              border: Border(
                  top: BorderSide(color: PlayGameState.ink, width: 4)),
            ),
          ),
        ),
        for (var hole = 0; hole < MossRules.holes; hole++)
          Positioned(
            left: geo.holeX(hole) - geo.moundW / 2,
            top: geo.holeLine(hole) - _Geo.moundBackAbove,
            width: geo.moundW,
            height: _Geo.moundBackH,
            child: const CustomPaint(painter: MolehillPainter(back: true)),
          ),
        if (wave != null) ..._buildMoles(geo, wave),
        for (var hole = 0; hole < MossRules.holes; hole++)
          Positioned(
            left: geo.holeX(hole) - geo.moundW / 2 - 4,
            top: geo.holeLine(hole) - 4,
            width: geo.moundW + 8,
            height: _Geo.lipH,
            child: const IgnorePointer(
              child: CustomPaint(painter: MolehillPainter(back: false)),
            ),
          ),
        particleLayer(front: false),
        positionedPet(
          feet: feet,
          size: geo.petBox,
          lift: lift,
          air: airborne,
        ),
        ...dizzyStars(
            Offset(geo.petX, geo.petTop + geo.petBox * 0.2), geo.petBox),
        ...buildHearts(geo.petBox),
        if (wave != null)
          Positioned(
            left: 12,
            top: _Geo.promptTop,
            width: geo.w - 24,
            height: _Geo.promptH + ShoutBubble.tailH,
            child: IgnorePointer(
              child: ShoutBubble(
                word: wave.prompt.meaning,
                style: pixelNative(16, PlayGameState.ink),
                tailX: (geo.petX - 12).clamp(24.0, geo.w - 48),
              ),
            ),
          ),
        particleLayer(front: true),
        ...buildPopups(),
      ],
    );
  }

  List<Widget> _buildMoles(_Geo geo, PebbleWave wave) {
    final revealing = _stage == _Stage.revealing;
    // When it got away, the last of its two pops comes back up, lit.
    final reveal = revealing
        ? wave.pops.lastIndexWhere((p) => wave.isRight(p))
        : null;
    final style = pixelTarget(10, PlayGameState.ink);
    return [
      for (var i = 0; i < wave.pops.length; i++)
        Builder(builder: (_) {
          final pop = wave.pops[i];
          final rise = i == reveal
              ? (_stageTime / _rise).clamp(0.0, 1.0)
              : revealing
                  ? 0.0
                  : _riseOf(i);
          if (rise <= 0) return const SizedBox.shrink();
          final line = geo.holeLine(pop.hole);
          final state = i == reveal
              ? PropState.right
              : _wrongAt.containsKey(i)
                  ? PropState.wrong
                  : PropState.plain;
          final bonked = i == _hit && _landed;
          // Squashed down into its hill under the pet.
          final squash = bonked ? 0.35 : 0.0;
          final down = ((1 - rise + squash) * geo.popH / 4).roundToDouble() * 4;
          return Positioned(
            left: geo.holeX(pop.hole) - geo.signW / 2,
            top: line - geo.popH,
            width: geo.signW,
            height: geo.popH,
            child: ClipRect(
              child: Transform.translate(
                offset: Offset(0, down),
                child: MoleSign(
                  label: pop.word.target,
                  style: state == PropState.wrong
                      ? pixelTarget(10, propInk(state))
                      : style,
                  state: state,
                  bonked: bonked || state == PropState.wrong,
                  onTapDown: _stage == _Stage.popping && state == PropState.plain
                      ? () => _tapMole(i)
                      : null,
                ),
              ),
            ),
          );
        }),
    ];
  }
}
