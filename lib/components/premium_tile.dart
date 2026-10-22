import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../constants/entitlements.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../providers/user_provider.dart';
import '../utils/fonts.dart';
import '../utils/rtl_locale.dart';

/// The way in to Mimikin Plus from the profile.
///
/// Exists because the paywall previously had exactly one entry point — the
/// sheet that appears when a day's allowance runs out. That is the worst
/// possible only-door: the single moment a player sees the offer is the moment
/// they have just been told no, which is when they are least inclined to pay
/// and most inclined to close the app. An offer needs a door someone can walk
/// through while they are happy.
///
/// Shows today's remaining quizzes rather than a slogan. The product is a
/// bigger number, so the honest advertisement for it is the number the player
/// currently has.
class PremiumTile extends StatelessWidget {
  const PremiumTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textDirection =
        textDirectionForLocale(Localizations.localeOf(context));
    final fontFunction =
        AppFonts.getFont(context.watch<SettingsProvider>().usePixelFont);

    final user = context.watch<UserProvider>();
    final isPremium = user.isPremium;
    final used = user.aiLimit(AiSpend.quiz) - user.aiRemaining(AiSpend.quiz);
    final total = user.aiLimit(AiSpend.quiz);

    return GestureDetector(
      onTap: () => context.pushNamed('premium'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isPremium ? AppTheme.retroSky : Colors.white,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPremium
                        ? (l10n?.premiumActive ?? 'Mimikin Plus is active.')
                        : (l10n?.aiLimitGoPlus ?? 'Get Mimikin Plus'),
                    textDirection: textDirection,
                    style: fontFunction(
                      fontSize: 10,
                      height: 1.4,
                      color: AppTheme.retroDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n?.aiLimitUsage(used, total) ??
                        '$used of $total used today',
                    textDirection: textDirection,
                    style: fontFunction(
                      fontSize: 8,
                      height: 1.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, color: AppTheme.retroDark),
          ],
        ),
      ),
    );
  }
}
