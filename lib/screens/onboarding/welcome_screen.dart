import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/theme.dart';
import '../../components/character_sprite.dart';
import '../../utils/rtl_locale.dart';
import '../../../utils/fonts.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final textAlign = textAlignForLocale(locale);

    return Scaffold(
      backgroundColor: AppTheme.retroSky,
      body: Stack(
        children: [
          // Background decorations
          Positioned(
            top: 40,
            left: 30,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.retroAccent,
                border: Border.all(width: 4, color: AppTheme.retroDark),
              ),
            ),
          ),
          Positioned(
            top: 100,
            right: 40,
            child: Container(
              width: 64,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppTheme.retroDark, width: 4),
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                
                // Welcome text
                Text(
                  'MOJILEARNER',
                  textDirection: textDirection,
                  textAlign: textAlign,
                  style: AppFonts.pressStart2p(
                    fontSize: 24,
                    color: AppTheme.retroDark,
                    shadows: [
                      const Shadow(
                        color: AppTheme.retroAccent,
                        offset: Offset(4, 4),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Learn Languages with Your Pet!',
                    textDirection: textDirection,
                    textAlign: TextAlign.center,
                    style: AppFonts.pressStart2p(
                      fontSize: 10,
                      color: AppTheme.retroDark,
                      height: 1.5,
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Character preview
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    border: Border.all(color: AppTheme.retroDark, width: 4),
                    boxShadow: const [
                      BoxShadow(
                        color: AppTheme.retroDark,
                        offset: Offset(6, 6),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: const CharacterSprite(
                      width: 120,
                      height: 120,
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Start button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: GestureDetector(
                    onTap: () => context.go('/onboarding/native-language'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.retroPrimary,
                        border: Border.all(color: AppTheme.retroDark, width: 4),
                        boxShadow: const [
                          BoxShadow(
                            color: AppTheme.retroDark,
                            offset: Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Text(
                        'START',
                        textDirection: textDirection,
                        textAlign: TextAlign.center,
                        style: AppFonts.pressStart2p(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
