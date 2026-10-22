import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/play/toy_chest.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/screens/home_screen.dart';
import 'package:mojilearner_flutter/screens/play/bubble_bath_screen.dart';
import 'package:mojilearner_flutter/screens/play/fetch_words_screen.dart';
import 'package:mojilearner_flutter/screens/play/pond_hop_screen.dart';
import 'package:mojilearner_flutter/screens/play/pounce_screen.dart';
import 'package:mojilearner_flutter/screens/play_catch_screen.dart';
import 'package:mojilearner_flutter/utils/pet_recolor.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';
import '../helpers/test_fixtures.dart';

/// The toy chest beside the pet has to actually start every game in it, and
/// each game has to stay open: a pool too thin to play used to close the
/// screen in the frame it opened, which from the home screen looked like a
/// ball that did nothing.
void main() {
  late MockUserProvider user;
  late MockDailyRewardProvider dailyReward;
  late MockCharacterProvider character;
  late MockLanguageProvider language;
  late MockSettingsProvider settings;

  setUp(() {
    user = MockUserProvider();
    dailyReward = MockDailyRewardProvider();
    character = MockCharacterProvider();
    language = MockLanguageProvider();
    settings = MockSettingsProvider();

    when(() => user.stats).thenReturn(TestFixtures.buildUserStats(
      level: 5,
      totalXP: 892,
      currentLevelXP: 92,
      nextLevelXP: 200,
      coins: 350,
      streak: 7,
      progress: 0.46,
    ));
    when(() => user.isLoading).thenReturn(false);
    when(() => dailyReward.checkDailyReward()).thenAnswer((_) async => null);
    when(() => dailyReward.pendingDailyReward).thenReturn(null);
    when(() => character.hunger).thenReturn(50);
    when(() => character.happiness).thenReturn(70);
    when(() => character.health).thenReturn(100);
    when(() => character.inventory).thenReturn(['apple']);
    when(() => character.currentCharacterType).thenReturn('cat');
    when(() => character.currentCharacterAsset)
        .thenReturn('assets/svgs/cat.svg');
    when(() => character.customization)
        .thenReturn(TestFixtures.buildCustomization());
    when(() => character.isSleeping).thenReturn(false);
    when(() => character.isTemporarilyAwake).thenReturn(false);
    when(() => character.isSleepingForNight).thenReturn(false);
    when(() => character.awakeUntil).thenReturn(null);
    when(() => character.colorSpecFor(any())).thenReturn(const PetColorSpec(
      bodyColor: '#959379',
      eyeMode: EyeMode.solid,
      eyeColor1: '#F4C430',
      eyeColor2: '#5AA0E0',
    ));
    when(() => character.equippedAccessoriesFor(any())).thenReturn(const []);
    when(() => language.nativeLanguage)
        .thenReturn(const Language(code: 'en', name: 'English'));
    when(() => settings.usePixelFont).thenReturn(true);
  });

  Future<void> play(WidgetTester tester, String toy) async {
    final router = GoRouter(routes: [
      // Inside a Scaffold, as the navigation shell puts it: the home screen
      // needs a bounded height to lay its scene out in.
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: HomeScreen()),
      ),
      GoRoute(
        path: '/play-catch',
        name: 'play_catch',
        builder: (_, __) => const PlayCatchScreen(),
      ),
      GoRoute(
        path: '/play-bubble-bath',
        name: 'play_bubble_bath',
        builder: (_, __) => const BubbleBathScreen(),
      ),
      GoRoute(
        path: '/play-pounce',
        name: 'play_pounce',
        builder: (_, __) => const PounceScreen(),
      ),
      GoRoute(
        path: '/play-pond-hop',
        name: 'play_pond_hop',
        builder: (_, __) => const PondHopScreen(),
      ),
      GoRoute(
        path: '/play-fetch-words',
        name: 'play_fetch_words',
        builder: (_, __) => const FetchWordsScreen(),
      ),
    ]);
    await pumpAppWithRouter(
      tester,
      router,
      userProvider: user,
      dailyRewardProvider: dailyReward,
      characterProvider: character,
      languageProvider: language,
      settingsProvider: settings,
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byType(ToyChest));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ToyChestPicker), findsOneWidget);

    await tester.tap(find.text(toy));
    // Long enough for a game that was going to close itself to have done so.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(ToyChestPicker), findsNothing);
  }

  testWidgets('the ball in the chest starts a game of catch that stays open',
      (tester) async {
    when(() => language.targetLanguage)
        .thenReturn(const Language(code: 'es', name: 'Spanish'));

    await play(tester, 'Play catch');

    expect(find.byType(PlayCatchScreen), findsOneWidget);
  });

  testWidgets('with no language chosen yet, catch still plays',
      (tester) async {
    when(() => language.targetLanguage).thenReturn(null);

    await play(tester, 'Play catch');

    expect(find.byType(PlayCatchScreen), findsOneWidget);
  });

  testWidgets('with the same language on both sides, catch still plays',
      (tester) async {
    when(() => language.targetLanguage)
        .thenReturn(const Language(code: 'en', name: 'English'));

    await play(tester, 'Play catch');

    expect(find.byType(PlayCatchScreen), findsOneWidget);
  });

  // Every other toy, on the pair that leaves the games the least to work
  // with — the same language both sides — so each has to fall back and still
  // stay open.
  for (final (toy, screen) in [
    ('Bubble bath', BubbleBathScreen),
    ('Pounce', PounceScreen),
    ('Pond hop', PondHopScreen),
    ('Fetch the words', FetchWordsScreen),
  ]) {
    testWidgets('$toy starts from the chest and stays open', (tester) async {
      when(() => language.targetLanguage)
          .thenReturn(const Language(code: 'en', name: 'English'));

      await play(tester, toy);

      expect(find.byType(screen), findsOneWidget);
    });
  }
}
