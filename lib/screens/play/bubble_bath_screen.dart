import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/play/play_kit.dart';
import '../../components/play/play_props.dart';
import '../../components/play/toy_chest_art.dart';
import '../../providers/vocab_provider.dart';
import '../../utils/boss_trial.dart';
import '../../utils/boss_trial_angler.dart';
import '../../utils/play_games.dart';
import 'play_game_state.dart';

/// Bubble Bath: Lanternmaw's Bubbles, played in the tub.
///
/// The pet sits in the bath and asks for a word by its meaning, in the
/// player's language. Bubbles rise off the water carrying letters of the
/// word in the language being learned — spares of them, and two it does not
/// have — and popping them in order spells it on the side of the tub. The
/// water draining is the clock: it shows on the pet, who comes up out of it
/// as it goes down. A wrong letter lets some out. Spelled with no slips, the
/// pet is delighted; drained first, the tub shows the word and refills for
/// the next. See [BubbleBathRules].
class BubbleBathScreen extends StatefulWidget {
  const BubbleBathScreen({super.key, this.random});

  /// Fixed in tests, so the words are known.
  final Random? random;

  @override
  State<BubbleBathScreen> createState() => _BubbleBathScreenState();
}

enum _Stage {
  /// The tub filling up before the next word.
  filling,

  /// Bubbles up, and the letters open.
  spelling,

  /// Spelled: the word lit on the tub.
  spelled,

  /// Drained first: the word shown, the pet glum.
  drained,
}

/// Scene geometry for one layout.
///
/// The pet's word along the top, the tub along the bottom with the pet in
/// it, and between them the wall the bubbles rise up. The tub is drawn in
/// three layers — its inside behind the pet, the water over it, its front
/// over both — so the pet sits in the water rather than on it.
class _Geo {
  _Geo(this.w, this.h) {
    petBox = min(min(h * 0.2, w * 0.38), 140.0).roundToDouble();
    floorTop = (h - max(36.0, h * 0.07)).roundToDouble();
    tubW = ((min(w - 24, 440.0)) / 4).floorToDouble() * 4;
    tubLeft = ((w - tubW) / 2).roundToDouble();
    frontH = max(100.0, spellLineH + 52);
    frontTop = (floorTop + 16 - frontH).roundToDouble();
    insideH = max(28.0, (petBox * 0.42 / 4).roundToDouble() * 4);
    backTop = frontTop - insideH;
    // The tile band stops a step above the tub's rim.
    wainscotTop = (backTop - 7 * PlayPalette.cell).roundToDouble();
    petX = (w / 2).roundToDouble();
    // Feet just behind the front of the tub: sprites stand low in their box,
    // and any lower and the bath hides all but the ears.
    petFeet = (frontTop + petBox * 0.06).roundToDouble();
    petTop = petFeet - petBox;
    spellTop = (frontTop + (frontH - TubFrontPainter.feetH - spellLineH) / 2 + 2)
        .roundToDouble();
    bubblesTop = promptTop + promptH + PlayBubble.tailH + 10;
    bubblesBottom = backTop - 6;
  }

  static const double promptTop = 8;
  static const double promptH = 54;
  static const double spellLineH = 46;
  static const double bubble = 52;

  final double w, h;
  late final double petBox, floorTop, tubW, tubLeft, frontH, frontTop;
  late final double insideH, backTop, wainscotTop, petX, petFeet, petTop;
  late final double spellTop;
  late final double bubblesTop, bubblesBottom;

  /// Where the water's surface is with [level] of it left: up the pet's body
  /// when full, behind the front of the tub when drained.
  double waterTop(double level) =>
      (frontTop - level.clamp(0.0, 1.0) * insideH * 0.75).roundToDouble();
}

class _BubbleBathScreenState extends PlayGameState<BubbleBathScreen> {
  static const double _firstFill = 0.9;
  static const double _fill = 0.6;
  static const double _spelledHold = 1.3;
  static const double _drainedHold = 1.7;

  /// Seconds for a bubble to rise from the water to the top of the wall.
  static const double _rise = 6;

  List<TrialWord> _pool = const [];
  _Geo? _geo;

  _Stage _stage = _Stage.filling;
  double _stageTime = 0;
  double _fillSeconds = _firstFill;
  double _fillFrom = 0;
  double _time = 0;

  BubbleWave? _wave;
  SpellCast? _cast;
  TrialWord? _lastWord;
  double _drainSeconds = 9;

  /// How much water is in the tub: 1 full, 0 drained.
  double _level = 0;

  /// Seconds since this word's bubbles came up.
  double _t = 0;
  List<double> _jitter = const [];

  /// Whether this word has been spelled without a wrong letter so far.
  bool _clean = true;
  int? _flashing;
  double _flashAt = -1;

  @override
  Random? get seed => widget.random;

  @override
  int get rounds => BubbleBathRules.wordsPerGame;

  @override
  double get particleFloor => _geo?.floorTop ?? 0;

  @override
  bool loadContent() {
    final words = bubbleBathWords(
      items: context.read<VocabProvider>().practiseItems,
      targetCode: targetCode,
      nativeCode: nativeCode,
    );
    _pool = words.pool;
    targetCode = words.targetCode;
    nativeCode = words.nativeCode;
    return BubbleWave.isPlayable(_pool);
  }

  @override
  void resetGame() {
    _wave = null;
    _cast = null;
    _lastWord = null;
    _flashing = null;
    _fillFrom = _level;
    _fillSeconds = _firstFill;
    _stage = _Stage.filling;
    _stageTime = 0;
  }

  @override
  void step(double dt) {
    _time += dt;
    _stageTime += dt;
    switch (_stage) {
      case _Stage.filling:
        final k = (_stageTime / _fillSeconds).clamp(0.0, 1.0);
        _level = _fillFrom + (1 - _fillFrom) * k;
        if (k >= 1) _beginWord();
      case _Stage.spelling:
        _t += dt;
        _level = max(0.0, _level - dt / _drainSeconds);
        if (_level <= 0) _drain();
      case _Stage.spelled:
        _t += dt;
        if (_stageTime >= _spelledHold) _next();
      case _Stage.drained:
        if (_stageTime >= _drainedHold) _next();
    }
  }

  void _beginWord() {
    final wave = BubbleWave.build(_pool, previous: _lastWord, random: rng);
    if (wave == null) {
      finish();
      return;
    }
    refresh(() {
      _wave = wave;
      _cast = SpellCast(wave.spell);
      _lastWord = wave.word;
      // Fixed for the word, so the water never speeds up halfway down.
      _drainSeconds = BubbleBathRules.drainTime(
                  letters: wave.letters.length, combo: score.combo)
              .inMicroseconds /
          1e6;
      _jitter = [for (final _ in wave.bubbles) rng.nextDouble() * 0.12];
      _t = 0;
      _clean = true;
      _flashing = null;
      _level = 1;
      _stage = _Stage.spelling;
      _stageTime = 0;
    });
    // The pet asks as the bubbles come up.
    if (!reduceMotion) petHop = 0;
  }

  void _tapBubble(int index) {
    final wave = _wave, cast = _cast, geo = _geo;
    if (_stage != _Stage.spelling || wave == null || cast == null || geo == null) {
      return;
    }
    final at = _bubbleRect(geo, index).center;
    switch (cast.tap(index)) {
      case SpellTap.ignored:
        return;
      case SpellTap.fizzle:
        _clean = false;
        _flashing = index;
        _flashAt = _t;
        _level = max(0.02, _level - BubbleBathRules.mistakeDrain);
        slip(PlayPractice.word(wave.word), at: at);
      case SpellTap.placed:
        refresh();
        if (!reduceMotion) {
          particles.sparks(at, count: 8, colors: BathWaterPainter.foam);
        }
      case SpellTap.complete:
        if (!reduceMotion) {
          particles.sparks(at, count: 8, colors: BathWaterPainter.foam);
          _popLeftovers(geo);
        }
        final head = Offset(geo.petX, geo.petTop + geo.petBox * 0.3);
        if (_clean) {
          scoreRight(at: head, petBox: geo.petBox);
        } else {
          // Got there in the end: a hop, but it was not a clean one.
          scoreMissed(PlayPractice.word(wave.word));
          if (!reduceMotion) petHop = 0;
        }
        refresh(() {
          _stage = _Stage.spelled;
          _stageTime = 0;
        });
    }
  }

  /// The water ran out before the word was spelled.
  void _drain() {
    final wave = _wave, geo = _geo;
    if (wave == null || geo == null) return;
    if (!reduceMotion) _popLeftovers(geo);
    scoreMissed(PlayPractice.word(wave.word));
    bonk(at: Offset(geo.petX, geo.petTop + geo.petBox * 0.2));
    refresh(() {
      _stage = _Stage.drained;
      _stageTime = 0;
    });
  }

  /// Every bubble still up bursts.
  void _popLeftovers(_Geo geo) {
    final wave = _wave, cast = _cast;
    if (wave == null || cast == null) return;
    for (var i = 0; i < wave.bubbles.length; i++) {
      if (cast.placed.contains(i)) continue;
      particles.sparks(_bubbleRect(geo, i).center,
          count: 4, colors: BathWaterPainter.foam);
    }
  }

  void _next() {
    if (score.played >= rounds) {
      finish();
      return;
    }
    refresh(() {
      _wave = null;
      _cast = null;
      _fillFrom = _level;
      _fillSeconds = _fill;
      _stage = _Stage.filling;
      _stageTime = 0;
    });
  }

  /// Bubble [index]'s box, [_t] into the rise.
  ///
  /// The bubbles take columns across the wall, two to a column half a rise
  /// apart, so none ever overlaps another; each wraps back down into the
  /// water when it reaches the top. Lanternmaw's layout, on dry land.
  Rect _bubbleRect(_Geo geo, int index) {
    final n = _wave!.bubbles.length;
    final columns = (n / 2).ceil();
    final column = index % columns;
    final second = index ~/ columns;
    final colW = (geo.w - 16) / columns;
    final span = max(1.0, geo.bubblesBottom - _Geo.bubble - geo.bubblesTop);
    final k = (_t / _rise + second * 0.5 + column * 0.17 + _jitter[index]) %
        1.0;
    final wobble = sin(_t * 2.2 + index * 1.7) * 4;
    final left = 8 + colW * (column + 0.5) - _Geo.bubble / 2 + wobble;
    return Rect.fromLTWH(
      left.roundToDouble(),
      (geo.bubblesTop + span * (1 - k)).roundToDouble(),
      _Geo.bubble,
      _Geo.bubble,
    );
  }

  // ---------------------------------------------------------------- build --

  @override
  Widget buildScene(BoxConstraints box) {
    final old = _geo;
    final geo = old != null && old.w == box.maxWidth && old.h == box.maxHeight
        ? old
        : _geo = _Geo(box.maxWidth, box.maxHeight);
    final wave = _wave, cast = _cast;
    final waterTop = geo.waterTop(_level);

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: BathroomPainter(
              floorTop: geo.floorTop,
              wainscotTop: geo.wainscotTop,
            ),
          ),
        ),
        // The window over the tub, on the wall above the tile band.
        Positioned(
          left: geo.tubLeft + 4 * PlayPalette.cell,
          top: geo.wainscotTop - bathWindowArtRows.length * PlayPalette.cell,
          width: bathWindowArtRows.first.length * PlayPalette.cell,
          height: bathWindowArtRows.length * PlayPalette.cell,
          child: const CustomPaint(
            painter: PixelPatternPainter(bathWindowArtRows, bathWindowArtInks),
          ),
        ),
        Positioned(
          left: geo.tubLeft,
          top: geo.backTop,
          width: geo.tubW,
          height: geo.frontTop - geo.backTop + 8,
          child: const CustomPaint(painter: TubBackPainter()),
        ),
        particleLayer(front: false),
        positionedPet(
          feet: Offset(geo.petX, geo.petFeet),
          size: geo.petBox,
        ),
        if (waterTop < geo.frontTop)
          Positioned(
            left: geo.tubLeft + 12,
            width: geo.tubW - 24,
            top: waterTop,
            height: geo.frontTop + 4 - waterTop,
            child: IgnorePointer(
              child: CustomPaint(painter: BathWaterPainter(_time)),
            ),
          ),
        Positioned(
          left: geo.tubLeft,
          top: geo.frontTop,
          width: geo.tubW,
          height: geo.frontH,
          child: const CustomPaint(painter: TubFrontPainter()),
        ),
        if (wave != null && cast != null)
          Positioned(
            left: geo.tubLeft + 20,
            right: geo.w - geo.tubLeft - geo.tubW + 20,
            top: geo.spellTop,
            height: _Geo.spellLineH,
            child: IgnorePointer(
              child: Center(
                child: PlaySpellLine(
                  slots: wave.letters.length,
                  filled: _stage == _Stage.drained
                      ? wave.letters
                      : [for (final i in cast.placed) wave.bubbles[i]],
                  style: pixelTarget(12, PlayPalette.ink),
                  glow: _stage == _Stage.spelled,
                  textDirection: targetDirection,
                ),
              ),
            ),
          ),
        ...dizzyStars(
            Offset(geo.petX, geo.petTop + geo.petBox * 0.2), geo.petBox),
        ...buildHearts(geo.petBox),
        if (wave != null && cast != null && _stage == _Stage.spelling)
          for (var i = 0; i < wave.bubbles.length; i++)
            if (!cast.placed.contains(i))
              Positioned.fromRect(
                rect: _bubbleRect(geo, i),
                child: PlayLetterBubble(
                  label: wave.bubbles[i],
                  style: pixelTarget(14, PlayGameState.ink),
                  flashing: _flashing == i && _t - _flashAt < 0.3,
                  onTapDown: () => _tapBubble(i),
                ),
              ),
        if (wave != null)
          Positioned(
            left: 12,
            top: _Geo.promptTop,
            width: geo.w - 24,
            height: _Geo.promptH + PlayBubble.tailH,
            child: IgnorePointer(
              child: PlayBubble(
                word: wave.word.meaning,
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
}
