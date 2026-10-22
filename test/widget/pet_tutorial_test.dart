import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/character_sprite.dart';
import 'package:mojilearner_flutter/components/speech_bubble_tail.dart';
import 'package:mojilearner_flutter/l10n/app_localizations.dart';
import 'package:mojilearner_flutter/screens/onboarding/pet_tutorial_screen.dart';
import 'package:mojilearner_flutter/utils/intro_handoff.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';
import '../helpers/test_fixtures.dart';

/// The screen that closes onboarding by teaching the head scratch.
///
/// What these tests hold in place is the promise the screen makes: the
/// gesture it teaches is the one the game accepts, the pet visibly answers
/// it, and — the part easiest to break — nobody who cannot perform it gets
/// stranded here without an app.
void main() {
  late MockUserProvider mockUser;
  late MockCharacterProvider mockCharacter;

  setUp(() {
    mockUser = MockUserProvider();
    mockCharacter = MockCharacterProvider();

    when(() => mockUser.stats).thenReturn(TestFixtures.buildUserStats());
    when(() => mockUser.username).thenReturn('Rin');
    when(() => mockUser.isLoading).thenReturn(false);
    when(() => mockUser.markOnboardingComplete()).thenAnswer((_) async {});

    when(() => mockCharacter.currentCharacterAsset)
        .thenReturn('assets/svgs/cat.svg');
    when(() => mockCharacter.customization)
        .thenReturn(TestFixtures.buildCustomization());
    when(() => mockCharacter.isSleeping).thenReturn(false);
    when(() => mockCharacter.petThePet()).thenReturn(true);
  });

  Future<void> pumpTutorial(WidgetTester tester) async {
    await pumpApp(
      tester,
      const PetTutorialScreen(),
      userProvider: mockUser,
      characterProvider: mockCharacter,
    );
    // Not pumpAndSettle: the hint hand and the pet's breathing both loop
    // forever, so nothing on this screen ever settles.
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// A point on the pet's head, taken off the sprite box the same way the
  /// hitbox is: a fraction down from the top of the art, not a screen guess.
  Offset headPoint(WidgetTester tester) {
    final box = tester.getRect(find.byType(CharacterSprite));
    return Offset(box.center.dx, box.top + box.height * 0.4);
  }

  /// Drags [legs] across the screen, each leg broken into finger-sized steps.
  ///
  /// The steps matter. A leg sent as one jump loses its whole first move to
  /// the drag recognizer's touch slop, which no real finger does.
  Future<void> rub(WidgetTester tester, Offset at, List<double> legs) async {
    const step = 8.0;
    final gesture = await tester.startGesture(at);
    for (final leg in legs) {
      final sign = leg.isNegative ? -1.0 : 1.0;
      var moved = 0.0;
      while (moved < leg.abs()) {
        final hop = (leg.abs() - moved).clamp(0.0, step);
        await gesture.moveBy(Offset(sign * hop, 0));
        await tester.pump();
        moved += hop;
      }
    }
    await gesture.up();
    await tester.pump();
  }

  Future<AppLocalizations> englishL10n() =>
      AppLocalizations.delegate.load(const Locale('en'));

  // The hand is the instruction. Nothing is written down, because a line of
  // text telling the player to do what the animation is already doing reads
  // as a manual rather than as a game.
  testWidgets('opens wordless, with the pet alone on screen', (tester) async {
    await pumpTutorial(tester);
    final l10n = await englishL10n();

    expect(find.text(l10n.petTutorialWelcome('Rin')), findsNothing);
    // One pet, not a carousel: this screen is about the pet they chose.
    expect(find.byType(CharacterSprite), findsOneWidget);
  });

  testWidgets('rubbing the head pets the pet and it says hello',
      (tester) async {
    await pumpTutorial(tester);
    final l10n = await englishL10n();

    await rub(tester, headPoint(tester), const [60, -60, 60]);

    verify(() => mockCharacter.petThePet()).called(1);
    expect(find.text(l10n.petTutorialWelcome('Rin')), findsOneWidget);
  });

  // A bubble with a tail, not a caption in a box: this is the pet talking to
  // the player, which is the whole point of the screen.
  testWidgets('the welcome is spoken, in a bubble over the head',
      (tester) async {
    await pumpTutorial(tester);
    final l10n = await englishL10n();

    expect(find.byType(PixelTrianglePainter), findsNothing);

    await rub(tester, headPoint(tester), const [60, -60, 60]);

    final bubble = tester.getRect(find.text(l10n.petTutorialWelcome('Rin')));
    final pet = tester.getRect(find.byType(CharacterSprite));
    expect(bubble.bottom, lessThan(pet.center.dy),
        reason: 'the bubble belongs over the head, not across the body');
    expect(
      find.byWidgetPredicate((w) =>
          w is CustomPaint && w.painter is PixelTrianglePainter),
      findsOneWidget,
      reason: 'a bubble without a tail is just a box',
    );
  });

  // The gesture taught here has to be the gesture the home screen accepts,
  // or the tutorial is teaching something that stops working tomorrow. One
  // wipe across is a swipe, not a rub, on both screens.
  testWidgets('one swipe across is not a scratch', (tester) async {
    await pumpTutorial(tester);

    await rub(tester, headPoint(tester), const [60, 60, 60]);

    verifyNever(() => mockCharacter.petThePet());
  });

  testWidgets('Continue is held back until the pet has been petted',
      (tester) async {
    await pumpTutorial(tester);
    final l10n = await englishL10n();

    double opacity() => tester
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.text(l10n.continueBtn),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;

    expect(opacity(), 0);

    await rub(tester, headPoint(tester), const [60, -60, 60]);
    await tester.pump(const Duration(milliseconds: 300));

    expect(opacity(), 1);
  });

  // The screen wants to be finished by petting, but it must never be a lock:
  // a player whose drag does not land still has to reach their app.
  testWidgets('Continue turns up on its own if the gesture never lands',
      (tester) async {
    await pumpTutorial(tester);
    final l10n = await englishL10n();

    await tester.pump(const Duration(seconds: 16));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      tester
          .widget<AnimatedOpacity>(
            find.ancestor(
              of: find.text(l10n.continueBtn),
              matching: find.byType(AnimatedOpacity),
            ),
          )
          .opacity,
      1,
    );
  });

  // Onboarding is completed *here*, not at the end of the quiz. The router
  // bounces a finished player off every /onboarding/ route, so setting the
  // flag any earlier would skip this screen entirely.
  testWidgets('Continue completes onboarding and goes home', (tester) async {
    final router = GoRouter(
      initialLocation: '/onboarding/pet-tutorial',
      routes: [
        GoRoute(
          path: '/onboarding/pet-tutorial',
          builder: (context, state) => const PetTutorialScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const Text('home'),
        ),
      ],
    );

    await pumpAppWithRouter(
      tester,
      router,
      userProvider: mockUser,
      characterProvider: mockCharacter,
    );
    await tester.pump(const Duration(milliseconds: 300));

    await rub(tester, headPoint(tester), const [60, -60, 60]);
    await tester.pump(const Duration(milliseconds: 300));

    final l10n = await englishL10n();
    await tester.tap(find.text(l10n.continueBtn));
    // Two waits, because leaving is two beats: the bubble and the button
    // clear off first, and only then does the handover happen.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    verify(() => mockUser.markOnboardingComplete()).called(1);
    expect(find.text('home'), findsOneWidget);
  });

  // The handover the seamless transition is built on: this screen leaves the
  // pet's pose where the next home screen will find it. The route it travels
  // is covered end to end in onboarding_handover_test.dart; what is pinned
  // here is that the pose left behind is the one that was actually on screen.
  testWidgets('leaves the pet pose behind for the home screen',
      (tester) async {
    addTearDown(IntroHandoff.reset);
    IntroHandoff.reset();

    final router = GoRouter(
      initialLocation: '/onboarding/pet-tutorial',
      routes: [
        GoRoute(
          path: '/onboarding/pet-tutorial',
          builder: (context, state) => const PetTutorialScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const Text('home'),
        ),
      ],
    );

    await pumpAppWithRouter(
      tester,
      router,
      userProvider: mockUser,
      characterProvider: mockCharacter,
    );
    await tester.pump(const Duration(milliseconds: 300));

    final petBefore = tester.getRect(find.byType(CharacterSprite));

    await rub(tester, headPoint(tester), const [60, -60, 60]);
    await tester.pump(const Duration(milliseconds: 300));

    final l10n = await englishL10n();
    await tester.tap(find.text(l10n.continueBtn));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    final left = IntroHandoff.claim();
    expect(left, isNotNull);
    // In global coordinates, which is the contract home reads it under.
    expect(left!.petRect, petBefore);
  });
}
