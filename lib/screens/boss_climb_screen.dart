import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../components/boss_trial/climb_map.dart';
import '../components/boss_trial/trial_boss.dart';
import '../constants/progression.dart';
import '../constants/theme.dart';
import '../providers/user_provider.dart';
import '../utils/fonts.dart';

/// Where the boss trials are chosen: a climb up through six floors, a boss at
/// the top of each, opening on the first at the bottom of the screen. A stop is
/// a level; tapping one takes the player to that level's fight.
///
/// It replaces the trial screen's own picker, which was a row of buttons for
/// trying each boss and opening in turn. The English copy, like the fights',
/// is for the testing build this is reached from (see
/// `AppRuntimeConfig.bossTrial`).
class BossClimbScreen extends StatelessWidget {
  const BossClimbScreen({super.key});

  /// Where a fight is: the boss by its id, and which of its levels.
  static String fightPath(TrialBoss boss, int step) =>
      '/boss-trial/fight/${boss.id}/$step';

  /// Whether a player at [playerLevel] has reached [step] of [boss]'s levels.
  ///
  /// The player's level only opens a stop. How hard its fight is comes from
  /// how they have been doing lately, never from the level.
  static bool isOpen(TrialBoss boss, int step, int playerLevel) =>
      ClimbFloorView.levelOf(boss, step) <= playerLevel;

  void _enter(BuildContext context, int playerLevel, TrialBoss boss, int step) {
    if (isOpen(boss, step, playerLevel)) {
      context.push(fightPath(boss, step));
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(
          'Reach level ${ClimbFloorView.levelOf(boss, step)} to fight this.',
        ),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final level = context.select<UserProvider, int>(
      (user) => user.stats.level.clamp(1, ProgressionConstants.maxLevel),
    );
    return Scaffold(
      backgroundColor: AppTheme.retroDark,
      // Both children are positioned, so that the stack is the whole screen:
      // a stack takes the size of its loose children, and the button alone
      // would make it the size of the button.
      body: Stack(
        children: [
          Positioned.fill(
            child: ClimbMap(
              playerLevel: level,
              onStop: (boss, step) => _enter(context, level, boss, step),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: _BackButton(onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A square pixel button over the map, since it has no bar to put one in.
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.retroLight,
            border: Border.all(color: AppTheme.retroDark, width: 3),
          ),
          child: Text(
            '<',
            style:
                AppFonts.pressStart2p(fontSize: 16, color: AppTheme.retroDark),
          ),
        ),
      ),
    );
  }
}
