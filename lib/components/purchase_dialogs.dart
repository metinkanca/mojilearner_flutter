/// The one buy flow: the purse, the confirm-a-purchase dialog, and the small
/// notice that answers "you cannot have this yet" — with a video for coins on
/// it when that is the answer.
///
/// Shared by everything the player can buy outside the shop itself — the
/// wardrobe's hats, colours and scenes, and the pets on the pet changer — so a
/// purchase looks and behaves the same wherever it happens.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/ads_provider.dart';
import 'free_coins_tile.dart';

/// The shared subset of the two retro font helpers (pixel / mono).
typedef PurchaseFontFn = TextStyle Function({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
});

/// The glyphs price tags are written with.
class AccessoryTileIcons {
  AccessoryTileIcons._();

  static const String coin = '\u{1FA99}';
  static const String locked = '\u{1F512}';
}

/// An extra button on a notice dialog.
typedef NoticeAction = ({String label, VoidCallback onTap});

/// Small retro dialog for the "you cannot have this yet" answers.
void showNoticeDialog({
  required BuildContext context,
  required PurchaseFontFn fontFunction,
  required TextDirection textDirection,
  required String title,
  required String message,
  String? detail,
  NoticeAction? action,
}) {
  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppTheme.retroLight,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppTheme.retroDark, width: 4),
        borderRadius: BorderRadius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title.toUpperCase(),
              textDirection: textDirection,
              textAlign: TextAlign.center,
              style: fontFunction(
                fontSize: 11,
                color: AppTheme.retroDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textDirection: textDirection,
              textAlign: TextAlign.center,
              style: fontFunction(fontSize: 8, color: AppTheme.retroDark),
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail,
                textDirection: textDirection,
                textAlign: TextAlign.center,
                style: fontFunction(
                  fontSize: 8,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              RetroDialogButton(
                label: action.label.toUpperCase(),
                color: AppTheme.retroAccent,
                fontFunction: fontFunction,
                textDirection: textDirection,
                // Closed first: the ad takes over the screen, and coming back
                // to a stale "not enough coins" over a balance that has since
                // gone up would read as the purchase having failed.
                onTap: () {
                  Navigator.of(context).pop();
                  action.onTap();
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// The "watch a video for coins" action for a can't-afford dialog, or null
/// when there is no ad to offer.
///
/// Deliberately reachable only from *purchase* paths. A bond-gated accessory
/// has no price at any amount of coins — see
/// `AccessoryAvailability.bondLocked` — so the branch that explains one never
/// comes near this. Putting an ad button there would turn a piece that is
/// earned by learning into one that is bought, which is the exact thing that
/// rule exists to prevent.
NoticeAction? rewardedAdAction(BuildContext context) {
  final ads = context.read<AdsProvider>();
  if (!ads.canOfferRewarded) return null;

  final reward = ads.nextRewardValue;
  if (reward == null) return null;

  return (
    label: AppLocalizations.of(context)!.adsWatchForCoins(reward),
    onTap: () => watchRewardedAd(context),
  );
}

/// The purse, in the app bar. Mirrors the shop's so they read as one wallet.
class CoinBalance extends StatelessWidget {
  final int coins;
  final PurchaseFontFn fontFunction;

  const CoinBalance({
    super.key,
    required this.coins,
    required this.fontFunction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.retroAccent,
        border: Border.all(color: AppTheme.retroDark, width: 3),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.retroDark,
            offset: Offset(2, 2),
            blurRadius: 0,
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on,
              color: AppTheme.retroDark, size: 16),
          const SizedBox(width: 4),
          Text(
            '$coins',
            textDirection: TextDirection.ltr,
            style: fontFunction(
              fontSize: 10,
              color: AppTheme.retroDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Confirms one purchase. Deliberately agnostic about what is being bought —
/// a hat shows its emoji, a colour shows the colour itself, a pet shows the
/// pet — so there is one buy flow rather than one per shelf.
class BuyDialog extends StatelessWidget {
  final Widget preview;
  final String name;
  final int price;
  final PurchaseFontFn fontFunction;
  final TextDirection textDirection;
  final Future<void> Function() onConfirm;

  const BuyDialog({
    super.key,
    required this.preview,
    required this.name,
    required this.price,
    required this.fontFunction,
    required this.textDirection,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: AppTheme.retroLight,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppTheme.retroDark, width: 4),
        borderRadius: BorderRadius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            preview,
            const SizedBox(height: 12),
            Text(
              name.toUpperCase(),
              textDirection: textDirection,
              textAlign: TextAlign.center,
              style: fontFunction(
                fontSize: 11,
                color: AppTheme.retroDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${AccessoryTileIcons.coin} $price',
              textDirection: textDirection,
              style: fontFunction(
                fontSize: 10,
                color: AppTheme.retroDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: RetroDialogButton(
                    label: l10n.cancel.toUpperCase(),
                    color: AppTheme.retroLight,
                    fontFunction: fontFunction,
                    textDirection: textDirection,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RetroDialogButton(
                    label: l10n.buy.toUpperCase(),
                    color: AppTheme.retroGrass,
                    fontFunction: fontFunction,
                    textDirection: textDirection,
                    onTap: onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A square retro button, as the purchase dialogs draw them.
class RetroDialogButton extends StatelessWidget {
  final String label;
  final Color color;
  final PurchaseFontFn fontFunction;
  final TextDirection textDirection;
  final VoidCallback onTap;

  const RetroDialogButton({
    super.key,
    required this.label,
    required this.color,
    required this.fontFunction,
    required this.textDirection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: AppTheme.retroDark, width: 3),
          boxShadow: const [
            BoxShadow(
              color: AppTheme.retroDark,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          label,
          textDirection: textDirection,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: fontFunction(
            fontSize: 8,
            color: AppTheme.retroDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
