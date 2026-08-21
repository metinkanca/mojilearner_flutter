import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/shop.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/character_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/fonts.dart';
import '../utils/rtl_locale.dart';

/// The food the player is carrying, as something they can drag onto the pet.
///
/// Renders nothing until a food is picked up in the care panel, so it costs
/// no screen space in the common case.
class CarriedFood extends StatelessWidget {
  const CarriedFood({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final fontFunction = AppFonts.getFont(settings.usePixelFont);
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);

    return Consumer<CharacterProvider>(
      builder: (context, character, _) {
        final item = _itemById(character.heldFoodId);
        if (item == null) return const SizedBox.shrink();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n?.careDragToFeed ?? 'Drag onto Moji to feed',
              textDirection: textDirection,
              textAlign: TextAlign.center,
              // White on a hard dark shadow: the hint now floats over the
              // pet and the ground rather than over chrome, and those change
              // colour with the time of day.
              style: fontFunction(
                fontSize: 7,
                height: 1.6,
                color: Colors.white,
              ).copyWith(
                shadows: const [
                  Shadow(
                    color: AppTheme.retroDark,
                    offset: Offset(1, 1),
                    blurRadius: 0,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Draggable<String>(
                  data: item.id,
                  dragAnchorStrategy: pointerDragAnchorStrategy,
                  feedback: _Bubble(icon: item.icon, size: 56),
                  // The pet stops anticipating if the drag is abandoned
                  // mid-air, otherwise it sits with its mouth open forever.
                  onDraggableCanceled: (_, __) => character.setFoodHovering(false),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _Bubble(icon: item.icon),
                  ),
                  child: GestureDetector(
                    // Tap is the fallback for anyone who does not discover the
                    // drag, and for pointer setups where dragging is awkward.
                    onTap: () {
                      final id = character.heldFoodId;
                      if (id == null) return;
                      character.putDownFood();
                      character.offerFood(id);
                    },
                    child: _Bubble(icon: item.icon),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: character.putDownFood,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.retroLight,
                      border: Border.all(color: AppTheme.retroDark, width: 3),
                    ),
                    child: const Icon(Icons.close,
                        size: 16, color: AppTheme.retroDark),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static ShopItem? _itemById(String? id) {
    if (id == null) return null;
    for (final item in shopItems) {
      if (item.id == id) return item;
    }
    return null;
  }
}

/// The food itself, as a bare glyph.
///
/// It used to sit in a bordered box the same off-white as the rest of the
/// chrome, which read as a UI tile rather than as an apple the player is
/// holding — and against the scene it was a white rectangle stamped on the
/// grass. Now it is just the food, with a hard offset shadow in the pixel
/// idiom to keep it legible on any sky or ground the time of day produces.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.icon, this.size = 44});

  final String icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        // Kept square at [size] so the tap target does not shrink to the
        // glyph's own ink.
        width: size,
        height: size,
        child: Center(
          child: Text(
            icon,
            style: TextStyle(
              fontSize: size * 0.78,
              shadows: const [
                Shadow(
                  color: AppTheme.retroDark,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
