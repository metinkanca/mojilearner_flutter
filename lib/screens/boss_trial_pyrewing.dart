part of 'boss_trial_screen.dart';

// Pyrewing's openers under test: the Parley, the Flame Link, the Ember
// Paraphrase and the Hoard. The
// rules are in `utils/boss_trial_dragon.dart` and the content, English and
// Turkish for now, in `constants/boss_trial_en_tr.dart`; this is their clock,
// their layout and their taps. They share Sableth's talk panel and field
// (`boss_trial_sableth.dart`).

class _ParleyRound extends _ClockRound {
  _ParleyRound(this.wave, double seconds) : super(seconds);
  final ParleyWave wave;

  /// Which turn of the conversation it is on.
  int turn = 0;

  /// This turn's clock: every turn gets its own, as long as its words need.
  late double turnSeconds = seconds;

  final Set<int> wrong = {};

  ParleyTurn get current => wave.script.turns[turn];
}

class _LinkRound extends _ClockRound {
  _LinkRound(this.wave, double seconds) : super(seconds);
  final LinkWave wave;
  final Set<int> wrong = {};

  /// When ([t]) the right rune was picked, which stops the runes drifting, and
  /// when ([t]) the pet's lob lands on it and the flames are bridged.
  double? stoppedAt;
  double bridgeAt = double.infinity;
}

class _EmberRound extends _ClockRound {
  _EmberRound(this.wave, double seconds) : super(seconds);
  final ParaphraseWave wave;
  final Set<int> wrong = {};

  /// The ember the pet is catching, when ([t]) its head gets there, and when
  /// it flings it back at the boss.
  int? caught;
  double caughtAt = double.infinity;
  double flungAt = double.infinity;

  /// Whether ember [i] has burned out.
  bool isOut(int i) => clock >= wave.lives[i];
}

class _HoardRound extends _ClockRound {
  _HoardRound(this.wave, double seconds)
      : play = HoardPlay(wave),
        super(seconds);
  final HoardWave wave;
  final HoardPlay play;

  /// The two coins of a wrong pair, while they flash.
  (int, int)? refusedPair;

  /// The coins the pet has lifted off the hoard to carry, one trip each.
  final List<_CoinTrip> trips = [];

  /// Pairs got wrong, each of which opens the sleeping dragon's eye a little.
  int mistakes = 0;
}

/// A coin the pet carries: lifted off its place onto its head, ridden along,
/// and let go — back to its place, or on to its match.
class _CoinTrip {
  _CoinTrip(this.coin,
      {required this.since, required this.from, required this.size});

  final int coin;

  /// When ([_ClockRound.t]) it was lifted, from where, and how big it was.
  final double since;
  final Offset from;
  final Size size;

  /// When it is let go and where to, once it is; where it was let go from; and
  /// the coin it joins there, if it joins one.
  double? letGoAt;
  Offset? to;
  Offset? letGoFrom;
  int? joins;
  bool landed = false;

  /// Seconds to fly from the hoard onto the pet's head, and from there to
  /// where it is going.
  static const double lift = 0.22;
  static const double fly = 0.2;
}

extension _PyrewingFlow on _BossTrialScreenState {
  // ---- Parley ----

  void _beginParley() {
    final wave = ParleyWave.build(_enTr?.parleys ?? const [],
        previous: _lastAs<ParleyScript>(), random: _rng);
    if (wave == null) {
      _throwWave();
      return;
    }
    _beginClockRound(() {
      _parley = _ParleyRound(wave, _parleyTurnSeconds(wave.script.turns[0]));
      _lastAsked = wave.script;
    });
    // The pet keeps its distance to begin with, well back from the dragon.
    final geo = _geo;
    if (geo != null && !_reduceMotion) {
      _runTo(geo, _parleyStandAt(geo, 0, wave.script.turns.length), stay: 600);
    }
  }

  /// Where the pet stands for turn [turn] of [turns]: well back to start with,
  /// a step closer to the dragon with every reply, and right under it for the
  /// last.
  double _parleyStandAt(_Geo geo, int turn, int turns) =>
      (geo.w * (0.2 + 0.3 * turn / max(1, turns - 1))).roundToDouble();

  double _parleyTurnSeconds(ParleyTurn turn) => _BossTrialScreenState._secs(
      DragonRules.parleyTime(words: turn.words, patience: _clockPatience));

  void _tapReply(int i) {
    final round = _parley;
    final geo = _geo;
    if (_phase != _Phase.playing ||
        _stage != _Stage.parleying ||
        round == null ||
        geo == null ||
        round.over ||
        round.wrong.contains(i)) {
      return;
    }
    final options = round.wave.options[round.turn];
    final reply = _tabletRect(geo, i, options.length);
    if (i != round.wave.answers[round.turn]) {
      round.wrong.add(i);
      _refused(geo, round, i, DragonRules.parleyMistake, reply.center);
      if (!_reduceMotion) _shakeHead();
      return;
    }
    if (round.turn == round.wave.script.turns.length - 1) {
      // The whole conversation: the pet bows low, then casts a big spell.
      _answeredByBow(geo, round, reply);
      return;
    }
    // A turn answered: a nod, a sting from the reply, a step closer, and on
    // to the next thing it says.
    HapticFeedback.selectionClick();
    final earliness = 1 - round.clock;
    _refresh(() {
      round.turn++;
      round.wrong.clear();
      round.flashing = null;
      round.clock = 0;
      round.turnSeconds = _parleyTurnSeconds(round.current);
    });
    if (_reduceMotion) {
      _shoot(
        geo,
        _Shot(from: reply.center, earliness: earliness, look: _ShotLook.spell),
      );
      return;
    }
    final toward = _bossSide(geo, _petX);
    final toX = _parleyStandAt(geo, round.turn, round.wave.script.turns.length);
    final run = _runTo(geo, toX, stay: 600, pace: 0.36);
    final k = _Keyer();
    // It nods, twice — head down and up — as it takes its step.
    for (var n = 0; n < 2; n++) {
      k.to(0.1, tilt: toward * 0.32, squash: 0.94, dy: -1);
      k.to(0.1, tilt: 0, squash: 1.0, dy: 0);
    }
    if (run > k.t) k.hold(run - k.t);
    k.to(0.1, squash: 0.92);
    k.to(0.1, squash: 1.0);
    _shots.add(_Shot(
      from: reply.center,
      earliness: earliness,
      look: _ShotLook.spell,
      delay: 0.1,
    ));
    _playMove(_PetMove.keys(k.keys));
  }

  /// A wrong reply: the pet shakes its head, no.
  void _shakeHead() {
    final k = _Keyer();
    k.to(0.06, squash: 0.94);
    for (var n = 0; n < 6; n++) {
      k.to(0.08, tilt: n.isEven ? 0.3 : -0.3, ease: _Ease.linear);
    }
    k.to(0.1, tilt: 0, squash: 1.0);
    _playMove(_PetMove.keys(k.keys));
  }

  /// The last turn answered, the whole conversation: the pet bows low to the
  /// dragon and holds it, straightens, then rears back and casts a BIG spell.
  void _answeredByBow(_Geo geo, _ParleyRound round, Rect reply) {
    HapticFeedback.selectionClick();
    final earliness = 1 - round.clock;
    _refresh(() {
      round.won = true;
      _stage = _Stage.resolving;
      _stageTime = 0;
    });
    if (_reduceMotion) {
      _launch(
        geo,
        _Shot(
          from: reply.center,
          earliness: earliness,
          whole: true,
          big: true,
          look: _ShotLook.spell,
        ),
      );
      return;
    }
    final toward = _bossSide(geo, _petX);
    final k = _Keyer();
    // The bow: right down, head first, and held there.
    k.to(0.4, tilt: toward * 0.85, squash: 0.8, dy: -3);
    k.hold(0.5);
    // Then up, and the cast.
    k.to(0.25, tilt: 0, squash: 1.0, dy: 0);
    final cast = _throwKeys(k, toward: toward, windUp: 0.6);
    final from = _throwFrom(geo, _petX, toward);
    _shots.add(_Shot(
      from: from,
      earliness: earliness,
      whole: true,
      big: true,
      look: _ShotLook.spell,
      delay: cast,
    ));
    _petFacesLeft = toward < 0;
    _playMove(_PetMove.keys(
      k.keys,
      faceLeft: toward < 0,
      events: [
        _MoveEvent(cast, (geo) {
          _shake = max(_shake, 0.12);
          _particles.sparks(from, count: 16, colors: DragonPalette.sparks);
        }),
      ],
    ));
  }

  List<Widget> _buildParley(_Geo geo, _ParleyRound round) {
    if (_stage == _Stage.jumping) return const [];
    final turn = round.current;
    final options = round.wave.options[round.turn];
    final n = options.length;
    final style =
        _pixel(9, _BossTrialScreenState._ink, localeCode: _languageCode);
    return [
      _talk(geo, turn.line, round.clock,
          label: 'ANSWER IT · ${round.turn + 1} OF '
              '${round.wave.script.turns.length}'),
      for (var i = 0; i < n; i++)
        Positioned.fromRect(
          rect: _tabletRect(geo, i, n),
          child: SkinTile(
            skin: _boss.skin,
            label: options[i],
            style: style,
            state: round.isFlashing(i)
                ? TileState.flashing
                : round.over && i == round.wave.answers[round.turn]
                    ? TileState.right
                    : round.wrong.contains(i)
                        ? TileState.wrong
                        : TileState.plain,
            onTapDown: () => _tapReply(i),
          ),
        ),
    ];
  }

  // ---- Flame Link ----

  void _beginLink() {
    final wave = LinkWave.build(_enTr?.links ?? const [],
        previous: _lastAs<LinkItem>(), random: _rng);
    if (wave == null) {
      _throwWave();
      return;
    }
    _beginClockRound(() {
      _link = _LinkRound(
        wave,
        _BossTrialScreenState._secs(DragonRules.linkTime(
            words: wave.item.words, patience: _clockPatience)),
      );
      _lastAsked = wave.item;
    });
  }

  /// The field in three: the first flame, the runes, the second flame.
  Rect _flameRect(_Geo geo, {required bool first}) {
    final space = _fieldBottom(geo) - _fieldTop(geo);
    final h = min(48.0, (space - 16) / 3).floorToDouble();
    final top = first
        ? _fieldTop(geo)
        : _fieldTop(geo) + space - h;
    final w = min(geo.w - 2 * _Geo.spellInset, 360.0);
    return Rect.fromLTWH(((geo.w - w) / 2).roundToDouble(), top, w, h);
  }

  /// Rune [i] of [n], drifting side to side between the flames.
  Rect _runeRect(_Geo geo, _LinkRound round, int i, int n) {
    final a = _flameRect(geo, first: true), b = _flameRect(geo, first: false);
    final h = min(runeStoneHeight, b.top - a.bottom - 12).floorToDouble();
    final w = ((geo.w - 32 - 8 * (n - 1)) / n).clamp(60.0, 120.0);
    final span = w * n + 8 * (n - 1);
    final drift = sin((round.stoppedAt ?? round.t) * 1.3) *
        max(0.0, (geo.w - span) / 2 - 10);
    return Rect.fromLTWH(
      ((geo.w - span) / 2 + i * (w + 8) + drift).roundToDouble(),
      ((a.bottom + b.top - h) / 2).roundToDouble(),
      w,
      h,
    );
  }

  void _tapRune(int i) {
    final round = _link;
    final geo = _geo;
    if (_phase != _Phase.playing ||
        _stage != _Stage.linking ||
        round == null ||
        geo == null ||
        round.over ||
        round.wrong.contains(i)) {
      return;
    }
    final rune = _runeRect(geo, round, i, round.wave.runes.length);
    if (i != round.wave.answer) {
      round.wrong.add(i);
      _refused(geo, round, i, DragonRules.linkMistake, rune.center);
      if (!_reduceMotion) _cringeAt(rune.center);
      return;
    }
    round.stoppedAt = round.t;
    _answeredByLob(geo, round, rune);
  }

  /// The rune that joins the flames picked: the pet rears right back, arched
  /// on its toes, and lobs a bolt at it overhand, snapping forward off the
  /// ground and coming down on its paws; where the bolt lands a bridge of light
  /// forms between the flames, and the spell leaves the rune for the boss.
  void _answeredByLob(_Geo geo, _LinkRound round, Rect rune) {
    HapticFeedback.selectionClick();
    final earliness = 1 - round.clock;
    _refresh(() {
      round.won = true;
      _stage = _Stage.resolving;
      _stageTime = 0;
    });
    void join() {
      if (_reduceMotion) return;
      for (final first in [true, false]) {
        _particles.sparks(_flameRect(geo, first: first).center,
            count: 10, colors: DragonPalette.sparks);
      }
    }

    // The spell leaves the rune once the bridge has formed.
    final spell = _Shot(
      from: rune.center,
      earliness: earliness,
      whole: true,
      look: _ShotLook.spell,
      delay: _reduceMotion ? 0 : 0.3,
    );
    if (_reduceMotion) {
      round.bridgeAt = round.t - 5;
      join();
      _shoot(geo, spell);
      return;
    }
    final toward = _bossSide(geo, _petX);
    final k = _Keyer();
    // Rears right back, arched, up on its toes, and holds it there...
    k.to(0.45, tilt: -toward * 0.55, squash: 0.92, dy: 6);
    k.hold(0.25);
    // ...and snaps forward, leaving the ground, the arm coming over the top...
    k.to(0.1, tilt: toward * 0.45, squash: 1.1, dy: 18, ease: _Ease.out);
    final lob = k.t;
    // ...follows through, and lands on its paws.
    k.to(0.12, tilt: toward * 0.6, squash: 0.95);
    k.to(0.22, tilt: toward * 0.1, dy: 0, squash: 0.8, ease: _Ease.accelerate);
    k.to(0.2, tilt: 0, squash: 1.0);
    const flight = 0.5;
    round.bridgeAt = round.t + lob + flight;
    // The bolt goes from the pet's hands to the rune; the spell goes on from
    // there when it lands.
    _shots.add(_Shot(
      from: _throwFrom(geo, _petX, toward),
      to: rune.center,
      earliness: earliness,
      look: _ShotLook.spell,
      delay: lob,
      seconds: flight,
      onLand: (geo) {
        join();
        _shots.add(spell);
      },
    ));
    _petFacesLeft = toward < 0;
    _stayPut(k.t + 0.3);
    _playMove(_PetMove.keys(k.keys, faceLeft: toward < 0));
  }

  List<Widget> _buildLink(_Geo geo, _LinkRound round) {
    if (_stage == _Stage.jumping) return const [];
    final wave = round.wave;
    final n = wave.runes.length;
    final clause =
        _pixel(9, _boss.skin.colors.ink, localeCode: _languageCode);
    final runeStyle =
        _pixel(10, _BossTrialScreenState._ink, localeCode: _languageCode);
    Widget flame(String text, bool first) => Positioned.fromRect(
          rect: _flameRect(geo, first: first),
          child: IgnorePointer(
            child: SkinPanel(
              skin: _boss.skin,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(text, maxLines: 1, style: clause),
                ),
              ),
            ),
          ),
        );
    return [
      _talk(
        geo,
        round.won || round.lost ? wave.item.joined : 'Join my flames.',
        round.clock,
        label: 'THROW THE RUNE THAT JOINS THEM',
      ),
      flame(wave.item.left, true),
      flame(wave.item.right, false),
      // The bridge of light the pet's lob made between them.
      if (round.t >= round.bridgeAt)
        () {
          final rune = _runeRect(geo, round, wave.answer, n);
          return Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: BridgePainter(
                  progress: (round.t - round.bridgeAt) / 0.35,
                  x: rune.center.dx,
                  top: _flameRect(geo, first: true).bottom,
                  rune: rune,
                  bottom: _flameRect(geo, first: false).top,
                ),
              ),
            ),
          );
        }(),
      for (var i = 0; i < n; i++)
        Positioned.fromRect(
          rect: _runeRect(geo, round, i, n),
          child: SkinTile(
            skin: _boss.skin,
            shape: TileShape.rune,
            label: wave.runes[i],
            style: runeStyle,
            state: round.isFlashing(i)
                ? TileState.flashing
                : round.over && i == wave.answer
                    ? TileState.right
                    : round.wrong.contains(i)
                        ? TileState.wrong
                        : TileState.plain,
            onTapDown: () => _tapRune(i),
          ),
        ),
    ];
  }

  // ---- Ember Paraphrase ----

  void _beginEmbers() {
    final wave = ParaphraseWave.build(_enTr?.paraphrases ?? const [],
        previous: _lastAs<ParaphraseItem>(), random: _rng);
    if (wave == null) {
      _throwWave();
      return;
    }
    _beginClockRound(() {
      _embers = _EmberRound(
        wave,
        _BossTrialScreenState._secs(DragonRules.paraphraseTime(
            words: wave.item.words, patience: _clockPatience)),
      );
      _lastAsked = wave.item;
    });
  }

  /// Ember [i] of [n], rising slowly up the field as it burns, and
  /// shrinking as it goes. All three burn down with the clock alike — one
  /// shrinking faster would mark the ember that goes out early as wrong.
  Rect _emberRect(_Geo geo, _EmberRound round, int i, int n) {
    final base = _tabletRect(geo, i, n);
    final burnt = round.clock.clamp(0.0, 1.0);
    final rise = (burnt * 10).roundToDouble();
    final narrow = (base.width * 0.12 * burnt).roundToDouble();
    return Rect.fromLTRB(base.left + narrow, base.top - rise,
        base.right - narrow, base.bottom - rise);
  }

  void _tapEmber(int i) {
    final round = _embers;
    final geo = _geo;
    if (_phase != _Phase.playing ||
        _stage != _Stage.embering ||
        round == null ||
        geo == null ||
        round.over ||
        round.isOut(i) ||
        round.wrong.contains(i)) {
      return;
    }
    final ember = _emberRect(geo, round, i, round.wave.embers.length);
    if (i != round.wave.answer) {
      round.wrong.add(i);
      // A wrong one burns the rest down faster, and singes the pet's
      // whiskers.
      _refused(geo, round, i, DragonRules.paraphraseMistake, ember.center);
      if (!_reduceMotion) _singedBy(geo, ember);
      return;
    }
    _catchEmber(geo, round, i, ember);
  }

  /// What it takes for the pet to get its head up under [ember].
  Offset _underEmber(_Geo geo, Rect ember) => _reachTo(
        geo,
        _withinLeap(geo, Offset(ember.center.dx, ember.bottom - _headInto),
            most: geo.petBox * 2.6),
      );

  /// The right ember: the pet LEAPS up and snatches it out of the air, comes
  /// down hugging it, rears back and FLINGS it at the boss as a fireball.
  void _catchEmber(_Geo geo, _EmberRound round, int i, Rect ember) {
    HapticFeedback.selectionClick();
    final earliness = 1 - round.clock;
    _refresh(() {
      round.won = true;
      round.caught = i;
      _stage = _Stage.resolving;
      _stageTime = 0;
    });
    if (_reduceMotion) {
      round.caughtAt = round.t - 5;
      round.flungAt = round.t - 5;
      _shoot(
        geo,
        _Shot(
          from: ember.center,
          earliness: earliness,
          whole: true,
          look: _ShotLook.ember,
        ),
      );
      return;
    }
    final reach = _underEmber(geo, ember);
    final aside = reach.dx.abs() > 8;
    final dir = aside ? reach.dx.sign : 0.0;
    final toward = _bossSide(geo, _petX);
    final up = max(0.0, reach.dy - _stretchRise(geo, 1.15));
    final k = _Keyer();
    k.to(0.06, squash: 0.88, dy: -2);
    k.to(0.2 + reach.dy / 1000,
        dx: reach.dx,
        dy: up,
        squash: 1.15,
        tilt: dir * 0.2,
        ease: _Ease.out);
    final catchAt = k.t;
    // Snatches it...
    k.hold(0.06);
    // ...comes down with it held to its chest...
    k.to(0.32,
        dx: 0,
        dy: 0,
        tilt: -toward * 0.15,
        squash: 0.85,
        ease: _Ease.accelerate);
    // ...rears back, and throws it.
    k.to(0.14, tilt: -toward * 0.5, squash: 0.95);
    k.to(0.1, tilt: toward * 0.5, squash: 1.0, dy: 8, ease: _Ease.out);
    final fling = k.t;
    k.hold(0.06);
    k.to(0.2, tilt: 0, dy: 0);
    round.caughtAt = round.t + catchAt;
    round.flungAt = round.t + fling;
    _shots.add(_Shot(
      from: _throwFrom(geo, _petX, toward),
      earliness: earliness,
      whole: true,
      look: _ShotLook.ember,
      delay: fling,
    ));
    _stayPut(k.t + 0.2);
    _faceToward(ember.center.dx, from: _petX, deadzone: 12);
    _playMove(_PetMove.keys(
      k.keys,
      events: [
        _MoveEvent(catchAt, (geo) {
          _particles.sparks(ember.center,
              count: 10, colors: DragonPalette.sparks);
        }),
        _MoveEvent(catchAt + 0.3, (geo) => _petFacesLeft = toward < 0),
      ],
    ));
  }

  /// A wrong ember: the pet leaps for it just the same, and it FLARES in its
  /// face — the whiskers singed, smoking — and it is thrown back off it, tipped
  /// away, to land coughing.
  void _singedBy(_Geo geo, Rect ember) {
    final reach = _underEmber(geo, ember);
    final aside = reach.dx.abs() > 8;
    final dir = aside ? reach.dx.sign : 0.0;
    final away = aside ? -dir : -_bossSide(geo, _petX);
    final up = max(0.0, reach.dy - _stretchRise(geo, 1.15));
    final k = _Keyer();
    k.to(0.06, squash: 0.88, dy: -2);
    k.to(0.2 + reach.dy / 1000,
        dx: reach.dx,
        dy: up,
        squash: 1.15,
        tilt: dir * 0.2,
        ease: _Ease.out);
    final flare = k.t;
    k.to(0.14,
        dx: reach.dx + away * 8,
        dy: max(0.0, up - 8),
        tilt: away * 0.55,
        squash: 0.9,
        ease: _Ease.out);
    k.to(0.3, dx: 0, dy: 0, tilt: away * 0.2, squash: 0.82, ease: _Ease.accelerate);
    k.to(0.2, tilt: 0, squash: 1.0);
    _stayPut(k.t + 0.2);
    _faceToward(ember.center.dx, from: _petX, deadzone: 12);
    _playMove(_PetMove.keys(
      k.keys,
      events: [
        _MoveEvent(flare, (geo) {
          _shake = max(_shake, 0.1);
          _singed = _BossTrialScreenState._singeSeconds;
          _particles.sparks(ember.center,
              count: 10, colors: DragonPalette.sparks);
          _particles.sparks(_petRect(geo).center.translate(0, -geo.petBox * 0.1),
              count: 8, colors: DragonPalette.smoke);
        }),
      ],
    ));
  }

  /// An ember going out: a puff of smoke where it was.
  void _stepEmbers(_Geo geo, _EmberRound round, double before) {
    for (var i = 0; i < round.wave.embers.length; i++) {
      final life = round.wave.lives[i];
      if (before < life && round.clock >= life && !_reduceMotion) {
        _particles.sparks(
            _emberRect(geo, round, i, round.wave.embers.length).center,
            count: 10,
            colors: DragonPalette.smoke);
      }
    }
  }

  List<Widget> _buildEmbers(_Geo geo, _EmberRound round) {
    if (_stage == _Stage.jumping) return const [];
    final wave = round.wave;
    final n = wave.embers.length;
    final style =
        _pixel(9, _BossTrialScreenState._ink, localeCode: _languageCode);
    return [
      _talk(geo, wave.item.line, round.clock,
          label: 'WHICH MEANS THE SAME?'),
      for (var i = 0; i < n; i++)
        if (!round.isOut(i) || (round.lost && i == wave.answer))
          Positioned.fromRect(
            rect: _emberRect(geo, round, i, n),
            child: SkinTile(
              skin: _boss.skin,
              label: wave.embers[i],
              style: style,
              state: i == round.caught && round.t >= round.caughtAt
                  // The pet has it.
                  ? TileState.spent
                  : round.isFlashing(i)
                      ? TileState.flashing
                      : round.over && i == wave.answer
                          ? TileState.right
                          : round.wrong.contains(i)
                              ? TileState.wrong
                              : TileState.plain,
              onTapDown: () => _tapEmber(i),
            ),
          ),
    ];
  }

  // ---- Hoard ----

  void _beginHoard() {
    final content = _enTr;
    final wave = content == null
        ? null
        : HoardWave.build(content.phrases,
            alsoFit: content.alsoFit, random: _rng);
    if (wave == null) {
      _throwWave();
      return;
    }
    _beginClockRound(() {
      _hoard = _HoardRound(
          wave, _BossTrialScreenState._secs(DragonRules.hoardTime(_clockPatience)));
    });
  }

  /// Coin [i]'s box: four to a row, two rows, in the field.
  Rect _coinRect(_Geo geo, int i) {
    const gap = 8.0;
    const cols = 4;
    final rows = (DragonRules.hoardPairs * 2 / cols).ceil();
    final w = min(geo.w - 16, 420.0);
    final cw = ((w - gap * (cols - 1)) / cols).floorToDouble();
    final space = _fieldBottom(geo) - _fieldTop(geo);
    final ch = min(48.0, (space - gap * (rows - 1)) / rows).floorToDouble();
    final left = ((geo.w - (cw * cols + gap * (cols - 1))) / 2).roundToDouble();
    final top = _fieldTop(geo) +
        ((space - ch * rows - gap * (rows - 1)) / 2).roundToDouble();
    return Rect.fromLTWH(
        left + (i % cols) * (cw + gap), top + (i ~/ cols) * (ch + gap), cw, ch);
  }

  void _tapCoin(int i) {
    final round = _hoard;
    final geo = _geo;
    if (_phase != _Phase.playing ||
        _stage != _Stage.hoarding ||
        round == null ||
        geo == null ||
        round.over) {
      return;
    }
    switch (round.play.tap(i)) {
      case HoardTap.ignored:
        return;
      case HoardTap.held:
        HapticFeedback.selectionClick();
        _refresh();
        // The coin lifts off the hoard onto the pet's head: it hops, quietly,
        // to catch it.
        if (!_reduceMotion) {
          final coin = _coinRect(geo, i);
          round.trips.add(_CoinTrip(i,
              since: round.t, from: coin.center, size: coin.size));
          _playMove(_quietHop());
        }
      case HoardTap.dropped:
        HapticFeedback.selectionClick();
        _refresh();
        if (!_reduceMotion) {
          _putBack(geo, round, i);
          _playMove(_quietHop());
        }
      case HoardTap.mismatched:
        final (a, b) = round.play.lastPair!;
        round.refusedPair = (a, b);
        round.mistakes++;
        _refused(geo, round, a, DragonRules.hoardMistake,
            _coinRect(geo, b).center,
            said: 'no');
        round.flashing = null;
        if (!_reduceMotion) {
          _putBack(geo, round, a);
          _cringeAt(_coinRect(geo, b).center);
        }
      case HoardTap.matched:
        final (a, b) = round.play.lastPair!;
        final at = Offset.lerp(
            _coinRect(geo, a).center, _coinRect(geo, b).center, 0.5)!;
        HapticFeedback.selectionClick();
        final earliness = 1 - round.clock;
        _refresh(() {
          if (round.play.isCleared) {
            round.won = true;
            _stage = _Stage.resolving;
            _stageTime = 0;
          }
        });
        if (_reduceMotion) {
          _shoot(
              geo, _Shot(from: at, earliness: earliness, look: _ShotLook.gem));
          return;
        }
        _carryToMatch(geo, round, a, b, at, earliness);
    }
  }

  /// A small quiet hop, up on its toes: catching a coin, putting one back.
  _PetMove _quietHop() {
    final k = _Keyer();
    k.to(0.06, squash: 0.95);
    k.to(0.1, dy: 8, squash: 1.06, ease: _Ease.out);
    k.to(0.1, dy: 0, squash: 1.0, ease: _Ease.accelerate);
    return _PetMove.keys(k.keys);
  }

  /// The coin [a] the pet was carrying goes back where it came from.
  void _putBack(_Geo geo, _HoardRound round, int a) {
    final trip = round.trips
        .where((t) => t.coin == a && t.letGoAt == null)
        .firstOrNull;
    if (trip == null) return;
    trip.letGoAt = round.t;
    trip.to = _coinRect(geo, a).center;
  }

  /// A pair found: the pet TIPTOES under the second coin with the first on its
  /// head, in small quiet hops, rises up on its toes and lifts it to its
  /// match; the two clink together, and the pair goes at the boss.
  void _carryToMatch(_Geo geo, _HoardRound round, int a, int b, Offset at,
      double earliness) {
    final trip = round.trips
        .where((t) => t.coin == a && t.letGoAt == null)
        .firstOrNull;
    final target = _coinRect(geo, b);
    final half = geo.petBox / 2;
    final toX = target.center.dx.clamp(half - 6, geo.w - half + 6).toDouble();
    // A tiptoe, however far: never longer than a second.
    final pace = max(0.5, (toX - _petX).abs() / geo.w);
    final run = _runTo(geo, toX, stay: 1.2, pace: pace, hop: 4);
    final reach = _underEmber(geo, target);
    final up = max(0.0, reach.dy - _stretchRise(geo, 1.15));
    final k = _Keyer();
    // Up on its toes the whole way...
    k.to(0.1, squash: 1.05);
    if (run > k.t) k.hold(run - k.t);
    // ...then a quiet crouch, and up, lifting the coin to its match.
    k.to(0.06, squash: 0.9, dy: -2);
    k.to(0.16 + reach.dy / 1400, dy: up, squash: 1.15, ease: _Ease.out);
    final join = k.t;
    k.hold(0.08);
    k.to(0.3, dy: 0, squash: 0.9, ease: _Ease.accelerate);
    k.to(0.12, squash: 1.0);
    if (trip != null) {
      trip.letGoAt = round.t + join;
      trip.to = target.center;
      trip.joins = b;
    }
    _shots.add(_Shot(
      from: at,
      earliness: earliness,
      look: _ShotLook.gem,
      delay: join + _CoinTrip.fly,
    ));
    _playMove(_PetMove.keys(k.keys, events: [
      _MoveEvent(join, (geo) {
        _particles.sparks(target.center, count: 10, colors: DragonPalette.sparks);
      }),
    ]));
  }

  /// Where [trip]'s coin is: lifted off the hoard onto the pet's head, riding
  /// there, or — let go — flying on to where it is going.
  Offset _tripAt(_Geo geo, _HoardRound round, _CoinTrip trip) {
    final ride = _plaqueRide(geo, trip.size * 0.6);
    final letGo = trip.letGoAt;
    if (letGo == null || round.t < letGo) {
      final up = _smooth((round.t - trip.since) / _CoinTrip.lift);
      return Offset.lerp(trip.from, ride, up)!;
    }
    final k = ((round.t - letGo) / _CoinTrip.fly).clamp(0.0, 1.0);
    return Offset.lerp(trip.letGoFrom ?? ride, trip.to!, k * (2 - k))!;
  }

  /// How far the sleeping dragon's eye is open: a little with the clock, and a
  /// good deal more with each pair got wrong.
  double _hoardEyeOpen(_HoardRound round) =>
      min(1.0, 0.5 * round.clock + 0.17 * round.mistakes);

  /// The game-clock side of the hoard: a coin let go from the pet's head where
  /// it is, and one landing.
  void _stepDragonFx(double dt, _Geo geo) {
    final round = _hoard;
    if (round == null) return;
    for (final trip in round.trips) {
      final letGo = trip.letGoAt;
      if (letGo == null || trip.landed) continue;
      if (trip.letGoFrom == null && round.t >= letGo) {
        trip.letGoFrom = _plaqueRide(geo, trip.size * 0.6);
      }
      if (round.t >= letGo + _CoinTrip.fly) {
        trip.landed = true;
        if (trip.joins == null) {
          _particles.sparks(trip.to!, count: 5, colors: DragonPalette.sparks);
        }
      }
    }
  }

  /// What is drawn over the pet: the coins it carries, and the ember it has
  /// caught.
  List<Widget> _buildDragonFront(_Geo geo) {
    final hoard = _hoard;
    final embers = _embers;
    final style =
        _pixel(9, _BossTrialScreenState._ink, localeCode: _languageCode);
    return [
      if (hoard != null && _stage != _Stage.jumping)
        for (final trip in hoard.trips)
          if (!trip.landed)
            () {
              final size = trip.size * 0.6;
              final at = _tripAt(geo, hoard, trip);
              return Positioned(
                key: ValueKey('trip-${trip.coin}'),
                left: (at.dx - size.width / 2).roundToDouble(),
                top: (at.dy - size.height / 2).roundToDouble(),
                width: size.width.roundToDouble(),
                height: size.height.roundToDouble(),
                child: IgnorePointer(
                  child: SkinTile(
                    skin: _boss.skin,
                    shape: TileShape.coin,
                    label: hoard.wave.coins[trip.coin].text,
                    style: style,
                    state: TileState.held,
                    onTapDown: null,
                  ),
                ),
              );
            }(),
      // The ember it has caught, held up over its head till it is thrown.
      if (embers != null &&
          embers.caught != null &&
          embers.t >= embers.caughtAt &&
          embers.t < embers.flungAt)
        () {
          final at = _plaqueRide(geo, const Size(30, 30)).translate(0, -6);
          return Positioned(
            key: const ValueKey('held-ember'),
            left: (at.dx - 15).roundToDouble(),
            top: (at.dy - 15).roundToDouble(),
            width: 30,
            height: 30,
            child: const IgnorePointer(child: FireballSprite()),
          );
        }(),
    ];
  }

  List<Widget> _buildHoard(_Geo geo, _HoardRound round) {
    if (_stage == _Stage.jumping) return const [];
    final coins = round.wave.coins;
    final refused = round.refusedPair;
    final flashing = refused != null && round.t - round.flashAt < 0.3;
    final style =
        _pixel(9, _BossTrialScreenState._ink, localeCode: _languageCode);
    return [
      _talk(
        geo,
        round.lost
            ? round.play.unfound.map((p) => p.phrase).join(' · ')
            : 'Pair up the halves before it wakes.',
        round.clock,
        label: round.lost ? 'IT WOKE UP' : 'ITS HOARD',
      ),
      for (var i = 0; i < coins.length; i++)
        () {
          // A coin the pet is carrying has left the hoard, but a ghost of it
          // stays where it was: tap that to put it back. One being flown to
          // its match or back is off the hoard until it lands; the one the
          // pet is carrying another to waits there till it arrives.
          final trip =
              round.trips.where((t) => t.coin == i && !t.landed).firstOrNull;
          final riding = trip != null && trip.letGoAt == null;
          final away = trip != null && !riding;
          final awaiting = round.trips.any((t) => t.joins == i && !t.landed);
          return Positioned.fromRect(
            rect: _coinRect(geo, i),
            child: Opacity(
              opacity: riding ? 0.3 : 1,
              child: SkinTile(
                skin: _boss.skin,
                shape: TileShape.coin,
                label: coins[i].text,
                style: style,
                state: away || (round.play.isPaired(i) && !awaiting)
                    ? TileState.spent
                    : flashing && (refused.$1 == i || refused.$2 == i)
                        ? TileState.flashing
                        : round.play.held == i
                            ? TileState.held
                            : TileState.plain,
                onTapDown: () => _tapCoin(i),
              ),
            ),
          );
        }(),
    ];
  }

  // ---- all three ----

  void _stepDragonRound(double dt, _Geo geo) {
    final _ClockRound? round = _parley ?? _link ?? _embers ?? _hoard;
    if (round == null || round.over) return;
    final seconds = round is _ParleyRound ? round.turnSeconds : round.seconds;
    final before = round.clock;
    round.clock = min(1.0, round.clock + dt / seconds);
    if (round case final _EmberRound embers) {
      _stepEmbers(geo, embers, before);
    }
    if (round.clock < 1) return;
    switch (round) {
      case _ParleyRound r:
        _timedOut(geo, r, r.current.asSentence);
      case _LinkRound r:
        _timedOut(geo, r, r.wave.item.asSentence);
      case _EmberRound r:
        _timedOut(geo, r, r.wave.item.asSentence);
      case _HoardRound r:
        // Every phrase it slept on is one to practise.
        final unfound = r.play.unfound;
        _refresh(() {
          r.lost = true;
          _run = _run.struck(unfound.first.asWord);
          for (final p in unfound.skip(1)) {
            _run = _run.wordSlip(p.asWord);
          }
          _holdAftermath = true;
          _stage = _Stage.resolving;
          _stageTime = 0;
          _cackleTime = 0;
        });
        _strikePet(geo);
        if (_run.isOver) _endIn = 0.8;
    }
  }

  /// The heat the clock has put on the pet so far: nothing until it is
  /// two-thirds through, then ash creeping over it, a third of the way to
  /// scorched by the time it is out.
  double _heat() {
    final _ClockRound? round = _parley ?? _link ?? _embers ?? _hoard;
    if (round == null || round.over || _reduceMotion) return 0;
    if (round.clock < 0.6) return 0;
    return 0.3 * _smooth((round.clock - 0.6) / 0.4);
  }

  /// How much of the ash is on the pet, 0 to 1: the creep the clock has put
  /// on it, and, once the curse has landed, the rest of it taking hold.
  double _scorchFill() {
    if (_scorched <= 0) return _heat();
    if (_reduceMotion) return 1;
    final since = _BossTrialScreenState._curseSeconds - _scorched;
    final takes = _smooth(since / _BossTrialScreenState._curseForms);
    // Shaken off, in the last second, till it is gone.
    return (_scorchFrom + (1 - _scorchFrom) * takes) *
        (1 - _shedK(_scorched));
  }

  /// Something of Pyrewing's got through: the pet is scorched — the ash takes
  /// hold of it — and it coughs and shakes in it a while.
  void _scorch(_Geo geo) {
    HapticFeedback.heavyImpact();
    _scorchFrom = _heat();
    _scorched = _BossTrialScreenState._curseSeconds;
    _hurtTint = 0.3;
    // Whatever its body was doing stops, and a run stops where it had got to.
    _move = null;
    if (_petRunning || _petGoX != null || _petLane != null) {
      _petGoX = _petX;
      _petLane = null;
      _petAway = _BossTrialScreenState._curseSeconds;
    }
    if (!_reduceMotion) {
      _shake = 0.35;
      _petHurt = 0;
      _particles.sparks(_petRect(geo).center,
          count: 16, colors: DragonPalette.sparks);
    }
    _pop('scorched', _BossTrialScreenState._hurtRed,
        Offset(_petX, geo.groundTop - geo.petBox - 8));
  }

  List<Widget> _buildDragonRounds(_Geo geo) => [
        if (_parley case final round?) ..._buildParley(geo, round),
        if (_link case final round?) ..._buildLink(geo, round),
        if (_embers case final round?) ..._buildEmbers(geo, round),
        if (_hoard case final round?) ..._buildHoard(geo, round),
      ];

  void _clearDragonRounds() {
    // The pet that was keeping its distance, or tiptoeing, goes home — unless
    // it is under a curse and must stay put till that has run its course.
    if ((_parley != null || _hoard != null) && _scorched <= 0) {
      _petAway = min(_petAway, 0.2);
    }
    _parley = null;
    _link = null;
    _embers = null;
    _hoard = null;
  }
}
