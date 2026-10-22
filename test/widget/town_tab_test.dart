import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/navigation_wrapper.dart';
import 'package:mojilearner_flutter/models/models.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/screens/quiz_screen.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// The town is a tab of the bottom bar, in the place the quiz's used to be, and
/// the quizzes are at the school in it: a quiz is left by the way it was come
/// in, back to the town.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the bar', () {
    GoRouter router(String at) => GoRouter(
          initialLocation: at,
          routes: [
            ShellRoute(
              builder: (context, state, child) =>
                  NavigationWrapper(child: child),
              routes: [
                GoRoute(path: '/', builder: (_, __) => const Text('home page')),
                GoRoute(
                    path: '/scenarios',
                    builder: (_, __) => const Text('town page')),
                GoRoute(path: '/quiz', builder: (_, __) => const Text('quiz')),
                GoRoute(path: '/shop', builder: (_, __) => const Text('shop')),
              ],
            ),
          ],
        );

    Future<void> settleBar(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('has a Town tab where the Quiz tab was, and no Quiz tab',
        (tester) async {
      await pumpAppWithRouter(tester, router('/'));
      await settleBar(tester);

      expect(find.text('TOWN'), findsOneWidget);
      expect(find.text('QUIZ'), findsNothing);
    });

    testWidgets('the Town tab opens the town', (tester) async {
      await pumpAppWithRouter(tester, router('/'));
      await settleBar(tester);

      await tester.tap(find.text('TOWN'));
      await tester.pumpAndSettle();

      expect(find.text('town page'), findsOneWidget);
    });

    testWidgets('stays up in the town, like it does in the shop, and the '
        'floating back arrow does not', (tester) async {
      await pumpAppWithRouter(tester, router('/scenarios'));
      await settleBar(tester);

      expect(find.byKey(const ValueKey('nav-bar')), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('is still hidden in a quiz, which has its own way out',
        (tester) async {
      await pumpAppWithRouter(tester, router('/quiz'));
      await settleBar(tester);

      expect(find.byKey(const ValueKey('nav-bar')), findsNothing);
    });
  });

  group('leaving a quiz', () {
    late MockUserProvider user;
    late MockCharacterProvider character;
    late MockLanguageProvider language;
    late MockSettingsProvider settings;
    late MockQuizProvider quiz;

    setUp(() {
      user = MockUserProvider();
      character = MockCharacterProvider();
      language = MockLanguageProvider();
      settings = MockSettingsProvider();
      quiz = MockQuizProvider();
      when(() => user.stats).thenReturn(UserStats());
      when(() => character.scaleReward(any())).thenReturn(3);
      when(() => language.targetLanguage)
          .thenReturn(const Language(code: 'es', name: 'Spanish'));
      when(() => settings.usePixelFont).thenReturn(true);
      when(() => quiz.hasSavedProgress).thenReturn(false);
      when(() => quiz.clearProgress()).thenAnswer((_) async {});
      when(() => quiz.saveProgress(any(), any())).thenAnswer((_) async {});
    });

    GoRouter router({String at = '/'}) => GoRouter(initialLocation: at, routes: [
          GoRoute(path: '/', builder: (_, __) => const Text('home page')),
          GoRoute(
              path: '/scenarios', builder: (_, __) => const Text('town page')),
          GoRoute(path: '/quiz', builder: (_, __) => const QuizScreen()),
        ]);

    Future<void> pumpAt(WidgetTester tester, GoRouter r) async {
      tester.view.physicalSize = const Size(1200, 2700);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpAppWithRouter(
        tester,
        r,
        userProvider: user,
        characterProvider: character,
        languageProvider: language,
        settingsProvider: settings,
        quizProvider: quiz,
      );
      await tester.pump();
    }

    Future<void> openPause(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pumpAndSettle();
    }

    testWidgets('Exit goes back to the town it was started from',
        (tester) async {
      final r = router(at: '/scenarios');
      await pumpAt(tester, r);
      unawaited(r.push('/quiz'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.pause), findsOneWidget);

      await openPause(tester);
      await tester.tap(find.text('EXIT'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.pause), findsNothing);
      expect(find.text('town page'), findsOneWidget,
          reason: 'what was under the quiz is what it returns to');
      expect(find.text('home page'), findsNothing);
    });

    testWidgets('Pause leaves the same way', (tester) async {
      final r = router(at: '/scenarios');
      await pumpAt(tester, r);
      unawaited(r.push('/quiz'));
      await tester.pumpAndSettle();

      await openPause(tester);
      await tester.tap(find.text('PAUSE'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.pause), findsNothing);
      expect(find.text('town page'), findsOneWidget);
      verify(() => quiz.saveProgress(any(), any())).called(1);
    });

    testWidgets('reached with nothing under it, it goes to the town, not home',
        (tester) async {
      final r = router();
      await pumpAt(tester, r);
      r.go('/quiz');
      await tester.pumpAndSettle();

      await openPause(tester);
      await tester.tap(find.text('EXIT'));
      await tester.pumpAndSettle();

      expect(find.text('town page'), findsOneWidget);
      expect(find.text('home page'), findsNothing);
    });
  });
}
