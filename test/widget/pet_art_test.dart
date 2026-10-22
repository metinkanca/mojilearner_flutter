import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/character_sprite.dart';
import 'package:mojilearner_flutter/components/pet_art_cache.dart';
import 'package:mojilearner_flutter/constants/accessories.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:mojilearner_flutter/utils/pet_recolor.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pet_art.dart';
import '../helpers/pump_app.dart';
import '../helpers/scene_capture.dart';

/// The pet arrives whole.
///
/// It used to arrive in pieces: the coat in its drawn colour, then the tail,
/// the eyes, the hat, each when its own picture finished parsing, and again
/// every time a screen mounted a new sprite, because the parsed pictures were
/// thrown away with the last one. These hold the three things that fixed it:
/// all of a pet's layers show in the same frame, they are still there for the
/// next screen, and a change of outfit swaps in whole rather than layer by
/// layer.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(PetArt.debugClear);

  CharacterProvider provider() {
    SharedPreferences.setMockInitialValues({});
    return CharacterProvider(startDecayTimer: false);
  }

  /// A cat in its natural coat wearing [hat], as a preview: it reads nothing
  /// from the saved pet, so the only thing between it and the screen is the
  /// layers loading.
  Widget cat(AccessoryDef? hat) => SizedBox(
        width: 222,
        height: 328,
        child: CharacterSprite(
          width: 222,
          height: 328,
          previewType: 'cat',
          naturalCoat: true,
          previewAccessories: [if (hat != null) hat],
        ),
      );

  /// The layers on screen *and drawn*: a [PetPicture] whose picture has not
  /// been parsed is in the tree but paints nothing, which is exactly the
  /// half-dressed pet.
  List<String> layers(WidgetTester tester) => [
        for (final p in tester.widgetList<PetPicture>(find.byType(PetPicture)))
          if (PetArt.picture(p.svg) != null) p.svg,
      ];

  final tophat = accessoryById('tophat')!;
  final crown = accessoryById('crown')!;

  testWidgets('every layer of the pet shows in the same frame', (tester) async {
    final character = provider();
    await pumpApp(tester, cat(tophat), characterProvider: character);

    final counts = <int>[layers(tester).length];
    for (var round = 0; round < 6; round++) {
      await tester.runAsync(PetArt.settled);
      await tester.pump();
      counts.add(layers(tester).length);
    }

    final whole = counts.last;
    expect(whole, greaterThanOrEqualTo(5),
        reason: 'coat, tail, mouth, eyes and the hat');
    expect(counts.toSet().difference({0, whole}), isEmpty,
        reason: 'the pet went from nothing to whole, never half there: '
            '$counts');
  });

  testWidgets('and is still whole the first frame a later screen shows it',
      (tester) async {
    final character = provider();
    await pumpApp(tester, cat(tophat), characterProvider: character);
    await settlePet(tester);
    final whole = layers(tester).length;
    expect(whole, greaterThanOrEqualTo(5));

    // Off the screen, and the sprite with it.
    await pumpApp(tester, const SizedBox(), characterProvider: character);
    expect(layers(tester), isEmpty);

    // A new sprite on a new screen. One frame, no waiting: this is the moment
    // that used to show the coat alone.
    await pumpApp(tester, cat(tophat), characterProvider: character);
    expect(layers(tester), hasLength(whole));
  });

  testWidgets('a new hat swaps in whole; the old outfit stays up until then',
      (tester) async {
    final character = provider();
    await pumpApp(tester, cat(tophat), characterProvider: character);
    await settlePet(tester);
    final before = layers(tester);

    await pumpApp(tester, cat(crown), characterProvider: character);

    // The crown has not been read yet. The pet is neither bare nor missing a
    // layer: it is the old one, complete.
    expect(layers(tester), before);

    await settlePet(tester);
    final after = layers(tester);
    expect(after, hasLength(before.length));
    expect(after, isNot(before), reason: 'now it wears the crown');
  });

  testWidgets('a pet whose save has not been read is not drawn',
      (tester) async {
    // Before the save is read the provider holds a default pet in a default
    // coat with nothing on: the stranger that used to flash up first.
    final character = MockCharacterProvider();
    when(() => character.isLoaded).thenReturn(false);
    when(() => character.currentCharacterType).thenReturn('cat');
    when(() => character.currentCharacterAsset)
        .thenReturn('assets/svgs/cat.svg');
    when(() => character.colorSpecFor(any())).thenReturn(const PetColorSpec(
      bodyColor: '#959379',
      eyeMode: EyeMode.solid,
      eyeColor1: '#F4C430',
      eyeColor2: '#5AA0E0',
    ));
    when(() => character.equippedAccessoriesFor(any())).thenReturn(const []);
    // Not const: a const sprite is the same widget on the second pump, and the
    // tree would not look at it again.
    Widget sprite() {
      final width = 222.0;
      return SizedBox(
          width: width,
          height: 328,
          child: CharacterSprite(width: width, height: 328));
    }

    await pumpApp(tester, sprite(), characterProvider: character);
    await settlePet(tester);
    expect(layers(tester), isEmpty);

    when(() => character.isLoaded).thenReturn(true);
    await pumpApp(tester, sprite(), characterProvider: character);
    await settlePet(tester);
    expect(layers(tester), isNotEmpty);
  });

  group('a layer comes out as flutter_svg draws it', () {
    const asset = 'assets/svgs/cat.svg';

    bool anyPaint(SceneFrame f) {
      for (var i = 3; i < f.rgba.lengthInBytes; i += 4) {
        if (f.rgba.getUint8(i) != 0) return true;
      }
      return false;
    }

    /// Share of pixels that differ by more than [tolerance] in any channel.
    double differing(SceneFrame a, SceneFrame b, {int tolerance = 8}) {
      final pixels = a.rgba.lengthInBytes ~/ 4;
      var off = 0;
      for (var i = 0; i < pixels; i++) {
        for (var c = 0; c < 4; c++) {
          final d = a.rgba.getUint8(i * 4 + c) - b.rgba.getUint8(i * 4 + c);
          if (d.abs() > tolerance) {
            off++;
            break;
          }
        }
      }
      return off / pixels;
    }

    for (final size in const [Size(222, 328), Size(300, 200), Size(120, 400)]) {
      testWidgets('in a ${size.width.round()}x${size.height.round()} box',
          (tester) async {
        await tester.runAsync(() => PetArt.loadRaw([asset]));
        final svg = PetArt.raw(asset)!;
        await tester.runAsync(() => PetArt.prepare([svg]));

        final vector = await captureScene(
            tester, SvgPicture.string(svg, fit: BoxFit.contain), size,
            asset: asset, ready: anyPaint);
        final picture = await captureScene(
            tester, PetPicture(svg), size,
            asset: asset, ready: anyPaint);

        expect(differing(vector, picture), lessThan(0.002));
      });
    }
  });
}
