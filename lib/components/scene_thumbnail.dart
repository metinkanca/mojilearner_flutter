import 'package:flutter/material.dart';

import '../constants/scenes.dart';
import 'scene_backdrop.dart';
import 'scene_motif.dart';
import '../constants/theme.dart';

/// A scene shrunk to a tile: the same sky band, ground band, celestial body
/// and decor the home screen paints, at a size that fits a shop card.
///
/// Drawn from the scene's own palette rather than from a screenshot or a flat
/// swatch, so a retuned world updates everywhere it is shown and what the
/// player is buying is what they will get.
class SceneThumbnail extends StatelessWidget {
  const SceneThumbnail({
    super.key,
    required this.scene,
    required this.size,
    this.time,
  });

  final SceneTheme scene;

  /// Width of the tile. The scene keeps its own sky-to-ground proportion
  /// inside it — see [SceneTheme.horizon] — so height follows from this.
  final double size;

  /// Which palette to show. Defaults to daytime, so two scenes side by side
  /// are compared on the same terms.
  final SceneTime? time;

  @override
  Widget build(BuildContext context) {
    final palette = time == null ? scene.preview : scene.paletteFor(time!);

    // The decor is authored for a full screen; at tile size it would be a
    // scatter of dots wider than the tile itself. Scaled down by the same
    // factor as the tile and capped so it never disappears entirely.
    final scale = (size / 360).clamp(0.18, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                Expanded(
                  flex: (scene.horizon * 1000).round(),
                  child: Container(
                    width: double.infinity,
                    color: palette.sky,
                    child: Stack(
                      children: [
                        for (final speck in palette.skySpecks)
                          _Speck(
                            speck: speck,
                            color: palette.skySpeckColor,
                            scale: scale,
                          ),
                        // Sky drawings. Scaled to fit the tile rather than by the
                        // speck factor above: a motif is one picture, and at the
                        // scatter's scale the plane would be four pixels.
                        for (final motif in palette.skyMotifs)
                          SceneMotifBox(
                            motif: motif,
                            inks: palette.motifInks,
                            scale: motif.scaleFor(size),
                          ),
                        if (palette.celestial != null)
                          Align(
                            alignment: const Alignment(-0.5, 0.1),
                            child: Container(
                              width: size * 0.2,
                              height: size * 0.2,
                              decoration: BoxDecoration(
                                color: palette.celestial,
                                border: Border.all(
                                  color: AppTheme.retroDark,
                                  width: size * 0.02,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1000 - (scene.horizon * 1000).round(),
                  child: Container(
                    width: double.infinity,
                    color: palette.ground,
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            height: size * 0.02,
                            color: AppTheme.retroDark,
                          ),
                        ),
                        for (final speck in palette.groundSpecks)
                          _Speck(
                            speck: speck,
                            color: palette.groundDetail,
                            scale: scale,
                          ),
                        for (final motif in palette.groundMotifs)
                          SceneMotifBox(
                            motif: motif,
                            inks: palette.motifInks,
                            scale: motif.scaleFor(size),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (scene.asset != null)
              SceneBackdrop(
                scene: scene,
                time: time ?? SceneTime.day,
                alignment: scene.previewAlignment,
              ),
          ],
        ),
      ),
    );
  }
}

class _Speck extends StatelessWidget {
  const _Speck({
    required this.speck,
    required this.color,
    required this.scale,
  });

  final SceneSpeck speck;
  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment(speck.x, speck.y),
      child: SizedBox(
        // Never below a pixel: a speck rounded to zero would silently drop
        // the decor from the smallest tiles.
        width: (speck.width * scale).clamp(1.0, speck.width),
        height: (speck.height * scale).clamp(1.0, speck.height),
        child: ColoredBox(
          color: speck.opacity == 1.0
              ? color
              : color.withValues(alpha: speck.opacity),
        ),
      ),
    );
  }
}
