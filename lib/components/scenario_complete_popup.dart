import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/scenarios.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../utils/fonts.dart';
import '../utils/progression_utils.dart';
import '../utils/rtl_locale.dart';

/// Shown when the learner clears every required objective in a scenario.
///
/// Deliberately simpler than `QuizRewardsPopup` — no confetti layer. A
/// scenario clear is a frequent, repeatable beat, and the quiz popup's full
/// celebration would wear thin at that cadence.
class ScenarioCompletePopup extends StatelessWidget {
  const ScenarioCompletePopup({
    super.key,
    required this.scenario,
    required this.clearedObjectiveIds,
    required this.reward,
    required this.grantedXp,
    required this.grantedCoins,
    required this.onContinue,
    this.sickPenaltyApplied = false,
  });

  final ScenarioDefinition scenario;

  /// Every objective cleared this run, bonus ones included.
  final Set<String> clearedObjectiveIds;

  final ScenarioRewardOutcome reward;

  /// Post-scaling values actually granted — a sick pet earns half, and the
  /// popup must never promise more than the learner received.
  final int grantedXp;
  final int grantedCoins;

  /// True when the pet was sick and the numbers shown are the halved ones,
  /// so the popup can say why rather than leaving the player to guess.
  final bool sickPenaltyApplied;

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final fontFunction = AppFonts.getFont(settings.usePixelFont);
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final textAlign = textAlignForLocale(locale);

    final cleared = scenario.objectives
        .where((o) => clearedObjectiveIds.contains(o.id))
        .length;

    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 340,
            margin: const EdgeInsets.symmetric(vertical: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.retroDark, width: 4),
              boxShadow: const [
                BoxShadow(
                  color: AppTheme.retroDark,
                  offset: Offset(4, 4),
                  blurRadius: 0,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.scenarioCompleteTitle.toUpperCase(),
                  textDirection: textDirection,
                  textAlign: TextAlign.center,
                  style: fontFunction(
                    fontSize: 12,
                    color: AppTheme.retroDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  scenario.title(l10n).toUpperCase(),
                  textDirection: textDirection,
                  textAlign: TextAlign.center,
                  style: fontFunction(
                    fontSize: 9,
                    color: AppTheme.retroDark,
                  ),
                ),
                if (reward.isFirstClear) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.retroAccent,
                      border: Border.all(color: AppTheme.retroDark, width: 3),
                    ),
                    child: Text(
                      l10n.scenarioFirstClear.toUpperCase(),
                      textDirection: textDirection,
                      textAlign: TextAlign.center,
                      style: fontFunction(
                        fontSize: 8,
                        color: AppTheme.retroDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Objective tally, plus the checklist as it finished.
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.retroLight,
                    border: Border.all(color: AppTheme.retroDark, width: 3),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.scenarioCompleteSummary(
                            cleared, scenario.objectives.length),
                        textDirection: textDirection,
                        textAlign: textAlign,
                        style: fontFunction(
                          fontSize: 9,
                          color: AppTheme.retroDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final objective in scenario.objectives) ...[
                        ScenarioObjectiveLine(
                          label: objective.label(l10n),
                          isCleared: clearedObjectiveIds.contains(objective.id),
                          isBonus: objective.isBonus,
                          bonusLabel: l10n.scenarioBonusLabel,
                          fontFunction: fontFunction,
                          textDirection: textDirection,
                        ),
                        const SizedBox(height: 6),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.retroGrass.withValues(alpha: 0.25),
                    border: Border.all(color: AppTheme.retroDark, width: 3),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REWARDS',
                        textDirection: textDirection,
                        textAlign: textAlign,
                        style: fontFunction(
                          fontSize: 9,
                          color: AppTheme.retroDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '+$grantedXp XP',
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                        style:
                            fontFunction(fontSize: 9, color: AppTheme.retroDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+$grantedCoins Coins',
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                        style:
                            fontFunction(fontSize: 9, color: AppTheme.retroDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+${reward.happinessDelta} Happiness',
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                        style:
                            fontFunction(fontSize: 9, color: AppTheme.retroDark),
                      ),
                    ],
                  ),
                ),

                if (sickPenaltyApplied) ...[
                  const SizedBox(height: 10),
                  Text(
                    l10n.scenarioSickPenalty,
                    textDirection: textDirection,
                    textAlign: TextAlign.center,
                    style: fontFunction(
                      fontSize: 8,
                      color: AppTheme.retroPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],

                // Explains the smaller number before the learner wonders.
                if (!reward.isFirstClear) ...[
                  const SizedBox(height: 10),
                  Text(
                    l10n.scenarioReplayNote,
                    textDirection: textDirection,
                    textAlign: TextAlign.center,
                    style: fontFunction(
                      fontSize: 7,
                      height: 1.6,
                      color: Colors.grey[600]!,
                    ),
                  ),
                ],
                const SizedBox(height: 18),

                GestureDetector(
                  onTap: onContinue,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.retroPrimary,
                      border: Border.all(color: AppTheme.retroDark, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: AppTheme.retroDark,
                          offset: Offset(3, 3),
                          blurRadius: 0,
                        )
                      ],
                    ),
                    child: Text(
                      l10n.scenarioContinue.toUpperCase(),
                      textDirection: textDirection,
                      textAlign: TextAlign.center,
                      style: fontFunction(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One checklist row: a pixel checkbox and its label.
///
/// Shared by the completion popup and the in-chat tracker so a ticked
/// objective looks identical in both places.
class ScenarioObjectiveLine extends StatelessWidget {
  const ScenarioObjectiveLine({
    super.key,
    required this.label,
    required this.isCleared,
    required this.isBonus,
    required this.bonusLabel,
    required this.fontFunction,
    required this.textDirection,
    this.fontSize = 7,
  });

  final String label;
  final bool isCleared;
  final bool isBonus;
  final String bonusLabel;
  final TextStyle Function({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    TextDecoration? decoration,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) fontFunction;
  final TextDirection textDirection;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            color: isCleared ? AppTheme.retroGrass : Colors.white,
            border: Border.all(color: AppTheme.retroDark, width: 2),
          ),
          child: isCleared
              ? const Icon(Icons.check, size: 10, color: AppTheme.retroDark)
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isBonus ? '$label ($bonusLabel)' : label,
            textDirection: textDirection,
            style: fontFunction(
              fontSize: fontSize,
              height: 1.7,
              color: isCleared ? AppTheme.retroDark : Colors.grey[600]!,
            ),
          ),
        ),
      ],
    );
  }
}
