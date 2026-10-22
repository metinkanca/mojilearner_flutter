import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../components/scenario_city.dart';
import '../constants/entitlements.dart';
import '../constants/pets.dart';
import '../constants/scenarios.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/user_provider.dart';
import '../utils/rtl_locale.dart';
import '../../utils/fonts.dart';

/// The scenarios, as a town: each one is a building with its host pet at the
/// door. Tapping one sends the player's pet walking over and opens a card to
/// go in. The school beside the town hall is the way into the quizzes: its card
/// shows how many of today's the player has used, and starts one.
class ScenariosScreen extends StatefulWidget {
  const ScenariosScreen({super.key});

  @override
  State<ScenariosScreen> createState() => _ScenariosScreenState();
}

class _ScenariosScreenState extends State<ScenariosScreen> {
  String? _selectedId;

  void _enter(BuildContext context, ScenarioDefinition scene) {
    context.pushNamed(
      'chat',
      pathParameters: {'chatId': 'new_${scene.id}'},
      extra: {
        'scenario': scene.title(AppLocalizations.of(context)!),
        'scenarioId': scene.id,
        'isScenario': true,
      },
    );
  }

  /// The quiz, from the school's door. Pushed rather than gone to, so the town
  /// is still there under it.
  void _startQuiz(BuildContext context) => context.push('/quiz');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final selected = ScenarioCatalog.byId(_selectedId);
    final schoolSelected = _selectedId == CityLayout.schoolId;

    return Scaffold(
      backgroundColor: AppTheme.retroSky,
      // The town fills the whole screen, status bar and all; the header and
      // the place card float over it. What they leave empty passes taps
      // through to the map beneath.
      body: Stack(
        children: [
          Positioned.fill(
            child: ScenarioCityMap(
              selectedId: _selectedId,
              onSelect: (id) => setState(() => _selectedId = id),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Retro Header
                Container(
                  margin: const EdgeInsets.all(16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  // The town is a tab of the bottom bar, which is the way out:
                  // no back button of its own.
                  child: Row(
                    children: [
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
                    ],
                  ),
                ),

                Expanded(
                  child: Stack(
                    children: [
                      if (schoolSelected)
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: _SchoolCard(onEnter: () => _startQuiz(context)),
                        )
                      else if (selected != null)
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: _PlaceCard(
                            scenario: selected,
                            onEnter: () => _enter(context, selected),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The school's card: its name, how many of today's quizzes have been used (for
/// a member, whose allowance is too big to count, what the quiz is), and the
/// way in -- the same door as every other place's.
class _SchoolCard extends StatelessWidget {
  const _SchoolCard({required this.onEnter});

  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textDirection =
        textDirectionForLocale(Localizations.localeOf(context));
    final user = context.watch<UserProvider>();
    final total = user.aiLimit(AiSpend.quiz);
    final used = (total - user.aiRemaining(AiSpend.quiz)).clamp(0, total);
    final title = l10n.townSchool;

    return Container(
      key: const ValueKey('school-card'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.retroDark, width: 4),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.retroDark,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        textDirection: textDirection,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              // The school's own wall: the coral its picture is built from.
              color: const Color(0xFFe58472),
              border: Border.all(color: AppTheme.retroDark, width: 3),
            ),
            child: const Icon(LucideIcons.graduationCap,
                color: AppTheme.retroDark, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.toUpperCase(),
                  textDirection: textDirection,
                  style: AppFonts.pressStart2p(
                    fontSize: 10,
                    color: AppTheme.retroDark,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  user.isPremium
                      ? l10n.quizDesc
                      : l10n.aiLimitUsage(used, total),
                  key: const ValueKey('school-progress'),
                  textDirection: textDirection,
                  style: AppFonts.pressStart2p(
                    fontSize: 8,
                    color: AppTheme.retroDark,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _EnterButton(label: title, onTap: onEnter),
        ],
      ),
    );
  }
}

/// The green door button at the end of a place's card.
class _EnterButton extends StatelessWidget {
  const _EnterButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.retroGrass,
            border: Border.all(color: AppTheme.retroDark, width: 4),
            boxShadow: const [
              BoxShadow(
                color: AppTheme.retroDark,
                offset: Offset(3, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: const Icon(
            LucideIcons.doorOpen,
            color: AppTheme.retroDark,
            size: 26,
          ),
        ),
      ),
    );
  }
}

/// The place the player's pet is heading to: what it is, who works there, how
/// far the player has got, and the way in.
class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.scenario, required this.onEnter});

  final ScenarioDefinition scenario;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textDirection =
        textDirectionForLocale(Localizations.localeOf(context));
    final title = scenario.title(l10n);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.retroDark, width: 4),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.retroDark,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        textDirection: textDirection,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scenarioPlaceColor(scenario.id),
              border: Border.all(color: AppTheme.retroDark, width: 3),
            ),
            child: Icon(scenario.icon, color: AppTheme.retroDark, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.toUpperCase(),
                  textDirection: textDirection,
                  style: AppFonts.pressStart2p(
                    fontSize: 10,
                    color: AppTheme.retroDark,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  textDirection: textDirection,
                  children: [
                    Flexible(
                      child: Text(
                        petDisplayName(l10n, scenario.hostPet).toUpperCase(),
                        textDirection: textDirection,
                        style: AppFonts.pressStart2p(
                          fontSize: 8,
                          color: AppTheme.retroDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ScenarioProgressChip(scenario: scenario),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _EnterButton(label: title, onTap: onEnter),
        ],
      ),
    );
  }
}
