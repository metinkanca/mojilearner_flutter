import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/calibration_provider.dart';
import 'providers/character_provider.dart';
import 'providers/daily_reward_provider.dart';
import 'providers/language_provider.dart';
import 'providers/user_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/mistakes_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/vocab_provider.dart';
import 'providers/scenario_provider.dart';
import 'components/notification_scheduler.dart';
import 'router.dart';
import 'constants/theme.dart';
import 'l10n/app_localizations.dart';
import 'utils/fonts.dart';
import 'utils/security_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set fullscreen mode - hide system navigation bar
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [],
  );
  
  // This project currently uses GoogleFonts styles that are not bundled as local assets.
  // Keep runtime fetching enabled to avoid startup crashes on web.
  GoogleFonts.config.allowRuntimeFetching = true;

  // Restore persisted security events (fire-and-forget; logging works
  // without it and later log calls await it internally before persisting).
  SecurityLogger.init();
  
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => UserProvider()),
      ChangeNotifierProxyProvider<UserProvider, DailyRewardProvider>(
        create: (context) => DailyRewardProvider()
          ..updateDependencies(
              Provider.of<UserProvider>(context, listen: false)),
        update: (context, userProvider, dailyRewardProvider) =>
            (dailyRewardProvider ?? DailyRewardProvider())
              ..updateDependencies(userProvider),
      ),
      ChangeNotifierProvider(create: (_) => CalibrationProvider()),
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ChangeNotifierProxyProvider<UserProvider, CharacterProvider>(
        create: (context) {
          final characterProvider = CharacterProvider();
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          characterProvider.subscribeToRewards(userProvider);
          return characterProvider;
        },
        update: (context, userProvider, characterProvider) {
          characterProvider?.subscribeToRewards(userProvider);
          return characterProvider ?? CharacterProvider();
        },
      ),
      ChangeNotifierProvider(create: (_) => ChatProvider()),
      ChangeNotifierProvider(create: (_) => QuizProvider()),
      ChangeNotifierProvider(create: (_) => MistakesProvider()),
      // Learning memory. Subscribes to mistakes so every correction the AI
      // records becomes a scheduled review item, tagged with whichever
      // language is being studied at the time.
      ChangeNotifierProxyProvider2<MistakesProvider, LanguageProvider,
          VocabProvider>(
        create: (_) => VocabProvider()..load(),
        update: (context, mistakesProvider, languageProvider, vocabProvider) {
          final provider = vocabProvider ?? (VocabProvider()..load());
          provider.subscribeToMistakes(
            mistakesProvider,
            languageCode: () =>
                languageProvider.targetLanguage?.code ?? 'en',
          );
          return provider;
        },
      ),
      ChangeNotifierProvider(create: (_) => ScenarioProvider()..load()),
      ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
    ],
    child: const MojiLearnerApp(),
  ));
}

class MojiLearnerApp extends StatefulWidget {
  const MojiLearnerApp({super.key});

  @override
  State<MojiLearnerApp> createState() => _MojiLearnerAppState();
}

class _MojiLearnerAppState extends State<MojiLearnerApp> {
  late final Listenable _routerRefresh;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // The router must re-evaluate its redirect once these providers finish
    // reading persisted state, otherwise startup is decided while both are
    // still loading and the user never leaves the splash screen.
    _routerRefresh = Listenable.merge([
      Provider.of<UserProvider>(context, listen: false),
      Provider.of<CalibrationProvider>(context, listen: false),
    ]);
    _router = createRouter(refreshListenable: _routerRefresh);
  }

  // Strip underline decoration from every text style in the theme
  static TextStyle _noUnderline(TextStyle? style) =>
      (style ?? const TextStyle()).copyWith(decoration: TextDecoration.none);

  static ThemeData _buildTheme() {
    final base = GoogleFonts.interTextTheme();
    final clean = base.copyWith(
      displayLarge:  _noUnderline(base.displayLarge),
      displayMedium: _noUnderline(base.displayMedium),
      displaySmall:  _noUnderline(base.displaySmall),
      headlineLarge: _noUnderline(base.headlineLarge),
      headlineMedium:_noUnderline(base.headlineMedium),
      headlineSmall: _noUnderline(base.headlineSmall),
      titleLarge:    _noUnderline(base.titleLarge),
      titleMedium:   _noUnderline(base.titleMedium),
      titleSmall:    _noUnderline(base.titleSmall),
      bodyLarge:     _noUnderline(base.bodyLarge),
      bodyMedium:    _noUnderline(base.bodyMedium),
      bodySmall:     _noUnderline(base.bodySmall),
      labelLarge:    _noUnderline(base.labelLarge),
      labelMedium:   _noUnderline(base.labelMedium),
      labelSmall:    _noUnderline(base.labelSmall),
    ).apply(fontFamilyFallback: AppFonts.universalFallbackFamilies);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTheme.primary,
        // ignore: deprecated_member_use
        background: AppTheme.background,
      ),
      textTheme: clean,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final appLocale = Locale(languageProvider.nativeLanguage.code);
        AppFonts.setAppLocale(appLocale);
        return MaterialApp.router(
          title: 'MojiLearner',
          theme: _buildTheme(),
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            // Inside the builder so the scheduler sits below Localizations —
            // it needs the localized copy at the moment it schedules.
            return NotificationScheduler(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: appLocale,
        );
      },
    );
  }
}
