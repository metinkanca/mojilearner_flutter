part of 'boss_trial_screen.dart';

// The witch's openers under test beside her Hexed Scroll: Mirror Clones,
// Tangled Spells and the Broom Chase. The rules are in
// `utils/boss_trial_witch.dart`; this is their clock, their layout and their
// taps, on the screen's own game clock.

// ---- Mirror Clones ----------------------------------------------------------

class _CloneRound {
  _CloneRound(this.wave, {required this.fuseSeconds, required Random rng})
      : phases = [
          for (var i = 0; i < wave.owls.length; i++) rng.nextDouble() * 2 * pi
        ];

  final CloneWave wave;
  final double fuseSeconds;

  /// Where along its flight each owl starts.
  final List<double> phases;

  double fuse = 0;

  /// Seconds since she split.
  double t = 0;

  final Set<int> popped = {};
  bool found = false;

  /// The fuse ran out: she shows which one was her.
  bool revealed = false;

  /// When the owls stopped flying: she was found, or the fuse ran out.
  double? stoppedAt;

  /// How fast each owl flies its band, in radians a second.
  static const List<double> speeds = [0.9, 1.25, 0.7];

  /// Seconds for the three to fly out of her to their bands.
  static const double split = 0.35;
}

extension _MirrorClonesFlow on _BossTrialScreenState {
  void _beginClones() {
    final wave =
        CloneWave.build(_sentences, previous: _lastScroll, random: _rng);
    if (wave == null) {
      _throwWave();
      return;
    }
    _refresh(() {
      // Fixed when she splits, so the fuse never speeds up mid-burn.
      _clones = _CloneRound(
        wave,
        fuseSeconds: _BossTrialScreenState._secs(WitchRules.cloneTime(
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

  /// She arrives, and splits into three in a burst of smoke.
  void _splitClones(_Geo geo) {
    _refresh(() {
      _stage = _Stage.cloning;
      _stageTime = 0;
      _clones?.t = 0;
    });
    _landingShock(geo);
    if (!_reduceMotion) {
      _particles.sparks(_bossHitPoint(geo),
          count: 18, colors: HexPalette.sparks);
    }
  }

  /// While she is split, she is only where her owls are.
  bool get _bossHidden => _clones != null && _stage != _Stage.jumping;

  void _stepClones(double dt, _Geo geo) {
    final round = _clones;
    if (round == null || round.found || round.revealed) return;
    round.fuse = min(1.0, round.fuse + dt / round.fuseSeconds);
    if (round.fuse < 1) return;

    // Out: the clones vanish, and she hexes the pet from where she is.
    final real = _owlCentre(geo, round, round.wave.real);
    _refresh(() {
      round.revealed = true;
      round.stoppedAt = round.t;
      _run = _run.castFailed(round.wave.sentence);
      _holdAftermath = true;
      _stage = _Stage.resolving;
      _stageTime = 0;
    });
    _poofClones(geo, round, keep: round.wave.real);
    if (!_reduceMotion) {
      _particles.sparks(real, count: 10, colors: HexPalette.sparks);
    }
    _strikePet(geo);
    if (_run.isOver) _endIn = 0.8;
  }

  void _poofClones(_Geo geo, _CloneRound round, {required int keep}) {
    for (var i = 0; i < round.wave.owls.length; i++) {
      if (i == keep || round.popped.contains(i)) continue;
      if (!_reduceMotion) {
        _particles.sparks(_owlCentre(geo, round, i),
            count: 14, colors: HexPalette.sparks);
      }
      round.popped.add(i);
    }
  }

  void _tapOwl(int owl) {
    final round = _clones;
    final geo = _geo;
    if (_phase != _Phase.playing ||
        _stage != _Stage.cloning ||
        round == null ||
        geo == null ||
        round.found ||
        round.popped.contains(owl) ||
        round.t < _CloneRound.split) {
      return;
    }
    final at = _owlCentre(geo, round, owl);
    if (owl != round.wave.real) {
      HapticFeedback.lightImpact();
      _refresh(() {
        round.popped.add(owl);
        round.fuse = min(0.97, round.fuse + WitchRules.cloneMistakeBurn);
        _run = _run.fizzle();
      });
      if (!_reduceMotion) {
        _particles.sparks(at, count: 16, colors: HexPalette.sparks);
        // The smoke makes it cringe, turned to it.
        _cringeAt(at);
      }
      _pop('clone!', _BossTrialScreenState._hurtRed, at.translate(0, -40));
      return;
    }

    HapticFeedback.selectionClick();
    final earliness = 1 - round.fuse;
    _refresh(() {
      round.found = true;
      round.stoppedAt = round.t;
      _stage = _Stage.resolving;
      _stageTime = 0;
    });
    _poofClones(geo, round, keep: owl);
    final spell = _Shot(
      from: Offset(_petX, _petTop(geo) + 10),
      earliness: earliness,
      whole: true,
      look: _ShotLook.spell,
      to: at,
    );
    if (_reduceMotion) {
      _shoot(geo, spell);
      return;
    }
    // She is far above, so the pet leaps for her — tall, and across toward
    // the owl — and SWATS her at the top of the leap, the spell leaving it
    // then.
    final apex = Offset(at.dx, geo.groundTop - geo.petBox * 0.65 - 96);
    final (swat, hit) = _swatLeap(geo, apex, rise: 0.24, fall: 0.3);
    _stayPut(hit + 0.7);
    _shots.add(_Shot(
      from: apex.translate(0, -geo.petBox * 0.1),
      earliness: earliness,
      whole: true,
      look: _ShotLook.spell,
      to: at,
      delay: hit,
    ));
    _playMove(swat);
  }

  /// The pet trots along under the lowest of the owls, whichever of them is
  /// the real one, as they fly — facing the way it goes.
  void _trailOwls(_Geo geo) {
    final round = _clones;
    if (round == null || round.found || round.revealed || _reduceMotion) return;
    final lowest = _owlCentre(geo, round, WitchRules.owls - 1).dx;
    final x = lowest.clamp(geo.petBox / 2, geo.w - geo.petBox / 2).toDouble();
    _petGoX = x;
    _petLane = null;
    _petAway = 0.3;
    _petRunning = true;
    // Going the way the owl does, it faces that way — however small the gap,
    // for it only ever lags an owl's frame behind.
    _faceToward(x, from: _petX);
  }

  // ---- layout ----

  /// The prompt sits just over the pet; the owls have everything above it.
  double _clonePromptTop(_Geo geo) =>
      geo.groundTop - geo.petBox * 0.95 - 8 - _Geo.promptH;

  double _cloneFuseTop(_Geo geo) => _clonePromptTop(geo) - 8 - _Geo.chargeH;

  double _bandH(_Geo geo) =>
      (_cloneFuseTop(geo) - 8 - _Geo.bubbleTop) / WitchRules.owls;

  Size _owlSize(_Geo geo) {
    final h = min(_bandH(geo) - 40, geo.bossH * 0.5).roundToDouble();
    return Size((h * _boss.aspect).roundToDouble(), h);
  }

  /// Owl [owl]'s middle, [round.t] into the flight.
  Offset _owlCentre(_Geo geo, _CloneRound round, int owl) {
    final t = round.stoppedAt ?? round.t;
    final size = _owlSize(geo);
    final reach = max(0.0, (geo.w - size.width) / 2 - 6);
    final speed = _CloneRound.speeds[owl % _CloneRound.speeds.length];
    final bob = (sin(t * 2.2 + owl) * 3).roundToDouble();
    final path = Offset(
      geo.w / 2 + reach * sin(speed * t + round.phases[owl]),
      _Geo.bubbleTop + _bandH(geo) * owl + 36 + size.height / 2 + bob,
    );
    if (t >= _CloneRound.split) return path;
    // Flying out of her to their bands.
    final k = t / _CloneRound.split;
    return Offset.lerp(_bossHitPoint(geo), path, k * k * (3 - 2 * k))!;
  }

  /// The fuse and what the real owl says, behind the pet: it leaps in front of
  /// them.
  List<Widget> _buildClonesBehind(_Geo geo, _CloneRound round) {
    if (_stage == _Stage.jumping) return const [];
    return [
      Positioned(
        left: ((geo.w - geo.chargeW) / 2).roundToDouble(),
        top: _cloneFuseTop(geo),
        width: geo.chargeW,
        height: _Geo.chargeH,
        child: ChargeBar(charge: round.fuse, color: HexPalette.hex),
      ),
      Positioned(
        left: _Geo.spellInset,
        right: _Geo.spellInset,
        top: _clonePromptTop(geo),
        height: _Geo.promptH,
        child: SpellPrompt(
          label: 'THE REAL ONE SAYS',
          meaning: round.wave.sentence.meaning,
          labelStyle: _pixel(7, const Color(0xFF7A4E2D)),
          meaningStyle:
              _pixel(12, _BossTrialScreenState._ink, localeCode: _nativeCode),
        ),
      ),
    ];
  }

  List<Widget> _buildClones(_Geo geo, _CloneRound round) {
    if (_stage == _Stage.jumping) return const [];
    final size = _owlSize(geo);
    final bubbleW = min(geo.w - 16, 236.0);
    final style =
        _pixel(9, _BossTrialScreenState._ink, localeCode: _languageCode);
    final pieces = <Widget>[];
    for (var i = 0; i < round.wave.owls.length; i++) {
      if (round.popped.contains(i)) continue;
      final at = _owlCentre(geo, round, i);
      final owl = Rect.fromCenter(
        center: Offset(at.dx.roundToDouble(), at.dy.roundToDouble()),
        width: size.width,
        height: size.height,
      );
      final bubbleLeft =
          (at.dx - bubbleW / 2).clamp(8.0, geo.w - 8 - bubbleW).roundToDouble();
      final said = round.wave.owls[i]
          .join(const {'ja', 'zh', 'th'}.contains(_languageCode) ? '' : ' ');
      pieces
        ..add(Positioned.fromRect(
          key: ValueKey('owl-$i'),
          rect: owl,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _tapOwl(i),
            child: _bossPoses().first,
          ),
        ))
        ..add(Positioned(
          left: bubbleLeft,
          top: owl.top - 34,
          width: bubbleW,
          height: 30,
          child: OwlBubble(
            text: said,
            style: style,
            state: round.revealed || round.found
                ? HexPieceState.right
                : HexPieceState.plain,
            onTapDown: () => _tapOwl(i),
          ),
        ));
    }
    return pieces;
  }
}

// ---- Tangled Spells ---------------------------------------------------------

class _TangleRound {
  _TangleRound(this.wave, {required this.fuseSeconds});

  final TangleWave wave;
  final double fuseSeconds;

  double fuse = 0;

  /// The word out now, and seconds since it came out.
  int next = 0;
  double wordT = 0;

  /// How full each cauldron looks: a word only counts here once the pet has
  /// carried it over and it has dropped in.
  int intoFirst = 0;
  int intoSecond = 0;

  /// The words the pet is carrying to a cauldron, or that are dropping in.
  final List<_CarriedWord> carried = [];

  /// The cauldron a word was just refused by: 0 the first, 1 the second.
  int? refused;
  double refusedAt = -1;

  bool revealed = false;

  bool get done => next >= wave.words.length;

  /// Seconds for a word to fall from her to where it waits.
  static const double fall = 0.45;
}

/// A word the pet is taking to a cauldron on its head: picked up off where it
/// waited, riding along as the pet runs, and dropped in when it gets there.
class _CarriedWord {
  _CarriedWord(this.label, {required this.first, required this.travel});

  final String label;
  final bool first;

  /// Seconds before it is let go: as long as the run takes. Shorter, if the
  /// pet is sent off with another word before it gets there.
  double travel;
  double t = 0;

  /// Where it was let go from: the pet's head as it let go, or — when the pet
  /// was sent off with another word first — where it had got to by then.
  Offset? from;

  /// Seconds it takes to arc into the pot.
  static const double drop = 0.45;

  bool get dropping => t >= travel;
  bool get landed => t >= travel + drop;
}

extension _TangledSpellsFlow on _BossTrialScreenState {
  void _beginTangle() {
    final wave =
        TangleWave.build(_sentences, previous: _lastScroll, random: _rng);
    if (wave == null) {
      _throwWave();
      return;
    }
    _refresh(() {
      _tangle = _TangleRound(
        wave,
        fuseSeconds: _BossTrialScreenState._secs(WitchRules.tangleTime(
          words: wave.words.length,
          patience: _clockPatience,
        )),
      );
      _lastScroll = wave.first;
      _stage = _Stage.jumping;
      _stageTime = 0;
      _startMove();
      _shouting = false;
    });
  }

  void _openTangle(_Geo geo) {
    _refresh(() {
      _stage = _Stage.sorting;
      _stageTime = 0;
      _tangle?.wordT = 0;
    });
    _landingShock(geo);
  }

  void _stepTangle(double dt, _Geo geo) {
    final round = _tangle;
    if (round == null || round.done || round.revealed) return;
    round.fuse = min(1.0, round.fuse + dt / round.fuseSeconds);
    if (round.fuse < 1) return;
    _refresh(() {
      round.revealed = true;
      _run = _run.castFailed(round.wave.first, also: [round.wave.second]);
      _holdAftermath = true;
      _stage = _Stage.resolving;
      _stageTime = 0;
    });
    _strikePet(geo);
    if (_run.isOver) _endIn = 0.8;
  }

  /// Drops the word out now into the first cauldron, or the second.
  void _sortInto(bool first) {
    final round = _tangle;
    final geo = _geo;
    if (_phase != _Phase.playing ||
        _stage != _Stage.sorting ||
        round == null ||
        geo == null ||
        round.done) {
      return;
    }
    final word = round.wave.words[round.next];
    final pot = _cauldronRect(geo, first: first);
    final potMouth = Offset(pot.center.dx, pot.bottom - 50);
    if (word.first != first) {
      HapticFeedback.lightImpact();
      _refresh(() {
        round.refused = first ? 0 : 1;
        round.refusedAt = round.wordT;
        round.fuse = min(0.97, round.fuse + WitchRules.tangleMistakeBurn);
        _run = _run.fizzle();
      });
      if (!_reduceMotion) {
        _particles.sparks(potMouth, count: 8, fizzle: true);
        // It backs off from the pot that spat the word out, still facing it.
        if (_move == null) {
          final away = pot.center.dx < _petX ? 1.0 : -1.0;
          _petFacesLeft = away > 0;
          _playMove(_PetMove.leap(
            reach: Offset(away * 22, 14),
            tilt: away * pi / 9,
            crouch: 0.05,
            rise: 0.1,
            hold: 0.04,
            fall: 0.18,
            squash: 0.1,
            shiver: 0,
            dip: 2,
          ));
        }
      }
      _pop('wrong pot', _BossTrialScreenState._hurtRed,
          potMouth.translate(0, -60));
      return;
    }

    HapticFeedback.selectionClick();
    final earliness = 1 - round.fuse;
    _refresh(() {
      round.next++;
      round.wordT = 0;
      round.refused = null;
      if (round.done) {
        _stage = _Stage.resolving;
        _stageTime = 0;
      }
    });
    if (_reduceMotion) {
      _refresh(() => first ? round.intoFirst++ : round.intoSecond++);
      _shoot(
        geo,
        _Shot(from: potMouth, earliness: earliness, look: _ShotLook.spell),
      );
      return;
    }
    // Any word still being carried is let go now, where it has got to.
    for (final other in round.carried) {
      if (!other.dropping) {
        other.from = _carriedAt(geo, round, other);
        other.travel = other.t;
      }
    }
    // The pet takes the word on its head to the pot — a hop-walk, a high hop
    // to every step, facing the way it goes — and at the pot cocks its head
    // back and LOBS it in, high; the spell leaves the pot when the word has
    // dropped in.
    final run = _runTo(geo, pot.center.dx, stay: 0.8, pace: 0.5, hop: 16);
    final k = _Keyer();
    k.to(0.1, tilt: -0.28, squash: 0.88, dy: -2);
    k.to(0.1, tilt: 0.34, squash: 1.1, dy: 10, ease: _Ease.out);
    k.to(0.12, tilt: 0, squash: 1.0, dy: 0);
    const toss = 0.2;
    round.carried
        .add(_CarriedWord(word.word, first: first, travel: run + toss));
    _shots.add(_Shot(
      from: potMouth,
      earliness: earliness,
      look: _ShotLook.spell,
      delay: run + toss + _CarriedWord.drop,
    ));
    _playMove(_PetMove.keys(k.keys, delay: run));
  }

  /// Where a word being carried is: lifted off where it waited onto the
  /// pet's head, riding there as the pet runs — or, let go, falling into its
  /// pot.
  Offset _carriedAt(_Geo geo, _TangleRound round, _CarriedWord word) {
    final pot = _cauldronRect(geo, first: word.first);
    final mouth = Offset(pot.center.dx, pot.bottom - 50);
    if (word.dropping) {
      // Lobbed: up and over in a high arc, and down into the pot.
      final k = ((word.t - word.travel) / _CarriedWord.drop).clamp(0.0, 1.0);
      final from = word.from ?? Offset(pot.center.dx, _carriedHead(geo).dy);
      return Offset.lerp(from, mouth, _smooth(k))!
          .translate(0, -sin(k * pi) * 70);
    }
    final up = (word.t / 0.12).clamp(0.0, 1.0);
    return Offset.lerp(_tangleWait(geo), _carriedHead(geo), up)!;
  }

  /// Where a word sits on the pet's head: standing on its ears, going where
  /// the pet goes — up with every hop, down with every squat.
  Offset _carriedHead(_Geo geo) {
    final size = _petSize(geo);
    final pose = _petPose(size);
    final top = (_petFeet ?? geo.groundTop) -
        pose.lift -
        size * _BossTrialScreenState._headHeight * pose.scaleY;
    return Offset(_petX + pose.dx, top - _tileH / 2);
  }

  // ---- layout ----

  static const double _labelH = 50;
  static const double _potH = 56;

  /// A word's tile, as it falls, waits and rides on the pet's head.
  static const double _tileH = 40;

  /// A cauldron and its label, sitting on the grass either side of the pet.
  Rect _cauldronRect(_Geo geo, {required bool first}) {
    final w = (geo.w * 0.36).roundToDouble();
    final h = _labelH + 6 + _potH;
    final top = geo.groundTop + 8 - h;
    return Rect.fromLTWH(first ? 10 : geo.w - 10 - w, top, w, h);
  }

  /// Where a word waits to be sorted, over the pet.
  Offset _tangleWait(_Geo geo) => Offset(
        geo.w / 2,
        (_cauldronRect(geo, first: true).top - 56).roundToDouble(),
      );

  List<Widget> _buildTangleBehind(_Geo geo, _TangleRound round) {
    if (_stage == _Stage.jumping) return const [];
    final style =
        _pixel(8, _BossTrialScreenState._ink, localeCode: _nativeCode);
    final flashing =
        round.refused != null && round.wordT - round.refusedAt < 0.3;
    Widget pot(bool first) => Positioned.fromRect(
          rect: _cauldronRect(geo, first: first),
          child: Cauldron(
            meaning:
                first ? round.wave.first.meaning : round.wave.second.meaning,
            style: style,
            labelHeight: _labelH,
            filled: first ? round.intoFirst : round.intoSecond,
            state: flashing && round.refused == (first ? 0 : 1)
                ? HexPieceState.wrong
                : round.revealed
                    ? HexPieceState.right
                    : HexPieceState.plain,
            onTapDown: () => _sortInto(first),
          ),
        );
    final wait = _tangleWait(geo);
    return [
      pot(true),
      pot(false),
      Positioned(
        left: ((geo.w - geo.chargeW) / 2).roundToDouble(),
        top: wait.dy - 60,
        width: geo.chargeW,
        height: _Geo.chargeH,
        child: ChargeBar(charge: round.fuse, color: HexPalette.hex),
      ),
    ];
  }

  List<Widget> _buildTangleFront(_Geo geo, _TangleRound round) {
    if (_stage == _Stage.jumping) return const [];
    final style = _pixel(11, _BossTrialScreenState._ink,
        localeCode: _languageCode);
    Widget tile(Offset at, String label, {double shake = 0, bool wrong = false}) =>
        Positioned(
          left: (at.dx - 60 + shake).roundToDouble(),
          top: (at.dy - _tileH / 2).roundToDouble(),
          width: 120,
          height: _tileH,
          child: IgnorePointer(
            child: TangleTile(
              label: label,
              style: style,
              state: wrong ? HexPieceState.wrong : HexPieceState.plain,
            ),
          ),
        );
    return [
      // Words the pet has sorted, on their way to the pot.
      for (final carried in round.carried)
        tile(_carriedAt(geo, round, carried), carried.label),
      if (!round.done && !round.revealed) ...[
        () {
          final word = round.wave.words[round.next];
          final k = (round.wordT / _TangleRound.fall).clamp(0.0, 1.0);
          final at =
              Offset.lerp(_bossMouth(geo), _tangleWait(geo), k * (2 - k))!;
          final flashing =
              round.refused != null && round.wordT - round.refusedAt < 0.3;
          final shake = flashing && !_reduceMotion
              ? (sin(round.wordT * 80) * 4).roundToDouble()
              : 0.0;
          return tile(at, word.word, shake: shake, wrong: flashing);
        }(),
      ],
    ];
  }
}

// ---- Broom Chase ------------------------------------------------------------

class _ChaseRound {
  _ChaseRound(
    this.wave, {
    required this.travel,
    required this.interval,
    required this.escapeSeconds,
  });

  final ChaseWave wave;

  /// Seconds a column takes to reach the pet, between columns, and for her
  /// to get away.
  final double travel;
  final double interval;
  final double escapeSeconds;

  double escape = 0;
  double clock = 0;

  /// Words flown through, and the next word to send a column for.
  int placed = 0;
  int nextToken = 0;

  final List<_Column> columns = [];

  /// The pet's lane.
  bool upper = false;

  bool done = false;
  bool escaped = false;
}

class _Column {
  _Column(this.token, this.gate);

  final int token;
  final ChaseGate gate;
  double t = 0;

  /// Whether the pet went through the right gate, once it has reached them.
  bool? passed;
}

extension _BroomChaseFlow on _BossTrialScreenState {
  void _beginChase() {
    final wave =
        ChaseWave.build(_sentences, previous: _lastScroll, random: _rng);
    if (wave == null) {
      _throwWave();
      return;
    }
    final patience = _clockPatience;
    _refresh(() {
      _chase = _ChaseRound(
        wave,
        travel: _BossTrialScreenState._secs(WitchRules.gateTravel(patience)),
        interval:
            _BossTrialScreenState._secs(WitchRules.gateInterval(patience)),
        escapeSeconds: _BossTrialScreenState._secs(WitchRules.chaseTime(
          words: wave.sentence.tokens.length,
          patience: patience,
        )),
      );
      _lastScroll = wave.sentence;
      _stage = _Stage.jumping;
      _stageTime = 0;
      _startMove();
      // She flees to the right, and the gates come from behind her.
      _side = 1;
      _shouting = false;
    });
  }

  /// The chase starts: the pet takes off on its broom.
  void _openChase(_Geo geo) {
    _refresh(() {
      _stage = _Stage.chasing;
      _stageTime = 0;
      _onBroom = true;
      _petScale = 0.6;
    });
    _perch = _chaseSeat(geo, upper: false);
    _landingShock(geo);
  }

  void _chaseLane(bool upper) {
    final round = _chase;
    final geo = _geo;
    if (_phase != _Phase.playing ||
        _stage != _Stage.chasing ||
        round == null ||
        geo == null ||
        round.upper == upper) {
      return;
    }
    HapticFeedback.selectionClick();
    round.upper = upper;
    _perch = _chaseSeat(geo, upper: upper);
    // Nose up to climb, nose down to dive: the pet flies right, so up is
    // counter-clockwise.
    if (!_reduceMotion) {
      _playMove(_PetMove.tipped(tilt: upper ? -0.34 : 0.34));
    }
  }

  void _stepChase(double dt, _Geo geo) {
    final round = _chase;
    if (round == null || round.done || round.escaped) return;
    round.escape = min(1.0, round.escape + dt / round.escapeSeconds);
    round.clock += dt;
    final tokens = round.wave.sentence.tokens.length;
    if (round.nextToken < tokens &&
        (round.columns.every((c) => c.passed != null) ||
            round.clock >= round.interval)) {
      round.columns.add(
          _Column(round.nextToken, round.wave.gate(round.nextToken, _rng)));
      round.nextToken++;
      round.clock = 0;
    }
    for (final column in [...round.columns]) {
      if (column.passed != null || column.t < round.travel) continue;
      _reachGates(geo, round, column);
      if (round.done || round.escaped) return;
    }
    if (round.escape >= 1) _escapes(geo, round);
  }

  /// A column reaches the pet: through the right gate or the wrong one.
  void _reachGates(_Geo geo, _ChaseRound round, _Column column) {
    final right = round.upper == column.gate.upper;
    final seat = _chaseSeat(geo, upper: round.upper);
    if (!right) {
      HapticFeedback.lightImpact();
      _refresh(() {
        column.passed = false;
        round.escape = min(0.97, round.escape + WitchRules.chaseMistakeBurn);
        _run = _run.fizzle();
        // The gates after it were for words the sentence has not got to:
        // gone, and this word offered again after a beat.
        round.columns.removeWhere((c) => c.passed == null);
        round.nextToken = column.token;
        round.clock = round.interval * 0.4;
      });
      if (!_reduceMotion) {
        _petHurt = 0;
        _particles.sparks(seat, count: 10, fizzle: true);
        // Knocked head over heels by the wall, backwards.
        _playMove(_PetMove.spin(turns: -1));
      }
      _pop('hex wall', _BossTrialScreenState._hurtRed, seat.translate(0, -50));
      return;
    }
    _refresh(() {
      column.passed = true;
      round.placed++;
    });
    if (!_reduceMotion) {
      _particles.sparks(seat, count: 8);
      // The broom wobbles as it goes through each gate; the last one goes into
      // the cast.
      if (_move == null) _playMove(_gateWobble());
    }
    if (round.placed < round.wave.sentence.tokens.length) return;

    // The whole spell, at her: the pet rears back on its broom, and thrusts.
    HapticFeedback.selectionClick();
    final earliness = 1 - round.escape;
    _refresh(() {
      round.done = true;
      _stage = _Stage.resolving;
      _stageTime = 0;
    });
    if (_reduceMotion) {
      _shoot(
        geo,
        _Shot(
          from: seat,
          earliness: earliness,
          whole: true,
          look: _ShotLook.spell,
        ),
      );
      return;
    }
    const windUp = _BossTrialScreenState._windUpSeconds;
    // She flees to the right: that is the way it throws — and the throw kicks
    // it and the broom back.
    final k = _Keyer();
    k.to(windUp, tilt: -0.38, squash: 0.9, dy: -2, ease: _Ease.accelerate);
    k.to(0.12, tilt: 0.44, squash: 1.0, dy: 6, dx: 6, ease: _Ease.out);
    final release = k.t;
    k.to(0.12, tilt: -0.5, dx: -16, squash: 0.92, ease: _Ease.out);
    k.to(0.1, tilt: -0.3, dx: -12);
    k.to(0.3, tilt: 0, dx: 0, dy: 0, squash: 1.0);
    _shots.add(_Shot(
      from: seat.translate(geo.petBox * 0.15, -geo.petBox * 0.3),
      earliness: earliness,
      whole: true,
      look: _ShotLook.spell,
      delay: release,
    ));
    _petFacesLeft = false;
    _playMove(_PetMove.keys(k.keys, faceLeft: false));
  }

  /// The broom shudders as it goes through a gate: tipped one way and the
  /// other, less each time.
  _PetMove _gateWobble() {
    final k = _Keyer();
    for (final lean in const [0.2, -0.2, 0.13, -0.08]) {
      k.to(0.09, tilt: lean, ease: _Ease.linear);
    }
    k.to(0.09, tilt: 0);
    return _PetMove.keys(k.keys);
  }

  void _escapes(_Geo geo, _ChaseRound round) {
    _refresh(() {
      round.escaped = true;
      round.columns.clear();
      _run = _run.castFailed(round.wave.sentence);
      _holdAftermath = true;
      _stage = _Stage.resolving;
      _stageTime = 0;
      _cackleTime = 0;
    });
    _strikePet(geo);
    if (_run.isOver) _endIn = 0.8;
  }

  void _animateWitchRounds(double dt, _Geo geo) {
    _clones?.t += dt;
    _tangle?.wordT += dt;
    final tangle = _tangle;
    if (tangle != null) {
      // Words the pet carried over drop into their pots, and fill them.
      for (final word in [...tangle.carried]) {
        word.t += dt;
        // It falls from where the pet's head is as it is let go.
        if (word.dropping && word.from == null) word.from = _carriedHead(geo);
        if (!word.landed) continue;
        tangle.carried.remove(word);
        if (word.first) {
          tangle.intoFirst++;
        } else {
          tangle.intoSecond++;
        }
        if (!_reduceMotion) {
          final pot = _cauldronRect(geo, first: word.first);
          _particles.sparks(
            Offset(pot.center.dx, pot.bottom - 50),
            count: 10,
            colors: HexPalette.splash,
          );
        }
      }
    }
    final round = _chase;
    if (round == null) return;
    for (final column in [...round.columns]) {
      column.t += dt;
      if (_gateX(geo, round, column) < -80) round.columns.remove(column);
    }
  }

  // ---- layout ----

  double _chasePromptTop(_Geo geo) => geo.groundTop - _Geo.promptH + 16;

  double _chaseLineTop(_Geo geo) =>
      min(geo.groundTop + 22, geo.h - _Geo.spellLineH - 2);

  double _laneY(_Geo geo, {required bool upper}) {
    final top = geo.ledgeTop;
    final bottom = _chasePromptTop(geo) - 12;
    return (top + (bottom - top) * (upper ? 0.26 : 0.74)).roundToDouble();
  }

  double _chasePetX(_Geo geo) => (geo.w * 0.19).roundToDouble();

  /// Where the pet's feet go to ride [upper] or the lower lane.
  Offset _chaseSeat(_Geo geo, {required bool upper}) => Offset(
        _chasePetX(geo),
        _laneY(geo, upper: upper) + geo.petBox * 0.6 * 0.4,
      );

  double _gateX(_Geo geo, _ChaseRound round, _Column column) {
    final start = geo.w + 70;
    final to = _chasePetX(geo);
    return start - (start - to) * column.t / round.travel;
  }

  List<Widget> _buildChaseBehind(_Geo geo, _ChaseRound round) {
    if (_stage == _Stage.jumping) return const [];
    final style =
        _pixel(10, _BossTrialScreenState._ink, localeCode: _languageCode);
    final laneH = (_laneY(geo, upper: false) - _laneY(geo, upper: true));
    final pieces = <Widget>[
      // The two lanes to fly in: a tap anywhere in one takes the pet there.
      for (final upper in const [true, false])
        Positioned(
          left: 0,
          right: 0,
          top: _laneY(geo, upper: upper) - laneH / 2,
          height: laneH,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _chaseLane(upper),
          ),
        ),
    ];
    for (final column in round.columns) {
      final x = _gateX(geo, round, column).roundToDouble();
      for (final upper in const [true, false]) {
        final right = column.gate.upper == upper;
        pieces.add(Positioned(
          left: x - 56,
          top: _laneY(geo, upper: upper) - 28,
          width: 112,
          height: 56,
          child: IgnorePointer(
            child: WordGate(
              label: right ? column.gate.word : column.gate.decoy,
              style: style,
              state: column.passed == null
                  ? HexPieceState.plain
                  : right
                      ? HexPieceState.right
                      : column.passed == false && upper == round.upper
                          ? HexPieceState.wrong
                          : HexPieceState.plain,
            ),
          ),
        ));
      }
    }
    return pieces;
  }

  List<Widget> _buildChaseFront(_Geo geo, _ChaseRound round) {
    if (_stage == _Stage.jumping) return const [];
    final tokens = round.wave.sentence.tokens;
    return [
      Positioned(
        left: _Geo.spellInset,
        right: _Geo.spellInset,
        top: _chasePromptTop(geo),
        height: _Geo.promptH,
        child: IgnorePointer(
          child: SpellPrompt(
            label: 'CHASE HER WITH',
            meaning: round.wave.sentence.meaning,
            labelStyle: _pixel(7, const Color(0xFF7A4E2D)),
            meaningStyle:
                _pixel(12, _BossTrialScreenState._ink, localeCode: _nativeCode),
          ),
        ),
      ),
      Positioned(
        left: _Geo.spellInset,
        right: _Geo.spellInset,
        top: _chaseLineTop(geo),
        height: _Geo.spellLineH,
        child: Center(
          child: SpellLine(
            slots: tokens.length,
            filled: tokens.take(round.placed).toList(),
            style:
                _pixel(10, DebrisPalette.runeLight, localeCode: _languageCode),
            glow: round.done,
            textDirection:
                _languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          ),
        ),
      ),
      Positioned(
        left: ((geo.w - geo.chargeW) / 2).roundToDouble(),
        top: geo.ledgeTop - _Geo.chargeH - 4,
        width: geo.chargeW,
        height: _Geo.chargeH,
        child: ChargeBar(charge: round.escape, color: HexPalette.hex),
      ),
    ];
  }

  List<Widget> _buildWitchRoundsBehind(_Geo geo) => [
        if (_clones case final round?) ..._buildClonesBehind(geo, round),
        if (_tangle case final round?) ..._buildTangleBehind(geo, round),
        if (_chase case final round?) ..._buildChaseBehind(geo, round),
      ];

  List<Widget> _buildWitchRoundsFront(_Geo geo) => [
        if (_clones case final round?) ..._buildClones(geo, round),
        if (_tangle case final round?) ..._buildTangleFront(geo, round),
        if (_chase case final round?) ..._buildChaseFront(geo, round),
      ];

  /// The witch's rounds are over. The pet hops off its broom first, when
  /// [dismount] — a round ending in play — and is simply back on the bank when
  /// not: a new run, or the end of this one.
  void _clearWitchRounds({bool dismount = false}) {
    _clones = null;
    _tangle = null;
    _chase = null;
    // Halfway down already: let it land.
    if (_hoppingOff && _move != null) return;
    final geo = _geo;
    if (dismount && _onBroom && !_reduceMotion && geo != null) {
      _hopOffBroom(geo);
      return;
    }
    _hoppingOff = false;
    _onBroom = false;
    _perch = null;
    _petFeet = null;
    _petScale = 1;
    _petFacesLeft = false;
  }

  /// Off the broom: it puffs away under the pet, which hops forward and falls
  /// to the bank — the further down it is, the longer the fall, to half a
  /// second — growing back to its full size as it comes down, lands with a
  /// squat, and trots home from where it lands.
  void _hopOffBroom(_Geo geo) {
    const forward = 24.0;
    final drop = geo.groundTop - (_petFeet ?? geo.groundTop);
    _onBroom = false;
    _hoppingOff = true;
    _particles.sparks(
      Offset(_petX, (_petFeet ?? geo.groundTop) - 8),
      count: 12,
      colors: HexPalette.sparks,
    );
    _playMove(_PetMove.leap(
      reach: const Offset(forward / 2, 22),
      back: Offset(forward, -drop),
      tilt: pi / 14,
      crouch: 0.06,
      rise: 0.14,
      hold: 0.04,
      fall: min(0.5, 0.28 + drop / 1400),
      squash: 0.1,
      shiver: 0,
      dip: 3,
      grow: true,
      onEnd: (geo) {
        // Landed on the bank, at full size, a stride on from where it left.
        _hoppingOff = false;
        _perch = null;
        _petFeet = null;
        _petScale = 1;
        _petX += forward;
        _particles.sparks(
          Offset(_petX, geo.groundTop),
          count: 8,
          colors: HexPalette.sparks,
        );
        // A squat to land, where it landed; then it trots home.
        const squat = 0.22;
        _petRunning = true;
        _stayPut(squat);
        _playMove(_PetMove.flatten(squash: 0.8, press: 0.1, spring: squat - 0.1));
      },
    ));
  }
}
