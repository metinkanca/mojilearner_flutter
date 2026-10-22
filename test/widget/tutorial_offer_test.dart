import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/tutorial/retro_showcase.dart';
import 'package:mojilearner_flutter/components/tutorial/tutorial_offer_host.dart';
import 'package:mojilearner_flutter/components/tutorial/tutorial_scope.dart';
import 'package:mojilearner_flutter/constants/tutorials.dart';
import 'package:mojilearner_flutter/providers/tutorial_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// Guards the one rule the whole feature rests on: a page tour is offered
/// once, and answering it either way retires the offer.
///
/// Written against a stand-in page rather than the real home screen, because
/// what is under test is the offering, not what any particular tour points at.
void main() {
  final stepKey = GlobalKey();
  late MockSettingsProvider settings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    settings = MockSettingsProvider();
    when(() => settings.usePixelFont).thenReturn(true);
  });

  /// The page under test: a tour host with one coach mark inside it.
  Widget page() => TutorialScope(
        child: TutorialOfferHost(
          id: TutorialId.home,
          steps: () => [stepKey],
          child: Center(
            child: RetroShowcase(
              showcaseKey: stepKey,
              description: 'THE THING',
              isFirst: true,
              isLast: true,
              child: const Text('TARGET'),
            ),
          ),
        ),
      );

  Future<TutorialProvider> pumpPage(
    WidgetTester tester, {
    TutorialProvider? tutorials,
    bool onboarded = true,
  }) async {
    final provider = tutorials ?? TutorialProvider();
    await provider.load();

    await pumpApp(
      tester,
      page(),
      tutorialProvider: provider,
      settingsProvider: settings,
      userProvider: MockUserProvider()..hasCompletedOnboarding = onboarded,
    );
    await tester.pumpAndSettle();
    return provider;
  }

  testWidgets('a page nobody has seen offers its tour', (tester) async {
    await pumpPage(tester);

    expect(find.text('NEED A TOUR?'), findsOneWidget);
    expect(find.text('SHOW ME'), findsOneWidget);
    expect(find.text('SKIP'), findsOneWidget);
  });

  testWidgets('skipping retires the offer', (tester) async {
    final provider = await pumpPage(tester);

    await tester.tap(find.text('SKIP'));
    await tester.pumpAndSettle();

    expect(find.text('NEED A TOUR?'), findsNothing);
    expect(provider.hasSeen(TutorialId.home), isTrue);
  });

  testWidgets('watching also retires the offer, and starts the tour',
      (tester) async {
    final provider = await pumpPage(tester);

    await tester.tap(find.text('SHOW ME'));
    await tester.pumpAndSettle();

    expect(provider.hasSeen(TutorialId.home), isTrue);
    expect(find.text('THE THING'), findsOneWidget);

    // Leave nothing running: the overlay holds animations, and the host is
    // about to be torn down under it.
    await tester.tap(find.text('DONE'));
    await tester.pumpAndSettle();
    expect(find.text('THE THING'), findsNothing);
  });

  testWidgets('a page already answered is not offered again', (tester) async {
    final provider = TutorialProvider();
    await provider.load();
    await provider.markSeen(TutorialId.home);

    await pumpPage(tester, tutorials: provider);

    expect(find.text('NEED A TOUR?'), findsNothing);
    expect(find.text('TARGET'), findsOneWidget);
  });

  testWidgets('nothing is offered before onboarding is finished',
      (tester) async {
    // The last step of the opening drops the player on the home screen. Being
    // asked about tours on the way there would be a second tutorial over the
    // top of the first.
    await pumpPage(tester, onboarded: false);

    expect(find.text('NEED A TOUR?'), findsNothing);
  });

  testWidgets('a disabled host waits rather than cancelling', (tester) async {
    final provider = TutorialProvider();
    await provider.load();

    await pumpApp(
      tester,
      TutorialScope(
        child: TutorialOfferHost(
          id: TutorialId.home,
          enabled: false,
          steps: () => [stepKey],
          child: const Text('TARGET'),
        ),
      ),
      tutorialProvider: provider,
      settingsProvider: settings,
      userProvider: MockUserProvider(),
    );
    await tester.pumpAndSettle();

    expect(find.text('NEED A TOUR?'), findsNothing);
    expect(provider.hasSeen(TutorialId.home), isFalse);
  });

  testWidgets('a coach mark with no controller renders its target bare',
      (tester) async {
    // Every screen in the app now carries these, and most of them are pumped
    // in tests that know nothing about tutorials.
    await pumpApp(
      tester,
      Center(
        child: RetroShowcase(
          showcaseKey: GlobalKey(),
          description: 'THE THING',
          child: const Text('TARGET'),
        ),
      ),
      settingsProvider: settings,
    );
    await tester.pumpAndSettle();

    expect(find.text('TARGET'), findsOneWidget);
    expect(find.text('THE THING'), findsNothing);
  });
}
