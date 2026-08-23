import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/theme.dart';
import '../constants/progression.dart';
import '../providers/calibration_provider.dart';
import '../providers/daily_reward_provider.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../components/account_link_tile.dart';
import '../components/character_sprite.dart';
import '../components/pixel_flag.dart';
import '../components/daily_rewards_dialog.dart';
import '../l10n/app_localizations.dart';
import '../utils/rtl_locale.dart';
import '../../utils/fonts.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showDailyRewardManually(BuildContext context) async {
    final dailyRewardProvider =
        Provider.of<DailyRewardProvider>(context, listen: false);
    final rewardInfo = await dailyRewardProvider.checkDailyReward();

    if (context.mounted) {
      if (rewardInfo != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => DailyRewardsDialog(
            rewardInfo: rewardInfo,
            onClaim: () {
              dailyRewardProvider.claimDailyReward();
            },
          ),
        );
      } else {
        // Show status of current week
        _showWeeklyStatus(context, dailyRewardProvider);
      }
    }
  }

  void _showWeeklyStatus(
      BuildContext context, DailyRewardProvider dailyRewardProvider) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);

    showDialog(
      context: context,
      builder: (context) {
        final totalClaims = dailyRewardProvider.dailyRewardClaimCount;
        final completedDayInCycle = dailyRewardProvider.completedRewardCycleDay;
        final nextDayInCycle = dailyRewardProvider.nextRewardCycleDay;
        
        return AlertDialog(
          backgroundColor: AppTheme.retroLight,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: AppTheme.retroDark, width: 4),
          ),
          title: Text(
            l10n.weeklyProgressTitle.toUpperCase(),
            textDirection: textDirection,
            style: AppFonts.pressStart2p(fontSize: 14, color: AppTheme.retroDark),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: List.generate(7, (index) {
                    final dayNum = index + 1;
                    final isCompleted = dayNum <= completedDayInCycle && totalClaims > 0;
                    final isToday = dayNum == nextDayInCycle;
                    final reward = dailyRewards[index];
                    
                    return Container(
                      width: 65,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isToday ? AppTheme.retroAccent.withValues(alpha: 0.3) : Colors.white,
                        border: Border.all(
                          color: isCompleted ? AppTheme.retroGreen : AppTheme.retroDark,
                          width: isToday ? 3 : 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            l10n.dayLabel(dayNum).toUpperCase(),
                            textDirection: textDirection,
                            style: AppFonts.pressStart2p(
                              fontSize: 6,
                              color: isCompleted ? AppTheme.retroGreen : AppTheme.retroDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isCompleted ? '✅' : _getRewardIcon(reward),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.dailyRewardHint,
                  textDirection: textDirection,
                  style: AppFonts.pressStart2p(fontSize: 8, color: AppTheme.retroDark, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.close.toUpperCase(), style: AppFonts.pressStart2p(fontSize: 10, color: AppTheme.retroDark)),
            ),
          ],
        );
      },
    );
  }

  String _getRewardIcon(RewardDef reward) {
    if (reward.type == RewardType.coins) return '🪙';
    if (reward.itemId == 'apple') return '🍎';
    if (reward.itemId == 'coffee') return '☕';
    if (reward.itemId == 'pizza') return '🍕';
    return '🎁';
  }

  void _handleTargetLanguageChange(BuildContext context, Language newLanguage) async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final calibrationProvider =
        Provider.of<CalibrationProvider>(context, listen: false);

    // Update the target language
    await langProvider.setTargetLanguage(newLanguage);

    // Check if this language has been calibrated
    final isCalibrated =
        calibrationProvider.isLanguageCalibrated(newLanguage.code);
    
    if (!isCalibrated && context.mounted) {
      final locale = Localizations.localeOf(context);
      final textDirection = textDirectionForLocale(locale);

      // Show dialog asking if they want to calibrate
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppTheme.retroLight,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: AppTheme.retroDark, width: 4),
          ),
          title: Text(
            'NEW LANGUAGE!',
            textDirection: textDirection,
            textAlign: TextAlign.center,
            style: AppFonts.pressStart2p(
              fontSize: 14,
              color: AppTheme.retroDark,
            ),
          ),
          content: Text(
            'Let\'s calibrate your ${newLanguage.name} level!\n\nThis helps us personalize your learning experience.',
            textDirection: textDirection,
            textAlign: TextAlign.center,
            style: AppFonts.pressStart2p(
              fontSize: 8,
              color: AppTheme.retroDark,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: AppTheme.retroDark, width: 2),
                ),
              ),
              child: Text(
                'LATER',
                textDirection: textDirection,
                textAlign: TextAlign.center,
                style: AppFonts.pressStart2p(
                  fontSize: 8,
                  color: AppTheme.retroDark,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.go('/onboarding/self-assessment');
              },
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.retroPrimary,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: AppTheme.retroDark, width: 2),
                ),
              ),
              child: Text(
                'START NOW',
                textDirection: textDirection,
                textAlign: TextAlign.center,
                style: AppFonts.pressStart2p(
                  fontSize: 8,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showResetDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.retroLight,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppTheme.retroDark, width: 4),
        ),
        title: Text(
          l10n.resetAppTitle.toUpperCase(),
          textDirection: textDirection,
          textAlign: TextAlign.center,
          style: AppFonts.pressStart2p(
            fontSize: 14,
            color: AppTheme.retroDark,
          ),
        ),
        content: Text(
          l10n.resetAppWarning,
          textDirection: textDirection,
          textAlign: TextAlign.center,
          style: AppFonts.pressStart2p(
            fontSize: 8,
            color: AppTheme.retroDark,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: AppTheme.retroDark, width: 2),
              ),
            ),
            child: Text(
              l10n.cancel.toUpperCase(),
              textDirection: textDirection,
              textAlign: TextAlign.center,
              style: AppFonts.pressStart2p(
                fontSize: 8,
                color: AppTheme.retroDark,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _resetApp(context);
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: AppTheme.retroDark, width: 2),
              ),
            ),
            child: Text(
              l10n.resetAction.toUpperCase(),
              textDirection: textDirection,
              textAlign: TextAlign.center,
              style: AppFonts.pressStart2p(
                fontSize: 8,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetApp(BuildContext context) async {
    try {
      // Clear all SharedPreferences data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Show feedback
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.retroPrimary,
            content: Text(
              l10n.resetSuccessMessage,
              textDirection: textDirectionForLocale(Localizations.localeOf(context)),
              textAlign: textAlignForLocale(Localizations.localeOf(context)),
              style: AppFonts.pressStart2p(
                fontSize: 8,
                color: Colors.white,
              ),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Wait a moment then navigate to onboarding
        await Future.delayed(const Duration(seconds: 1));
        
        if (context.mounted) {
          context.go('/onboarding/welcome');
        }
      }
    } catch (e) {
      debugPrint('Error resetting app: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch language provider for updates (rebuilds when language changes)
    final langProvider = Provider.of<LanguageProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final textAlign = textAlignForLocale(locale);

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
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppTheme.retroDark, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: AppTheme.retroDark,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppTheme.retroDark,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n.profile.toUpperCase(),
                        textDirection: textDirection,
                        textAlign: TextAlign.center,
                        style: AppFonts.pressStart2p(
                          fontSize: 16,
                          color: AppTheme.retroDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
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
                            child: const CharacterSprite(width: 120, height: 120),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // "MOJI" Title
                        Text(
                          "MOJI",
                          textDirection: textDirection,
                          textAlign: textAlign,
                          style: AppFonts.pressStart2p(
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
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.left,
                                style: AppFonts.pressStart2p(
                                  fontSize: 12,
                                  color: AppTheme.retroDark.withValues(alpha: 0.6),
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
                        
                        const SizedBox(height: 24),
                        
                        // Daily Reward Tracker Item
                        GestureDetector(
                          onTap: () => _showDailyRewardManually(context),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.retroAccent.withValues(alpha: 0.1),
                              border: Border.all(color: AppTheme.retroDark, width: 4),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromARGB(255, 255, 255, 255),
                                  offset: Offset(2, 2),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Text("🎁", style: TextStyle(fontSize: 20)),
                                const SizedBox(width: 12),
                                Text(
                                  l10n.daily_reward.toUpperCase(),
                                  textDirection: textDirection,
                                  textAlign: textAlign,
                                  style: AppFonts.pressStart2p(
                                    fontSize: 10,
                                    color: AppTheme.retroDark,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.chevron_right, color: AppTheme.retroDark, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Language Settings Header
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      l10n.header.toUpperCase(),
                      textDirection: textDirection,
                      textAlign: textAlign,
                      style: AppFonts.pressStart2p(
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
                    label: l10n.iSpeak,
                    current: langProvider.nativeLanguage,
                    options: langProvider.availableLanguages,
                    onSelect: (lang) => langProvider.setNativeLanguage(lang),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildRetroLanguageSelector(
                     context, 
                    label: l10n.imLearning,
                     current: langProvider.targetLanguage ?? langProvider.availableLanguages[1],
                     options: langProvider.availableLanguages,
                     onSelect: (lang) => _handleTargetLanguageChange(context, lang),
                  ),
                  
                  const SizedBox(height: 32),

                  // The way back for a player who skipped signing in
                  // during the opening. Hides itself when there is no
                  // account layer to sign in to.
                  const AccountLinkTile(),

                  const SizedBox(height: 32),
                  
                  // Reset App Button
                  GestureDetector(
                    onTap: () => _showResetDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF44336),
                        border: Border.all(color: AppTheme.retroDark, width: 4),
                        boxShadow: const [
                          BoxShadow(
                            color: AppTheme.retroDark,
                            offset: Offset(4, 4),
                            blurRadius: 0,
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.refresh, color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            l10n.resetAppButton.toUpperCase(),
                            textDirection: textDirection,
                            textAlign: textAlign,
                            style: AppFonts.pressStart2p(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
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
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final textAlign = textAlignForLocale(locale);

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
              textDirection: textDirection,
              textAlign: textAlign,
              style: AppFonts.pressStart2p(
                color: AppTheme.retroDark.withValues(alpha: 0.6), 
                fontSize: 10
              )
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(
              canvasColor: AppTheme.retroLight, // Dropdown background
            ),
            child: DropdownButtonFormField<Language>(
              initialValue: selectedOption,
              // DropdownButtonFormField is dense by default, which pins the
              // closed button to a 24pt box — shorter than the line it holds,
              // so "English" lost the tail of its g and 한국어 lost more than
              // that. The row is a settings row, not a compact form field.
              isDense: false,
              // Fills the row rather than shrink-wrapping the widest option:
              // the button lays every option out at its own width, so without
              // this the longest name in the catalogue decides how wide the
              // closed button is and pushes the arrow off the card.
              isExpanded: true,
              decoration: const InputDecoration(
                 border: InputBorder.none,
                 contentPadding: EdgeInsets.symmetric(vertical: 4),
              ),
              icon: const Icon(Icons.arrow_drop_down, color: AppTheme.retroDark, size: 32),
              items: options.map((lang) {
                return DropdownMenuItem(
                  value: lang,
                  child: Row(
                    // The open menu measures its items against unbounded
                    // width, where a flex child is an error; min lets the
                    // name below size itself in both places.
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       PixelFlag(code: lang.code, height: 18),
                       const SizedBox(width: 12),
                       // Named in itself, and left as the language writes it:
                       // upper-casing an endonym mangles scripts that have no
                       // case and Turkish dotted i alike.
                       //
                       // Flexible because the dropdown lays every option out
                       // at the width of the closed button: without it the
                       // longest name in the catalogue — "Bahasa Indonesia" —
                       // runs off the side of the row it is not even in yet.
                       Flexible(
                         child: Text(
                           lang.nativeName,
                           textDirection: textDirectionForLocale(
                             Locale(lang.code),
                           ),
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                           style: AppFonts.spaceMono(
                             fontSize: 16,
                             fontWeight: FontWeight.bold,
                             color: AppTheme.retroDark
                           )
                         ),
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

