import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// One captured frame, readable a pixel at a time.
class SceneFrame {
  SceneFrame(this.width, this.rgba, this.png);

  final int width;
  final ByteData rgba;
  final Uint8List png;

  Color at(Offset p) {
    final i = (p.dy.round() * width + p.dx.round()) * 4;
    return Color.fromARGB(
      rgba.getUint8(i + 3),
      rgba.getUint8(i),
      rgba.getUint8(i + 1),
      rgba.getUint8(i + 2),
    );
  }
}

/// Pumps [child] at exactly [size] and returns the frame once [ready] says the
/// picture has arrived.
///
/// A scene picture is read from the bundle and parsed on the real clock, which
/// FakeAsync never advances, so this polls on it rather than guessing a delay:
/// a fixed wait passed on a warm cache and failed on a cold one.
Future<SceneFrame> captureScene(
  WidgetTester tester,
  Widget child,
  Size size, {
  required String asset,
  required bool Function(SceneFrame) ready,
}) async {
  // The test window is 800x600 and clamps anything bigger, which would crop
  // the picture differently from the layout being checked.
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  // Read the asset on the real clock first. The backdrop reads it from inside
  // the fake-async zone, where a read the bundle has already cached from an
  // earlier test never resumes.
  await tester.runAsync(() => rootBundle.loadString(asset));

  final key = GlobalKey();
  await tester.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    // Align loosens the surface's tight constraints, or the box below would be
    // stretched to the whole test window.
    child: Align(
      alignment: Alignment.topLeft,
      child: RepaintBoundary(
        key: key,
        child: SizedBox.fromSize(size: size, child: child),
      ),
    ),
  ));

  Future<SceneFrame> grab() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final rgba = (await image.toByteData())!;
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    final frame = SceneFrame(image.width, rgba, png.buffer.asUint8List());
    image.dispose();
    return frame;
  }

  SceneFrame? frame;
  for (var i = 0; i < 60 && (frame == null || !ready(frame)); i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    frame = await tester.runAsync(grab);
  }
  expect(ready(frame!), isTrue, reason: 'the picture never arrived');
  return frame;
}

/// Writes [frame] as `<dir>/<name>.png` when [dir] is set; a no-op otherwise.
void saveShot(String dir, String name, SceneFrame frame) {
  if (dir.isEmpty) return;
  Directory(dir).createSync(recursive: true);
  File('$dir/$name.png').writeAsBytesSync(frame.png);
}
