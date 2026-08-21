import 'package:flutter/material.dart';

import '../constants/theme.dart';

/// The pixel grid one heart is drawn on, which sets its aspect ratio.
const int _kHeartCols = 9;
const int _kHeartRows = 8;

/// The little hearts that pop off the pet when petting actually pays.
///
/// Deliberately tied to the payout rather than to the rub. Petting itself is
/// free and unlimited — the pet reacts every single time a hand goes on it —
/// but happiness is only granted once per cooldown, and hearts are the tell
/// for which of the two just happened. A heart on every rub would promise a
/// reward the player is not getting.
///
/// Plays on [burstId] changing, so the caller triggers a burst by handing it a
/// new number rather than by reaching in through a key.
class PetHearts extends StatefulWidget {
  const PetHearts({super.key, required this.burstId, this.baseSize = 22});

  /// Bump this to play a burst. Its value carries no meaning; only the change
  /// does.
  final int burstId;

  /// Font size of the middle heart. The outer two step down from it.
  final double baseSize;

  @override
  State<PetHearts> createState() => _PetHeartsState();
}

class _PetHeartsState extends State<PetHearts>
    with SingleTickerProviderStateMixin {
  /// One burst, start to finish. Long enough to be read as a reward, short
  /// enough that a second payout never lands on top of the first — the pet
  /// cooldown is minutes.
  static const Duration _burst = Duration(milliseconds: 1100);

  /// Where each heart starts, in multiples of [PetHearts.baseSize] from the
  /// centre, and how far up it drifts. The middle one goes highest.
  static const List<Offset> _origins = [
    Offset(-1.1, 0),
    Offset(0, -0.25),
    Offset(1.0, 0.1),
  ];
  static const List<double> _rise = [1.6, 2.3, 1.5];
  static const List<double> _scales = [0.72, 1.0, 0.62];

  /// How far each heart lags the one before it, as a fraction of the burst.
  static const double _stagger = 0.12;

  late final AnimationController _controller;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _burst);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  @override
  void didUpdateWidget(PetHearts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.burstId != oldWidget.burstId) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Progress of the heart at [index] through its own life, or null before it
  /// has started and after it has gone.
  double? _phaseFor(int index, double t) {
    final phase = (t - index * _stagger) / (1 - _stagger * _origins.length);
    if (phase <= 0 || phase >= 1) return null;
    return phase;
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseSize;

    return IgnorePointer(
      child: SizedBox(
        width: base * 4,
        height: base * 4,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            // Nothing to draw between bursts, which is most of the time.
            if (t == 0 || t == 1) return const SizedBox.shrink();

            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < _origins.length; i++) ..._heart(i, t, base),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _heart(int index, double t, double base) {
    final phase = _phaseFor(index, t);
    if (phase == null) return const [];

    // Up and away, fading over the back half. Reduce-motion keeps the heart
    // parked at its origin and just fades it, so the reward still registers
    // without anything flying across the screen.
    final rise = _reduceMotion ? 0.0 : Curves.easeOut.transform(phase);
    final opacity = phase < 0.5 ? 1.0 : 1.0 - (phase - 0.5) * 2;

    // Pops in, then settles: a heart that arrived at full size would just
    // appear, and this is meant to feel like it burst out of the pet.
    final pop = phase < 0.25 ? 0.6 + (phase / 0.25) * 0.4 : 1.0;

    return [
      Positioned(
        left: base * 1.6 + _origins[index].dx * base,
        bottom:
            base * 0.4 + _origins[index].dy * base + rise * _rise[index] * base,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: CustomPaint(
            size: Size(base * _scales[index] * pop,
                base * _scales[index] * pop * _kHeartRows / _kHeartCols),
            painter: const _PixelHeart(),
          ),
        ),
      ),
    ];
  }
}

/// A heart drawn as pixels rather than set as a glyph.
///
/// The obvious version was a text '♥', and it came out as tofu: the pixel font
/// the game is set in has no such character. Painting it makes the heart match
/// the pet's own art — same hard outline, same blocky edges — and removes the
/// question of which fonts on which devices happen to carry the glyph.
class _PixelHeart extends CustomPainter {
  const _PixelHeart();

  /// '#' outline, 'o' fill, '.' empty. Read top-down.
  static const List<String> _pattern = [
    '..##.##..',
    '.#oo#oo#.',
    '#ooooooo#',
    '#ooooooo#',
    '.#ooooo#.',
    '..#ooo#..',
    '...#o#...',
    '....#....',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _kHeartCols;
    final fill = Paint()..color = AppTheme.retroPrimary;
    final outline = Paint()..color = AppTheme.retroDark;

    for (var row = 0; row < _pattern.length; row++) {
      for (var col = 0; col < _pattern[row].length; col++) {
        final glyph = _pattern[row][col];
        if (glyph == '.') continue;
        canvas.drawRect(
          // Overdrawn by a hair: adjacent cells rounded to different device
          // pixels leave hairline gaps through the heart otherwise.
          Rect.fromLTWH(col * cell, row * cell, cell + 0.5, cell + 0.5),
          glyph == '#' ? outline : fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PixelHeart oldDelegate) => false;
}
