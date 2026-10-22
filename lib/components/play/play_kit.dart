/// What every toy chest game shares around its own scene: the bar across the
/// top, the row of squares that keeps score, the results card, and the small
/// pixel pieces a game reacts with.
///
/// Lifted from Catch, the first of them, so five games look like one set and
/// a change to how a game ends is made once.
library;

import 'package:flutter/material.dart';

import '../../constants/theme.dart';
import '../../utils/fonts.dart';
import '../../utils/play_games.dart';
import '../pet_hearts.dart' show PixelHeartPainter;

/// The pixel font the games are drawn in, at [size], in [color] — with the
/// locale's own glyphs when [localeCode] is given, since a word in Japanese
/// drawn in the Latin face is a row of boxes.
TextStyle playPixel(double size, Color color, {String? localeCode}) =>
    AppFonts.pressStart2p(
      fontSize: size,
      color: color,
      locale: localeCode == null ? null : Locale(localeCode),
    );

/// A square pixel button carrying an icon, with a label for screen readers.
class PlaySquareButton extends StatelessWidget {
  const PlaySquareButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: AppTheme.retroDark, width: 3),
          ),
          child: Icon(icon, color: AppTheme.retroDark, size: size * 0.45),
        ),
      ),
    );
  }
}

/// A row of squares, one per round: right, not right, or still to come, with
/// the round in play outlined.
class PlayResultTrack extends StatelessWidget {
  const PlayResultTrack({
    super.key,
    required this.results,
    required this.total,
    required this.current,
    required this.pending,
  });

  /// Every round played so far: true for right.
  final List<bool> results;
  final int total;

  /// The round in play, or null once the game is over.
  final int? current;
  final Color pending;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          for (var i = 0; i < total; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  decoration: BoxDecoration(
                    color: i < results.length
                        ? (results[i]
                            ? AppTheme.retroGrass
                            : AppTheme.retroPrimary)
                        : pending,
                    border: Border.all(
                      color: i == current ? AppTheme.retroAccent : Colors.black,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The bar over a game: close, the score so far, and the streak.
class PlayHud extends StatelessWidget {
  const PlayHud({
    super.key,
    required this.results,
    required this.total,
    required this.current,
    required this.combo,
    required this.onClose,
  });

  final List<bool> results;
  final int total;
  final int? current;
  final int combo;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.retroDark,
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: Row(
        children: [
          PlaySquareButton(
            icon: Icons.close,
            label: MaterialLocalizations.of(context).closeButtonTooltip,
            color: AppTheme.retroLight,
            size: 36,
            onTap: onClose,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PlayResultTrack(
              results: results,
              total: total,
              current: current,
              pending: const Color(0xFF4E4A4E),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: Text(
              combo > 1 ? 'x$combo' : '',
              textAlign: TextAlign.end,
              textDirection: TextDirection.ltr,
              style: playPixel(10, AppTheme.retroAccent),
            ),
          ),
        ],
      ),
    );
  }
}

/// The card a game ends on: the score, its squares, what it paid, what is
/// worth practising, and the way to play again or leave.
///
/// Almost wordless, like the games: a number, a row of squares, a heart and
/// the app's own "XP" say how it went in every language the app ships.
class PlayResultsPanel extends StatelessWidget {
  const PlayResultsPanel({
    super.key,
    required this.results,
    required this.total,
    required this.happiness,
    required this.xp,
    required this.xpLabel,
    required this.toPractise,
    required this.targetCode,
    required this.nativeCode,
    required this.againLabel,
    required this.onAgain,
    required this.onClose,
  });

  final List<bool> results;
  final int total;

  /// What the game added to the pet's happiness, and to the player's XP.
  final int happiness;
  final int xp;
  final String xpLabel;

  final List<PlayPractice> toPractise;
  final String? targetCode;
  final String? nativeCode;
  final String againLabel;
  final VoidCallback onAgain;
  final VoidCallback onClose;

  static const Color _ink = AppTheme.retroDark;
  static const Color _muted = Color(0xFF8595A1);

  @override
  Widget build(BuildContext context) {
    final right = results.where((r) => r).length;
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.retroLight,
            border: Border.all(color: _ink, width: 4),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '$right/${results.length}',
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: playPixel(28, _ink),
                ),
                const SizedBox(height: 14),
                PlayResultTrack(
                  results: results,
                  total: total,
                  current: null,
                  pending: _muted,
                ),
                if (happiness > 0 || xp > 0) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 20,
                    runSpacing: 8,
                    textDirection: TextDirection.ltr,
                    children: [
                      if (happiness > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          textDirection: TextDirection.ltr,
                          children: [
                            const SizedBox(
                              width: 22,
                              height: 20,
                              child: CustomPaint(painter: PixelHeartPainter()),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+$happiness',
                              textDirection: TextDirection.ltr,
                              style: playPixel(14, AppTheme.retroPrimary),
                            ),
                          ],
                        ),
                      if (xp > 0)
                        Text(
                          '+$xp $xpLabel',
                          textDirection: TextDirection.ltr,
                          style: playPixel(14, AppTheme.retroGrassDark),
                        ),
                    ],
                  ),
                ],
                if (toPractise.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(height: 3, color: _ink),
                  const SizedBox(height: 12),
                  for (final item in toPractise) _practiseRow(item),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: PlaySquareButton(
                        icon: Icons.replay,
                        label: againLabel,
                        color: AppTheme.retroAccent,
                        size: 52,
                        onTap: onAgain,
                      ),
                    ),
                    const SizedBox(width: 10),
                    PlaySquareButton(
                      icon: Icons.close,
                      label:
                          MaterialLocalizations.of(context).closeButtonTooltip,
                      color: Colors.white,
                      size: 52,
                      onTap: onClose,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Something that got away, with what it means.
  Widget _practiseRow(PlayPractice item) {
    final reading = item.reading;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Text(item.target, style: playPixel(10, _ink, localeCode: targetCode)),
          if (reading != null && reading.isNotEmpty)
            Text('($reading)', style: playPixel(7, _muted)),
          Text(
            '= ${item.meaning}',
            style: playPixel(8, AppTheme.textSecondary, localeCode: nativeCode),
          ),
        ],
      ),
    );
  }
}

/// A five-cell pixel star, for a dizzy orbit.
class PixelStarPainter extends CustomPainter {
  const PixelStarPainter();

  /// '#' outline, 'o' fill.
  static const List<String> _pattern = [
    '..#..',
    '.#o#.',
    '#ooo#',
    '.#o#.',
    '..#..',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 5;
    final paint = Paint()..isAntiAlias = false;
    for (var row = 0; row < 5; row++) {
      for (var col = 0; col < 5; col++) {
        final glyph = _pattern[row][col];
        if (glyph == '.') continue;
        paint.color = glyph == '#' ? AppTheme.retroDark : AppTheme.retroAccent;
        canvas.drawRect(
          Rect.fromLTWH(col * cell, row * cell, cell + 0.5, cell + 0.5),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant PixelStarPainter oldDelegate) => false;
}

/// A pattern of pixel cells, drawn to fill its box: each character of
/// [rows] is a cell, looked up in [inks]; a character with no ink is
/// see-through.
///
/// What every small prop in the games is drawn with — a duck, a mole, a
/// lily pad, a stick — so they share the pet's chunky pixels.
class PixelPatternPainter extends CustomPainter {
  const PixelPatternPainter(this.rows, this.inks, {this.mirrored = false});

  final List<String> rows;
  final Map<String, Color> inks;

  /// Drawn facing the other way.
  final bool mirrored;

  int get columns => rows.fold(0, (m, r) => r.length > m ? r.length : m);

  @override
  void paint(Canvas canvas, Size size) {
    final cols = columns;
    if (cols == 0 || rows.isEmpty) return;
    final cw = size.width / cols;
    final ch = size.height / rows.length;
    final paint = Paint()..isAntiAlias = false;
    for (var y = 0; y < rows.length; y++) {
      final row = rows[y];
      for (var x = 0; x < row.length; x++) {
        final ink = inks[row[x]];
        if (ink == null) continue;
        final col = mirrored ? cols - 1 - x : x;
        canvas.drawRect(
          // Overdrawn by a hair, so cells rounded to different device
          // pixels leave no gaps.
          Rect.fromLTWH(col * cw, y * ch, cw + 0.5, ch + 0.5),
          paint..color = ink,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant PixelPatternPainter old) =>
      old.rows != rows || old.inks != inks || old.mirrored != mirrored;
}
