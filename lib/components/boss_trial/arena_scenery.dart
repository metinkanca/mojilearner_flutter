/// The scenery a boss's arena stands in: the owner's backdrop, the ledge the
/// boss stands on, and the grass the pet stands on.
///
/// Each arena is three pictures drawn on a pixel grid in that boss's own
/// cells, cut out of the owner's art by `art_src/gen_arena.py`. The screen is
/// never the canvas they were drawn on, so they are not simply stretched onto
/// it. Two rows carry the whole composition -- the row the ledge's top edge
/// sits on and the row the grass starts at -- and the screen works both out
/// for itself, from the boss's size and its own height. So the backdrop is
/// *pinned* to those two rows and stretched between them, which keeps the
/// rocks on the ledge and the roots on the grass at aspects the art was never
/// drawn for, and the strips are scaled by arena width, which leaves them
/// square.
///
/// Every layer falls back to the flat colour it replaced. That is not belt
/// and braces: it is what is on screen for the frames before the asset
/// resolves, and what stays there if it never does, so a missing file costs
/// the player a plainer arena rather than a boss standing on nothing.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../constants/theme.dart';
import '../rasterized_svg.dart';
import 'arena_pieces.dart';

/// The pictures one arena is drawn from, and the rows they hang on.
///
/// All measurements are in the art's own cells. [width] and [height] are the
/// arena itself — the box a screen maps onto — while [backdropWidth] is wider,
/// because the backdrop is drawn with scenery running off both sides so there
/// is something to show on a screen squatter than the one it was drawn for.
class ArenaArt {
  const ArenaArt._({
    required this.id,
    required this.width,
    required this.height,
    required this.backdropWidth,
    required this.groundLine,
    required this.groundUnits,
    this.ledgeLine,
    this.ledgeUnits,
  });

  /// The boss's id in [TrialBosses], which is what the files are named for.
  final String id;
  final double width, height;
  final double backdropWidth;

  /// The row the grass starts at, and the row the ledge's top edge lands on —
  /// null for a boss that flies, whose arena has no ledge.
  final double groundLine;
  final double? ledgeLine;

  /// How tall each strip is drawn, in cells.
  final double groundUnits;
  final double? ledgeUnits;

  String get backdrop => 'assets/svgs/arena_${id}_backdrop.svg';
  String get ledge => 'assets/svgs/arena_${id}_ledge.svg';
  String get ground => 'assets/svgs/arena_${id}_ground.svg';

  /// A mossy stone shelf over a river gorge, its ledge and grass cut out of
  /// one whole-arena picture.
  static const ArenaArt mossback = ArenaArt._(
    id: 'mossback',
    width: 300,
    height: 540,
    backdropWidth: 300,
    ledgeLine: 186,
    ledgeUnits: 27,
    groundLine: 471,
    groundUnits: 69,
  );

  /// A crystal shelf: amethyst clusters on the ledge either side of the boss,
  /// and nothing at all in the play field, which its spikes and gems fill.
  static const ArenaArt amethyst = ArenaArt._(
    id: 'amethyst',
    width: 306,
    height: 550,
    backdropWidth: 408,
    ledgeLine: 206,
    ledgeUnits: 17,
    groundLine: 478,
    groundUnits: 72,
  );

  /// A night grove under a crescent moon. No ledge: she flies.
  static const ArenaArt witch = ArenaArt._(
    id: 'witch',
    width: 257,
    height: 463,
    backdropWidth: 344,
    groundLine: 403,
    groundUnits: 60,
  );

  /// The deep sea, on PLACEHOLDER art (`art_src/gen_lanternmaw_placeholder.py`)
  /// until the owner's: open water down the middle for its fish and bubbles,
  /// rock and kelp in the bleed, a sandy seabed. No ledge: it swims.
  static const ArenaArt angler = ArenaArt._(
    id: 'angler',
    width: 268,
    height: 482,
    backdropWidth: 356,
    groundLine: 421,
    groundUnits: 61,
  );

  /// A desert at dusk on PLACEHOLDER art (`art_src/gen_placeholder_arenas.py`):
  /// a sandstone plinth for it to sit on, pyramids and dunes far off.
  static const ArenaArt sphinx = ArenaArt._(
    id: 'sphinx',
    width: 306,
    height: 550,
    backdropWidth: 408,
    ledgeLine: 206,
    ledgeUnits: 17,
    groundLine: 478,
    groundUnits: 72,
  );

  /// A volcanic peak at night on PLACEHOLDER art: a basalt ledge — "the rock
  /// I sit on", in its Gaze — and ash for the ground.
  static const ArenaArt dragon = ArenaArt._(
    id: 'dragon',
    width: 306,
    height: 550,
    backdropWidth: 408,
    ledgeLine: 206,
    ledgeUnits: 17,
    groundLine: 478,
    groundUnits: 72,
  );

  static const Map<String, ArenaArt> byBoss = {
    'mossback': mossback,
    'amethyst': amethyst,
    'witch': witch,
    'angler': angler,
    'sphinx': sphinx,
    'dragon': dragon,
  };

  /// The arena [bossId] is drawn in, or null for a boss with no art yet —
  /// which draws the flat sky and grass it always did.
  static ArenaArt? of(String bossId) => byBoss[bossId];

  /// How many logical pixels a cell is on a [w] wide arena. Strips are scaled
  /// by this in both axes, so they are never squashed.
  double cell(double w) => w / width;
}

/// The sky, the scenery behind the fight, and the grass: everything drawn
/// before the boss.
class ArenaBackdrop extends StatelessWidget {
  const ArenaBackdrop({
    super.key,
    required this.art,
    required this.width,
    required this.height,
    required this.ledgeTop,
    required this.groundTop,
  });

  final ArenaArt? art;
  final double width, height;

  /// The rows the art is pinned to, as the screen worked them out.
  final double ledgeTop, groundTop;

  @override
  Widget build(BuildContext context) {
    final art = this.art;
    final groundH = height - groundTop;
    return Stack(
      children: [
        const Positioned.fill(
          child: ColoredBox(color: AppTheme.retroNightSky),
        ),
        if (art != null)
          if (art.ledgeLine case final ledgeLine?) ...[
            _band(art, 0, ledgeLine, 0, ledgeTop),
            _band(art, ledgeLine, art.groundLine, ledgeTop, groundTop),
          ] else
            _band(art, 0, art.groundLine, 0, groundTop),
        Positioned(
          left: 0,
          top: groundTop,
          width: width,
          height: groundH,
          child: art == null
              // The flat grass, with the hard edge the strip's top row draws.
              ? const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.retroNightGrass,
                    border: Border(
                      top: BorderSide(color: AppTheme.retroDark, width: 4),
                    ),
                  ),
                )
              : Stack(
                  children: [
                    const Positioned.fill(
                      child: ColoredBox(color: AppTheme.retroNightGrass),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      width: width,
                      height: art.groundUnits * art.cell(width),
                      child: _ArenaPicture(asset: art.ground),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  /// Art rows [from] to [to] of the backdrop, drawn into the screen rows
  /// [top] to [bottom].
  ///
  /// Each band stretches those rows by whatever its own pin demands, across
  /// the middle [ArenaArt.width] of the backdrop's columns (the scenery off
  /// both sides is there for squatter screens). Only that window of the
  /// picture is drawn: laying all of it out at the band's stretch and
  /// clipping, as this once did, would also make an image of all of it, once
  /// per band.
  Widget _band(ArenaArt art, double from, double to, double top,
      double bottom) {
    final bandH = bottom - top;
    if (bandH <= 0 || to <= from) return const SizedBox.shrink();
    final side = (1 - art.width / art.backdropWidth) / 2;
    return Positioned(
      left: 0,
      top: top,
      width: width,
      height: bandH,
      child: _ArenaPicture(
        asset: art.backdrop,
        window:
            Rect.fromLTRB(side, from / art.height, 1 - side, to / art.height),
      ),
    );
  }
}

/// The ledge the boss stands on, drawn after it so its feet sink into the
/// stone. A flying boss has no ledge and this draws nothing.
class ArenaLedge extends StatelessWidget {
  const ArenaLedge({super.key, required this.art});

  final ArenaArt? art;

  @override
  Widget build(BuildContext context) {
    final art = this.art;
    if (art == null) return const CustomPaint(painter: LedgePainter());
    if (art.ledgeUnits == null) return const SizedBox.shrink();
    return _ArenaPicture(
      asset: art.ledge,
      fallback: const CustomPaint(painter: LedgePainter()),
    );
  }
}

/// One arena layer, shown once its file is in hand and [fallback] until then.
///
/// The pictures are the whole background and never change within a fight, so
/// they are read once per asset for the life of the process, and drawn once
/// into an image (see [RasterizedSvg]) rather than replayed as paths every
/// frame — the arena redraws at the display's full rate for the whole fight.
class _ArenaPicture extends StatefulWidget {
  const _ArenaPicture({required this.asset, this.fallback, this.window});

  final String asset;
  final Widget? fallback;

  /// The part of the picture drawn, as fractions of it; all of it when null.
  final Rect? window;

  @override
  State<_ArenaPicture> createState() => _ArenaPictureState();
}

class _ArenaPictureState extends State<_ArenaPicture> {
  static final Map<String, String> _cache = {};
  static final Map<String, Future<String>> _loading = {};

  String? _svg;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_ArenaPicture old) {
    super.didUpdateWidget(old);
    if (old.asset != widget.asset) {
      _svg = null;
      _load();
    }
  }

  Future<void> _load() async {
    final asset = widget.asset;
    final cached = _cache[asset];
    if (cached != null) {
      _svg = cached;
      return;
    }

    final future = _loading.putIfAbsent(asset, () async {
      final raw = await rootBundle.loadString(asset);
      _cache[asset] = raw;
      return raw;
    });

    try {
      final raw = await future;
      if (mounted && asset == widget.asset) setState(() => _svg = raw);
    } catch (_) {
      // The flat colour underneath is the fallback; see the library note.
    } finally {
      _loading.remove(asset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final svg = _svg;
    if (svg == null) return widget.fallback ?? const SizedBox.shrink();
    return RasterizedSvg.string(
      svg,
      cacheKey: widget.asset,
      fit: BoxFit.fill,
      window: widget.window,
      placeholder: widget.fallback,
    );
  }
}
