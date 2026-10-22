import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../constants/scenarios.dart';
import '../constants/shop.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/character_provider.dart';
import '../screens/coin_shop_screen.dart' show kCoinAsset;
import '../utils/fonts.dart';
import '../utils/rtl_locale.dart';
import '../utils/shop_item_localizer.dart';
import 'character_sprite.dart';
import 'rasterized_svg.dart';
import 'scenario_city.dart' show scenarioPlaceColor;
import 'shop_item_icon.dart';
import 'speech_bubble_tail.dart';

/// The interior a place's chat is set in, or null for a place with no art of
/// its own (a custom scenario has no place at all), which draws the flat wall
/// in `scenarioPlaceColor` instead.
///
/// Each picture is cut by `art_src/gen_city.py` at 2.4:1, a shade wider than
/// the full stage, and drawn bottom-aligned under [BoxFit.cover], never
/// stretched: a wider phone loses a little wall off the top and the compact
/// strip keeps only the bottom band, but the floor line stays where it is in
/// both — which is what the pets are standing on.
String? scenarioRoomBackdrop(String scenarioId) => switch (scenarioId) {
      'coffee' ||
      'job_interview' ||
      'directions' ||
      'doctor' ||
      'shopping' ||
      'restaurant' =>
        'assets/svgs/scenario_${scenarioId}_room.svg',
      _ => null,
    };

/// The scene docked above a scenario chat: the player's pet on the left, the
/// scenario's host pet on the right, facing each other in the place's room.
///
/// The room is the place's own interior where one has been drawn — see
/// [scenarioRoomBackdrop] — and a placeholder everywhere else: a wall in the
/// place's colour from the city map, a floor and a sign. What it is for
/// is the two pets: the host shows it is thinking while the tutor writes,
/// whichever side just spoke hops, and a service the host offers (a meal, a
/// checkup) is put on the table to pay for and then eaten in front of it.
class ScenarioStage extends StatefulWidget {
  const ScenarioStage({
    super.key,
    required this.scenario,
    required this.learnerTurns,
    required this.hostTurns,
    required this.hostThinking,
    this.compact = false,
    this.offer,
    this.canAffordOffer = false,
    this.onPay,
    this.onDecline,
    this.lastBought,
    this.servicesBought = 0,
  });

  final ScenarioDefinition scenario;

  /// Messages sent by each side so far. A count going up is a new line, which
  /// is what makes that side's pet hop.
  final int learnerTurns;
  final int hostTurns;

  /// The tutor is writing: the host wears a thinking bubble.
  final bool hostThinking;

  /// A short strip instead of the full room, for when the keyboard is up and
  /// the conversation needs the height.
  final bool compact;

  /// A service on the table, waiting to be paid for — or null.
  final ShopItem? offer;

  /// Whether the player has the coins for [offer]. Drawn only; paying is
  /// still refused by the purchase itself.
  final bool canAffordOffer;
  final VoidCallback? onPay;
  final VoidCallback? onDecline;

  /// The service most recently paid for, and how many have been. The count
  /// going up is what plays the pet eating [lastBought].
  final ShopItem? lastBought;
  final int servicesBought;

  static const double fullHeight = 150;
  static const double compactHeight = 76;

  @override
  State<ScenarioStage> createState() => _ScenarioStageState();
}

class _ScenarioStageState extends State<ScenarioStage>
    with TickerProviderStateMixin {
  late final AnimationController _learnerHop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final AnimationController _hostHop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final AnimationController _dots = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final AnimationController _eat = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..addStatusListener(_onEatStatus);

  late final String _learnerType;

  late final Widget _host = CharacterSprite(
    width: double.infinity,
    height: double.infinity,
    groundShadow: true,
    previewType: widget.scenario.hostPet,
    previewAccessories: const [],
    naturalCoat: true,
  );

  @override
  void initState() {
    super.initState();
    _learnerType = context.read<CharacterProvider>().currentCharacterType;
    if (widget.hostThinking) _dots.repeat();
  }

  @override
  void didUpdateWidget(covariant ScenarioStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final still = MediaQuery.disableAnimationsOf(context);
    if (!still && widget.learnerTurns > oldWidget.learnerTurns) {
      _learnerHop.forward(from: 0);
    }
    if (!still && widget.hostTurns > oldWidget.hostTurns) {
      _hostHop.forward(from: 0);
    }
    // Nothing plays with reduced motion: the stats change and the ticket goes
    // away, which is the whole of what happened.
    if (!still &&
        widget.servicesBought > oldWidget.servicesBought &&
        widget.lastBought != null) {
      _eat.forward(from: 0);
    }
    if (widget.hostThinking != oldWidget.hostThinking) {
      if (widget.hostThinking) {
        _dots.repeat();
      } else {
        _dots.stop();
      }
    }
  }

  @override
  void dispose() {
    _learnerHop.dispose();
    _hostHop.dispose();
    _dots.dispose();
    _eat.dispose();
    super.dispose();
  }

  void _onEatStatus(AnimationStatus status) {
    if (!mounted) return;
    // Rebuilt on both ends, so the pet chews for exactly as long as there is
    // something in front of it — then a happy hop for the meal.
    setState(() {});
    if (status == AnimationStatus.completed) _learnerHop.forward(from: 0);
  }

  /// How much of the served item is left: whole, then three bites, stepped.
  static double _leftAfterBites(double t) => 1 - (t * 4).floor() / 4;

  /// Two quick hops over the controller's run, snapped to three heights.
  static double _lift(double t, double height) {
    if (t == 0 || t == 1) return 0;
    final arc = math.sin(t * 2 * math.pi).abs();
    return (arc * 3).round() / 3 * height;
  }

  Widget _hopping(AnimationController hop, double height, Widget child) {
    return AnimatedBuilder(
      animation: hop,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -_lift(hop.value, height)),
        child: child,
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: compact ? ScenarioStage.compactHeight : ScenarioStage.fullHeight,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: scenarioPlaceColor(widget.scenario.id),
        border: Border.all(color: AppTheme.retroDark, width: 4),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final floor = height * 0.28;
          final pet = math.min(height * 0.84, width * 0.3);
          final standY = floor * 0.35;
          final hopHeight = pet * 0.1;
          final learnerX = width * 0.24;
          final hostX = width * 0.76;
          final eating = _eat.isAnimating;
          final learner = CharacterSprite(
            width: double.infinity,
            height: double.infinity,
            groundShadow: true,
            previewType: _learnerType,
            previewState: eating ? PetVisualState.eating : null,
          );
          final offer = widget.offer;
          final meal = widget.lastBought;
          final room = scenarioRoomBackdrop(widget.scenario.id);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // The room, or the floor band that stands in for one. Until the
              // picture resolves there is the wall colour behind it, which is
              // also what a place with no art of its own keeps.
              if (room != null)
                Positioned.fill(
                  // Drawn once into an image, not replayed as paths every
                  // frame the two pets breathe. See [RasterizedSvg].
                  child: RasterizedSvg.asset(
                    room,
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                  ),
                )
              else
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: floor,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.wardrobeWood,
                      border: Border(
                        top: BorderSide(color: AppTheme.retroDark, width: 3),
                      ),
                    ),
                  ),
                ),
              // An offer takes the sign's place: while something is on the
              // table, that is what the room is about.
              if (offer != null)
                Positioned(
                  top: compact ? 4 : 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: width * 0.62),
                      child: _ServiceTicket(
                        item: offer,
                        showName: !compact,
                        canAfford: widget.canAffordOffer,
                        onPay: widget.onPay,
                        onDecline: widget.onDecline,
                      ),
                    ),
                  ),
                )
              else if (!compact)
                Positioned(
                  top: 10,
                  left: width * 0.3,
                  right: width * 0.3,
                  child: _RoomSign(scenario: widget.scenario),
                ),
              Positioned(
                left: learnerX - pet / 2,
                bottom: standY,
                width: pet,
                height: pet,
                child: _hopping(_learnerHop, hopHeight, learner),
              ),
              if (eating && meal != null)
                Positioned(
                  // Held at chin height on the side the pet faces. Heads sit
                  // at different heights across the roster; this is the level
                  // that reads as "at the mouth" for all of them.
                  left: learnerX + pet * 0.22,
                  bottom: standY + pet * 0.25,
                  width: pet * 0.3,
                  height: pet * 0.3,
                  child: AnimatedBuilder(
                    animation: _eat,
                    builder: (context, _) => Transform.scale(
                      scale: _leftAfterBites(_eat.value),
                      child: ShopItemIcon(item: meal, size: pet * 0.3),
                    ),
                  ),
                ),
              Positioned(
                left: hostX - pet / 2,
                bottom: standY,
                width: pet,
                height: pet,
                child: _hopping(
                  _hostHop,
                  hopHeight,
                  // The art faces right; the host faces the player's pet.
                  Transform.flip(flipX: true, child: _host),
                ),
              ),
              if (widget.hostThinking)
                Positioned(
                  // Up on the host's tail side, clear of the sign, and low
                  // enough to fit in a compact strip too.
                  left: hostX + pet * 0.2,
                  top: compact ? 4 : 8,
                  child: _ThinkingBubble(dots: _dots),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble({required this.dots});

  final AnimationController dots;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.retroDark, width: 3),
          ),
          child: AnimatedBuilder(
            animation: dots,
            builder: (context, _) {
              final shown = still ? 3 : math.min(3, (dots.value * 4).floor());
              return Text(
                // Padded with spaces so the bubble does not jitter.
                '.' * shown + ' ' * (3 - shown),
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: AppFonts.pressStart2p(
                  fontSize: 9,
                  color: AppTheme.retroDark,
                ),
              );
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 6),
          child: SizedBox(
            width: 12,
            height: 8,
            child: CustomPaint(painter: PixelTrianglePainter()),
          ),
        ),
      ],
    );
  }
}

/// What the host is offering and what it costs, with the way to pay for it or
/// turn it down. The item's name, the price and the buttons all come from the
/// shop's own strings, so it reads the same as buying it there.
/// The name of the place, over its wall. Reconstructed after the original was
/// lost; it matches its call site and the map's own sign styling.
class _RoomSign extends StatelessWidget {
  const _RoomSign({required this.scenario});

  final ScenarioDefinition scenario;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textDirection =
        textDirectionForLocale(Localizations.localeOf(context));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.retroDark, width: 3),
      ),
      child: Text(
        scenario.title(l10n).toUpperCase(),
        textDirection: textDirection,
        textAlign: TextAlign.center,
        style: AppFonts.pressStart2p(
          fontSize: 8,
          color: AppTheme.retroDark,
          height: 1.4,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ServiceTicket extends StatelessWidget {
  const _ServiceTicket({
    required this.item,
    required this.showName,
    required this.canAfford,
    required this.onPay,
    required this.onDecline,
  });

  final ShopItem item;

  /// The item's name above the price — dropped in a compact strip.
  final bool showName;
  final bool canAfford;
  final VoidCallback? onPay;
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textDirection =
        textDirectionForLocale(Localizations.localeOf(context));
    final name = ShopItemLocalizer.localizedName(l10n, item);
    final label = canAfford ? l10n.buy : l10n.tooPoor;

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 4, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.retroDark, width: 3),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.retroDark,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showName) ...[
            Text(
              name.toUpperCase(),
              textDirection: textDirection,
              textAlign: TextAlign.center,
              style: AppFonts.pressStart2p(
                fontSize: 7,
                color: AppTheme.retroDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
          ],
          Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: textDirection,
            children: [
              ShopItemIcon(item: item, size: 22),
              const SizedBox(width: 4),
              SvgPicture.asset(kCoinAsset, width: 12, height: 12),
              const SizedBox(width: 2),
              Text(
                '${item.price}',
                textDirection: TextDirection.ltr,
                style: AppFonts.pressStart2p(
                  fontSize: 8,
                  color: AppTheme.retroDark,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Semantics(
                  button: true,
                  label: '$label $name',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: onPay,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 5),
                      decoration: BoxDecoration(
                        color: canAfford
                            ? AppTheme.retroGrass
                            : AppTheme.retroLight,
                        border: Border.all(color: AppTheme.retroDark, width: 2),
                      ),
                      child: Text(
                        label.toUpperCase(),
                        textDirection: textDirection,
                        textAlign: TextAlign.center,
                        style: AppFonts.pressStart2p(
                          fontSize: 7,
                          color: AppTheme.retroDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Semantics(
                button: true,
                label: MaterialLocalizations.of(context).closeButtonTooltip,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: onDecline,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.retroDark, width: 2),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 12,
                      color: AppTheme.retroDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
