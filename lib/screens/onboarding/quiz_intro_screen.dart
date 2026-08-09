import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/theme.dart';
import '../../components/character_sprite.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/level_validator.dart';
import '../../utils/rtl_locale.dart';
import '../../../utils/fonts.dart';

class QuizIntroScreen extends StatelessWidget {
  final String? aiLevel;

  const QuizIntroScreen({super.key, this.aiLevel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final retroDarkHex = AppTheme.retroDark
        .toARGB32()
        .toRadixString(16)
        .padLeft(8, '0')
        .substring(2);

    return Scaffold(
      backgroundColor: AppTheme.retroSky,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    '7/8',
                    textDirection: TextDirection.ltr,
                    style: AppFonts.pressStart2p(
                      fontSize: 10,
                      color: AppTheme.retroDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppTheme.retroDark, width: 2),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: 7 / 8,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          color: AppTheme.retroAccent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Text(
                    'QUIZ TIME!',
                    textDirection: textDirection,
                    textAlign: TextAlign.center,
                    style: AppFonts.pressStart2p(
                      fontSize: 20,
                      color: AppTheme.retroDark,
                      shadows: [
                        const Shadow(
                          color: AppTheme.retroAccent,
                          offset: Offset(3, 3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Let\'s verify your level with a quick quiz',
                    textDirection: textDirection,
                    textAlign: TextAlign.center,
                    style: AppFonts.pressStart2p(
                      fontSize: 10,
                      color: AppTheme.retroDark,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Pet and Speech Bubble area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Speech Bubble
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border:
                                Border.all(color: AppTheme.retroDark, width: 4),
                            boxShadow: const [
                              BoxShadow(
                                color: AppTheme.retroDark,
                                offset: Offset(4, 4),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            'I\'ve prepared a quick quiz of 5 questions tailored just for you! It helps me understand exactly where you are so we can learn faster together.',
                            textDirection: textDirection,
                            textAlign: TextAlign.center,
                            style: AppFonts.pressStart2p(
                              fontSize: 10,
                              color: AppTheme.retroDark,
                              height: 1.8,
                            ),
                          ),
                        ),
                        // Bubble pointer
                        Positioned(
                          bottom: -16,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: SvgPicture.string(
                              '''<svg width="24" height="16" viewBox="0 0 24 16" fill="none" xmlns="http://www.w3.org/2000/svg">
                                <path d="M12 16L0 0H24L12 16Z" fill="white"/>
                                <path d="M0 0L12 16L24 0" stroke="#$retroDarkHex" stroke-width="4"/>
                              </svg>''',
                              width: 24,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Pet character
                    const CharacterSprite(
                      width: 130,
                      height: 130,
                    ),
                  ],
                ),
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: GestureDetector(
                onTap: () {
                  final normalizedLevel =
                      LevelValidator.normalizeLevel(aiLevel);
                  context.go(
                    '/onboarding/adaptive-quiz?aiLevel=$normalizedLevel',
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                    l10n.continueBtn,
                    textDirection: textDirection,
                    textAlign: TextAlign.center,
                    style: AppFonts.pressStart2p(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
