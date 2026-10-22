/// How the bosses move: Mossback's jump that throws each wave, the witch's
/// swoop from side to side, and the flinch when something comes back at them.
///
/// Pure timing maths, no widgets, so the choreography can be tuned and tested
/// on its own. Motion is stepped the way the pets' is — whole pixels and a
/// coarse scale grid — so the boss reads as the same pixel art mid-jump
/// rather than smearing between frames.
library;

import 'dart:math';

/// One frame of the boss.
class BossPose {
  const BossPose({
    this.lift = 0,
    this.scaleX = 1,
    this.scaleY = 1,
    this.dx = 0,
    this.drift = 0,
    this.mouthOpen = false,
    this.flash = false,
  });

  /// Height off the ground as a fraction of the jump (0 = standing, 1 = top).
  final double lift;

  /// Squash and stretch, anchored at the feet.
  final double scaleX;
  final double scaleY;

  /// Sideways knock, in design pixels.
  final double dx;

  /// Where a flying boss is across the arena, from -1 (as far left as it
  /// goes) to 1 (as far right). Always 0 for one that stands on the ledge.
  final double drift;

  final bool mouthOpen;

  /// Drawn white for a frame when hit.
  final bool flash;

  static const BossPose rest = BossPose();
}

class BossMotion {
  BossMotion._();

  // ---- the jump, timed from the start of a wave -------------------------

  /// Anticipation: it sinks before it leaves the ground.
  static const Duration crouch = Duration(milliseconds: 140);

  /// Up to the top of the jump.
  static const Duration rise = Duration(milliseconds: 260);

  /// Held at the top, where it shouts.
  static const Duration hang = Duration(milliseconds: 140);

  /// Back down. The wave's rubble breaks loose on the landing.
  static const Duration fall = Duration(milliseconds: 180);

  /// Recovering from the landing squash.
  static const Duration settle = Duration(milliseconds: 200);

  /// How long the mouth stays open, counted from the top of the jump.
  static const Duration shout = Duration(milliseconds: 700);

  static Duration get shoutAt => crouch + rise;
  static Duration get landAt => crouch + rise + hang + fall;
  static Duration get jumpEnds => landAt + settle;

  /// The boss mid-jump, [t] after the wave began.
  static BossPose jump(Duration t) {
    final ms = t.inMicroseconds / 1000;
    final mouthOpen = t >= shoutAt && t < shoutAt + shout;

    double lift = 0, sx = 1, sy = 1;
    final c = crouch.inMilliseconds;
    final r = c + rise.inMilliseconds;
    final h = r + hang.inMilliseconds;
    final f = h + fall.inMilliseconds;
    final s = f + settle.inMilliseconds;

    if (ms < c) {
      final k = ms / c;
      sy = 1 - 0.10 * k;
      sx = 1 + 0.06 * k;
    } else if (ms < r) {
      final k = (ms - c) / (r - c);
      lift = 1 - pow(1 - k, 2).toDouble(); // decelerating
      sy = 1.08 - 0.08 * k;
      sx = 0.95 + 0.05 * k;
    } else if (ms < h) {
      lift = 1;
    } else if (ms < f) {
      final k = (ms - h) / (f - h);
      lift = 1 - k * k; // accelerating
      sy = 1 + 0.08 * k;
      sx = 1 - 0.05 * k;
    } else if (ms < s) {
      final k = (ms - f) / (s - f);
      sy = 0.86 + 0.14 * k;
      sx = 1.10 - 0.10 * k;
    }
    return _stepped(BossPose(
      lift: lift,
      scaleX: sx,
      scaleY: sy,
      mouthOpen: mouthOpen,
    ));
  }

  // ---- the flinch, timed from the impact ----------------------------------

  static const Duration flinch = Duration(milliseconds: 260);
  static const Duration flash = Duration(milliseconds: 90);

  /// The boss recoiling [t] after rubble hit it.
  static BossPose hit(Duration t) {
    if (t >= flinch) return BossPose.rest;
    final k = t.inMicroseconds / flinch.inMicroseconds;
    final ease = 1 - k;
    return _stepped(BossPose(
      scaleX: 1 + 0.08 * ease,
      scaleY: 1 - 0.08 * ease,
      dx: 8 * ease * (k < 0.25 ? 1 : -0.4),
      flash: t < flash,
    ));
  }

  // ---- getting away, timed from the hit that sends it ----------------------

  /// Powering up for the big jump: sinking deep, and shuddering harder as it
  /// gathers itself. Starts once the last hit's [flinch] is over.
  static const Duration powerUp = Duration(milliseconds: 700);

  /// Then up and off the top of the arena.
  static const Duration launch = Duration(milliseconds: 550);

  static Duration get launchAt => flinch + powerUp;
  static Duration get getawayEnds => launchAt + launch;

  /// The boss [t] after the hit that sends it away — the flinch, the
  /// power-up, the leap — and how far along the leap it is, 0 to 1, for the
  /// screen to carry it off by.
  static (BossPose, double) getaway(Duration t) {
    if (t < flinch) return (hit(t), 0);
    if (t < launchAt) {
      final k = (t - flinch).inMicroseconds / powerUp.inMicroseconds;
      // Most of the sinking early, then held low while it shudders.
      final sink = 1 - pow(1 - k, 3).toDouble();
      final shudder = ((t.inMilliseconds ~/ 45).isEven ? 1 : -1) * 3 * k;
      return (
        _stepped(BossPose(
          scaleY: 1 - 0.18 * sink,
          scaleX: 1 + 0.10 * sink,
          dx: shudder,
          mouthOpen: k > 0.7,
        )),
        0,
      );
    }
    final k = ((t - launchAt).inMicroseconds / launch.inMicroseconds)
        .clamp(0.0, 1.0);
    return (
      _stepped(BossPose(
        // Stretched out of the crouch, easing back as it goes.
        scaleY: 1.14 - 0.14 * k,
        scaleX: 0.92 + 0.08 * k,
        mouthOpen: true,
      )),
      // Fast off the ledge, and gone before it could slow.
      1 - (1 - k) * (1 - k),
    );
  }

  // ---- idle -----------------------------------------------------------------

  /// A slow breath while nothing is happening, [t] into the idle loop.
  static BossPose idle(Duration t) {
    const period = 1800;
    final phase = (t.inMilliseconds % period) / period;
    return _stepped(BossPose(scaleY: 1 + 0.02 * sin(phase * 2 * pi)));
  }

  /// Scale snapped to a 2% grid and the knock to whole pixels, so a pose
  /// holds for several frames and then jumps — the pets' stepped look.
  static BossPose _stepped(BossPose p) => BossPose(
        lift: (p.lift * 8).round() / 8,
        scaleX: (p.scaleX * 50).round() / 50,
        scaleY: (p.scaleY * 50).round() / 50,
        dx: p.dx.roundToDouble(),
        drift: (p.drift * 24).round() / 24,
        mouthOpen: p.mouthOpen,
        flash: p.flash,
      );
}

/// How the witch moves. She never lands: she hovers, bobbing, and each spell
/// begins with a swoop across to the other side of the arena, dipping on the
/// way, reading the spell out as she arrives.
///
/// [BossPose.lift] is her height above the line she hovers on, as a fraction
/// of the arena's jump height — which is small for a flyer, so these run
/// larger than Mossback's — and it goes below zero at the bottom of a swoop.
class WitchMotion {
  WitchMotion._();

  /// Across to the other side. The spell appears when she gets there.
  static const Duration swoop = Duration(milliseconds: 620);

  /// Mouth open from a little before she arrives, for this long.
  static const Duration castAt = Duration(milliseconds: 420);
  static const Duration cast = Duration(milliseconds: 700);

  static Duration get arriveAt => swoop;
  static Duration get ends => castAt + cast;

  /// The resting bob, [t] into the loop.
  static BossPose hover(Duration t) {
    const period = 1600;
    final phase = (t.inMilliseconds % period) / period;
    return BossMotion._stepped(
        BossPose(lift: 0.5 + 0.35 * sin(phase * 2 * pi)));
  }

  /// [t] into a swoop from side [from] to side [to], each from -1 to 1,
  /// bobbing on [hoverT] once she is there.
  static BossPose swoopFrom(
    Duration t, {
    required double from,
    required double to,
    required Duration hoverT,
  }) {
    final mouthOpen = t >= castAt && t < castAt + cast;
    if (t >= swoop) {
      final rest = hover(hoverT);
      return BossPose(lift: rest.lift, drift: to, mouthOpen: mouthOpen);
    }
    final k = t.inMicroseconds / swoop.inMicroseconds;
    // Eased in and out, dipping through the middle and leaning into it.
    final ease = k * k * (3 - 2 * k);
    final dip = sin(pi * k);
    return BossMotion._stepped(BossPose(
      lift: 0.5 - 2.2 * dip,
      scaleX: 1 + 0.06 * dip,
      scaleY: 1 - 0.04 * dip,
      drift: from + (to - from) * ease,
      mouthOpen: mouthOpen,
    ));
  }
}
