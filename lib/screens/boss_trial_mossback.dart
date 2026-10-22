part of 'boss_trial_screen.dart';

// Mossback's openers under test beside its Catch: the Shell Game, Pebble Pop
// and Stepping Stones. The rules are in `utils/boss_trial_moss.dart`; this is
// their clock, their layout and their taps, on the screen's own game clock.

// ---- Shell Game -------------------------------------------------------------

class _ShellRound {
  _ShellRound(
    this.game, {
    required this.reveal,
    required this.swap,
    required this.pick,
  });

  final ShellGame game;

  /// Seconds the meanings show, one swap takes, and a pick waits.
  final double reveal;
  final double swap;
  final double pick;

  /// Seconds since the cups came up.
  double t = 0;

  int? picked;
  bool timedOut = false;

  /// When it was settled, by a pick or by waiting too long.
  double? settledAt;

  /// When the picked cup, and the right one, lift to show what is under them:
  /// the moment the pet lands on its pick, or at once when time ran out.
  double? revealAt;

  /// Cups rise out of the ground, then show their meanings.
  static const double rise = 0.25;

  /// The domes coming down over the slabs.
  static const double flip = 0.2;

  double get showEnd => rise + reveal;
  double get shuffleStart => showEnd + flip;
  double get shuffleEnd => shuffleStart + game.swaps.length * swap;
  double get pickEnd => shuffleEnd + pick;

  bool get settled => settledAt != null;

  /// A pick is only taken once the shuffle is over: the meanings showing are
  /// the thing to remember, not a shortcut past the shuffle.
  bool get canPick => !settled && t >= shuffleEnd;
}

extension _ShellGameFlow on _BossTrialScreenState {
  void _beginShell() {
    final game = ShellGame.build(
      _pool,
      previous: _lastPrompt,
      random: _rng,
      swaps: MossRules.swapCount(_clockPatience),
    );
    if (game == null) {
      _finish();
      return;
    }
    _refresh(() {
      // Fixed when it shouts, so the shuffle never speeds up halfway.
      _shell = _ShellRound(
        game,
        reveal:
            _BossTrialScreenState._secs(MossRules.revealTime(_clockPatience)),
        swap: _BossTrialScreenState._secs(MossRules.swapTime(_clockPatience)),
        pick: _BossTrialScreenState._secs(MossRules.pickTime),
      );
      _lastPrompt = game.prompt;
      _stage = _Stage.jumping;
      _stageTime = 0;
      _startMove();
      _shouting = false;
    });
  }

  /// The landing: the cups come up out of the moss, meanings showing.
  void _raiseShells(_Geo geo) {
    _refresh(() {
      _stage = _Stage.shelling;
      _stageTime = 0;
      _shell?.t = 0;
    });
    _landingShock(geo);
  }

  void _stepShell(_Geo geo) {
    final round = _shell;
    if (round == null || round.settled) return;
    if (round.t >= round.pickEnd) _shellTimeout(geo);
  }

  void _shellTimeout(_Geo geo) {
    final round = _shell!;
    _refresh(() {
      round.timedOut = true;
      round.settledAt = round.t;
      round.revealAt = round.t;
      _run = _run.letLand();
      _holdAftermath = true;
      _stage = _Stage.resolving;
      _stageTime = 0;
    });
    _pop('too slow', _BossTrialScreenState._muted,
        Offset(geo.w / 2, _petTop(geo) - 8));
  }

  void _tapCup(int cup) {
    final round = _shell;
    final geo = _geo;
    if (_phase != _Phase.playing ||
        _stage != _Stage.shelling ||
        round == null ||
        geo == null ||
        !round.canPick) {
      return;
    }
    final right = cup == round.game.answer;
    // Sure of it the moment the cups stop is worth the most.
    final earliness = (1 - (round.t - round.shuffleEnd) / round.pick)
        .clamp(0.0, 1.0);
    final at = _cupRect(geo, round, cup).center;
    _refresh(() {
      round.picked = cup;
      round.settledAt = round.t;
      // The cup lifts as its stone leaves it.
      round.revealAt = round.t;
      _stage = _Stage.resolving;
      _stageTime = 0;
      if (!right) _holdAftermath = true;
    });

    // The pet does not move. A right cup's stone goes at the boss...
    if (right) {
      HapticFeedback.selectionClick();
      _launch(
        geo,
        _Shot(
          from: at,
          earliness: earliness,
          whole: true,
          look: _ShotLook.rock,
        ),
      );
      return;
    }
    // ...and a wrong cup's comes down on the pet instead, which takes it.
    HapticFeedback.mediumImpact();
    _launch(
      geo,
      _Shot(
        from: at,
        to: geo.petHead(_petX).translate(0, geo.petBox * 0.2),
        earliness: 0,
        look: _ShotLook.rock,
        onLand: (geo) {
          _refresh(() => _run = _run.answerWrong(round.game.prompt));
          _wrongJolt(geo, Offset(_petX, _petTop(geo) - 8));
          if (_reduceMotion) return;
          _particles.shatter(Rect.fromCenter(
            center: geo.petHead(_petX),
            width: geo.petBox * 0.6,
            height: 30,
          ));
          _playMove(_PetMove.flatten(onEnd: _springUp));
        },
      ),
    );
  }

  /// While the cups shuffle the pet watches them, turning to whichever side
  /// the swap is on.
  void _watchShuffle(_Geo geo) {
    final round = _shell;
    if (round == null || round.settled || _move != null) return;
    final into = (round.t - round.shuffleStart) / round.swap;
    final swaps = round.game.swaps;
    if (into < 0 || into >= swaps.length) return;
    final (a, b) = swaps[into.floor()];
    // Its middle: two cups at the ends have nothing to turn to.
    final middle = geo.w * (0.2 + 0.3 * (a + b) / 2);
    _faceToward(middle, from: _petX, deadzone: 12);
  }

  // ---- layout ----

  /// The three places the cups stand in, left to right.
  Offset _cupPlace(_Geo geo, int place) {
    final y = ((geo.fallTop + _petTop(geo)) / 2 + 24).roundToDouble();
    return Offset(geo.w * (0.2 + 0.3 * place), y);
  }

  double _cupW(_Geo geo) => min(112.0, geo.w * 0.29).roundToDouble();

  /// One of the cup sprite's cells, on screen.
  double _cupCell(_Geo geo) => ShellDome.cellFor(_cupW(geo));

  /// The slab sits inside the cup's outline, so a covered slab never shows
  /// past its sides: across cells 4–23 of its 28 and down rows 12–22 of its
  /// 24, where the cup's narrowest row is cells 3–23. The bottom row, the
  /// foot, hangs one cell below the slab.
  static const int _slabCells = 20;
  static const int _slabRows = 11;

  /// How far a cup lifts to show its slab: clear of the slab's top.
  static const double _domeLift = 54;

  /// Where [cup]'s slab is now: in its place, or mid-swap on an arc.
  Rect _cupRect(_Geo geo, _ShellRound round, int cup) {
    final swaps = round.game.swaps;
    final into = (round.t - round.shuffleStart) / round.swap;
    Offset at;
    if (into <= 0) {
      at = _cupPlace(geo, cup);
    } else if (into >= swaps.length) {
      at = _cupPlace(geo, round.game.placesAfter(swaps.length)[cup]);
    } else {
      final done = into.floor();
      final k = into - done;
      final places = round.game.placesAfter(done);
      final (a, b) = swaps[done];
      final from = places[cup];
      if (from == a || from == b) {
        final to = from == a ? b : a;
        final ease = k * k * (3 - 2 * k);
        final p0 = _cupPlace(geo, from);
        final p1 = _cupPlace(geo, to);
        // One goes over, the other under.
        final arc = (from == a ? -1 : 1) * 34 * sin(pi * k);
        at = Offset(p0.dx + (p1.dx - p0.dx) * ease, p0.dy + arc);
      } else {
        at = _cupPlace(geo, from);
      }
    }
    final cell = _cupCell(geo);
    final w = (cell * _slabCells).roundToDouble();
    final h = (cell * _slabRows).roundToDouble();
    return Rect.fromLTWH(
      (at.dx - w / 2).roundToDouble(),
      (at.dy - h / 2).roundToDouble(),
      w,
      h,
    );
  }

  /// How far [cup]'s dome is lifted off its slab, 0 to 1.
  double _cupLift(_ShellRound round, int cup) {
    final t = round.t;
    final revealAt = round.revealAt;
    if (revealAt != null &&
        (cup == round.picked || cup == round.game.answer)) {
      return ((t - revealAt) / 0.15).clamp(0.0, 1.0);
    }
    if (t < round.showEnd) return 1;
    return (1 - (t - round.showEnd) / _ShellRound.flip).clamp(0.0, 1.0);
  }

  List<Widget> _buildShellGame(_Geo geo, _ShellRound round) {
    if (_stage == _Stage.jumping) return const [];
    final game = round.game;
    final rise = (round.t / _ShellRound.rise).clamp(0.0, 1.0);
    final style =
        _pixel(10, _BossTrialScreenState._ink, localeCode: _nativeCode);
    final pieces = <Widget>[];
    for (var cup = 0; cup < game.cups.length; cup++) {
      final slab = _cupRect(geo, round, cup)
          .translate(0, ((1 - rise) * 40).roundToDouble());
      final lift = _cupLift(round, cup);
      final state = !round.settled
          ? MossPieceState.plain
          : cup == game.answer
              ? MossPieceState.right
              : cup == round.picked
                  ? MossPieceState.wrong
                  : MossPieceState.plain;
      final cupW = _cupW(geo);
      final domeH = ShellDome.heightFor(cupW);
      final dome = Rect.fromLTWH(
        (slab.center.dx - cupW / 2).roundToDouble(),
        (slab.bottom - domeH + _cupCell(geo) - lift * _domeLift)
            .roundToDouble(),
        cupW,
        domeH,
      );
      pieces
        ..add(Positioned.fromRect(
          rect: slab,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _tapCup(cup),
            child: ShellSlab(
              label: game.cups[cup].meaning,
              style: style,
              state: state,
            ),
          ),
        ))
        ..add(Positioned.fromRect(
          rect: dome,
          child: ShellDome(onTapDown: () => _tapCup(cup)),
        ));
    }
    return pieces;
  }
}

// ---- Pebble Pop -------------------------------------------------------------

class _PebbleRound {
  _PebbleRound(this.wave, {required this.up, required this.interval});

  final PebbleWave wave;

  /// Seconds a pebble stays up, and between one pop and the next.
  final double up;
  final double interval;

  double clock = 0;
  int next = 0;
  final List<_Popped> live = [];
  bool found = false;

  /// The right pebble, once it is bonked: it stays up while the pet crouches
  /// over it and pounces, and bursts when the pet lands.
  _Popped? bonked;

  /// Seconds a pebble takes to come up out of its hole, or go back down.
  static const double duck = 0.12;
}

class _Popped {
  _Popped(this.pop);

  final PebblePop pop;
  double t = 0;
}

extension _PebblePopFlow on _BossTrialScreenState {
  /// The pet's jump at a bonked pebble: only a dip to spring from, then the
  /// leap, so it is in the air as soon as the pebble is hit.
  static const double _jumpCrouch = 0.06;
  static const double _jumpRise = 0.3;

  void _beginPebbles() {
    final wave = PebbleWave.build(_pool, previous: _lastPrompt, random: _rng);
    if (wave == null) {
      _finish();
      return;
    }
    _refresh(() {
      _pebbles = _PebbleRound(
        wave,
        up: _BossTrialScreenState._secs(MossRules.popUp(_clockPatience)),
        interval:
            _BossTrialScreenState._secs(MossRules.popInterval(_clockPatience)),
      );
      _lastPrompt = wave.prompt;
      _stage = _Stage.jumping;
      _stageTime = 0;
      _startMove();
      _shouting = false;
    });
  }

  void _openPebbles(_Geo geo) {
    _refresh(() {
      _stage = _Stage.popping;
      _stageTime = 0;
    });
    _landingShock(geo);
  }

  void _stepPebbles(double dt, _Geo geo) {
    final round = _pebbles;
    if (round == null || round.found) return;
    round.clock += dt;
    final pops = round.wave.pops;
    if (round.next < pops.length &&
        (round.next == 0 || round.clock >= round.interval)) {
      round.live.add(_Popped(pops[round.next]));
      // The pet turns to watch whatever pops up.
      _faceToward(_pebbleRect(geo, pops[round.next].hole).center.dx,
          from: _petX, deadzone: 12);
      round.next++;
      round.clock = 0;
    }
    for (final p in [...round.live]) {
      p.t += dt;
      if (p.t >= round.up) round.live.remove(p);
    }
    if (round.next >= pops.length && round.live.isEmpty) {
      _refresh(() {
        _run = _run.letLand();
        _stage = _Stage.resolving;
        _stageTime = 0;
      });
      _pop('too slow', _BossTrialScreenState._muted,
          Offset(geo.w / 2, _petTop(geo) - 8));
    }
  }

  /// How far [p] is up out of its hole, 0 to 1.
  double _popHeight(_PebbleRound round, _Popped p) {
    const d = _PebbleRound.duck;
    if (p.t < d) return p.t / d;
    if (p.t > round.up - d) return ((round.up - p.t) / d).clamp(0.0, 1.0);
    return 1;
  }

  void _bonk(_Popped p) {
    final round = _pebbles;
    final geo = _geo;
    if (_phase != _Phase.playing ||
        _stage != _Stage.popping ||
        round == null ||
        geo == null ||
        round.found ||
        !round.live.contains(p) ||
        _popHeight(round, p) < 0.5) {
      return;
    }
    final rect = _pebbleRect(geo, p.pop.hole);
    final at = rect.center;
    if (round.wave.isRight(p.pop)) {
      HapticFeedback.selectionClick();
      final earliness = 1 - p.t / round.up;
      _refresh(() {
        round.found = true;
        round.live.clear();
        // Held up where it is while the pet comes for it.
        if (!_reduceMotion) round.bonked = p;
        _stage = _Stage.resolving;
        _stageTime = 0;
      });
      final shot = _Shot(
        from: at,
        earliness: earliness,
        whole: true,
        look: _ShotLook.rock,
      );
      if (_reduceMotion) {
        _shoot(geo, shot);
        return;
      }
      // It jumps for it the moment it is bonked — no gathering, the pebble
      // would duck — and the pebble bursts into the shot as the pet lands on
      // it. Then back to where it was.
      final reach = Offset(
        at.dx - _petX,
        max(0.0, geo.groundTop - (rect.top + 8)),
      );
      _faceToward(at.dx, from: _petX);
      _playMove(_PetMove.leap(
        reach: reach,
        tilt: (reach.dx < 0 ? -1.0 : 1.0) * pi / 9,
        crouch: _jumpCrouch,
        rise: _jumpRise,
        hold: 0.12,
        fall: 0.35,
        squash: 0.1,
        shiver: 0,
        dip: 3,
        onImpact: (geo) {
          _refresh(() => round.bonked = null);
          _particles.shatter(rect);
          _shots.add(shot);
        },
      ));
      return;
    }
    _refresh(() {
      round.live.remove(p);
      _run = _run.answerWrong(round.wave.prompt);
    });
    if (!_reduceMotion) {
      _particles.shatter(rect);
      // It turns to what it was fooled by, and flinches.
      _faceToward(at.dx, from: _petX, deadzone: 12);
    }
    _wrongJolt(geo, at.translate(0, -34));
  }

  // ---- layout ----

  double _pebbleTop(_Geo geo) => geo.fallTop + _Geo.promptH + 18;

  /// The middle of hole [hole]'s mouth: two rows of three.
  Offset _holeAt(_Geo geo, int hole) {
    final rowGap =
        ((_petTop(geo) - 12 - _pebbleTop(geo)) / 2).clamp(60.0, 110.0);
    final row = hole ~/ 3;
    final col = hole % 3;
    return Offset(
      geo.w * (0.2 + 0.3 * col),
      (_pebbleTop(geo) + rowGap * (row + 0.9)).roundToDouble(),
    );
  }

  /// A pebble fully up out of hole [hole].
  Rect _pebbleRect(_Geo geo, int hole) {
    final mouth = _holeAt(geo, hole);
    final w = min(108.0, geo.w * 0.28).roundToDouble();
    return Rect.fromLTWH(
      (mouth.dx - w / 2).roundToDouble(),
      mouth.dy - 2 - PebbleTile.height,
      w,
      PebbleTile.height,
    );
  }

  List<Widget> _buildPebblePop(_Geo geo, _PebbleRound round) {
    if (_stage == _Stage.jumping) return const [];
    final style =
        _pixel(10, _BossTrialScreenState._ink, localeCode: _languageCode);
    return [
      Positioned(
        left: _Geo.spellInset,
        right: _Geo.spellInset,
        top: geo.fallTop + 6,
        height: _Geo.promptH,
        child: SpellPrompt(
          label: 'BONK THE WORD FOR',
          meaning: round.wave.prompt.meaning,
          labelStyle: _pixel(7, const Color(0xFF7A4E2D)),
          meaningStyle:
              _pixel(12, _BossTrialScreenState._ink, localeCode: _nativeCode),
        ),
      ),
      for (var hole = 0; hole < MossRules.holes; hole++)
        Positioned.fromRect(
          rect: Rect.fromCenter(
            center: _holeAt(geo, hole).translate(0, 6),
            width: min(112.0, geo.w * 0.3).roundToDouble(),
            height: 20,
          ),
          child: const MossHole(),
        ),
      for (final p in round.live)
        Positioned.fromRect(
          rect: _pebbleRect(geo, p.pop.hole),
          child: ClipRect(
            child: Transform.translate(
              offset: Offset(
                0,
                (((1 - _popHeight(round, p)) * (PebbleTile.height + 2)) / 4)
                        .round() *
                    4.0,
              ),
              child: PebbleTile(
                label: p.pop.word.target,
                style: style,
                onTapDown: () => _bonk(p),
              ),
            ),
          ),
        ),
      // The bonked one, held up where it was while the pet comes for it.
      if (round.bonked case final p?)
        Positioned.fromRect(
          rect: _pebbleRect(geo, p.pop.hole),
          child: PebbleTile(
            label: p.pop.word.target,
            style: style,
            onTapDown: null,
          ),
        ),
    ];
  }
}

// ---- Stepping Stones --------------------------------------------------------

class _CrossingRound {
  _CrossingRound(this.crossing, {required this.sinkSeconds});

  final Crossing crossing;
  final double sinkSeconds;

  /// The row to hop onto next; the bank is before row 0.
  int row = 0;

  /// This hop's clock: the stone under the pet sinking, 0 to 1.
  double sink = 0;

  /// How early each hop so far was made, banked for the headbutt.
  final List<double> earliness = [];

  /// The stone the pet stands on, in the row before [row].
  int? on;

  /// A stone chosen wrong, which takes the pet down with it: (row, stone).
  (int, int)? wrong;

  /// Seconds into the pet's dunk, or null while it is dry.
  double? dunk;

  /// The pet is under the river, sunk from a stone, until it comes back up on
  /// the bank. A pet caught too slow on the bank itself has nothing to sink
  /// into.
  bool swimming = false;

  bool crossed = false;
}

extension _SteppingStonesFlow on _BossTrialScreenState {
  void _beginCrossing() {
    final crossing = Crossing.build(_pool, random: _rng);
    if (crossing == null) {
      _finish();
      return;
    }
    _refresh(() {
      _leaving = null;
      // Fixed for the crossing, so the stones never sink faster halfway.
      _crossing = _CrossingRound(
        crossing,
        sinkSeconds:
            _BossTrialScreenState._secs(MossRules.sinkTime(_clockPatience)),
      );
      _stage = _Stage.jumping;
      _stageTime = 0;
      _startMove();
      _shouting = false;
    });
  }

  void _openCrossing(_Geo geo) {
    _refresh(() {
      _stage = _Stage.crossing;
      _stageTime = 0;
      _petScale = 0.6;
    });
    _landingShock(geo);
  }

  /// The word Mossback is shouting for the row to hop onto next.
  String? get _crossingShout {
    final round = _crossing;
    if (round == null || round.crossed || round.dunk != null) return null;
    final rows = round.crossing.rows;
    return round.row < rows.length ? rows[round.row].prompt.target : null;
  }

  void _stepCrossing(double dt, _Geo geo) {
    final round = _crossing;
    if (round == null || round.dunk != null || round.crossed) return;
    round.sink = min(1.0, round.sink + dt / round.sinkSeconds);
    if (round.sink >= 1) {
      // Too slow: the stone goes under, or the tide takes the bank.
      _refresh(() => _run = _run.letLand());
      _pop('too slow', _BossTrialScreenState._muted,
          Offset(_petX, _petTop(geo) - 8));
      _dunkPet(geo);
    }
  }

  void _animateMossRounds(double dt, _Geo geo) {
    _shell?.t += dt;
    // The pet's headbutt, pounce, throw, cast or flattening, a frame on.
    _stepMove(dt, geo);
    _watchPhase(geo);
    if (_petSpring >= 0) {
      _petSpring += dt;
      if (_petSpring >= _BossTrialScreenState._springSeconds) _petSpring = -1;
    }
    if (_leaving != null) {
      // The stones of a crossing over sink back under the river.
      _leavingT += dt;
      if (_leavingT >= _leaveSeconds) _leaving = null;
    }
    final round = _crossing;
    final dunk = round?.dunk;
    if (round != null && dunk != null) {
      round.dunk = dunk + dt;
      if (round.swimming) {
        _petDunk = (round.dunk! / _sinkSeconds).clamp(0.0, 1.0);
        if (round.dunk! >= _comeBackAt) _comeBack(geo, round);
      }
    }
  }

  static const List<Color> _splash = [
    RiverPainter.ripple,
    RiverPainter.glint,
    Color(0xFFFFFFFF),
  ];

  /// Seconds for the pet to go under, and for it to come back up on the bank.
  static const double _sinkSeconds = 0.7;
  static const double _comeBackAt = 0.9;

  /// Seconds for a crossing's stones to sink away once it is over.
  static const double _leaveSeconds = 0.4;

  /// Up out of the river onto the bank as itself: full size, in its place at
  /// the start of the arena, with a small hop.
  void _comeBack(_Geo geo, _CrossingRound round) {
    round.swimming = false;
    _perch = null;
    _petFeet = null;
    _petDunk = 0;
    _petScale = 1;
    _petFacesLeft = false;
    _petX = _petHomeX(geo);
    if (_reduceMotion) return;
    _petSpring = 0;
    _particles.sparks(
      Offset(_petX, geo.groundTop - 10),
      count: 10,
      colors: _splash,
    );
  }

  /// The pet goes under where it stands — if that is on a stone — loses what
  /// it banked, and comes up back on the bank. Caught too slow on the bank
  /// itself it can't sink, and just hops clear of the water.
  void _dunkPet(_Geo geo) {
    final round = _crossing;
    if (round == null) return;
    _refresh(() {
      round.dunk = 0;
      round.swimming = _perch != null;
      round.earliness.clear();
      _holdAftermath = true;
      _stage = _Stage.resolving;
      _stageTime = 0;
      if (!round.swimming && !_reduceMotion) _petSpring = 0;
    });
    if (!_reduceMotion) {
      _particles.sparks(
        Offset(_petX, _petFeet ?? geo.groundTop),
        count: 14,
        colors: _splash,
      );
    }
  }

  void _tapStepStone(int row, int stone) {
    final round = _crossing;
    final geo = _geo;
    if (_phase != _Phase.playing ||
        _stage != _Stage.crossing ||
        round == null ||
        geo == null ||
        round.dunk != null ||
        round.crossed ||
        row != round.row) {
      return;
    }
    final line = round.crossing.rows[row];
    final rect = _stepStoneRect(geo, round, row, stone);
    // Turned the way it hops, from the stone it stands on (or the bank).
    _faceToward(rect.center.dx, from: _perch?.dx ?? _petX);
    if (stone != line.answer) {
      // It hops on anyway, and the stone goes down with it.
      _refresh(() {
        round.wrong = (row, stone);
        _run = _run.answerWrong(line.prompt);
      });
      _perch = Offset(rect.center.dx, rect.top + 6);
      _wrongJolt(geo, rect.topCenter.translate(0, -12));
      _dunkPet(geo);
      return;
    }

    HapticFeedback.selectionClick();
    _refresh(() {
      round.earliness.add(1 - round.sink);
      round.on = stone;
      round.row++;
      round.sink = 0;
    });
    _perch = Offset(rect.center.dx, rect.top + 6);
    if (!_reduceMotion) {
      _petHop = 0;
      _particles.sparks(rect.topCenter, count: 6, colors: _splash);
    }
    if (round.row < round.crossing.rows.length) return;

    // Across: everything banked lands in one headbutt.
    _refresh(() {
      round.crossed = true;
      _stage = _Stage.resolving;
      _stageTime = 0;
    });
    _pop('across!', _BossTrialScreenState._right,
        Offset(_petX, _petTop(geo) - 8));
    _headbutt(
      geo,
      _Shot(
        from: Offset(rect.center.dx, rect.top - 20),
        earliness: 0,
        look: _ShotLook.butt,
        bank: [...round.earliness],
        seconds: _headbuttImpact,
      ),
    );
  }

  /// A headbutt: a second to gather on the stone, a quarter of one to leap, and
  /// the hit lands at the top of the leap.
  static const double _headbuttCrouch = 1.0;
  static const double _headbuttRise = 0.25;
  static const double _headbuttImpact = _headbuttCrouch + _headbuttRise;

  /// The pet crouches on the far stone, leaps up at the boss, lands everything
  /// it banked as one hit at the top of the leap, and falls all the way back
  /// to the start of the arena. With reduced motion the hit just lands.
  void _headbutt(_Geo geo, _Shot shot) {
    final stand = _perch;
    final hit = _bossHitPoint(geo);
    if (_reduceMotion || stand == null) {
      if (stand != null) _petFacesLeft = hit.dx < stand.dx;
      _shoot(geo, shot);
      return;
    }
    final size = (geo.petBox * _petScale).roundToDouble();
    _shots.add(shot);
    // The head goes to the boss's hit point, from the stone it stands on, and
    // the fall ends on the ground where the pet began.
    final reach = Offset(
      hit.dx - stand.dx,
      max(0.0, stand.dy - size * 0.9 - hit.dy),
    );
    _playMove(_PetMove.leap(
      reach: reach,
      back: Offset(_petHomeX(geo) - stand.dx, stand.dy - geo.groundTop),
      tilt: (reach.dx < 0 ? -1.0 : 1.0) * pi / 6,
      crouch: _headbuttCrouch,
      rise: _headbuttRise,
      hold: 0.2,
      fall: 0.4,
      grow: true,
      // Landed on the last stone from a hop that faced the way it went, it
      // turns to face the boss.
      faceAt: 0.3,
      faceLeft: reach.dx < 0,
      onEnd: (geo) {
        // Landed back at the start of the arena, full size, standing as it
        // does when any phase begins.
        _perch = null;
        _petFeet = null;
        _petScale = 1;
        _petX = _petHomeX(geo);
        if (!_reduceMotion) {
          _particles.sparks(
            Offset(_petX, geo.groundTop),
            count: 8,
            colors: _splash,
          );
        }
      },
    ));
  }

  // ---- layout ----

  double _riverTop(_Geo geo) => geo.ledgeTop + geo.ledgeH - 4;

  /// The middle of row [row]'s stones, counted up from the bank.
  double _rowY(_Geo geo, int row) {
    final river = geo.groundTop - _riverTop(geo);
    final pitch = river / (MossRules.rows + 0.4);
    return (geo.groundTop - pitch * (row + 0.75)).roundToDouble();
  }

  Rect _stepStoneRect(_Geo geo, _CrossingRound round, int row, int stone) {
    final lane = round.crossing.rows[row].lanes[stone];
    return Rect.fromCenter(
      center: Offset(geo.laneCentre(lane), _rowY(geo, row)),
      width: geo.tileW,
      height: 36,
    );
  }

  /// The river is there for the whole of the Stepping Stones opening —
  /// between crossings too — and only its stones come and go.
  bool get _riverUp =>
      _crossing != null ||
      _leaving != null ||
      (_phase == _Phase.playing && _opener == TrialOpener.steppingStones);

  /// How far up out of the river row [row]'s stones are while the boss jumps,
  /// [p] being how far through the jump to its landing, 0 to 1: the bottom row
  /// first, and the top one just as the boss lands.
  static double _risen(int row, double p) {
    final k = ((p - row * 0.12) / 0.64).clamp(0.0, 1.0);
    return 1 - (1 - k) * (1 - k);
  }

  List<Widget> _buildRiver(_Geo geo) => [
        Positioned(
          left: 0,
          right: 0,
          top: _riverTop(geo),
          bottom: geo.h - geo.groundTop,
          child: CustomPaint(painter: RiverPainter(_time)),
        ),
      ];

  /// The stones of [round]: rising out of the river while the boss jumps,
  /// tappable once it lands, and — when [leaving], the crossing over —
  /// sinking back under.
  List<Widget> _buildCrossing(_Geo geo, _CrossingRound round,
      {bool leaving = false}) {
    final style =
        _pixel(10, _BossTrialScreenState._ink, localeCode: _nativeCode);
    final rows = round.crossing.rows;
    final jumping = !leaving && _stage == _Stage.jumping;
    final jumped = jumping && !_reduceMotion
        ? (_stageTime / _BossTrialScreenState._secs(_arriveAt))
            .clamp(0.0, 1.0)
        : 1.0;
    final leave =
        leaving ? (_leavingT / _leaveSeconds).clamp(0.0, 1.0) : 0.0;
    return [
      for (var r = 0; r < rows.length; r++)
        for (var s = 0; s < rows[r].stones.length; s++)
          Positioned.fromRect(
            rect: _stepStoneRect(geo, round, r, s),
            child: SteppingStone(
              label: rows[r].stones[s].meaning,
              style: style,
              state: round.wrong == (r, s)
                  ? MossPieceState.wrong
                  : r < round.row && s == rows[r].answer
                      ? MossPieceState.right
                      : MossPieceState.plain,
              // The stone under the pet sinks with the hop's clock; a wrong
              // one goes straight down.
              sunk: jumping
                  ? 1 - _risen(r, jumped)
                  : max(
                      round.wrong == (r, s)
                          ? ((round.dunk ?? 0) / 0.4).clamp(0.0, 1.0)
                          : r == round.row - 1 && s == round.on
                              ? round.sink
                              : 0.0,
                      leave,
                    ),
              onTapDown: !leaving && !jumping && r == round.row
                  ? () => _tapStepStone(r, s)
                  : null,
            ),
          ),
    ];
  }

  List<Widget> _buildMossRounds(_Geo geo) => [
        if (_shell case final round?) ..._buildShellGame(geo, round),
        if (_pebbles case final round?) ..._buildPebblePop(geo, round),
        if (_crossing case final round?) ..._buildCrossing(geo, round),
        if (_leaving case final round?)
          ..._buildCrossing(geo, round, leaving: true),
      ];

  void _clearMossRounds() {
    _shell = null;
    _pebbles = null;
    // A crossing's stones sink back under the river, which stays.
    if (_crossing != null && !_reduceMotion) {
      _leaving = _crossing;
      _leavingT = 0;
    }
    _crossing = null;
    _petDunk = 0;
    // Mid-headbutt, the pet is still on its way back to the start of the
    // arena: the end of the fall puts it there, rather than it vanishing off
    // the apex. And on the witch's broom, it is hers to bring down.
    if (_move != null || _onBroom) return;
    _perch = null;
    _petFeet = null;
    _petScale = 1;
    _petFacesLeft = false;
  }
}
