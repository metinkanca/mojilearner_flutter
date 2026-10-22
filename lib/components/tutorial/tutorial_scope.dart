import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../constants/theme.dart';

/// Owns the app's single showcase controller.
///
/// showcaseview 5 is controller-based rather than inherited-widget-based, so
/// this does not have to sit above the screens it serves — but something has
/// to own the register/unregister pair, and a widget mounted for the life of
/// the app is the honest place for it.
///
/// One controller in the default scope is enough: exactly one screen is on
/// screen at a time, so there is never a second tour to keep separate, and
/// call sites stay free of a `scope:` argument they would only ever pass one
/// value for.
class TutorialScope extends StatefulWidget {
  const TutorialScope({super.key, required this.child});

  final Widget child;

  static bool _registered = false;

  /// Whether a controller exists to attach showcases to.
  ///
  /// [Showcase] throws from its `initState` when nothing is registered, and
  /// the package exposes no way to ask, so we track our own registration.
  /// Widgets consult this and fall back to their bare target, which is what
  /// lets a screen be pumped in a test that knows nothing about tutorials.
  static bool get isRegistered => _registered;

  @override
  State<TutorialScope> createState() => _TutorialScopeState();
}

class _TutorialScopeState extends State<TutorialScope> {
  @override
  void initState() {
    super.initState();
    ShowcaseView.register(
      // Steps point at things that are not always there — the care badge, the
      // review badge, the free-coins tile — and a sequence that stops dead on
      // the first absent one would be worse than no tour at all.
      skipIfTargetNotPresent: true,
      // The profile and shop lists run past the fold.
      enableAutoScroll: true,
      // Advancing is the buttons' job. A stray tap on the dimmed background
      // should not skip a step the player is still reading.
      disableBarrierInteraction: true,
      // The package's tooltip drifts and scales into place. Nothing else in
      // this app eases — the art is on a pixel grid and the chrome snaps —
      // so a coach mark sliding a few sub-pixels back and forth reads as the
      // one soft thing on screen. It also never stops, which means a page
      // with a tour running never settles.
      disableMovingAnimation: true,
      disableScaleAnimation: true,
      overlayColor: AppTheme.retroDark,
      overlayOpacity: 0.82,
    );
    TutorialScope._registered = true;
  }

  @override
  void dispose() {
    TutorialScope._registered = false;
    ShowcaseView.get().unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
