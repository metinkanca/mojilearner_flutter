import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/utils/fonts.dart';

/// Ark Pixel draws one face per design size, and a pixel face only renders
/// cleanly at the size it was drawn for. The 16px face at nav-bar sizes was
/// dropping whole rows of pixels, which is what made Japanese unreadable.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> loadFont(String family, String path) async {
    await (FontLoader(family)
          ..addFont(rootBundle.load(path).then((d) => d.buffer.asByteData())))
        .load();
  }

  tearDown(() => AppFonts.setAppLocale(const Locale('en')));

  group('size floor', () {
    test('CJK text is never drawn below the 10px face size', () {
      for (final code in ['ja', 'ko', 'zh']) {
        final locale = Locale(code);
        expect(AppFonts.cjkAwareFontSize(7, locale), AppFonts.cjkSmallFontSize);
        expect(AppFonts.cjkAwareFontSize(8, locale), AppFonts.cjkSmallFontSize);
        expect(AppFonts.cjkAwareFontSize(9.5, locale), AppFonts.cjkSmallFontSize);
      }
    });

    test('sizes at or above the floor are left alone', () {
      const locale = Locale('ja');
      expect(AppFonts.cjkAwareFontSize(10, locale), 10);
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
      final style = AppFonts.pressStart2p(fontSize: 8, locale: const Locale('ja'));
      expect(style.fontSize, AppFonts.cjkSmallFontSize);
    });
  });

  group('face selection', () {
    String? firstArkFamily(double size, Locale locale) {
      final style = AppFonts.pressStart2p(fontSize: size, locale: locale);
      return style.fontFamilyFallback
          ?.firstWhere((f) => f.startsWith('ArkPixel'), orElse: () => '');
    }

    test('small text uses the 10px face, larger text the 16px face', () {
      expect(firstArkFamily(8, const Locale('ja')), 'ArkPixelJa10');
      expect(firstArkFamily(16, const Locale('ja')), 'ArkPixelJa');
      expect(firstArkFamily(8, const Locale('ko')), 'ArkPixelKo10');
      expect(firstArkFamily(16, const Locale('ko')), 'ArkPixelKo');
    });

    test('Chinese keeps its regional cut at either size', () {
      expect(firstArkFamily(8, const Locale('zh', 'TW')), 'ArkPixelZhTw10');
      expect(firstArkFamily(16, const Locale('zh', 'TW')), 'ArkPixelZhTw');
      expect(firstArkFamily(8, const Locale('zh', 'CN')), 'ArkPixelZhCn10');
    });
  });

  // The bigger size is only an improvement if the labels still fit their slot;
  // an overflowing label gets scaled back down by the nav bar's FittedBox,
  // which would put it right back off the pixel grid.
  testWidgets('the longest nav label still fits its slot in every CJK locale',
      (tester) async {
    await loadFont('PressStart2P', 'assets/fonts/PressStart2P-Regular.ttf');
    await loadFont(
        'ArkPixelJa10', 'assets/fonts/ark/ark-pixel-10px-proportional-ja.ttf');
    await loadFont(
        'ArkPixelKo10', 'assets/fonts/ark/ark-pixel-10px-proportional-ko.ttf');
    await loadFont('ArkPixelZhCn10',
        'assets/fonts/ark/ark-pixel-10px-proportional-zh_cn.ttf');

    /// The label box inside a nav item — see [_navItem] in navigation_wrapper.
    const slotWidth = 64.0;
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
      expect(painter.width, lessThanOrEqualTo(slotWidth),
          reason: '${entry.key}: "${entry.value}" must fit without shrinking');
    }
  });
}
