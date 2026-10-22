part of 'boss_trial_screen.dart';

// Sableth's openers under test: the Riddle, the Sealed Door and the Tablets.
// The rules are in `utils/boss_trial_sphinx.dart` and the content, English
// and Turkish for now, in `constants/boss_trial_en_tr.dart`; this is their
// clock, their layout and their taps, on the screen's own game clock.
//
// Every round here, and Pyrewing's, puts its words on a TalkPanel in the sky
// over the boss and keeps the field between the ledge and the pet for what
// is tapped: on a small phone that field is barely three tablets tall.

/// What every sand-clock round keeps: its clock, and a flash on a refusal.
abstract class _ClockRound {
  _ClockRound(this.seconds);

  /// Seconds the clock takes to run out, fixed when the round began.
  final double seconds;

  /// How far it has run: 0 to 1.
  double clock = 0;

  /// Seconds since it began.
  double t = 0;

  /// The piece just refused, and when.
  int? flashing;
  double flashAt = -1;

  /// Answered, or out of time: either way, nothing more can be tapped.
  bool won = false;
  bool lost = false;
  bool get over => won || lost;

  bool isFlashing(int i) => flashing == i && t - flashAt < 0.3;

  void refuse(int i, double cost) {
    flashing = i;
    flashAt = t;
    clock = min(0.97, clock + cost);
  }
}

class _RiddleRound extends _ClockRound {
  _RiddleRound(this.wave, double seconds) : super(seconds);
  final RiddleWave wave;
  final Set<int> wrong = {};

  /// The tablet the pet stamped, and when ([t]) its head hits it.
  int? stamped;
  double stampedAt = 0;

  /// The tablets the pet rammed that cracked, and when ([t]) each did.
  final Map<int, double> cracked = {};
}

class _DoorRound extends _ClockRound {
  _DoorRound(this.wave, double seconds)
      : dial = wave.start,
        super(seconds);
  final DoorWave wave;
  int dial;

  /// The pet has burst the door.
  bool broken = false;
}

class _StormRound extends _ClockRound {
  _StormRound(this.wave, double seconds) : super(seconds);
  final StormWave wave;

  /// Where a swipe started, and the cells it covers now.
  int? anchor;
  List<int> swiped = const [];

  /// Swipes that found nothing, left dimmed on the sand a moment.
  List<int> refusedCells = const [];

  /// The word the pet howled the sand off, and when ([t]) its howl begins and
  /// the sand leaves the word.
  List<int> blown = const [];
  double howledAt = double.infinity;
  double blownAt = double.infinity;

  bool get isBlown => t >= blownAt;
}

class _TabletRound extends _ClockRound {
  _TabletRound(this.wave, double seconds)
      : play = TabletPlay(wave),
        super(seconds);
  final TabletWave wave;
  final TabletPlay play;

  /// The tablets the pet has taken off the stack to carry to their places on
  /// the slot rail, in the order it took them.
  final List<_Plaque> plaques = [];
}

/// A tablet the pet carries, shrunk to a plaque: taken off the stack, ridden
/// on the pet's head to its slot, and dropped in with a squash.
class _Plaque {
  _Plaque(
    this.slot, {
    required this.since,
    required this.from,
    required this.size,
    required this.ridesFor,
  });

  /// Its place in the story, which is the slot it goes to.
  final int slot;

  /// When ([_ClockRound.t]) the pet took it, from where on the stack, and how
  /// big the tablet was there.
  final double since;
  final Offset from;
  final Size size;

  /// Seconds after it was taken that it is let go: when the pet gets to the
  /// slot and squats. Sooner, if the pet is sent off with another tablet.
  double ridesFor;

  /// Where it was let go from, as it was: the pet's head, or wherever it had
  /// got to when the pet was sent off.
  Offset? letGoAt;

  /// Whether it has landed in its slot yet, and been made a fuss of.
  bool landed = false;

  /// Seconds to fly from the stack onto the pet's head, to fall into its slot,
  /// and to settle there.
  static const double lift = 0.2;
  static const double fall = 0.3;
  static const double settle = 0.3;
}

extension _SablethFlow on _BossTrialScreenState {
  // ---- shared layout ----

  /// The panel its words go on: the sky over it, down to the top of its head.
  Rect _talkRect(_Geo geo) => Rect.fromLTRB(
        _Geo.bubbleInset,
        _Geo.bubbleTop,
        geo.w - _Geo.bubbleInset,
        max(_Geo.bubbleTop + _Geo.bubbleH, geo.bossTop - 6),
      );

  /// The field for what is tapped: from under the ledge to over the pet.
  double _fieldTop(_Geo geo) => geo.ledgeTop + geo.ledgeH + 8;
  double _fieldBottom(_Geo geo) => geo.groundTop - geo.petBox * 0.9 - 6;

  /// [n] rows of tablets stacked in the field, each [i]'s box.
  Rect _tabletRect(_Geo geo, int i, int n) {
    const gap = 8.0;
    final space = _fieldBottom(geo) - _fieldTop(geo);
    final h = min(46.0, (space - gap * (n - 1)) / n).floorToDouble();
    final top =
        _fieldTop(geo) + ((space - n * h - (n - 1) * gap) / 2).roundToDouble();
    final w = min(geo.w - 2 * _Geo.spellInset, 360.0);
    return Rect.fromLTWH(((geo.w - w) / 2).roundToDouble(),
        top + i * (h + gap), w, h);
  }

  Widget _talk(_Geo geo, String text, double clock, {String? label}) {
    return Positioned.fromRect(
      rect: _talkRect(geo),
      child: IgnorePointer(
        child: TalkPanel(
          text: text,
          style: _pixel(10, _BossTrialScreenState._ink,
                  localeCode: _languageCode)
              .copyWith(height: 1.5),
          clock: clock,
          label: label,
          labelStyle: _pixel(7, const Color(0xFF7A4E2D)),
        ),
      ),
    );
  }

  /// A first round's clock run out over [missed]: it lands its curse.
  void _timedOut(_Geo geo, _ClockRound round, TrialSentence missed) {
    _refresh(() {
      round.lost = true;
      _run = _run.castFailed(missed);
      _holdAftermath = true;
      _stage = _Stage.resolving;
      _stageTime = 0;
      _cackleTime = 0;
    });
    _strikePet(geo);
    if (_run.isOver) _endIn = 0.8;
  }

  void _refused(_Geo geo, _ClockRound round, int i, double cost, Offset at,
      {String said = 'wrong'}) {
    HapticFeedback.lightImpact();
    _refresh(() {
      round.refuse(i, cost);
      _run = _run.fizzle();
    });
    if (!_reduceMotion) _particles.sparks(at, count: 8, fizzle: true);
    _pop(said, _BossTrialScreenState._hurtRed, at.translate(0, -30));
  }

  /// Starts a sand-clock round: the boss's move, and the round held until it
  /// lands.
  void _beginClockRound(void Function() set) {
    _refresh(() {
      set();
      _stage = _Stage.jumping;
      _stageTime = 0;
      _startMove();
      _shouting = false;
    });
  }

  void _openClockRound(_Geo geo, _Stage stage) {
    _refresh(() {
      _stage = stage;
      _stageTime = 0;
    });
    _landingShock(geo);
  }

  // ---- Riddle ----

  void _beginRiddle() {
    final wave = RiddleWave.build(_enTr?.riddles ?? const [],
        previous: _lastAs<TrialRiddle>(), random: _rng);
    if (wave == null) {
      _throwWave();
      return;
    }
    _beginClockRound(() {
      _riddle = _RiddleRound(
        wave,
        _BossTrialScreenState._secs(SphinxRules.riddleTime(
            words: wave.riddle.words, patience: _clockPatience)),
      );
      _lastAsked = wave.riddle;
    });
  }

  void _tapRiddle(int i) {
    final round = _riddle;
    final geo = _geo;
    if (_phase != _Phase.playing ||
        _stage != _Stage.riddling ||
        round == null ||
        geo == null ||
        round.over ||
        round.wrong.contains(i)) {
      return;
    }
    final tablet = _tabletRect(geo, i, round.wave.options.length);
    if (i != round.wave.answer) {
      round.wrong.add(i);
      _refused(geo, round, i, SphinxRules.riddleMistake, tablet.center);
      if (!_reduceMotion) _ramTablet(geo, round, i, tablet);
      return;
    }
    _answeredByStamp(geo, round, i, tablet);
  }

  /// What it takes for the pet to get its head up under [tablet], as far as a
  /// leap goes.
  Offset _underTablet(_Geo geo, Rect tablet) => _reachTo(
        geo,
        _withinLeap(geo, Offset(tablet.center.dx, tablet.bottom - _headInto),
            most: geo.petBox * 2.6),
      );

  /// The right tablet: the pet springs up under it, stretched, and STAMPS it —
  /// its head driven up into the stone, which is shoved up into its place with
  /// the pet's seal cut in it — and pushes there a moment, shivering with the
  /// effort, before it lets go and drops with a thud. The spell leaves the
  /// tablet as the stamp lands.
  void _answeredByStamp(_Geo geo, _RiddleRound round, int i, Rect tablet) {
    HapticFeedback.selectionClick();
    final earliness = 1 - round.clock;
    _refresh(() {
      round.won = true;
      _stage = _Stage.resolving;
      _stageTime = 0;
    });
    if (_reduceMotion) {
      round.stamped = i;
      round.stampedAt = round.t - 5;
      _shoot(
        geo,
        _Shot(
          from: tablet.center,
          earliness: earliness,
          whole: true,
          look: _ShotLook.spell,
        ),
      );
      return;
    }
    final reach = _underTablet(geo, tablet);
    final aside = reach.dx.abs() > 8;
    final dir = aside ? reach.dx.sign : 0.0;
    // Stretched, it is drawn taller: it has to go up a little less.
    final up = max(0.0, reach.dy - _stretchRise(geo, 1.2));
    final k = _Keyer();
    k.to(0.07, squash: 0.85, dy: -2);
    k.to(0.22 + reach.dy / 1000,
        dx: reach.dx,
        dy: up,
        squash: 1.2,
        tilt: dir * 0.2,
        ease: _Ease.out);
    final hit = k.t;
    // Driven in, and held, as stretched as ever and pushing the stone up
    // with it: a squeeze, then a tremble.
    k.to(0.06, dy: up + 4, ease: _Ease.out);
    for (var n = 0; n < 4; n++) {
      k.to(0.07, dx: reach.dx + (n.isEven ? 2 : -2), ease: _Ease.linear);
    }
    k.to(0.01, dx: reach.dx);
    // Lets go, and drops.
    k.to(0.38, dx: 0, dy: 0, tilt: 0, squash: 0.8, ease: _Ease.accelerate);
    k.to(0.14, squash: 1.0);
    round.stamped = i;
    round.stampedAt = round.t + hit;
    _shots.add(_Shot(
      from: tablet.center,
      earliness: earliness,
      whole: true,
      look: _ShotLook.spell,
      delay: hit + 0.2,
    ));
    _stayPut(k.t + 0.2);
    _faceToward(tablet.center.dx, from: _petX, deadzone: 12);
    _playMove(_PetMove.keys(
      k.keys,
      events: [
        _MoveEvent(hit, (geo) {
          _shake = max(_shake, 0.1);
          _particles.sparks(Offset(tablet.center.dx, tablet.bottom),
              count: 10, colors: SphinxPalette.dust);
        }),
      ],
    ));
  }

  /// A tablet that was not the answer: the pet springs up and rams it anyway,
  /// and it CRACKS across; the pet is thrown off it, tipped away, and lands
  /// wincing.
  void _ramTablet(_Geo geo, _RiddleRound round, int i, Rect tablet) {
    final reach = _underTablet(geo, tablet);
    final aside = reach.dx.abs() > 8;
    final dir = aside ? reach.dx.sign : 0.0;
    // Knocked back from the tablet — or, straight under it, from the boss.
    final away = aside ? -dir : -_bossSide(geo, _petX);
    final up = max(0.0, reach.dy - _stretchRise(geo, 1.18));
    final k = _Keyer();
    k.to(0.06, squash: 0.88, dy: -2);
    k.to(0.2 + reach.dy / 1000,
        dx: reach.dx,
        dy: up,
        squash: 1.18,
        tilt: dir * 0.25,
        ease: _Ease.out);
    final hit = k.t;
    k.to(0.14,
        dx: reach.dx + away * 10,
        dy: max(0.0, up - 10),
        squash: 0.92,
        tilt: away * 0.6,
        ease: _Ease.out);
    k.to(0.3, dx: 0, dy: 0, squash: 0.78, tilt: away * 0.25, ease: _Ease.accelerate);
    k.to(0.2, squash: 1.0, tilt: 0);
    round.cracked[i] = round.t + hit;
    _stayPut(k.t + 0.2);
    _faceToward(tablet.center.dx, from: _petX, deadzone: 12);
    _playMove(_PetMove.keys(
      k.keys,
      events: [
        _MoveEvent(hit, (geo) {
          _shake = max(_shake, 0.12);
          _particles.shatter(
              Rect.fromLTWH(tablet.left + tablet.width * 0.4, tablet.bottom - 6,
                  tablet.width * 0.2, 6),
              colors: SphinxPalette.dust);
        }),
      ],
    ));
  }

  /// How far the stamped tablet is shoved up into its place, in pixels,
  /// [since] seconds after the pet's head hit it: at once, held while the pet
  /// pushes, then let down.
  double _stampPress(double since) {
    if (since < 0) return 0;
    final v = since < 0.05
        ? 6 * since / 0.05
        : since < 0.34
            ? 6.0
            : 6 * (1 - (since - 0.34) / 0.16);
    return max(0.0, v).roundToDouble();
  }

  List<Widget> _buildRiddle(_Geo geo, _RiddleRound round) {
    if (_stage == _Stage.jumping) return const [];
    final wave = round.wave;
    final n = wave.options.length;
    final style =
        _pixel(10, _BossTrialScreenState._ink, localeCode: _languageCode);
    return [
      _talk(geo, '${wave.riddle.passage}\n${wave.riddle.question}',
          round.clock),
      for (var i = 0; i < n; i++)
        () {
          final stamped = round.stamped == i ? round.t - round.stampedAt : -1.0;
          final crackedAt = round.cracked[i];
          final cracking = crackedAt == null ? 0.0 : (round.t - crackedAt) / 0.15;
          return Positioned.fromRect(
            rect: _tabletRect(geo, i, n)
                .shift(Offset(0, -_stampPress(stamped))),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: SkinTile(
                    skin: _boss.skin,
                    label: wave.options[i],
                    style: style,
                    state: round.isFlashing(i)
                        ? TileState.flashing
                        : i == wave.answer && round.over
                            ? TileState.right
                            : round.wrong.contains(i)
                                ? TileState.wrong
                                : TileState.plain,
                    onTapDown: () => _tapRiddle(i),
                  ),
                ),
                // The seal the pet stamped, and the crack it made in a wrong one.
                if (stamped >= 0)
                  Positioned.fill(
                    child: IgnorePointer(
                        child: SealMark(progress: stamped / 0.18)),
                  ),
                if (cracking > 0)
                  Positioned.fill(
                    child: IgnorePointer(child: TabletCrack(progress: cracking)),
                  ),
              ],
            ),
          );
        }(),
    ];
  }

  // ---- Sealed Door ----

  void _beginDoor() {
    final wave = DoorWave.build(_enTr?.doors ?? const [],
        previous: _lastAs<GrammarDoor>(), random: _rng);
    if (wave == null) {
      _throwWave();
      return;
    }
    _beginClockRound(() {
      _door = _DoorRound(
        wave,
        _BossTrialScreenState._secs(SphinxRules.doorTime(
            words: wave.door.words, patience: _clockPatience)),
      );
      _lastAsked = wave.door;
    });
  }

  void _turnDial() {
    final round = _door;
    if (_phase != _Phase.playing ||
        _stage != _Stage.dooring ||
        round == null ||
        round.over) {
      return;
    }
    HapticFeedback.selectionClick();
    _refresh(() => round.dial = (round.dial + 1) % round.wave.forms.length);
    // The pet spins the dial: round it goes, like a top.
    if (!_reduceMotion) _playMove(_twirl());
  }

  /// A pirouette on the spot, with a hop at the top of it.
  _PetMove _twirl() {
    final k = _Keyer();
    k.to(0.06, squash: 0.88);
    k.to(0.15, twirl: 0.5, dy: 12, squash: 1.1, ease: _Ease.out);
    k.to(0.15, twirl: 1, dy: 0, squash: 1.0, ease: _Ease.accelerate);
    k.to(0.07, squash: 0.88);
    k.to(0.07, squash: 1.0);
    return _PetMove.keys(k.keys);
  }

  /// Where the door is drawn, in the field.
  Rect _doorRect(_Geo geo) => _drawnRect(
        _doorKey,
        Rect.fromLTRB(8, _fieldTop(geo), geo.w - 8, _fieldBottom(geo)),
      );

  void _pushDoor() {
    final round = _door;
    final geo = _geo;
    if (_phase != _Phase.playing ||
        _stage != _Stage.dooring ||
        round == null ||
        geo == null ||
        round.over) {
      return;
    }
    final door = _doorRect(geo);
    if (round.dial != round.wave.answer) {
      _refused(geo, round, round.dial, SphinxRules.doorMistake, door.center,
          said: 'sealed');
      if (!_reduceMotion) _bounceOffDoor(geo, door);
      return;
    }
    _answeredByCharge(geo, round, door, onBroken: () => round.broken = true);
  }

  /// A wrong push: the pet throws itself up at the door, which does not give,
  /// and comes back down off it dizzy.
  void _bounceOffDoor(_Geo geo, Rect door) {
    final aim = _withinLeap(
      geo,
      Offset(door.center.dx, door.bottom - _headInto),
      most: geo.petBox * 2.6,
    );
    final reach = _reachTo(geo, aim);
    _stayPut(1.2);
    _playMove(_PetMove.bounce(reach: reach, rise: 0.2 + reach.dy / 1000));
  }

  /// The right form dialled: the pet crouches for a full second, trembling
  /// harder and harder, then throws itself at the door shoulder first, which
  /// bursts — [onBroken] is called then — and the spell leaves it.
  void _answeredByCharge(_Geo geo, _ClockRound round, Rect door,
      {required void Function() onBroken}) {
    HapticFeedback.selectionClick();
    final earliness = 1 - round.clock;
    _refresh(() {
      round.won = true;
      _stage = _Stage.resolving;
      _stageTime = 0;
    });
    if (_reduceMotion) {
      _refresh(onBroken);
      _shoot(
        geo,
        _Shot(
          from: door.center,
          earliness: earliness,
          whole: true,
          look: _ShotLook.spell,
        ),
      );
      return;
    }
    final toward = _bossSide(geo, _petX);
    final aim = _withinLeap(
      geo,
      Offset(door.center.dx, door.bottom - _headInto),
      most: geo.petBox * 2.6,
    );
    final reach = _reachTo(geo, aim);
    final up = max(0.0, reach.dy - _stretchRise(geo, 1.22));
    final k = _Keyer();
    // A full second down on its haunches, leaning back from the door...
    k.to(0.3, squash: 0.86, tilt: -toward * 0.05);
    k.to(0.7,
        squash: 0.6, tilt: -toward * 0.22, dy: -5, ease: _Ease.accelerate);
    final charge = k.t;
    // ...and the shoulder charge: up and across, tipped over on to its shoulder.
    k.to(0.12 + reach.dy / 1800,
        dx: toward * 14,
        dy: up,
        tilt: toward * 0.7,
        squash: 1.22,
        ease: _Ease.out);
    final hit = k.t;
    k.hold(0.12);
    k.to(0.4, dx: 0, dy: 0, tilt: 0, squash: 0.8, ease: _Ease.accelerate);
    k.to(0.16, squash: 1.0);
    _shots.add(_Shot(
      from: door.center,
      earliness: earliness,
      whole: true,
      look: _ShotLook.spell,
      delay: hit + 0.05,
    ));
    _stayPut(k.t + 0.2);
    _playMove(_PetMove.keys(
      k.keys,
      faceLeft: toward < 0,
      shiver: 3.5,
      shiverFor: charge,
      events: [
        _MoveEvent(hit, (geo) {
          _shake = max(_shake, 0.25);
          _particles.shatter(door, colors: SphinxPalette.dust);
          _refresh(onBroken);
        }),
      ],
    ));
  }

  List<Widget> _buildDoor(_Geo geo, _DoorRound round) {
    if (_stage == _Stage.jumping) return const [];
    final door = round.wave.door;
    final dial = round.lost ? round.wave.answer : round.dial;
    List<String> words(String s) => [
          for (final w in s.split(' '))
            if (w.isNotEmpty) w,
        ];
    final talk = _talk(geo, door.meaning, round.clock,
        label: 'OPEN IT WITH THE RIGHT FORM');
    // The pet has burst it: the door is gone.
    if (round.broken) return [talk];
    return [
      talk,
      Positioned(
        left: 8,
        right: 8,
        top: _fieldTop(geo),
        height: _fieldBottom(geo) - _fieldTop(geo),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: geo.w - 16),
              child: SealedDoor(
                key: _doorKey,
                before: words(door.before),
                after: words(door.after),
                dial: round.wave.forms[dial],
                turn: dial,
                base: door.base,
                style: _pixel(10, _BossTrialScreenState._ink,
                    localeCode: _languageCode),
                baseStyle: _pixel(7, SphinxPalette.band,
                    localeCode: _languageCode),
                state: round.isFlashing(round.dial)
                    ? TileState.flashing
                    : round.over
                        ? TileState.right
                        : TileState.plain,
                onTurn: _turnDial,
                onPush: _pushDoor,
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  // ---- Tablets ----

  void _beginTablets() {
    final wave = TabletWave.build(_enTr?.stories ?? const [],
        previous: _lastAs<TrialStory>(), random: _rng);
    if (wave == null) {
      _throwWave();
      return;
    }
    _beginClockRound(() {
      _tablets = _TabletRound(
        wave,
        _BossTrialScreenState._secs(SphinxRules.tabletTime(
            words: wave.story.words, patience: _clockPatience)),
      );
      _lastAsked = wave.story;
    });
  }

  void _tapTablet(int i) {
    final round = _tablets;
    final geo = _geo;
    if (_phase != _Phase.playing ||
        _stage != _Stage.tableting ||
        round == null ||
        geo == null ||
        round.over) {
      return;
    }
    final n = round.wave.tablets.length;
    final tablet = _tabletRect(geo, i, n);
    switch (round.play.tap(i)) {
      case TabletTap.ignored:
        return;
      case TabletTap.wrong:
        _refused(geo, round, i, SphinxRules.tabletMistake, tablet.center,
            said: 'not yet');
        if (!_reduceMotion) _cringeAt(tablet.center);
      case TabletTap.next:
        HapticFeedback.selectionClick();
        _refresh();
        _carryToSlot(geo, round, tablet);
      case TabletTap.done:
        // The whole story set out: the pet takes the last tablet to its slot,
        // then casts it, and the tablets burst as the spell leaves.
        HapticFeedback.selectionClick();
        final earliness = 1 - round.clock;
        _refresh(() {
          round.won = true;
          _stage = _Stage.resolving;
          _stageTime = 0;
        });
        _carryToSlot(geo, round, tablet, earliness: earliness);
    }
  }

  // ---- the slot rail ----

  /// The rail of slots on the ground, one for each line of the story with the
  /// first at the left: where the pet takes the tablets.
  Rect _slotRect(_Geo geo, int k, int n) {
    final feet = geo.groundTop + geo.petBox * 0.1 + 4;
    final room = max(0.0, geo.h - 4 - feet);
    final h = min(30.0, room).floorToDouble();
    const gap = 8.0;
    final w = min(92.0, ((geo.w - 24 - gap * (n - 1)) / n).floorToDouble());
    final total = n * w + (n - 1) * gap;
    return Rect.fromLTWH(
      ((geo.w - total) / 2).roundToDouble() + k * (w + gap),
      (feet + (room - h) / 2).roundToDouble(),
      w,
      h,
    );
  }

  /// How big a tablet is as a plaque: what fits in a slot.
  Size _plaqueSize(_Geo geo, int n) {
    final slot = _slotRect(geo, 0, n);
    return Size(min(58.0, slot.width - 8), min(28.0, slot.height));
  }

  /// Where a plaque sits on the pet's head: standing on its ears, going where
  /// the pet goes — up with every hop, down with every squat.
  Offset _plaqueRide(_Geo geo, Size plaque) {
    final size = _petSize(geo);
    final pose = _petPose(size);
    final top = (_petFeet ?? geo.groundTop) -
        pose.lift -
        size * _BossTrialScreenState._headHeight * pose.scaleY;
    return Offset(_petX + pose.dx, top - plaque.height / 2 + 2);
  }

  /// The tablet the pet has just lifted goes to its slot: it hops to catch the
  /// tablet — shrunk to a plaque — on its head, carries it overhead along the
  /// ground to the slot, squats and lets it go, and the plaque drops in with a
  /// squash. With an [earliness] it was the last one, and the pet goes straight
  /// on to cast the whole story, its tablets bursting as the spell leaves.
  void _carryToSlot(_Geo geo, _TabletRound round, Rect tablet,
      {double? earliness}) {
    final n = round.wave.tablets.length;
    final slot = round.play.lifted.length - 1;
    final slotAt = _slotRect(geo, slot, n);
    // Reduced motion: the plaque is simply in its slot.
    if (_reduceMotion) {
      round.plaques.add(_Plaque(slot,
          since: round.t - 10,
          from: tablet.center,
          size: tablet.size,
          ridesFor: 0));
      if (earliness != null) {
        _castWhole(geo, earliness, tablet.center,
            onRelease: (geo) => _burstStory(geo, round));
      }
      return;
    }
    // Any plaque still being carried is let go now, where it has got to.
    for (final other in round.plaques) {
      final age = round.t - other.since;
      if (age < other.ridesFor) {
        other.letGoAt = _plaqueAt(geo, round, other);
        other.ridesFor = age;
      }
    }
    final half = geo.petBox / 2;
    final toX = slotAt.center.dx.clamp(half - 6, geo.w - half + 6).toDouble();
    final run = _runTo(geo, toX, stay: 0.6, pace: 0.42);
    final k = _Keyer();
    // A hop to catch it...
    k.to(0.05, squash: 0.9);
    k.to(0.09, dy: 14, squash: 1.1, ease: _Ease.out);
    k.to(0.08, dy: 0, squash: 1.0, ease: _Ease.accelerate);
    // ...nothing but the hop-walk till it gets there, and a beat to line it
    // up over the slot...
    final arrives = run + 0.15;
    if (arrives > k.t) k.hold(arrives - k.t);
    // ...then down on its haunches to let it go, and up again.
    k.to(0.1, squash: 0.72, dy: -2, ease: _Ease.accelerate);
    final release = k.t;
    k.to(0.12, squash: 1.12, dy: 6, ease: _Ease.out);
    k.to(0.14, squash: 1.0, dy: 0, ease: _Ease.accelerate);
    round.plaques.add(_Plaque(slot,
        since: round.t, from: tablet.center, size: tablet.size, ridesFor: release));
    var events = <_MoveEvent>[];
    if (earliness != null) {
      // Waits for the plaque to land, then rears back and casts the story.
      final lands = release + _Plaque.fall;
      if (k.t < lands + 0.1) k.hold(lands + 0.1 - k.t);
      final toward = _bossSide(geo, toX);
      final cast = _throwKeys(k, toward: toward);
      _shots.add(_Shot(
        from: _throwFrom(geo, toX, toward),
        earliness: earliness,
        whole: true,
        look: _ShotLook.spell,
        delay: cast,
      ));
      events = [_MoveEvent(cast, (geo) => _burstStory(geo, round))];
    }
    _petAway = k.t + 0.3;
    _playMove(_PetMove.keys(k.keys, events: events));
  }

  /// The story set out and cast: its tablets burst, in their slots.
  void _burstStory(_Geo geo, _TabletRound round) {
    final n = round.wave.tablets.length;
    for (final plaque in round.plaques) {
      _particles.shatter(_slotRect(geo, plaque.slot, n),
          colors: SphinxPalette.dust);
    }
    _refresh(() => round.plaques.clear());
  }

  /// Where [plaque] is now: lifted off the stack and shrinking onto the pet's
  /// head, riding there, or — let go — falling into its slot.
  Offset _plaqueAt(_Geo geo, _TabletRound round, _Plaque plaque) {
    final n = round.wave.tablets.length;
    final age = round.t - plaque.since;
    final slot = _slotRect(geo, plaque.slot, n).center;
    final size = _plaqueSize(geo, n);
    if (age >= plaque.ridesFor) {
      final from = plaque.letGoAt ?? _plaqueRide(geo, size);
      final k = ((age - plaque.ridesFor) / _Plaque.fall).clamp(0.0, 1.0);
      return Offset.lerp(from, slot, k * k)!;
    }
    final up = _smooth(age / _Plaque.lift);
    return Offset.lerp(plaque.from, _plaqueRide(geo, size), up)!;
  }

  /// Everything about the carrying that happens on the game clock: a plaque
  /// let go from the pet's head where it is, and one landing in its slot.
  void _stepSphinxFx(double dt, _Geo geo) {
    final round = _tablets;
    if (round == null) return;
    final n = round.wave.tablets.length;
    for (final plaque in round.plaques) {
      final age = round.t - plaque.since;
      if (plaque.letGoAt == null && age >= plaque.ridesFor) {
        plaque.letGoAt = _plaqueRide(geo, _plaqueSize(geo, n));
      }
      if (!plaque.landed && age >= plaque.ridesFor + _Plaque.fall) {
        plaque.landed = true;
        _shake = max(_shake, 0.06);
        _particles.sparks(_slotRect(geo, plaque.slot, n).center.translate(0, 8),
            count: 7, colors: SphinxPalette.dust);
      }
    }
  }

  /// The plaques the pet is carrying, and those in their slots, over the pet.
  List<Widget> _buildPlaques(_Geo geo, _TabletRound round) {
    final n = round.wave.tablets.length;
    final size = _plaqueSize(geo, n);
    final style = _pixel(10, _BossTrialScreenState._ink, localeCode: _languageCode);
    return [
      for (final plaque in round.plaques)
        () {
          final age = round.t - plaque.since;
          final centre = _plaqueAt(geo, round, plaque);
          // Shrinks from the tablet it was to the plaque it is as it flies.
          final shrink = _smooth(age / _Plaque.lift);
          final w = plaque.size.width + (size.width - plaque.size.width) * shrink;
          final h = plaque.size.height + (size.height - plaque.size.height) * shrink;
          // On landing it is squashed flat, and springs back.
          final since = age - plaque.ridesFor - _Plaque.fall;
          final squash = since < 0 || since > _Plaque.settle
              ? 1.0
              : 1 - 0.45 * cos(since / _Plaque.settle * pi / 2) * (1 - since / _Plaque.settle);
          return Positioned(
            key: ValueKey('plaque-${plaque.slot}'),
            left: (centre.dx - w / 2).roundToDouble(),
            top: (centre.dy - h / 2).roundToDouble(),
            width: w.roundToDouble(),
            height: h.roundToDouble(),
            child: IgnorePointer(
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.diagonal3Values(
                    since < 0 || since > _Plaque.settle ? 1.0 : 1 + (1 - squash) * 0.5,
                    squash,
                    1),
                child: SkinTile(
                  skin: _boss.skin,
                  shape: TileShape.tablet,
                  label: '${plaque.slot + 1}',
                  style: style,
                  state: TileState.right,
                  onTapDown: null,
                ),
              ),
            ),
          );
        }(),
    ];
  }

  List<Widget> _buildTablets(_Geo geo, _TabletRound round) {
    if (_stage == _Stage.jumping) return const [];
    final wave = round.wave;
    final n = wave.tablets.length;
    final lifted = round.play.lifted;
    final style =
        _pixel(9, _BossTrialScreenState._ink, localeCode: _languageCode);
    return [
      _talk(geo, 'Lift them in the order it happens.', round.clock, label: 'THE STORY IS BROKEN'),
      // The places they go: along the ground, the first at the left.
      for (var k = 0; k < n; k++)
        Positioned.fromRect(
          rect: _slotRect(geo, k, n),
          child: IgnorePointer(
            child: PlaqueSlot(number: '${k + 1}', style: style),
          ),
        ),
      for (var i = 0; i < n; i++)
        Positioned.fromRect(
          rect: _tabletRect(geo, i, n),
          child: SkinTile(
            skin: _boss.skin,
            shape: TileShape.tablet,
            label: wave.story.lines[wave.tablets[i]],
            style: style,
            // Where it should have gone, once the sand has run out.
            badge: round.lost && !lifted.contains(i) ? '${wave.tablets[i] + 1}' : null,
            // A tablet the pet has taken leaves its place empty.
            state: lifted.contains(i)
                ? TileState.spent
                : round.isFlashing(i)
                    ? TileState.flashing
                    : TileState.plain,
            onTapDown: () => _tapTablet(i),
          ),
        ),
    ];
  }

  // ---- Sandstorm ----

  void _beginStorm() {
    final wave = StormWave.build(_pool,
        previous: _lastAs<TrialWord>(), random: _rng);
    if (wave == null) {
      _throwWave();
      return;
    }
    _beginClockRound(() {
      _storm = _StormRound(
        wave,
        _BossTrialScreenState._secs(SphinxRules.stormTime(
            letters: wave.cells.length, patience: _clockPatience)),
      );
      _lastAsked = wave.word;
    });
  }

  /// The sand grid in the field: square cells, as big as the field allows.
  Rect _stormRect(_Geo geo) {
    final space = _fieldBottom(geo) - _fieldTop(geo);
    final cell = min((geo.w - 24) / StormWave.cols, space / StormWave.rows)
        .floorToDouble();
    final w = cell * StormWave.cols, h = cell * StormWave.rows;
    return Rect.fromLTWH(((geo.w - w) / 2).roundToDouble(),
        _fieldTop(geo) + ((space - h) / 2).roundToDouble(), w, h);
  }

  int? _stormCellAt(_Geo geo, Offset local) {
    final r = _stormRect(geo);
    final cell = r.width / StormWave.cols;
    final x = (local.dx / cell).floor(), y = (local.dy / cell).floor();
    if (x < 0 || y < 0 || x >= StormWave.cols || y >= StormWave.rows) {
      return null;
    }
    return y * StormWave.cols + x;
  }

  bool get _stormLive =>
      _phase == _Phase.playing &&
      _stage == _Stage.storming &&
      _storm != null &&
      !_storm!.over;

  /// A finger down on the sand: the start of a swipe — or, if a letter was
  /// tapped before, the other end of one.
  void _stormDown(Offset local) {
    final round = _storm;
    final geo = _geo;
    if (!_stormLive || round == null || geo == null) return;
    final cell = _stormCellAt(geo, local);
    if (cell == null) return;
    final anchor = round.anchor;
    if (anchor != null && anchor != cell && round.swiped.length == 1) {
      // Tapped one end and now the other.
      final line = StormWave.line(anchor, cell);
      _refresh(() => round.swiped = line ?? [cell]);
      _stormUp();
      return;
    }
    _refresh(() {
      round.anchor = cell;
      round.swiped = [cell];
    });
  }

  void _stormMove(Offset local) {
    final round = _storm;
    final geo = _geo;
    if (!_stormLive || round == null || geo == null) return;
    final anchor = round.anchor;
    final cell = _stormCellAt(geo, local);
    if (anchor == null || cell == null) return;
    final line = StormWave.line(anchor, cell);
    if (line != null && line.length != round.swiped.length) {
      _refresh(() => round.swiped = line);
    }
  }

  /// The finger lifted: a swipe of one letter waits for its other end; a
  /// longer one is checked.
  void _stormUp() {
    final round = _storm;
    final geo = _geo;
    if (!_stormLive || round == null || geo == null) return;
    final swiped = round.swiped;
    if (swiped.length < 2) return;
    final r = _stormRect(geo);
    final cell = r.width / StormWave.cols;
    Offset centre(int c) => r.topLeft +
        Offset((c % StormWave.cols + 0.5) * cell,
            (c ~/ StormWave.cols + 0.5) * cell);
    final at = Offset.lerp(centre(swiped.first), centre(swiped.last), 0.5)!;
    if (!round.wave.found(swiped)) {
      _refresh(() {
        round.refusedCells = swiped;
        round.anchor = null;
        round.swiped = const [];
      });
      _refused(geo, round, -1, SphinxRules.stormMistake, at, said: 'no');
      if (!_reduceMotion) _cringeAt(at);
      return;
    }
    _refresh(() => round.anchor = null);
    _answeredByHowl(geo, round, swiped, at, [
      for (final c in swiped)
        Rect.fromCenter(center: centre(c), width: cell, height: cell),
    ]);
  }

  /// The word found: the pet crouches, throws its head back and HOWLS, rings
  /// of sound spreading up to the grid, and the sand is blown off the word —
  /// streaming away on the wind — which the spell leaves.
  void _answeredByHowl(_Geo geo, _StormRound round, List<int> word, Offset at,
      List<Rect> cells) {
    HapticFeedback.selectionClick();
    final earliness = 1 - round.clock;
    _refresh(() {
      round.won = true;
      round.blown = word;
      _stage = _Stage.resolving;
      _stageTime = 0;
    });
    if (_reduceMotion) {
      round.howledAt = round.t - 5;
      round.blownAt = round.t - 5;
      _shoot(
        geo,
        _Shot(
          from: at,
          earliness: earliness,
          whole: true,
          look: _ShotLook.spell,
        ),
      );
      return;
    }
    final k = _Keyer();
    // Draws breath, low to the ground...
    k.to(0.14, squash: 0.82);
    // ...and throws its head back, up on its toes.
    k.to(0.22, tilt: -0.6, dy: 8, squash: 1.08, ease: _Ease.out);
    final howl = k.t;
    // Holds the howl, trembling with it.
    for (var n = 0; n < 6; n++) {
      k.to(0.1, tilt: n.isEven ? -0.55 : -0.65, ease: _Ease.linear);
    }
    k.to(0.28, tilt: 0, dy: 0, squash: 0.9);
    k.to(0.12, squash: 1.0);
    final blow = howl + 0.28;
    round.howledAt = round.t + howl;
    round.blownAt = round.t + blow;
    _shots.add(_Shot(
      from: at,
      earliness: earliness,
      whole: true,
      look: _ShotLook.spell,
      delay: blow + 0.1,
    ));
    _stayPut(k.t + 0.2);
    _playMove(_PetMove.keys(
      k.keys,
      faceLeft: false,
      events: [
        _MoveEvent(blow, (geo) {
          _shake = max(_shake, 0.08);
          for (final cell in cells) {
            _particles.gust(cell, dir: -1, colors: SphinxPalette.dust);
          }
        }),
      ],
    ));
  }

  /// How far into the wind the storm leans on the pet while it hunts for the
  /// word: ten degrees, with a flutter, more as the clock runs.
  double _stormLean() {
    final round = _storm;
    if (_stage != _Stage.storming ||
        round == null ||
        round.over ||
        _reduceMotion) {
      return 0;
    }
    return pi / 18 + sin(_time * 2.3) * 0.015 * (0.4 + round.clock);
  }

  List<Widget> _buildStorm(_Geo geo, _StormRound round) {
    if (_stage == _Stage.jumping) return const [];
    final wave = round.wave;
    final rect = _stormRect(geo);
    final cell = rect.width / StormWave.cols;
    final flashing = round.t - round.flashAt < 0.3;
    // The word the pet howled the sand off is gone from the grid.
    final blown = round.isBlown ? round.blown : const <int>[];
    final shown = round.won || round.lost ? wave.cells : round.swiped;
    return [
      _talk(geo, wave.word.meaning, round.clock,
          label: 'FIND IT IN THE SAND'),
      Positioned.fromRect(
        rect: rect,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (d) => _stormDown(d.localPosition),
          onPanUpdate: (d) => _stormMove(d.localPosition),
          onPanEnd: (_) => _stormUp(),
          child: CustomPaint(
            painter: SandGridPainter(
              cols: StormWave.cols,
              rows: StormWave.rows,
              lit: shown,
              found: round.won || round.lost,
              refused: flashing ? round.refusedCells : const [],
              cleared: blown,
            ),
            foregroundPainter: SandDriftPainter(round.clock),
            child: Stack(
              children: [
                Column(
                  children: [
                    for (var y = 0; y < StormWave.rows; y++)
                      SizedBox(
                        height: cell,
                        child: Row(
                          children: [
                            for (var x = 0; x < StormWave.cols; x++)
                              SizedBox(
                                width: cell,
                                child: blown.contains(y * StormWave.cols + x)
                                    ? null
                                    : Center(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            wave.grid[y * StormWave.cols + x],
                                            style: _pixel(
                                                min(16, cell * 0.42),
                                                _BossTrialScreenState._ink,
                                                localeCode: _languageCode),
                                          ),
                                        ),
                                      ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
                // The wind: sand streaming across the grid, right to left.
                if (!_reduceMotion)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: WindStreaksPainter(
                          time: _time,
                          strength: round.over ? 0.25 : 0.3 + 0.7 * round.clock,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  /// What is drawn over the pet: the plaques it carries and the howl it lets
  /// out.
  List<Widget> _buildSphinxFront(_Geo geo) {
    final tablets = _tablets;
    final storm = _storm;
    return [
      if (tablets != null && _stage != _Stage.jumping)
        ..._buildPlaques(geo, tablets),
      if (storm != null && !_reduceMotion && storm.howledAt.isFinite)
        () {
          final size = _petSize(geo);
          final pose = _petPose(size);
          final head = Offset(
            _petX + pose.dx,
            (_petFeet ?? geo.groundTop) -
                pose.lift -
                size * _BossTrialScreenState._headHeight * pose.scaleY -
                4,
          );
          return Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: HowlRingsPainter(
                  origin: head,
                  progress: (storm.t - storm.howledAt) / 0.9,
                ),
              ),
            ),
          );
        }(),
    ];
  }

  // ---- all four ----

  void _stepSphinxRound(double dt, _Geo geo) {
    final _ClockRound? round = _riddle ?? _door ?? _tablets ?? _storm;
    if (round == null || round.over) return;
    round.clock = min(1.0, round.clock + dt / round.seconds);
    if (round.clock < 1) return;
    final missed = switch (round) {
      _RiddleRound r => r.wave.riddle.asSentence,
      _DoorRound r => r.wave.door.asSentence,
      _TabletRound r => r.wave.story.asSentence,
      _ => null,
    };
    if (missed != null) {
      _timedOut(geo, round, missed);
    } else if (round is _StormRound) {
      // A word, not a sentence: it goes with the words to practise.
      _refresh(() {
        round.lost = true;
        _run = _run.struck(round.wave.word);
        _holdAftermath = true;
        _stage = _Stage.resolving;
        _stageTime = 0;
        _cackleTime = 0;
      });
      _strikePet(geo);
      if (_run.isOver) _endIn = 0.8;
    }
  }

  /// The sand the clock has heaped round the pet so far: nothing until it is
  /// two-thirds through, then a low mound, a third of the way to burying it by
  /// the time it is out.
  double _sandMound() {
    final _ClockRound? round = _riddle ?? _door ?? _tablets ?? _storm;
    if (round == null || round.over || _reduceMotion) return 0;
    if (round.clock < 0.6) return 0;
    final k = (round.clock - 0.6) / 0.4;
    return 0.3 * _smooth(k);
  }

  /// How much sand there is over the pet, 0 to 1: the mound the clock has
  /// been heaping, and, once the curse has landed, the rest of it swelling
  /// over the pet.
  double _sandFill() {
    if (_buried <= 0) return _sandMound();
    if (_reduceMotion) return 1;
    final since = _BossTrialScreenState._curseSeconds - _buried;
    final swells = _smooth(since / _BossTrialScreenState._curseForms);
    // Dug away from, a little more at every stroke, in the last second.
    return (_buriedFrom + (1 - _buriedFrom) * swells) *
        (1 - 0.92 * _shedK(_buried));
  }

  /// How far the sand has sunk the pet into the ground, in pixels.
  double _burySink() {
    if (_buried <= 0 || _reduceMotion) return 0;
    final since = _BossTrialScreenState._curseSeconds - _buried;
    // Sunk into it, and rising out as it digs.
    return (8 *
                _smooth(since / _BossTrialScreenState._curseForms) *
                (1 - _shedK(_buried)) /
                2)
            .roundToDouble() *
        2;
  }

  /// Something of Sableth's got through: the pet is buried in sand, which
  /// heaps over it, and it struggles under it a while.
  void _bury(_Geo geo) {
    HapticFeedback.heavyImpact();
    _buriedFrom = _sandMound();
    _buried = _BossTrialScreenState._curseSeconds;
    _hurtTint = 0.3;
    // Whatever its body was doing stops, and a run stops where it had got to.
    _move = null;
    if (_petRunning || _petGoX != null || _petLane != null) {
      _petGoX = _petX;
      _petLane = null;
      _petAway = _BossTrialScreenState._curseSeconds;
    }
    if (!_reduceMotion) {
      _shake = 0.3;
      _petHurt = 0;
      _particles.shatter(_petRect(geo), colors: SphinxPalette.dust);
    }
    _pop('buried', _BossTrialScreenState._hurtRed,
        Offset(_petX, geo.groundTop - geo.petBox - 8));
  }

  List<Widget> _buildSphinxRounds(_Geo geo) => [
        if (_riddle case final round?) ..._buildRiddle(geo, round),
        if (_door case final round?) ..._buildDoor(geo, round),
        if (_tablets case final round?) ..._buildTablets(geo, round),
        if (_storm case final round?) ..._buildStorm(geo, round),
      ];

  void _clearSphinxRounds() {
    _riddle = null;
    _door = null;
    _tablets = null;
    _storm = null;
  }
}
