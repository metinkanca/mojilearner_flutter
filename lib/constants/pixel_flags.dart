/// Pixel-art flags, one per language the app ships.
///
/// The app is drawn in 8-bit: emoji flags were the one place a smooth,
/// vendor-drawn, differently-styled glyph sat inside a retro list — and worse,
/// they render as two letters on Windows and as three different art styles
/// across the platforms the app runs on. These are drawn instead, from data,
/// so every flag matches the rest of the UI and looks identical everywhere.
///
/// Each flag is a 12x8 grid — the 3:2 ratio most of these flags actually use —
/// of single-character palette keys. At this size a flag is an impression
/// rather than a reproduction: circles are stepped, crests and script become
/// suggestive marks. That is the style, not a shortcoming.
library;

import 'package:flutter/material.dart';

/// Cells across in every grid.
const int pixelFlagColumns = 12;

/// Cells down in every grid.
const int pixelFlagRows = 8;

/// The shared palette every flag draws from.
///
/// One palette rather than each flag's exact official colours: slightly
/// harmonised reds and blues read as a single set of icons, which is what a
/// list of them needs to look like.
const Map<String, Color> pixelFlagPalette = {
  'w': Color(0xFFFFFFFF),
  'k': Color(0xFF1B1B1B),
  'r': Color(0xFFD8232A),
  'b': Color(0xFF1D4E9B),
  'c': Color(0xFF2C74C9),
  'n': Color(0xFF10265A),
  'y': Color(0xFFF5C518),
  'g': Color(0xFF1E9E52),
  'o': Color(0xFFF5872B),
};

/// Drawn when a language has no flag of its own — a neutral plate rather than
/// a gap, so a row with an unknown code still lines up with its neighbours.
const List<String> pixelFlagFallback = [
  'wwwwwwwwwwww',
  'wwwwkkkkwwww',
  'wwwkwwwwkwww',
  'wwwwwwwkwwww',
  'wwwwwwkwwwww',
  'wwwwwwkwwwww',
  'wwwwwwwwwwww',
  'wwwwwwkwwwww',
];

/// Flag art by language code, matching `LanguageProvider.availableLanguages`.
const Map<String, List<String>> pixelFlags = {
  // English — the Union Jack, the icon language pickers conventionally use
  // for "English". The saltires are too fine to survive 12x8, so what
  // survives is the cross and the diagonal corners.
  'en': [
    'wwbbwrrwbbww',
    'bwwbwrrwbwwb',
    'wwwwwrrwwwww',
    'rrrrrrrrrrrr',
    'rrrrrrrrrrrr',
    'wwwwwrrwwwww',
    'bwwbwrrwbwwb',
    'wwbbwrrwbbww',
  ],
  'es': [
    'rrrrrrrrrrrr',
    'rrrrrrrrrrrr',
    'yyyyyyyyyyyy',
    'yyyyyyyyyyyy',
    'yyyyyyyyyyyy',
    'yyyyyyyyyyyy',
    'rrrrrrrrrrrr',
    'rrrrrrrrrrrr',
  ],
  'fr': [
    'bbbbwwwwrrrr',
    'bbbbwwwwrrrr',
    'bbbbwwwwrrrr',
    'bbbbwwwwrrrr',
    'bbbbwwwwrrrr',
    'bbbbwwwwrrrr',
    'bbbbwwwwrrrr',
    'bbbbwwwwrrrr',
  ],
  // Horizontal tricolours get a 3/2/3 split. Eight rows cannot be thirds, and
  // a symmetric flag beats an evenly-banded one that leans.
  'de': [
    'kkkkkkkkkkkk',
    'kkkkkkkkkkkk',
    'kkkkkkkkkkkk',
    'rrrrrrrrrrrr',
    'rrrrrrrrrrrr',
    'yyyyyyyyyyyy',
    'yyyyyyyyyyyy',
    'yyyyyyyyyyyy',
  ],
  'it': [
    'ggggwwwwrrrr',
    'ggggwwwwrrrr',
    'ggggwwwwrrrr',
    'ggggwwwwrrrr',
    'ggggwwwwrrrr',
    'ggggwwwwrrrr',
    'ggggwwwwrrrr',
    'ggggwwwwrrrr',
  ],
  // The armillary sphere reduces to the gold mark straddling the seam.
  'pt': [
    'gggggrrrrrrr',
    'gggggrrrrrrr',
    'gggggrrrrrrr',
    'ggggyyrrrrrr',
    'ggggyyrrrrrr',
    'gggggrrrrrrr',
    'gggggrrrrrrr',
    'gggggrrrrrrr',
  ],
  'ru': [
    'wwwwwwwwwwww',
    'wwwwwwwwwwww',
    'wwwwwwwwwwww',
    'bbbbbbbbbbbb',
    'bbbbbbbbbbbb',
    'rrrrrrrrrrrr',
    'rrrrrrrrrrrr',
    'rrrrrrrrrrrr',
  ],
  'ja': [
    'wwwwwwwwwwww',
    'wwwwrrrrwwww',
    'wwwrrrrrrwww',
    'wwwrrrrrrwww',
    'wwwrrrrrrwww',
    'wwwrrrrrrwww',
    'wwwwrrrrwwww',
    'wwwwwwwwwwww',
  ],
  // One large star plus its arc of four, thinned to single pixels.
  'zh': [
    'rrrrrrrrrrrr',
    'rrrrryrrrrrr',
    'rryrrryrrrrr',
    'ryyyrrrrrrrr',
    'rryrrryrrrrr',
    'rrrrryrrrrrr',
    'rrrrrrrrrrrr',
    'rrrrrrrrrrrr',
  ],
  // The taegeuk splits on the diagonal; the trigrams become corner dashes.
  'ko': [
    'wwwwwwwwwwww',
    'wkkwwwwwwkkw',
    'wwwwwrrwwwww',
    'wwwwrrrbwwww',
    'wwwwrbbbwwww',
    'wwwwwbbwwwww',
    'wkkwwwwwwkkw',
    'wwwwwwwwwwww',
  ],
  // Arabic — the shahada and the sword as white marks on green. No script
  // survives twelve pixels, so this is the shape of the flag, not its words.
  'ar': [
    'gggggggggggg',
    'gggggggggggg',
    'gwwgwgwwgwgg',
    'gggggggggggg',
    'gwwwwwwwwwwg',
    'ggwwgggggggg',
    'gggggggggggg',
    'gggggggggggg',
  ],
  'hi': [
    'oooooooooooo',
    'oooooooooooo',
    'oooooooooooo',
    'wwwwwnnwwwww',
    'wwwwwnnwwwww',
    'gggggggggggg',
    'gggggggggggg',
    'gggggggggggg',
  ],
  'tr': [
    'rrrrrrrrrrrr',
    'rrrwwrrrrrrr',
    'rrwwrrrwrrrr',
    'rrwrrrwwwrrr',
    'rrwrrrrwrrrr',
    'rrwwrrrrrrrr',
    'rrrwwrrrrrrr',
    'rrrrrrrrrrrr',
  ],
  'nl': [
    'rrrrrrrrrrrr',
    'rrrrrrrrrrrr',
    'rrrrrrrrrrrr',
    'wwwwwwwwwwww',
    'wwwwwwwwwwww',
    'bbbbbbbbbbbb',
    'bbbbbbbbbbbb',
    'bbbbbbbbbbbb',
  ],
  // The Nordic cross sits off-centre towards the hoist, as it does at full
  // size: vertical bar on columns 3-4, horizontal on rows 3-4.
  'sv': [
    'cccyyccccccc',
    'cccyyccccccc',
    'cccyyccccccc',
    'yyyyyyyyyyyy',
    'yyyyyyyyyyyy',
    'cccyyccccccc',
    'cccyyccccccc',
    'cccyyccccccc',
  ],
  'pl': [
    'wwwwwwwwwwww',
    'wwwwwwwwwwww',
    'wwwwwwwwwwww',
    'wwwwwwwwwwww',
    'rrrrrrrrrrrr',
    'rrrrrrrrrrrr',
    'rrrrrrrrrrrr',
    'rrrrrrrrrrrr',
  ],
  'id': [
    'rrrrrrrrrrrr',
    'rrrrrrrrrrrr',
    'rrrrrrrrrrrr',
    'rrrrrrrrrrrr',
    'wwwwwwwwwwww',
    'wwwwwwwwwwww',
    'wwwwwwwwwwww',
    'wwwwwwwwwwww',
  ],
  'vi': [
    'rrrrrrrrrrrr',
    'rrrrryyrrrrr',
    'rrrryyyyrrrr',
    'ryyyyyyyyyyr',
    'rrryyyyyyrrr',
    'rryyyrryyyrr',
    'rryrrrrrryrr',
    'rrrrrrrrrrrr',
  ],
  'th': [
    'rrrrrrrrrrrr',
    'rrrrrrrrrrrr',
    'wwwwwwwwwwww',
    'nnnnnnnnnnnn',
    'nnnnnnnnnnnn',
    'wwwwwwwwwwww',
    'rrrrrrrrrrrr',
    'rrrrrrrrrrrr',
  ],
  // Nine stripes will not fit in eight rows, so the canton and the
  // alternation carry the flag.
  'el': [
    'ccwccccccccc',
    'ccwccwwwwwww',
    'wwwwwccccccc',
    'ccwccwwwwwww',
    'ccwccccccccc',
    'wwwwwwwwwwww',
    'cccccccccccc',
    'wwwwwwwwwwww',
  ],
  'uk': [
    'cccccccccccc',
    'cccccccccccc',
    'cccccccccccc',
    'cccccccccccc',
    'yyyyyyyyyyyy',
    'yyyyyyyyyyyy',
    'yyyyyyyyyyyy',
    'yyyyyyyyyyyy',
  ],
  'da': [
    'rrrwwrrrrrrr',
    'rrrwwrrrrrrr',
    'rrrwwrrrrrrr',
    'wwwwwwwwwwww',
    'wwwwwwwwwwww',
    'rrrwwrrrrrrr',
    'rrrwwrrrrrrr',
    'rrrwwrrrrrrr',
  ],
  'fi': [
    'wwwbbwwwwwww',
    'wwwbbwwwwwww',
    'wwwbbwwwwwww',
    'bbbbbbbbbbbb',
    'bbbbbbbbbbbb',
    'wwwbbwwwwwww',
    'wwwbbwwwwwww',
    'wwwbbwwwwwww',
  ],
  // Norway's cross is the only one wide enough to keep its white outline.
  'no': [
    'rrwbbwrrrrrr',
    'rrwbbwrrrrrr',
    'wwwwwwwwwwww',
    'bbbbbbbbbbbb',
    'bbbbbbbbbbbb',
    'wwwwwwwwwwww',
    'rrwbbwrrrrrr',
    'rrwbbwrrrrrr',
  ],
  'cs': [
    'bwwwwwwwwwww',
    'bbwwwwwwwwww',
    'bbbwwwwwwwww',
    'bbbbwwwwwwww',
    'bbbbrrrrrrrr',
    'bbbrrrrrrrrr',
    'bbrrrrrrrrrr',
    'brrrrrrrrrrr',
  ],
  'ro': [
    'bbbbyyyyrrrr',
    'bbbbyyyyrrrr',
    'bbbbyyyyrrrr',
    'bbbbyyyyrrrr',
    'bbbbyyyyrrrr',
    'bbbbyyyyrrrr',
    'bbbbyyyyrrrr',
    'bbbbyyyyrrrr',
  ],
  'hu': [
    'rrrrrrrrrrrr',
    'rrrrrrrrrrrr',
    'rrrrrrrrrrrr',
    'wwwwwwwwwwww',
    'wwwwwwwwwwww',
    'gggggggggggg',
    'gggggggggggg',
    'gggggggggggg',
  ],
};
