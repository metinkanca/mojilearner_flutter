import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import '../constants/theme.dart';
import 'character_sprite.dart';

/// The shared subset of the two retro font helpers (pixel / mono), so a chosen
/// font can be passed down to the carousel.
typedef CarouselFontFn = TextStyle Function({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
});

/// A swipeable rank of pets, the chosen one centred at full size and full
/// colour with its neighbours shrunk and dimmed to either side.
///
/// Each pet is drawn in its own saved design — coat, eyes and what it is
/// wearing — because that design is the thing being picked between, and a rank
/// of identical grey source art would not show it.
///
/// Deliberately knows nothing about CharacterProvider: it reports the settled
/// pet through [onSelected] and takes its starting point as [initialType]. The
/// pet-changing screen commits that straight to the provider; onboarding holds
/// it as local state until the player confirms, so swiping past a pet does not
/// adopt it.
class CharacterCarousel extends StatefulWidget {
  /// Tile width as a fraction of the carousel, kept just under
  /// [defaultViewportFraction] so a tile fits inside its own page.
  static const double tileFraction = 0.44;

  /// See [viewportFraction].
  static const double defaultViewportFraction = 0.46;

  /// The chosen pet is drawn larger than life and its neighbours smaller, far
  /// enough apart that the enlarged centre tile still clears them: at these
  /// numbers the centre spans 24%-76% of the carousel and a neighbour starts
  /// at 81%, leaving about two thirds of each neighbour in view.
  static const double centreScale = 1.2;

  /// Vertical room taken by the row of position markers under the pets.
  static const double indicatorHeight = 24;

  final List<String> types;
  final double tileWidth;

  /// Null draws no caption under the pets — for the opening, where the art is
  /// the whole point and three names would only crowd it.
  final String Function(String type)? labelForType;
  final CarouselFontFn fontFunction;
  final TextDirection textDirection;

  /// Whether each pet stands in the white retro card. False leaves the sprite
  /// bare on the background.
  final bool framed;

  /// Page width as a fraction of the carousel, which is what spaces the pets
  /// apart. The default leaves the neighbours part-way off both edges, in the
  /// manner of a character-select screen. Around 1/3 fits all three on screen
  /// whole instead.
  ///
  /// Fixed for the life of the carousel: changing it would mean rebuilding the
  /// PageController, which throws away the scroll position mid-gesture.
  final double viewportFraction;

  /// Whether the rank wraps: swipe past the last pet and the first comes
  /// round again, in both directions. The rank then has no ends to hit.
  final bool looping;

  /// How strongly the centred pet is singled out, from 0 to 1.
  ///
  /// At 1 this is a character-select rank: the centre enlarged, its
  /// neighbours shrunk and dimmed, position dots underneath. At 0 it is a
  /// plain row — three pets the same size, none dimmed, no dots — which is
  /// what the opening wants before a pet is the thing being chosen.
  ///
  /// Animating it between the two is what turns one into the other without
  /// swapping widgets, so the pets never unmount mid-zoom.
  final double emphasis;

  /// The pet centred on first build. A type outside [types] starts at the
  /// first pet rather than throwing.
  final String initialType;

  /// Called with the pet that settled under the centre — on swipe or on tap.
  final ValueChanged<String> onSelected;

  const CharacterCarousel({
    super.key,
    required this.types,
    required this.tileWidth,
    required this.labelForType,
    required this.fontFunction,
    required this.textDirection,
    required this.initialType,
    required this.onSelected,
    this.framed = true,
    this.looping = false,
    this.emphasis = 1.0,
    this.viewportFraction = defaultViewportFraction,
  });

  /// The height a carousel needs so the centre tile is not clipped at its
  /// enlarged size — scaling is paint-only, so the box has to be big enough
  /// for the grown tile up front.
  ///
  /// [framed] adds the card's padding, border and caption around the sprite.
  static double stageHeight(double tileWidth, {bool framed = true}) =>
      centreScale * (tileWidth + (framed ? 62 : 0)) + 8 + indicatorHeight;

  @override
  State<CharacterCarousel> createState() => _CharacterCarouselState();
}

class _CharacterCarouselState extends State<CharacterCarousel> {
  /// How many times the rank is repeated when looping. A player swiping once
  /// a second would need most of an hour to reach either end, so in practice
  /// there is none — which is cheaper and far simpler than a PageView that
  /// genuinely wraps.
  static const int _loopCycles = 1000;

  /// A neighbour, against [CharacterCarousel.centreScale] for the chosen one.
  static const double _sideScale = 0.66;

  /// How far a neighbour is darkened, in the manner of a character-select
  /// screen: the chosen one in full colour, the rest in shadow.
  static const double _sideDim = 0.45;

  late final PageController _controller;

  /// The live scroll position in pages, so a tile grows and brightens as it is
  /// dragged towards the centre instead of snapping when the page settles.
  late double _page;

  @override
  void initState() {
    super.initState();
    final initial = _indexOfInitialType();
    _page = initial.toDouble();
    _controller = PageController(
      initialPage: initial,
      viewportFraction: widget.viewportFraction,
    )..addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients || !_controller.position.haveDimensions) return;
    final page = _controller.page;
    if (page == null || page == _page) return;
    setState(() => _page = page);
  }

  int get _typeCount => widget.types.length;

  /// A single pet has nothing to wrap around, so it never loops.
  bool get _looping => widget.looping && _typeCount > 1;

  /// Virtual pages, so there is room to swipe either way before running out.
  int get _pageCount => _looping ? _typeCount * _loopCycles : _typeCount;

  /// The pet a virtual page shows.
  String _typeAt(int page) => widget.types[page % _typeCount];

  int _indexOfInitialType() {
    final index = widget.types.indexOf(widget.initialType);
    final safe = index < 0 ? 0 : index;
    // Start half way along the repeats, so either direction has as far to run.
    return _looping ? _typeCount * (_loopCycles ~/ 2) + safe : safe;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildPages(context)),
        SizedBox(
          height: CharacterCarousel.indicatorHeight,
          // The space is always reserved so the row does not jump as the dots
          // arrive; only their visibility follows the emphasis.
          child: Center(
            child: Opacity(
              opacity: widget.emphasis.clamp(0.0, 1.0),
              child: _buildMarkers(),
            ),
          ),
        ),
      ],
    );
  }

  /// Where in the rank the player is, so the carousel reads as one of several
  /// rather than as all there is. Square, like everything else on the screen.
  Widget _buildMarkers() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.types.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                // Which pet is centred, not which virtual page: when looping,
              // page 1501 and page 4 are both the cat.
              color: _page.round() % _typeCount == i
                  ? AppTheme.retroDark
                  : Colors.white,
                border: Border.all(color: AppTheme.retroDark, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPages(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      itemCount: _pageCount,
      // Committing on settle rather than on tap means a swipe alone chooses
      // the pet — the gesture the screen is built around.
      onPageChanged: (index) => widget.onSelected(_typeAt(index)),
      itemBuilder: (context, index) {
        final type = _typeAt(index);
        // 0 at the centre, 1 once a full page away.
        final distance = (_page - index).abs().clamp(0.0, 1.0);
        // Flattened towards a plain row as emphasis falls to 0: every pet
        // the same size, none in shadow.
        final centre =
            lerpDouble(1.0, CharacterCarousel.centreScale, widget.emphasis)!;
        final side = lerpDouble(1.0, _sideScale, widget.emphasis)!;
        final scale = lerpDouble(centre, side, distance)!;
        final dim = lerpDouble(0.0, _sideDim * widget.emphasis, distance)!;

        return Center(
          child: GestureDetector(
            // A neighbour is also a target: tapping it slides it in rather
            // than making the player drag.
            onTap: () => _controller.animateToPage(
              index,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
            ),
            child: Transform.scale(
              scale: scale,
              child: CharacterTile(
                type: type,
                label: widget.labelForType?.call(type),
                width: widget.tileWidth,
                dim: dim,
                framed: widget.framed,
                fontFunction: widget.fontFunction,
                textDirection: widget.textDirection,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One pet on the carousel, with [dim] of black laid over the art (0 = the
/// chosen pet, at full colour).
///
/// Either standing in the white retro card with its name under it, or — when
/// [framed] is false and [label] is null — bare on the background.
class CharacterTile extends StatelessWidget {
  final String type;
  final String? label;
  final double width;
  final double dim;
  final bool framed;
  final CarouselFontFn fontFunction;
  final TextDirection textDirection;

  const CharacterTile({
    super.key,
    required this.type,
    required this.label,
    required this.width,
    required this.dim,
    required this.fontFunction,
    required this.textDirection,
    this.framed = true,
  });

  @override
  Widget build(BuildContext context) {
    // The frame sizes itself around the sprite, so `width` is the tile and the
    // sprite is what is left after the padding and border. Bare, the sprite is
    // the whole tile.
    final spriteSize = framed ? (width - 32).clamp(60.0, width) : width;

    final sprite = SizedBox(
      width: spriteSize,
      height: spriteSize,
      // srcATop so only the pet is darkened, not the frame it stands in.
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.black.withValues(alpha: dim),
          BlendMode.srcATop,
        ),
        child: CharacterSprite(
          width: spriteSize,
          height: spriteSize,
          previewType: type,
        ),
      ),
    );

    if (!framed) return sprite;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        // Constant width, fading colour: a border that thickened on selection
        // would resize the tile and make the carousel jitter as it settles.
        border: Border.all(
          color: AppTheme.retroDark.withValues(alpha: 1.0 - dim * 0.6),
          width: 4,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.retroDark,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          sprite,
          const SizedBox(height: 8),
          SizedBox(
            width: spriteSize,
            child: Text(
              label ?? '',
              textDirection: textDirection,
              // Centred under the sprite it names, in either script direction.
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: fontFunction(
                fontSize: 10,
                color: AppTheme.retroDark
                    .withValues(alpha: (1.0 - dim).clamp(0.45, 1.0)),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
