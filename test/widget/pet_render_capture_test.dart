import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/character_sprite.dart';
import 'package:mojilearner_flutter/constants/accessories.dart';
import 'package:mojilearner_flutter/constants/pets.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:mojilearner_flutter/utils/pet_recolor.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Not an assertion — a camera. Draws every pet through the real renderer,
/// plain and then dressed and recoloured, and writes the frames out as PNGs
/// for a person to look at.
///
/// Chrome is the quick way to preview the SVGs (see the art notes), but it is
/// not what ships: it honours `shape-rendering="crispEdges"` where flutter_svg
/// does not, and it never sees the sprite's own transforms — the blink, the
/// mirrored cap, the accessory offsets. This does.
///
/// Tagged `capture` and skipped by default, because it writes files and
/// checks nothing. Run it when the art or the placements change:
///
///     flutter test test/widget/pet_render_capture_test.dart \
///         --tags capture --dart-define=CAPTURE_DIR=<somewhere>
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const dir = String.fromEnvironment('CAPTURE_DIR');

  /// One frame of [type], saved as `<dir>/<name>.png`.
  Future<void> capture(
    WidgetTester tester,
    String name,
    String type, {
    List<AccessoryDef> wearing = const [],
    String? coat,
    Color background = const Color(0xFF6E9B54),
    bool darkEyes = false,
  }) async {
    // A fresh provider per frame, and prefs wiped first, so nothing a
    // previous frame saved can bleed into this one — the coat is set on the
    // pet being drawn, which means that pet has to be the one out.
    SharedPreferences.setMockInitialValues({'character_type': type});
    final character = CharacterProvider(startDecayTimer: false);
    await tester.pump();
    if (coat != null) {
      character.updateBodyColor(coat);
      expect(character.colorSpecFor(type).bodyColor, coat,
          reason: 'the $coat coat did not take on the $type');
    }
    if (darkEyes) {
      character.updateEyeColors(mode: EyeMode.solid, color1: kOutlineFill);
    }
    final key = GlobalKey();

    await tester.pumpWidget(
      ChangeNotifierProvider<CharacterProvider>.value(
        value: character,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: RepaintBoundary(
                key: key,
                child: Container(
                  // A ground line where the scene puts one, so the cast
                  // shadow can be seen landing on something.
                  color: background,
                  padding: const EdgeInsets.only(bottom: 52),
                  child: CharacterSprite(
                    width: 222,
                    height: 328,
                    previewType: type,
                    previewAccessories: wearing,
                    groundShadow: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // The SVG layers are loaded from the bundle, so the first frames are the
    // plain-asset fallback; pump until the tinted strings have arrived.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    // toImage awaited directly inside testWidgets never completes — the fake
    // clock is not running the engine. runAsync is the whole trick.
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final png = await image.toByteData(format: ImageByteFormat.png);
      File('$dir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });

    await tester.pumpWidget(const SizedBox.shrink());
    character.dispose();
  }

  testWidgets('draw every pet, plain and dressed', (tester) async {
    final hat = accessoryById('tophat')!;
    final neck = accessoryById('collar')!;
    final face = accessoryById('glasses')!;

    for (final type in kPetTypes) {
      // The legacy character_type-only fixture migrates to the old grey
      // coat. Explicitly preview the natural coat for the art comparison.
      await capture(tester, '${type}_plain', type, coat: naturalCoatFor(type));
      await capture(tester, '${type}_dressed', type,
          // Ginger, one of the free coats, so the gate cannot quietly
          // swallow it and leave the frame looking un-recoloured.
          wearing: [hat, neck, face], coat: '#E0883B');
      // Neutral coats expose stray shading; the dark backdrop exposes pale
      // fringes hidden by the daytime grass. Keep a close-review frame too.
      await capture(tester, '${type}_dark', type,
          coat: '#959379', background: const Color(0xFF121414), darkEyes: true);
    }
    // Nowhere to write means nothing to do — see the note above for how to
    // run it.
  }, skip: dir.isEmpty);
}
