import 'dart:async';

import 'package:flutter/widgets.dart';

/// The one clock all the pixel-stepped idle motion runs on, 8 steps a second.
///
/// The pet's breath, blink, tail flick and petting rock, the sleep trail and
/// the chat's online dot all move in whole steps on an 8 fps grid — that is
/// the look. They used to be driven by [AnimationController]s, and a
/// controller asks for a new frame at every refresh of the screen: 60 a
/// second on a phone, 180 on a fast monitor. Every one of those frames redraws
/// the whole screen, so a home screen whose picture changed 8 times a second
/// was being drawn 60 times, and on a mid-range phone that was most of what it
/// had to give.
///
/// One shared timer at the grid's own rate fixes both halves of that: nothing
/// asks for a frame between steps, and every listener steps in the same frame,
/// so a screen with seven pets on it still redraws 8 times a second rather
/// than 56.
///
/// It only runs while something listens. Listen through [PixelClockListener],
/// which also lets go while its route is hidden or motion is reduced.
class PixelClock extends ChangeNotifier {
  PixelClock._();

  static final PixelClock instance = PixelClock._();

  /// Steps a second.
  static const int fps = 8;

  /// How long one step lasts.
  static const Duration step = Duration(microseconds: 1000000 ~/ fps);

  Timer? _timer;

  /// Whether the clock is ticking — that is, whether anything listens.
  @visibleForTesting
  bool get isRunning => _timer != null;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _timer ??= Timer.periodic(step, (_) => notifyListeners());
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      _timer?.cancel();
      _timer = null;
    }
  }
}

/// A widget's hold on [PixelClock], kept only while it should move.
///
/// That is while the caller says it may — reduce-motion is the caller's to
/// read — and while its route is on screen. The second is what [TickerMode]
/// tells animation controllers, and it matters as much here: the home screen
/// stays mounted under a pushed route, and its pet must not go on stepping
/// there, asking for frames on behalf of a screen nobody can see.
class PixelClockListener {
  PixelClockListener(this.onStep);

  /// Called on every step while listening.
  final VoidCallback onStep;

  bool _listening = false;

  /// Starts or stops listening. Call it from [State.didChangeDependencies],
  /// which is also what reruns it when the route is covered or uncovered.
  void update(BuildContext context, {required bool animate}) {
    final listen = animate && TickerMode.valuesOf(context).enabled;
    if (listen == _listening) return;
    _listening = listen;
    if (listen) {
      PixelClock.instance.addListener(onStep);
    } else {
      PixelClock.instance.removeListener(onStep);
    }
  }

  void dispose() {
    if (_listening) PixelClock.instance.removeListener(onStep);
    _listening = false;
  }
}
