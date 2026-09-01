import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:mojilearner_flutter/providers/user_provider.dart';
import 'package:mojilearner_flutter/providers/daily_reward_provider.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/chat_provider.dart';
import 'package:mojilearner_flutter/providers/quiz_provider.dart';
import 'package:mojilearner_flutter/providers/mistakes_provider.dart';
import 'package:mojilearner_flutter/providers/settings_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/providers/scenario_provider.dart';
import 'package:mojilearner_flutter/providers/calibration_provider.dart';
import 'package:mojilearner_flutter/providers/ads_provider.dart';
import 'package:mojilearner_flutter/services/ads_service.dart';
import 'package:mojilearner_flutter/l10n/app_localizations.dart';
import 'fake_ads.dart';
import 'mock_providers.dart';

/// The surface every layout test gets unless it asks for something else.
///
/// The default flutter_test surface is 800x600 — wider than any phone, which
/// is how a 16px overflow in the daily reward dialog and a 129px one in the
/// home screen top bar both stayed invisible. Tests that genuinely need room
/// (long scrolling lists, tablet layouts) pass [surfaceSize] explicitly.
const Size kHandsetSurface = Size(400, 844);

/// Helper function to wrap a widget with all necessary providers for testing
/// 
/// Usage:
/// ```dart
/// await pumpApp(
///   tester,
///   MyWidget(),
///   userProvider: mockUserProvider,
/// );
/// ```
Future<void> pumpApp(
  WidgetTester tester,
  Widget widget, {
  UserProvider? userProvider,
  DailyRewardProvider? dailyRewardProvider,
  CharacterProvider? characterProvider,
  LanguageProvider? languageProvider,
  ChatProvider? chatProvider,
  QuizProvider? quizProvider,
  MistakesProvider? mistakesProvider,
  SettingsProvider? settingsProvider,
  VocabProvider? vocabProvider,
  ScenarioProvider? scenarioProvider,
  CalibrationProvider? calibrationProvider,
  AdsProvider? adsProvider,
  /// Stands in for AdMob. Defaults to one that reports nothing loaded, so a
  /// screen carrying the free-coins offer simply does not show it and the
  /// post-quiz interstitial hook is a no-op. Tests about ads pass their own.
  FakeAdsService? adsService,
  /// Pins the app locale, for layouts that need checking against the
  /// longest translation rather than English. Null keeps the default.
  Locale? locale,
  /// The test surface to lay out on. Defaults to a handset — see
  /// [kHandsetSurface].
  Size surfaceSize = kHandsetSurface,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  // Restored rather than cleared, so a test that installed its own fake
  // before pumping keeps it, and nothing leaks into the next test.
  final previousAdsService = AdsService.debugOverride;
  AdsService.debugOverride =
      adsService ?? previousAdsService ?? FakeAdsService();
  addTearDown(() => AdsService.debugOverride = previousAdsService);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>.value(
          value: userProvider ?? MockUserProvider(),
        ),
        ChangeNotifierProvider<DailyRewardProvider>.value(
          value: dailyRewardProvider ?? MockDailyRewardProvider(),
        ),
        ChangeNotifierProvider<CharacterProvider>.value(
          value: characterProvider ?? MockCharacterProvider(),
        ),
        ChangeNotifierProvider<LanguageProvider>.value(
          value: languageProvider ?? MockLanguageProvider(),
        ),
        ChangeNotifierProvider<ChatProvider>.value(
          value: chatProvider ?? MockChatProvider(),
        ),
        ChangeNotifierProvider<QuizProvider>.value(
          value: quizProvider ?? MockQuizProvider(),
        ),
        ChangeNotifierProvider<MistakesProvider>.value(
          value: mistakesProvider ?? MockMistakesProvider(),
        ),
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider ?? MockSettingsProvider(),
        ),
        // A real (empty) VocabProvider rather than a mock: with no items its
        // queue is empty and nothing needs stubbing.
        ChangeNotifierProvider<VocabProvider>.value(
          value: vocabProvider ?? VocabProvider(),
        ),
        // Likewise a real (empty) ScenarioProvider — no progress, nothing to
        // stub.
        ChangeNotifierProvider<ScenarioProvider>.value(
          value: scenarioProvider ?? ScenarioProvider(),
        ),
        ChangeNotifierProvider<CalibrationProvider>.value(
          value: calibrationProvider ?? MockCalibrationProvider(),
        ),
        // Proxied off UserProvider exactly as `main.dart` does. The rewarded
        // offer is gated on whether anything has been learned today, and
        // that fact lives on the user — a plain .value provider here would
        // leave every screen test looking at a player who never studies.
        ChangeNotifierProxyProvider<UserProvider, AdsProvider>(
          create: (_) => adsProvider ?? AdsProvider(),
          update: (_, user, ads) =>
              (ads ?? adsProvider ?? AdsProvider())..updateFromUser(user),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: Scaffold(
          body: widget,
        ),
      ),
    ),
  );
}

/// Helper function to wrap a widget with providers and GoRouter for navigation testing
/// 
/// Usage:
/// ```dart
/// final router = GoRouter(
///   routes: [
///     GoRoute(path: '/', builder: (context, state) => HomeScreen()),
///   ],
/// );
/// await pumpAppWithRouter(tester, router);
/// ```
Future<void> pumpAppWithRouter(
  WidgetTester tester,
  GoRouter router, {
  UserProvider? userProvider,
  DailyRewardProvider? dailyRewardProvider,
  CharacterProvider? characterProvider,
  LanguageProvider? languageProvider,
  ChatProvider? chatProvider,
  QuizProvider? quizProvider,
  MistakesProvider? mistakesProvider,
  SettingsProvider? settingsProvider,
  VocabProvider? vocabProvider,
  ScenarioProvider? scenarioProvider,
  CalibrationProvider? calibrationProvider,
  AdsProvider? adsProvider,
  /// Stands in for AdMob. Defaults to one that reports nothing loaded, so a
  /// screen carrying the free-coins offer simply does not show it and the
  /// post-quiz interstitial hook is a no-op. Tests about ads pass their own.
  FakeAdsService? adsService,
  /// The test surface to lay out on. Defaults to a handset — see
  /// [kHandsetSurface].
  Size surfaceSize = kHandsetSurface,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  // Restored rather than cleared, so a test that installed its own fake
  // before pumping keeps it, and nothing leaks into the next test.
  final previousAdsService = AdsService.debugOverride;
  AdsService.debugOverride =
      adsService ?? previousAdsService ?? FakeAdsService();
  addTearDown(() => AdsService.debugOverride = previousAdsService);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>.value(
          value: userProvider ?? MockUserProvider(),
        ),
        ChangeNotifierProvider<DailyRewardProvider>.value(
          value: dailyRewardProvider ?? MockDailyRewardProvider(),
        ),
        ChangeNotifierProvider<CharacterProvider>.value(
          value: characterProvider ?? MockCharacterProvider(),
        ),
        ChangeNotifierProvider<LanguageProvider>.value(
          value: languageProvider ?? MockLanguageProvider(),
        ),
        ChangeNotifierProvider<ChatProvider>.value(
          value: chatProvider ?? MockChatProvider(),
        ),
        ChangeNotifierProvider<QuizProvider>.value(
          value: quizProvider ?? MockQuizProvider(),
        ),
        ChangeNotifierProvider<MistakesProvider>.value(
          value: mistakesProvider ?? MockMistakesProvider(),
        ),
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider ?? MockSettingsProvider(),
        ),
        // A real (empty) VocabProvider rather than a mock: with no items its
        // queue is empty and nothing needs stubbing.
        ChangeNotifierProvider<VocabProvider>.value(
          value: vocabProvider ?? VocabProvider(),
        ),
        // Likewise a real (empty) ScenarioProvider — no progress, nothing to
        // stub.
        ChangeNotifierProvider<ScenarioProvider>.value(
          value: scenarioProvider ?? ScenarioProvider(),
        ),
        ChangeNotifierProvider<CalibrationProvider>.value(
          value: calibrationProvider ?? MockCalibrationProvider(),
        ),
        // Proxied off UserProvider exactly as `main.dart` does. The rewarded
        // offer is gated on whether anything has been learned today, and
        // that fact lives on the user — a plain .value provider here would
        // leave every screen test looking at a player who never studies.
        ChangeNotifierProxyProvider<UserProvider, AdsProvider>(
          create: (_) => adsProvider ?? AdsProvider(),
          update: (_, user, ads) =>
              (ads ?? adsProvider ?? AdsProvider())..updateFromUser(user),
        ),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
}
