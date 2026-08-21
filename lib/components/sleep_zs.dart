import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/theme.dart';
import '../providers/settings_provider.dart';
import '../utils/fonts.dart';

/// The "z z z" that drifts off a sleeping pet.
///
/// Three glyphs on a diagonal, largest at the bottom and smallest at the top,
/// each fading up and then all the way out, one after the other, so the trail
/// reads as rising away from the pet and dissolving. Sizing is driven by
/// [baseSize] rather than fixed points, so the trail stays in proportion to
/// whatever the pet is scaled to.
///
/// Rendered next to the pet rather than on it: the sprite is pixel art on a
/// fixed viewBox, and anything drawn inside that box would have to be baked
/// into the art to stay aligned.
class SleepZs extends StatefulWidget {
  const SleepZs({super.key, this.baseSize = 22});

  /// Font size of the largest (bottom) z. The other two step down from it.
  final double baseSize;

  @override
  State<SleepZs> createState() => _SleepZsState();
}

class _SleepZsState extends State<SleepZs> with SingleTickerProviderStateMixin {
  /// One full trip through the trail. Slow enough to read as breathing rather
  /// than blinking.
  static const Duration _cycle = Duration(milliseconds: 2600);

  /// Where each z sits, as a fraction of [SleepZs.baseSize]: right and up from
  /// the largest one, which anchors the bottom-left.
  static const List<Offset> _positions = [
    Offset(0, 0),
    Offset(0.75, -0.85),
    Offset(1.35, -1.55),
  ];

  /// Each z is smaller than the one below it.
  static const List<double> _scales = [1.0, 0.68, 0.46];

  late final AnimationController _controller;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _cycle)..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce == _reduceMotion) return;
    _reduceMotion = reduce;
    if (reduce) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Fraction of the cycle a single z is on screen for.
  static const double _window = 0.55;

  /// How far each z lags the one below it, so they light up in sequence.
  static const double _stagger = 0.18;

  /// Opacity of the z at [index] at loop position [t] (0..1).
  ///
  /// Each z fades up, then all the way back down to nothing. The phase is not
  /// wrapped, so the last z finishes at 0.91 and the trail is completely blank
  /// for the rest of the cycle before it starts again — the breath out.
  double _opacityFor(int index, double t) {
    final phase = t - index * _stagger;
    if (phase <= 0 || phase >= _window) return 0;

    // In quickly, out slowly: a z drifting away should take longer to go than
    // it took to arrive.
    final ramp = phase / _window;
    const peak = 0.33;
    final pulse = ramp < peak ? ramp / peak : 1 - (ramp - peak) / (1 - peak);
    return Curves.easeInOut.transform(pulse.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final fontFunction = AppFonts.getFont(settings.usePixelFont);
    final base = widget.baseSize;

    return IgnorePointer(
      child: SizedBox(
        // Sized from the trail's own extent so the caller can anchor it like
        // any other box. The widest z sits at 1.35 + its own glyph width, and
        // the stack climbs 1.55 above the baseline.
        width: base * 2.4,
        height: base * 2.8,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < _positions.length; i++)
                  Positioned(
                    left: _positions[i].dx * base,
                    // Measured up from the bottom of the box, so the largest z
                    // stays put and the trail grows upward from it.
                    bottom: -_positions[i].dy * base,
                    child: Opacity(
                      // Reduce-motion holds the trail at full rather than
                      // animating it. It cannot hold the *resting* state,
                      // which is now invisible.
                      opacity: _reduceMotion ? 1.0 : _opacityFor(i, t),
                      child: Text(
                        'z',
                        style: fontFunction(
                          fontSize: base * _scales[i],
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ).copyWith(
                          // White with a hard dark offset, the same treatment
                          // the carried-food hint uses. The trail floats over
                          // the night sky as often as the day one, and dark
                          // glyphs disappeared into the former entirely.
                          shadows: const [
                            Shadow(
                              color: AppTheme.retroDark,
                              offset: Offset(1.5, 1.5),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
