import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/character_sprite.dart';
import 'package:mojilearner_flutter/components/tutorial/tutorial_scope.dart';
import 'package:mojilearner_flutter/constants/tutorials.dart';
import 'package:mojilearner_flutter/l10n/app_localizations.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/tutorial_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';
import '../helpers/test_fixtures.dart';

class MockVocabProvider extends Mock implements VocabProvider {}

/// The home tour, against the real home screen.
///
/// The framework has its own tests; this one is about the wiring — that the
/// steps resolve to widgets that are actually on the screen, that the ones
/// which are not there get skipped rather than pointed at, and that the tour
/// ends where it is supposed to.
void main() {
  const handset = Size(400, 844);

  late MockUserProvider mockUser;
  late MockDailyRewardProvider mockDailyReward;
  late MockCharacterProvider mockCharacter;
  late MockLanguageProvider mockLanguage;
  late MockSettingsProvider mockSettings;
  late MockVocabProvider mockVocab;
  late MockMistakesProvider mockMistakes;
  late TutorialProvider tutorials;

  late AppLocalizations en;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});

    mockUser = MockUserProvider();
    mockDailyReward = MockDailyRewardProvider();
    mockCharacter = MockCharacterProvider();
    mockLanguage = MockLanguageProvider();
    mockSettings = MockSettingsProvider();
    mockVocab = MockVocabProvider();
    mockMistakes = MockMistakesProvider();

    when(() => mockUser.stats).thenReturn(TestFixtures.buildUserStats());
    when(() => mockUser.isLoading).thenReturn(false);

    when(() => mockDailyReward.checkDailyReward())
        .thenAnswer((_) async => null);
    when(() => mockDailyReward.pendingDailyReward).thenReturn(null);

    // A pet in good order, so there is no care badge. Hunger is inverted —
    // 10 is a well-fed pet. Together with an empty review queue this is the
    // state of a brand-new save, which is exactly when the tour runs, so two
    // of its steps have nothing to point at.
    when(() => mockCharacter.hunger).thenReturn(10);
    when(() => mockCharacter.happiness).thenReturn(90);
    when(() => mockCharacter.health).thenReturn(100);
    when(() => mockCharacter.inventory).thenReturn(const []);
    when(() => mockCharacter.currentCharacterAsset)
        .thenReturn('assets/svgs/cat.svg');
    when(() => mockCharacter.customization)
        .thenReturn(TestFixtures.buildCustomization());
    when(() => mockCharacter.isSleeping).thenReturn(false);
    when(() => mockCharacter.isTemporarilyAwake).thenReturn(false);
    when(() => mockCharacter.isSleepingForNight).thenReturn(false);
    when(() => mockCharacter.awakeUntil).thenReturn(null);

    when(() => mockLanguage.targetLanguage).thenReturn(
      const Language(code: 'es', name: 'Spanish'),
    );
    when(() => mockSettings.usePixelFont).thenReturn(true);
    // Read by the settings dialog, which the replay test opens.
    when(() => mockSettings.notificationsEnabled).thenReturn(false);
    when(() => mockSettings.notificationsDenied).thenReturn(false);
    when(() => mockVocab.dueCount(languageCode: any(named: 'languageCode')))
        .thenReturn(0);

    tutorials = TutorialProvider();
    await tutorials.load();
  });

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(handset);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpApp(
      tester,
      const TutorialScope(child: HomeScreen()),
      userProvider: mockUser,
      dailyRewardProvider: mockDailyReward,
      characterProvider: mockCharacter,
      languageProvider: mockLanguage,
      settingsProvider: mockSettings,
      vocabProvider: mockVocab,
      mistakesProvider: mockMistakes,
      tutorialProvider: tutorials,
    );
    // Not pumpAndSettle: the pet's breathing animation never settles.
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> startTour(WidgetTester tester) async {
    await pumpHome(tester);
    await tester.tap(find.text(en.tutorialWatch));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.text(en.tutorialNext));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // A step change waits on the old tooltip's reverse animation, which only
    // advances on frames. These pumps used to get a frame each for free, from
    // the pet's breathing asking for one at every refresh; it now steps 8
    // times a second (see PixelClock), so the second half of the animation
    // gets a pump of its own.
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('the home screen offers its tour on a fresh save',
      (tester) async {
    await pumpHome(tester);

    expect(find.text(en.tutorialOfferTitle), findsOneWidget);
    expect(find.text(en.tutorialOfferHome), findsOneWidget);
  });

  testWidgets('the study button is on home even with nothing due',
      (tester) async {
    await pumpHome(tester);

    expect(find.byIcon(LucideIcons.bookOpen), findsOneWidget);
    expect(find.byKey(const ValueKey('study-due')), findsNothing);
  });

  testWidgets('the study button carries what is due', (tester) async {
    when(() => mockVocab.dueCount(languageCode: any(named: 'languageCode')))
        .thenReturn(7);
    await pumpHome(tester);

    expect(
      find.descendant(
          of: find.byKey(const ValueKey('study-due')), matching: find.text('7')),
      findsOneWidget,
    );
  });

  testWidgets('the study button opens review and mistakes', (tester) async {
    when(() => mockMistakes.mistakes).thenReturn(const []);
    await pumpHome(tester);
    // The tour offer is a dialog over the screen; wave it away first.
    await tester.tap(find.text(en.tutorialSkip));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byIcon(LucideIcons.bookOpen));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('study-review')), findsOneWidget);
    expect(find.byKey(const ValueKey('study-mistakes')), findsOneWidget);
  });

  testWidgets('the tour opens on the pet, and covers it', (tester) async {
    await startTour(tester);

    expect(find.text(en.tutorialHomePet), findsOneWidget);

    // The step is drawn over the pet's own art box, not over the full-scene
    // gesture layer that wraps it — highlighting that would just dim the
    // screen and cut a hole the shape of it.
    final sprite = tester.getRect(find.byType(CharacterSprite));
    expect(sprite.height, lessThan(handset.height));
  });

  testWidgets('steps with nothing to point at are skipped, not shown',
      (tester) async {
    await startTour(tester);
    await next(tester); // pet -> level

    expect(find.text(en.tutorialHomeLevel), findsOneWidget);

    // The care badge comes next in the sequence, and does not exist on a
    // healthy pet. The study button is always there, so it is the next stop.
    await next(tester);

    expect(find.text(en.tutorialHomeCare), findsNothing);
    expect(find.text(en.tutorialHomeReview), findsOneWidget);

    await next(tester);
    expect(find.text(en.tutorialHomeFeed), findsOneWidget);
  });

  testWidgets('the tour visits every part of the screen, in order',
      (tester) async {
    await startTour(tester);

    // The nav-bar steps that follow these are not reachable here: the bar
    // belongs to NavigationWrapper, which this harness does not mount. That
    // they are simply skipped rather than stalling the tour is the same
    // guarantee the care and review badges rely on.
    final rest = [
      en.tutorialHomeLevel,
      en.tutorialHomeReview,
      en.tutorialHomeFeed,
      en.tutorialHomeSettings,
    ];

    for (final copy in rest) {
      await next(tester);
      expect(find.text(copy), findsOneWidget, reason: copy);
    }

    // Off the end of what is on screen, and the tour is over rather than
    // stuck on a step with no target.
    await next(tester);
    expect(find.text(en.tutorialHomeSettings), findsNothing);
    expect(find.text(en.tutorialNext), findsNothing);
  });

  testWidgets('BACK returns to the previous step', (tester) async {
    await startTour(tester);
    await next(tester);
    expect(find.text(en.tutorialHomeLevel), findsOneWidget);

    await tester.tap(find.text(en.tutorialBack));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(en.tutorialHomePet), findsOneWidget);
    // And the first step offers no way further back.
    expect(find.text(en.tutorialBack), findsNothing);
  });

  testWidgets('skipping mid-tour ends it and does not re-offer',
      (tester) async {
    await startTour(tester);
    await next(tester);

    await tester.tap(find.text(en.tutorialSkip));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(en.tutorialHomeLevel), findsNothing);
    expect(find.text(en.tutorialOfferTitle), findsNothing);
    expect(tutorials.hasSeen(TutorialId.home), isTrue);
  });

  testWidgets('the settings dialog can put the tours back on offer',
      (tester) async {
    // The one way back for a player who tapped SKIP by reflex on the first
    // screen they ever saw.
    await tutorials.markSeen(TutorialId.home);
    await pumpHome(tester);
    expect(find.text(en.tutorialOfferTitle), findsNothing);

    await tester.tap(find.byKey(homeSettingsButtonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text(en.tutorialReplay));
    await tester.pump();
    // Long enough for the dialog to finish popping and the host's retry to
    // come round: it holds off while anything is on top of the page.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(tutorials.hasSeen(TutorialId.home), isFalse);
    // And the offer comes straight back, on the screen the player is on.
    expect(find.text(en.tutorialOfferTitle), findsOneWidget);
  });
}
