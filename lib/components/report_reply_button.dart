import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_runtime_config.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../utils/fonts.dart';
import '../utils/rtl_locale.dart';

/// How a reported reply is sent: opened in the player's own email app.
typedef ReportLauncher = Future<bool> Function(Uri uri);

Future<bool> _openEmailApp(Uri uri) => launchUrl(uri);

/// The most of a reply that goes into the email. A reply is a few sentences; the
/// cap only stops an enormous one making a mail link too long to open.
const int _maxQuotedChars = 1000;

/// The mail link for reporting [reply] to [email].
///
/// The reply is quoted in the body so the player can see exactly what will be
/// sent and edit it before sending; nothing else is attached (no account id, no
/// chat history). Built by hand because `Uri(queryParameters:)` writes spaces as
/// `+`, which mail apps show literally.
Uri reportReplyUri(String email, String reply) {
  final quoted = reply.length > _maxQuotedChars
      ? reply.substring(0, _maxQuotedChars)
      : reply;
  final subject = Uri.encodeComponent('Mimikin: report an AI reply');
  final body = Uri.encodeComponent(
    'What was wrong with this reply? (optional)\n\n\n'
    '---\nReported reply:\n$quoted\n',
  );
  return Uri.parse('mailto:$email?subject=$subject&body=$body');
}

/// A small flag under an AI reply that opens an email reporting it.
///
/// Play expects an app that shows generated text to let the player flag
/// offensive or harmful output. There is no server inbox for this, so it hands
/// the report to the player's email app, addressed to `SUPPORT_EMAIL`, and the
/// player decides whether to send it.
///
/// Renders nothing until a support address is configured: a flag that goes
/// nowhere is worse than none.
class ReportReplyButton extends StatelessWidget {
  const ReportReplyButton({
    super.key,
    required this.reply,
    this.email = AppRuntimeConfig.supportEmail,
    this.launcher = _openEmailApp,
  });

  final String reply;
  final String email;
  final ReportLauncher launcher;

  Future<void> _report(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final textDirection =
        textDirectionForLocale(Localizations.localeOf(context));

    var opened = false;
    try {
      opened = await launcher(reportReplyUri(email, reply));
    } catch (_) {}
    if (!opened) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.retroPrimary,
          content: Text(
            l10n.reportReplyFailed,
            textDirection: textDirection,
            style: AppFonts.pressStart2p(fontSize: 8, color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (email.isEmpty) return const SizedBox.shrink();
    final label = AppLocalizations.of(context)!.reportReply;

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: () => _report(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.retroDark, width: 2),
              boxShadow: const [
                BoxShadow(color: AppTheme.retroDark, offset: Offset(2, 2)),
              ],
            ),
            child: const Icon(
              Icons.flag_outlined,
              size: 12,
              color: AppTheme.retroDark,
            ),
          ),
        ),
      ),
    );
  }
}
