import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/ads.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/ads_provider.dart';
import '../providers/user_provider.dart';
import '../utils/fonts.dart';

/// Runs one rewarded ad and tells the player what it paid.
///
/// Shared by every entry point — the shop tile below and the wardrobe's
/// can't-afford dialog — so the two can never drift on what a failed ad does.
/// A watch that earns nothing says so rather than failing silently, because
/// from the player's side an ad that pays nothing and a bug look identical.
///
/// Returns the coins granted, or 0.
Future<int> watchRewardedAd(BuildContext context) async {
  final ads = context.read<AdsProvider>();
  final user = context.read<UserProvider>();
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);

  final earned = await ads.watchRewarded(user);

  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 2),
      backgroundColor: AppTheme.retroDark,
      content: Text(
        earned > 0 ? l10n.adsEarnedCoins(earned) : l10n.adsNotReady,
        style: const TextStyle(color: Colors.white),
      ),
    ),
  );

  return earned;
}

/// The "watch a video for coins" offer, as it appears at the top of the shop.
///
/// Placed there rather than on the home screen deliberately: the shop is
/// where a player is already looking at something they cannot afford, which
/// is the moment the offer is most welcome and least like an interruption.
///
/// Collapses to nothing once the day's ads are used up, rather than sitting
/// there greyed out — a dead control on a shop shelf reads as broken.
class FreeCoinsTile extends StatefulWidget {
  const FreeCoinsTile({super.key, required this.usePixelFont});

  final bool usePixelFont;

  @override
  State<FreeCoinsTile> createState() => _FreeCoinsTileState();
}

class _FreeCoinsTileState extends State<FreeCoinsTile> {
  @override
  void initState() {
    super.initState();
    // Fetch ahead of the tap. A rewarded ad takes seconds to arrive, and the
    // offer stays hidden until one has, so asking on open is what makes the
    // tile appear at all.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdsProvider>().prepareRewarded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ads = context.watch<AdsProvider>();
    final l10n = AppLocalizations.of(context)!;
    final fontFunction = AppFonts.getFont(widget.usePixelFont);

    final reward = ads.nextRewardValue;
    if (reward == null || !ads.canOfferRewarded) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GestureDetector(
        onTap: ads.isWatchingRewarded ? null : () => watchRewardedAd(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.retroAccent,
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
              const Icon(
                Icons.play_circle_fill,
                color: AppTheme.retroDark,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.adsFreeCoins.toUpperCase(),
                      style: fontFunction(
                        fontSize: 10,
                        color: AppTheme.retroDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.adsLeftToday(
                        ads.rewardedRemaining,
                        AdsConstants.rewardedDailyLimit,
                      ),
                      style: fontFunction(
                        fontSize: 8,
                        color: AppTheme.retroDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '+$reward',
                textDirection: TextDirection.ltr,
                style: fontFunction(
                  fontSize: 12,
                  color: AppTheme.retroDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
