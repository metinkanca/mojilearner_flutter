import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../constants/entitlements.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/ads_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/user_provider.dart';
import '../utils/fonts.dart';
import '../utils/rtl_locale.dart';

/// The subset of [AppFonts.getFont]'s signature this sheet actually uses.
typedef _WallFontFn = TextStyle Function({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? height,
});

/// What the app says when a day's model allowance is spent.
///
/// The shape of this sheet is the whole argument. `gold.dart` refused a hard
/// cap on coins because "hitting a wall mid-session tells the player to stop
/// studying", and that objection would apply here too if this were a door.
/// It is not: the middle of the sheet always names something free the player
/// can go and do right now, and the routes out are offers rather than the only
/// way forward.
///
/// So the order is deliberate — what is spent, when it comes back, what is
/// still open, and only then the two ways to have more today. "Come back
/// tomorrow" is never the whole message.
class AiLimitSheet extends StatefulWidget {
  const AiLimitSheet({super.key, required this.spend});

  /// Which meter ran out. Decides the wording, and whether an ad is offered at
  /// all: ads buy quizzes, never messages.
  final AiSpend spend;

  static Future<void> show(BuildContext context, AiSpend spend) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => AiLimitSheet(spend: spend),
    );
  }

  @override
  State<AiLimitSheet> createState() => _AiLimitSheetState();
}

class _AiLimitSheetState extends State<AiLimitSheet> {
  bool _watchingAd = false;

  bool get _isQuiz => widget.spend == AiSpend.quiz;

  /// Watches a rewarded ad, and closes the sheet if it bought a quiz.
  ///
  /// Closing on success rather than staying open with a changed number is the
  /// point: the player asked for one more quiz, and the next thing they should
  /// see is the quiz, not this sheet again.
  Future<void> _watchAd() async {
    final ads = context.read<AdsProvider>();
    final user = context.read<UserProvider>();

    setState(() => _watchingAd = true);
    try {
      final earned = await ads.watchRewarded(user);
      if (!mounted) return;
      if (earned > 0) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _watchingAd = false);
    }
  }

  void _openPaywall() {
    Navigator.of(context).pop();
    context.pushNamed('premium');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textDirection =
        textDirectionForLocale(Localizations.localeOf(context));
    final fontFunction =
        AppFonts.getFont(context.watch<SettingsProvider>().usePixelFont);

    final user = context.watch<UserProvider>();
    final ads = context.watch<AdsProvider>();

    final limit = user.aiLimit(widget.spend);
    // An ad is only worth offering for the meter it can actually refill, and
    // only while the day still has one left to give.
    final canWatchAd = _isQuiz && ads.canOfferRewarded && !_watchingAd;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppTheme.retroDark, width: 4),
        borderRadius: BorderRadius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isQuiz
                  ? (l10n?.aiLimitQuizTitle ?? 'Today’s AI quizzes are '
                      'used up')
                  : (l10n?.aiLimitMessageTitle ?? 'Today’s AI messages '
                      'are used up'),
              textDirection: textDirection,
              style: fontFunction(
                fontSize: 12,
                color: AppTheme.retroDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n?.aiLimitUsage(limit, limit) ?? '$limit of $limit used today',
              textDirection: textDirection,
              style: fontFunction(
                fontSize: 8,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n?.aiLimitResets ?? 'Your allowance comes back tomorrow.',
              textDirection: textDirection,
              style: fontFunction(
                fontSize: 8,
                height: 1.6,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            // The part that keeps this from being a door. A spent quiz meter
            // still leaves the review queue; a spent message meter still
            // leaves both review and the locally-built quiz.
            Text(
              _isQuiz
                  ? (l10n?.aiLimitReviewOpen ??
                      'Review never needs the tutor — your due cards are '
                          'always there.')
                  : (l10n?.aiLimitQuizOpen ??
                      'Quizzes built from your own words are still there.'),
              textDirection: textDirection,
              style: fontFunction(
                fontSize: 8,
                height: 1.6,
                color: AppTheme.retroDark,
              ),
            ),
            const SizedBox(height: 18),
            if (canWatchAd) ...[
              _WallButton(
                label: l10n?.aiLimitWatchAd ?? 'Watch an ad for one more',
                fontFunction: fontFunction,
                textDirection: textDirection,
                filled: false,
                onTap: _watchAd,
              ),
              const SizedBox(height: 8),
            ],
            _WallButton(
              label: l10n?.aiLimitGoPlus ?? 'Get Mimikin Plus',
              fontFunction: fontFunction,
              textDirection: textDirection,
              filled: true,
              onTap: _watchingAd ? null : _openPaywall,
            ),
          ],
        ),
      ),
    );
  }
}

/// The retro button both offers share, so the ad route and the paid route look
/// like the same kind of thing — two ways to have more today, rather than a
/// real choice and a decoy.
class _WallButton extends StatelessWidget {
  const _WallButton({
    required this.label,
    required this.fontFunction,
    required this.textDirection,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final _WallFontFn fontFunction;
  final TextDirection textDirection;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: filled ? AppTheme.retroSky : Colors.white,
            border: Border.all(color: AppTheme.retroDark, width: 2),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            textDirection: textDirection,
            style: fontFunction(
              fontSize: 8,
              color: AppTheme.retroDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
