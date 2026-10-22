import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../constants/app_runtime_config.dart';
import '../constants/season_pass.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../providers/user_provider.dart';
import '../utils/fonts.dart';
import '../utils/rtl_locale.dart';

/// The way in to the season pass from the profile.
///
/// Same reasoning as `premium_tile.dart`: an offer needs a door a player can
/// walk through while they are happy, not only the moment something is locked.
/// The pass has it worse than Plus, in fact — its content shows up in the
/// wardrobe as pass-locked tiles, so without this the only place a player
/// meets it is a shelf telling them no.
///
/// Shows the tier they are on once they own it, and the size of the track
/// before that. Hides itself entirely when no pass exists yet, so an empty
/// `seasonPasses` cannot put a dead tile on the profile.
class SeasonPassTile extends StatelessWidget {
  const SeasonPassTile({super.key});

  @override
  Widget build(BuildContext context) {
    final pass = seasonPassById(kSeasonOneId);
    if (pass == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final textDirection =
        textDirectionForLocale(Localizations.localeOf(context));
    final fontFunction =
        AppFonts.getFont(context.watch<SettingsProvider>().usePixelFont);

    final user = context.watch<UserProvider>();
    final progress = user.passProgress(pass.id);
    final debugXp = AppRuntimeConfig.seasonPassXpOverride;

    final String subtitle;
    if (progress != null) {
      subtitle = progress.hasClaimable
          ? (l10n?.seasonPassWaitingToClaim(
                  progress.claimableTierIndexes.length) ??
              'Waiting to claim: ${progress.claimableTierIndexes.length}')
          : progress.isComplete
              ? (l10n?.seasonPassComplete ?? 'Track complete.')
              : (l10n?.seasonPassXpToNext(progress.xpToNextTier) ??
                  '${progress.xpToNextTier} XP to the next piece');
    } else if (debugXp >= 0) {
      subtitle = 'Debug preview';
    } else {
      subtitle =
          l10n?.seasonPassEarnedByStudying ?? 'Earned by studying';
    }

    final highlight = progress?.hasClaimable ?? false;

    return GestureDetector(
      onTap: () => context.pushNamed('pass'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: highlight ? AppTheme.retroAccent : Colors.white,
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
                    pass.name,
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
                    subtitle,
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
