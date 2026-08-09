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

  static List<String> _chineseArkFamiliesForLocale(Locale locale) {
    final country = locale.countryCode?.toUpperCase();
    final script = locale.scriptCode?.toLowerCase();

    final primaryFamily = switch (country) {
      'TW' => _arkPixelZhTwFamily,
      'HK' || 'MO' => _arkPixelZhHkFamily,
      'CN' || 'SG' => _arkPixelZhCnFamily,
      _ => switch (script) {
          'hant' => _arkPixelZhTrFamily,
          'hans' => _arkPixelZhCnFamily,
          _ => _arkPixelZhCnFamily,
        },
    };

    return <String>{
      primaryFamily,
      _arkPixelZhTrFamily,
      _arkPixelZhTwFamily,
      _arkPixelZhHkFamily,
      _arkPixelZhCnFamily,
      _arkPixelJaFamily,
      _arkPixelKoFamily,
    }.toList();
  }

  static List<String> _pixelFallbackFamiliesForLocale([Locale? locale]) {
    final resolvedLocale =
        locale ?? _appLocale ?? WidgetsBinding.instance.platformDispatcher.locale;
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
          ..._sraPixelFamilies,
          'Noto Sans JP',
          'Noto Sans SC',
          'Noto Sans',
          'sans-serif',
        ];
      case 'ko':
        return [
          _arkPixelKoFamily,
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
    final pixelFallbackFamilies = _pixelFallbackFamiliesForLocale(locale);
    try {
      // Try using the local bundled font first
      return TextStyle(
        fontFamily: 'PressStart2P',
        fontSize: fontSize,
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
        fontSize: fontSize,
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
      fontSize: fontSize,
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
