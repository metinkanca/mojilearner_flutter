import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import '../constants/entitlements.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/premium_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/user_provider.dart';
import '../utils/fonts.dart';
import '../utils/rtl_locale.dart';

/// What Mimikin Plus is, stated as a comparison rather than a pitch.
///
/// The page is a table on purpose. Most of what Plus sells is a number that is
/// already visible elsewhere in the app — how many quizzes the tutor will
/// write, how many things the pet will say back — so the honest way to sell it
/// is to show both columns and let the difference speak. There is nothing here
/// a player has to take on trust.
///
/// Two rows are not numbers, and both are there because the numbers alone
/// were a poor description of the thing. A daily allowance nobody reaches is
/// not worth paying for, so unused quizzes now carry forward and the row says
/// so. And the pet decays more slowly, which is the only line on the page that
/// sells *time* rather than a quantity: what a lapsed player dreads is the
/// state they will find the pet in. Note what that row does not say — the pet
/// still declines, still gets hungry and can still get sick, because a pet
/// that could not would stop being one. `PlusCareConstants` explains why the
/// slower slope is also the more profitable one.
///
/// The dressing around the table is only there to make the page worth landing
/// on: a highlighted Plus column so the difference is visible before the
/// numbers are read, and the app's own hard borders and offset shadows so the
/// paywall looks like it belongs to the same game as the wardrobe. None of it
/// makes a claim the table does not.
///
/// It opens straight onto the table, with no banner naming the product above
/// it. Both doors into this page — the shop's Plus tab and `/premium` — have
/// already said what it is by the time anyone arrives, so a title block was
/// a screen's worth of height spent repeating the tab that was just tapped.
///
/// The page no longer *prints* the list of what Plus does not buy. It is still
/// the rule the design is held to — everything below is here or absent because
/// of it — but a paywall that spends a panel advertising its own absences is
/// arguing with a reader who has not objected yet.
///
/// Deliberately absent, and each for a reason written down elsewhere:
///
/// * **coins**, because `gold.dart` cut the login reward from 375 a week to 45
///   precisely to stop money that was not earned by learning from outweighing
///   money that was;
/// * **bond stages and the accessories gated on them**, because the premise of
///   the game is that closeness is earned through the language (`bond.dart`);
/// * **cloud backup**, because a free player losing their pet with their phone
///   is not a thing to sell the fix for; and
/// * **rewarded ads**, because `ads.dart` already worked out that removing
///   them would leave a paying player with fewer coin sources than a free one.
///
/// Cosmetics are not here either. They belong to the season pass, which is a
/// separate purchase — capacity and content are different things to want, and
/// bundling them would mean a player who only wants hats pays monthly forever.
/// Plus on its own page, for the routes that arrive from outside the shop —
/// the allowance sheet, the profile tile, and anything linking to `/premium`.
///
/// A frame and nothing else: the page's content is [PremiumBody], because the
/// shop's slider shows the same thing without a Scaffold or a back arrow of
/// its own. Two widgets rather than a `bool` parameter so neither caller can
/// accidentally get the other's chrome.
class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textDirection =
        textDirectionForLocale(Localizations.localeOf(context));
    final fontFunction =
        AppFonts.getFont(context.watch<SettingsProvider>().usePixelFont);

    return Scaffold(
      backgroundColor: AppTheme.retroSky,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: _RetroIconButton(
          icon: Icons.arrow_back,
          onPressed: () => context.pop(),
        ),
        title: Text(
          (l10n?.aiLimitGoPlus ?? 'Get Mimikin Plus').toUpperCase(),
          textDirection: textDirection,
          textAlign: TextAlign.center,
          style: fontFunction(
            fontSize: 10,
            color: AppTheme.retroDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: const PremiumBody(),
    );
  }
}

/// What Plus is, as the comparison table described above. Carries no chrome,
/// so the shop's slider can show it under the tabs.
class PremiumBody extends StatefulWidget {
  const PremiumBody({super.key});

  @override
  State<PremiumBody> createState() => _PremiumBodyState();
}

class _PremiumBodyState extends State<PremiumBody> {
  /// Says the restore button found nothing, which is a different answer from
  /// the button appearing to do nothing at all.
  void _reportRestore(bool recovered) {
    if (!mounted || recovered) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        l10n?.premiumRestoreDone ?? 'Nothing to restore on this account.',
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textDirection =
        textDirectionForLocale(Localizations.localeOf(context));
    final fontFunction =
        AppFonts.getFont(context.watch<SettingsProvider>().usePixelFont);
    final isPremium = context.select<UserProvider, bool>((u) => u.isPremium);
    final premium = context.watch<PremiumProvider>();

    const free = EntitlementConstants.free;
    const plus = EntitlementConstants.premium;

    return SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ComparisonTable(
                fontFunction: fontFunction,
                textDirection: textDirection,
                rows: [
                  _ComparisonRow(
                    icon: Icons.quiz_outlined,
                    label: l10n?.premiumRowQuizzes ?? 'AI quizzes a day',
                    free: '${free.quizzes}',
                    plus: '${plus.quizzes}',
                  ),
                  _ComparisonRow(
                    icon: Icons.chat_bubble_outline,
                    label: l10n?.premiumRowMessages ?? 'AI messages a day',
                    free: '${free.messages}',
                    plus: '${plus.messages}',
                  ),
                  _ComparisonRow(
                    icon: Icons.savings_outlined,
                    label: l10n?.premiumRowRollover ?? 'Unused quizzes',
                    free: l10n?.premiumValueExpire ?? 'Expire',
                    plus: l10n?.premiumValueRollOver ?? 'Roll over',
                  ),
                  _ComparisonRow(
                    icon: Icons.block_outlined,
                    label: l10n?.premiumRowAds ?? 'Interstitial ads',
                    free: l10n?.premiumValueShown ?? 'Shown',
                    plus: l10n?.premiumValueNone ?? 'None',
                  ),
                  _ComparisonRow(
                    icon: Icons.favorite_outline,
                    label: l10n?.premiumRowPetStats ?? 'Pet stats',
                    free: l10n?.premiumValueDecay ?? 'Decay',
                    plus: l10n?.premiumValueDecaySlower ?? 'Decay slower',
                  ),
                ],
              ),
              const SizedBox(height: 22),
              if (isPremium)
                _Notice(
                  fontFunction: fontFunction,
                  textDirection: textDirection,
                  label: l10n?.premiumActive ?? 'Mimikin Plus is active.',
                )
              else if (premium.isPurchasePending)
                _Notice(
                  fontFunction: fontFunction,
                  textDirection: textDirection,
                  label: l10n?.premiumPurchasePending ??
                      'Finishing with the store…',
                )
              // A build with no product ids, or a device the store will not
              // talk to, says so plainly rather than drawing a price it cannot
              // charge. A live-looking dead button is worse than an honest gap.
              else if (!premium.isAvailable)
                _Notice(
                  fontFunction: fontFunction,
                  textDirection: textDirection,
                  label: l10n?.premiumComingSoon ??
                      'Subscriptions are not open yet.',
                )
              else ...[
                for (final product in premium.products) ...[
                  _PlanButton(
                    product: product,
                    fontFunction: fontFunction,
                    textDirection: textDirection,
                    onTap: () => premium.buy(product),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 4),
                // Both stores require a way back to a subscription on a new
                // device, and a player who paid and cannot recover it writes
                // the review that costs the most.
                TextButton(
                  onPressed: premium.isRestoring
                      ? null
                      : () async => _reportRestore(await premium.restore()),
                  child: Text(
                    l10n?.premiumRestore ?? 'Restore a purchase',
                    textDirection: textDirection,
                    style: fontFunction(
                      fontSize: 8,
                      color: AppTheme.retroDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
  }
}

class _ComparisonRow {
  const _ComparisonRow({
    required this.icon,
    required this.label,
    required this.free,
    required this.plus,
  });

  final IconData icon;
  final String label;
  final String free;
  final String plus;
}

/// Free and Plus side by side, because the whole product is the difference
/// between two columns of numbers.
///
/// The Plus column is tinted down the whole table rather than only in its
/// header, so the eye follows one stripe of numbers instead of reading three
/// separate comparisons.
class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({
    required this.rows,
    required this.fontFunction,
    required this.textDirection,
  });

  final List<_ComparisonRow> rows;
  final _PremiumFontFn fontFunction;
  final TextDirection textDirection;

  static const int _freeFlex = 2;
  static const int _plusFlex = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return _RetroPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _header(
            free: l10n?.premiumColumnFree ?? 'Free',
            plus: l10n?.premiumColumnPlus ?? 'Plus',
          ),
          for (var i = 0; i < rows.length; i++)
            _row(rows[i], last: i == rows.length - 1),
        ],
      ),
    );
  }

  Widget _header({required String free, required String plus}) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.retroLight,
        border: Border(
          bottom: BorderSide(color: AppTheme.retroDark, width: 3),
        ),
      ),
      // Stretch tints the Plus cell down the full row, which needs a height to
      // stretch to — the empty label cell supplies it, and IntrinsicHeight is
      // what turns that into a height for the Row.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Expanded(flex: 4, child: SizedBox(height: 34)),
            Expanded(
              flex: _freeFlex,
              child: Center(
                child: Text(
                  free,
                  textDirection: textDirection,
                  style: fontFunction(
                    fontSize: 8,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: _plusFlex,
              child: Container(
                color: AppTheme.retroAccent,
                alignment: Alignment.center,
                child: Text(
                  plus,
                  textDirection: textDirection,
                  style: fontFunction(
                    fontSize: 8,
                    color: AppTheme.retroDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(_ComparisonRow row, {required bool last}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: last
            ? null
            : const Border(
                bottom: BorderSide(color: AppTheme.retroDark, width: 2),
              ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 8, 14),
                child: Row(
                  children: [
                    Icon(row.icon, size: 14, color: AppTheme.retroDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        row.label,
                        textDirection: textDirection,
                        style: fontFunction(
                          fontSize: 8,
                          height: 1.5,
                          color: AppTheme.retroDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: _freeFlex,
              child: Center(
                child: Text(
                  row.free,
                  textAlign: TextAlign.center,
                  textDirection: textDirection,
                  style: fontFunction(
                    fontSize: 8,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: _plusFlex,
              child: Container(
                color: AppTheme.retroAccent.withValues(alpha: 0.35),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  row.plus,
                  textAlign: TextAlign.center,
                  textDirection: textDirection,
                  style: fontFunction(
                    fontSize: 10,
                    color: AppTheme.retroDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One plan, priced by the store rather than by the app.
///
/// [ProductDetails.price] arrives already localised and already in the
/// viewer's own currency, so it is shown verbatim. A price the app formatted
/// itself would eventually disagree with the one the payment sheet charges,
/// and that disagreement is the kind that gets an app pulled.
class _PlanButton extends StatelessWidget {
  const _PlanButton({
    required this.product,
    required this.fontFunction,
    required this.textDirection,
    required this.onTap,
  });

  final ProductDetails product;
  final _PremiumFontFn fontFunction;
  final TextDirection textDirection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        // Green, not the table's yellow: yellow is doing the job of marking
        // the Plus column, and a button in the same colour reads as more of
        // the same chart rather than as the thing to press. Green is what the
        // rest of the app puts on a button that commits to something.
        decoration: BoxDecoration(
          color: AppTheme.retroGrass,
          border: Border.all(color: AppTheme.retroDark, width: 3),
          boxShadow: const [
            BoxShadow(color: AppTheme.retroDark, offset: Offset(4, 4)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                product.title,
                textDirection: textDirection,
                style: fontFunction(
                  fontSize: 8,
                  height: 1.5,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              product.price,
              textDirection: textDirection,
              style: fontFunction(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A plain statement where a button would otherwise be.
class _Notice extends StatelessWidget {
  const _Notice({
    required this.label,
    required this.fontFunction,
    required this.textDirection,
  });

  final String label;
  final _PremiumFontFn fontFunction;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    return _RetroPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Text(
        label,
        textAlign: TextAlign.center,
        textDirection: textDirection,
        style: fontFunction(
          fontSize: 8,
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// The app's card: flat fill, hard border, hard offset shadow.
class _RetroPanel extends StatelessWidget {
  const _RetroPanel({
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.retroDark, width: 3),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.retroDark,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Back button with the app's raised-border treatment.
class _RetroIconButton extends StatelessWidget {
  const _RetroIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.retroDark, width: 3),
        boxShadow: const [
          BoxShadow(color: AppTheme.retroDark, offset: Offset(2, 2)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: AppTheme.retroDark, size: 20),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        // No round ink ripple inside the square retro frame.
        style: const ButtonStyle(
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
    );
  }
}

/// The subset of [AppFonts.getFont]'s signature this page uses.
typedef _PremiumFontFn = TextStyle Function({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? height,
});
