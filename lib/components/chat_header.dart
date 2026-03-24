import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../providers/user_provider.dart';

class ChatHeader extends StatelessWidget {
  final VoidCallback onOpenSidebar;

  const ChatHeader({super.key, required this.onOpenSidebar});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final level = userProvider.stats.level;

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
                GestureDetector(
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
                ),
                const SizedBox(width: 12),
                // Title
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PIXEL PET',
                      style: GoogleFonts.pressStart2p(
                        color: Colors.white,
                        fontSize: 12,
                        shadows: [const Shadow(color: Colors.black26, offset: Offset(2, 2))]
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Online',
                      style: GoogleFonts.pressStart2p(
                        color: Colors.white.withOpacity(0.8),
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
                    style: GoogleFonts.pressStart2p(
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

class _BlinkingDotState extends State<BlinkingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8, 
        height: 8, 
        color: AppTheme.retroGrass
      ),
    );
  }
}
