import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kDebugMode, TargetPlatform;

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

  /// The model every AI call asks for.
  ///
  /// Not a 2.5 model: that family is closed to new API keys, and
  /// `generateContent` answers a new key with a 404 pointing at a 3.x
  /// replacement — while still listing the 2.5 models in `/v1beta/models`, so
  /// the listing is no proof of access.
  ///
  /// Among what is left, 3.1 Flash Lite is the cheapest ($0.25/$1.50 per M
  /// against $0.30/$2.50 for 3.5 Flash Lite) and, decisively, the only cheap
  /// one that still accepts `thinkingBudget: 0` — 3.5 and 3.6 reject it with
  /// a 400, which would break `AiGenerationConfig.structuredJson` and put
  /// reasoning tokens back on the bill at the output rate.
  ///
  /// It scored 16/16 usable on `server/tools/eval` across the language
  /// matrix, p50 1.57s. Cheaper models exist outside the Gemini family, but
  /// they are text-only — foreclosing speaking practice — and slower to first
  /// token, which every turn of a chat with the pet would feel.
  ///
  /// Switching is deliberately a build flag, not an edit:
  ///
  ///     flutter build apk --dart-define=AI_MODEL=deepseek/deepseek-v4-flash
  ///
  /// Whatever is set here must also appear in the proxy's `ALLOWED_MODELS`,
  /// or the request comes back rejected — that list is what stops a leaked
  /// proxy URL from being pointed at the most expensive model on offer.
  ///
  /// Unlike its neighbours this is a `const` field rather than a getter,
  /// because `AiService` uses it as a default parameter value and Dart
  /// requires those to be compile-time constants.
  static const String checkedInAiModel = 'gemini-3.1-flash-lite';

  static const String aiModel = String.fromEnvironment(
    'AI_MODEL',
    defaultValue: checkedInAiModel,
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

  // ==================== ADS ====================
  //
  // See `lib/constants/ads.dart` for what ads are allowed to do and what they
  // pay; this half is only about which AdMob inventory the build talks to.

  /// AdMob unit ids for the current platform.
  ///
  /// The checked-in defaults are **Google's official test units**, and that is
  /// deliberate rather than a placeholder left in by accident. A debug build
  /// serving live inventory means developers generating impressions and
  /// clicks on their own ads, which is what gets an AdMob account terminated.
  /// Test units are the only safe thing to fail back to, so the live ids
  /// arrive at build time and nowhere else:
  ///
  ///     flutter build appbundle \
  ///       --dart-define=ADMOB_REWARDED_ANDROID=ca-app-pub-XXX/YYY \
  ///       --dart-define=ADMOB_INTERSTITIAL_ANDROID=ca-app-pub-XXX/ZZZ
  ///
  /// Same reasoning as [aiProxyBaseUrl] above: a deployment's own identifiers
  /// stay out of the repo, and one source tree can produce a test build and a
  /// store build.
  static const String testRewardedAndroid =
      'ca-app-pub-3940256099942544/5224354917';
  static const String testRewardedIos =
      'ca-app-pub-3940256099942544/1712485313';
  static const String testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testInterstitialIos =
      'ca-app-pub-3940256099942544/4411468910';

  static const String _rewardedAndroid = String.fromEnvironment(
    'ADMOB_REWARDED_ANDROID',
    defaultValue: testRewardedAndroid,
  );

  static const String _rewardedIos = String.fromEnvironment(
    'ADMOB_REWARDED_IOS',
    defaultValue: testRewardedIos,
  );

  static const String _interstitialAndroid = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ANDROID',
    defaultValue: testInterstitialAndroid,
  );

  static const String _interstitialIos = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_IOS',
    defaultValue: testInterstitialIos,
  );

  static String get rewardedAdUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? _rewardedIos
          : _rewardedAndroid;

  static String get interstitialAdUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? _interstitialIos
          : _interstitialAndroid;

  /// True while the build is still pointed at Google's test inventory.
  ///
  /// Read by `AdsService`, which complains about it on a release build — the
  /// one case where the mistake is expensive and nobody is watching a debug
  /// console.
  static bool get usingTestAdUnits =>
      rewardedAdUnitId == testRewardedAndroid ||
      rewardedAdUnitId == testRewardedIos;

  /// Whether ads are switched on at all.
  ///
  /// On everywhere by default, and turned off for the test suite by
  /// `AdsService.debugOverride`. The define exists so a manual run can be
  /// made ad-free while looking at something else:
  ///
  ///     flutter run --dart-define=ADS_ENABLED=false
  static const bool adsEnabled = bool.fromEnvironment(
    'ADS_ENABLED',
    defaultValue: true,
  );
}
