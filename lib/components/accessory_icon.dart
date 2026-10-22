import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/accessories.dart';
import '../components/character_sprite.dart' show artSourceFor;
import '../utils/pet_recolor.dart';

/// The wardrobe tile's picture of one accessory.
///
/// Exists so a palette variant needs no icon file of its own: it borrows the
/// source piece's drawing and swaps the fills, exactly as the pet does when
/// wearing it. Without this a recoloured hat would need a second icon SVG,
/// which is half the saving the recolour pipeline is for.
///
/// A piece with art of its own takes the plain asset path — no bundle read, no
/// future, no cache — so the ordinary case is exactly as cheap as it was.
class AccessoryIcon extends StatelessWidget {
  const AccessoryIcon({super.key, required this.accessory, this.fit});

  final AccessoryDef accessory;
  final BoxFit? fit;

  /// Raw icon SVGs, kept for the life of the process.
  ///
  /// The wardrobe rebuilds on every purchase and every equip, and re-reading
  /// the bundle each time would flash the tile empty on a screen that shows
  /// twenty of them. Bounded by the catalogue, which is small.
  static final Map<String, String> _rawCache = {};

  static String assetFor(AccessoryDef accessory) =>
      'assets/svgs/acc_${artSourceFor(accessory).id}_icon.svg';

  @override
  Widget build(BuildContext context) {
    final asset = assetFor(accessory);
    final fills = accessory.recolor?.fills;
    final boxFit = fit ?? BoxFit.contain;

    if (fills == null || fills.isEmpty) {
      return SvgPicture.asset(asset, fit: boxFit);
    }

    final cached = _rawCache[asset];
    if (cached != null) {
      return SvgPicture.string(recolorAccessory(cached, fills), fit: boxFit);
    }

    return FutureBuilder<String>(
      future: rootBundle.loadString(asset).then((raw) {
        _rawCache[asset] = raw;
        return raw;
      }),
      builder: (context, snapshot) {
        final raw = snapshot.data;
        // The uncoloured drawing for one frame rather than a hole in the
        // shelf. The shapes are identical, so what settles is the colour.
        if (raw == null) return SvgPicture.asset(asset, fit: boxFit);
        return SvgPicture.string(recolorAccessory(raw, fills), fit: boxFit);
      },
    );
  }
}
