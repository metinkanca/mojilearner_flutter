import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../constants/theme.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch language provider for updates (rebuilds when language changes)
    final langProvider = Provider.of<LanguageProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    // Get translated strings based on native language
    final texts = langProvider.getTranslations();

    final stats = userProvider.stats;
    // Calculate level progress (safe division)
    final double progress = stats.progress;

    return Scaffold(
      backgroundColor: AppTheme.retroSky,
      body: SafeArea(
        child: Column(
          children: [
            // Retro Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.retroUi,
                border: Border.all(color: AppTheme.retroDark, width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.retroDark,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  (texts['profile'] ?? 'PROFILE').toUpperCase(),
                  style: GoogleFonts.pressStart2p(
                    fontSize: 16,
                    color: AppTheme.retroDark,
                  ),
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  // User Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.retroLight,
                      border: Border.all(color: AppTheme.retroDark, width: 4),
                      boxShadow: const [
                         BoxShadow(
                          color: AppTheme.retroDark,
                          offset: Offset(4, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Pet Avatar (Link to Design)
                        GestureDetector(
                          onTap: () => context.pushNamed('design_moji'),
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: SvgPicture.asset('assets/svgs/pet.svg'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // "MOJI" Title
                        Text(
                          "MOJI",
                          style: GoogleFonts.pressStart2p(
                            fontSize: 24,
                            color: AppTheme.retroDark,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Level Progress Bar
                        Column(
                          children: [
                             Text(
                                "LVL ${stats.level}",
                                style: GoogleFonts.pressStart2p(
                                  fontSize: 12,
                                  color: AppTheme.retroDark.withOpacity(0.6),
                                ),
                             ),
                             const SizedBox(height: 8),
                             // Bar Container
                             Container(
                               height: 20,
                               width: 200,
                               decoration: BoxDecoration(
                                 color: Colors.white,
                                 border: Border.all(color: AppTheme.retroDark, width: 3),
                               ),
                               child: LayoutBuilder(
                                 builder: (context, constraints) {
                                   return Row(
                                     children: [
                                       Container(
                                         width: constraints.maxWidth * progress,
                                         color: AppTheme.retroPrimary,
                                       ),
                                     ],
                                   );
                                 }
                               ),
                             ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Language Settings Header
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      (texts['header'] ?? 'SETTINGS').toUpperCase(),
                      style: GoogleFonts.pressStart2p(
                        fontSize: 14,
                        color: Colors.white,
                        shadows: [
                          const Shadow(color: AppTheme.retroDark, offset: Offset(2, 2)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildRetroLanguageSelector(
                    context, 
                    label: texts['iSpeak'] ?? 'I SPEAK', 
                    current: langProvider.nativeLanguage,
                    options: langProvider.availableLanguages,
                    onSelect: (lang) => langProvider.setNativeLanguage(lang),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildRetroLanguageSelector(
                     context, 
                     label: texts['imLearning'] ?? "TARGET", 
                     current: langProvider.targetLanguage ?? langProvider.availableLanguages[1],
                     options: langProvider.availableLanguages,
                     onSelect: (lang) => langProvider.setTargetLanguage(lang),
                  ),
                  
                  // Removed Streak and XP Cards as requested

                  const SizedBox(height: 80), // Bottom nav padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetroLanguageSelector(BuildContext context, {required String label, required Language current, required List<Language> options, required Function(Language) onSelect}) {
    final selectedOption = options.firstWhere(
      (lang) => lang.code == current.code,
      orElse: () => options.first,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.retroDark, width: 4),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.retroDark,
            offset: Offset(4, 4),
            blurRadius: 0,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              label.toUpperCase(), 
              style: GoogleFonts.pressStart2p(
                color: AppTheme.retroDark.withOpacity(0.6), 
                fontSize: 10
              )
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(
              canvasColor: AppTheme.retroLight, // Dropdown background
            ),
            child: DropdownButtonFormField<Language>(
              value: selectedOption,
              decoration: const InputDecoration(
                 border: InputBorder.none,
                 contentPadding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.arrow_drop_down, color: AppTheme.retroDark, size: 32),
              items: options.map((lang) {
                return DropdownMenuItem(
                  value: lang,
                  child: Row(
                    children: [
                       Text(lang.flag, style: const TextStyle(fontSize: 24)),
                       const SizedBox(width: 12),
                       Text(
                         lang.name.toUpperCase(), 
                         style: GoogleFonts.vt323(
                           fontSize: 22, 
                           fontWeight: FontWeight.bold,
                           color: AppTheme.retroDark
                         )
                       ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) onSelect(val);
              },
            ),
          ),
        ],
      ),
    );
  }
}

