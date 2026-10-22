import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/boss_trial/mossback_pieces.dart';
import 'package:mojilearner_flutter/components/character_sprite.dart';

/// One frame of the pet's body in a boss trial, as a player sees it.
class PetSample {
  const PetSample({
    required this.x,
    required this.feet,
    required this.head,
    required this.height,
    required this.tilt,
    required this.squash,
    required this.width,
    required this.facesLeft,
  });

  /// Where its middle is, where its feet are, and where the top of its head
  /// is (screen coordinates, down positive: higher in the air is a smaller
  /// number); and how tall its box is drawn (smaller on a stone or a broom).
  final double x, feet, head, height;

  /// How far it is tipped over, in radians, clockwise.
  final double tilt;

  /// Its height as a fraction of itself: 1 standing, lower squashed.
  final double squash;

  /// Its width as a fraction of itself: 1 as drawn, narrower the further it
  /// is twirled round about its middle, -1 turned right round.
  final double width;

  /// Whether it is turned to face left (its art faces right).
  final bool facesLeft;
}

/// Reads the pet off a [BossTrialScreen] under test. Everything here is what
/// the screen draws, not what it holds: the sprite's box, and the transforms
/// the pet's widget is wrapped in (keys `pet-squash`, `pet-tilt`, `pet-flip`,
/// `pet-waterline`).
class PetProbe {
  PetProbe(this.tester);

  final WidgetTester tester;

  Finder get _sprite => find.byType(CharacterSprite).first;

  RenderBox get _box => _sprite.evaluate().first.renderObject! as RenderBox;

  /// The sprite's box as laid out, before the pet is tipped over or squashed.
  Size get size => _box.size;

  /// The sprite's box as drawn, from its top left corner to its bottom right
  /// one. A fair picture of the pet only while it stands straight: the corners
  /// swing round when it is tipped, so read positions off [middle], [feet],
  /// [head] and [x] instead.
  Rect get rect => tester.getRect(_sprite);

  /// The middle of the sprite's box as drawn. The pet turns about its middle,
  /// so this does not move when it is tipped over.
  Offset get middle => _box.localToGlobal(size.center(Offset.zero));

  /// Its sprite's box runs a tenth of its height below its feet, and the top
  /// of its head is 0.65 of its height above them: both shortened with the
  /// pet when it is squashed (it is scaled about its feet), and neither
  /// shifted when it is tipped.
  double get feet => middle.dy + size.height * 0.4 * squash;
  double get head => feet - size.height * 0.65 * squash;
  double get x => middle.dx;

  /// How tall it is drawn: its box, less what a squash takes off it.
  double get height => size.height * squash;

  List<double> _matrix(String key) => tester
      .widget<Transform>(find.byKey(ValueKey(key)))
      .transform
      .storage;

  double get tilt {
    final m = _matrix('pet-tilt');
    return atan2(m[1], m[0]);
  }

  double get squash => _matrix('pet-squash')[5];
  double get width => _matrix('pet-squash')[0];
  bool get facesLeft => _matrix('pet-flip')[0] < 0;

  /// Whether the pet is cut off at a water line (it is going under).
  bool get underwater =>
      (tester
                  .widget<ClipRect>(find.byKey(const ValueKey('pet-waterline')))
                  .clipper! as WaterlineClipper)
              .line !=
          null;

  PetSample get sample => PetSample(
        x: x,
        feet: feet,
        head: head,
        height: height,
        tilt: tilt,
        squash: squash,
        width: width,
        facesLeft: facesLeft,
      );

  /// Runs the game clock [frames] frames, a sample after each.
  Future<List<PetSample>> track(int frames) async {
    final samples = <PetSample>[];
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      samples.add(sample);
    }
    return samples;
  }
}

/// Handy reductions over a run of samples.
extension PetSamples on List<PetSample> {
  double get highest => map((s) => s.feet).reduce(min);
  double get highestHead => map((s) => s.head).reduce(min);
  double get lowestSquash => map((s) => s.squash).reduce(min);
  double get farLeft => map((s) => s.x).reduce(min);
  double get farRight => map((s) => s.x).reduce(max);

  /// The index of the first frame [test] holds, or -1.
  int firstWhere(bool Function(PetSample s) test) => indexWhere(test);

  /// How far x ranges over the run.
  double get xSpread => farRight - farLeft;

  /// How far round the pet has gone over the run, in radians, clockwise
  /// positive. The probe reads a tilt that wraps at a half turn, so this adds
  /// up the frames' steps.
  double get turned {
    var total = 0.0;
    for (var i = 1; i < length; i++) {
      var step = this[i].tilt - this[i - 1].tilt;
      if (step > pi) step -= 2 * pi;
      if (step < -pi) step += 2 * pi;
      total += step;
    }
    return total;
  }

  /// How many separate times the pet's feet leave [ground] by [by] pixels or
  /// more. A hop is over once they are back within half of that, so a squash
  /// flickering the reading about [by] on the way down is not a second hop.
  int hops(double ground, {double by = 8}) {
    var count = 0;
    var up = false;
    for (final s in this) {
      if (!up && s.feet < ground - by) {
        count++;
        up = true;
      } else if (up && s.feet > ground - by / 2) {
        up = false;
      }
    }
    return count;
  }

  /// Seconds (to the frame) before the first frame [test] holds.
  int msUntil(bool Function(PetSample s) test) {
    final i = indexWhere(test);
    return i < 0 ? -1 : (i + 1) * 16;
  }
}
