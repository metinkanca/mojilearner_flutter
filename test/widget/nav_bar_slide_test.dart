import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mojilearner_flutter/components/navigation_wrapper.dart';

import '../helpers/pump_app.dart';

/// The nav bar arriving.
///
/// It exists for the handover off the meet-your-pet screen, where a bar that
/// blinked into existence under the pet would undo a transition built to have
/// no seam in it. Written as "animate whenever the bar appears" rather than as
/// an onboarding special case, so every other route that brings it back gets
/// the same thing.
void main() {
  /// A router with one route that shows the bar and one that does not.
  GoRouter buildRouter(String initialLocation) => GoRouter(
        initialLocation: initialLocation,
        routes: [
          ShellRoute(
            builder: (context, state, child) => NavigationWrapper(child: child),
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const Text('home'),
              ),
              GoRoute(
                path: '/quiz',
                builder: (context, state) => const Text('quiz'),
              ),
            ],
          ),
        ],
      );

  const bar = ValueKey('nav-bar');

  Offset barOffset(WidgetTester tester) =>
      tester.widget<SlideTransition>(find.byKey(bar)).position.value;

  testWidgets('slides up into place when it first appears', (tester) async {
    await pumpAppWithRouter(tester, buildRouter('/'));
    await tester.pump();

    // Fully below the screen on the first frame, not already sitting there.
    expect(barOffset(tester), const Offset(0, 1));

    await tester.pump(const Duration(milliseconds: 300));
    final midway = barOffset(tester);
    expect(midway.dy, lessThan(1));
    expect(midway.dy, greaterThan(0));

    await tester.pump(const Duration(milliseconds: 700));
    expect(barOffset(tester), Offset.zero);
  });

  testWidgets('slides in again after a route that hides it', (tester) async {
    final router = buildRouter('/');
    await pumpAppWithRouter(tester, router);
    await tester.pump(const Duration(seconds: 1));
    expect(barOffset(tester), Offset.zero);

    // A quiz hides the bar entirely.
    router.go('/quiz');
    await tester.pumpAndSettle();
    expect(find.byKey(bar), findsNothing);

    router.go('/');
    await tester.pump();
    await tester.pump();
    expect(barOffset(tester), const Offset(0, 1),
        reason: 'coming back should replay the slide, not snap the bar on');
  });
}
