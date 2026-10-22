/// Coin packs: the one thing in the shop that is paid for with money.
///
/// The ladder is a doubling one. Each rung holds twice the coins of the rung
/// below — 100, 200, 400, 800, 1600, 3200 — and costs a little *less* than
/// twice as much. That is the whole offer in one sentence: the coins double
/// cleanly, the price does not quite keep up, and so the rate quietly improves
/// all the way up. A player does not have to work any of that out, because
/// each row states its own rate by putting the coins and the price side by
/// side, and the badge names the difference.
///
/// The discount is deliberately small at the bottom and never dramatic at the
/// top: the base rung is the anchor the catalogue is priced against, and a top
/// rung that paid double would make every other row look like a mistake rather
/// than a choice. A third more coins per dollar is enough to make climbing
/// worth it and small enough that the bottom rung is still an honest purchase.
///
/// Two prices, and it matters which is which:
///
/// * [usdPrice] is the **list price**, the number a console listing should be
///   set to. It is what the page falls back to before the store is open, so
///   the ladder can be read at all, and it is a US figure.
/// * [ProductDetails.price] is what a player is actually charged, in their
///   currency under their tax rules, and it is what the page shows the moment
///   the store answers. Nothing here ever assembles a price out of the two.
///
/// Where this sits against the rest of the economy, which is the part worth
/// being careful about:
///
/// * **Packs buy appearance, never care.** The same line `gold.dart` draws
///   around earned coins applies to bought ones: food and medicine are the
///   cheapest things on the shelves and the daily reward hands them out, so no
///   pack is ever the difference between a looked-after pet and a neglected
///   one.
/// * **Nothing here touches the bond.** XP, bond stages and every accessory
///   gated on one stay earned through the language — see `bond.dart`. A pack
///   moves the wardrobe closer, not the relationship.
/// * **The taper in `gold.dart` is untouched.** Buying coins is deliberately
///   not a way to raise the ceiling on what learning pays; it is a separate
///   source, and the day's earning bands are measured only against earned
///   coins.
///
/// This was once a change of position from the paywall, which carried a note
/// reading "Coins ... are never for sale" — written when learning was the only
/// route to a coin. That note has since been taken off the page, so the two no
/// longer disagree.
library;

/// Coins the bottom rung hands over, and what it lists for in US cents.
///
/// Every other rung is measured against this pair: it is the base rate, and
/// the badge on a rung says how much better than this one it is.
const int _baseCoins = 100;
const int _baseCents = 99;

/// The rate the catalogue is priced against: roughly a hundred coins to the
/// dollar, which is what the bottom rung is — 100 coins for $0.99. A round
/// number rather than the exact 101 that price works out to, because its job
/// is to make a 250-coin hat read as "about $2.50" and not to be arithmetic
/// anybody checks.
const int coinsPerDollar = 100;

/// One pack, as sold.
class CoinPack {
  const CoinPack({
    required this.id,
    required this.productId,
    required this.coins,
    required this.cents,
    required this.rung,
  });

  /// Stable id, used in analytics and to look a pack up from a purchase.
  ///
  /// Named for its size rather than its contents on purpose: retuning the
  /// ladder must not require a new store listing, and a product id with `100`
  /// in it would.
  final String id;

  /// Store product id. A *consumable* — unlike Plus and the season pass, a
  /// pack is bought, paid out and gone, and the same one can be bought again.
  final String productId;

  /// What the pack hands over. Doubles every rung.
  final int coins;

  /// The US list price in cents: what the console listing should be set to,
  /// and the figure [usdPrice] formats. Cents rather than dollars because no
  /// rung above the first is a whole number of them.
  final int cents;

  /// Position on the ladder, 0 for the base pack.
  final int rung;

  /// The list price as a US figure, for the one case where there is nothing
  /// better to show: the store has not answered yet, or has no listings at
  /// all. A live listing always wins over this — see the class doc.
  String get usdPrice => '\$${(cents / 100).toStringAsFixed(2)}';

  /// How much better this rung's rate is than the base rung's, as a
  /// percentage of extra coins per unit of money — 0 on the bottom rung.
  ///
  /// Derived from the coins and the price rather than declared beside them, so
  /// a badge cannot end up advertising a discount the price does not give.
  int get bonusPercent =>
      ((coins * _baseCents) / (cents * _baseCoins) * 100 - 100).round();
}

/// The rungs: coins, and the US list price in cents. Cheapest first.
///
/// Six of them. The coins double on every step, which is the part a player
/// reads without thinking about it; the prices are the deliberate part, each
/// one set a little under twice the rung below so that the rate climbs 0, 5,
/// 10, 17, 24 and 32 per cent above the base. The top rung is deliberately
/// kept under $25 — past that a single purchase buys more of the catalogue
/// than the catalogue has.
const List<(int coins, int cents)> _rungs = [
  (_baseCoins, _baseCents),
  (200, 189),
  (400, 359),
  (800, 679),
  (1600, 1279),
  (3200, 2399),
];

const List<String> _rungIds = [
  'pouch',
  'sack',
  'chest',
  'vault',
  'hoard',
  'trove',
];

/// Every pack on sale, cheapest first.
final List<CoinPack> coinPacks = [
  for (var i = 0; i < _rungs.length; i++)
    CoinPack(
      id: _rungIds[i],
      productId: 'com.mimikin.app.coins.${_rungIds[i]}',
      coins: _rungs[i].$1,
      cents: _rungs[i].$2,
      rung: i,
    ),
];

/// The pack with [id], or null when nothing matches.
CoinPack? coinPackById(String id) {
  for (final pack in coinPacks) {
    if (pack.id == id) return pack;
  }
  return null;
}
