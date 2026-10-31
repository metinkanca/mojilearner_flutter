import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
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
import 'providers/boss_progress_provider.dart';
import 'providers/premium_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/mistakes_provider.dart';
import 'providers/ads_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/vocab_provider.dart';
import 'providers/scenario_provider.dart';
import 'providers/tutorial_provider.dart';
import 'components/character_sprite.dart' show warmPetArt;
import 'components/notification_scheduler.dart';
import 'components/tutorial/tutorial_scope.dart';
import 'router.dart';
import 'constants/theme.dart';
import 'l10n/app_localizations.dart';
import 'utils/fonts.dart';
import 'utils/security_logger.dart';
import 'services/account_service.dart';
import 'services/ai_service.dart';
import 'services/cloud_sync.dart';
import 'services/data_eraser.dart';
import 'components/app_restart.dart';
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
  //
  // Except for a returning player. A device that already holds a save never has
  // one restored over it, so nothing the providers read can change under them,
  // and waiting on the network (up to 8 seconds on a bad connection) would only
  // keep a splash screen up. Those open at once and sync behind the first frame.
  if (await CloudSync.hasLocalSave()) {
    cloudStartup = _startCloudSync();
  } else {
    await (cloudStartup = _startCloudSync());
  }

  // AppRestart: Reset App and Delete Account wipe storage, and the providers
  // below only read it when they are created, so those flows rebuild this tree.
  runApp(AppRestart(child: MultiProvider(
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
          characterProvider.updateFromUser(userProvider);
          return characterProvider;
        },
        update: (context, userProvider, characterProvider) {
          characterProvider?.subscribeToRewards(userProvider);
          characterProvider?.updateFromUser(userProvider);
          return characterProvider ?? CharacterProvider();
        },
      ),
      ChangeNotifierProvider(create: (_) => ChatProvider()),
      ChangeNotifierProvider(create: (_) => QuizProvider()),
      ChangeNotifierProvider(create: (_) => MistakesProvider()..loadMistakes()),
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
      // Which boss levels have been cleared, so each pays once.
      ChangeNotifierProvider(create: (_) => BossProgressProvider()..load()),
      ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
      // Which per-page tours have already been offered. Eager, like
      // settings: the first screen asks about its tour on the first
      // frame, and a late answer would ask a player who said no once.
      ChangeNotifierProvider(create: (_) => TutorialProvider()..load()),
      // Ads. Proxied off UserProvider for the membership flag, which is the
      // only thing that suppresses an interstitial — see `constants/ads.dart`.
      ChangeNotifierProxyProvider<UserProvider, AdsProvider>(
        create: (context) => AdsProvider()
          ..load()
          ..updateFromUser(
              Provider.of<UserProvider>(context, listen: false)),
        update: (context, userProvider, adsProvider) =>
            (adsProvider ?? (AdsProvider()..load()))
              ..updateFromUser(userProvider),
      ),
      // The store connection. Proxied off UserProvider because the
      // entitlement it receives is written straight back there, and lifted to
      // app scope so a purchase that lands after the paywall closed is still
      // heard — see `providers/premium_provider.dart`.
      ChangeNotifierProxyProvider<UserProvider, PremiumProvider>(
        create: (_) => PremiumProvider(),
        update: (context, userProvider, premiumProvider) =>
            (premiumProvider ?? PremiumProvider())..attach(userProvider),
      ),
      // Nullable on purpose: when cloud sync could not start there is no
      // account to attach anything to, and the screens that offer signing in
      // hide themselves rather than failing at the tap.
      // A holder rather than the value: for a returning player sync is still
      // starting when this tree is built, and screens must see the account
      // appear when it does.
      ValueListenableProvider<AccountService?>.value(
        value: accountServiceHolder,
      ),
      // What Reset App and Delete Account call. Nullable for the same reason.
      Provider<DataEraser?>.value(
        value: DataEraser.lazy(
          sync: () => cloudSync,
          account: () => accountServiceHolder.value,
          ready: () => cloudStartup ?? Future<void>.value(),
        ),
      ),
    ],
    child: const MojiLearnerApp(),
  )));
}

/// Held so the flush timer and lifecycle observer outlive [main].
CloudSync? cloudSync;

/// Null when cloud sync did not start — there is then no uid to upgrade, so
/// nothing offers to sign in.
final ValueNotifier<AccountService?> accountServiceHolder = ValueNotifier(null);

/// Cloud sync coming up. Awaited before the first frame for a new install, and
/// left running behind it for a returning player.
Future<void>? cloudStartup;

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
    await _startAppCheck();
    final sync = CloudSync(backend: FirebaseSyncBackend());
    // Bounded: a slow network must not hold the splash screen open. Giving up
    // costs one missed restore, and the next launch tries again.
    await sync.start().timeout(const Duration(seconds: 8));
    cloudSync = sync;
    final account = AccountService(
      backend: FirebaseAccountBackend(),
      sync: sync,
    );
    accountServiceHolder.value = account;

    // Lets the proxy meter a day's model calls per account. Wired here rather
    // than read inside AiService so a build where cloud sync could not start
    // simply sends no identity and is metered anonymously — which is tighter
    // than a per-account allowance, not looser. See `services/ai_service.dart`.
    AiService.instance.idTokenResolver = account.currentIdToken;
  } catch (e) {
    debugPrint('⚠️ SYNC: cloud save unavailable, running local-only - $e');
  }
}

/// Proves to the AI proxy that requests come from a genuine build of this app,
/// on a real device, so a script cannot mint anonymous accounts to collect a
/// fresh daily allowance for each. See `server/src/appcheck.js`.
///
/// Never throws and never blocks the app: a device that cannot attest simply
/// sends no token, and what the proxy does about that is its own setting
/// (count it, or refuse it). Skipped on web, which is a preview target here and
/// would need a reCAPTCHA key of its own.
Future<void> _startAppCheck() async {
  if (kIsWeb) return;
  try {
    await FirebaseAppCheck.instance.activate(
      // The debug providers print a token to the log that has to be registered
      // in the Firebase console, which is how a debug build or an emulator is
      // allowed through without weakening the real check.
      providerAndroid: kReleaseMode
          ? const AndroidPlayIntegrityProvider()
          : const AndroidDebugProvider(),
      providerApple: kReleaseMode
          ? const AppleAppAttestWithDeviceCheckFallbackProvider()
          : const AppleDebugProvider(),
    );
    AiService.instance.appCheckTokenResolver = () async {
      try {
        return await FirebaseAppCheck.instance.getToken();
      } catch (_) {
        return null;
      }
    };
  } catch (e) {
    debugPrint('⚠️ APP CHECK: unavailable, requests go without a token - $e');
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
    _warmPet(Provider.of<CharacterProvider>(context, listen: false));
  }

  /// Reads and parses the pet's drawings while the splash is still up, so the
  /// first screen that shows the pet shows it whole instead of waiting for it.
  /// Starts when the saved pet has been read, since which pet, which coat and
  /// which hat it is are all in that save.
  void _warmPet(CharacterProvider character) {
    void warm() {
      if (!character.isLoaded) return;
      character.removeListener(warm);
      warmPetArt(character);
    }

    character.addListener(warm);
    warm();
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
                // Registers the showcase controller before any screen below
                // builds a coach mark against it. It renders its child
                // untouched — the overlay attaches itself to the router's
                // navigator, not to this position in the tree.
                child: TutorialScope(
                  child: child ?? const SizedBox.shrink(),
                ),
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
