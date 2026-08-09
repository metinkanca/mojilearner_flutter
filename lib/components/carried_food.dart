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
              style: fontFunction(
                fontSize: 7,
                height: 1.6,
                color: AppTheme.retroDark.withValues(alpha: 0.7),
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
                      color: Colors.white,
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

class _Bubble extends StatelessWidget {
  const _Bubble({required this.icon, this.size = 44});

  final String icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.retroLight,
          border: Border.all(color: AppTheme.retroDark, width: 3),
          boxShadow: const [
            BoxShadow(
              color: AppTheme.retroDark,
              offset: Offset(3, 3),
              blurRadius: 0,
            )
          ],
        ),
        child: Text(icon, style: TextStyle(fontSize: size * 0.5)),
      ),
    );
  }
}
