import 'package:flutter/material.dart';

import '../../../constants/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/account_service.dart';
import 'onboarding_text.dart';
import 'retro_button.dart';

/// Named so tests can reach the fields without depending on label text.
const Key loginEmailFieldKey = Key('first-launch-email');
const Key loginPasswordFieldKey = Key('first-launch-password');

/// The last step of the opening: an offer to keep the pet that was just
/// chosen, and a way past it.
///
/// Deliberately an offer. The pet already exists under an anonymous uid and
/// is already syncing; signing in upgrades that uid in place rather than
/// creating anything, so "maybe later" costs the player nothing today. What
/// it costs is the guarantee — see [AccountService].
class LoginPanel extends StatefulWidget {
  final AccountService account;
  final AppLocalizations strings;
  final Locale locale;
  final TextDirection textDirection;
  final bool usePixelFont;

  /// Signed in, or decided not to. Either way the opening is over.
  final VoidCallback onDone;

  const LoginPanel({
    super.key,
    required this.account,
    required this.strings,
    required this.locale,
    required this.textDirection,
    required this.usePixelFont,
    required this.onDone,
  });

  @override
  State<LoginPanel> createState() => _LoginPanelState();
}

class _LoginPanelState extends State<LoginPanel> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  /// Whether the address form has replaced the list of choices.
  bool _showingForm = false;

  /// Blocks a second tap while a provider sheet or a network call is open.
  bool _busy = false;

  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  AppLocalizations get _s => widget.strings;

  /// Provider codes onto something a player can act on. Anything unrecognised
  /// becomes the general message rather than leaking a raw code on screen.
  String _messageFor(String? code) {
    switch (code) {
      case 'invalid-email':
        return _s.accountErrorInvalidEmail;
      case 'weak-password':
        return _s.accountErrorWeakPassword;
      default:
        return _s.accountErrorSignIn;
    }
  }

  Future<void> _run(Future<AccountLinkResult> Function() attempt) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final result = await attempt();
    if (!mounted) return;

    if (result.isLinked) {
      widget.onDone();
      return;
    }
    if (result.isCancelled) {
      // The player closed the sheet themselves. Nothing to explain.
      setState(() => _busy = false);
      return;
    }
    if (result.isConflict) {
      setState(() => _busy = false);
      await _askWhichPet(result.email);
      return;
    }
    setState(() {
      _busy = false;
      _error = _messageFor(result.code);
    });
  }

  /// The two-pets question. Asked, never guessed: there is no honest merge of
  /// a pet raised here and a pet raised on the account.
  Future<void> _askWhichPet(String? email) async {
    final choice = await showDialog<ConflictChoice>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppTheme.retroDark, width: 4),
          borderRadius: BorderRadius.zero,
        ),
        title: Text(_s.accountConflictTitle, style: _style(12)),
        content: Text(
          _s.accountConflictBody(email ?? ''),
          style: _style(10),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(ConflictChoice.keepThisDevice),
            child: Text(_s.accountConflictKeepThisDevice, style: _style(9)),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(ConflictChoice.useSavedAccount),
            child: Text(_s.accountConflictUseSaved, style: _style(9)),
          ),
        ],
      ),
    );

    if (choice == null || !mounted) return;

    setState(() => _busy = true);
    final result = _showingForm
        ? await widget.account.resolveConflict(
            email: _email.text.trim(),
            password: _password.text,
            choice: choice,
          )
        : await widget.account.resolveGoogleConflict(choice: choice);
    if (!mounted) return;

    if (result.isLinked) {
      widget.onDone();
      return;
    }
    setState(() {
      _busy = false;
      _error = _messageFor(result.code);
    });
  }

  TextStyle _style(double size, {Color color = AppTheme.retroDark}) =>
      onboardingTextStyle(
        usePixelFont: widget.usePixelFont,
        locale: widget.locale,
        fontSize: size,
        color: color,
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _s.onboardingLoginTitle,
            textDirection: widget.textDirection,
            textAlign: TextAlign.center,
            style: _style(14),
          ),
          const SizedBox(height: 8),
          Text(
            _s.onboardingLoginSubtitle,
            textDirection: widget.textDirection,
            textAlign: TextAlign.center,
            style: _style(9),
          ),
          const SizedBox(height: 20),
          if (_showingForm) ..._formChildren() else ..._choiceChildren(),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              textDirection: widget.textDirection,
              textAlign: TextAlign.center,
              style: _style(9, color: AppTheme.retroPrimary),
            ),
          ],
          const SizedBox(height: 12),
          TextButton(
            onPressed: _busy ? null : widget.onDone,
            child: Text(
              _s.onboardingLoginSkip,
              textDirection: widget.textDirection,
              style: _style(9),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _choiceChildren() => [
        // Withheld where the platform cannot show Google's sheet, rather than
        // offered and then failing at the tap.
        if (widget.account.supportsGoogle) ...[
          RetroButton(
            label: _s.onboardingLoginGoogle,
            locale: widget.locale,
            textDirection: widget.textDirection,
            usePixelFont: widget.usePixelFont,
            onTap: _busy ? null : () => _run(widget.account.linkGoogleAccount),
          ),
          const SizedBox(height: 12),
        ],
        RetroButton(
          label: _s.onboardingLoginEmail,
          locale: widget.locale,
          textDirection: widget.textDirection,
          usePixelFont: widget.usePixelFont,
          onTap: _busy
              ? null
              : () => setState(() {
                    _showingForm = true;
                    _error = null;
                  }),
        ),
      ];

  List<Widget> _formChildren() => [
        _field(
          key: loginEmailFieldKey,
          controller: _email,
          label: _s.accountEmailLabel,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _field(
          key: loginPasswordFieldKey,
          controller: _password,
          label: _s.accountPasswordLabel,
          obscure: true,
        ),
        const SizedBox(height: 16),
        RetroButton(
          label: _s.accountContinueAction,
          locale: widget.locale,
          textDirection: widget.textDirection,
          usePixelFont: widget.usePixelFont,
          onTap: _busy
              ? null
              : () => _run(() => widget.account.linkAccount(
                    _email.text.trim(),
                    _password.text,
                  )),
        ),
      ];

  Widget _field({
    required Key key,
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.retroDark, width: 3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        key: key,
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        autocorrect: false,
        enableSuggestions: false,
        style: _style(10),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: _style(9),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
