import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/theme.dart';
import '../../components/character_sprite.dart';
import '../../providers/user_provider.dart';
import '../../providers/language_provider.dart';

class PetFarewellScreen extends StatefulWidget {
  const PetFarewellScreen({super.key});

  @override
  State<PetFarewellScreen> createState() => _PetFarewellScreenState();
}

class _PetFarewellScreenState extends State<PetFarewellScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
    _waveAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getFarewell(String languageCode, String username) {
    final farewells = {
      'en': 'Great job, $username!',
      'es': '¡Buen trabajo, $username!',
      'fr': 'Bon travail, $username!',
      'de': 'Gute Arbeit, $username!',
      'it': 'Ottimo lavoro, $username!',
      'pt': 'Bom trabalho, $username!',
      'ru': 'Отличная работа, $username!',
      'ja': 'よくできました、$username！',
      'zh': '干得好，$username！',
      'ko': '잘했어요, $username!',
      'ar': 'عمل رائع، $username!',
      'hi': 'बढ़िया काम, $username!',
      'tr': 'Aferin, $username!',
      'nl': 'Goed gedaan, $username!',
      'sv': 'Bra jobbat, $username!',
      'pl': 'Dobra robota, $username!',
      'vi': 'Làm tốt lắm, $username!',
      'th': 'ทำได้ดีมาก, $username!',
      'el': 'Μπράβο, $username!',
      'he': 'כל הכבוד, $username!',
      'da': 'Godt klaret, $username!',
      'fi': 'Hyvää työtä, $username!',
      'no': 'Godt jobbet, $username!',
      'cs': 'Dobrá práce, $username!',
    };
    return farewells[languageCode] ?? farewells['en']!;
  }

  String _getLevelBadge(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return '🌱 BEGINNER';
      case 'intermediate':
        return '⭐ INTERMEDIATE';
      case 'advanced':
        return '🏆 ADVANCED';
      default:
        return '🌱 BEGINNER';
    }
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF4CAF50);
      case 'intermediate':
        return const Color(0xFFFFC107);
      case 'advanced':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF4CAF50);
    }
  }

  Future<void> _continue() async {
    // Mark onboarding as complete before navigating to home
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.markOnboardingComplete();
    
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = Provider.of<UserProvider>(context).username;
    final languageCode = 
        Provider.of<LanguageProvider>(context).targetLanguage?.code ?? 'en';
    final userProvider = Provider.of<UserProvider>(context);
    final proficiency = userProvider.getLanguageProficiency(languageCode);
    final finalLevel = proficiency?.aiDeterminedLevel ?? 'beginner';
    
    final farewell = _getFarewell(languageCode, username);
    final levelBadge = _getLevelBadge(finalLevel);
    final levelColor = _getLevelColor(finalLevel);

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
                    '8/8',
                    style: GoogleFonts.pressStart2p(
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
                      child: Container(
                        color: AppTheme.retroAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Header
            Text(
              'CALIBRATION',
              style: GoogleFonts.pressStart2p(
                fontSize: 12,
                color: AppTheme.retroDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'COMPLETE!',
              style: GoogleFonts.pressStart2p(
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
            
            const SizedBox(height: 40),
            
            // Level badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: levelColor,
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
                levelBadge,
                style: GoogleFonts.pressStart2p(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Animated pet (waving)
            AnimatedBuilder(
              animation: _waveAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _waveAnimation.value,
                  child: child,
                );
              },
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
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
                    width: 110,
                    height: 110,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Farewell message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                  farewell,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.pressStart2p(
                    fontSize: 12,
                    color: AppTheme.retroDark,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            
            const Spacer(),
            
            // Start learning button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: GestureDetector(
                onTap: _continue,
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
                    'START LEARNING!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.pressStart2p(
                      fontSize: 12,
                      color: Colors.white,
                    ),
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
