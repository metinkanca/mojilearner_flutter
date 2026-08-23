import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/navigation_wrapper.dart';
import 'package:mojilearner_flutter/utils/fonts.dart';

/// A pixel face only renders cleanly at the size it was drawn for, and both
/// bundled East Asian faces are drawn on a 12px em: Ark Pixel 12px for CJK,
/// Galmuri11 for Hangul.
///
/// 12px is also the only size Ark has drawn CJK at in bulk — 18,299
/// ideographs, against 1,076 at 10px and 97 at 16px — so it is the size that
/// decides whether the app's Japanese and Chinese are pixels at all.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> loadFont(String family, String path) async {
    await (FontLoader(family)
          ..addFont(rootBundle.load(path).then((d) => d.buffer.asByteData())))
        .load();
  }

  tearDown(() => AppFonts.setAppLocale(const Locale('en')));

  group('size floor', () {
    test('East Asian text is never drawn below the design size', () {
      for (final code in ['ja', 'ko', 'zh']) {
        final locale = Locale(code);
        for (final size in [7.0, 8.0, 9.5, 11.9]) {
          expect(AppFonts.cjkAwareFontSize(size, locale),
              AppFonts.cjkSmallFontSize,
              reason: '$code at $size');
        }
      }
    });

    test('sizes at or above the floor are left alone', () {
      const locale = Locale('ja');
      expect(AppFonts.cjkAwareFontSize(12, locale), 12);
      expect(AppFonts.cjkAwareFontSize(16, locale), 16);
      expect(AppFonts.cjkAwareFontSize(null, locale), isNull);
    });

    // Press Start 2P is drawn for 8px, so Latin must keep its own size —
    // bumping it would push it off its pixel grid for no benefit.
    test('Latin scripts keep the size they asked for', () {
      expect(AppFonts.cjkAwareFontSize(8, const Locale('en')), 8);
      expect(AppFonts.cjkAwareFontSize(7, const Locale('tr')), 7);
    });

    test('the style carries the floored size', () {
      final style =
          AppFonts.pressStart2p(fontSize: 8, locale: const Locale('ja'));
      expect(style.fontSize, AppFonts.cjkSmallFontSize);
    });

    // 8 is the app's commonest small size; scaled it lands at 10, two points
    // under the grid, and the floor carries it the rest of the way. 10 scales
    // to 12.5, which is already there.
    test('the scale and the floor agree on the sizes the app actually uses',
        () {
      const ja = Locale('ja');
      expect(AppFonts.pressStart2p(fontSize: 8, locale: ja).fontSize, 12);
      expect(AppFonts.pressStart2p(fontSize: 10, locale: ja).fontSize, 12.5);
      expect(AppFonts.pressStart2p(fontSize: 12, locale: ja).fontSize, 15);
    });
  });

  group('face selection', () {
    String? firstArkFamily(double size, Locale locale) {
      final style = AppFonts.pressStart2p(fontSize: size, locale: locale);
      return style.fontFamilyFallback
          ?.firstWhere((f) => f.startsWith('ArkPixel'), orElse: () => '');
    }

    // One face per script, at every size. The cuts that used to be chosen by
    // size were different design sizes of the same family, and picking the
    // larger one is what sent most kanji to the platform's smooth Noto.
    test('one face leads at every size', () {
      for (final size in [8.0, 10.0, 12.0, 16.0, 22.0]) {
        expect(firstArkFamily(size, const Locale('ja')), 'ArkPixelJa',
            reason: 'ja at $size');
      }
    });

    test('Chinese gets the cut for its region, either script', () {
      expect(firstArkFamily(8, const Locale('zh', 'TW')), 'ArkPixelZhTw');
      expect(firstArkFamily(8, const Locale('zh', 'HK')), 'ArkPixelZhTw');
      expect(firstArkFamily(8, const Locale('zh', 'CN')), 'ArkPixelZhCn');
      expect(
          firstArkFamily(
              8,
              const Locale.fromSubtags(
                  languageCode: 'zh', scriptCode: 'Hant')),
          'ArkPixelZhTw');
      expect(firstArkFamily(8, const Locale('zh')), 'ArkPixelZhCn');
    });

    // Ark Pixel has no Hangul at any size — which is why Korean used to
    // arrive smooth however the faces were ordered.
    test('Korean leads with the Hangul face, hanja behind it', () {
      final families =
          AppFonts.pressStart2p(fontSize: 10, locale: const Locale('ko'))
              .fontFamilyFallback!;
      expect(families.first, 'GalmuriKo');
      expect(families, contains('ArkPixelZhTw'));
    });
  });

  // The bigger size is only an improvement if the labels still fit their slot;
  // an overflowing label gets scaled back down by the nav bar's FittedBox,
  // which would put it right back off the pixel grid.
  testWidgets('the longest nav label still fits its slot in every CJK locale',
      (tester) async {
    await loadFont('PressStart2P', 'assets/fonts/PressStart2P-Regular.ttf');
    await loadFont(
        'ArkPixelJa', 'assets/fonts/ark/ark-pixel-12px-proportional-ja.ttf');
    await loadFont('ArkPixelZhCn',
        'assets/fonts/ark/ark-pixel-12px-proportional-zh_cn.ttf');
    await loadFont('GalmuriKo', 'assets/fonts/galmuri/Galmuri11-Bold.ttf');

    const longest = {'ja': 'プロフィール', 'ko': '프로필', 'zh': '个人资料'};

    for (final entry in longest.entries) {
      final locale = Locale(entry.key);
      AppFonts.setAppLocale(locale);
      final painter = TextPainter(
        text: TextSpan(
          text: entry.value,
          style: AppFonts.pressStart2p(fontSize: 8, locale: locale),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      expect(painter.width, lessThanOrEqualTo(navLabelSlotWidth),
          reason: '${entry.key}: "${entry.value}" must fit without shrinking');
    }
  });
}
