import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Font utilities that prioritize bundled local fonts
class AppFonts {
  static Locale? _appLocale;

  static const String _pixelAeArabicFamily = 'PixelAEArabic';
  static const String _arkPixelJaFamily = 'ArkPixelJa';
  static const String _arkPixelKoFamily = 'ArkPixelKo';
  static const String _arkPixelZhCnFamily = 'ArkPixelZhCn';
  static const String _arkPixelZhHkFamily = 'ArkPixelZhHk';
  static const String _arkPixelZhTwFamily = 'ArkPixelZhTw';
  static const String _arkPixelZhTrFamily = 'ArkPixelZhTr';

  // Ark Pixel draws one face per design size, and a pixel face only renders
  // cleanly at the size it was drawn for. The 16px face at nav-bar sizes was
  // losing whole rows of pixels, which is what turned kana and kanji into
  // smudges. Small text uses the 10px face instead -- the smallest size the
  // family offers -- and is never drawn below that size.
  static const double cjkSmallFontSize = 10.0;

  /// Sizes below this use the 10px faces; at or above it, the 16px faces.
  static const double _arkSmallFaceCutoff = 12.0;

  static const String _arkPixelJa10Family = 'ArkPixelJa10';
  static const String _arkPixelKo10Family = 'ArkPixelKo10';
  static const String _arkPixelZhCn10Family = 'ArkPixelZhCn10';
  static const String _arkPixelZhHk10Family = 'ArkPixelZhHk10';
  static const String _arkPixelZhTw10Family = 'ArkPixelZhTw10';
  static const String _arkPixelZhTr10Family = 'ArkPixelZhTr10';

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

  static List<String> _chineseArkFamiliesForLocale(Locale locale,
      {required bool small}) {
    final country = locale.countryCode?.toUpperCase();
    final script = locale.scriptCode?.toLowerCase();

    final region = switch (country) {
      'TW' => 'tw',
      'HK' || 'MO' => 'hk',
      'CN' || 'SG' => 'cn',
      _ => switch (script) {
          'hant' => 'tr',
          'hans' => 'cn',
          _ => 'cn',
        },
    };

    final tw = small ? _arkPixelZhTw10Family : _arkPixelZhTwFamily;
    final hk = small ? _arkPixelZhHk10Family : _arkPixelZhHkFamily;
    final cn = small ? _arkPixelZhCn10Family : _arkPixelZhCnFamily;
    final tr = small ? _arkPixelZhTr10Family : _arkPixelZhTrFamily;

    final primaryFamily = switch (region) {
      'tw' => tw,
      'hk' => hk,
      'tr' => tr,
      _ => cn,
    };

    // The other regional cuts follow as fallbacks, then the CJK neighbours:
    // between them they cover any character the primary cut is missing.
    return <String>{
      primaryFamily,
      tr,
      tw,
      hk,
      cn,
      small ? _arkPixelJa10Family : _arkPixelJaFamily,
      small ? _arkPixelKo10Family : _arkPixelKoFamily,
    }.toList();
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
    // Which Ark Pixel face to reach for, by the size it will be drawn at.
    final small = (fontSize ?? cjkSmallFontSize) < _arkSmallFaceCutoff;

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
          small ? _arkPixelJa10Family : _arkPixelJaFamily,
          ..._sraPixelFamilies,
          'Noto Sans JP',
          'Noto Sans SC',
          'Noto Sans',
          'sans-serif',
        ];
      case 'ko':
        return [
          small ? _arkPixelKo10Family : _arkPixelKoFamily,
          ..._sraPixelFamilies,
          'Noto Sans KR',
          'Noto Sans',
          'sans-serif',
        ];
      case 'zh':
        return [
          ..._chineseArkFamiliesForLocale(resolvedLocale, small: small),
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
    final size = cjkAwareFontSize(fontSize, locale);
    final pixelFallbackFamilies = _pixelFallbackFamiliesForLocale(locale, size);
    try {
      // Try using the local bundled font first
      return TextStyle(
        fontFamily: 'PressStart2P',
        fontSize: size,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
        shadows: shadows,
        fontFamilyFallback: pixelFallbackFamilies,
      );
    } catch (e) {
      // Fallback to google_fonts (requires internet on first use)
      return GoogleFonts.pressStart2p(
        fontSize: size,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
      ).copyWith(
        shadows: shadows,
        fontFamilyFallback: pixelFallbackFamilies,
      );
    }
  }

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
