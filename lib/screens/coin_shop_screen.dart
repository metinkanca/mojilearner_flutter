import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../constants/coin_packs.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/premium_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/fonts.dart';
import '../utils/rtl_locale.dart';

/// The coin, as a picture. See `art_src/gen_coin.py` for how it is struck.
const String kCoinAsset = 'assets/svgs/coin.svg';

/// The top-up counter: coins for money.
///
/// The page is the ladder and nothing else. There is no paragraph explaining
/// what coins are for — a player reading this screen has already spent some —
/// and no sentence quoting the rate, because each row states its own rate by
/// putting the coins and the price side by side.
///
/// A price comes from [ProductDetails.price] whenever the store has one:
/// that is the only figure a player in Japan or Brazil is actually charged.
/// Before the store answers the rows fall back to the ladder's US list price
/// so the page can still be read, and say so in a line above them — a price
/// slot left empty reads as a broken row rather than as an honest one.
///
/// Carries no chrome: it is a section of the shop's slider, and the balance in
/// the corner belongs to [ShopHubScreen].
class CoinShopBody extends StatefulWidget {
  const CoinShopBody({super.key});

  @override
  State<CoinShopBody> createState() => _CoinShopBodyState();
}

class _CoinShopBodyState extends State<CoinShopBody> {
  /// The pack whose purchase we are still waiting on, so the row that was
  /// tapped is the row that says so. `isPurchasePending` alone only knows that
  /// *something* is in flight.
  String? _pendingPackId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textDirection =
        textDirectionForLocale(Localizations.localeOf(context));
    final store = context.watch<PremiumProvider>();
    final fontFunction =
        AppFonts.getFont(context.watch<SettingsProvider>().usePixelFont);

    // Coins granted by a purchase that completed while this page was open —
    // including one the store finished long after the tap, which is why the
    // grant itself lives on the provider and not here.
    final granted = store.takeCoinsGranted();
    if (granted != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _pendingPackId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            backgroundColor: AppTheme.retroDark,
            content: Text(
              l10n.topUpThanks(granted),
              textDirection: textDirection,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      });
    }

    // With no listings, the prices on the right are the ladder's own US list
    // figures rather than nothing at all: a row with an empty price slot reads
    // as broken, and a player looking at the counter before it opens should
    // still be able to see what the piles cost. The line above the ladder is
    // what keeps that honest, and the moment the store answers, every price
    // becomes the store's own — the player's currency, their tax rules.
    final storeOpen = store.isAvailable;

    // The notice, when there is one, is the first row of the same list, so it
    // scrolls with the ladder rather than pinning a banner over it.
    final offset = storeOpen ? 0 : 1;

    return ListView.separated(
      // Room at the top and on the right for the best-value seal, which hangs
      // off the corner of its row rather than sitting inside it.
      padding: const EdgeInsets.fromLTRB(16, 20, 24, 24),
      itemCount: coinPacks.length + offset,
      // A wider gap above the last rung, which is the one wearing the seal:
      // the sticker hangs above its own box, and has to land inempty space
      // rather than on the row above it.
      separatorBuilder: (context, index) => SizedBox(
        height: index == coinPacks.length + offset - 2 ? 44 : 12,
      ),
      itemBuilder: (context, index) {
        if (index < offset) {
          return _ClosedNotice(
            message: l10n.topUpNotOpen,
            fontFunction: fontFunction,
            textDirection: textDirection,
          );
        }

        final rung = index - offset;
        final pack = coinPacks[rung];
        final listing = storeOpen ? store.coinPackProduct(pack.id) : null;
        return _PackRow(
          pack: pack,
          rung: rung,
          // The store's price when there is one, the list price when there is
          // not. Never a number assembled here out of both.
          price: listing?.price ?? pack.usdPrice,
          isListed: listing != null,
          // The last rung, which is the best deal by construction: every step
          // up the ladder pays more per unit of money than the one below.
          isBest: rung == coinPacks.length - 1,
          isPending: _pendingPackId == pack.id,
          // Every row answers a tap, including the ones that cannot be bought
          // yet — a tile that does nothing at all reads as a broken tile. What
          // an unbuyable one does is say why.
          onTap: () {
            if (!storeOpen || listing == null) {
              _say(context, l10n.topUpNotOpen, textDirection);
              return;
            }
            // One purchase at a time. The store enforces this too, but a
            // second tap that silently does nothing looks like a broken button
            // rather than a queue.
            if (store.isPurchasePending) {
              _say(context, l10n.premiumPurchasePending, textDirection);
              return;
            }
            setState(() => _pendingPackId = pack.id);
            store.buyCoinPack(pack.id);
          },
          fontFunction: fontFunction,
          textDirection: textDirection,
          l10n: l10n,
        );
      },
    );
  }

  /// One line of feedback, in the retro bar the grant message already uses.
  void _say(BuildContext context, String message, TextDirection textDirection) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: AppTheme.retroDark,
          content: Text(
            message,
            textDirection: textDirection,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
  }
}

/// The line above the ladder when the store has no listings to sell.
class _ClosedNotice extends StatelessWidget {
  const _ClosedNotice({
    required this.message,
    required this.fontFunction,
    required this.textDirection,
  });

  final String message;
  final TextStyle Function({
    required double fontSize,
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) fontFunction;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.retroDark, width: 4),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.retroDark,
            offset: Offset(4, 4),
            blurRadius: 0,
          )
        ],
      ),
      child: Text(
        message,
        textDirection: textDirection,
        style: fontFunction(
          fontSize: 9,
          color: AppTheme.retroDark,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// One rung of the ladder: the coins it holds, its bonus, and what it costs.
class _PackRow extends StatelessWidget {
  const _PackRow({
    required this.pack,
    required this.rung,
    required this.price,
    required this.isListed,
    required this.isBest,
    required this.isPending,
    required this.onTap,
    required this.fontFunction,
    required this.textDirection,
    required this.l10n,
  });

  final CoinPack pack;

  /// Position on the ladder, which is how many coins the pile is drawn with.
  final int rung;

  /// What to print in the price slot: the store's own formatted price, or the
  /// ladder's US list price when the store has no listing for this pack.
  final String price;

  /// Whether [price] came from the store. A list price is still shown, but it
  /// is not a live one, so the slot is drawn flat instead of as a button.
  final bool isListed;

  final bool isBest;
  final bool isPending;
  final VoidCallback? onTap;
  final TextStyle Function({
    required double fontSize,
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) fontFunction;
  final TextDirection textDirection;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        // The seal hangs off the top corner, and a Stack clips its children to
        // its own box unless told otherwise.
        clipBehavior: Clip.none,
        children: [
          Container(
            // The seal-wearing row carries a band of empty space along its
            // top, which is what the sticker dips into. Without it the disc
            // would either float clear of the box or land on the price.
            padding: EdgeInsets.fromLTRB(12, isBest ? 26 : 12, 12, 12),
            decoration: BoxDecoration(
              // Every rung is white, the top one included. Filling the best
              // deal with the accent made it read as the selected row rather
              // than as the recommended one; the seal is what marks it now.
              color: Colors.white,
              border: Border.all(color: AppTheme.retroDark, width: 4),
              boxShadow: const [
                BoxShadow(
                  color: AppTheme.retroDark,
                  offset: Offset(4, 4),
                  blurRadius: 0,
                )
              ],
            ),
            child: Row(
              children: [
                CoinPile(count: rung + 1),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.topUpCoins(pack.coins).toUpperCase(),
                        textDirection: textDirection,
                        style: fontFunction(
                          fontSize: 12,
                          color: AppTheme.retroDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Nothing under the anchor pack: it has no bonus and no
                      // badge, and an explicit "+0%" would be advertising the
                      // rung that exists to set the rate.
                      if (pack.bonusPercent > 0) ...[
                        const SizedBox(height: 6),
                        _Tag(
                          label: l10n.topUpBonus(pack.bonusPercent),
                          color: AppTheme.retroGreen,
                          textColor: Colors.white,
                          fontFunction: fontFunction,
                          textDirection: textDirection,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    // Only a live listing gets the raised button colour. A
                    // list price sits flat, because tapping it cannot buy
                    // anything yet.
                    color: isPending
                        ? Colors.grey[300]
                        : isListed
                            ? AppTheme.retroLight
                            : Colors.white,
                    border: Border.all(color: AppTheme.retroDark, width: 3),
                  ),
                  child: Text(
                    isPending ? l10n.premiumPurchasePending : price,
                    // A price string carries its own currency symbol and its
                    // own direction; the pending label is prose and follows
                    // the locale.
                    textDirection: isPending ? textDirection : TextDirection.ltr,
                    style: fontFunction(
                      fontSize: isPending ? 7 : 10,
                      color: AppTheme.retroDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isBest)
            // Pinned to the top-right corner and let out over both edges, the
            // way a sticker is stuck on a box rather than printed on it.
            Positioned(
              // High enough that the disc clears the price slot below it,
              // and far enough out that it breaks the box's right side.
              top: -26,
              right: -18,
              child: _BestValueSeal(
                label: l10n.topUpBestValue,
                fontFunction: fontFunction,
                textDirection: textDirection,
              ),
            ),
        ],
      ),
    );
  }
}

/// The best-value sticker: a red disc tilted off the corner of the top rung.
///
/// Tilted 30 degrees clockwise, which is most of the point of it — a badge
/// square to the row is one more label in a column of labels, and one at an
/// angle is a thing stuck on afterwards. It keeps the same outline every other
/// surface has, so it reads as part of the same drawing.
class _BestValueSeal extends StatelessWidget {
  const _BestValueSeal({
    required this.label,
    required this.fontFunction,
    required this.textDirection,
  });

  /// The diameter of the disc. Big enough for the longest translation of
  /// "best value" over three lines at the badge type size, small enough to sit
  /// above the price rather than on it.
  static const double _size = 56;

  final String label;
  final TextStyle Function({
    required double fontSize,
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) fontFunction;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      // Positive radians turn clockwise on screen.
      angle: 30 * math.pi / 180,
      child: Container(
        width: _size,
        height: _size,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: AppTheme.retroPrimary,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.retroDark, width: 3),
        ),
        child: Text(
          label.toUpperCase(),
          textDirection: textDirection,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: fontFunction(
            fontSize: 7,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// A heap of [count] coins, drawn from the one coin asset.
///
/// One piece of art rather than six pack illustrations: the rungs differ by
/// how much money they are, so the honest picture of the difference is more of
/// the same coin. It also means retuning the ladder cannot leave a $50 pack
/// illustrated with somebody's idea of a $20 one.
///
/// Laid out on a fixed stage so every row is the same height and the prices
/// line up down the page. Positions are hand-placed rather than computed —
/// a heap is not a formula, and five arrangements is fewer lines than the
/// geometry that would generate them.
class CoinPile extends StatelessWidget {
  const CoinPile({super.key, required this.count, this.size = 56});

  /// How many coins to draw, one per rung. Clamped, so a seventh rung
  /// added to the catalogue draws the biggest heap rather than throwing.
  final int count;

  /// The side of the square stage the heap is drawn on.
  final double size;

  /// Each coin's centre, as a fraction of the stage, back to front. Later
  /// entries overlap earlier ones, so the front row is drawn last.
  static const List<List<Offset>> _arrangements = [
    [Offset(0.5, 0.5)],
    [Offset(0.36, 0.62), Offset(0.64, 0.38)],
    [Offset(0.5, 0.3), Offset(0.32, 0.66), Offset(0.68, 0.66)],
    [
      Offset(0.35, 0.28),
      Offset(0.65, 0.28),
      Offset(0.28, 0.68),
      Offset(0.6, 0.7),
    ],
    [
      Offset(0.34, 0.26),
      Offset(0.64, 0.24),
      Offset(0.22, 0.6),
      Offset(0.5, 0.62),
      Offset(0.76, 0.6),
    ],
    [
      Offset(0.3, 0.22),
      Offset(0.58, 0.2),
      Offset(0.78, 0.4),
      Offset(0.22, 0.55),
      Offset(0.5, 0.6),
      Offset(0.74, 0.74),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final places =
        _arrangements[(count - 1).clamp(0, _arrangements.length - 1)];
    // Coins shrink as the heap grows, so six of them occupy about the same
    // stage as one and the rows stay the same height.
    final coin = size *
        switch (places.length) {
          1 => 0.62,
          <= 5 => 0.46,
          _ => 0.40,
        };

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          for (final place in places)
            Positioned(
              left: place.dx * size - coin / 2,
              top: place.dy * size - coin / 2,
              child: SvgPicture.asset(kCoinAsset, width: coin, height: coin),
            ),
        ],
      ),
    );
  }
}

/// A small square-cornered label — the bonus and the best-value flag.
class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.color,
    required this.textColor,
    required this.fontFunction,
    required this.textDirection,
  });

  final String label;
  final Color color;
  final Color textColor;
  final TextStyle Function({
    required double fontSize,
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) fontFunction;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: AppTheme.retroDark, width: 2),
      ),
      child: Text(
        label.toUpperCase(),
        textDirection: textDirection,
        style: fontFunction(
          fontSize: 7,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
