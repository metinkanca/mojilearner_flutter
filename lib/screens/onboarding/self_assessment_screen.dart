import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../constants/theme.dart';
import '../../providers/user_provider.dart';
import '../../providers/language_provider.dart';
import '../../l10n/app_localizations.dart';

class SelfAssessmentScreen extends StatefulWidget {
  const SelfAssessmentScreen({super.key});

  @override
  State<SelfAssessmentScreen> createState() => _SelfAssessmentScreenState();
}

class _SelfAssessmentScreenState extends State<SelfAssessmentScreen> {
  String? _selectedLevel;

  void _selectLevel(String level) {
    setState(() {
      _selectedLevel = level;
    });
    
    // Save the self-assessment
    final languageCode = Provider.of<LanguageProvider>(context, listen: false)
        .targetLanguage?.code ?? 'en';
    Provider.of<UserProvider>(context, listen: false)
        .updateSelfAssessment(languageCode, level);
    
    // Wait a moment for visual feedback, then navigate
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.go('/onboarding/pet-greeting');
    });
  }

  Widget _buildLevelButton({
    required String level,
    required String title,
    required String description,
    required Color color,
    required BuildContext context,
  }) {
    final isSelected = _selectedLevel == level;
    
    return GestureDetector(
      onTap: () => _selectLevel(level),
      child: Container(
        width: double.infinity,
        height: 132, // Fixed card size across languages
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          border: Border.all(
            color: AppTheme.retroDark,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  const BoxShadow(
                    color: AppTheme.retroDark,
                    offset: Offset(6, 6),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 24,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: GoogleFonts.pressStart2p(
                      fontSize: 14,
                      color: isSelected ? Colors.white : AppTheme.retroDark,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: Center(
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.pressStart2p(
                    fontSize: 8,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.9)
                        : AppTheme.retroDark.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                    '4/8',
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
                      child: FractionallySizedBox(
                        widthFactor: 4 / 8,
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
            
            const SizedBox(height: 20),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Text(
                    l10n.howWouldYouRate,
                    style: GoogleFonts.pressStart2p(
                      fontSize: 10,
                      color: AppTheme.retroDark,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.yourLevel,
                    style: GoogleFonts.pressStart2p(
                      fontSize: 18,
                      color: AppTheme.retroDark,
                      shadows: [
                        const Shadow(
                          color: AppTheme.retroAccent,
                          offset: Offset(3, 3),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.dontWorryVerify,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.pressStart2p(
                      fontSize: 8,
                      color: AppTheme.retroDark.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Level buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  _buildLevelButton(
                    level: 'beginner',
                    title: l10n.beginner,
                    description: l10n.beginnerDesc,
                    color: const Color(0xFF4CAF50),
                    context: context,
                  ),
                  const SizedBox(height: 16),
                  _buildLevelButton(
                    level: 'intermediate',
                    title: l10n.intermediate,
                    description: l10n.intermediateDesc,
                    color: const Color(0xFFFFC107),
                    context: context,
                  ),
                  const SizedBox(height: 16),
                  _buildLevelButton(
                    level: 'advanced',
                    title: l10n.advanced,
                    description: l10n.advancedDesc,
                    color: const Color(0xFFF44336),
                    context: context,
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
