import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/language_provider.dart';
import '../../utils/rtl_locale.dart';
import '../../../utils/fonts.dart';

class TargetLanguageScreen extends StatefulWidget {
  const TargetLanguageScreen({super.key});

  @override
  State<TargetLanguageScreen> createState() => _TargetLanguageScreenState();
}

class _TargetLanguageScreenState extends State<TargetLanguageScreen> {
  String? _selectedLanguage;

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'ja', 'name': 'Japanese', 'flag': '🇯🇵'},
    {'code': 'es', 'name': 'Spanish', 'flag': '🇪🇸'},
    {'code': 'fr', 'name': 'French', 'flag': '🇫🇷'},
    {'code': 'de', 'name': 'German', 'flag': '🇩🇪'},
    {'code': 'it', 'name': 'Italian', 'flag': '🇮🇹'},
    {'code': 'pt', 'name': 'Portuguese', 'flag': '🇵🇹'},
    {'code': 'ru', 'name': 'Russian', 'flag': '🇷🇺'},
    {'code': 'ko', 'name': 'Korean', 'flag': '🇰🇷'},
    {'code': 'zh', 'name': 'Chinese', 'flag': '🇨🇳'},
    {'code': 'ar', 'name': 'Arabic', 'flag': '🇸🇦'},
    {'code': 'hi', 'name': 'Hindi', 'flag': '🇮🇳'},
    {'code': 'nl', 'name': 'Dutch', 'flag': '🇳🇱'},
    {'code': 'pl', 'name': 'Polish', 'flag': '🇵🇱'},
    {'code': 'tr', 'name': 'Turkish', 'flag': '🇹🇷'},
    {'code': 'sv', 'name': 'Swedish', 'flag': '🇸🇪'},
    {'code': 'no', 'name': 'Norwegian', 'flag': '🇳🇴'},
    {'code': 'da', 'name': 'Danish', 'flag': '🇩🇰'},
    {'code': 'fi', 'name': 'Finnish', 'flag': '🇫🇮'},
    {'code': 'cs', 'name': 'Czech', 'flag': '🇨🇿'},
    {'code': 'el', 'name': 'Greek', 'flag': '🇬🇷'},
    {'code': 'th', 'name': 'Thai', 'flag': '🇹🇭'},
    {'code': 'vi', 'name': 'Vietnamese', 'flag': '🇻🇳'},
  ];

  void _continue(BuildContext context) {
    if (_selectedLanguage != null) {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      final selectedLang = languageProvider.availableLanguages
          .firstWhere((lang) => lang.code == _selectedLanguage);
      languageProvider.setTargetLanguage(selectedLang);
      context.go('/onboarding/self-assessment');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final textAlign = textAlignForLocale(locale);
    
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
                    '3/8',
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
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
                        widthFactor: 3 / 8,
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
            
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    l10n.whichLanguage,
                    textDirection: textDirection,
                    style: AppFonts.pressStart2p(
                      fontSize: 12,
                      color: AppTheme.retroDark,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.doYouWantToLearn,
                    textDirection: textDirection,
                    style: AppFonts.pressStart2p(
                      fontSize: 14,
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
                    l10n.changeAnytime,
                    textDirection: textDirection,
                    textAlign: TextAlign.center,
                    style: AppFonts.pressStart2p(
                      fontSize: 8,
                      color: AppTheme.retroDark.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Language grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _languages.length,
                itemBuilder: (context, index) {
                  final lang = _languages[index];
                  final isSelected = _selectedLanguage == lang['code'];
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedLanguage = lang['code'];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.retroPrimary : Colors.white,
                        border: Border.all(
                          color: AppTheme.retroDark,
                          width: isSelected ? 4 : 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                const BoxShadow(
                                  color: AppTheme.retroDark,
                                  offset: Offset(4, 4),
                                  blurRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            lang['flag']!,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              lang['name']!,
                              textDirection: textDirection,
                              textAlign: textAlign,
                              style: AppFonts.pressStart2p(
                                fontSize: 8,
                                color: isSelected ? Colors.white : AppTheme.retroDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Continue button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: GestureDetector(
                onTap: _selectedLanguage == null ? null : () => _continue(context),
                child: Opacity(
                  opacity: _selectedLanguage == null ? 0.5 : 1.0,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.retroPrimary,
                      border: Border.all(color: AppTheme.retroDark, width: 4),
                      boxShadow: _selectedLanguage != null
                          ? [
                              const BoxShadow(
                                color: AppTheme.retroDark,
                                offset: Offset(4, 4),
                                blurRadius: 0,
                              ),
                            ]
                          : null,
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
            ),
          ],
        ),
      ),
    );
  }
}
