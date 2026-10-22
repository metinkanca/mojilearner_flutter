import 'dart:ui';

/// The rub-the-head-to-pet gesture, as rules rather than as widget state.
///
/// Extracted from the home screen so the onboarding tutorial can teach the
/// same gesture it will later ask for. A tutorial that trained a slightly
/// different motion than the one the game accepts would be worse than no
/// tutorial: the player would learn something that then stopped working.
///
/// The gesture is deliberately not a swipe. What reads as affection is the
/// rubbing back and forth, so what is counted is direction changes, not
/// distance travelled — [_legTravel] measures the current leg so that a
/// reversal only counts once the finger has actually gone somewhere.
class HeadScratchDetector {
  HeadScratchDetector({required this.onScratch});

  /// Called once per registered rub, which may be many times in one drag.
  final void Function() onScratch;

  /// The head's slice of the sprite box, as fractions of the box height from
  /// its top. The shared viewBox is "-20 -90 222 328"; the ears start at art
  /// y = 0 and the head meets the body around y = 110, which is 0.27..0.61 of
  /// the box. Opened up a little either side, because a scratch is aimed with
  /// a fingertip at a moving target and should not need to be precise.
  static const double headTopFactor = 0.20;
  static const double headBottomFactor = 0.66;

  /// The art's own aspect ratio, width over height. The hitbox is rebuilt
  /// from the numbers that place the sprite rather than measured off the
  /// widget: the art is breathing, and a hitbox that breathed with it would
  /// slide out from under the finger.
  static const double petAspect = 222 / 328;

  /// How far one sweep has to travel, as a fraction of the pet's width. Small
  /// enough for a flick of the thumb, big enough that a finger jittering in
  /// place cannot pet the pet by holding still.
  static const double strokeFactor = 0.07;

  /// Direction changes that make a scratch. Two means back-and-forth-and-back:
  /// one wipe across the head is a swipe, three legs of it is a rub.
  static const int strokesPerPet = 2;

  bool _onHead = false;
  double? _lastX;
  int _direction = 0;
  double _legTravel = 0;
  int _reversals = 0;

  /// Whether the drag in progress started on the pet's head.
  bool get isOnHead => _onHead;

  /// Whether [point], in the pet layer's coordinates, lands on the head.
  ///
  /// The sprite box is centred horizontally in a scene of [sceneSize] and
  /// planted [footOffset] above its bottom edge.
  static bool isOnPetHead(
    Offset point, {
    required Size sceneSize,
    required double petWidth,
    required double footOffset,
  }) {
    final boxHeight = petWidth / petAspect;
    final boxLeft = (sceneSize.width - petWidth) / 2;
    if (point.dx < boxLeft || point.dx > boxLeft + petWidth) return false;

    final boxTop = sceneSize.height - footOffset - boxHeight;
    final y = point.dy - boxTop;
    return y >= boxHeight * headTopFactor && y <= boxHeight * headBottomFactor;
  }

  void start(Offset localPosition,
      {required Size sceneSize,
      required double petWidth,
      required double footOffset}) {
    reset();
    _onHead = isOnPetHead(localPosition,
        sceneSize: sceneSize, petWidth: petWidth, footOffset: footOffset);
    _lastX = localPosition.dx;
  }

  void update(Offset localPosition, {required double petWidth}) {
    if (!_onHead) return;

    final lastX = _lastX;
    _lastX = localPosition.dx;
    if (lastX == null) return;

    final dx = localPosition.dx - lastX;
    if (dx == 0) return;
    final direction = dx > 0 ? 1 : -1;

    if (direction == _direction) {
      _legTravel += dx.abs();
      return;
    }

    // Turned around. Only a leg long enough to be deliberate counts, which is
    // what keeps a slow diagonal drag from registering as frantic scratching.
    if (_direction != 0 && _legTravel >= petWidth * strokeFactor) {
      _reversals++;
      if (_reversals >= strokesPerPet) {
        _reversals = 0;
        onScratch();
      }
    }
    _direction = direction;
    _legTravel = dx.abs();
  }

  void reset() {
    _onHead = false;
    _lastX = null;
    _direction = 0;
    _legTravel = 0;
    _reversals = 0;
  }
}
