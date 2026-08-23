import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/utils/fonts.dart';

/// Press Start 2P is drawn on an 8px grid, so at font size 10 its strokes are
/// 1.25px. Ark Pixel and PixelAE are drawn on a 10px grid, so theirs are 1px —
/// and Hangul, Devanagari and Thai have no bundled face at all and arrive
/// smooth from the platform. The ink heights nearly match already; what makes
/// a language list look like Latin shouting over everything else is weight.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const black = Color(0xFF000000);

  tearDown(() => AppFonts.setAppLocale(const Locale('en')));

  TextStyle balanced(String code, [double size = 10]) => AppFonts.pressStart2p(
        fontSize: size,
        color: black,
        locale: Locale(code),
      );

  group('scripts Press Start 2P draws itself', () {
    test('are left exactly as they were', () {
      for (final code in ['en', 'tr', 'ru', 'el', 'cs', 'vi']) {
        final style = balanced(code);
        expect(style.fontSize, 10, reason: '$code was resized');
        expect(style.shadows, isNull, reason: '$code was emboldened');
        expect(style.fontWeight, isNull, reason: '$code was weighted');
      }
    });
  });

  group('hairline pixel scripts', () {
    test('are scaled up and thickened by one pixel', () {
      for (final code in ['ja', 'zh', 'ar']) {
        final style = balanced(code);
        expect(style.fontSize, 10 * AppFonts.nonLatinOpticalScale,
            reason: '$code kept the Latin size');
        expect(style.shadows, hasLength(1), reason: '$code was not thickened');
        expect(style.shadows!.single.offset, const Offset(1, 0));
        expect(style.shadows!.single.blurRadius, 0,
            reason: 'a blurred copy would smear the pixel grid');
        expect(style.shadows!.single.color, black,
            reason: 'the copy has to be the text colour to read as weight');
      }
    });

    test('are never synthetically bolded, which smears a pixel face', () {
      expect(balanced('ja').fontWeight, isNull);
    });

    test('still respect the East Asian size floor', () {
      // The bundled faces are drawn on a 12px em; below it they lose rows.
      expect(balanced('ja', 8).fontSize, AppFonts.cjkSmallFontSize);
      expect(balanced('ja', 6).fontSize, AppFonts.cjkSmallFontSize);
      expect(balanced('ja', 10).fontSize, 12.5);
    });
  });

  group('Korean', () {
    // Galmuri ships a drawn bold cut and that is the one bundled, so Hangul
    // needs neither an offset copy nor a synthetic weight — only the size.
    test('takes the scale and nothing else', () {
      final style = balanced('ko');
      expect(style.fontSize, 10 * AppFonts.nonLatinOpticalScale);
      expect(style.shadows, isNull);
      expect(style.fontWeight, isNull);
    });
  });

  group('scripts with no bundled face', () {
    test('are scaled up and given a real bold', () {
      for (final code in ['hi', 'th']) {
        final style = balanced(code);
        expect(style.fontSize, 10 * AppFonts.nonLatinOpticalScale);
        expect(style.fontWeight, FontWeight.w700, reason: '$code stayed light');
        expect(style.shadows, isNull,
            reason: '$code has a real bold cut, so it needs no offset copy');
      }
    });
  });

  test('the scale is a quarter — the ratio between the two pixel grids', () {
    expect(AppFonts.nonLatinOpticalScale, 10 / 8);
  });

  group('applied everywhere, not only where a locale is passed', () {
    test('an unlabelled call follows the app locale', () {
      AppFonts.setAppLocale(const Locale('ja'));
      final style = AppFonts.pressStart2p(fontSize: 12, color: black);
      expect(style.fontSize, 15);
      expect(style.shadows, hasLength(1));
    });

    test('a caller-supplied shadow keeps it, with the copy on top', () {
      const drop = Shadow(offset: Offset(2, 2), color: Color(0xFF222222));
      final style = AppFonts.pressStart2p(
        fontSize: 12,
        color: black,
        locale: const Locale('ja'),
        shadows: [drop],
      );
      expect(style.shadows, hasLength(2));
      expect(style.shadows!.first, drop);
      expect(style.shadows!.last.color, black,
          reason: 'the thickening copy is painted over the drop shadow');
    });

    test('a caller-supplied weight wins over the script default', () {
      final style = AppFonts.pressStart2p(
        fontSize: 12,
        color: black,
        locale: const Locale('th'),
        fontWeight: FontWeight.w400,
      );
      expect(style.fontWeight, FontWeight.w400);
    });

    test('a style with no size is left alone', () {
      final style =
          AppFonts.pressStart2p(color: black, locale: const Locale('ja'));
      expect(style.fontSize, isNull);
    });
  });
}
