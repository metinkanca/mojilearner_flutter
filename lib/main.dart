import 'package:firebase_core/firebase_core.dart';
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
import 'services/account_service.dart';
import 'services/cloud_sync.dart';
import 'services/firebase_account_backend.dart';
import 'services/firebase_sync_backend.dart';
import 'firebase_options.dart';

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

  // Awaited, and it has to be: a restore rewrites local storage, and every
  // provider below reads that storage once, at construction. Starting sync
  // after them would show the player their old save until the next launch.
  //
  // Every failure path here is silent by design. Firebase being unreachable,
  // misconfigured, or blocked is not a reason a pet game cannot open — the
  // local save is untouched and the app behaves exactly as it did before any
  // of this existed.
  await _startCloudSync();

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
      // Nullable on purpose: when cloud sync could not start there is no
      // account to attach anything to, and the screens that offer signing in
      // hide themselves rather than failing at the tap.
      Provider<AccountService?>.value(value: accountService),
    ],
    child: const MojiLearnerApp(),
  ));
}

/// Held so the flush timer and lifecycle observer outlive [main].
CloudSync? cloudSync;

/// Null when cloud sync did not start — there is then no uid to upgrade, so
/// nothing offers to sign in.
AccountService? accountService;

/// Brings up Firebase and pulls down a save if this device has none.
///
/// Never throws. The three things that can go wrong — Firebase failing to
/// initialise, sign-in being refused, the fetch timing out — all end with the
/// app running on local storage alone, which is what it did before cloud save
/// existed. A pet that opens is worth more than a pet that syncs.
Future<void> _startCloudSync() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final sync = CloudSync(backend: FirebaseSyncBackend());
    // Bounded: a slow network must not hold the splash screen open. Giving up
    // costs one missed restore, and the next launch tries again.
    await sync.start().timeout(const Duration(seconds: 8));
    cloudSync = sync;
    accountService = AccountService(
      backend: FirebaseAccountBackend(),
      sync: sync,
    );
  } catch (e) {
    debugPrint('⚠️ SYNC: cloud save unavailable, running local-only - $e');
  }
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
          title: 'Mimikin',
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
