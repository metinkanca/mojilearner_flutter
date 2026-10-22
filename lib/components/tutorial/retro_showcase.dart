import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../constants/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
import '../../utils/fonts.dart';
import '../../utils/rtl_locale.dart';
import 'tutorial_scope.dart';

/// A coach mark drawn in the app's own visual language.
///
/// The package's default tooltip is a soft white rounded card, which next to
/// four-pixel borders and hard offset shadows reads as a system alert that has
/// wandered in from another app. So the tooltip is ours: [Showcase.withWidget]
/// hands us the whole card and positions it, and we draw the frame, the copy
/// and the buttons.
///
/// Everything the card needs is resolved here, in the screen's build, and
/// baked into the container as plain strings and styles. The container itself
/// is built inside the overlay, which carries the captured theme, direction
/// and media query but *not* [Localizations] — so an `.of(context)` down
/// there would come back null.
class RetroShowcase extends StatelessWidget {
  const RetroShowcase({
    super.key,
    required this.showcaseKey,
    required this.description,
    required this.child,
    this.isFirst = false,
    this.isLast = false,
    this.targetShapeBorder,
    this.targetPadding = const EdgeInsets.all(6),
    this.tooltipPosition,
  });

  /// Identifies this step in the sequence passed to `startShowCase`.
  ///
  /// Since 5.x this key is a registry id, not a widget key — it is never
  /// attached to an element, so the same key may safely be a file-level
  /// constant that outlives the widget it names.
  final GlobalKey showcaseKey;

  /// One short sentence. The pixel face is wide and the card is narrow.
  final String description;

  /// Hides BACK: there is nothing behind the first step.
  final bool isFirst;

  /// Turns NEXT into DONE on the last step of a sequence.
  final bool isLast;

  final ShapeBorder? targetShapeBorder;
  final EdgeInsets targetPadding;
  final TooltipPosition? tooltipPosition;

  final Widget child;

  /// Roughly thirty pixel-font characters to a line, which is as wide as this
  /// copy wants to be on a phone.
  static const double cardMaxWidth = 292;

  @override
  Widget build(BuildContext context) {
    // No controller, no showcase. Screens are pumped in plenty of widget
    // tests that never set tutorials up, and a coach mark is not worth
    // taking those down over.
    if (!TutorialScope.isRegistered) return child;

    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final usePixelFont = context.select<SettingsProvider, bool>(
      (settings) => settings.usePixelFont,
    );
    final font = AppFonts.getFont(usePixelFont);

    return Showcase.withWidget(
      key: showcaseKey,
      targetShapeBorder: targetShapeBorder ??
          const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      targetPadding: targetPadding,
      tooltipPosition: tooltipPosition,
      disableBarrierInteraction: true,
      container: _RetroTooltipCard(
        description: description,
        isFirst: isFirst,
        isLast: isLast,
        textDirection: textDirectionForLocale(locale),
        textAlign: textAlignForLocale(locale),
        bodyStyle: font(
          fontSize: 10,
          height: 1.7,
          color: AppTheme.retroDark,
        ),
        primaryButtonStyle: font(
          fontSize: 9,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        plainButtonStyle: font(
          fontSize: 9,
          color: AppTheme.retroDark,
          fontWeight: FontWeight.bold,
        ),
        backLabel: l10n?.tutorialBack ?? 'BACK',
        nextLabel: l10n?.tutorialNext ?? 'NEXT',
        doneLabel: l10n?.tutorialDone ?? 'DONE',
        skipLabel: l10n?.tutorialSkip ?? 'SKIP',
      ),
      child: child,
    );
  }
}

class _RetroTooltipCard extends StatelessWidget {
  const _RetroTooltipCard({
    required this.description,
    required this.isFirst,
    required this.isLast,
    required this.textDirection,
    required this.textAlign,
    required this.bodyStyle,
    required this.primaryButtonStyle,
    required this.plainButtonStyle,
    required this.backLabel,
    required this.nextLabel,
    required this.doneLabel,
    required this.skipLabel,
  });

  final String description;
  final bool isFirst;
  final bool isLast;
  final TextDirection textDirection;
  final TextAlign textAlign;
  final TextStyle bodyStyle;
  final TextStyle primaryButtonStyle;
  final TextStyle plainButtonStyle;
  final String backLabel;
  final String nextLabel;
  final String doneLabel;
  final String skipLabel;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: RetroShowcase.cardMaxWidth),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.retroDark, width: 4),
          boxShadow: const [
            BoxShadow(
              color: AppTheme.retroDark,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              description,
              style: bodyStyle,
              textDirection: textDirection,
              textAlign: textAlign,
            ),
            const SizedBox(height: 16),
            // A Wrap, not a Row: all three labels translate, and German's
            // "ÜBERSPRINGEN" alongside "ZURÜCK" and "WEITER" is 92pt wider
            // than a handset can give this card. Wrapping onto a second line
            // is the only way out of that which does not scale a pixel font
            // off its grid.
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                // On every card, so nobody is trapped in a tour they opened
                // by accident.
                _RetroTooltipButton(
                  label: skipLabel,
                  style: plainButtonStyle,
                  fill: Colors.white,
                  onTap: () => ShowcaseView.get().dismiss(),
                ),
                if (!isFirst)
                  _RetroTooltipButton(
                    label: backLabel,
                    style: plainButtonStyle,
                    fill: AppTheme.retroUi,
                    onTap: () => ShowcaseView.get().previous(),
                  ),
                _RetroTooltipButton(
                  label: isLast ? doneLabel : nextLabel,
                  style: primaryButtonStyle,
                  fill: AppTheme.retroPrimary,
                  // On the last step this runs off the end of the sequence,
                  // which is how the package finishes a tour.
                  onTap: () => ShowcaseView.get().next(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RetroTooltipButton extends StatelessWidget {
  const _RetroTooltipButton({
    required this.label,
    required this.style,
    required this.fill,
    required this.onTap,
  });

  final String label;
  final TextStyle style;
  final Color fill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
