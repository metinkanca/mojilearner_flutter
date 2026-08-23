import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Font utilities that prioritize bundled local fonts
class AppFonts {
  static Locale? _appLocale;

  static const String _pixelAeArabicFamily = 'PixelAEArabic';
  static const String _arkPixelJaFamily = 'ArkPixelJa';
  static const String _arkPixelZhCnFamily = 'ArkPixelZhCn';
  static const String _arkPixelZhTwFamily = 'ArkPixelZhTw';
  static const String _galmuriKoFamily = 'GalmuriKo';

  /// The size CJK and Hangul are never drawn below.
  ///
  /// A pixel face only renders cleanly at the size it was drawn for, and both
  /// bundled East Asian faces — Ark Pixel 12px and Galmuri11 — are drawn on a
  /// 12px em. Below this they lose whole rows, which is what turns a kanji
  /// into a smudge. It is also close to what the optical scale asks for
  /// anyway: the app's commonest small size, 8, scales to 10 and is raised the
  /// last two points to land on the grid, and its next size, 10, scales to
  /// 12.5 and is already there.
  static const double cjkSmallFontSize = 12.0;

  /// Scripts held to [cjkSmallFontSize] — the ones the 12px faces draw.
  static const Set<String> _cjkLanguageCodes = {'ja', 'ko', 'zh'};

  // SRA pixel families are used first for selected non-Latin locales.
  static const List<String> _sraPixelFamilies = [
    'SraPixelMiddle',
    'SraPixelSmall',
    'SraPixelHigh',
  ];

  // Keep retro pixel styling while guaranteeing glyph fallback for non-Latin scripts.
  static const List<String> universalFallbackFamilies = [
    'Noto Sans',
    'Noto Sans Arabic',
    'Noto Sans JP',
    'Noto Sans KR',
    'Noto Sans SC',
    'Noto Sans Devanagari',
    'Noto Sans Thai',
    'sans-serif',
  ];

  static void setAppLocale(Locale locale) {
    _appLocale = locale;
  }

  /// The Chinese cuts, the one matching the reader's region first.
  ///
  /// Upstream draws six regional cuts; two are bundled. They differ in the
  /// shape of shared characters, not in which characters exist, so Simplified
  /// readers get zh_cn and every Traditional region — Taiwan, Hong Kong,
  /// Macau — gets zh_tw rather than three near-identical megabytes.
  static List<String> _chineseArkFamiliesForLocale(Locale locale) {
    final country = locale.countryCode?.toUpperCase();
    final script = locale.scriptCode?.toLowerCase();

    final traditional = switch (country) {
      'TW' || 'HK' || 'MO' => true,
      'CN' || 'SG' => false,
      _ => script == 'hant',
    };

    // The other cut follows as a fallback, then Japanese: between them they
    // cover characters the primary cut is missing.
    return traditional
        ? const [_arkPixelZhTwFamily, _arkPixelZhCnFamily, _arkPixelJaFamily]
        : const [_arkPixelZhCnFamily, _arkPixelZhTwFamily, _arkPixelJaFamily];
  }

  static Locale _resolveLocale([Locale? locale]) =>
      locale ?? _appLocale ?? WidgetsBinding.instance.platformDispatcher.locale;

  static bool _isCjk(Locale locale) =>
      _cjkLanguageCodes.contains(locale.languageCode.toLowerCase());

  /// The size text is actually drawn at. CJK scripts are never drawn below
  /// [cjkSmallFontSize]: the Latin pixel face is drawn for 8px, but a kanji
  /// needs more rows than that to stay a kanji.
  static double? cjkAwareFontSize(double? fontSize, [Locale? locale]) {
    if (fontSize == null || fontSize >= cjkSmallFontSize) return fontSize;
    return _isCjk(_resolveLocale(locale)) ? cjkSmallFontSize : fontSize;
  }

  static List<String> _pixelFallbackFamiliesForLocale([Locale? locale,
      double? fontSize]) {
    final resolvedLocale = _resolveLocale(locale);
    final code = resolvedLocale.languageCode.toLowerCase();

    switch (code) {
      case 'ar':
        return [
          _pixelAeArabicFamily,
          ..._sraPixelFamilies,
          'Noto Sans Arabic',
          'Noto Sans',
          'sans-serif',
        ];
      case 'hi':
        return [
          ..._sraPixelFamilies,
          'Noto Sans Devanagari',
          'Noto Sans',
          'sans-serif',
        ];
      case 'th':
        return [
          ..._sraPixelFamilies,
          'Noto Sans Thai',
          'Noto Sans',
          'sans-serif',
        ];
      case 'tr':
        return [
          'Noto Sans',
          ..._sraPixelFamilies,
          'sans-serif',
        ];
      case 'ja':
        return [
          _arkPixelJaFamily,
          _arkPixelZhCnFamily,
          _arkPixelZhTwFamily,
          ..._sraPixelFamilies,
          'Noto Sans JP',
          'Noto Sans SC',
          'Noto Sans',
          'sans-serif',
        ];
      case 'ko':
        return [
          // Galmuri carries the Hangul; the Ark cuts behind it carry the
          // hanja that Korean text occasionally reaches for.
          _galmuriKoFamily,
          _arkPixelZhTwFamily,
          _arkPixelJaFamily,
          ..._sraPixelFamilies,
          'Noto Sans KR',
          'Noto Sans',
          'sans-serif',
        ];
      case 'zh':
        return [
          ..._chineseArkFamiliesForLocale(resolvedLocale),
          ..._sraPixelFamilies,
          'Noto Sans SC',
          'Noto Sans JP',
          'Noto Sans KR',
          'Noto Sans',
          'sans-serif',
        ];
      default:
        return universalFallbackFamilies;
    }
  }

  /// Returns Press Start 2P font style (bundled locally, no internet needed)
  /// Falls back to google_fonts if local font fails to load
  static TextStyle pressStart2p({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    TextDecoration? decoration,
    double? letterSpacing,
    FontStyle? fontStyle,
    List<Shadow>? shadows,
    Locale? locale,
  }) {
    // Every script is drawn at the size that gives it the same weight as the
    // Latin pixel face, not at the size the caller nominally asked for. The
    // floor is applied after the scale, so a size that was already being
    // raised to the 10px face is not raised twice.
    final size = fontSize == null
        ? null
        : cjkAwareFontSize(fontSize * scriptScale(locale), locale);
    final pixelFallbackFamilies = _pixelFallbackFamiliesForLocale(locale, size);
    final weight = fontWeight ?? scriptWeight(locale);
    // The offset copy goes last so it sits above any drop shadow the caller
    // asked for, directly under the glyph it is thickening.
    final allShadows = color != null && usesOffsetBold(locale)
        ? [...?shadows, Shadow(offset: const Offset(1, 0), color: color)]
        : shadows;
    try {
      // Try using the local bundled font first
      return TextStyle(
        fontFamily: 'PressStart2P',
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        decoration: decoration,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
        shadows: allShadows,
        fontFamilyFallback: pixelFallbackFamilies,
      );
    } catch (e) {
      // Fallback to google_fonts (requires internet on first use)
      return GoogleFonts.pressStart2p(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        decoration: decoration,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
      ).copyWith(
        shadows: allShadows,
        fontFamilyFallback: pixelFallbackFamilies,
      );
    }
  }

  /// Scripts a bundled pixel face does draw, but only as hairlines.
  ///
  /// Ark Pixel draws CJK on a 10px grid and PixelAE draws Arabic on the same,
  /// so their strokes are one pixel wide. Press Start 2P is drawn for 8px, so
  /// at the same font size its strokes are 1.25px. The ink heights match
  /// almost exactly — 0.9em against 0.875em — which is why the difference
  /// reads as size when it is really weight.
  static const Set<String> _hairlinePixelScripts = {'ja', 'zh', 'ar'};

  /// Korean, whose bundled face is already a designed bold.
  ///
  /// Galmuri ships a drawn bold cut, and that is the one bundled: a real pixel
  /// bold beats both a synthetic one and an offset copy. So Hangul takes the
  /// size scale and nothing else.
  static const Set<String> _boldPixelScripts = {'ko'};

  /// Scripts no bundled face covers at all.
  ///
  /// There is not one Devanagari letter or Thai character in any of them, so
  /// these fall through to the platform's Noto and arrive smooth and light
  /// beside blocky Latin. A real [FontWeight.w700] is available there.
  static const Set<String> _unservedScripts = {'hi', 'th'};

  /// How much larger a non-Latin script is drawn to carry the same weight as
  /// Latin at the same nominal size.
  ///
  /// A quarter, which is also the ratio between the pixel grids: it puts an
  /// Ark design pixel at 1.25 device pixels, exactly where Press Start 2P's
  /// already sits. Dense scripts need the extra rows anyway — a kanji has
  /// five strokes where a Latin capital has two.
  ///
  /// Latin, Greek and Cyrillic are all drawn by Press Start 2P itself, so
  /// they are already the weight everything else is matched to and scale by 1.
  static const double nonLatinOpticalScale = 1.25;

  /// The optical scale for [locale]'s script.
  static double scriptScale([Locale? locale]) {
    final code = _resolveLocale(locale).languageCode.toLowerCase();
    return _hairlinePixelScripts.contains(code) ||
            _boldPixelScripts.contains(code) ||
            _unservedScripts.contains(code)
        ? nonLatinOpticalScale
        : 1.0;
  }

  /// Whether [locale]'s script is thickened with an offset copy of itself.
  ///
  /// A pixel face has no bold cut, and emboldening one synthetically smears it
  /// off the grid. A hard copy of the glyph one pixel over is how bitmap fonts
  /// have always been thickened: at these sizes the offset is one design
  /// pixel, so the result is still square. Scripts that arrive from the
  /// platform's Noto get a real [FontWeight.w700] instead — see
  /// [scriptWeight].
  static bool usesOffsetBold([Locale? locale]) => _hairlinePixelScripts
      .contains(_resolveLocale(locale).languageCode.toLowerCase());

  /// The weight [locale]'s script is drawn at when the caller asks for none.
  static FontWeight? scriptWeight([Locale? locale]) =>
      _unservedScripts.contains(
              _resolveLocale(locale).languageCode.toLowerCase())
          ? FontWeight.w700
          : null;

  /// Returns Space Mono font style (alternative to pixel font)
  static TextStyle spaceMono({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    TextDecoration? decoration,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) {
    return GoogleFonts.spaceMono(
      fontSize: cjkAwareFontSize(fontSize),
      fontWeight: fontWeight,
      color: color,
      height: height,
      decoration: decoration,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    ).copyWith(
      fontFamilyFallback: universalFallbackFamilies,
    );
  }

  /// Returns the appropriate font based on pixel font setting
  static TextStyle Function({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    TextDecoration? decoration,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) getFont(bool usePixelFont) {
    return usePixelFont ? pressStart2p : spaceMono;
  }
}
