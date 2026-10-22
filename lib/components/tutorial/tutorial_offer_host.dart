import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../constants/tutorials.dart';
import '../../providers/tutorial_provider.dart';
import '../../providers/user_provider.dart';
import 'tutorial_offer_dialog.dart';
import 'tutorial_scope.dart';

/// Wraps a page and offers its guided tour the first time the player lands
/// on it.
///
/// A widget rather than a mixin because two of the pages it serves
/// ([ProfileScreen], and anything else built stateless) have no state to mix
/// into, and a wrapper works the same either way.
class TutorialOfferHost extends StatefulWidget {
  const TutorialOfferHost({
    super.key,
    required this.id,
    required this.steps,
    required this.child,
    this.enabled = true,
  });

  final TutorialId id;

  /// The sequence, resolved when the tour actually starts rather than when
  /// this widget is built — by then the conditional targets have settled and
  /// the arrival animations have finished moving them.
  final List<GlobalKey> Function() steps;

  /// False while the page is in no state to be toured: an empty review
  /// session, a home screen still walking its pet into place. The offer waits
  /// rather than being cancelled.
  final bool enabled;

  final Widget child;

  @override
  State<TutorialOfferHost> createState() => _TutorialOfferHostState();
}

class _TutorialOfferHostState extends State<TutorialOfferHost> {
  /// How long to wait before looking again when something transient is in the
  /// way — a daily-reward dialog, prefs still loading.
  static const Duration _retry = Duration(milliseconds: 500);

  Timer? _retryTimer;
  bool _offered = false;

  /// Whether this page's tour was retired last time we looked. Null until the
  /// first dependency read.
  bool? _wasSeen;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(TutorialOfferHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) _schedule();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Listening rather than reading, for one case: "Replay tutorials" in the
    // settings dialog. That closes back onto the page the player is standing
    // on, and a host that only looked on mount would make them navigate away
    // and back to see the tour they just asked for.
    final seen = Provider.of<TutorialProvider>(context).hasSeen(widget.id);
    if ((_wasSeen ?? seen) && !seen) {
      _offered = false;
      _schedule();
    }
    _wasSeen = seen;
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _schedule() {
    if (_offered) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOffer());
  }

  void _scheduleRetry() {
    if (_offered || (_retryTimer?.isActive ?? false)) return;
    _retryTimer = Timer(_retry, () {
      if (mounted) _maybeOffer();
    });
  }

  Future<void> _maybeOffer() async {
    if (!mounted || _offered || !widget.enabled) return;
    if (!TutorialScope.isRegistered) return;

    final tutorials = context.read<TutorialProvider>();
    final user = context.read<UserProvider>();

    // Nothing is offered to a player who has not finished onboarding: the
    // last step of that flow drops them on the home screen, and being asked
    // about tours on the way there would be a second tutorial over the top of
    // the first.
    if (!user.hasCompletedOnboarding) return;

    // Prefs may still be in flight. Come back rather than showing a tour the
    // player skipped last week.
    if (!tutorials.isLoaded) return _scheduleRetry();
    if (tutorials.hasSeen(widget.id)) return;

    // Something is already on top of this page — the daily reward, a purchase
    // confirmation, another tour. Wait it out.
    if (ModalRoute.of(context)?.isCurrent != true) return _scheduleRetry();
    if (ShowcaseView.get().isShowcaseRunning) return _scheduleRetry();

    // Set before awaiting, so a rebuild mid-dialog cannot open a second one.
    _offered = true;
    _retryTimer?.cancel();

    final accepted = await showTutorialOffer(context, widget.id);

    // Answering at all retires the offer. The question was asked; asking it
    // again every launch until the player sits through the whole tour is how
    // a tutorial turns into nagging.
    await tutorials.markSeen(widget.id);

    if (!mounted || accepted != true) return;

    // One frame for the dialog's route to finish popping, so the showcase
    // measures the page rather than the barrier that was over it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !TutorialScope.isRegistered) return;
      final steps = widget.steps();
      if (steps.isEmpty) return;
      ShowcaseView.get().startShowCase(steps);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
