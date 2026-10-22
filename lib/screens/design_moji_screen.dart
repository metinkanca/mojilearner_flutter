import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../components/character_carousel.dart';
import '../components/character_sprite.dart';
import '../components/purchase_dialogs.dart';
import '../providers/character_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/user_provider.dart';
import '../constants/pets.dart';
import '../constants/theme.dart';
import '../utils/fonts.dart';
import '../utils/rtl_locale.dart';

/// The pet changer: every pet in the rank, the three starters free and the
/// rest for sale.
///
/// A pet the player owns is adopted the moment it settles in the middle, as
/// it always was. One they do not is shown with its price and a buy button
/// instead, and swiping past it changes nothing — the pet out stays out until
/// one is bought or another owned one is picked.
class DesignMojiScreen extends StatefulWidget {
  const DesignMojiScreen({super.key});

  @override
  State<DesignMojiScreen> createState() => _DesignMojiScreenState();
}

class _DesignMojiScreenState extends State<DesignMojiScreen> {
  /// The pet in the middle of the carousel, which is not the pet out when it
  /// has not been bought.
  late String _centred =
      context.read<CharacterProvider>().currentCharacterType;

  void _onSettled(String type) {
    setState(() => _centred = type);
    final character = context.read<CharacterProvider>();
    // This screen is the pet being lived with, so an owned pet is adopted on
    // the spot.
    if (character.ownsPet(type)) character.updateCharacterType(type);
  }

  void _buy({
    required String type,
    required int price,
    required String name,
    required PurchaseFontFn fontFunction,
    required TextDirection textDirection,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final character = context.read<CharacterProvider>();
    final user = context.read<UserProvider>();

    if (user.coins < price) {
      showNoticeDialog(
        context: context,
        fontFunction: fontFunction,
        textDirection: textDirection,
        title: name,
        message: l10n.notEnoughCoinsMessage,
        detail: '${AccessoryTileIcons.coin} $price',
        action: rewardedAdAction(context),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => BuyDialog(
        preview: CharacterSprite(width: 88, height: 88, previewType: type),
        name: name,
        price: price,
        fontFunction: fontFunction,
        textDirection: textDirection,
        onConfirm: () async {
          Navigator.of(dialogContext).pop();
          final bought = await character.purchasePet(type, user);
          // Straight out, the way a bought hat goes straight on: meeting the
          // pet is what it was bought for.
          if (bought) await character.updateCharacterType(type);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final character = context.watch<CharacterProvider>();
    final coins = context.watch<UserProvider>().coins;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);

    final CarouselFontFn fontFunction = settingsProvider.usePixelFont
        ? AppFonts.pressStart2p
        : AppFonts.spaceMono;

    int? priceFor(String type) =>
        character.ownsPet(type) ? null : petPrice(type);
    final centredPrice = priceFor(_centred);

    return Scaffold(
      backgroundColor: AppTheme.retroSky,
      appBar: AppBar(
        title: Text(
          l10n.designMoji.toUpperCase(),
          textDirection: textDirection,
          textAlign: TextAlign.center,
          style: fontFunction(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.retroDark,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.retroDark, width: 3),
            boxShadow: const [
              BoxShadow(
                color: AppTheme.retroDark,
                offset: Offset(2, 2),
                blurRadius: 0,
              )
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back,
                color: AppTheme.retroDark, size: 20),
            onPressed: () => context.pop(),
            padding: EdgeInsets.zero,
            // No round ink ripple inside the square retro frame.
            style: const ButtonStyle(
              overlayColor: WidgetStatePropertyAll(Colors.transparent),
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.retroDark, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: AppTheme.retroDark,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                )
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.checkroom,
                  color: AppTheme.retroDark, size: 20),
              tooltip: 'Wardrobe',
              onPressed: () => context.pushNamed('wardrobe'),
              padding: EdgeInsets.zero,
              // No round ink ripple inside the square retro frame.
              style: const ButtonStyle(
                overlayColor: WidgetStatePropertyAll(Colors.transparent),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Tile width is tied to the carousel's page width (see
            // [CharacterCarousel]): a tile has to fit its page, and the pages
            // are what space the pets apart.
            final tileWidth =
                (constraints.maxWidth * CharacterCarousel.tileFraction)
                    .clamp(120.0, 220.0);
            final stageHeight = CharacterCarousel.stageHeight(tileWidth);

            return SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: stageHeight,
                    child: CharacterCarousel(
                      types: kPetTypes,
                      tileWidth: tileWidth,
                      labelForType: (type) => petDisplayName(l10n, type),
                      fontFunction: fontFunction,
                      textDirection: textDirection,
                      initialType: character.currentCharacterType,
                      priceForType: priceFor,
                      onSelected: _onSettled,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (centredPrice == null)
                    Text(
                      l10n.selectYourCharacter.toUpperCase(),
                      textDirection: textDirection,
                      textAlign: TextAlign.center,
                      style: fontFunction(
                        fontSize: 10,
                        color: AppTheme.retroDark,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    // The purse beside the price, since pets are bought here:
                    // whether one is affordable should not take a trip to the
                    // shop to find out. Down here rather than in the app bar,
                    // where it squeezed the title in every language.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      textDirection: textDirection,
                      children: [
                        SizedBox(
                          width: tileWidth,
                          child: RetroDialogButton(
                            label: '${l10n.buy.toUpperCase()}  '
                                '${AccessoryTileIcons.coin} $centredPrice',
                            color: AppTheme.retroGrass,
                            fontFunction: fontFunction,
                            textDirection: textDirection,
                            onTap: () => _buy(
                              type: _centred,
                              price: centredPrice,
                              name: petDisplayName(l10n, _centred),
                              fontFunction: fontFunction,
                              textDirection: textDirection,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        CoinBalance(coins: coins, fontFunction: fontFunction),
                      ],
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
