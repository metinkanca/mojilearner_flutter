import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/boss_trial/arena_scenery.dart';
import 'package:mojilearner_flutter/components/rasterized_svg.dart';

import '../helpers/scene_capture.dart';

/// Scenery drawn once into an image, rather than replayed as paths every
/// frame.
///
/// The whole case for it is that nobody can tell. The image is made at the
/// pixel size it is shown at, so it has to come out as the picture
/// flutter_svg draws, laid out the same way — these compare the two through
/// the real renderer. And it has to actually be kept: a second copy draws
/// straight from the cache, and the home scene keeps its image while the
/// keyboard squeezes its box.
void main() {
  setUp(debugClearRasterizedSvgCache);

  const room = 'assets/svgs/cozy_room.svg';
  const dragon = 'assets/svgs/arena_dragon_backdrop.svg';

  bool anyPaint(SceneFrame f) {
    for (var i = 3; i < f.rgba.lengthInBytes; i += 4) {
      if (f.rgba.getUint8(i) != 0) return true;
    }
    return false;
  }

  Future<SceneFrame> capture(
          WidgetTester tester, Widget child, Size size, String asset) =>
      captureScene(tester, child, size, asset: asset, ready: anyPaint);

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

  /// [child] laid out at [size] on a test view already sized by a capture.
  Future<void> pumpAt(WidgetTester tester, Size size, Widget child) =>
      tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox.fromSize(size: size, child: child),
        ),
      ));

  /// Whether a [RasterizedSvg] is showing its image rather than the
  /// placeholder.
  bool showingImage() => find
      .descendant(
          of: find.byType(RasterizedSvg), matching: find.byType(CustomPaint))
      .evaluate()
      .isNotEmpty;

  testWidgets('a covered scene comes out as flutter_svg draws it',
      (tester) async {
    const size = Size(390, 700);
    final vector = await capture(
        tester,
        SvgPicture.asset(room,
            fit: BoxFit.cover, alignment: Alignment.bottomCenter),
        size,
        room);
    final image = await capture(
        tester,
        RasterizedSvg.asset(room,
            fit: BoxFit.cover, alignment: Alignment.bottomCenter),
        size,
        room);

    expect(differing(vector, image), lessThan(0.002));
  });

  testWidgets('a stretched backdrop comes out as flutter_svg draws it',
      (tester) async {
    const size = Size(390, 640);
    final vector = await capture(
        tester, SvgPicture.asset(dragon, fit: BoxFit.fill), size, dragon);
    final image = await capture(
        tester, RasterizedSvg.asset(dragon, fit: BoxFit.fill), size, dragon);

    expect(differing(vector, image), lessThan(0.002));
  });

  // The arena's bands each show a window of the backdrop. They used to lay
  // the whole picture out at the band's stretch and clip it; the window has
  // to show exactly what that showed.
  testWidgets('a window shows what the clipped arena band showed',
      (tester) async {
    const art = ArenaArt.dragon;
    final from = art.ledgeLine!, to = art.groundLine;
    const box = Size(390, 330);
    final pictureW = box.width * art.backdropWidth / art.width;
    final pictureH = box.height * art.height / (to - from);
    final clipped = await capture(
        tester,
        Stack(children: [
          Positioned(
            left: (box.width - pictureW) / 2,
            top: -from / art.height * pictureH,
            width: pictureW,
            height: pictureH,
            child: SvgPicture.asset(dragon, fit: BoxFit.fill),
          ),
        ]),
        box,
        dragon);
    final side = (1 - art.width / art.backdropWidth) / 2;
    final windowed = await capture(
        tester,
        RasterizedSvg.asset(dragon,
            fit: BoxFit.fill,
            window: Rect.fromLTRB(
                side, from / art.height, 1 - side, to / art.height)),
        box,
        dragon);

    expect(differing(clipped, windowed), lessThan(0.002));
  });

  testWidgets('a second copy draws straight from the cache', (tester) async {
    const size = Size(390, 640);
    Widget backdrop() => RasterizedSvg.asset(dragon, fit: BoxFit.fill);
    await capture(tester, backdrop(), size, dragon);

    // A new widget, so nothing is carried over but the cache — and no real
    // time passes, so an image that had to be made would not be there.
    await pumpAt(tester, size, const SizedBox());
    await pumpAt(tester, size, backdrop());
    expect(showingImage(), isTrue);
  });

  testWidgets('the home scene keeps its image as the keyboard squeezes it',
      (tester) async {
    Widget scene() => RasterizedSvg.asset(room,
        fit: BoxFit.cover, alignment: Alignment.bottomCenter);
    await capture(tester, scene(), const Size(390, 700), room);

    // Shorter, as the dock rides up on the keyboard: covered by its width,
    // the picture keeps its scale and only crops more of the sky.
    await pumpAt(tester, const Size(390, 700), const SizedBox());
    await pumpAt(tester, const Size(390, 520), scene());
    expect(showingImage(), isTrue);

    // Whereas a stretched picture really does need a new image at a new
    // height: the check above is not passing by accident.
    await pumpAt(tester, const Size(390, 520), const SizedBox());
    await pumpAt(tester, const Size(390, 520),
        RasterizedSvg.asset(room, fit: BoxFit.fill));
    expect(showingImage(), isFalse);
  });
}
