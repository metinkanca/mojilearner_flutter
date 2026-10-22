import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
import '../../utils/fonts.dart';
import '../../utils/play_games.dart';
import '../../utils/rtl_locale.dart';
import '../play_toy.dart' show BeachBallPainter;
import 'play_kit.dart';
import 'play_props.dart';

/// The toy chest: tap it for the games.
///
/// It took the beach ball's place when Catch stopped being the only game, and
/// keeps the ball on its lid so the old way in still reads. A chest of toys
/// says "play" in every language without a word, which is why it is a drawing
/// on the home screen's action bar rather than a labelled button.
class ToyChest extends StatelessWidget {
  const ToyChest({
    super.key,
    required this.semanticLabel,
    required this.onTap,
    this.size = 30,
    this.padding = 8,
  });

  final String semanticLabel;
  final VoidCallback onTap;

  /// How wide it is drawn.
  final double size;

  /// The tap target's margin around the chest.
  final double padding;

  static int get _cols => toyChestPainter.columns;
  static int get _rows => toyChestRows.length;

  /// How tall a chest [size] wide is drawn, shadow and all.
  static double heightFor(double size) => size * _rows / _cols;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        // A thumb-sized target around a chest that is smaller than one.
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: SizedBox(
            width: size,
            height: heightFor(size),
            child: const CustomPaint(painter: toyChestPainter),
          ),
        ),
      ),
    );
  }
}

/// One toy in the chest: the game it starts, what it is called, and how it
/// is drawn.
class ChestToy {
  const ChestToy({
    required this.game,
    required this.routeName,
    required this.painter,
    required this.aspect,
  });

  final PlayGame game;

  /// The named route the game is pushed on.
  final String routeName;
  final CustomPainter painter;

  /// Its drawing's width over its height.
  final double aspect;

  String label(AppLocalizations l10n) => switch (game) {
        PlayGame.catchBall => l10n.playCatch,
        PlayGame.bubbleBath => l10n.playBubbleBath,
        PlayGame.pounce => l10n.playPounce,
        PlayGame.pondHop => l10n.playPondHop,
        PlayGame.fetchWords => l10n.playFetchWords,
      };

  static final List<ChestToy> all = [
    const ChestToy(
      game: PlayGame.catchBall,
      routeName: 'play_catch',
      painter: BeachBallPainter(withShadow: false),
      aspect: 1,
    ),
    ChestToy(
      game: PlayGame.bubbleBath,
      routeName: 'play_bubble_bath',
      painter: toyPainter(rubberDuckRows),
      aspect: 12 / 10,
    ),
    ChestToy(
      game: PlayGame.pounce,
      routeName: 'play_pounce',
      painter: toyPainter(moleToyRows),
      aspect: 12 / 9,
    ),
    ChestToy(
      game: PlayGame.pondHop,
      routeName: 'play_pond_hop',
      painter: toyPainter(lilyPadToyRows),
      aspect: 12 / 10,
    ),
    ChestToy(
      game: PlayGame.fetchWords,
      routeName: 'play_fetch_words',
      painter: toyPainter(stickToyRows),
      aspect: 12 / 10,
    ),
  ];
}

/// The chest opened: a toy for each game. Picking one closes the chest and
/// starts the game.
class ToyChestPicker extends StatelessWidget {
  const ToyChestPicker({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => const ToyChestPicker(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final font = AppFonts.getFont(settings.usePixelFont);
    final textDirection =
        textDirectionForLocale(Localizations.localeOf(context));

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppTheme.retroDark, width: 4),
        borderRadius: BorderRadius.zero,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.playToyChest.toUpperCase(),
                textDirection: textDirection,
                textAlign: TextAlign.center,
                style: font(
                  fontSize: 12,
                  color: AppTheme.retroDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              for (final toy in ChestToy.all) ...[
                _ToyTile(
                  toy: toy,
                  label: toy.label(l10n),
                  style: font(
                    fontSize: 10,
                    height: 1.4,
                    color: AppTheme.retroDark,
                  ),
                  textDirection: textDirection,
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 6),
              PlaySquareButton(
                icon: Icons.close,
                label: MaterialLocalizations.of(context).closeButtonTooltip,
                color: AppTheme.retroLight,
                size: 44,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToyTile extends StatelessWidget {
  const _ToyTile({
    required this.toy,
    required this.label,
    required this.style,
    required this.textDirection,
  });

  final ChestToy toy;
  final String label;
  final TextStyle style;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          final router = GoRouter.of(context);
          Navigator.of(context).pop();
          router.pushNamed(toy.routeName);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.retroLight,
            border: Border.all(color: AppTheme.retroDark, width: 3),
          ),
          child: Row(
            textDirection: textDirection,
            children: [
              SizedBox(
                width: 40,
                height: 36,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: toy.aspect,
                    child: CustomPaint(painter: toy.painter),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  textDirection: textDirection,
                  style: style,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
