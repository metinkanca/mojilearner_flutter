import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../constants/scenarios.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/scenario_provider.dart';
import '../utils/rtl_locale.dart';
import '../../utils/fonts.dart';

class ScenariosScreen extends StatelessWidget {
  const ScenariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);

    const scenarios = ScenarioCatalog.all;

    return Scaffold(
      backgroundColor: AppTheme.retroSky,
      body: SafeArea(
        child: Column(
          children: [
            // Retro Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.retroUi,
                border: Border.all(color: AppTheme.retroDark, width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.retroDark,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              // This screen owns its back button (see NavigationWrapper, which
              // suppresses its floating one for /scenarios).
              child: Row(
                children: [
                  // GestureDetector rather than IconButton: no ink ripple, and
                  // this screen is reached via `go` (which leaves nothing to
                  // pop), so fall back to home.
                  GestureDetector(
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                    child: Container(
                      width: 36,
                      height: 36,
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
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppTheme.retroDark,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n.scenarios.toUpperCase(),
                        textDirection: textDirection,
                        textAlign: TextAlign.center,
                        style: AppFonts.pressStart2p(
                          fontSize: 16,
                          color: AppTheme.retroDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grid Layout
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: scenarios.length,
                      itemBuilder: (context, index) {
                        final scene = scenarios[index];
                        // Assign colors based on index for variety
                        final cardColor = index % 2 == 0 ? Colors.white : AppTheme.retroLight;
                        final iconBgColor = index % 3 == 0 ? AppTheme.retroGrass : (index % 3 == 1 ? AppTheme.retroSkyLight : AppTheme.retroOrange);

                        // Progress is read per card so the grid answers "what
                        // have I actually done here" at a glance.
                        final scenarioProvider =
                            context.watch<ScenarioProvider>();
                        final done =
                            scenarioProvider.clearedRequiredCount(scene);
                        final everCleared =
                            scenarioProvider.hasEverCompleted(scene.id);

                        return GestureDetector(
                          onTap: () {
                            context.pushNamed(
                              'chat',
                              pathParameters: {'chatId': 'new_${scene.id}'},
                              extra: {
                                'scenario': scene.title(l10n),
                                'scenarioId': scene.id,
                                'isScenario': true,
                              },
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cardColor,
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: iconBgColor,
                                    border: Border.all(color: AppTheme.retroDark, width: 3),
                                  ),
                                  child: Icon(scene.icon, color: AppTheme.retroDark, size: 24),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  scene.title(l10n).toUpperCase(),
                                  textDirection: textDirection,
                                  textAlign: TextAlign.center,
                                  style: AppFonts.pressStart2p(
                                    fontSize: 10,
                                    color: AppTheme.retroDark,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: everCleared
                                        ? AppTheme.retroGrass
                                        : Colors.white,
                                    border: Border.all(
                                        color: AppTheme.retroDark, width: 2),
                                  ),
                                  child: Text(
                                    // A cleared scenario keeps showing its
                                    // in-progress count once replayed, so the
                                    // stamp and the tally are both useful.
                                    everCleared && done == 0
                                        ? l10n.scenarioCleared.toUpperCase()
                                        : l10n.scenarioProgress(
                                            done, scene.requiredCount),
                                    textDirection: everCleared && done == 0
                                        ? textDirection
                                        : TextDirection.ltr,
                                    textAlign: TextAlign.center,
                                    style: AppFonts.pressStart2p(
                                      fontSize: 7,
                                      color: AppTheme.retroDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 80), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
