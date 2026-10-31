import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'home_button_art.dart';
import 'play/play_kit.dart';
import 'play/toy_chest.dart';

/// The things standing around the home scene's ground: the toy chest, the
/// mistakes and, where the climb is switched on, the way up to the bosses.
///
/// Bare drawings with no frame or bar behind them, so they read as objects in
/// the room rather than chrome, and a drawing says the same thing in every
/// locale and cannot overflow in the long ones. Each stands where it would if
/// someone had left it there: the chest and the tower in the margins either
/// side of the pet, level with its feet, the books nearer the front. Each
/// one's name is its semantic label.
///
/// Fills whatever it is given, and only its drawings take taps.
class HomeActionBar extends StatelessWidget {
  const HomeActionBar({
    super.key,
    required this.canPlay,
    required this.onToys,
    required this.onMistakes,
    this.onClimb,
  });

  /// Whether the pet is awake to play. The chest stays where it is when it is
  /// not, dimmed, so the row does not rearrange itself every night.
  final bool canPlay;

  final VoidCallback onToys;
  final VoidCallback onMistakes;

  /// Null leaves the climb button out.
  final VoidCallback? onClimb;

  /// The side of each one's tap target.
  static const double buttonSize = 64;

  static const Key toysKey = ValueKey('home-toys-button');
  static const Key mistakesKey = ValueKey('home-mistakes-button');
  static const Key climbKey = ValueKey('home-climb-button');

  /// One pixel of the tower, in points. 32 rows at 2 points fill the
  /// tap target's height.
  static const double _towerCell = 2;

  /// The books are on a much finer grid than the placeholder icons.
  static const double _booksCell = 0.9;

  // Where each stands: its middle as a fraction of the width, and its
  // baseline in points above the bottom. The pet is 0.645 of the width and
  // stands 88 up (`_kPetFootOffset` on the home screen), which leaves the
  // margins at 0.09 and 0.91 clear for the two upright things, and puts the
  // books, which are low, in front of the pet's feet rather than beside them.
  static const double _toysX = 0.92, _toysBase = 66;

  /// The chest and the toys either side of it are one drawing, 34 cells wide.
  /// It has to fit the margin beside the pet, which is a little under 60
  /// points on a tall phone, so a cell is 1.65 points.
  static const double _toysWidth = 56;
  static const double _booksX = 0.34, _booksBase = 14;
  static const double _climbX = 0.09, _climbBase = 82;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        Widget stand(double x, double base, Widget child) => Positioned(
              left: constraints.maxWidth * x - buttonSize / 2,
              bottom: base,
              child: child,
            );

        // Back to front, so what stands nearer is drawn over what is behind.
        return Stack(
          children: [
            if (onClimb != null)
              stand(
                _climbX,
                _climbBase,
                _ActionButton(
                  key: climbKey,
                  // Only shown on debug builds with BOSS_TRIAL set, so the
                  // English label is never read by a player.
                  semanticLabel: 'Boss climb',
                  onTap: onClimb,
                  child: const _PixelIcon(
                    rows: bossTowerArtRows,
                    inks: bossTowerArtInks,
                    cell: _towerCell,
                  ),
                ),
              ),
            stand(
              _toysX,
              _toysBase,
              _ActionButton(
                key: toysKey,
                onTap: canPlay ? onToys : null,
                child: Opacity(
                  opacity: canPlay ? 1 : 0.45,
                  // The chest brings its own label and tap target; the
                  // surrounding one reaches the same place from the corners
                  // it does not cover.
                  child: ToyChest(
                    semanticLabel: l10n?.playToyChest ?? 'Toy chest',
                    onTap: canPlay ? onToys : () {},
                    size: _toysWidth,
                    padding: 0,
                  ),
                ),
              ),
            ),
            stand(
              _booksX,
              _booksBase,
              _ActionButton(
                key: mistakesKey,
                semanticLabel: l10n?.mistakes ?? 'Mistakes',
                onTap: onMistakes,
                child: const _PixelIcon(
                  rows: booksRows,
                  inks: _booksInks,
                  cell: _booksCell,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final target = GestureDetector(
      onTap: onTap,
      // Nothing is drawn behind the icon, so the empty corners need to hit.
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: HomeActionBar.buttonSize,
        height: HomeActionBar.buttonSize,
        child: Align(alignment: Alignment.bottomCenter, child: child),
      ),
    );
    if (semanticLabel == null) return target;
    return Semantics(
      button: true,
      label: semanticLabel,
      container: true,
      excludeSemantics: true,
      child: target,
    );
  }
}

/// A [PixelPatternPainter] grid drawn [cell] points to the pixel.
class _PixelIcon extends StatelessWidget {
  const _PixelIcon({
    required this.rows,
    required this.inks,
    required this.cell,
  });

  final List<String> rows;
  final Map<String, Color> inks;
  final double cell;

  @override
  Widget build(BuildContext context) {
    final painter = PixelPatternPainter(rows, inks);
    return SizedBox(
      width: painter.columns * cell,
      height: rows.length * cell,
      child: CustomPaint(painter: painter),
    );
  }
}

// ---- the icons --------------------------------------------------------------

const Map<String, Color> _booksInks = {
  'X': Color(0xFF14120E),
  'w': Color(0xFFF2E3C6),
  's': Color(0xFFA8DCEF),
  'c': Color(0xFFE98A7B),
  'l': Color(0xFF8CC56A),
};

/// Three books stacked askew: the mistakes. Cut from the generated props
/// sheet (`art_src/gen_home_props.py`) and read onto the cozy room's colours,
/// so unlike the tower it is on a fine grid and drawn under a point to the
/// cell, as the room is.
const List<String> booksRows = [
  '..........................XXXXXXX........................',
  '..........................XXXXXXX........................',
  '.....................XXXXXXXXccccXXXXX...................',
  '.................XXXXXXXXXcccccccXXXXXXXXXX..............',
  '............XXXXXXXXXXcccccccccccccccXXXXXXXXXX..........',
  '........XXXXXXXXXcccccccccccccccccccccccccXXXXX..........',
  '.......XXXXXXXXXcccccccccccccccccccccccccccXXXXXXXX......',
  '.......XXXXXcccccccccccccccccccccccccccccccccccXXXXX.....',
  '.....XXXXccccccccccccccccccccccccccccccccccccccXXXXXXXXX.',
  '.....XXXcccccccccccccccccccccccccccccccccccccccccccXXXXX.',
  '...XXcccccccccccccccccccccccccccccccccccccccccccccccccXX.',
  '...XXcccccccccccccccccccccccccccccccccccccccccccccccccXX.',
  '...XXccccccccccccccccccccccccccccccccccccccccccccccccXXX.',
  '...XXccccccccccccccccccccccccccccccccccccccccccccXXXXX...',
  '...XXccccccccccccccccccccccccccccccccccccccccXXXXXXXXX...',
  '...XXcccccccccccccccccccccccccccccccccccXXXXXXXXXwwwXX...',
  '...XXcccccccccccccccccccccccccccccccccXXXXXXXwwwwwwwXX...',
  '...XXccccccccccccccccccccccccccccXXXXXXXwwwwwwwwwwwwXX...',
  '...XXXcccccccccccccccccccccccccccXXXXXwwwwwwwwwwwwXXXXXX.',
  '...XXXXXXXcccccccccccccccccccccXXwwwwwwwwwwwwwwwwXXXXXXX.',
  '.....XXXXXcccccccccccccccccccccXXwwwwwwwwwwwwXXXXcccccXXX',
  '.....XXXXXXXcccccccccccccccccccXXwwwwwwwwXXXXcccccccXXXX.',
  '...XXsssssXXXXXXcccccccccccccccXXwwwwwXXXccccccccXXXXX...',
  '...XXsssssssXXXXXXXccccccccccccXXwwXXXXccccccXXXXXXXXX...',
  '...XXXXsssssssssXXXXXXXXcccccccXXXXXccccXXXXXXXXXXsssXX..',
  '...XXXXXXssssssssssXXXXXXXcccccccccccXXXXXXXXssssssssXX..',
  '.....XXXwXXXsssssssssssXXXXccccccXXXXXXXsssssssssssssXX..',
  '.....XXXwwXXXXXsssssssssXXXXXccccXXXXXXXsssssssssssssXX..',
  '.....XXXwwwwXXXXXsssssssssXXXXXXXXXXXssssssssssssssssXX..',
  '.....XXXwwwwwwwXXXXXXXsssssssXXXXXXssssssssssssssssssXX..',
  '.....XXXXXwwwwwwwXXXXXsssssssssssssssssssssssssssssssXX..',
  '...XXXXXXXXXwwwwwwwwwXXXXXsssssssssssssssssssssssssssXX..',
  '...XXssssXXXXXwwwwwwwwwwwXXXssssssssssssssssssssssssXXX..',
  '...XXXsssssssswwwwwwwwwwwwwwsssssssssssssssssssssssXXXXX.',
  '...XXXXXsssssssXXXXwwwwwwwwwXXXssssssssssssssssXXXXXXXXXX',
  '...XXXXXXXXXsssssXXXXwwwwwwwXXXssssssssssssssssXXXXXXXXX.',
  '..XXXlllXXXXXXXXXssssXXXXXwwXXXsssssssssssXXXXXlllllllXX.',
  '..XXXlllllllXXXXXssssXXXXXXXXXXsssssssssssXXXXXlllllllXX.',
  'XXXlllllllllllllXXXXXsssssXXXXXsssssssXXXXXllllllXXXXXX..',
  'XXXllllllllllllllXXXXXXXXXXXXXsssXXXXXXXXXlllllXXXXXXX...',
  'XXXllllllllllllllllllXXXXXsssssssXXXXXlllllllllXXXwXXX...',
  'XXXlllllllllllllllllllXXXXsssssssXXXXXllllXXXXXXXwwwXX...',
  'XXXlllllllllllllllllllllllXXXXXXXllllllllXXXXXXwwwwwXX...',
  'XXXlllllllllllllllllllllllXXXXXXXlllllXXXXwwwwwwwwwwXX...',
  'XXXlllllllllllllllllllllllllllllllXXXXXXwwwwwwwwwwwXXXXX.',
  'XXXXXllllllllllllllllllllllllllllXXXwwwwwwwwwwwwwXXXllXX.',
  'XXXXXllllllllllllllllllllllllllXXwwwwwwwwwwwwXXXXXXlllXX.',
  '.XXXXllllllllllllllllllllllllllXXwwwwwwwwwwwlllXllllllXX.',
  '.....XXXXXlllllllllllllllllllllXXwwwwwwwXXXXXlllllXXXXX..',
  '.......XXXXXlllllllllllllllllllXXwwwwwwXXXXllllllXXXXX...',
  '..........XXXXXXXllllllllllllllXXwwXXXXllllllXXXXX.......',
  '............XXXXXXXllllllllllllXXXXXXXlllXXXXXXXX........',
  '................XXXXXllllllllllXXlllllXXXXXXX............',
  '.................XXXXXXXXXlllllXXlllXXXXXXXX.............',
  '..................XXXXXXXXlllllllllXXXXXX................',
  '......................XXXXXXXXXXXXXXXX...................',
  '..........................XXXXXXXXXX.....................',
];
