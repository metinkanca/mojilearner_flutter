import 'package:flutter/material.dart';

import '../constants/theme.dart';

/// A beach ball on the pet's pixel grid — the one thrown to the pet in Catch,
/// and Catch's toy in the toy chest.
///
/// With [withShadow], a row of shadow under it for a ball resting on the
/// ground. Without, just the ball, square: a ball in the air casts its shadow
/// somewhere else.
class BeachBallPainter extends CustomPainter {
  const BeachBallPainter({this.withShadow = true});

  final bool withShadow;

  /// 'X' outline, 'R' red, 'W' white, 'B' blue, 'h' highlight, 's' shadow.
  static const List<String> _pattern = [
    '..XXXXX..',
    '.XRRRRRX.',
    'XRhRRRRRX',
    'XRRRRRRRX',
    'XWWWWWWWX',
    'XBBBBBBBX',
    'XBBBBBBBX',
    '.XBBBBBX.',
    '..XXXXX..',
    '.sssssss.',
  ];

  static const int cols = 9;

  /// Rows of the ball alone, and with its shadow row.
  static const int rows = 9;
  static const int rowsWithShadow = 10;

  static const Map<String, Color> _inks = {
    'X': AppTheme.retroDark,
    'R': AppTheme.retroPrimary,
    'W': AppTheme.retroLight,
    'B': Color(0xFF5B6EE1),
    'h': Color(0xFFF1A7AE),
    's': Color(0x40000000),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / cols;
    final paint = Paint()..isAntiAlias = false;
    final drawn = withShadow ? rowsWithShadow : rows;
    for (var row = 0; row < drawn; row++) {
      for (var col = 0; col < _pattern[row].length; col++) {
        final ink = _inks[_pattern[row][col]];
        if (ink == null) continue;
        canvas.drawRect(
          // Overdrawn by a hair, as the pixel heart is, so cells rounded to
          // different device pixels leave no gaps.
          Rect.fromLTWH(col * cell, row * cell, cell + 0.5, cell + 0.5),
          paint..color = ink,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant BeachBallPainter oldDelegate) =>
      oldDelegate.withShadow != withShadow;
}
