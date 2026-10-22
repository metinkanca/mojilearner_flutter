part of 'boss_trial_screen.dart';

// Lanternmaw's openers under test: the Lure and the Bubbles. The rules are in
// `utils/boss_trial_angler.dart`; this is their clock, their layout and their
// taps, on the screen's own game clock.

// ---- Lure -------------------------------------------------------------------

class _LureRound {
  _LureRound(this.wave, {required this.lightSeconds, required Random rng})
      : phases = [
          for (var i = 0; i < wave.fish.length; i++) rng.nextDouble() * 2 * pi
        ];

  final LureWave wave;
  final double lightSeconds;

  /// Where along its swim each fish starts.
  final List<double> phases;

  /// How far the lantern has dimmed: 0 lit, 1 out.
  double dim = 0;

  /// Seconds since the fish came.
  double t = 0;

  /// Fish tapped that were wrong: they dart off.
  final Set<int> fled = {};

  /// The fish just refused, and when.
  int? flashing;
  double flashAt = -1;

  bool hooked = false;

  /// The pet has nipped the hooked fish, which is gone.
  bool nipped = false;

  /// The lantern went out: the gap shows what it needed.
  bool missed = false;

  /// When the fish stopped swimming: one was hooked, or the light went out.
  double? stoppedAt;

  /// How fast each fish swims its band, in radians a second.
  static const List<double> speeds = [0.8, 1.15, 0.6];
}

extension _LureFlow on _BossTrialScreenState {
  void _beginLure() {
    final wave =
        LureWave.build(_sentences, previous: _lastScroll, random: _rng);
    if (wave == null) {
      _throwWave();
      return;
    }
    _refresh(() {
      // Fixed when it lights, so the lantern never dims faster mid-sentence.
      _lure = _LureRound(
        wave,
        lightSeconds: _BossTrialScreenState._secs(AnglerRules.lureTime(
          words: wave.sentence.tokens.length,
          patience: _clockPatience,
        )),
        rng: _rng,
      );
      _lastScroll = wave.sentence;
      _stage = _Stage.jumping;
      _stageTime = 0;
      _startMove();
      _shouting = false;
    });
  }

  /// It arrives, and the lantern lights the sentence.
  void _openLure(_Geo geo) {
    _refresh(() {
      _stage = _Stage.luring;
      _stageTime = 0;
      _lure?.t = 0;
    });
    _landingShock(geo);
  }

  void _stepLure(double dt, _Geo geo) {
    final round = _lure;
    if (round == null || round.hooked || round.missed) return;
    round.dim = min(1.0, round.dim + dt / round.lightSeconds);
    if (round.dim < 1) return;

    // Out: the fish scatter, and it gulps.
    _refresh(() {
      round.missed = true;
      round.stoppedAt = round.t;
      _run = _run.castFailed(round.wave.sentence);
      _holdAftermath = true;
      _stage = _Stage.resolving;
      _stageTime = 0;
      _cackleTime = 0;
    });
    _strikePet(geo);
    if (_run.isOver) _endIn = 0.8;
  }

  void _tapFish(int fish) {
    final round = _lure;
    final geo = _geo;
    if (_phase != _Phase.playing ||
        _stage != _Stage.luring ||
        round == null ||
        geo == null ||
        round.hooked ||
        round.fled.contains(fish)) {
      return;
    }
    final rect = _fishRect(geo, round, fish);
    final at = rect.center;
    if (fish != round.wave.answer) {
      HapticFeedback.lightImpact();
      _refresh(() {
        round.fled.add(fish);
        round.flashing = fish;
        round.flashAt = round.t;
        round.dim = min(0.97, round.dim + AnglerRules.lureMistakeDim);
        _run = _run.fizzle();
      });
      if (!_reduceMotion) {
        _particles.sparks(at, count: 10, colors: AnglerPalette.bubbles);
        _cringeAt(at);
      }
      _pop('wrong', _BossTrialScreenState._hurtRed, at.translate(0, -30));
      return;
    }

    HapticFeedback.selectionClick();
    final earliness = 1 - round.dim;
    _refresh(() {
      round.hooked = true;
      round.stoppedAt = round.t;
      _stage = _Stage.resolving;
      _stageTime = 0;
    });
    // The pet dashes along the seabed to under it, nips it, and spits.
    _dashNipSpit(geo, rect, earliness, onNip: () => round.nipped = true);
  }

  // ---- layout ----

  /// What it says, in the player's language, under where it hovers.
  double _lurePromptTop(_Geo geo) => geo.chargeTop;

  /// The lantern's board, under the prompt.
  double _lureBoardTop(_Geo geo) => _lurePromptTop(geo) + _Geo.promptH + 8;
  static const double _lureBoardH = 96;

  /// The fish have all the water from the board down to the seabed, the
  /// pet's included: they swim in front of it.
  double _schoolTop(_Geo geo) => _lureBoardTop(geo) + _lureBoardH + 8;
  double _schoolBandH(_Geo geo) =>
      max(44.0, (geo.groundTop - 4 - _schoolTop(geo)) / AnglerRules.fish);

  Size _fishSize(_Geo geo) =>
      Size(min(170.0, (geo.w * 0.44).roundToDouble()), 44);

  /// Fish [fish]'s box, [round.t] into its swim.
  Rect _fishRect(_Geo geo, _LureRound round, int fish) {
    final t = round.stoppedAt ?? round.t;
    final size = _fishSize(geo);
    final reach = max(0.0, (geo.w - size.width) / 2 - 6);
    final speed = _LureRound.speeds[fish % _LureRound.speeds.length];
    final bob = (sin(t * 2.4 + fish) * 3).roundToDouble();
    final centre = Offset(
      (geo.w / 2 + reach * sin(speed * t + round.phases[fish]))
          .roundToDouble(),
      (_schoolTop(geo) + _schoolBandH(geo) * (fish + 0.5) + bob).roundToDouble(),
    );
    return Rect.fromCenter(
        center: centre, width: size.width, height: size.height);
  }

  /// Which way fish [fish] is swimming this frame.
  bool _fishFacingRight(_LureRound round, int fish) {
    final t = round.stoppedAt ?? round.t;
    final speed = _LureRound.speeds[fish % _LureRound.speeds.length];
    return cos(speed * t + round.phases[fish]) >= 0;
  }

  List<Widget> _buildLure(_Geo geo, _LureRound round) {
    if (_stage == _Stage.jumping) return const [];
    final wave = round.wave;
    final wordStyle =
        _pixel(11, _BossTrialScreenState._ink, localeCode: _languageCode);
    final flashing =
        round.flashing != null && round.t - round.flashAt < 0.3;
    final pieces = <Widget>[
      Positioned(
        left: _Geo.spellInset,
        right: _Geo.spellInset,
        top: _lurePromptTop(geo),
        height: _Geo.promptH,
        child: IgnorePointer(
          child: SpellPrompt(
            label: 'IT SAYS',
            meaning: wave.sentence.meaning,
            labelStyle: _pixel(7, const Color(0xFF7A4E2D)),
            meaningStyle: _pixel(12, _BossTrialScreenState._ink,
                localeCode: _nativeCode),
          ),
        ),
      ),
      Positioned(
        left: 12,
        right: 12,
        top: _lureBoardTop(geo),
        height: _lureBoardH,
        child: IgnorePointer(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: geo.w - 24),
                child: LureBoard(
                  words: wave.sentence.tokens,
                  gap: wave.gap,
                  style: wordStyle,
                  state: round.hooked
                      ? LureGap.hooked
                      : round.missed
                          ? LureGap.missed
                          : LureGap.waiting,
                  light: 1 - round.dim,
                  textDirection: _languageCode == 'ar'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                ),
              ),
            ),
          ),
        ),
      ),
    ];
    for (var i = 0; i < wave.fish.length; i++) {
      if (round.fled.contains(i) && !(flashing && round.flashing == i)) {
        continue;
      }
      // A hooked fish stays where it was caught, until the pet nips it; once
      // the light is out only the one it needed is left, lit.
      if (round.hooked && i != wave.answer) continue;
      if (round.nipped) continue;
      if (round.missed && i != wave.answer) continue;
      pieces.add(Positioned.fromRect(
        rect: _fishRect(geo, round, i),
        child: WordFish(
          label: wave.fish[i],
          style: wordStyle,
          facingRight: _fishFacingRight(round, i),
          state: flashing && round.flashing == i
              ? FishState.wrong
              : round.hooked || round.missed
                  ? FishState.right
                  : FishState.plain,
          onTapDown: () => _tapFish(i),
        ),
      ));
    }
    return pieces;
  }
}

// ---- Bubbles ----------------------------------------------------------------

class _BubbleRound {
  _BubbleRound(this.wave, {required this.gulpSeconds, required Random rng})
      : cast = SpellCast(wave.spell),
        jitter = [for (final _ in wave.bubbles) rng.nextDouble() * 0.12];

  final BubbleWave wave;
  final SpellCast cast;
  final double gulpSeconds;

  /// A little of each bubble's own, so no two rise in step.
  final List<double> jitter;

  /// How close it is to gulping: 0 to 1.
  double gulp = 0;

  /// Seconds since the bubbles came up.
  double t = 0;

  /// The bubble just refused, and when.
  int? flashing;
  double flashAt = -1;

  /// It gulped: the spell line shows the word it wanted.
  bool gulped = false;

  /// Bubbles the pet has been sent up for: each stops where it was picked,
  /// swelling, until [bursts] — [t], when the pet's head gets there.
  final Map<int, ({Rect rect, double since, double bursts})> held = {};

  bool get done => cast.isComplete;

  /// Seconds for a bubble to rise from the seabed to the top of the water.
  static const double rise = 6;
}

extension _BubblesFlow on _BossTrialScreenState {
  void _beginBubbles() {
    final wave =
        BubbleWave.build(_pool, previous: _lastPrompt, random: _rng);
    if (wave == null) {
      _throwWave();
      return;
    }
    _refresh(() {
      // Fixed when it breathes out, so the gulp never speeds up mid-word.
      _bubbles = _BubbleRound(
        wave,
        gulpSeconds: _BossTrialScreenState._secs(AnglerRules.gulpTime(
          letters: wave.letters.length,
          patience: _clockPatience,
        )),
        rng: _rng,
      );
      _lastPrompt = wave.word;
      _stage = _Stage.jumping;
      _stageTime = 0;
      _startMove();
      _shouting = false;
    });
  }

  /// It arrives, and the bubbles come up off the seabed.
  void _openBubbles(_Geo geo) {
    _refresh(() {
      _stage = _Stage.bubbling;
      _stageTime = 0;
      _bubbles?.t = 0;
    });
    _landingShock(geo);
  }

  void _stepBubbles(double dt, _Geo geo) {
    final round = _bubbles;
    if (round == null || round.done || round.gulped) return;
    round.gulp = min(1.0, round.gulp + dt / round.gulpSeconds);
    if (round.gulp < 1) return;

    _refresh(() {
      round.gulped = true;
      _run = _run.struck(round.wave.word);
      _holdAftermath = true;
      _stage = _Stage.resolving;
      _stageTime = 0;
      _cackleTime = 0;
    });
    _strikePet(geo);
    if (_run.isOver) _endIn = 0.8;
  }

  void _tapBubble(int index) {
    final round = _bubbles;
    final geo = _geo;
    if (_phase != _Phase.playing ||
        _stage != _Stage.bubbling ||
        round == null ||
        geo == null) {
      return;
    }
    final at = _bubbleRect(geo, round, index).center;
    switch (round.cast.tap(index)) {
      case SpellTap.ignored:
        return;
      case SpellTap.fizzle:
        HapticFeedback.lightImpact();
        _refresh(() {
          round.flashing = index;
          round.flashAt = round.t;
          round.gulp = min(0.97, round.gulp + AnglerRules.bubbleMistakeGulp);
          _run = _run.fizzle();
        });
        if (!_reduceMotion) {
          _particles.sparks(at, count: 8, fizzle: true);
          _cringeAt(at);
        }
        _pop('wrong', _BossTrialScreenState._hurtRed, at.translate(0, -34));
      case SpellTap.placed:
        HapticFeedback.selectionClick();
        if (_reduceMotion) {
          _refresh();
          return;
        }
        // The pet swims up to the bubble; it stops where it was picked and
        // bursts as the pet's nose touches it.
        final nose = _swimToBubble(geo, at);
        round.held[index] = (
          rect: _bubbleRect(geo, round, index),
          since: round.t,
          bursts: round.t + nose,
        );
        _refresh();
      case SpellTap.complete:
        HapticFeedback.selectionClick();
        final earliness = 1 - round.gulp;
        _refresh(() {
          _stage = _Stage.resolving;
          _stageTime = 0;
        });
        if (!_reduceMotion) {
          // Whatever the pet was still leaping for bursts now; this one too.
          for (final held in round.held.values) {
            _particles.sparks(held.rect.center,
                count: 10, colors: AnglerPalette.bubbles);
          }
          round.held.clear();
          _particles.sparks(at, count: 10, colors: AnglerPalette.bubbles);
        }
        // The whole word spelt, the pet rears back and casts it.
        _castWhole(
          geo,
          earliness,
          Offset(geo.w / 2, _bubbleLineTop(geo)),
        );
    }
  }

  // ---- layout ----

  double _gulpTop(_Geo geo) => geo.chargeTop;
  double _bubblePromptTop(_Geo geo) => _gulpTop(geo) + _Geo.chargeH + 8;

  /// The water the bubbles rise through: from the seabed up to the prompt.
  double _waterTop(_Geo geo) => _bubblePromptTop(geo) + _Geo.promptH + 8;
  double _waterBottom(_Geo geo) => geo.groundTop - 4;

  /// The spelled word, in the seabed under the pet's feet.
  double _bubbleLineTop(_Geo geo) =>
      min(geo.groundTop + 22, geo.h - _Geo.spellLineH - 2);

  static const double _bubbleSize = 52;

  /// Bubble [index]'s box, [round.t] into the rise.
  ///
  /// The bubbles take columns across the water, two to a column half a rise
  /// apart, so none ever overlaps another; each wraps back to the seabed
  /// when it reaches the top.
  Rect _bubbleRect(_Geo geo, _BubbleRound round, int index) {
    final n = round.wave.bubbles.length;
    final columns = (n / 2).ceil();
    final column = index % columns;
    final second = index ~/ columns;
    final colW = (geo.w - 16) / columns;
    final top = _waterTop(geo);
    final span = max(1.0, _waterBottom(geo) - _bubbleSize - top);
    final k = (round.t / _BubbleRound.rise +
            second * 0.5 +
            column * 0.17 +
            round.jitter[index]) %
        1.0;
    final wobble = sin(round.t * 2.2 + index * 1.7) * 4;
    final left = 8 + colW * (column + 0.5) - _bubbleSize / 2 + wobble;
    return Rect.fromLTWH(
      left.roundToDouble(),
      (top + span * (1 - k)).roundToDouble(),
      _bubbleSize,
      _bubbleSize,
    );
  }

  List<Widget> _buildBubbles(_Geo geo, _BubbleRound round) {
    if (_stage == _Stage.jumping) return const [];
    final wave = round.wave;
    final letterStyle =
        _pixel(14, _BossTrialScreenState._ink, localeCode: _languageCode);
    final flashing =
        round.flashing != null && round.t - round.flashAt < 0.3;
    final placed = round.cast.placed;
    final shown = round.gulped ? wave.letters : [
      for (final i in placed) wave.bubbles[i],
    ];
    return [
      Positioned(
        left: ((geo.w - geo.chargeW) / 2).roundToDouble(),
        top: _gulpTop(geo),
        width: geo.chargeW,
        height: _Geo.chargeH,
        child: ChargeBar(charge: round.gulp, color: AnglerPalette.seafoam),
      ),
      Positioned(
        left: _Geo.spellInset,
        right: _Geo.spellInset,
        top: _bubblePromptTop(geo),
        height: _Geo.promptH,
        child: IgnorePointer(
          child: SpellPrompt(
            label: 'SPELL IT IN ITS LANGUAGE',
            meaning: wave.word.meaning,
            labelStyle: _pixel(7, const Color(0xFF7A4E2D)),
            meaningStyle: _pixel(12, _BossTrialScreenState._ink,
                localeCode: _nativeCode),
          ),
        ),
      ),
      if (!round.done && !round.gulped)
        for (var i = 0; i < wave.bubbles.length; i++)
          if (round.held[i] case final held?)
            // Stopped where it was picked, swelling as the pet comes for it.
            Positioned.fromRect(
              rect: held.rect,
              child: Transform.scale(
                scale: 1 +
                    0.25 *
                        ((round.t - held.since) / (held.bursts - held.since))
                            .clamp(0.0, 1.0),
                child: LetterBubble(
                  label: wave.bubbles[i],
                  style: letterStyle,
                  onTapDown: null,
                ),
              ),
            )
          else if (!placed.contains(i))
            Positioned.fromRect(
              rect: _bubbleRect(geo, round, i),
              child: LetterBubble(
                label: wave.bubbles[i],
                style: letterStyle,
                flashing: flashing && round.flashing == i,
                onTapDown: () => _tapBubble(i),
              ),
            ),
      Positioned(
        left: _Geo.spellInset,
        right: _Geo.spellInset,
        top: _bubbleLineTop(geo),
        height: _Geo.spellLineH,
        child: IgnorePointer(
          child: Center(
            child: SpellLine(
              slots: wave.letters.length,
              filled: shown,
              style: _pixel(12, DebrisPalette.runeLight,
                  localeCode: _languageCode),
              glow: round.done,
              textDirection:
                  _languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            ),
          ),
        ),
      ),
    ];
  }
}

// ---- Shoal -------------------------------------------------------------------

class _ShoalRound {
  _ShoalRound(this.wave, {required this.gulpSeconds, required Random rng})
      : phases = [
          for (var i = 0; i < wave.fish.length; i++) rng.nextDouble() * 2 * pi
        ];

  final ShoalWave wave;
  final double gulpSeconds;
  final List<double> phases;

  double gulp = 0;
  double t = 0;

  /// Fish scared off: they belonged.
  final Set<int> fled = {};
  int? flashing;
  double flashAt = -1;

  bool found = false;
  bool gulped = false;
  double? stoppedAt;

  /// The stray once it is picked: a shot with nothing in the air, because the
  /// fish is the shot. Hit by the pet, it swims at the boss and rams it, drawn
  /// from the shot's own clock so it arrives as the damage lands.
  _Shot? rammer;

  static const List<double> speeds = [0.7, 1.05, 0.55, 0.9, 0.65];
}

/// The stray rebounding off the belly it rammed: back the way it came, kicked
/// up a little, spinning, and falling under its own weight as it fades.
class _FishBounce {
  _FishBounce({
    required this.label,
    required this.at,
    required this.size,
    required this.right,
    required this.tilt,
    required this.off,
  });

  final String label;

  /// Where it hit, and how it was drawn there.
  final Offset at;
  final Size size;
  final bool right;
  final double tilt;

  /// How fast it comes off the belly, in pixels a second.
  final Offset off;

  /// Seconds since it hit.
  double t = 0;

  static const double seconds = 0.8;
  static const double gravity = 900;

  /// Whole turns it spins through on the way.
  static const double turns = 2.5;
}

extension _ShoalFlow on _BossTrialScreenState {
  void _beginShoal() {
    final wave = ShoalWave.build(_enTr?.categories ?? const {},
        previous: _lastAs<TrialWord>(), random: _rng);
    if (wave == null) {
      _throwWave();
      return;
    }
    _refresh(() {
      _shoal = _ShoalRound(
        wave,
        gulpSeconds:
            _BossTrialScreenState._secs(AnglerRules.shoalTime(_clockPatience)),
        rng: _rng,
      );
      _lastAsked = wave.strayWord;
      _stage = _Stage.jumping;
      _stageTime = 0;
      _startMove();
      _shouting = false;
    });
  }

  void _openShoal(_Geo geo) {
    _refresh(() {
      _stage = _Stage.shoaling;
      _stageTime = 0;
      _shoal?.t = 0;
    });
    _landingShock(geo);
  }

  void _stepShoal(double dt, _Geo geo) {
    final round = _shoal;
    if (round == null || round.found || round.gulped) return;
    round.gulp = min(1.0, round.gulp + dt / round.gulpSeconds);
    if (round.gulp < 1) return;
    _refresh(() {
      round.gulped = true;
      round.stoppedAt = round.t;
      _run = _run.struck(round.wave.strayWord);
      _holdAftermath = true;
      _stage = _Stage.resolving;
      _stageTime = 0;
      _cackleTime = 0;
    });
    _strikePet(geo);
    if (_run.isOver) _endIn = 0.8;
  }

  void _tapShoalFish(int fish) {
    final round = _shoal;
    final geo = _geo;
    if (_phase != _Phase.playing ||
        _stage != _Stage.shoaling ||
        round == null ||
        geo == null ||
        round.found ||
        round.fled.contains(fish)) {
      return;
    }
    final rect = _shoalRect(geo, round, fish);
    final at = rect.center;
    if (fish != round.wave.stray) {
      HapticFeedback.lightImpact();
      _refresh(() {
        round.fled.add(fish);
        round.flashing = fish;
        round.flashAt = round.t;
        round.gulp = min(0.97, round.gulp + AnglerRules.shoalMistakeGulp);
        _run = _run.fizzle();
      });
      if (!_reduceMotion) {
        _particles.sparks(at, count: 10, colors: AnglerPalette.bubbles);
        _cringeAt(at);
      }
      _pop('it belongs', _BossTrialScreenState._hurtRed, at.translate(0, -30));
      return;
    }
    HapticFeedback.selectionClick();
    final earliness = 1 - round.gulp;
    _refresh(() {
      round.found = true;
      round.stoppedAt = round.t;
      _stage = _Stage.resolving;
      _stageTime = 0;
    });
    // The pet darts at it and hits it; it swims at the boss and rams it.
    _dartAndShove(
      geo,
      rect,
      earliness,
      label: round.wave.fish[fish].target,
      onLaunch: (rammer) => _refresh(() => round.rammer = rammer),
    );
  }

  double _shoalTop(_Geo geo) => geo.chargeTop + _Geo.chargeH + 8;

  Rect _shoalRect(_Geo geo, _ShoalRound round, int fish) {
    final t = round.stoppedAt ?? round.t;
    final size = _fishSize(geo);
    final bandH =
        (geo.groundTop - 4 - _shoalTop(geo)) / round.wave.fish.length;
    final reach = max(0.0, (geo.w - size.width) / 2 - 6);
    final speed = _ShoalRound.speeds[fish % _ShoalRound.speeds.length];
    final centre = Offset(
      (geo.w / 2 + reach * sin(speed * t + round.phases[fish]))
          .roundToDouble(),
      (_shoalTop(geo) + bandH * (fish + 0.5) + sin(t * 2.4 + fish) * 2)
          .roundToDouble(),
    );
    return Rect.fromCenter(
        center: centre,
        width: size.width,
        height: min(size.height, bandH - 4));
  }

  List<Widget> _buildShoal(_Geo geo, _ShoalRound round) {
    if (_stage == _Stage.jumping) return const [];
    final style =
        _pixel(11, _BossTrialScreenState._ink, localeCode: _languageCode);
    final wave = round.wave;
    final pieces = <Widget>[
      Positioned(
        left: ((geo.w - geo.chargeW) / 2).roundToDouble(),
        top: geo.chargeTop,
        width: geo.chargeW,
        height: _Geo.chargeH,
        child: ChargeBar(charge: round.gulp, color: AnglerPalette.seafoam),
      ),
    ];
    for (var i = 0; i < wave.fish.length; i++) {
      final flashing = round.flashing == i && round.t - round.flashAt < 0.3;
      if (round.fled.contains(i) && !flashing) continue;
      if ((round.found || round.gulped) && i != wave.stray) continue;
      final t = round.stoppedAt ?? round.t;
      final speed = _ShoalRound.speeds[i % _ShoalRound.speeds.length];
      var rect = _shoalRect(geo, round, i);
      var facingRight = cos(speed * t + round.phases[i]) >= 0;
      var tilt = 0.0;
      // The stray the pet has hit swims at the boss, nose first, faster and
      // faster. It is held where it was till then; once it has rammed the boss
      // the bounce has it.
      final rammer = i == wave.stray ? round.rammer : null;
      if (rammer != null) {
        if (!_shots.contains(rammer)) continue;
        final swum = rammer.t - rammer.delay;
        if (swum > 0) {
          final pose = _strayPose(rect.center, _bossHitPoint(geo), rect.size,
              swum / rammer.seconds!);
          rect = Rect.fromCenter(
              center: pose.at, width: rect.width, height: rect.height);
          facingRight = pose.right;
          tilt = pose.tilt;
        }
      }
      Widget fish = WordFish(
        label: wave.fish[i].target,
        style: style,
        facingRight: facingRight,
        state: flashing
            ? FishState.wrong
            : round.found || round.gulped
                ? FishState.right
                : FishState.plain,
        onTapDown: () => _tapShoalFish(i),
      );
      if (tilt != 0) fish = Transform.rotate(angle: tilt, child: fish);
      pieces.add(Positioned.fromRect(rect: rect, child: fish));
    }
    return pieces;
  }
}

// ---- Net --------------------------------------------------------------------

class _NetRound extends _ClockRound {
  _NetRound(this.wave, double seconds, Random rng)
      : play = NetPlay(wave),
        phases = [
          for (var i = 0; i < wave.fish.length; i++) rng.nextDouble() * 2 * pi
        ],
        super(seconds);
  final NetWave wave;
  final NetPlay play;
  final List<double> phases;

  /// The fish most recently netted, which the pet turns to.
  int? last;

  /// The nets the pet has thrown: over which fish, when ([t]) and from where.
  final List<({int fish, double since, Offset from})> casts = [];

  /// Seconds since the pet began to haul the whole net in, once every fish is
  /// netted; and whether the haul is done and the fish have burst.
  double? hauling;
  bool hauled = false;
}

extension _NetFlow on _BossTrialScreenState {
  void _beginNet() {
    final wave = NetWave.build(_sentences,
        previous: _lastAs<TrialSentence>(), random: _rng);
    if (wave == null) {
      _throwWave();
      return;
    }
    _beginClockRound(() {
      _net = _NetRound(
        wave,
        _BossTrialScreenState._secs(AnglerRules.netTime(
            fish: wave.fish.length, patience: _clockPatience)),
        _rng,
      );
      _lastAsked = wave.sentence;
    });
  }

  double _netTop(_Geo geo) => geo.chargeTop + _Geo.promptH + 8 + _Geo.chargeH + 8;

  /// Fish [i]: two columns of them, each swimming its half of the water.
  Rect _netFishRect(_Geo geo, _NetRound round, int i) {
    final n = round.wave.fish.length;
    final perColumn = (n / 2).ceil();
    final column = i % 2, band = i ~/ 2;
    final bandH = (geo.groundTop - 4 - _netTop(geo)) / perColumn;
    final w = min(150.0, (geo.w / 2 - 12).floorToDouble());
    final h = min(40.0, bandH - 6).floorToDouble();
    final half = geo.w / 2;
    final reach = max(0.0, (half - w) / 2 - 4);
    final netted = round.play.isNetted(i);
    final t = round.t;
    final x = column * half +
        half / 2 +
        (netted ? 0 : reach * sin(t * (0.7 + 0.15 * band) + round.phases[i]));
    final y = _netTop(geo) + bandH * (band + 0.5);
    return Rect.fromCenter(
        center: Offset(x.roundToDouble(), y.roundToDouble()),
        width: w,
        height: h);
  }

  void _tapNetFish(int i) {
    final round = _net;
    final geo = _geo;
    if (_phase != _Phase.playing ||
        _stage != _Stage.netting ||
        round == null ||
        geo == null ||
        round.over) {
      return;
    }
    final rect = _netFishRect(geo, round, i);
    final at = rect.center;
    switch (round.play.tap(i)) {
      case NetTap.ignored:
        return;
      case NetTap.stray:
        _refused(geo, round, i, AnglerRules.netMistakeGulp, at,
            said: 'not in it');
        if (!_reduceMotion) _cringeAt(at);
      case NetTap.netted:
        HapticFeedback.selectionClick();
        round.last = i;
        _refresh();
        // The pet leaps and casts a net over it.
        if (!_reduceMotion) _castNet(geo, round, i, rect);
      case NetTap.done:
        HapticFeedback.selectionClick();
        round.last = i;
        final earliness = 1 - round.clock;
        _refresh(() {
          round.won = true;
          _stage = _Stage.resolving;
          _stageTime = 0;
        });
        if (_reduceMotion) {
          round.hauled = true;
          _castWhole(geo, earliness, at);
        } else {
          // The last net cast, the pet leans back and hauls the lot in.
          _castNet(geo, round, i, rect, earliness: earliness);
        }
    }
  }

  /// Seconds a thrown net takes to open out and settle over its fish.
  static const double _netFlight = 0.4;

  /// How far the net has been hauled in, 0 to 1, [haul] seconds into it: three
  /// jerks, the cords snapping taut each time.
  static double _hauledBy(double haul) {
    double jerk(double a, double b) => _smooth((haul - a) / (b - a));
    return jerk(0.36, 0.48) * 0.34 +
        jerk(0.58, 0.70) * 0.34 +
        jerk(0.80, 0.94) * 0.32;
  }

  /// A net thrown over [fish]: the pet LEAPS, arm back and stretched, swings
  /// the net out over it at the top and falls crouched; the net opens in the
  /// air and settles over the fish. With an [earliness] it is the last fish, and
  /// the pet then LEANS BACK to haul the whole net in: it digs in, tugs three
  /// times — the cords snapping taut, the fish dragged to it — and heaves; the
  /// fish burst and the spell leaves the pet.
  void _castNet(_Geo geo, _NetRound round, int fish, Rect rect,
      {double? earliness}) {
    final dx = rect.center.dx - _petX;
    final dir = dx.abs() < 12 ? _bossSide(geo, _petX) : dx.sign;
    final toward = _bossSide(geo, _petX);
    final k = _Keyer();
    k.to(0.07, squash: 0.82, tilt: -0.3 * dir);
    k.to(0.2,
        dy: 56, dx: dir * 8, squash: 1.1, tilt: -0.45 * dir, ease: _Ease.out);
    final throwAt = k.t + 0.04;
    k.to(0.09, tilt: 0.5 * dir, squash: 1.0, ease: _Ease.out);
    k.to(0.28, dy: 0, dx: 0, tilt: 0, squash: 0.88, ease: _Ease.accelerate);
    k.to(0.1, squash: 1.0);
    // The net leaves its hands at the top of the leap. Booked on the round now,
    // by the clock, so a second fish tapped on the heels of this one cannot
    // take the throw with it.
    final from = Offset(_petX + dir * 22, geo.groundTop - geo.petBox * 0.8 - 56);
    round.casts.add((fish: fish, since: round.t + throwAt, from: from));
    final events = <_MoveEvent>[
      _MoveEvent(throwAt,
          (geo) => _particles.sparks(from, count: 5, colors: AnglerPalette.bubbles)),
    ];
    if (earliness != null) {
      final haul0 = k.t;
      // Leans back, digs in, shivering...
      k.to(0.2, tilt: -toward * 0.45, squash: 0.9);
      for (var i = 0; i < 4; i++) {
        k.to(0.04, dx: i.isEven ? 2 : -2, ease: _Ease.linear);
      }
      k.to(0.0001, dx: 0);
      // ...and tugs: back hard, then slack, three times; the last the hardest.
      for (final (pull, lean) in const [(0.6, 0.42), (0.64, 0.42), (0.7, 0.5)]) {
        k.to(0.12, tilt: -toward * pull, dx: -toward * 5, ease: _Ease.out);
        k.to(0.1, tilt: -toward * lean, dx: 0);
      }
      k.to(0.1, tilt: toward * 0.4, squash: 1.1, dx: toward * 4, ease: _Ease.out);
      final release = k.t;
      k.to(0.25, tilt: 0, squash: 1.0, dx: 0);
      events
        ..add(_MoveEvent(haul0, (geo) {
          _petFacesLeft = toward < 0;
          _refresh(() => round.hauling = 0);
        }))
        ..add(_MoveEvent(release, (geo) {
          _refresh(() => round.hauled = true);
          _shake = max(_shake, 0.15);
          for (var f = 0; f < round.wave.fish.length; f++) {
            if (round.play.isNetted(f)) {
              _particles.sparks(_hauledAt(geo, round, f),
                  count: 8, colors: AnglerPalette.bubbles);
            }
          }
        }));
      _shots.add(_Shot(
        from: _throwFrom(geo, _petX, toward),
        earliness: earliness,
        whole: true,
        look: _ShotLook.spell,
        delay: release,
      ));
    }
    _stayPut(k.t + 0.3);
    _playMove(_PetMove.keys(k.keys, faceLeft: dir < 0, events: events));
  }

  /// Where a netted fish is as the net is hauled in: from where it was netted
  /// toward the pet's hands, by the jerks of the haul.
  Offset _hauledAt(_Geo geo, _NetRound round, int fish) {
    final from = _netFishRect(geo, round, fish).center;
    final haul = round.hauling;
    if (haul == null) return from;
    final to = _throwFrom(geo, _petX, _bossSide(geo, _petX));
    return Offset.lerp(from, to, _hauledBy(haul))!;
  }

  List<Widget> _buildNet(_Geo geo, _NetRound round) {
    if (_stage == _Stage.jumping) return const [];
    final wave = round.wave;
    final style =
        _pixel(10, _BossTrialScreenState._ink, localeCode: _languageCode);
    final pieces = <Widget>[
      Positioned(
        left: _Geo.spellInset,
        right: _Geo.spellInset,
        top: geo.chargeTop,
        height: _Geo.promptH,
        child: IgnorePointer(
          child: SpellPrompt(
            label: 'NET EVERY WORD OF IT · '
                '${round.play.netted} OF ${wave.toNet}',
            meaning: wave.sentence.meaning,
            labelStyle: _pixel(7, const Color(0xFF7A4E2D)),
            meaningStyle: _pixel(12, _BossTrialScreenState._ink,
                localeCode: _nativeCode),
          ),
        ),
      ),
      Positioned(
        left: ((geo.w - geo.chargeW) / 2).roundToDouble(),
        top: geo.chargeTop + _Geo.promptH + 8,
        width: geo.chargeW,
        height: _Geo.chargeH,
        child: ChargeBar(charge: round.clock),
      ),
    ];
    final ropes = <Offset>[];
    final nets = <Widget>[];
    for (var i = 0; i < wave.fish.length; i++) {
      final flashing = round.isFlashing(i);
      if (round.play.hasFled(i) && !flashing) continue;
      // Once it is over only the sentence's own fish are left: netted, or
      // shown for what they were; and hauled in, they burst.
      if (round.over && !wave.fish[i].$2) continue;
      if (round.hauled) continue;
      final netted = round.play.isNetted(i);
      final size = _netFishRect(geo, round, i).size;
      final centre = _hauledAt(geo, round, i);
      final rect = Rect.fromCenter(
        center: Offset(centre.dx.roundToDouble(), centre.dy.roundToDouble()),
        width: size.width,
        height: size.height,
      );
      // The net thrown over it opens in the air on its way, then lies on it —
      // pulled taut once the pet is hauling.
      final cast = round.casts.where((c) => c.fish == i).firstOrNull;
      final flown = cast == null
          ? 1.0
          : ((round.t - cast.since) / _netFlight).clamp(0.0, 1.0);
      if (netted && cast != null && flown < 1) {
        // Until it is thrown the fish is just a fish the pet is leaping at.
        if (round.t >= cast.since) {
          final at = Offset.lerp(cast.from, rect.center, _smooth(flown))!
              .translate(0, -sin(flown * pi) * 46);
          nets.add(Positioned.fromRect(
            rect: Rect.fromCenter(
              center: Offset(at.dx.roundToDouble(), at.dy.roundToDouble()),
              width: size.width + 16,
              height: size.height + 16,
            ),
            child: IgnorePointer(child: NetMesh(grow: flown)),
          ));
        }
      } else if (netted) {
        nets.add(Positioned.fromRect(
          rect: rect.inflate(8),
          child: IgnorePointer(
            child: NetMesh(slack: round.hauling == null ? 1 : 0),
          ),
        ));
        if (round.hauling != null) ropes.add(rect.center);
      }
      pieces.add(Positioned.fromRect(
        rect: rect,
        child: WordFish(
          label: wave.fish[i].$1,
          style: style,
          facingRight: i.isEven,
          state: flashing
              ? FishState.wrong
              : (netted && flown >= 1) || round.over
                  ? FishState.right
                  : FishState.plain,
          onTapDown: () => _tapNetFish(i),
        ),
      ));
    }
    pieces.addAll(nets);
    if (ropes.isNotEmpty) {
      // The cords from the pet's hands to the fish it is hauling in.
      pieces.add(Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: NetRopesPainter(
              hands: _throwFrom(geo, _petX, _bossSide(geo, _petX)),
              fish: ropes,
            ),
          ),
        ),
      ));
    }
    return pieces;
  }
}

// ---- both -------------------------------------------------------------------

extension _LanternmawFlow on _BossTrialScreenState {
  /// The lure's fish found: the pet DASHES along the seabed to under it, low
  /// and stretched, bubbles streaming behind; crouches, lunges up and NIPS it —
  /// the fish is gone in a gulp — then turns to the boss, rears and SPITS the
  /// spell at it from its mouth, and trots home.
  void _dashNipSpit(_Geo geo, Rect fish, double earliness,
      {required void Function() onNip}) {
    if (_reduceMotion) {
      onNip();
      _shoot(
        geo,
        _Shot(
          from: fish.center,
          earliness: earliness,
          whole: true,
          look: _ShotLook.spell,
        ),
      );
      return;
    }
    final half = geo.petBox / 2;
    final toX = fish.center.dx.clamp(half, geo.w - half).toDouble();
    final dash = toX - _petX;
    final dir = dash.abs() < 12 ? _bossSide(geo, _petX) : dash.sign;
    final toward = _bossSide(geo, toX);
    // How far up its head must go to get into the fish's belly.
    final up = _reachTo(
      geo,
      _withinLeap(geo, Offset(toX, fish.bottom - _headInto),
          most: geo.petBox * 2),
    ).dy;
    final k = _Keyer();
    k.to((0.14 + dash.abs() / 1400).clamp(0.14, 0.34),
        dx: dash, tilt: 0.3 * dir, squash: 0.88, ease: _Ease.out);
    k.to(0.07, tilt: 0.05 * dir, squash: 0.78);
    k.to(0.12 + up / 1500,
        dy: up, tilt: 0.45 * dir, squash: 1.12, ease: _Ease.out);
    final nip = k.t;
    k.to(0.05, squash: 1.0, ease: _Ease.linear);
    k.to(0.16, dy: 0, tilt: 0, squash: 0.85, ease: _Ease.accelerate);
    final turn = k.t;
    k.to(0.12, tilt: -toward * 0.22, squash: 0.92);
    k.to(0.1, tilt: toward * 0.32, squash: 1.06, ease: _Ease.out);
    final spit = k.t;
    k.to(0.2, tilt: 0, squash: 1.0);
    final home = k.t;
    // Trots home in three small hops.
    for (var i = 1; i <= 3; i++) {
      k.to(0.075,
          dx: dash * (1 - (i - 0.5) / 3),
          dy: 8,
          tilt: -0.12 * dir,
          ease: _Ease.out);
      k.to(0.075, dx: dash * (1 - i / 3), dy: 0, tilt: 0, ease: _Ease.accelerate);
    }

    final mouth = _throwFrom(geo, toX, toward);
    _shots.add(_Shot(
      from: mouth,
      earliness: earliness,
      whole: true,
      look: _ShotLook.spell,
      delay: spit,
    ));
    _stayPut(k.t + 0.3);
    _particles.sparks(Offset(_petX, geo.groundTop - 6),
        count: 8, colors: AnglerPalette.bubbles);
    _playMove(_PetMove.keys(
      k.keys,
      faceLeft: dir < 0,
      events: [
        _MoveEvent(nip, (geo) {
          _refresh(onNip);
          _particles.sparks(fish.center,
              count: 10, colors: AnglerPalette.bubbles);
        }),
        _MoveEvent(turn, (geo) => _petFacesLeft = toward < 0),
        _MoveEvent(spit, (geo) => _particles.sparks(mouth,
            count: 6, colors: AnglerPalette.bubbles)),
        _MoveEvent(home, (geo) => _petFacesLeft = dir > 0),
      ],
    ));
  }

  /// The pet SWIMS up to a letter's bubble: no crouch, no spring — it leaves
  /// the seabed and glides there in paddling strokes, tipping a little each
  /// way, and noses the bubble; then it sinks slowly back down. Returns the
  /// seconds until its nose is on it.
  double _swimToBubble(_Geo geo, Offset bubble) {
    final half = geo.petBox / 2;
    final toX = bubble.dx.clamp(half, geo.w - half).toDouble();
    final dx = toX - _petX;
    final dir = dx.abs() < 12 ? _bossSide(geo, _petX) : dx.sign;
    // Up to the bubble's underside, its nose under it.
    final up = _reachTo(
      geo,
      _withinLeap(
        geo,
        Offset(toX, bubble.dy + _BubblesFlow._bubbleSize / 2 - 4),
        most: geo.petBox * 2.6,
      ),
    ).dy;
    final swim = 0.42 + sqrt(dx * dx + up * up) / 650;
    final strokes = max(2, (swim / 0.15).round());
    final k = _Keyer();
    for (var i = 1; i <= strokes; i++) {
      final p = _smooth(i / strokes);
      k.to(swim / strokes,
          dx: dx * p,
          dy: up * p,
          tilt: (i.isOdd ? 0.13 : -0.13) * dir,
          ease: _Ease.linear);
    }
    k.to(0.09, dx: dx + 10 * dir, tilt: 0.28 * dir, ease: _Ease.out);
    final nose = k.t;
    k.to(0.12, dx: dx, tilt: 0);
    k.to(0.45, dx: dx * 0.45, dy: up * 0.5, tilt: -0.1 * dir);
    k.to(0.45, dx: 0, dy: 0, tilt: 0);
    _stayPut(k.t + 0.3);
    _particles.sparks(Offset(_petX, geo.groundTop - 8),
        count: 5, colors: AnglerPalette.bubbles);
    _playMove(_PetMove.keys(k.keys, faceLeft: dir < 0));
    return nose;
  }

  /// The odd fish found: the pet DARTS at it in a straight line, stretched and
  /// tipped along it, and HITS it out of the school with its whole body — and
  /// is knocked back by it, and drifts home, sinking. The fish, hit, SWIMS at
  /// the boss, faster and faster, and RAMS it: that is the attack, landing as
  /// it arrives. It rebounds off the belly spinning ([_fishRams]). [onLaunch]
  /// is given the shot that is the fish, to draw it by.
  void _dartAndShove(_Geo geo, Rect fish, double earliness,
      {required String label, required void Function(_Shot rammer) onLaunch}) {
    if (_reduceMotion) {
      final rammer = _Shot(
        from: fish.center,
        earliness: earliness,
        whole: true,
        look: _ShotLook.fish,
      );
      onLaunch(rammer);
      _shoot(geo, rammer);
      return;
    }
    final half = geo.petBox / 2;
    final toX = fish.center.dx.clamp(half, geo.w - half).toDouble();
    final dx = toX - _petX;
    final dir = dx.abs() < 12 ? _bossSide(geo, _petX) : dx.sign;
    final up = _reachTo(
      geo,
      _withinLeap(geo, Offset(toX, fish.bottom - _headInto),
          most: geo.petBox * 2.6),
    ).dy;
    // Tipped along the line it darts on: head first.
    final aim = (atan2(dx.abs(), max(up, 20.0)) * dir).clamp(-1.0, 1.0);
    final k = _Keyer();
    k.to(0.07, tilt: -aim * 0.3, squash: 0.8);
    k.to(0.14 + sqrt(dx * dx + up * up) / 2500,
        dx: dx, dy: up, tilt: aim.toDouble(), squash: 1.15, ease: _Ease.linear);
    final hit = k.t;
    k.to(0.05, tilt: aim * 1.1, squash: 0.78, ease: _Ease.out);
    k.to(0.2,
        dx: dx - dir * 22,
        dy: max(0.0, up - 16),
        tilt: -aim * 0.35,
        squash: 1.0,
        ease: _Ease.out);
    k.to(0.75, dx: 0, dy: 0, tilt: 0);

    // The swim: a longer way takes longer, but never so long it drags.
    final swim = 0.32 + (_bossHitPoint(geo) - fish.center).distance / 1100;
    final rammer = _Shot(
      from: fish.center,
      earliness: earliness,
      whole: true,
      look: _ShotLook.fish,
      seconds: swim,
      delay: hit,
      onHit: (geo) => _fishRams(geo, label, fish),
    );
    _shots.add(rammer);
    onLaunch(rammer);
    _stayPut(k.t + 0.3);
    _particles.sparks(Offset(_petX, geo.groundTop - 6),
        count: 6, colors: AnglerPalette.bubbles);
    _playMove(_PetMove.keys(
      k.keys,
      faceLeft: dir < 0,
      events: [
        _MoveEvent(hit, (geo) {
          _shake = max(_shake, 0.12);
          _particles.sparks(fish.center,
              count: 12, colors: AnglerPalette.bubbles);
        }),
      ],
    ));
  }

  /// The stray [k] (0 to 1) of the way through its swim at the boss, [from]
  /// where the pet hit it to [belly], where the blow lands: it draws back a
  /// little, then speeds up, nose first and wagging, to stop with its nose on
  /// the belly. [heading] is the way it swims.
  ({Offset at, double tilt, bool right, Offset heading}) _strayPose(
      Offset from, Offset belly, Size size, double k) {
    k = k.clamp(0.0, 1.0);
    final gap = belly - from;
    final heading = gap.distance < 1 ? const Offset(0, -1) : gap / gap.distance;
    final reach = max(0.0, gap.distance - size.width * 0.4);
    final windUp = k < 0.18 ? sin(k / 0.18 * pi) * 12 : 0.0;
    final wag = sin(k * 16) * 5 * (1 - k);
    final right = heading.dx >= 0;
    // Tipped along its line, as far as its word stays readable, turning into
    // it over the first of the swim rather than snapping.
    final tilt = (right
                ? atan2(heading.dy, heading.dx)
                : atan2(-heading.dy, -heading.dx))
            .clamp(-0.9, 0.9)
            .toDouble() *
        _smooth(k / 0.2);
    return (
      at: from +
          heading * (reach * k * k - windUp) +
          Offset(-heading.dy, heading.dx) * wag,
      tilt: tilt,
      right: right,
      heading: heading,
    );
  }

  /// The stray has rammed the boss: it rebounds back the way it came, kicked
  /// up a little, spinning, and falls out of the water ([_buildFishBounce]).
  void _fishRams(_Geo geo, String label, Rect fish) {
    if (_reduceMotion) return;
    final pose = _strayPose(fish.center, _bossHitPoint(geo), fish.size, 1);
    final h = pose.heading;
    _refresh(() {
      _fishBounce = _FishBounce(
        label: label,
        at: pose.at,
        size: fish.size,
        right: pose.right,
        tilt: pose.tilt,
        off: Offset(-h.dx * 330 + (h.dx >= 0 ? -60 : 60), -h.dy * 330 - 150),
      );
    });
  }

  void _stepFishBounce(double dt) {
    final bounce = _fishBounce;
    if (bounce == null) return;
    bounce.t += dt;
    if (bounce.t >= _FishBounce.seconds) _fishBounce = null;
  }

  Widget _buildFishBounce(_Geo geo, _FishBounce bounce) {
    final k = (bounce.t / _FishBounce.seconds).clamp(0.0, 1.0);
    final at = bounce.at +
        bounce.off * bounce.t +
        Offset(0, 0.5 * _FishBounce.gravity * bounce.t * bounce.t);
    // Spinning fast off the blow, and slowing.
    final spin = (bounce.off.dx >= 0 ? 1 : -1) *
        _FishBounce.turns *
        2 *
        pi *
        (1 - (1 - k) * (1 - k));
    return Positioned.fromRect(
      rect: Rect.fromCenter(
          center: at, width: bounce.size.width, height: bounce.size.height),
      child: IgnorePointer(
        child: Opacity(
          opacity: k < 0.7 ? 1 : 1 - (k - 0.7) / 0.3,
          child: Transform.rotate(
            angle: bounce.tilt + spin,
            child: WordFish(
              label: bounce.label,
              style: _pixel(11, _BossTrialScreenState._ink,
                  localeCode: _languageCode),
              facingRight: bounce.right,
              state: FishState.right,
              onTapDown: null,
            ),
          ),
        ),
      ),
    );
  }

  /// The gulp coming: the water DRIFTS the pet toward the maw — up off the
  /// seabed and across toward the boss, its nose tipped that way, swaying — more
  /// and more the nearer the gulp is.
  ({double dx, double lift, double tilt}) _pull() {
    const none = (dx: 0.0, lift: 0.0, tilt: 0.0);
    final geo = _geo;
    if (_reduceMotion || _bubbled > 0 || geo == null) return none;
    final closing = switch (_stage) {
      _Stage.luring => _lure?.dim,
      _Stage.bubbling => _bubbles?.gulp,
      _Stage.shoaling => _shoal?.gulp,
      _Stage.netting => _net?.clock,
      _ => null,
    };
    if (closing == null || closing < 0.5) return none;
    final e = (closing - 0.5) / 0.5;
    final k = e * e;
    final toward = _bossSide(geo, _petX);
    return (
      dx: (toward * 36 * k).roundToDouble(),
      lift: ((k * 42 + sin(_time * 5) * e * 3) / 2).roundToDouble() * 2,
      tilt: toward * 0.26 * k + sin(_time * 4) * 0.03 * e,
    );
  }

  /// How far up the bubble has floated the pet: it rises as the bubble forms,
  /// then bobs. Nothing when it is in none.
  double _bubbleLift(double size) {
    if (_bubbled <= 0 || _reduceMotion) return 0;
    final since = _BossTrialScreenState._bubbleSeconds - _bubbled;
    final rises = _smooth(since / _BossTrialScreenState._bubbleForms);
    // From wherever the water had drawn it, up to its height in the bubble.
    final floats = size * 0.14 + sin(_time * 4) * 3;
    return ((_bubbleFrom + (floats - _bubbleFrom) * rises) / 2)
            .roundToDouble() *
        2;
  }

  /// How much of the bubble there is round the pet, 0 to 1: it swells from
  /// nothing as it forms.
  double _bubbleFill() {
    if (_bubbled <= 0) return 0;
    if (_reduceMotion) return 1;
    final since = _BossTrialScreenState._bubbleSeconds - _bubbled;
    return _smooth(since / _BossTrialScreenState._bubbleForms);
  }

  /// Something of Lanternmaw's got through: the pet is trapped in a bubble,
  /// which swells round it, and floats in it for a moment.
  void _trapInBubble(_Geo geo) {
    HapticFeedback.heavyImpact();
    _bubbleFrom = _pull().lift;
    _bubbled = _BossTrialScreenState._bubbleSeconds;
    _hurtTint = 0.3;
    // Whatever its body was doing stops, and a run stops where it had got to.
    _move = null;
    if (_petRunning || _petGoX != null || _petLane != null) {
      _petGoX = _petX;
      _petLane = null;
      _petAway = _BossTrialScreenState._bubbleSeconds;
    }
    if (!_reduceMotion) {
      _shake = 0.3;
      _petHurt = 0;
      _particles.sparks(
        Offset(_petX, geo.groundTop - geo.petBox * 0.45),
        count: 16,
        colors: AnglerPalette.bubbles,
      );
    }
    _pop('blub', _BossTrialScreenState._hurtRed,
        Offset(_petX, geo.groundTop - geo.petBox - 8));
  }

  /// The bubble pops: the pet falls out of it to the seabed, and gets up
  /// again with a hop. [lifted] is how far up it had floated.
  void _popBubble(_Geo geo, double lifted) {
    if (_reduceMotion) return;
    _particles.sparks(
      _petRect(geo).center.translate(0, -lifted),
      count: 14,
      colors: AnglerPalette.bubbles,
    );
    if (lifted <= 0) {
      _springUp(geo);
      return;
    }
    const fall = 0.24;
    _playMove(_PetMove(
      duration: fall,
      offsetAt: (t) {
        final k = (t / fall).clamp(0.0, 1.0);
        return Offset(0, ((lifted * (1 - k * k)) / 2).roundToDouble() * 2);
      },
      onEnd: _springUp,
    ));
  }

  void _animateAnglerRounds(double dt, _Geo geo) {
    _lure?.t += dt;
    _bubbles?.t += dt;
    _shoal?.t += dt;
    _burstHeldBubbles(geo);
    final net = _net;
    if (net != null && net.hauling != null) net.hauling = net.hauling! + dt;
  }

  /// The bubbles the pet went up for burst as its head gets there.
  void _burstHeldBubbles(_Geo geo) {
    final round = _bubbles;
    if (round == null || round.held.isEmpty) return;
    for (final index in [...round.held.keys]) {
      final held = round.held[index]!;
      if (round.t < held.bursts) continue;
      round.held.remove(index);
      if (!_reduceMotion) {
        _particles.sparks(held.rect.center,
            count: 10, colors: AnglerPalette.bubbles);
      }
    }
  }

  /// Its lantern, dimming through a lure: dark water laid over the lantern
  /// on the sprite, wherever the sprite is this frame.
  Widget? _lanternShade(_Geo geo) {
    final round = _lure;
    if (round == null || _stage == _Stage.jumping || _bossHidden) return null;
    final at = _bossOrigin(geo, _bossPose());
    final d = (geo.bossW * _BossTrialScreenState._lanternSize)
        .roundToDouble();
    return Positioned(
      left: (at.dx + geo.bossW * _BossTrialScreenState._lanternX - d / 2)
          .roundToDouble(),
      top: (at.dy + geo.bossH * _BossTrialScreenState._lanternY - d / 2)
          .roundToDouble(),
      width: d,
      height: d,
      child: IgnorePointer(child: LanternShade(dim: round.dim)),
    );
  }

  /// The lure's fish swim behind the pet: they are wide, and one passing in
  /// front would hide it whole. Nothing on the pet takes a tap, so a fish
  /// behind it can still be caught.
  List<Widget> _buildAnglerRoundsBehind(_Geo geo) => [
        if (_lanternShade(geo) case final shade?) shade,
        if (_lure case final round?) ..._buildLure(geo, round),
        if (_shoal case final round?) ..._buildShoal(geo, round),
        if (_net case final round?) ..._buildNet(geo, round),
      ];

  /// The bubbles rise in front of it: each is small and soon past, and one
  /// hidden behind it could not be read.
  List<Widget> _buildAnglerRoundsFront(_Geo geo) => [
        if (_bubbles case final round?) ..._buildBubbles(geo, round),
      ];

  void _clearAnglerRounds() {
    _lure = null;
    _bubbles = null;
    _shoal = null;
    _net = null;
  }
}
