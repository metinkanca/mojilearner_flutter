import 'package:flutter/foundation.dart'
    show
        defaultTargetPlatform,
        kDebugMode,
        kReleaseMode,
        TargetPlatform,
        visibleForTesting;

import 'coin_packs.dart';
import 'season_pass.dart';

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

  /// Where the privacy policy lives, passed as `--dart-define=PRIVACY_POLICY_URL=...`.
  ///
  /// Empty until there is a page to point at, and the profile link hides itself
  /// while it is: a link that opens nothing is worse than none. Play requires
  /// the same address in the store listing, so set both together.
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
  );

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

  /// Treat every accessory, every bought coat/eye colour and every scene as
  /// owned, so the whole wardrobe and every world can be tried on without
  /// buying anything or grinding bond stages.
  ///
  /// Scenes are in here despite the define's name because they are the other
  /// half of the same errand: showing the app off means dressing the pet *and*
  /// standing it somewhere. A second define for one more ownership gate would
  /// only make the command line longer for the same intent.
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

  /// Shrinks a day's AI allowance so the wall can be reached on purpose.
  ///
  /// Both walls otherwise take a real session to reach — three generated
  /// quizzes, or thirty messages — which makes the one screen that carries the
  /// upgrade offer the most tedious thing in the app to look at. Set either to
  /// 1 and the next quiz or the next message hits it:
  ///
  ///     flutter run --dart-define=AI_QUIZ_LIMIT=1 --dart-define=AI_MESSAGE_LIMIT=1
  ///
  /// Debug-gated for the same reason [unlockAllAccessories] is, and with the
  /// same care about the test suite: -1 means "no override", so a run that
  /// sets nothing gets exactly `EntitlementConstants` and the allowance tests
  /// are testing the shipping numbers.
  static int get aiQuizLimitOverride => _limitOverride('AI_QUIZ_LIMIT');

  static int get aiMessageLimitOverride => _limitOverride('AI_MESSAGE_LIMIT');

  /// Pretends the season pass is owned and this far along it, so the pass
  /// screen's real states can be looked at without a store product.
  ///
  /// The track is otherwise unreachable in a dev build: buying is what starts
  /// it, and there is nothing to buy until the store listing exists. Set this
  /// to the XP earned *since purchase* and every tier below it reads as
  /// reached — 0 shows a freshly bought pass, 2600 a half-finished one, 5000 a
  /// complete one:
  ///
  ///     flutter run --dart-define=SEASON_PASS_XP=2600
  ///
  /// Display only. It does not grant the pass, write anything to storage or
  /// mark a tier claimed, so no dev run can leave a real purchase record
  /// behind. Debug-gated for the same reason [unlockAllAccessories] is, and
  /// -1 means "no override" so the test suite sees the shipping behaviour.
  static int get seasonPassXpOverride {
    if (!kDebugMode) return -1;
    return const int.fromEnvironment('SEASON_PASS_XP', defaultValue: -1);
  }

  static int _limitOverride(String key) {
    if (!kDebugMode) return -1;
    return switch (key) {
      'AI_QUIZ_LIMIT' =>
        const int.fromEnvironment('AI_QUIZ_LIMIT', defaultValue: -1),
      'AI_MESSAGE_LIMIT' =>
        const int.fromEnvironment('AI_MESSAGE_LIMIT', defaultValue: -1),
      _ => -1,
    };
  }

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

  /// Whether the stock words and sentences (`boss_trial_words.dart`,
  /// `boss_trial_sentences.dart`) may top up what a game or a fight is played
  /// with.
  ///
  /// On while the app is being built and tested, so every screen has something
  /// to play with from the first run. **Off in a release build**: the stock is
  /// twelve everyday nouns and six sentences, a testing placeholder, and a game
  /// that falls back to them is practising words the player never learned. In a
  /// release the games use the player's own words and nothing else, and one
  /// that cannot be filled stays shut until it can.
  ///
  ///     flutter build apk --dart-define=STOCK_CONTENT=true   // to keep them
  static bool get stockContent =>
      debugStockContent ??
      (!kReleaseMode ||
          const bool.fromEnvironment('STOCK_CONTENT', defaultValue: false));

  /// Pins [stockContent] in a test, to see a release build's behaviour.
  @visibleForTesting
  static bool? debugStockContent;

  /// Show the boss-trial badge on the home screen, the only way into the
  /// trial prototype while it is being tuned. It opens the climb up through
  /// the six bosses' floors, where every level's fight can be tried.
  ///
  /// Milestone trials are not wired to the player's progress yet (the climb
  /// only marks where their level is), so without this the screens are
  /// unreachable. Fenced like the flags above: ANDed with [kDebugMode] so a
  /// release build can never show a half-built fight, and off by default so
  /// the home screen's layout tests measure the badge row players actually
  /// get.
  ///
  ///     flutter run --dart-define=BOSS_TRIAL=true
  static bool get bossTrial =>
      kDebugMode &&
      const bool.fromEnvironment(
        'BOSS_TRIAL',
        defaultValue: false,
      );

  /// Fill the Mistakes list and the review queue with a few sample English
  /// sentences explained in Turkish (`constants/sample_mistakes.dart`), so the
  /// screens can be seen with something on them.
  ///
  /// Fenced like the flags above: ANDed with [kDebugMode], and off by default
  /// so tests and release builds are unaffected. The samples are held in
  /// memory only and never written to storage, so they cannot reach a real
  /// save or the cloud copy of one.
  ///
  ///     flutter run --dart-define=SAMPLE_MISTAKES=true
  static bool get sampleMistakes =>
      kDebugMode &&
      const bool.fromEnvironment(
        'SAMPLE_MISTAKES',
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

  /// Store product ids for Mimikin Plus.
  ///
  /// Empty by default, and that emptiness is the switch: with no ids
  /// configured `PurchaseService` reports the store as unavailable and the
  /// paywall says subscriptions are not open rather than drawing a button
  /// that cannot charge. So a build made before the Play Console and App
  /// Store Connect products exist is honest about it instead of broken.
  ///
  ///     flutter build appbundle   ///       --dart-define=IAP_PLUS_MONTHLY=mimikin_plus_monthly   ///       --dart-define=IAP_PLUS_ANNUAL=mimikin_plus_annual
  ///
  /// Same reasoning as [aiProxyBaseUrl] and the AdMob units above: a
  /// deployment's own identifiers stay out of the repo.
  static const String plusMonthlyProductId = String.fromEnvironment(
    'IAP_PLUS_MONTHLY',
  );

  static const String plusAnnualProductId = String.fromEnvironment(
    'IAP_PLUS_ANNUAL',
  );

  /// Every Plus product id that is actually configured, in the order the
  /// paywall should offer them — annual second, so the cheaper commitment is
  /// read first and the better value is the one you land on.
  static List<String> get plusProductIds => [
        if (plusMonthlyProductId.isNotEmpty) plusMonthlyProductId,
        if (plusAnnualProductId.isNotEmpty) plusAnnualProductId,
      ];

  /// Whether this build has any subscription to sell.
  static bool get subscriptionsConfigured => plusProductIds.isNotEmpty;

  /// Every product the store should be asked about: subscriptions, passes and
  /// coin packs.
  ///
  /// Pass and coin-pack ids are NOT dart-defines like the two above. A pass id
  /// is recorded against every tier a player claims and has to survive for as
  /// long as their save does, and a coin pack's id decides how many coins a
  /// purchase is worth — so both belong in the catalogue beside the thing they
  /// sell (`constants/season_pass.dart`, `constants/coin_packs.dart`) rather
  /// than in a build flag that a later deployment could quietly point
  /// somewhere else.
  static List<String> get storeProductIds => [
        ...plusProductIds,
        for (final pass in seasonPasses) pass.productId,
        for (final pack in coinPacks) pack.productId,
      ];

  /// Whether there is anything at all to ask the store about.
  static bool get storeConfigured => storeProductIds.isNotEmpty;
}
