import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/scenarios.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/scenario_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/fonts.dart';
import '../utils/rtl_locale.dart';
import 'scenario_complete_popup.dart';

/// The objective checklist docked above a scenario chat.
///
/// This is what makes the scene read as a quest rather than a chat with a
/// score attached: the goals are visible from the first turn, and tick as the
/// learner hits them. The tutor never narrates progress, so this is the only
/// place that answers "what's left".
///
/// Collapsible, because four rows of pixel text is a lot of vertical space on
/// a phone once the conversation gets going.
class ScenarioObjectiveTracker extends StatefulWidget {
  const ScenarioObjectiveTracker({super.key, required this.scenario});

  final ScenarioDefinition scenario;

  @override
  State<ScenarioObjectiveTracker> createState() =>
      _ScenarioObjectiveTrackerState();
}

class _ScenarioObjectiveTrackerState extends State<ScenarioObjectiveTracker> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = Provider.of<SettingsProvider>(context);
    final fontFunction = AppFonts.getFont(settings.usePixelFont);
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);

    return Consumer<ScenarioProvider>(
      builder: (context, scenarioProvider, _) {
        final progress = scenarioProvider.forScenario(widget.scenario.id);
        final done = scenarioProvider.clearedRequiredCount(widget.scenario);

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          decoration: BoxDecoration(
            color: AppTheme.retroLight,
            border: Border.all(color: AppTheme.retroDark, width: 3),
            boxShadow: const [
              BoxShadow(
                color: AppTheme.retroDark,
                offset: Offset(3, 3),
                blurRadius: 0,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.scenarioObjectives.toUpperCase(),
                          textDirection: textDirection,
                          style: fontFunction(
                            fontSize: 8,
                            color: AppTheme.retroDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: done >= widget.scenario.requiredCount
                              ? AppTheme.retroGrass
                              : Colors.white,
                          border: Border.all(
                              color: AppTheme.retroDark, width: 2),
                        ),
                        child: Text(
                          l10n.scenarioProgress(
                              done, widget.scenario.requiredCount),
                          textDirection: TextDirection.ltr,
                          style: fontFunction(
                            fontSize: 8,
                            color: AppTheme.retroDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: AppTheme.retroDark,
                      ),
                    ],
                  ),
                ),
              ),
              if (_expanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final objective in widget.scenario.objectives) ...[
                        ScenarioObjectiveLine(
                          label: objective.label(l10n),
                          isCleared: progress.isCleared(objective.id),
                          isBonus: objective.isBonus,
                          bonusLabel: l10n.scenarioBonusLabel,
                          fontFunction: fontFunction,
                          textDirection: textDirection,
                          fontSize: 8,
                        ),
                        const SizedBox(height: 6),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
