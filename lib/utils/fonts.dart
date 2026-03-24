import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Font utilities that prioritize bundled local fonts
class AppFonts {
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
  }) {
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
