import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../components/tutorial/retro_showcase.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../providers/user_provider.dart';
import '../utils/fonts.dart';
import '../utils/rtl_locale.dart';
import 'coin_shop_screen.dart';
import 'premium_screen.dart';
import 'season_pass_screen.dart';
import 'shop_screen.dart';

/// The shop: four sections behind one strip of tabs.
///
/// The shop used to be the item grid alone, and everything else that costs
/// money lived somewhere else — Plus behind the allowance sheet and the
/// profile, the pass behind a tile. That left the screen a player opens in
/// order to spend showing them a quarter of what there is.
///
/// The four are **tabs, not pages**. That is the whole design of this screen
/// and it is worth being explicit about why: a player comparing what a pound
/// buys — coins, or capacity, or a track of hats — is doing one thing, and a
/// layout that makes them leave the shop and come back to compare turns one
/// decision into four errands. So the strip never moves, the bottom bar never
/// goes away, and there is no back arrow to press, because nothing was ever
/// left behind.
///
/// Plus and the pass keep their own routes as well (`/premium`, `/pass`) for
/// the doors that are not the shop — the allowance sheet, the profile tile.
/// Those wrap the same bodies in a Scaffold of their own; see [PremiumScreen]
/// and [SeasonPassScreen].
class ShopHubScreen extends StatefulWidget {
  const ShopHubScreen({super.key});

  @override
  State<ShopHubScreen> createState() => _ShopHubScreenState();
}

/// The sections, in the order the strip lists them. Const so the stack can
/// hold on to the same widgets across rebuilds.
const List<Widget> _sections = [
  ShopItemsBody(),
  CoinShopBody(),
  PremiumBody(),
  SeasonPassBody(),
];

class _ShopHubScreenState extends State<ShopHubScreen> {
  /// Starts on the item shelves, which is what `/shop` has always meant. The
  /// tab a player lands on by tapping "shop" in the bottom bar should be the
  /// shop, not an offer to sell them something.
  int _section = 0;

  /// Sections that have been opened at least once, and so are in the tree.
  ///
  /// The stack below keeps every visited section alive but builds none of them
  /// until they are asked for. Both halves matter: the pass alone is a
  /// carousel of ten tier cards, each rendering an accessory, so building all
  /// four sections to show one would make opening the shop cost four screens.
  /// Keeping them once built is what lets the carousel stay on the rung the
  /// player scrolled to, and the shelves keep their category and their
  /// hide-owned toggle, when they come back to it.
  final Set<int> _visited = {0};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textDirection =
        textDirectionForLocale(Localizations.localeOf(context));
    final fontFunction =
        AppFonts.getFont(context.watch<SettingsProvider>().usePixelFont);

    final titles = [
      l10n.shopSectionItems,
      l10n.shopSectionTopUp,
      l10n.shopSectionPlus,
      l10n.shopSectionPass,
    ];

    return Scaffold(
      backgroundColor: AppTheme.retroSky,
      appBar: AppBar(
        title: Text(
          l10n.shopTitle.toUpperCase(),
          textDirection: textDirection,
          textAlign: TextAlign.center,
          style: fontFunction(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.retroDark,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        // White rather than the sky behind it, so the title and the strip of
        // tabs below read as one header block sitting on the page instead of
        // a floating word above a bar.
        backgroundColor: Colors.white,
        elevation: 0,
        // No back arrow. The shop is one of the bottom bar's own destinations,
        // and every section of it is reached without leaving the route.
        automaticallyImplyLeading: false,
        actions: [
          // The shop tour's first step. It is anchored here rather than in the
          // items section because the balance belongs to the whole shop now,
          // and it has to stay on screen while the tour walks the sections
          // below it.
          RetroShowcase(
            showcaseKey: shopCoinsShowcaseKey,
            description: l10n.tutorialShopCoins,
            isFirst: true,
            child: ShopCoinsChip(fontFunction: fontFunction),
          ),
        ],
      ),
      body: Column(
        children: [
          _SectionStrip(
            titles: titles,
            selected: _section,
            onSelected: (i) => setState(() {
              _section = i;
              _visited.add(i);
            }),
            fontFunction: fontFunction,
            textDirection: textDirection,
          ),
          Expanded(
            child: IndexedStack(
              index: _section,
              sizing: StackFit.expand,
              children: [
                // A placeholder rather than a missing child: IndexedStack
                // addresses its children by position, so an unvisited section
                // has to hold its place in the list.
                for (var i = 0; i < _sections.length; i++)
                  _visited.contains(i)
                      ? _sections[i]
                      : const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The strip of section tabs.
///
/// One unbroken bar from edge to edge: every tab claims an equal share of the
/// width, and they sit against each other so the row reads as one control
/// rather than as four buttons floating on the sky.
///
/// It still scrolls, because these are real names in twenty-six languages
/// ("Sezónní pas", "Karnet sezonowy") and a quarter of a handset is about
/// ninety pixels. The share is a *minimum*, so a name too long for it widens
/// its tab and pushes the strip past the viewport instead of being cut down.
class _SectionStrip extends StatelessWidget {
  const _SectionStrip({
    required this.titles,
    required this.selected,
    required this.onSelected,
    required this.fontFunction,
    required this.textDirection,
  });

  final List<String> titles;
  final int selected;
  final ValueChanged<int> onSelected;
  final TextStyle Function({
    required double fontSize,
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) fontFunction;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final share = constraints.maxWidth / titles.length;
        return SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: titles.length,
            itemBuilder: (context, index) {
              final isSelected = index == selected;
              final isLast = index == titles.length - 1;
              return GestureDetector(
                onTap: () => onSelected(index),
                child: Container(
                  alignment: Alignment.center,
                  // A floor, not a width: the tabs cover the screen between
                  // them, and a locale whose name outgrows its share takes
                  // the space it needs and lets the row scroll.
                  constraints: BoxConstraints(minWidth: share),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    // The fill is what marks the selected tab. The lifted
                    // shadow the tabs used to carry has nowhere to fall now
                    // that they touch — it would land under its neighbour.
                    color: isSelected ? AppTheme.retroAccent : Colors.white,
                    // Directional rather than a plain right border: the list
                    // itself lays the tabs out in reading order, so the
                    // divider has to follow it or the far edge of an RTL
                    // strip grows one and the seam loses one.
                    border: BorderDirectional(
                      top: const BorderSide(color: AppTheme.retroDark, width: 4),
                      bottom:
                          const BorderSide(color: AppTheme.retroDark, width: 4),
                      end: BorderSide(
                        color: AppTheme.retroDark,
                        width: isLast ? 0 : 3,
                      ),
                    ),
                  ),
                  child: Text(
                    titles[index].toUpperCase(),
                    textDirection: textDirection,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: fontFunction(
                      fontSize: 10,
                      color: AppTheme.retroDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// The coin balance, as it appears in the corner of the shop.
class ShopCoinsChip extends StatelessWidget {
  const ShopCoinsChip({super.key, required this.fontFunction});

  final TextStyle Function({
    required double fontSize,
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) fontFunction;

  @override
  Widget build(BuildContext context) {
    final coins = context.watch<UserProvider>().coins;

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
      decoration: BoxDecoration(
        color: AppTheme.retroAccent,
        border: Border.all(color: AppTheme.retroDark, width: 3),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.retroDark,
            offset: Offset(2, 2),
            blurRadius: 0,
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(kCoinAsset, width: 18, height: 18),
          const SizedBox(width: 6),
          Text(
            '$coins',
            // Always LTR: a balance is a number, and an RTL locale that
            // mirrored it would reorder the digits rather than the label.
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            style: fontFunction(
              fontSize: 10,
              color: AppTheme.retroDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
