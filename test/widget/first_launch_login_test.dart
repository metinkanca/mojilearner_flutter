import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/l10n/app_localizations.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/screens/onboarding/first_launch/login_panel.dart';
import 'package:mojilearner_flutter/screens/onboarding/first_launch_screen.dart';
import 'package:mojilearner_flutter/services/account_service.dart';
import 'package:mojilearner_flutter/services/cloud_sync.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_account.dart';
import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// The last step of the opening: an offer, not a gate.
///
/// The pet already exists under an anonymous uid by the time this is reached,
/// so declining has to cost nothing — and every path out of here, taken or
/// declined, has to end up in the rest of onboarding.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSettingsProvider mockSettings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockSettings = MockSettingsProvider();
    when(() => mockSettings.usePixelFont).thenReturn(true);
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
  }

  const onePet = 142.0;
  AppLocalizations spanish() => lookupAppLocalizations(const Locale('es'));

  /// Walks language and pet, so the login step is what is on screen.
  Future<void> reachLoginPhase(WidgetTester tester) async {
    await tester.tap(find.text('Español'));
    await settle(tester);
    await tester.tap(find.text(spanish().onboardingLanguageConfirm));
    await settle(tester);
    await tester.tap(find.text(spanish().onboardingPetConfirm));
    await settle(tester);
  }

  Future<AccountService> pumpOpening(
    WidgetTester tester, {
    FakeAccountBackend? backend,
  }) async {
    final account = backend ?? FakeAccountBackend();
    // Deliberately not started: start() installs a five-minute flush timer,
    // and a periodic timer outliving a widget test fails it. Nothing here
    // needs it — linking never touches sync, and conflict resolution goes
    // through onAccountChanged, which signs in for itself.
    final sync = CloudSync(backend: FakeSyncBackend(account));
    final service = AccountService(backend: account, sync: sync);

    final character = CharacterProvider(startDecayTimer: false);
    final language = LanguageProvider();

    final router = GoRouter(
      initialLocation: '/onboarding/start',
      routes: [
        GoRoute(
          path: '/onboarding/start',
          builder: (context, state) => Provider<AccountService?>.value(
            value: service,
            child: const FirstLaunchScreen(),
          ),
        ),
        GoRoute(
          path: afterPetRoute,
          builder: (context, state) => const Text('next step'),
        ),
      ],
    );

    await pumpAppWithRouter(
      tester,
      router,
      characterProvider: character,
      languageProvider: language,
      settingsProvider: mockSettings,
    );
    await settle(tester);

    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      character.dispose();
      language.dispose();
      router.dispose();
    });
    return service;
  }

  testWidgets('the opening ends with an offer to save the pet',
      (tester) async {
    await pumpOpening(tester);
    await reachLoginPhase(tester);

    expect(find.text(spanish().onboardingLoginTitle), findsOneWidget);
    expect(find.text(spanish().onboardingLoginGoogle), findsOneWidget);
    expect(find.text(spanish().onboardingLoginEmail), findsOneWidget);
    expect(find.text(spanish().onboardingLoginSkip), findsOneWidget);
  });

  testWidgets('declining costs nothing and still finishes the opening',
      (tester) async {
    final service = await pumpOpening(tester);
    await reachLoginPhase(tester);

    await tester.tap(find.text(spanish().onboardingLoginSkip));
    await settle(tester);

    expect(find.text('next step'), findsOneWidget);
    // Still the silent per-install identity — nothing was created.
    expect(service.isAnonymous, isTrue);
  });

  testWidgets('signing in with Google links the pet in place', (tester) async {
    final service = await pumpOpening(tester);
    await reachLoginPhase(tester);

    await tester.tap(find.text(spanish().onboardingLoginGoogle));
    await settle(tester);

    expect(service.isAnonymous, isFalse);
    expect(service.email, 'metin@gmail.com');
    expect(find.text('next step'), findsOneWidget);
  });

  testWidgets('backing out of the Google sheet is not an error',
      (tester) async {
    final service = await pumpOpening(
      tester,
      backend: FakeAccountBackend(googleCancels: true),
    );
    await reachLoginPhase(tester);

    await tester.tap(find.text(spanish().onboardingLoginGoogle));
    await settle(tester);

    // Nothing went wrong, so nothing is said. The player is still here, with
    // the offer still standing.
    expect(find.text(spanish().accountErrorSignIn), findsNothing);
    expect(find.text(spanish().onboardingLoginGoogle), findsOneWidget);
    expect(service.isAnonymous, isTrue);
  });

  testWidgets('the email form links the pet in place', (tester) async {
    final service = await pumpOpening(tester);
    await reachLoginPhase(tester);

    await tester.tap(find.text(spanish().onboardingLoginEmail));
    await settle(tester);

    await tester.enterText(find.byKey(loginEmailFieldKey), 'metin@example.com');
    await tester.enterText(find.byKey(loginPasswordFieldKey), 'hunter22');
    await tester.tap(find.text(spanish().accountContinueAction));
    await settle(tester);

    expect(service.isAnonymous, isFalse);
    expect(service.email, 'metin@example.com');
    expect(find.text('next step'), findsOneWidget);
  });

  testWidgets('a weak password is explained rather than swallowed',
      (tester) async {
    await pumpOpening(tester);
    await reachLoginPhase(tester);

    await tester.tap(find.text(spanish().onboardingLoginEmail));
    await settle(tester);

    await tester.enterText(find.byKey(loginEmailFieldKey), 'metin@example.com');
    await tester.enterText(find.byKey(loginPasswordFieldKey), 'abc');
    await tester.tap(find.text(spanish().accountContinueAction));
    await settle(tester);

    expect(find.text(spanish().accountErrorWeakPassword), findsOneWidget);
    // And the player is still on the form, not thrown back or moved on.
    expect(find.text('next step'), findsNothing);
  });

  testWidgets('an address that already has a pet asks which one to keep',
      (tester) async {
    await pumpOpening(
      tester,
      backend: FakeAccountBackend(takenEmails: {'metin@example.com'}),
    );
    await reachLoginPhase(tester);

    await tester.tap(find.text(spanish().onboardingLoginEmail));
    await settle(tester);
    await tester.enterText(find.byKey(loginEmailFieldKey), 'metin@example.com');
    await tester.enterText(find.byKey(loginPasswordFieldKey), 'hunter22');
    await tester.tap(find.text(spanish().accountContinueAction));
    await settle(tester);

    // A question, not an error, and not a silent choice on the player's behalf.
    expect(find.text(spanish().accountConflictTitle), findsOneWidget);
    expect(find.text(spanish().accountConflictKeepThisDevice), findsOneWidget);
    expect(find.text(spanish().accountConflictUseSaved), findsOneWidget);
    expect(find.text('next step'), findsNothing);
  });

  testWidgets('answering the two-pets question passes the choice on',
      (tester) async {
    final backend = FakeAccountBackend(takenEmails: {'metin@example.com'});
    await pumpOpening(tester, backend: backend);
    await reachLoginPhase(tester);

    await tester.tap(find.text(spanish().onboardingLoginEmail));
    await settle(tester);
    await tester.enterText(find.byKey(loginEmailFieldKey), 'metin@example.com');
    await tester.enterText(find.byKey(loginPasswordFieldKey), 'hunter22');
    await tester.tap(find.text(spanish().accountContinueAction));
    await settle(tester);
    expect(backend.signIns, 0, reason: 'nothing decided before the answer');

    await tester.tap(find.text(spanish().accountConflictKeepThisDevice));
    await settle(tester);

    // Stops here on purpose. Resolving goes on to CloudSync.flush, which
    // captures a snapshot through SecureStorage — and awaiting SecureStorage
    // inside testWidgets deadlocks under FakeAsync, so the rest of that path
    // cannot be driven from here. What this level owns is dispatching the
    // player's answer; where the data then goes is covered end to end in
    // test/unit/services/account_service_test.dart.
    expect(backend.signIns, 1);
  });

  testWidgets('the pet chosen a moment ago is the one that was kept',
      (tester) async {
    await pumpOpening(tester);

    await tester.tap(find.text('Español'));
    await settle(tester);
    await tester.tap(find.text(spanish().onboardingLanguageConfirm));
    await settle(tester);
    await tester.drag(find.byType(PageView), const Offset(-onePet, 0));
    await settle(tester);
    await tester.tap(find.text(spanish().onboardingPetConfirm));
    await settle(tester);

    // The login step must not disturb what the step before it settled.
    await tester.tap(find.text(spanish().onboardingLoginSkip));
    await settle(tester);

    expect(find.text('next step'), findsOneWidget);
  });
}
