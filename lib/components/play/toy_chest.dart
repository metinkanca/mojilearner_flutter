import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/language_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vocab_provider.dart';
import '../../services/starter_words.dart';
import '../../utils/fonts.dart';
import '../../utils/play_games.dart';
import '../../utils/rtl_locale.dart';
import 'play_kit.dart';
import 'play_props.dart';
import 'toy_chest_art.dart';

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
    required this.rows,
    required this.inks,
  });

  final PlayGame game;

  /// The named route the game is pushed on.
  final String routeName;

  /// Its drawing: pixel rows, and the colour of each character in them.
  final List<String> rows;
  final Map<String, Color> inks;

  String label(AppLocalizations l10n) => switch (game) {
        PlayGame.catchBall => l10n.playCatch,
        PlayGame.bubbleBath => l10n.playBubbleBath,
        PlayGame.pounce => l10n.playPounce,
        PlayGame.pondHop => l10n.playPondHop,
        PlayGame.fetchWords => l10n.playFetchWords,
      };

  static const List<ChestToy> all = [
    ChestToy(
      game: PlayGame.catchBall,
      routeName: 'play_catch',
      rows: toyCatchArtRows,
      inks: toyCatchArtInks,
    ),
    ChestToy(
      game: PlayGame.bubbleBath,
      routeName: 'play_bubble_bath',
      rows: toyBathArtRows,
      inks: toyBathArtInks,
    ),
    ChestToy(
      game: PlayGame.pounce,
      routeName: 'play_pounce',
      rows: toyPounceArtRows,
      inks: toyPounceArtInks,
    ),
    ChestToy(
      game: PlayGame.pondHop,
      routeName: 'play_pond_hop',
      rows: toyPondArtRows,
      inks: toyPondArtInks,
    ),
    ChestToy(
      game: PlayGame.fetchWords,
      routeName: 'play_fetch_words',
      rows: toyFetchArtRows,
      inks: toyFetchArtInks,
    ),
  ];
}

/// The chest opened: its lid thrown back over a toy for each game. Picking one
/// closes the chest and starts the game.
class ToyChestPicker extends StatelessWidget {
  const ToyChestPicker({super.key});

  static Future<void> show(BuildContext context) {
    // Short of words? Ask for some while the chest is open. The tiles watch
    // the words, so a toy opens the moment they arrive.
    unawaited(StarterWords.ensureForPlayer(context));
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
    // What the player has learned decides which toys open. Watched, so a word
    // learned while the chest is up opens one.
    final items = context.watch<VocabProvider>().practiseItems;
    final languages = context.watch<LanguageProvider>();
    bool playable(PlayGame game) => canPlay(
          game,
          items: items,
          targetCode: languages.targetLanguage?.code,
          nativeCode: languages.nativeLanguage.code,
        );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: PixelPanel(
        color: PlayPalette.wood,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The lid thrown back, the toys looking out.
              Center(
                child: SizedBox(
                  width: chestOpenArtRows.first.length * PlayPalette.cell,
                  height: chestOpenArtRows.length * PlayPalette.cell,
                  child: const CustomPaint(
                    painter:
                        PixelPatternPainter(chestOpenArtRows, chestOpenArtInks),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: PixelPanel(
                  color: PlayPalette.wall,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Text(
                    l10n.playToyChest.toUpperCase(),
                    textDirection: textDirection,
                    textAlign: TextAlign.center,
                    style: font(
                      fontSize: 12,
                      color: PlayPalette.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              for (final toy in ChestToy.all) ...[
                _ToyTile(
                  toy: toy,
                  label: toy.label(l10n),
                  hint: playable(toy.game) ? null : l10n.playNeedsWords,
                  style: font(
                    fontSize: 10,
                    height: 1.4,
                    color: PlayPalette.ink,
                  ),
                  textDirection: textDirection,
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 4),
              Center(
                child: PlaySquareButton(
                  icon: PlayIcon.close,
                  label: MaterialLocalizations.of(context).closeButtonTooltip,
                  color: PlayPalette.coral,
                  size: 44,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A toy's row: its picture in a window, its name, and an arrow to the game —
/// or, while it is shut, the toy as a stone outline and a padlock.
class _ToyTile extends StatelessWidget {
  const _ToyTile({
    required this.toy,
    required this.label,
    required this.style,
    required this.textDirection,
    this.hint,
  });

  final ChestToy toy;
  final String label;

  /// Why the toy is shut, or null when it opens.
  final String? hint;
  final TextStyle style;
  final TextDirection textDirection;

  /// The room every toy gets: the widest and tallest of them, in cells.
  static const double _slotW = 21 * PlayPalette.cell;
  static const double _slotH = 18 * PlayPalette.cell;

  @override
  Widget build(BuildContext context) {
    final shut = hint != null;
    final rtl = textDirection == TextDirection.rtl;
    // A shut toy keeps its outline and gives up its colours.
    final inks = shut
        ? {
            for (final e in toy.inks.entries)
              e.key: e.value == PlayPalette.ink ? e.value : PlayPalette.stone,
          }
        : toy.inks;
    final toyCols =
        toy.rows.fold<int>(0, (m, r) => r.length > m ? r.length : m);
    final lock = shut ? padlockArtRows : playArrowArtRows;
    final lockInks = shut ? padlockArtInks : playArrowArtInks;
    return Semantics(
      button: true,
      enabled: !shut,
      label: shut ? '$label. $hint' : label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: shut
            ? null
            : () {
                final router = GoRouter.of(context);
                Navigator.of(context).pop();
                router.pushNamed(toy.routeName);
              },
        child: PixelPanel(
          color: shut ? PlayPalette.stone : PlayPalette.wall,
          padding: const EdgeInsets.all(8),
          child: Row(
            textDirection: textDirection,
            children: [
              // The toy on the tile itself, in a slot every toy shares.
              SizedBox(
                width: _slotW,
                height: _slotH,
                child: Center(
                  child: SizedBox(
                    width: toyCols * PlayPalette.cell,
                    height: toy.rows.length * PlayPalette.cell,
                    child: CustomPaint(
                      painter: PixelPatternPainter(toy.rows, inks),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, textDirection: textDirection, style: style),
                    if (hint != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        hint!,
                        textDirection: textDirection,
                        style: style.copyWith(
                          fontSize: (style.fontSize ?? 10) * 0.75,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: lock.first.length * PlayPalette.cell,
                height: lock.length * PlayPalette.cell,
                child: CustomPaint(
                  painter: PixelPatternPainter(lock, lockInks, mirrored: rtl),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
