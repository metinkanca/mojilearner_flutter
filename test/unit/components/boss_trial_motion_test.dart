import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/boss_trial/boss_motion.dart';
import 'package:mojilearner_flutter/components/boss_trial/trial_particles.dart';

Duration ms(int n) => Duration(milliseconds: n);

void main() {
  group('BossMotion.jump', () {
    test('the phases run in order: crouch, rise, shout, land, settle', () {
      expect(BossMotion.shoutAt, BossMotion.crouch + BossMotion.rise);
      expect(BossMotion.landAt > BossMotion.shoutAt, isTrue);
      expect(BossMotion.jumpEnds > BossMotion.landAt, isTrue);
    });

    test('sinks before it leaves the ground', () {
      final pose = BossMotion.jump(BossMotion.crouch - ms(10));
      expect(pose.lift, 0);
      expect(pose.scaleY, lessThan(1));
      expect(pose.scaleX, greaterThan(1));
    });

    test('is at the top of the jump, mouth open, when it shouts', () {
      final pose = BossMotion.jump(BossMotion.shoutAt + ms(20));
      expect(pose.lift, 1);
      expect(pose.mouthOpen, isTrue);
    });

    test('keeps its mouth shut until the top of the jump', () {
      expect(BossMotion.jump(BossMotion.shoutAt - ms(20)).mouthOpen, isFalse);
    });

    test('is back on the ground and squashed just after landing', () {
      final pose = BossMotion.jump(BossMotion.landAt + ms(10));
      expect(pose.lift, 0);
      expect(pose.scaleY, lessThan(1));
    });

    test('ends exactly at rest', () {
      final pose = BossMotion.jump(BossMotion.jumpEnds + ms(1));
      expect(pose.lift, 0);
      expect(pose.scaleX, 1);
      expect(pose.scaleY, 1);
    });

    test('moves in steps, not smoothly', () {
      // Two frames a sixtieth of a second apart often hold the same pose.
      final lifts = {
        for (var t = 140; t < 400; t += 16)
          BossMotion.jump(ms(t)).lift,
      };
      expect(lifts.length, lessThanOrEqualTo(9));
      for (final lift in lifts) {
        expect((lift * 8) % 1, 0);
      }
    });
  });

  group('BossMotion.hit', () {
    test('flashes, flinches, and recovers to rest', () {
      final start = BossMotion.hit(ms(10));
      expect(start.flash, isTrue);
      expect(start.scaleY, lessThan(1));
      expect(BossMotion.hit(BossMotion.flash + ms(10)).flash, isFalse);
      final end = BossMotion.hit(BossMotion.flinch);
      expect(end.scaleX, 1);
      expect(end.dx, 0);
    });

    test('knocks the boss by whole pixels only', () {
      for (var t = 0; t < 260; t += 13) {
        final dx = BossMotion.hit(ms(t)).dx;
        expect(dx, dx.roundToDouble());
      }
    });
  });

  group('BossMotion.getaway', () {
    test('flinches, crouches to power up, then leaps off', () {
      // The last hit lands first.
      final (flinch, flinchAway) = BossMotion.getaway(ms(10));
      expect(flinch.flash, isTrue);
      expect(flinchAway, 0);

      // Powering up: sunk low, going nowhere yet, the mouth opening near
      // the end.
      final crouchAt = BossMotion.flinch + BossMotion.powerUp * 0.6;
      final (crouch, crouchAway) = BossMotion.getaway(crouchAt);
      expect(crouch.scaleY, lessThan(0.9));
      expect(crouch.scaleX, greaterThan(1.05));
      expect(crouchAway, 0);
      final (lastBeat, _) =
          BossMotion.getaway(BossMotion.launchAt - ms(20));
      expect(lastBeat.mouthOpen, isTrue);

      // The leap: stretched, fast off the ledge, and all the way gone.
      final (leap, leapAway) =
          BossMotion.getaway(BossMotion.launchAt + BossMotion.launch * 0.3);
      expect(leap.scaleY, greaterThan(1));
      expect(leapAway, greaterThan(0.45), reason: 'quick off the mark');
      final (_, gone) = BossMotion.getaway(BossMotion.getawayEnds);
      expect(gone, 1);
    });

    test('shudders by whole pixels while it powers up', () {
      final shakes = <double>{};
      for (var t = BossMotion.flinch.inMilliseconds;
          t < BossMotion.launchAt.inMilliseconds;
          t += 15) {
        final (pose, _) = BossMotion.getaway(ms(t));
        expect(pose.dx, pose.dx.roundToDouble());
        shakes.add(pose.dx.sign);
      }
      expect(shakes, containsAll([1.0, -1.0]));
    });
  });

  group('TrialParticles', () {
    test('debris falls under gravity and is gone at the floor', () {
      final particles = TrialParticles();
      particles.shatter(const Rect.fromLTWH(100, 100, 20, 20));
      expect(particles.items, isNotEmpty);

      final before = particles.items.map((p) => p.vy).toList();
      particles.update(0.05, floor: 1000);
      final after = particles.items.map((p) => p.vy).toList();
      for (var i = 0; i < before.length; i++) {
        expect(after[i], greaterThan(before[i]));
      }

      for (var i = 0; i < 100; i++) {
        particles.update(0.05, floor: 130);
      }
      expect(particles.isEmpty, isTrue);
    });

    test('a landing throws chunks out to both sides', () {
      final particles = TrialParticles();
      particles.landing(
        left: const Offset(100, 200),
        right: const Offset(300, 200),
        scale: 1,
      );
      final chunks = particles.items.where((p) => p.gravity > 100);
      expect(chunks.where((p) => p.vx < 0 && p.x < 200), isNotEmpty);
      expect(chunks.where((p) => p.vx > 0 && p.x > 200), isNotEmpty);
      expect(chunks.every((p) => p.vy < 0), isTrue, reason: 'kicked upward');
    });

    test('shrinks in whole pixels rather than fading', () {
      final p = TrialParticle(
        x: 0, y: 0, vx: 0, vy: 0, size: 6,
        color: DebrisPalette.stone, life: 1,
      );
      for (var age = 0.0; age < 1; age += 0.05) {
        p.age = age;
        expect(p.drawnSize, p.drawnSize.roundToDouble());
        expect(p.drawnSize, greaterThanOrEqualTo(1));
      }
    });
  });
}
