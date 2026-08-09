import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/character_provider.dart';
import '../providers/daily_reward_provider.dart';
import '../providers/language_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/vocab_provider.dart';
import '../services/notification_service.dart';
import '../utils/notification_planner.dart';

/// Rewrites the pending notification schedule whenever the app leaves the
/// foreground.
///
/// Backgrounding is the only moment worth doing this: it is the last point at
/// which the pet's stats, the review queue, and the reward clock are all
/// known, and it is exactly when a reminder starts being useful. Scheduling
/// on every state change instead would rewrite the plan dozens of times a
/// session for no benefit.
class NotificationScheduler extends StatefulWidget {
  const NotificationScheduler({super.key, required this.child});

  final Widget child;

  /// Resolves the localized copy for each kind.
  ///
  /// Static and public so the wording can be exercised without a lifecycle
  /// event or a plugin.
  static Map<NotificationKind, NotificationCopy> buildCopy({
    required AppLocalizations l10n,
    required int hunger,
    required int happiness,
    required int dueReviewCount,
  }) {
    // Lead with whichever need is more pressing. Telling someone their pet is
    // lonely when it is actually starving wastes the one message you get.
    final hungerSeverity = hunger - NotificationPlanner.criticalHunger;
    final happinessSeverity = NotificationPlanner.lowHappiness - happiness;
    final isHungrier = hungerSeverity >= happinessSeverity;

    return {
      NotificationKind.petNeedsCare: NotificationCopy(
        title: isHungrier ? l10n.notifPetHungryTitle : l10n.notifPetSadTitle,
        body: isHungrier ? l10n.notifPetHungryBody : l10n.notifPetSadBody,
      ),
      NotificationKind.reviewDue: NotificationCopy(
        title: l10n.notifReviewTitle,
        body: l10n.notifReviewBody(dueReviewCount),
      ),
      NotificationKind.dailyReward: NotificationCopy(
        title: l10n.notifRewardTitle,
        body: l10n.notifRewardBody,
      ),
    };
  }

  @override
  State<NotificationScheduler> createState() => _NotificationSchedulerState();
}

class _NotificationSchedulerState extends State<NotificationScheduler>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _reschedule();
      case AppLifecycleState.resumed:
        // The player is here; anything pending is now redundant and would
        // fire while they are already in the app.
        _clear();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _clear() async {
    final settings = context.read<SettingsProvider>();
    if (!settings.notificationsEnabled) return;
    await NotificationService.I.cancelAll();
  }

  Future<void> _reschedule() async {
    final settings = context.read<SettingsProvider>();
    if (!settings.notificationsEnabled) {
      await NotificationService.I.cancelAll();
      return;
    }

    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    final character = context.read<CharacterProvider>();
    final vocab = context.read<VocabProvider>();
    final rewards = context.read<DailyRewardProvider>();
    final languageCode =
        context.read<LanguageProvider>().targetLanguage?.code;

    final dueCount = vocab.dueCount(languageCode: languageCode);

    final planned = NotificationPlanner.plan(
      now: DateTime.now(),
      hunger: character.hunger,
      happiness: character.happiness,
      nextReviewDueAt: vocab.nextDueAt(languageCode: languageCode),
      dueReviewCount: dueCount,
      dailyRewardAvailable: rewards.isRewardAvailableNow,
      nextDailyRewardAt: rewards.nextRewardAvailableAt,
    );

    await NotificationService.I.applyPlan(
      planned,
      NotificationScheduler.buildCopy(
        l10n: l10n,
        hunger: character.hunger,
        happiness: character.happiness,
        // A reminder written now would understate a queue that keeps growing
        // while the app is closed, so count what will be due at fire time.
        dueReviewCount: dueCount == 0 ? 1 : dueCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
