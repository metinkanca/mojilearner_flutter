import 'package:flutter/material.dart';

import '../../../constants/theme.dart';
import 'onboarding_text.dart';

/// The flow's primary button: square, hard-shadowed, in the retro frame the
/// rest of the app uses.
///
/// Labelled in whatever language is currently on offer rather than the app's,
/// so it takes that [locale] and draws in that script's faces.
class RetroButton extends StatelessWidget {
  final String label;
  final Locale locale;
  final TextDirection textDirection;
  final bool usePixelFont;

  /// Null disables the button — it dims and stops taking taps, which is how
  /// the language step holds the player until they have actually picked one.
  final VoidCallback? onTap;

  const RetroButton({
    super.key,
    required this.label,
    required this.locale,
    required this.textDirection,
    required this.usePixelFont,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.retroPrimary,
            border: Border.all(color: AppTheme.retroDark, width: 4),
            boxShadow: enabled
                ? const [
                    BoxShadow(
                      color: AppTheme.retroDark,
                      offset: Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textDirection: textDirection,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: onboardingTextStyle(
              usePixelFont: usePixelFont,
              locale: locale,
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
