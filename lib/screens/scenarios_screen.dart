import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../components/scenario_city.dart';
import '../constants/entitlements.dart';
import '../constants/scenarios.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/user_provider.dart';
import '../utils/rtl_locale.dart';
import '../../utils/fonts.dart';

/// The scenarios, as a town: each one is a building. Tapping one sends the
/// player's pet walking over and opens a card with the place's name and a go
/// button that names what is practised there. The school beside the town hall
/// is the way into the quizzes: its card shows how many of today's the player
/// has used, and starts one.
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
    final selected = ScenarioCatalog.byId(_selectedId);
    final schoolSelected = _selectedId == CityLayout.schoolId;

    return Scaffold(
      backgroundColor: AppTheme.retroSky,
      // The town fills the whole screen, status bar and all; the place card
      // floats over it. What it leaves empty passes taps through to the map
      // beneath.
      body: Stack(
        children: [
          Positioned.fill(
            child: ScenarioCityMap(
              selectedId: _selectedId,
              onSelect: (id) => setState(() => _selectedId = id),
            ),
          ),
          if (schoolSelected)
            Positioned(
              left: _cardMargin,
              right: _cardMargin,
              bottom: _cardMargin,
              child: _SchoolCard(onEnter: () => _startQuiz(context)),
            )
          else if (selected != null)
            Positioned(
              left: _cardMargin,
              right: _cardMargin,
              bottom: _cardMargin,
              child: _PlaceCard(
                scenario: selected,
                onEnter: () => _enter(context, selected),
              ),
            ),
        ],
      ),
    );
  }
}

/// How far a card stands off the screen's edges and the bar below it. Kept
/// small, so the card hides as little of the town as it can.
const double _cardMargin = 8;

/// The white frame every place's card shares.
class _CardFrame extends StatelessWidget {
  const _CardFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
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
      child: child,
    );
  }
}

/// The small coloured square with a place's icon in it.
class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: AppTheme.retroDark, width: 3),
      ),
      child: Icon(icon, color: AppTheme.retroDark, size: 22),
    );
  }
}

/// A place's name, at the head of its card.
class _PlaceName extends StatelessWidget {
  const _PlaceName(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    return Text(
      name.toUpperCase(),
      textDirection: textDirectionForLocale(Localizations.localeOf(context)),
      style: AppFonts.pressStart2p(
        fontSize: 10,
        color: AppTheme.retroDark,
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
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

    return _CardFrame(
      key: const ValueKey('school-card'),
      child: Row(
        textDirection: textDirection,
        children: [
          // The school's own wall: the coral its picture is built from.
          const _PlaceTile(
              color: Color(0xFFe58472), icon: LucideIcons.graduationCap),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _PlaceName(title),
                const SizedBox(height: 6),
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
          const SizedBox(width: 10),
          _GoButton(label: title, onTap: onEnter),
        ],
      ),
    );
  }
}

/// The green button at the end of a place's card. With a [practice] it names
/// what the player will do inside; without one it is just the door.
class _GoButton extends StatelessWidget {
  const _GoButton({required this.label, required this.onTap, this.practice});

  /// For screen readers.
  final String label;
  final String? practice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textDirection =
        textDirectionForLocale(Localizations.localeOf(context));
    final practice = this.practice;

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(
            minWidth: 48,
            minHeight: 48,
            maxWidth: practice == null ? 48 : 130,
          ),
          padding: EdgeInsets.symmetric(
              horizontal: practice == null ? 0 : 8, vertical: 6),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: textDirection,
            children: [
              const Icon(LucideIcons.doorOpen,
                  color: AppTheme.retroDark, size: 22),
              if (practice != null) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    practice.toUpperCase(),
                    textDirection: textDirection,
                    style: AppFonts.pressStart2p(
                      fontSize: 8,
                      color: AppTheme.retroDark,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The place the player's pet is heading to: what it is called, how far the
/// player has got, and the way in, which says what is practised there.
class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.scenario, required this.onEnter});

  final ScenarioDefinition scenario;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textDirection =
        textDirectionForLocale(Localizations.localeOf(context));
    final practice = scenario.title(l10n);

    return _CardFrame(
      key: const ValueKey('place-card'),
      child: Row(
        textDirection: textDirection,
        children: [
          _PlaceTile(
              color: scenarioPlaceColor(scenario.id), icon: scenario.icon),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _PlaceName(scenario.place(l10n)),
                const SizedBox(height: 6),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ScenarioProgressChip(scenario: scenario),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _GoButton(label: practice, practice: practice, onTap: onEnter),
        ],
      ),
    );
  }
}
