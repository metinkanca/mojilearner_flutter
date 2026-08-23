import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/utils/pet_recolor.dart';

void main() {
  group('recolorBodyLayer', () {
    const sample =
        '<svg><path fill="#959379" d="M0,0"/><polyline fill="#959279"/>'
        '<polygon fill="#606659"/><rect fill="#1f2223"/><line fill="none"/></svg>';

    test('swaps both main coat fills for the chosen colour', () {
      final out = recolorBodyLayer(sample, '#E0883B');
      expect(out.contains('fill="#959379"'), isFalse);
      expect(out.contains('fill="#959279"'), isFalse);
      expect('fill="#E0883B"'.allMatches(out).length, 2);
    });

    test('derives a darker shade for the shading tone', () {
      final out = recolorBodyLayer(sample, '#E0883B');
      expect(out.contains('fill="#606659"'), isFalse);
      // 0x E0->~0xA1, 88->~0x61, 3B->~0x2A at factor 0.72
      expect(out.contains('fill="${darken('#E0883B', 0.72)}"'), isTrue);
    });

    test('leaves the dark outline and "none" fills untouched', () {
      final out = recolorBodyLayer(sample, '#E0883B');
      expect(out.contains('fill="#1f2223"'), isTrue);
      expect(out.contains('fill="none"'), isTrue);
    });
  });

  group('buildEyesLayer', () {
    test('solid: both eyes share colour 1, no pupils', () {
      final svg = buildEyesLayer(const PetColorSpec(
        bodyColor: '#959379',
        eyeMode: EyeMode.solid,
        eyeColor1: '#4CA65B',
        eyeColor2: '#5AA0E0',
      ));
      expect('fill="#4CA65B"'.allMatches(svg).length, 2);
      expect(svg.contains('#5AA0E0'), isFalse);
      expect(svg.startsWith('<svg'), isTrue);
      expect(svg.trim().endsWith('</svg>'), isTrue);
    });

    test('heterochromia: left uses colour 1, right uses colour 2', () {
      final svg = buildEyesLayer(const PetColorSpec(
        bodyColor: '#959379',
        eyeMode: EyeMode.heterochromia,
        eyeColor1: '#5AA0E0',
        eyeColor2: '#F4C430',
      ));
      // left eye cell x=80, right eye cell x=141
      expect(svg.contains('fill="#5AA0E0" x="80"'), isTrue);
      expect(svg.contains('fill="#F4C430" x="141"'), isTrue);
    });

    /// The bird is drawn in profile, so it has one eye cell and odd-eyed has
    /// nothing to act on. Without this, the second colour would be painted
    /// over the first at the same x.
    test('a single-eyed pet draws one cell and ignores odd-eyed', () {
      expect(kBirdEyes.isSingle, isTrue);
      expect(kCatEyes.isSingle, isFalse);

      final svg = buildEyesLayer(
        const PetColorSpec(
          bodyColor: '#959379',
          eyeMode: EyeMode.heterochromia,
          eyeColor1: '#5AA0E0',
          eyeColor2: '#F4C430',
        ),
        kBirdEyes,
      );
      expect('<rect'.allMatches(svg).length, 1);
      expect(svg.contains('fill="#5AA0E0" x="121"'), isTrue);
      expect(svg.contains('#F4C430'), isFalse);
    });
  });

  /// The rim this seals is only visible against a dark background — at night
  /// the pet wore a white outline — so nothing about it is obvious from
  /// reading the art. These hold the shape of the fix.
  group('sealOutlines', () {
    test('gives every outline piece a stroke of its own colour', () {
      const svg = '<svg><path fill="#1f2223" d="M0 0"/>'
          '<path fill="#1f2223" d="M1 1"/></svg>';

      final sealed = sealOutlines(svg);

      expect(
        'stroke="#1f2223" stroke-width="1"'.allMatches(sealed).length,
        2,
      );
    });

    test('leaves the coat alone: only the outline is widened', () {
      const svg = '<svg><path fill="#959379" d="M0 0"/>'
          '<path fill="#1f2223" d="M1 1"/></svg>';

      final sealed = sealOutlines(svg);

      expect(sealed.contains('fill="#959379" d='), isTrue);
      expect(sealed.contains('fill="#959379" stroke'), isFalse);
    });

    test('is idempotent, so a cached layer cannot be sealed twice', () {
      const svg = '<svg><path fill="#1f2223" d="M0 0"/></svg>';

      expect(sealOutlines(sealOutlines(svg)), sealOutlines(svg));
    });

    test('survives a recolour: the outline is not a coat fill', () {
      const svg = '<svg><path fill="#959379" d="M0 0"/>'
          '<path fill="#1f2223" d="M1 1"/></svg>';

      final sealed = sealOutlines(recolorBodyLayer(svg, '#E0883B'));

      expect(sealed.contains('fill="#E0883B"'), isTrue);
      expect(sealed.contains('fill="#1f2223" stroke="#1f2223"'), isTrue);
    });
  });

  group('hexToColor', () {
    test('parses a valid opaque colour', () {
      expect(hexToColor('#FF8800').toARGB32(), 0xFFFF8800);
    });

    test('falls back to grey on malformed input', () {
      expect(hexToColor('not-a-color').toARGB32(), 0xFF959379);
    });
  });
}
