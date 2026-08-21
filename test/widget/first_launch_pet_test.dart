import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/l10n/app_localizations.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/screens/onboarding/first_launch_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// The second step of the opening. The pets are already on screen from the
/// first step; here they are what is being chosen, and the swipe only moves
/// the rank — the button is what adopts one.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSettingsProvider mockSettings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockSettings = MockSettingsProvider();
    when(() => mockSettings.usePixelFont).thenReturn(true);
  });

  /// The pet sprites animate continuously, so nothing here ever settles —
  /// every wait is a bounded pump.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
  }

  /// Exactly one page wide — the carousel spaces pets 0.355 of the screen
  /// apart, so 400 * 0.355 on the handset surface. A shorter drag ends with
  /// no velocity and PageScrollPhysics settles it straight back, which looks
  /// like a swipe that silently did nothing.
  const onePet = 142.0;

  AppLocalizations spanish() => lookupAppLocalizations(const Locale('es'));

  /// Walks the language step so the pets become the thing being chosen.
  Future<void> reachPetPhase(WidgetTester tester) async {
    await tester.tap(find.text('Spanish'));
    await settle(tester);
    await tester.tap(find.text(spanish().onboardingLanguageConfirm));
    await settle(tester);
  }

  Future<CharacterProvider> pumpOpening(WidgetTester tester) async {
    final character = CharacterProvider(startDecayTimer: false);
    final language = LanguageProvider();

    final router = GoRouter(
      initialLocation: '/onboarding/start',
      routes: [
        GoRoute(
          path: '/onboarding/start',
          builder: (context, state) => const FirstLaunchScreen(),
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
    return character;
  }

  testWidgets('the cat is the pet centred to begin with', (tester) async {
    final character = await pumpOpening(tester);
    await reachPetPhase(tester);

    expect(character.currentCharacterType, 'cat');
  });

  testWidgets('swiping the rank does not adopt a pet on its own',
      (tester) async {
    final character = await pumpOpening(tester);
    await reachPetPhase(tester);

    await tester.drag(find.byType(PageView), const Offset(-onePet, 0));
    await settle(tester);

    // The bird is now centred, but nothing has been chosen yet — passing a
    // pet must not adopt it.
    expect(character.currentCharacterType, 'cat');
  });

  testWidgets('confirming adopts whichever pet is centred', (tester) async {
    final character = await pumpOpening(tester);
    await reachPetPhase(tester);

    await tester.drag(find.byType(PageView), const Offset(-onePet, 0));
    await settle(tester);
    await tester.tap(find.text(spanish().onboardingPetConfirm));
    await settle(tester);

    expect(character.currentCharacterType, 'bird');
  });

  testWidgets('the dog can be chosen by swiping the other way',
      (tester) async {
    final character = await pumpOpening(tester);
    await reachPetPhase(tester);

    await tester.drag(find.byType(PageView), const Offset(onePet, 0));
    await settle(tester);
    await tester.tap(find.text(spanish().onboardingPetConfirm));
    await settle(tester);

    expect(character.currentCharacterType, 'dog');
  });

  testWidgets('past the last pet the rank comes round to the first',
      (tester) async {
    final character = await pumpOpening(tester);
    await reachPetPhase(tester);

    // cat -> bird, the last of the three.
    await tester.drag(find.byType(PageView), const Offset(-onePet, 0));
    await settle(tester);
    // ...and on again, which wraps rather than stopping dead.
    await tester.drag(find.byType(PageView), const Offset(-onePet, 0));
    await settle(tester);

    await tester.tap(find.text(spanish().onboardingPetConfirm));
    await settle(tester);

    expect(character.currentCharacterType, 'dog');
  });

  testWidgets('before the first pet the rank comes round to the last',
      (tester) async {
    final character = await pumpOpening(tester);
    await reachPetPhase(tester);

    // cat -> dog, the first of the three.
    await tester.drag(find.byType(PageView), const Offset(onePet, 0));
    await settle(tester);
    // ...and back again, off the front end.
    await tester.drag(find.byType(PageView), const Offset(onePet, 0));
    await settle(tester);

    await tester.tap(find.text(spanish().onboardingPetConfirm));
    await settle(tester);

    expect(character.currentCharacterType, 'bird');
  });

  testWidgets('confirming hands over to the rest of onboarding',
      (tester) async {
    await pumpOpening(tester);
    await reachPetPhase(tester);

    await tester.tap(find.text(spanish().onboardingPetConfirm));
    await settle(tester);

    expect(find.text('next step'), findsOneWidget);
  });
}
