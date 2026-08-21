import 'package:flutter/material.dart';

import '../../../utils/fonts.dart';

/// Text drawn in a language that is not (yet) the app's.
///
/// [AppFonts.pressStart2p] resolves its per-script fallbacks from the app's
/// own locale when it is not told otherwise. Its default list does cover every
/// script the app ships, so this is not the difference between readable and
/// tofu — but the per-locale lists reach for the matching *pixel* faces (Ark
/// Pixel for CJK, the Arabic pixel face) before falling back to Noto. Passing
/// the locale being drawn is what keeps Japanese in the opening looking like
/// the rest of the app instead of dropping to a smooth webfont.
///
/// Space Mono already carries the universal Noto fallbacks and takes no
/// locale, so it needs no such help.
TextStyle onboardingTextStyle({
  required bool usePixelFont,
  required Locale locale,
  required double fontSize,
  required Color color,
  FontWeight? fontWeight,
}) {
  return usePixelFont
      ? AppFonts.pressStart2p(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          locale: locale,
        )
      : AppFonts.spaceMono(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
        );
}
