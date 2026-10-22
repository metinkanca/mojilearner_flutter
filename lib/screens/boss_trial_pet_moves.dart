part of 'boss_trial_screen.dart';

// The pet's body moves in a fight: the headbutt across Mossback's river, the
// pounce on a cup or a pebble, the catch and throw, the cast and being
// flattened. Each is a short piece of choreography — a crouch that gathers,
// a leap or a thrust, a hold, a fall — that moves the pet off where it stands,
// tips and squashes it, and brings it back.
//
// The game clock steps one at a time ([_BossTrialScreenState._move], by
// `_stepMove`); the pet's widget reads where it is each frame. Timings are
// meant to be WATCHED: a gather of half a second to a second, a leap of a
// quarter, a fall of a third to a half. Anything quicker is not visible.

/// How far the pet's head goes into what it leaps at, in pixels: a bump, not a
/// near miss (the head it is aimed with is a little higher than the ears drawn).
const double _headInto = 10;

/// An ease in and out, 0 to 1.
double _smooth(double k) {
  final c = k.clamp(0.0, 1.0);
  return c * c * (3 - 2 * c);
}

/// How a keyframed move eases from one pose into the next.
enum _Ease {
  /// At a steady rate: a dash, a tug.
  linear,

  /// Slowly into it and slowly out: a swim, a bow.
  smooth,

  /// Fast at first, settling: a snap, a landing.
  out,

  /// Slowly at first, then faster and faster: a fall, a wind-up.
  accelerate,
}

double _eased(_Ease ease, double k) {
  final c = k.clamp(0.0, 1.0);
  return switch (ease) {
    _Ease.linear => c,
    _Ease.smooth => c * c * (3 - 2 * c),
    _Ease.out => 1 - (1 - c) * (1 - c),
    _Ease.accelerate => c * c,
  };
}

/// One pose of a keyframed move: where the pet is [t] seconds in — [dx] across
/// and [dy] up from where it stands, tipped [tilt] radians clockwise, squashed
/// to [squash] of its height, [grow] of the way back to full size, [twirl]
/// turns round about its own middle like a top — reached by easing from the
/// pose before it as [ease] says.
class _Key {
  const _Key(
    this.t, {
    this.dx = 0,
    this.dy = 0,
    this.tilt = 0,
    this.squash = 1,
    this.grow = 0,
    this.twirl = 0,
    this.ease = _Ease.smooth,
  });

  final double t;
  final double dx, dy, tilt, squash, grow, twirl;
  final _Ease ease;
}

/// Writes a keyframed move down pose by pose, the way it is read out loud:
/// "dash across in a fifth of a second, crouch, lunge up..." Each [to] says how
/// long the next stretch takes and what changes by its end; what is left out
/// stays as it was.
class _Keyer {
  final List<_Key> keys = [const _Key(0)];

  /// Seconds into the move so far.
  double get t => keys.last.t;

  /// The pose the move is in now.
  _Key get now => keys.last;

  /// Moves on [dt] seconds, to the pose with whatever is given changed.
  void to(
    double dt, {
    double? dx,
    double? dy,
    double? tilt,
    double? squash,
    double? grow,
    double? twirl,
    _Ease ease = _Ease.smooth,
  }) {
    final last = keys.last;
    keys.add(_Key(
      last.t + dt,
      dx: dx ?? last.dx,
      dy: dy ?? last.dy,
      tilt: tilt ?? last.tilt,
      squash: squash ?? last.squash,
      grow: grow ?? last.grow,
      twirl: twirl ?? last.twirl,
      ease: ease,
    ));
  }

  /// Stays as it is for [dt] seconds.
  void hold(double dt) => to(dt, ease: _Ease.linear);
}

/// Something that happens partway through a move — a bite landing, a spell
/// leaving the pet: [run] is called once, [at] seconds in.
class _MoveEvent {
  _MoveEvent(this.at, this.run);

  final double at;
  final void Function(_Geo geo) run;
  bool fired = false;
}

/// One piece of the pet's choreography. Times are seconds from the move's own
/// start, which is [delay] after it was made.
class _PetMove {
  _PetMove({
    required this.duration,
    required this.offsetAt,
    this.squashAt,
    this.tiltAt,
    this.growAt,
    this.twirlAt,
    this.impactAt,
    this.onImpact,
    this.onEnd,
    this.faceAt = 0,
    this.faceLeft,
    this.delay = 0,
    this.events = const [],
  });

  /// A move drawn pose by pose: [keys] say where the pet is as it goes — the
  /// first at 0 seconds, the last where it ends — and the pet eases through
  /// them. Whole-body stepped, like the rest of the pet's moves. [events] go
  /// off as it passes them.
  ///
  /// With a [shiverFor], the pet trembles across by up to [shiver] pixels as
  /// that many seconds go by, harder and harder.
  factory _PetMove.keys(
    List<_Key> keys, {
    List<_MoveEvent> events = const [],
    double delay = 0,
    bool? faceLeft,
    double faceAt = 0,
    double shiver = 0,
    double shiverFor = 0,
    void Function(_Geo geo)? onEnd,
  }) {
    assert(keys.length >= 2 && keys.first.t == 0);
    _Key from(double t) {
      var i = 0;
      while (i < keys.length - 2 && t >= keys[i + 1].t) {
        i++;
      }
      return keys[i];
    }

    double along(double t, double Function(_Key k) read) {
      if (t >= keys.last.t) return read(keys.last);
      final a = from(t);
      final b = keys[keys.indexOf(a) + 1];
      final k = (t - a.t) / (b.t - a.t);
      final e = _eased(b.ease, k);
      return read(a) + (read(b) - read(a)) * e;
    }

    double trembling(double t) {
      if (shiver == 0 || t >= shiverFor) return 0;
      final k = t / shiverFor;
      return sin(t * 50) * shiver * k * k;
    }

    return _PetMove(
      duration: keys.last.t,
      offsetAt: (t) => Offset(
        (along(t, (k) => k.dx) + trembling(t)).roundToDouble(),
        (along(t, (k) => k.dy) / 2).roundToDouble() * 2,
      ),
      squashAt: (t) => (along(t, (k) => k.squash) * 20).round() / 20,
      tiltAt: (t) => along(t, (k) => k.tilt),
      growAt: (t) => along(t, (k) => k.grow),
      twirlAt: (t) => along(t, (k) => k.twirl),
      events: events,
      delay: delay,
      faceLeft: faceLeft,
      faceAt: faceAt,
      onEnd: onEnd,
    );
  }

  /// A crouch that gathers, a leap — or a thrust — whose top is where the hit
  /// lands, a hold there, and a fall to [back]. The pet is tipped [windTilt]
  /// through the crouch (away from what it is about to hit) and [tilt]
  /// from the leap on (toward it), both in radians, clockwise positive.
  ///
  /// [reach] and [back] are offsets from where the pet stands, up positive.
  /// All four times must be above zero.
  factory _PetMove.leap({
    required Offset reach,
    Offset back = Offset.zero,
    required double tilt,
    double windTilt = 0,
    double crouch = 1.0,
    double rise = 0.25,
    double hold = 0.2,
    double fall = 0.4,
    double squash = 0.2,
    double shiver = 2.5,
    double dip = 4,
    double press = 0,
    double pressTo = 0.55,
    bool grow = false,
    double delay = 0,
    double faceAt = 0,
    bool? faceLeft,
    void Function(_Geo geo)? onImpact,
    void Function(_Geo geo)? onEnd,
  }) {
    final impact = crouch + rise;
    final drop = impact + hold;
    final ends = drop + fall;

    Offset offsetAt(double t) {
      final Offset at;
      if (t < crouch) {
        // Sinks and shivers harder the closer the leap.
        final k = t / crouch;
        at = Offset(sin(t * 50) * shiver * k * k, -dip * k);
      } else if (t < impact) {
        final k = (t - crouch) / rise;
        final e = 1 - (1 - k) * (1 - k);
        at = Offset(reach.dx * e, -dip + (reach.dy + dip) * e);
      } else if (t < drop) {
        at = reach;
      } else {
        // Falls under gravity, drifting across as it goes.
        final k = min(1.0, (t - drop) / fall);
        at = Offset(
          reach.dx + (back.dx - reach.dx) * k,
          reach.dy + (back.dy - reach.dy) * k * k,
        );
      }
      // Whole-body stepped, like the rest of the pet's moves.
      return Offset(at.dx.roundToDouble(), (at.dy / 2).roundToDouble() * 2);
    }

    // Squashed lower and lower through the crouch, in steps, then sprung back
    // to full at the launch. With a [press], something heavy has just landed
    // on it: slammed down to [pressTo] at once, and easing up under the weight
    // to where the crouch has got to.
    double squashAt(double t) {
      if (t >= crouch) return 1;
      final gather = 1 - squash * t / crouch;
      if (t >= press) return (gather * 20).round() / 20;
      const slam = 0.07;
      final to = 1 - squash * press / crouch;
      // Kept pressed until half way, then eased up under the weight.
      final eases = slam + (press - slam) * 0.5;
      final v = t < slam
          ? 1 + (pressTo - 1) * t / slam
          : t < eases
              ? pressTo
              : pressTo + (to - pressTo) * _smooth((t - eases) / (press - eases));
      return (v * 20).round() / 20;
    }

    // Leans back to wind up only once the press is over.
    double tiltAt(double t) {
      if (t < crouch) {
        if (t < press) return 0;
        final k = (t - press) / (crouch - press);
        return windTilt * (1 - (1 - k) * (1 - k));
      }
      if (t < impact) {
        final k = (t - crouch) / rise;
        return windTilt + (tilt - windTilt) * (1 - (1 - k) * (1 - k));
      }
      if (t < drop) return tilt;
      return tilt * (1 - min(1.0, (t - drop) / fall));
    }

    // Grown back from its stone-hopping size as it falls to the bank.
    double growAt(double t) =>
        t < drop ? 0 : min(1.0, (t - drop) / fall);

    return _PetMove(
      duration: ends,
      offsetAt: offsetAt,
      squashAt: squashAt,
      tiltAt: tiltAt,
      growAt: grow ? growAt : null,
      impactAt: impact,
      onImpact: onImpact,
      onEnd: onEnd,
      faceAt: faceAt,
      faceLeft: faceLeft,
      delay: delay,
    );
  }

  /// A bonk and a bounce: up at something that does not give — a sealed door —
  /// and back down off it dizzy, swaying one way and then the other, less and
  /// less, all the way down.
  factory _PetMove.bounce({
    required Offset reach,
    double crouch = 0.08,
    double rise = 0.22,
    double fall = 0.55,
    double delay = 0,
  }) {
    final base = _PetMove.leap(
      reach: reach,
      tilt: 0,
      crouch: crouch,
      rise: rise,
      hold: 0.04,
      fall: fall,
      squash: 0.12,
      shiver: 0,
      dip: 3,
    );
    // When it comes off the door.
    final off = crouch + rise + 0.04;
    return _PetMove(
      duration: base.duration,
      offsetAt: base.offsetAt,
      squashAt: base.squashAt,
      tiltAt: (t) {
        if (t < off) return 0;
        final k = ((t - off) / fall).clamp(0.0, 1.0);
        return 0.45 * sin(k * 3.2 * pi) * (1 - k);
      },
      delay: delay,
    );
  }

  /// Squashed flat by something heavy, held there, then let up. [squash] is
  /// the height it is pressed to.
  factory _PetMove.flatten({
    double squash = 0.5,
    double press = 0.45,
    double spring = 0.15,
    double delay = 0,
    void Function(_Geo geo)? onImpact,
    void Function(_Geo geo)? onEnd,
  }) {
    double squashAt(double t) {
      if (t < press) return squash;
      final k = ((t - press) / spring).clamp(0.0, 1.0);
      return ((squash + (1 - squash) * k) * 20).round() / 20;
    }

    return _PetMove(
      duration: press + spring,
      offsetAt: (_) => Offset.zero,
      squashAt: squashAt,
      impactAt: 0,
      onImpact: onImpact,
      onEnd: onEnd,
      delay: delay,
    );
  }

  /// Tipped over by [tilt] radians and back — nose up or down as the pet
  /// climbs or dives on its broom — in [duration] seconds, without going
  /// anywhere.
  factory _PetMove.tipped({
    required double tilt,
    double duration = 0.45,
    double delay = 0,
  }) =>
      _PetMove(
        duration: duration,
        offsetAt: (_) => Offset.zero,
        tiltAt: (t) => tilt * sin(pi * (t / duration).clamp(0.0, 1.0)),
        delay: delay,
      );

  /// A full turn head over heels, [turns] of them (negative is
  /// counter-clockwise), in [duration] seconds, with a hop's height at the top.
  factory _PetMove.spin({
    required double turns,
    double duration = 0.6,
    double height = 14,
    double delay = 0,
    void Function(_Geo geo)? onEnd,
  }) =>
      _PetMove(
        duration: duration,
        offsetAt: (t) => Offset(
          0,
          (sin(pi * (t / duration).clamp(0.0, 1.0)) * height / 2).roundToDouble() *
              2,
        ),
        tiltAt: (t) => turns * 2 * pi * _smooth(t / duration),
        delay: delay,
        onEnd: onEnd,
      );

  /// Seconds the move takes, once it has begun.
  final double duration;

  /// Where the pet is off where it stands, [Offset.dy] being height, up
  /// positive.
  final Offset Function(double t) offsetAt;

  /// The pet's height as a fraction of itself, its feet planted.
  final double Function(double t)? squashAt;

  /// How far the pet is tipped over, in radians, clockwise.
  final double Function(double t)? tiltAt;

  /// How far the pet has grown back to full size, 0 to 1.
  final double Function(double t)? growAt;

  /// How many turns the pet has spun about its own middle, standing like a
  /// top: 0 and 1 both mean as it was drawn.
  final double Function(double t)? twirlAt;

  /// When the move lands its hit — where a thrown thing leaves the pet's
  /// hands, or what the pet pounced on is struck.
  final double? impactAt;
  final void Function(_Geo geo)? onImpact;

  /// Called once the pet is back where it stands.
  final void Function(_Geo geo)? onEnd;

  /// When the pet turns to [faceLeft] — or never, with no direction.
  final double faceAt;
  final bool? faceLeft;

  /// Seconds before the move begins: the pet is as it was until then.
  final double delay;

  /// What happens partway through it.
  final List<_MoveEvent> events;

  /// Seconds since the move was made.
  double t = 0;
  bool faced = false;
  bool impacted = false;

  /// What the move this one cut in on was doing to the pet at that moment,
  /// which this one starts from and eases out of, so a pet cut off in mid-air
  /// comes down to start again rather than jumping to the ground to do it.
  Offset carryOffset = Offset.zero;
  double carryTilt = 0;
  double carrySquash = 1;

  /// Seconds the carried pose takes to ease out.
  static const double carryFor = 0.16;

  bool get begun => t >= delay;
  double get _local => max(0.0, t - delay);

  /// How much of the carried pose is left: 1 as the move begins, 0 once eased
  /// out.
  double get _carried => 1 - _smooth(_local / carryFor);

  Offset get offset =>
      begun ? offsetAt(_local) + carryOffset * _carried : Offset.zero;
  double get squash {
    if (!begun) return 1;
    final raw = squashAt?.call(_local) ?? 1;
    return raw + (carrySquash - 1) * _carried;
  }

  double get tilt {
    if (!begun) return 0;
    final raw = tiltAt?.call(_local) ?? 0;
    return raw + carryTilt * _carried;
  }

  double get grow => begun ? (growAt?.call(_local) ?? 0) : 0;

  /// How wide the pet is drawn as it twirls, across its own height, in steps:
  /// 1 facing as drawn, down through edge-on to -1 turned right round, and
  /// back. Never quite nothing.
  double get width {
    final turns = begun ? (twirlAt?.call(_local) ?? 0) : 0.0;
    if (turns == 0) return 1;
    final across = (cos(turns * 2 * pi) * 8).round() / 8;
    return across == 0 ? 0.125 : across;
  }
}

extension _PetMoves on _BossTrialScreenState {
  /// Plays [move] now. Cutting in on a move still going, it starts from where
  /// that had got the pet and eases out of it.
  void _playMove(_PetMove move) => _refresh(() {
        final old = _move;
        if (old != null && old.begun && move.delay == 0) {
          move.carryOffset = old.offset;
          move.carryTilt = old.tilt;
          move.carrySquash = old.squash;
        }
        _move = move;
      });

  /// Sends [shot] on its way without the pet hopping to throw it: a stone
  /// that did not come from the pet. Reduced motion lands it at once.
  void _launch(_Geo geo, _Shot shot) {
    _shots.add(shot);
    if (_reduceMotion) _shotLands(geo, shot);
  }

  /// Turns the pet to face [x], from [from], once it is further than
  /// [deadzone] away: straight up and down it keeps the way it was facing.
  void _faceToward(double x, {required double from, double deadzone = 0.5}) {
    if ((x - from).abs() > deadzone) _petFacesLeft = x < from;
  }

  /// Where the pet stands across the bottom of the arena, at the start of
  /// every phase.
  double _petHomeX(_Geo geo) =>
      _petLane == null ? geo.w / 2 : geo.laneCentre(_petLane!);

  /// Runs the pet to [x] — at a pace it can be seen at, a hop to every stride,
  /// facing the way it goes — and keeps it there for [stay] seconds once it
  /// has arrived, before it runs home. [pace] is widths of the arena a second,
  /// slower for a hop-walk, with [hop] the height in pixels of the hop to every
  /// stride: small and quiet for a tiptoe, high for a hop-walk. Returns the
  /// seconds the run takes; with reduced motion the pet is just there.
  double _runTo(_Geo geo, double x,
      {double stay = 0.3, double? pace, double hop = 10}) {
    final speed = pace ?? _BossTrialScreenState._runWidths;
    final run = _reduceMotion ? 0.0 : (x - _petX).abs() / (geo.w * speed);
    _petPace = speed;
    _petHopPx = hop;
    _petGoX = x;
    _petLane = null;
    _petRunning = !_reduceMotion;
    _faceToward(x, from: _petX);
    _petAway = run + stay;
    return run;
  }

  /// Holds the pet where it stands for [seconds], so a jump or a catch it is
  /// making — measured from where it began — is not skewed by the pet being
  /// sent home underneath it; then it goes home.
  void _stayPut(double seconds) {
    _petGoX = _petX;
    _petLane = null;
    _petAway = seconds;
  }

  /// Where a thing the pet throws leaves it, from the lane at [x]: out in front
  /// of its head, toward the boss on [toward] (+1 right, -1 left).
  Offset _throwFrom(_Geo geo, double x, double toward) => Offset(
        x + toward * geo.petBox * 0.22,
        geo.groundTop - geo.petBox * 0.8,
      );

  /// Which side the boss is on, from the lane at [x]: +1 right, -1 left.
  double _bossSide(_Geo geo, double x) => _bossHitPoint(geo).dx >= x ? 1.0 : -1.0;

  /// The offset, from where the pet stands, that takes its head to [target]
  /// (the top of its head sits [_BossTrialScreenState._headHeight] of its size
  /// above its feet), or its feet when [feet]. Dy is height, up positive, and
  /// never negative.
  Offset _reachTo(_Geo geo, Offset target, {bool feet = false}) {
    final size = geo.petBox * _petScale;
    final standing = _petFeet ?? geo.groundTop;
    final head = size * _BossTrialScreenState._headHeight;
    final dy = feet ? standing - target.dy : standing - head - target.dy;
    return Offset(target.dx - _petX, max(0.0, dy));
  }

  /// [target], brought down as far as it takes for the pet's head to be no
  /// more than [most] pixels above where it is standing: whatever is higher is
  /// leapt at as far as a leap goes.
  Offset _withinLeap(_Geo geo, Offset target, {double most = 150}) {
    final standing = _petFeet ?? geo.groundTop;
    final head = standing -
        geo.petBox * _petScale * _BossTrialScreenState._headHeight;
    return Offset(target.dx, max(target.dy, head - most));
  }

  /// A leap at [apex] with a SWAT at the top of it: the head cocked back on the
  /// way up, then the whole body swept round at the thing — from one lean to the
  /// other — and down. [onHit] is called at the swat; the seconds to it are
  /// returned with the move.
  (_PetMove, double) _swatLeap(
    _Geo geo,
    Offset apex, {
    double rise = 0.3,
    double fall = 0.38,
    void Function(_Geo geo)? onHit,
  }) {
    final reach = _reachTo(geo, apex);
    final aside = reach.dx.abs() > 8;
    final dir = aside ? reach.dx.sign : _bossSide(geo, _petX);
    final up = max(0.0, reach.dy - _stretchRise(geo, 1.12));
    final k = _Keyer();
    k.to(0.06, squash: 0.88, dy: -2);
    k.to(rise,
        dx: reach.dx, dy: up, tilt: -dir * 0.5, squash: 1.12, ease: _Ease.out);
    k.to(0.08, tilt: dir * 0.85, dy: up + 4, squash: 1.0, ease: _Ease.linear);
    final hit = k.t;
    k.hold(0.05);
    k.to(fall, dx: 0, dy: 0, tilt: 0, squash: 0.85, ease: _Ease.accelerate);
    k.to(0.14, squash: 1.0);
    if (aside) _petFacesLeft = reach.dx < 0;
    return (
      _PetMove.keys(
        k.keys,
        faceLeft: aside ? reach.dx < 0 : null,
        events: [if (onHit != null) _MoveEvent(hit, onHit)],
      ),
      hit,
    );
  }

  /// The pet winds up leaning back from the boss, then snaps forward and throws
  /// at it. It leaves the pet's hands [releaseAt] seconds after the move
  /// begins — [windUp] and the snap, plus a [press] first if something has
  /// just landed on it — which is when [onRelease] is called.
  _PetMove _throwMove(
    _Geo geo, {
    required double toward,
    double windUp = 0.45,
    double press = 0,
    double delay = 0,
    double squash = 0.12,
    void Function(_Geo geo)? onRelease,
    void Function(_Geo geo)? onEnd,
  }) =>
      _PetMove.leap(
        reach: const Offset(0, 10),
        tilt: toward * pi * 0.14,
        windTilt: -toward * pi * 0.12,
        crouch: press + windUp,
        press: press,
        rise: 0.12,
        hold: 0.08,
        fall: 0.2,
        squash: squash,
        shiver: 0,
        dip: 2,
        delay: delay,
        faceLeft: toward < 0,
        onImpact: onRelease,
        onEnd: onEnd,
      );

  /// Adds to [k] the pet casting at the boss on [toward]: rearing back for
  /// [windUp] seconds, thrusting, holding, and falling back. Returns the seconds
  /// from the start of the move to the thrust, where the spell leaves its hands.
  double _throwKeys(_Keyer k, {required double toward, double windUp = 0.5}) {
    k.to(windUp,
        tilt: -toward * pi * 0.12, squash: 0.88, dy: -2, ease: _Ease.accelerate);
    k.to(0.12,
        tilt: toward * pi * 0.14, squash: 1.0, dy: 10, ease: _Ease.out);
    final release = k.t;
    k.hold(0.08);
    k.to(0.2, tilt: 0, dy: 0, ease: _Ease.accelerate);
    return release;
  }

  /// How much higher a pet stretched to [stretch] of its height has its head
  /// than standing: it is drawn from its feet up. Take it off the height a leap
  /// aims at, to put the head where it was meant to go and no deeper.
  double _stretchRise(_Geo geo, double stretch) =>
      geo.petBox * _petScale * 0.75 * (stretch - 1);

  /// Seconds from the start of a [_throwMove] to its release.
  double _releaseAt({double windUp = 0.45, double press = 0}) =>
      press + windUp + 0.12;

  /// A first round's whole answer found: the pet rears back for half a second
  /// and more, then thrusts it at the boss — the spell leaves it at the thrust,
  /// which is when [onRelease] is called, to burst whatever powered it. With
  /// reduced motion the spell just goes, from [from].
  void _answeredByCast(
    _Geo geo,
    _ClockRound round,
    Offset from, {
    double windUp = 0.5,
    _ShotLook look = _ShotLook.spell,
    void Function(_Geo geo)? onRelease,
  }) {
    HapticFeedback.selectionClick();
    final earliness = 1 - round.clock;
    _refresh(() {
      round.won = true;
      _stage = _Stage.resolving;
      _stageTime = 0;
    });
    _castWhole(geo, earliness, from,
        windUp: windUp, look: look, onRelease: onRelease);
  }

  /// The pet casts a whole answer at the boss: rears back, thrusts, and the
  /// spell leaves it at the thrust — [onRelease] is called then. With reduced
  /// motion the spell just goes, from [from].
  void _castWhole(
    _Geo geo,
    double earliness,
    Offset from, {
    double windUp = 0.5,
    _ShotLook look = _ShotLook.spell,
    void Function(_Geo geo)? onRelease,
  }) {
    if (_reduceMotion) {
      onRelease?.call(geo);
      _launch(
        geo,
        _Shot(
          from: from,
          earliness: earliness,
          whole: true,
          look: look,
        ),
      );
      return;
    }
    final toward = _bossSide(geo, _petX);
    _shots.add(_Shot(
      from: _throwFrom(geo, _petX, toward),
      earliness: earliness,
      whole: true,
      look: look,
      delay: _releaseAt(windUp: windUp),
    ));
    _petFacesLeft = toward < 0;
    _playMove(_throwMove(geo, toward: toward, windUp: windUp, onRelease: onRelease));
  }

  /// How far the pet is wobbling this frame, in radians: while it reads the
  /// witch's scroll, tipped one way and the other, faster and faster — and
  /// wider — the more of the fuse has burnt.
  double _fuseWobble() {
    if (_stage != _Stage.reading || _read == null || _reduceMotion) return 0;
    return sin(_wobblePhase) * (0.04 + 0.12 * _fuse);
  }

  /// How far the pet's head is tipped back this frame, in radians, as it looks
  /// up at the wall of crystals it is tracing a vein across: nose up, whichever
  /// way it faces.
  double _veinLookUp() {
    final round = _vein;
    if (_stage != _Stage.veining || round == null || round.over || _reduceMotion) {
      return 0;
    }
    return _petFacesLeft ? 0.25 : -0.25;
  }

  /// How far through freeing itself the pet is, 0 to 1, with [left] seconds of
  /// its curse to go: nothing till the last second.
  double _shedK(double left) =>
      left <= 0 || left >= _BossTrialScreenState._shedSeconds
          ? 0
          : _smooth((_BossTrialScreenState._shedSeconds - left) /
              _BossTrialScreenState._shedSeconds);

  /// How far the pet is tipped this frame freeing itself: digging out of the
  /// sand, a stroke of one paw and then the other; shaking its head in the ash.
  double _shedWobble() {
    if (_reduceMotion) return 0;
    if (_buried > 0 && _buried < _BossTrialScreenState._shedSeconds) {
      return sin((_BossTrialScreenState._shedSeconds - _buried) * 14) * 0.2;
    }
    if (_scorched > 0 && _scorched < _BossTrialScreenState._shedSeconds) {
      return sin(_shiverPhase * 0.6) * 0.14;
    }
    return 0;
  }

  /// Sand thrown off the pet to one side, then the other, as it digs; ash
  /// flung off as it shakes.
  void _throwOff(_Geo geo, double dt, {required bool sand}) {
    if (_reduceMotion) return;
    _shedTick -= dt;
    if (_shedTick > 0) return;
    _shedTick = sand ? 0.12 : 0.1;
    _shedSide = -_shedSide;
    final box = _petRect(geo);
    final at = Rect.fromCenter(
      center: Offset(box.center.dx + _shedSide * box.width * 0.15,
          box.top + box.height * (sand ? 0.55 : 0.35)),
      width: box.width * 0.3,
      height: 12,
    );
    _particles.gust(at,
        dir: _shedSide,
        colors: sand ? SphinxPalette.dust : DragonPalette.smoke);
  }

  /// How hard the pet is trembling this frame, in pixels either way: the
  /// amethyst creeping up it through an echo, and the crystal round it
  /// cracking in the last half second before it breaks out.
  double _shiverNow() {
    var shiver = 0.0;
    if (_stage == _Stage.echoing && _creep > 0.15) {
      shiver = max(shiver, 3 * _creep * _creep);
    }
    // Nervous, the more of the fuse has burned: the scroll's, the clones',
    // the cauldrons'.
    final fuse = switch (_stage) {
      _Stage.reading => _fuse,
      _Stage.cloning => _clones?.fuse ?? 0.0,
      _Stage.sorting => _tangle?.fuse ?? 0.0,
      _ => 0.0,
    };
    if (fuse > 0.2) shiver = max(shiver, 3.2 * fuse * fuse);
    if (_encased > 0 && _encased < 0.5) {
      shiver = max(shiver, 3.5 * (1 - _encased / 0.5));
    }
    // Under the sand or the ash, it struggles to get out in the last stretch.
    final stuck = max(_buried, _scorched);
    if (stuck > 0 && stuck < 0.6) {
      shiver = max(shiver, (_scorched > 0 ? 5.5 : 3.5) * (1 - stuck / 0.6));
    }
    return shiver;
  }

  /// A cringe: down a little and straight back up.
  _PetMove _flinch({double delay = 0, double squash = 0.82}) =>
      _PetMove.flatten(squash: squash, press: 0.12, spring: 0.14, delay: delay);

  /// The pet cringes from what went wrong at [at], turned to it — unless its
  /// body is busy with something else.
  void _cringeAt(Offset at) {
    _faceToward(at.dx, from: _petX, deadzone: 12);
    if (_move == null) _playMove(_flinch());
  }

  /// The pet's head turns to follow the phase it is in: the cups being swapped,
  /// the spike nearest it, the vein being traced. Only while its body is doing
  /// nothing else.
  void _watchPhase(_Geo geo) {
    if (_move != null) return;
    switch (_stage) {
      case _Stage.shelling:
        _watchShuffle(geo);
      case _Stage.spiking:
        final rush = _spikes;
        if (rush == null) return;
        var lane = -1;
        var most = 0.1;
        for (var l = 0; l < _spikeGrowth.length; l++) {
          if (!rush.isShattered(l) && _spikeGrowth[l] > most) {
            most = _spikeGrowth[l];
            lane = l;
          }
        }
        if (lane >= 0) {
          _faceToward(geo.laneCentre(lane), from: _petX, deadzone: 12);
        }
      case _Stage.veining:
        final round = _vein;
        if (round == null || round.play.followed == 0) return;
        final cell = round.wave.path[round.play.followed - 1];
        _faceToward(_veinRect(geo, cell).center.dx, from: _petX, deadzone: 12);
      case _Stage.cloning:
        _trailOwls(geo);
      case _Stage.storming:
        // Faces into the wind, which blows from the right.
        _petFacesLeft = false;
      case _Stage.netting:
        final round = _net;
        final last = round?.last;
        if (round == null || last == null) return;
        _faceToward(_netFishRect(geo, round, last).center.dx,
            from: _petX, deadzone: 12);
      default:
        break;
    }
  }

  /// How high the frog the witch made of the pet is off the ground, in pixels:
  /// two hops, the first a fifth of a second after the hex lands. Nothing when
  /// it is no frog.
  double _frogHop() {
    if (_frog <= 0 || _reduceMotion) return 0;
    final since = _BossTrialScreenState._frogSeconds - _frog;
    for (final start in const [0.2, 0.75]) {
      final k = (since - start) / 0.4;
      if (k >= 0 && k <= 1) return (sin(k * pi) * 16 / 2).roundToDouble() * 2;
    }
    return 0;
  }

  /// A comeback: the small hop the pet makes standing up again, after being
  /// under the water or flattened. Skipped with reduced motion.
  void _springUp(_Geo geo) {
    if (!_reduceMotion) _petSpring = 0;
  }

  /// Advances the pet's move one frame: turns it, lands the hit, and puts
  /// it back at the end.
  void _stepMove(double dt, _Geo geo) {
    final move = _move;
    if (move == null) return;
    move.t += dt;
    if (!move.begun) return;
    final local = move.t - move.delay;
    final face = move.faceLeft;
    if (face != null && !move.faced && local >= move.faceAt) {
      move.faced = true;
      _petFacesLeft = face;
    }
    final impactAt = move.impactAt;
    if (impactAt != null && !move.impacted && local >= impactAt) {
      move.impacted = true;
      move.onImpact?.call(geo);
    }
    for (final event in move.events) {
      if (!event.fired && local >= event.at) {
        event.fired = true;
        event.run(geo);
      }
    }
    if (local >= move.duration) {
      _move = null;
      // Back where it stands, as its art is drawn.
      _petFacesLeft = false;
      move.onEnd?.call(geo);
    }
  }
}
