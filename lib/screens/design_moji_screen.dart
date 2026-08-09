import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../l10n/app_localizations.dart';
import '../components/character_sprite.dart';
import '../providers/character_provider.dart';
import '../providers/settings_provider.dart';
import '../constants/theme.dart';
import '../utils/fonts.dart';
import '../utils/rtl_locale.dart';

/// The shared subset of the two retro font helpers (pixel / mono), so a chosen
/// font can be passed to the colour-picker helpers.
typedef _FontFn = TextStyle Function({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
});

class DesignMojiScreen extends StatelessWidget {
  const DesignMojiScreen({super.key});

  static const _characters = <Map<String, String>>[
    {'type': 'dog', 'asset': 'assets/svgs/dog.svg'},
    {'type': 'cat', 'asset': 'assets/svgs/cat.svg'},
    {'type': 'bird', 'asset': 'assets/svgs/bird.svg'},
  ];

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
    final characterProvider = Provider.of<CharacterProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final textAlign = textAlignForLocale(locale);

    final _FontFn fontFunction = settingsProvider.usePixelFont
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
            final previewSize = (constraints.maxWidth * 0.68).clamp(150.0, 260.0);
            final previewFrameHeight = (previewSize + 28).clamp(190.0, 300.0);

            return SingleChildScrollView(
              child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppTheme.retroDark, width: 4),
                    boxShadow: const [
                      BoxShadow(
                        color: AppTheme.retroDark,
                        offset: Offset(5, 5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: previewSize,
                        height: previewFrameHeight,
                        child: CharacterSprite(
                          width: previewSize,
                          height: previewFrameHeight,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _characters.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.9,
                    ),
                    itemBuilder: (context, index) {
                      final character = _characters[index];
                      final type = character['type']!;
                      final label = _characterLabelForType(l10n, type);
                      final asset = character['asset']!;
                      final isSelected = characterProvider.currentCharacterType == type;

                      return GestureDetector(
                        onTap: () => characterProvider.updateCharacterType(type),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                              ? AppTheme.retroAccent.withValues(alpha: 0.35)
                                : Colors.white,
                            border: Border.all(
                              color: AppTheme.retroDark,
                              width: isSelected ? 4 : 3,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppTheme.retroDark,
                                offset: Offset(3, 3),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: LayoutBuilder(
                            builder: (context, tileConstraints) {
                              final spriteSize =
                                  (tileConstraints.maxWidth * 0.95).clamp(70.0, 150.0);

                              return Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: SizedBox(
                                        width: spriteSize,
                                        height: spriteSize,
                                        child: SvgPicture.asset(
                                          asset,
                                          fit: BoxFit.contain,
                                          alignment: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    label,
                                    textDirection: textDirection,
                                    textAlign: textAlign,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: fontFunction(
                                      fontSize: 9,
                                      color: AppTheme.retroDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      );
                    },
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
