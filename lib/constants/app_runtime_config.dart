import 'package:flutter/foundation.dart' show kDebugMode;

/// Deployment-specific, non-secret runtime values.
///
/// Every value here can be supplied at build time with `--dart-define`, and
/// falls back to the checked-in default below it. Build-time is the preferred
/// route: it keeps a particular deployment's URL and token out of the repo,
/// and lets one source tree produce a staging and a production build.
///
///     flutter build apk \
///       --dart-define=AI_PROXY_BASE_URL=https://ai.example.com \
///       --dart-define=AI_PROXY_TOKEN=...
///
/// Note on `.env`: the app depends on flutter_dotenv, but nothing ever calls
/// `dotenv.load()`, so `dotenv.env` is always empty and a `.env` file
/// configures nothing. `--dart-define` or the constants here are the only
/// routes that work.
class AppRuntimeConfig {
  AppRuntimeConfig._();

  /// Base URL of the AI proxy (see `server/`), with no trailing slash.
  ///
  /// Empty means the app has no backend, which it treats as "AI unavailable"
  /// and handles with local fallbacks — it never falls back to calling the
  /// provider directly unless [allowClientAiFallback] is also on.
  static const String checkedInAiProxyBaseUrl = '';

  static String get aiProxyBaseUrl => const String.fromEnvironment(
        'AI_PROXY_BASE_URL',
        defaultValue: checkedInAiProxyBaseUrl,
      );

  /// Bearer token the proxy expects, when it is configured to require one.
  ///
  /// Not a secret in the sense the provider API key is: it ships inside the
  /// binary and can be extracted. What it buys is a credential that is scoped
  /// to this proxy and can be rotated without touching the provider key, so
  /// the blast radius of a leak is a revoked token rather than a stolen
  /// Gemini account. Left empty, no Authorization header is sent.
  static const String checkedInAiProxyToken = '';

  static String get aiProxyToken => const String.fromEnvironment(
        'AI_PROXY_TOKEN',
        defaultValue: checkedInAiProxyToken,
      );

  // Keep strict backend-only behavior by default.
  static const bool allowClientAiFallback = false;

  // Force onboarding/quiz routing to stay on online screens.
  // When AI is unavailable, screens should use local safe fallbacks.
  static const bool forceOnlineAssessment = true;

  /// The Web OAuth client id, passed to Google Sign-In as `serverClientId`.
  ///
  /// Not a secret: it identifies the project, ships in every build, and is
  /// already in `google-services.json` next to it. What it does is make the
  /// ID token Firebase gets back one that Firebase will actually accept —
  /// omitting it is the usual reason Android sign-in succeeds at the sheet
  /// and is then rejected at `signInWithCredential`.
  static const String checkedInGoogleServerClientId =
      '592310164564-qegmiaj3nqvgidj0nkfjmnt9nussu6t2.apps.googleusercontent.com';

  static String get googleServerClientId => const String.fromEnvironment(
        'GOOGLE_SERVER_CLIENT_ID',
        defaultValue: checkedInGoogleServerClientId,
      );

  /// The iOS OAuth client id. Apple platforms need their own; Android reads
  /// its client from the signing certificate instead and passes null here.
  static const String checkedInGoogleIosClientId =
      '592310164564-lo9fh9gl2o13up5tju1lcm8bvra3b4tp.apps.googleusercontent.com';

  static String get googleIosClientId => const String.fromEnvironment(
        'GOOGLE_IOS_CLIENT_ID',
        defaultValue: checkedInGoogleIosClientId,
      );

  /// Treat every accessory and every bought coat/eye colour as owned, so the
  /// whole wardrobe can be tried on without buying anything or grinding bond
  /// stages.
  ///
  /// A testing affordance, not a gameplay one, so it is doubly fenced:
  ///
  ///   * ANDed with [kDebugMode], so a release build ignores it even when the
  ///     define is passed and an unlocked wardrobe cannot ship; and
  ///   * off by default, because `flutter test` also runs in debug mode, and
  ///     defaulting it on would silently pass every gating test in
  ///     `accessory_ownership_test` and `character_provider_accessories_test`
  ///     by making the thing under test unconditionally true.
  ///
  /// Turn it on for a manual dress-up session with:
  ///
  ///     flutter run --dart-define=UNLOCK_ALL_ACCESSORIES=true
  static bool get unlockAllAccessories =>
      kDebugMode &&
      const bool.fromEnvironment(
        'UNLOCK_ALL_ACCESSORIES',
        defaultValue: false,
      );

  /// Keep the pet awake, so its face can actually be looked at.
  ///
  /// Without a configured AI proxy, `isAiAvailable` is false and the home
  /// screen's `_initAI` puts the pet into AI-issue sleep on every `initState`
  /// — which means every return from another screen re-sleeps it, and tapping
  /// cannot wake it because `wakeUp` early-returns in that mode. That makes
  /// eye-level art (glasses, masks) impossible to review on a build with no
  /// backend. This also suppresses the 22:00-07:00 night sleep, so a late
  /// session is not blocked either.
  ///
  /// Fenced exactly like [unlockAllAccessories]:
  ///
  ///   * ANDed with [kDebugMode], so a release build can never ship an
  ///     insomniac pet; and
  ///   * off by default, because `flutter test` also runs in debug mode and
  ///     defaulting it on would make the sleep tests vacuous.
  ///
  /// Turn it on for a manual art-review session with:
  ///
  ///     flutter run --dart-define=KEEP_PET_AWAKE=true
  static bool get keepPetAwake =>
      kDebugMode &&
      const bool.fromEnvironment(
        'KEEP_PET_AWAKE',
        defaultValue: false,
      );

  /// Start already onboarded, so a test run lands straight on the home screen.
  ///
  /// Onboarding completion lives in SharedPreferences, which is lost whenever
  /// the run starts from clean storage — a fresh emulator, a reinstall, or
  /// `-d chrome`, which launches a throwaway browser profile every time. That
  /// makes an art or UI change cost a full assessment flow to look at.
  ///
  /// This does not merely skip the router gate: it also seeds an in-memory
  /// calibrated proficiency (see `CalibrationProvider`), because the gate is
  /// satisfied by *either* flag, and bypassing it alone would land on a home
  /// screen belonging to a user with no calibrated language — a state normal
  /// play cannot produce. Nothing is written to storage, so real progress is
  /// never overwritten and the seed lasts exactly one run.
  ///
  /// Fenced like [unlockAllAccessories] and [keepPetAwake]: ANDed with
  /// [kDebugMode], and off by default so `flutter test` is unaffected.
  ///
  ///     flutter run --dart-define=SKIP_ONBOARDING=true
  static bool get skipOnboarding =>
      kDebugMode &&
      const bool.fromEnvironment(
        'SKIP_ONBOARDING',
        defaultValue: false,
      );
}
