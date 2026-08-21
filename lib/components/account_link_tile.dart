import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../screens/onboarding/first_launch/login_panel.dart';
import '../services/account_service.dart';
import '../utils/fonts.dart';
import '../utils/rtl_locale.dart';

/// The way back to signing in for a player who said "maybe later".
///
/// The opening offers this once and then never blocks on it again, so without
/// somewhere permanent to find it, declining would mean declining forever.
///
/// Renders nothing at all when there is no account layer (cloud sync did not
/// start) — an offer that cannot be taken is worse than no offer.
class AccountLinkTile extends StatelessWidget {
  const AccountLinkTile({super.key});

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountService?>();
    if (account == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final usePixelFont = context.watch<SettingsProvider>().usePixelFont;

    final style = AppFonts.pressStart2p(
      fontSize: 10,
      color: AppTheme.retroDark,
      locale: locale,
    );

    // Already attached: there is nothing to offer, only something to confirm.
    if (!account.isAnonymous) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.retroDark, width: 4),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_done, color: AppTheme.retroDark, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                account.email ?? '',
                textDirection: textDirection,
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _openSheet(context, account, l10n, locale, textDirection,
          usePixelFont: usePixelFont),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_upload, color: AppTheme.retroDark, size: 20),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                l10n.onboardingLoginTitle,
                textDirection: textDirection,
                textAlign: TextAlign.center,
                style: style,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSheet(
    BuildContext context,
    AccountService account,
    AppLocalizations l10n,
    Locale locale,
    TextDirection textDirection, {
    required bool usePixelFont,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.retroSky,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        // Clears the keyboard when the address form is open.
        padding: EdgeInsets.only(
          top: 24,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: LoginPanel(
          account: account,
          strings: l10n,
          locale: locale,
          textDirection: textDirection,
          usePixelFont: usePixelFont,
          // Linked, or declined again. Either way the sheet has done its job.
          onDone: () => Navigator.of(sheetContext).pop(),
        ),
      ),
    );
  }
}
