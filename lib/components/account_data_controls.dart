import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_runtime_config.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../services/account_service.dart';
import '../services/data_eraser.dart';
import '../utils/fonts.dart';
import '../utils/rtl_locale.dart';
import 'app_restart.dart';

/// How long the confirmation is left on screen before the app is rebuilt. The
/// rebuild replaces the whole tree, snackbar included, so without a pause the
/// player would never see that anything had happened.
const Duration _confirmationPause = Duration(milliseconds: 1500);

/// "Reset App": starts over from the first screen, keeping the account.
Future<void> resetAndRestart(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final eraser = context.read<DataEraser?>() ?? DataEraser();
  final messenger = ScaffoldMessenger.of(context);
  final textDirection = textDirectionForLocale(Localizations.localeOf(context));

  await eraser.resetProgress();

  messenger.showSnackBar(_snack(l10n.resetSuccessMessage, textDirection));
  await Future<void>.delayed(_confirmationPause);
  if (context.mounted) AppRestart.restart(context);
}

SnackBar _snack(String text, TextDirection textDirection) => SnackBar(
      backgroundColor: AppTheme.retroPrimary,
      content: Text(
        text,
        textDirection: textDirection,
        style: AppFonts.pressStart2p(fontSize: 8, color: Colors.white),
      ),
      duration: const Duration(seconds: 3),
    );

/// "Delete Account & Data". Permanently removes the stored save, the account
/// and everything on the device, which Play and GDPR both expect to be possible
/// from inside the app.
class DeleteAccountButton extends StatelessWidget {
  const DeleteAccountButton({super.key});

  Future<void> _confirm(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final textDirection =
        textDirectionForLocale(Localizations.localeOf(context));

    final sure = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.retroLight,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppTheme.retroDark, width: 4),
        ),
        title: Text(
          l10n.deleteAccountTitle.toUpperCase(),
          textDirection: textDirection,
          textAlign: TextAlign.center,
          style: AppFonts.pressStart2p(fontSize: 14, color: AppTheme.retroDark),
        ),
        content: Text(
          l10n.deleteAccountWarning,
          textDirection: textDirection,
          textAlign: TextAlign.center,
          style: AppFonts.pressStart2p(
            fontSize: 8,
            color: AppTheme.retroDark,
            height: 1.5,
          ),
        ),
        actions: [
          _DialogButton(
            label: l10n.cancel,
            color: Colors.white,
            textColor: AppTheme.retroDark,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          _DialogButton(
            label: l10n.deleteAction,
            color: const Color(0xFFF44336),
            textColor: Colors.white,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
    await _delete(context);
  }

  Future<void> _delete(BuildContext context, {String? password}) async {
    final l10n = AppLocalizations.of(context)!;
    final eraser = context.read<DataEraser?>() ?? DataEraser();
    final messenger = ScaffoldMessenger.of(context);
    final textDirection =
        textDirectionForLocale(Localizations.localeOf(context));

    final status = await eraser.deleteAccount(password: password);
    switch (status) {
      case AccountDeleteStatus.deleted:
        messenger.showSnackBar(_snack(l10n.deleteAccountDone, textDirection));
        await Future<void>.delayed(_confirmationPause);
        if (context.mounted) AppRestart.restart(context);
      case AccountDeleteStatus.needsPassword:
        if (!context.mounted) return;
        final typed = await _askPassword(context);
        if (typed != null && context.mounted) {
          await _delete(context, password: typed);
        }
      case AccountDeleteStatus.failed:
        messenger.showSnackBar(
          _snack(l10n.deleteAccountFailed, textDirection),
        );
    }
  }

  Future<String?> _askPassword(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (_) => const _PasswordDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    return GestureDetector(
      onTap: () => _confirm(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFF44336), width: 4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_forever,
                color: Color(0xFFF44336), size: 20),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                l10n.deleteAccountButton.toUpperCase(),
                textDirection: textDirectionForLocale(locale),
                textAlign: TextAlign.center,
                style: AppFonts.pressStart2p(
                  fontSize: 10,
                  color: const Color(0xFFF44336),
                  locale: locale,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the privacy policy. Renders nothing until `PRIVACY_POLICY_URL` is set.
class PrivacyPolicyLink extends StatelessWidget {
  const PrivacyPolicyLink({super.key, this.url = AppRuntimeConfig.privacyPolicyUrl});

  final String url;

  Future<void> _open(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final textDirection =
        textDirectionForLocale(Localizations.localeOf(context));

    final uri = Uri.tryParse(url);
    var opened = false;
    if (uri != null && uri.hasScheme) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
    if (!opened) {
      messenger.showSnackBar(_snack(l10n.privacyPolicyOpenFailed, textDirection));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    return GestureDetector(
      onTap: () => _open(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          l10n.privacyPolicyButton.toUpperCase(),
          textDirection: textDirectionForLocale(locale),
          textAlign: TextAlign.center,
          style: AppFonts.pressStart2p(
            fontSize: 10,
            color: AppTheme.retroDark,
            locale: locale,
          ).copyWith(decoration: TextDecoration.underline),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: color,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppTheme.retroDark, width: 2),
        ),
      ),
      child: Text(
        label.toUpperCase(),
        textAlign: TextAlign.center,
        style: AppFonts.pressStart2p(fontSize: 8, color: textColor),
      ),
    );
  }
}

/// Asks an email account for its password, to confirm a deletion.
///
/// Its own widget so the text controller lives exactly as long as the dialog:
/// disposing one when the dialog's future completes frees it while the closing
/// animation is still drawing the field.
class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textDirection =
        textDirectionForLocale(Localizations.localeOf(context));

    return AlertDialog(
      backgroundColor: AppTheme.retroLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppTheme.retroDark, width: 4),
      ),
      content: TextField(
        controller: _controller,
        obscureText: true,
        autofocus: true,
        textDirection: textDirection,
        decoration: InputDecoration(labelText: l10n.accountPasswordLabel),
      ),
      actions: [
        _DialogButton(
          label: l10n.cancel,
          color: Colors.white,
          textColor: AppTheme.retroDark,
          onPressed: () => Navigator.of(context).pop(),
        ),
        _DialogButton(
          label: l10n.deleteAction,
          color: const Color(0xFFF44336),
          textColor: Colors.white,
          onPressed: () => Navigator.of(context).pop(_controller.text),
        ),
      ],
    );
  }
}
