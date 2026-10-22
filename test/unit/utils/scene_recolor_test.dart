import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/utils/scene_recolor.dart';

void main() {
  const svg = '<svg><path fill="#14120e"/><path fill="#c58c56"/>'
      '<path fill="#a8dcef"/></svg>';

  const dusk = SceneTint(
    lightness: 0.9,
    towards: Color(0xFFE0663F),
    towardsAmount: 0.25,
  );

  test('a tint with nothing to do hands the document back untouched', () {
    expect(recolorSceneSvg(svg, SceneTint.none), svg);
  });

  test('every fill is pushed toward the tint', () {
    final out = recolorSceneSvg(svg, dusk);
    expect(out, isNot(contains('fill="#14120e"')));
    expect(out, isNot(contains('fill="#c58c56"')));
  });

  // Black pushed toward dusk-orange is brown. A drawing whose lines change
  // colour with the clock has stopped being the same drawing, so the outline
  // is named and left alone.
  test('a kept fill is left exactly as drawn', () {
    final out = recolorSceneSvg(
      svg,
      const SceneTint(
        lightness: 0.9,
        towards: Color(0xFFE0663F),
        towardsAmount: 0.25,
        keep: {0x14120E},
      ),
    );
    expect(out, contains('fill="#14120e"'));
    // ...and only that one: the rest still go the way of the tint.
    expect(out, isNot(contains('fill="#c58c56"')));
    expect(out, isNot(contains('fill="#a8dcef"')));
  });

  test('a light is replaced outright, and wins over the tint', () {
    final out = recolorSceneSvg(
      svg,
      const SceneTint(lightness: 0.5, lights: {0xA8DCEF: 0xF2B36E}),
    );
    expect(out, contains('fill="#f2b36e"'));
  });

  test('keeping a fill does not make a tint do anything on its own', () {
    const onlyKeeps = SceneTint(keep: {0x14120E});
    expect(onlyKeeps.isIdentity, isTrue);
    expect(recolorSceneSvg(svg, onlyKeeps), svg);
  });

  group('a glow', () {
    const lamp = SceneGlow(
      color: 0xFF9AA0,
      under: 0xC58C56,
      halos: [SceneHalo(50, 50, 20, 10)],
    );
    const night = SceneTint(lightness: 0.5, keep: {0x14120E}, glow: lamp);

    test('is a tint on its own', () {
      expect(const SceneTint(glow: lamp).isIdentity, isFalse);
    });

    // The sky is before the layer and gets lit; the object and the outline are
    // after it and cover the light. That is what keeps the outline black.
    test('sits behind the layer it names, and in front of what precedes it', () {
      final out = recolorSceneSvg(svg, night);
      // The outline comes first in this picture, so the light is painted over
      // it; the two layers from the named one on are painted over the light.
      expect(out, startsWith('<svg><path fill="#14120e"/><path fill="#ff9aa0"'));
      final lastHalo = out.lastIndexOf('<path fill="#ff9aa0"');
      final after = out.substring(out.indexOf('/>', lastHalo) + 2);
      expect(RegExp(r'<path fill="#[0-9a-f]{6}"/>').allMatches(after),
          hasLength(2));
    });

    test('is not recoloured by the tint around it', () {
      final out = recolorSceneSvg(svg, night);
      expect(out, contains('fill="#ff9aa0"'));
    });

    test('leaves the rest of the picture exactly as the tint alone would', () {
      final withGlow = recolorSceneSvg(svg, night);
      final without =
          recolorSceneSvg(svg, const SceneTint(lightness: 0.5, keep: {0x14120E}));
      expect(withGlow.replaceAll(RegExp(r'<path fill="#ff9aa0"[^>]*/>'), ''),
          without);
    });

    test('is dropped, not mangled, when the art has no such layer', () {
      const lost = SceneGlow(
        color: 0xFF9AA0,
        under: 0x123456,
        halos: [SceneHalo(50, 50, 20, 10)],
      );
      final out = recolorSceneSvg(
          svg, const SceneTint(lightness: 0.5, keep: {0x14120E}, glow: lost));
      expect(out, isNot(contains('ff9aa0')));
    });

    test('is drawn in rows of the picture\'s own pixels', () {
      final d = RegExp(r' d="([^"]*)"').firstMatch(lamp.markup)![1]!;
      // Every row starts on the 2px grid, is 2 high, and ends on it.
      final rows = RegExp(r'M(-?\d+) (-?\d+)h(\d+)v2h-\3z').allMatches(d);
      expect(rows, isNotEmpty);
      for (final row in rows) {
        expect(int.parse(row[1]!) % 2, 0);
        expect(int.parse(row[2]!) % 2, 0);
        expect(int.parse(row[3]!) % 2, 0);
      }
      // ...and nothing else is in the path, so no row is mis-formed.
      expect(rows.map((m) => m[0]!.length).reduce((a, b) => a + b), d.length);
    });

    test('stays inside its radii and is widest across the middle', () {
      final d = RegExp(r' d="([^"]*)"').firstMatch(lamp.markup)![1]!;
      final rows = RegExp(r'M(-?\d+) (-?\d+)h(\d+)v2').allMatches(d).toList();
      var left = 1 << 30, right = -1, top = 1 << 30, bottom = -1;
      var widest = 0, widestNearMiddle = 0;
      for (final row in rows) {
        final x = int.parse(row[1]!), y = int.parse(row[2]!);
        final w = int.parse(row[3]!);
        left = left < x ? left : x;
        right = right > x + w ? right : x + w;
        top = top < y ? top : y;
        bottom = bottom > y + 2 ? bottom : y + 2;
        if (w > widest) widest = w;
        if ((y - 50).abs() <= 2 && w > widestNearMiddle) widestNearMiddle = w;
      }
      expect(left, greaterThanOrEqualTo(50 - 20 - 2));
      expect(right, lessThanOrEqualTo(50 + 20 + 2));
      expect(top, greaterThanOrEqualTo(50 - 10 - 2));
      expect(bottom, lessThanOrEqualTo(50 + 10 + 2));
      // Snapping to the grid makes several rows equally wide, so ask whether
      // the middle is among them rather than which one comes first.
      expect(widestNearMiddle, widest);
    });
  });
}
