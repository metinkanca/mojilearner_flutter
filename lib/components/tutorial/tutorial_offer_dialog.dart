import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/theme.dart';
import '../../constants/tutorials.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
import '../../utils/fonts.dart';
import '../../utils/rtl_locale.dart';

/// Asks whether the player wants to be shown around this page.
///
/// Deliberately a question rather than an unprompted tour: the player who
/// already knows what a shop is should be able to say no in one tap and never
/// be asked again, and the one who wants the help should have chosen it.
///
/// Returns true if they asked for the tour, false or null otherwise. Either
/// answer retires the offer — see [TutorialOfferHost].
Future<bool?> showTutorialOffer(BuildContext context, TutorialId id) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _TutorialOfferDialog(id: id),
  );
}

class _TutorialOfferDialog extends StatelessWidget {
  const _TutorialOfferDialog({required this.id});

  final TutorialId id;

  String _offerText(AppLocalizations l10n) {
    switch (id) {
      case TutorialId.home:
        return l10n.tutorialOfferHome;
      case TutorialId.quiz:
        return l10n.tutorialOfferQuiz;
      case TutorialId.chat:
        return l10n.tutorialOfferChat;
      case TutorialId.shop:
        return l10n.tutorialOfferShop;
      case TutorialId.profile:
        return l10n.tutorialOfferProfile;
      case TutorialId.review:
        return l10n.tutorialOfferReview;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final usePixelFont = context.select<SettingsProvider, bool>(
      (settings) => settings.usePixelFont,
    );
    final font = AppFonts.getFont(usePixelFont);

    return Dialog(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppTheme.retroDark, width: 4),
        borderRadius: BorderRadius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.tutorialOfferTitle,
              textAlign: TextAlign.center,
              style: font(
                fontSize: 14,
                color: AppTheme.retroDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _offerText(l10n),
              textDirection: textDirectionForLocale(locale),
              textAlign: textAlignForLocale(locale,
                  ltr: TextAlign.center, rtl: TextAlign.center),
              style: font(
                fontSize: 10,
                height: 1.7,
                color: AppTheme.retroDark,
              ),
            ),
            const SizedBox(height: 24),
            // Wrapped for the same reason the coach mark's buttons are: at
            // 10pt pixel type "ÜBERSPRINGEN" beside "ZEIG MIR" is wider than
            // the dialog on a handset.
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 12,
              runSpacing: 8,
              children: [
                _OfferButton(
                  label: l10n.tutorialSkip,
                  fill: Colors.white,
                  style: font(
                    fontSize: 10,
                    color: AppTheme.retroDark,
                    fontWeight: FontWeight.bold,
                  ),
                  onTap: () => Navigator.of(context).pop(false),
                ),
                _OfferButton(
                  label: l10n.tutorialWatch,
                  fill: AppTheme.retroPrimary,
                  style: font(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  onTap: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferButton extends StatelessWidget {
  const _OfferButton({
    required this.label,
    required this.fill,
    required this.style,
    required this.onTap,
  });

  final String label;
  final Color fill;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(color: AppTheme.retroDark, width: 3),
          boxShadow: const [
            BoxShadow(color: AppTheme.retroDark, offset: Offset(2, 2)),
          ],
        ),
        child: Text(label, style: style),
      ),
    );
  }
}
