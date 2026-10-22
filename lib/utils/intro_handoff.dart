import 'dart:ui';

/// Where the meet-your-pet screen left the pet, so the home screen can pick
/// it up from exactly there.
///
/// The two screens draw the pet at different sizes in different places, and
/// the join between them should not be a cut. The obvious fix — have the
/// tutorial animate the pet into home's resting pose before navigating —
/// needs the tutorial to predict home's layout, and it cannot: home's pet
/// area is what is left after an input dock whose height comes out of the
/// font metrics of whatever locale is loaded.
///
/// So the measurement goes the other way. The tutorial reports where its pet
/// actually was, in global screen coordinates, and home starts the pet there
/// and animates it home. Nothing is predicted and no layout constant is
/// duplicated across the two files.
///
/// Left behind rather than passed as go_router's `extra`, and the reason is
/// worth knowing before anyone tidies it. Finishing onboarding writes a flag
/// that the router listens to, so the redirect fires the instant the flag is
/// set and carries the player home on its own — a redirect cannot take an
/// `extra`, so a pose handed to a later `go()` would arrive after home had
/// already opened without it. This is dropped off before the flag is set and
/// claimed by whichever home screen opens next, whichever route drove it.
class IntroHandoff {
  const IntroHandoff(this.petRect);

  static IntroHandoff? _pending;

  /// Leaves [handoff] for the next home screen to pick up.
  static void leave(IntroHandoff handoff) => _pending = handoff;

  /// Takes the waiting pose, if there is one. Claiming clears it: an arrival
  /// happens once, and a second home screen in the same session is an
  /// ordinary visit.
  static IntroHandoff? claim() {
    final pending = _pending;
    _pending = null;
    return pending;
  }

  /// Drops anything waiting. For tests, and for a flow that changes its mind.
  static void reset() => _pending = null;

  /// The pet's sprite box in global coordinates, as the tutorial last drew it.
  ///
  /// The box, not the art: both screens plant the sprite's box on the ground
  /// and centre it horizontally, so its width and its bottom edge are enough
  /// to reconstruct the pose on the other side.
  final Rect petRect;
}
