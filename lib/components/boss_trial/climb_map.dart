import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/boss_climb_art.dart';
import '../../constants/theme.dart';
import '../../utils/boss_trial.dart';
import '../../utils/fonts.dart';
import '../rasterized_svg.dart';
import 'trial_boss.dart';

/// The way to the bosses, drawn as a climb: one floor a boss, the first at the
/// bottom, so the player starts there and scrolls up.
///
/// A floor is a picture (`assets/svgs/climb_floor_N.svg`, made by
/// `art_src/gen_climb.py` in the home scenes' few flat colours) with five
/// round stops on it, one a level, winding up to the boss's gate: the boss's
/// four openings, then its finale. The stops are drawn by the art and
/// numbered here, so what a stop says never has to be painted into a picture.
///
/// Every picture is the home scenes' shape, but each is drawn on a pixel grid
/// of its own (the pad of its stops is the same size on all of them, so a
/// floor's pixels are not): [ClimbFloorArt] says where things are in the
/// picture's own cells, and everything here is sized by the pad, never by a
/// cell, so that the numbers and names are the same on every floor.
///
/// The map only says which stop was tapped; [onStop] decides what that means.
class ClimbMap extends StatelessWidget {
  const ClimbMap({
    super.key,
    required this.playerLevel,
    required this.onStop,
    this.controller,
    this.floors = climbFloorArt,
    this.bosses = TrialBosses.all,
  }) : assert(
            floors.length == bosses.length, 'one floor of art for every boss');

  /// The player's own level, 1 to 30: its stop is flagged, and the stops above
  /// it are drawn dimmer. Every stop can still be tapped, since this is a
  /// testing build.
  final int playerLevel;

  /// A stop was tapped: [step] of [boss]'s levels, 0 to
  /// [BossTrialRules.levelsPerBoss] - 1.
  final void Function(TrialBoss boss, int step) onStop;

  final ScrollController? controller;
  final List<ClimbFloorArt> floors;
  final List<TrialBoss> bosses;

  /// The widest the map is drawn: on a tablet the picture would otherwise be
  /// bigger than the pixels are meant to be.
  static const double maxWidth = 560;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          return ListView.builder(
            // Reversed, so that the first floor is at the bottom and the list
            // opens there: scrolling up is climbing.
            reverse: true,
            controller: controller,
            itemCount: floors.length,
            itemExtentBuilder: (i, _) =>
                ClimbFloorView.extentFor(width, floors[i]),
            itemBuilder: (context, i) => ClimbFloorView(
              key: ValueKey('climb-floor-${i + 1}'),
              art: floors[i],
              boss: bosses[i],
              floor: i + 1,
              playerLevel: playerLevel,
              onStop: onStop,
            ),
          );
        }),
      ),
    );
  }
}

/// One floor: its picture, the stops over it, and under it the band that says
/// whose floor it is (the band between two floors is the way up from one to
/// the next).
class ClimbFloorView extends StatelessWidget {
  const ClimbFloorView({
    super.key,
    required this.art,
    required this.boss,
    required this.floor,
    required this.playerLevel,
    required this.onStop,
  });

  final ClimbFloorArt art;
  final TrialBoss boss;

  /// First floor to last, from 1.
  final int floor;
  final int playerLevel;
  final void Function(TrialBoss boss, int step) onStop;

  /// How tall the band under a floor is.
  static const double bandHeight = 52;

  /// How tall a floor is drawn at [width]: its picture at its own aspect, and
  /// its band.
  static double extentFor(double width, ClimbFloorArt art) =>
      width * art.height / art.width + bandHeight;

  /// The level of the boss's [step]th fight: its openings, one a level, then
  /// its finale, which is the level the boss is named for.
  static int levelOf(TrialBoss boss, int step) =>
      boss.level - (BossTrialRules.levelsPerBoss - 1) + step;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = width * art.height / art.width;
      // Points to a cell of the art: the picture and where the stops are on it
      // scale by it.
      final cell = width / art.width;
      return Column(
        children: [
          SizedBox(
            width: width,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // What shows for the frames before the picture has loaded,
                // and if it never does.
                Positioned.fill(child: ColoredBox(color: Color(art.ground))),
                // Drawn once into an image, not replayed as paths on every
                // frame of a scroll. See [RasterizedSvg].
                Positioned.fill(
                  child: RasterizedSvg.asset(art.asset, fit: BoxFit.fill),
                ),
                for (var step = 0; step < art.stops.length; step++)
                  _stop(step, cell),
              ],
            ),
          ),
          ClimbBand(boss: boss, floor: floor),
        ],
      );
    });
  }

  Widget _stop(int step, double cell) {
    final (x, y) = art.stops[step];
    final pad = art.pad * cell;
    final level = levelOf(boss, step);
    // The name goes on the side the path leans away from, where the floor is
    // empty: a stop left of the middle has it on its left.
    final left = x < art.width / 2;
    final room = ClimbStop.roomFor(pad);
    return Positioned(
      left: x * cell - pad / 2 - (left ? room : 0),
      top: y * cell - pad / 2,
      width: pad + room,
      height: pad,
      child: ClimbStop(
        key: ValueKey('climb-stop-$level'),
        level: level,
        name: step < boss.openings.length ? boss.openings[step].name : 'FINALE',
        finale: step == BossTrialRules.levelsPerBoss - 1,
        reached: level <= playerLevel,
        you: level == playerLevel,
        pad: pad,
        nameOnLeft: left,
        onTap: () => onStop(boss, step),
      ),
    );
  }
}

/// A stop: the number of its level on a small plate over its pad, and beside
/// the pad, what is fought there. The pad, the number and the name can all be
/// tapped.
class ClimbStop extends StatelessWidget {
  const ClimbStop({
    super.key,
    required this.level,
    required this.name,
    required this.finale,
    required this.reached,
    required this.you,
    required this.pad,
    required this.nameOnLeft,
    required this.onTap,
  });

  final int level;
  final String name;

  /// The boss's own level, its last stop.
  final bool finale;

  /// The player has got this far.
  final bool reached;

  /// The player is here.
  final bool you;

  /// The pad's width, in points: the plates and the type are sized by it, so
  /// they are the same on every floor.
  final double pad;

  /// Which side of the pad the name is on.
  final bool nameOnLeft;
  final VoidCallback onTap;

  /// How wide the strip beside a pad is, for its name: the longest of them
  /// (TABLETS) with its frame.
  static double roomFor(double pad) => pad * 0.82;

  static const Color _ink = AppTheme.retroDark;

  @override
  Widget build(BuildContext context) {
    final number = (pad * 0.13).clamp(8.0, 15.0);
    final label = (pad * 0.09).clamp(6.0, 9.0);
    // Stops above the player's level are drawn paler. They still work. The
    // plate is a solid grey rather than a see-through one, or the mark on the
    // pad under it would show.
    final dim = !reached && !finale;
    final fill = finale
        ? AppTheme.retroAccent
        : dim
            ? const Color(0xFFE3DDD6)
            : AppTheme.retroLight;
    final ink = dim ? _ink.withValues(alpha: 0.5) : _ink;
    final room = roomFor(pad);

    Widget frame(Widget child, EdgeInsets padding) => Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(color: _ink, width: 2),
          ),
          child: child,
        );

    final badge = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        frame(
          Text('$level',
              style: AppFonts.pressStart2p(fontSize: number, color: ink)),
          EdgeInsets.symmetric(horizontal: pad * 0.05, vertical: pad * 0.04),
        ),
        if (you)
          Positioned(
            top: -label * 2.6,
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: label * 0.6, vertical: label * 0.35),
              decoration: BoxDecoration(
                color: AppTheme.retroOrange,
                border: Border.all(color: _ink, width: 2),
              ),
              child: Text(
                'YOU',
                style: AppFonts.pressStart2p(
                    fontSize: label, color: AppTheme.retroLight),
              ),
            ),
          ),
      ],
    );

    final caption = SizedBox(
      width: room,
      child: Align(
        alignment: nameOnLeft ? Alignment.centerRight : Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: frame(
            Text(name,
                style: AppFonts.pressStart2p(fontSize: label, color: ink)),
            EdgeInsets.symmetric(horizontal: pad * 0.035, vertical: pad * 0.027),
          ),
        ),
      ),
    );

    final onPad = SizedBox(width: pad, child: Center(child: badge));
    return Semantics(
      button: true,
      label: 'Level $level, $name',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          children: nameOnLeft ? [caption, onPad] : [onPad, caption],
        ),
      ),
    );
  }
}

/// The band under a floor: which floor, whose, and which levels.
class ClimbBand extends StatelessWidget {
  const ClimbBand({
    super.key,
    required this.boss,
    required this.floor,
  });

  final TrialBoss boss;
  final int floor;

  @override
  Widget build(BuildContext context) {
    final first = ClimbFloorView.levelOf(boss, 0);
    return Container(
      height: ClimbFloorView.bandHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppTheme.retroDark,
        border: Border.symmetric(
          horizontal: BorderSide(color: AppTheme.retroAccent, width: 3),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 34,
            child: SvgPicture.asset(boss.asset, fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FLOOR $floor',
                  style: AppFonts.pressStart2p(
                      fontSize: 7, color: AppTheme.retroAccent),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    boss.name.toUpperCase(),
                    style: AppFonts.pressStart2p(
                        fontSize: 12, color: AppTheme.retroLight),
                  ),
                ),
              ],
            ),
          ),
          Text(
            'LEVELS $first–${boss.level}',
            style:
                AppFonts.pressStart2p(fontSize: 7, color: AppTheme.retroLight),
          ),
        ],
      ),
    );
  }
}
