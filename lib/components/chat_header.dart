import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../providers/user_provider.dart';
import '../utils/pixel_clock.dart';
import '../utils/rtl_locale.dart';
import '../../utils/fonts.dart';
import 'tutorial/retro_showcase.dart';

class ChatHeader extends StatelessWidget {
  final VoidCallback onOpenSidebar;

  /// Set by the chat tour. The step is about the hamburger specifically —
  /// what is behind it — so it points at the button rather than the bar.
  final GlobalKey? menuShowcaseKey;
  final String? menuShowcaseDescription;

  const ChatHeader({
    super.key,
    required this.onOpenSidebar,
    this.menuShowcaseKey,
    this.menuShowcaseDescription,
  });

  Widget _menuShowcase(Widget child) {
    final key = menuShowcaseKey;
    final description = menuShowcaseDescription;
    if (key == null || description == null) return child;
    return RetroShowcase(
      showcaseKey: key,
      description: description,
      isFirst: true,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final level = userProvider.stats.level;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final textAlign = textAlignForLocale(locale);

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 16),
      decoration: const BoxDecoration(
        color: AppTheme.retroSky,
        border: Border(bottom: BorderSide(color: AppTheme.retroDark, width: 4)),
      ),
      child: SafeArea( // Ensure it doesn't overlap status bar
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space out header
          children: [
            // Left Side: Back button + Title
            Row(
              children: [
                // Hamburger Menu (Square Box)
                _menuShowcase(GestureDetector(
                  onTap: onOpenSidebar,
                  child: Container(
                    width: 32, 
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppTheme.retroDark, width: 4),
                      boxShadow: const [BoxShadow(color: AppTheme.retroDark, offset: Offset(2, 2))]
                    ),
                    child: Center(
                      // Custom pixel hamburger icon
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 14, height: 2, color: AppTheme.retroDark),
                          const SizedBox(height: 3),
                          Container(width: 14, height: 2, color: AppTheme.retroDark),
                          const SizedBox(height: 3),
                          Container(width: 14, height: 2, color: AppTheme.retroDark),
                        ],
                      ),
                    ),
                  ),
                )),
                const SizedBox(width: 12),
                // Title
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PIXEL PET',
                      textDirection: textDirection,
                      textAlign: textAlign,
                      style: AppFonts.pressStart2p(
                        color: Colors.white,
                        fontSize: 12,
                        shadows: [const Shadow(color: Colors.black26, offset: Offset(2, 2))]
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Online',
                      textDirection: textDirection,
                      textAlign: textAlign,
                      style: AppFonts.pressStart2p(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Right Side: Level Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppTheme.retroDark, width: 2),
              ),
              child: Row(
                children: [
                  // Blinking Dot
                  const BlinkingDot(),
                  const SizedBox(width: 6),
                  Text(
                    'LV.$level',
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    style: AppFonts.pressStart2p(
                      color: AppTheme.retroDark,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BlinkingDot extends StatefulWidget {
  const BlinkingDot({super.key});

  @override
  State<BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<BlinkingDot> {
  /// Steps each way of the pulse: up over a second, back over a second, a
  /// [PixelClock] step at a time. A smooth fade asked for a frame at every
  /// refresh of the screen, for as long as the chat was open.
  static const int _half = PixelClock.fps;

  late final PixelClockListener _clock = PixelClockListener(_step);
  final ValueNotifier<int> _frame = ValueNotifier(0);

  void _step() => _frame.value = (_frame.value + 1) % (2 * _half);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _clock.update(context, animate: true);
  }

  @override
  void dispose() {
    _clock.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _frame,
      builder: (context, frame, dot) => Opacity(
        opacity: (frame <= _half ? frame : 2 * _half - frame) / _half,
        child: dot,
      ),
      child: Container(
        width: 8,
        height: 8,
        color: AppTheme.retroGrass
      ),
    );
  }
}
