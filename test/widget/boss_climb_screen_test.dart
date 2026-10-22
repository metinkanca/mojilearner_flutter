import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/boss_trial/climb_map.dart';
import 'package:mojilearner_flutter/components/boss_trial/trial_boss.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/router.dart'
    show bossFightFor, createRouter;
import 'package:mojilearner_flutter/screens/boss_climb_screen.dart';
import 'package:mojilearner_flutter/screens/boss_trial_screen.dart';
import 'package:mojilearner_flutter/utils/boss_trial.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';
import '../helpers/test_fixtures.dart';

/// The climb up to the bosses: six floors, the first at the bottom, a stop a
/// level, and a tap on a stop taking the player to that level's fight.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Finder stop(int level) => find.byKey(ValueKey('climb-stop-$level'));

  /// Lets a page arrive or leave: the route is applied on the next frame, and
  /// then the page slides, over about a second. The fight's own clock never
  /// lets pumpAndSettle finish.
  Future<void> turnPage(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  /// Scrolls up the map until [finder] is on screen: climbing.
  Future<void> climbTo(WidgetTester tester, Finder finder) async {
    await tester.dragUntilVisible(
      finder,
      find.byType(ListView),
      const Offset(0, 300),
    );
    await tester.pump();
  }

  group('the map', () {
    Future<List<(TrialBoss, int)>> pumpMap(
      WidgetTester tester, {
      int playerLevel = 1,
    }) async {
      final taps = <(TrialBoss, int)>[];
      await pumpApp(
        tester,
        ClimbMap(
          playerLevel: playerLevel,
          onStop: (boss, step) => taps.add((boss, step)),
        ),
      );
      await tester.pump();
      return taps;
    }

    testWidgets('opens at the bottom, on the first boss\'s floor',
        (tester) async {
      await pumpMap(tester);

      // Its five levels: Mossback's four openings, then the finale.
      for (final level in [1, 2, 3, 4, 5]) {
        expect(stop(level), findsOneWidget, reason: 'level $level');
      }
      expect(find.text('CATCH'), findsOneWidget);
      expect(find.text('SHELLS'), findsOneWidget);
      expect(find.text('PEBBLES'), findsOneWidget);
      expect(find.text('STONES'), findsOneWidget);
      expect(find.text('FINALE'), findsOneWidget);

      // Level 1 is the lowest thing on the map, and the way goes up from it.
      expect(tester.getCenter(stop(1)).dy,
          greaterThan(tester.getCenter(stop(5)).dy));
      // The last boss is far above, not drawn yet.
      expect(stop(30), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('names each floor for its boss, from the first up',
        (tester) async {
      await pumpMap(tester);
      expect(find.text('MOSSBACK'), findsOneWidget);
      expect(find.text('LEVELS 1–5'), findsOneWidget);
      // Floors are built as they are climbed to, not all at once.
      expect(find.text('PYREWING'), findsNothing);

      await climbTo(tester, stop(30));
      expect(find.text('PYREWING'), findsOneWidget);
      expect(find.text('LEVELS 26–30'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('flags the player\'s own level and no other', (tester) async {
      await pumpMap(tester, playerLevel: 1);
      expect(find.text('YOU'), findsOneWidget);

      await pumpMap(tester, playerLevel: 7);
      // Level 7 is on the second floor, above the first.
      expect(find.text('YOU'), findsNothing);
      await climbTo(tester, stop(7));
      expect(find.text('YOU'), findsOneWidget);
      expect(
        find.descendant(of: stop(7), matching: find.text('YOU')),
        findsOneWidget,
        reason: 'it is on level 7\'s own stop',
      );
    });

    testWidgets('a tap says which boss, and which of its levels',
        (tester) async {
      final taps = await pumpMap(tester);

      await tester.tap(stop(3));
      expect(taps, [(TrialBosses.mossback, 2)]);

      // Levels on the floors above are the next bosses', counted from their
      // own first: 13 is the witch's third opening.
      await climbTo(tester, stop(13));
      await tester.tap(stop(13));
      expect(taps.last, (TrialBosses.witch, 2));

      // The finale of a floor is the level the boss is named for.
      await climbTo(tester, stop(30));
      await tester.tap(stop(30));
      expect(taps.last, (TrialBosses.dragon, 4));
    });

    testWidgets('the name beside a stop can be tapped too', (tester) async {
      final taps = await pumpMap(tester);
      await tester.tap(find.text('SHELLS'));
      expect(taps, [(TrialBosses.mossback, 1)]);
    });
  });

  group('the screen', () {
    late MockUserProvider user;
    late MockCharacterProvider character;
    late MockLanguageProvider language;

    setUp(() {
      user = MockUserProvider();
      character = MockCharacterProvider();
      language = MockLanguageProvider();
      when(() => user.stats).thenReturn(TestFixtures.buildUserStats(level: 1));
      when(() => character.currentCharacterType).thenReturn('cat');
      when(() => language.targetLanguage)
          .thenReturn(const Language(code: 'es', name: 'Spanish'));
      when(() => language.nativeLanguage)
          .thenReturn(const Language(code: 'en', name: 'English'));
    });

    /// The two routes the app has for it: the climb, and a fight under it.
    GoRouter climbRouter() => GoRouter(
          initialLocation: '/boss-trial',
          routes: [
            GoRoute(path: '/', builder: (_, __) => const Text('home')),
            GoRoute(
              path: '/boss-trial',
              builder: (_, __) => const BossClimbScreen(),
              routes: [
                GoRoute(
                  path: 'fight/:boss/:step',
                  builder: (_, state) => bossFightFor(state.pathParameters),
                ),
              ],
            ),
          ],
        );

    Future<void> pumpClimb(WidgetTester tester) async {
      await pumpAppWithRouter(
        tester,
        climbRouter(),
        userProvider: user,
        characterProvider: character,
        languageProvider: language,
        vocabProvider: VocabProvider(),
      );
      await tester.pump();
    }

    testWidgets('opens on the climb, not on a fight', (tester) async {
      await pumpClimb(tester);

      expect(stop(1), findsOneWidget);
      expect(find.text('START TRIAL'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reads the player\'s level off their stats', (tester) async {
      when(() => user.stats).thenReturn(TestFixtures.buildUserStats(level: 3));
      await pumpClimb(tester);
      expect(
        find.descendant(of: stop(3), matching: find.text('YOU')),
        findsOneWidget,
      );
    });

    testWidgets('a level past the last is still the last', (tester) async {
      when(() => user.stats).thenReturn(TestFixtures.buildUserStats(level: 99));
      await pumpClimb(tester);
      await climbTo(tester, stop(30));
      expect(
        find.descendant(of: stop(30), matching: find.text('YOU')),
        findsOneWidget,
      );
    });

    testWidgets('a stop opens that level\'s fight, with nothing to pick',
        (tester) async {
      when(() => user.stats).thenReturn(TestFixtures.buildUserStats(level: 4));
      await pumpClimb(tester);

      await tester.tap(stop(4));
      await turnPage(tester);

      // Level 4 is Mossback's fourth opening, the stepping stones.
      expect(find.text('LEVEL 4 · STONES'), findsOneWidget);
      expect(find.text('START TRIAL'), findsOneWidget);
      // The climb chose the boss and the level, so the intro's own pickers
      // are gone.
      expect(find.text('LV 5\nMOSSBACK'), findsNothing);
      expect(find.textContaining('PICK ONE TO TRY'), findsNothing);
    });

    testWidgets('a stop above the player\'s level stays shut', (tester) async {
      when(() => user.stats).thenReturn(TestFixtures.buildUserStats(level: 3));
      await pumpClimb(tester);

      await tester.tap(stop(4));
      await turnPage(tester);

      expect(find.text('Reach level 4 to fight this.'), findsOneWidget);
      expect(find.text('START TRIAL'), findsNothing);
      expect(stop(4), findsOneWidget, reason: 'still on the climb');
    });

    test('a stop is open from the player\'s level up, finale included', () {
      expect(BossClimbScreen.isOpen(TrialBosses.mossback, 2, 3), isTrue);
      expect(BossClimbScreen.isOpen(TrialBosses.mossback, 2, 2), isFalse);
      // The finale is the level the boss is named for.
      expect(BossClimbScreen.isOpen(TrialBosses.mossback, 4, 4), isFalse);
      expect(BossClimbScreen.isOpen(TrialBosses.mossback, 4, 5), isTrue);
    });

    testWidgets('leaving a fight comes back to the climb', (tester) async {
      when(() => user.stats).thenReturn(TestFixtures.buildUserStats(level: 2));
      await pumpClimb(tester);
      await tester.tap(stop(2));
      await turnPage(tester);
      expect(find.text('START TRIAL'), findsOneWidget);

      await tester.tap(find.text('X'));
      await turnPage(tester);

      expect(find.text('START TRIAL'), findsNothing);
      expect(stop(2), findsOneWidget);
    });

    testWidgets('the back button on the climb leaves it', (tester) async {
      await pumpClimb(tester);
      await tester.tap(find.text('<'));
      await turnPage(tester);
      expect(find.text('home'), findsOneWidget);
    });
  });

  group('the fight route', () {
    test('names a boss by its id, and one of its levels', () {
      final fight = bossFightFor({'boss': 'sphinx', 'step': '3'});
      expect(fight.boss, TrialBosses.sphinx);
      expect(fight.step, 3);
      expect(fight.picker, isFalse);
    });

    test('falls back to the first boss and its first level', () {
      final fight = bossFightFor({'boss': 'nobody', 'step': 'x'});
      expect(fight.boss, TrialBosses.mossback);
      expect(fight.step, 0);
    });

    test('keeps a step inside the boss\'s five levels', () {
      expect(bossFightFor({'boss': 'witch', 'step': '99'}).step, 4);
      expect(bossFightFor({'boss': 'witch', 'step': '-2'}).step, 0);
    });

    test('is in the app\'s router, where the climb pushes to', () {
      final router = createRouter(refreshListenable: ValueNotifier(0));
      expect(router.namedLocation('boss_trial'), '/boss-trial');
      for (final boss in TrialBosses.all) {
        for (var step = 0; step < BossTrialRules.levelsPerBoss; step++) {
          expect(
            router.namedLocation('boss_fight', pathParameters: {
              'boss': boss.id,
              'step': '$step',
            }),
            BossClimbScreen.fightPath(boss, step),
          );
        }
      }
    });

    test('is the fight screen without its pickers', () {
      expect(const BossTrialScreen().picker, isTrue,
          reason: 'on its own, the screen still has them');
    });
  });
}
