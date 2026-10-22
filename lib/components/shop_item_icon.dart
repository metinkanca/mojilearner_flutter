import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/scenes.dart';
import '../constants/shop.dart';
import 'scene_thumbnail.dart';

/// A shop item drawn as a picture.
///
/// Food has pixel art on the pet's own 7-unit grid, so it is the same art set
/// as the cat and its accessories rather than whatever emoji the player's
/// platform happens to ship. A background shows the world itself, in
/// miniature — the one item whose emoji could never say what it does. Anything
/// else falls back to the emoji, which is what every item started as.
///
/// [size] is the box the art fits inside; the SVGs are cropped to their own
/// content, so a wide item (the capsule) and a tall one (the pizza slice)
/// both fill it without either being clipped.
class ShopItemIcon extends StatelessWidget {
  const ShopItemIcon({
    super.key,
    required this.item,
    required this.size,
    this.shadow,
  });

  final ShopItem item;
  final double size;

  /// A hard offset shadow, for the places the icon sits on the scene rather
  /// than on a card. Applied to both the art and the emoji so the two paths
  /// look the same.
  final Shadow? shadow;

  @override
  Widget build(BuildContext context) {
    if (item.type == 'background') {
      final scene = sceneThemeById(item.id);
      if (scene != null) {
        return SceneThumbnail(scene: scene, size: size);
      }
    }

    final art = item.art;
    if (art == null) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            item.icon,
            style: TextStyle(
              // Emoji are drawn inside their own generous box, so matching the
              // art's apparent size means asking for less than [size].
              fontSize: size * 0.78,
              shadows: shadow == null ? null : [shadow!],
            ),
          ),
        ),
      );
    }

    final picture = SvgPicture.asset(
      art,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    if (shadow == null) {
      return SizedBox(width: size, height: size, child: picture);
    }

    // flutter_svg has no shadow of its own, so the drop shadow is a second
    // copy of the art tinted flat and offset behind the first.
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Transform.translate(
            offset: shadow!.offset,
            child: SvgPicture.asset(
              art,
              width: size,
              height: size,
              fit: BoxFit.contain,
              colorFilter: ColorFilter.mode(shadow!.color, BlendMode.srcIn),
            ),
          ),
          picture,
        ],
      ),
    );
  }
}
