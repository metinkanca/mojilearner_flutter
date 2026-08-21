import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../components/character_carousel.dart';
import '../providers/character_provider.dart';
import '../providers/settings_provider.dart';
import '../constants/theme.dart';
import '../utils/fonts.dart';
import '../utils/rtl_locale.dart';

class DesignMojiScreen extends StatelessWidget {
  const DesignMojiScreen({super.key});

  /// Carousel order, left to right. The cat sits in the middle because it is
  /// the pet a new player starts with.
  static const _characterTypes = <String>['dog', 'cat', 'bird'];

  String _characterLabelForType(AppLocalizations l10n, String type) {
    switch (type) {
      case 'dog':
        return l10n.characterDog;
      case 'cat':
        return l10n.characterCat;
      case 'bird':
        return l10n.characterBird;
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);

    final CarouselFontFn fontFunction = settingsProvider.usePixelFont
        ? AppFonts.pressStart2p
        : AppFonts.spaceMono;

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
            // are what space the three pets apart.
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
                      types: _characterTypes,
                      tileWidth: tileWidth,
                      labelForType: (type) =>
                          _characterLabelForType(l10n, type),
                      fontFunction: fontFunction,
                      textDirection: textDirection,
                      initialType: context
                          .read<CharacterProvider>()
                          .currentCharacterType,
                      // This screen is the pet being lived with, so the
                      // settled pet is adopted on the spot.
                      onSelected: (type) => context
                          .read<CharacterProvider>()
                          .updateCharacterType(type),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.selectYourCharacter.toUpperCase(),
                    textDirection: textDirection,
                    textAlign: TextAlign.center,
                    style: fontFunction(
                      fontSize: 10,
                      color: AppTheme.retroDark,
                      fontWeight: FontWeight.bold,
                    ),
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
