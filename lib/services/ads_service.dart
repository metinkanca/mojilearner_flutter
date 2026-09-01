import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/ads.dart';
import '../constants/app_runtime_config.dart';

/// Thin wrapper over `google_mobile_ads`.
///
/// Deliberately holds no policy: how many ads a day, what they pay, and
/// whether a membership suppresses them is `AdLedger`'s job in
/// `constants/ads.dart`, and deciding *when* to ask is `AdsProvider`'s. This
/// class only knows how to talk to AdMob, which is the part that cannot be
/// unit-tested anyway — the same split `NotificationService` has against
/// `NotificationPlanner`.
///
/// Every method swallows platform errors rather than throwing. A quiz result
/// screen must never fail because an ad server did.
class AdsService {
  AdsService._();

  /// Subclass hook for tests. Lets a fake stand in for the platform channel
  /// without pulling the plugin into a widget test — there is no AdMob behind
  /// the test binder, so an un-faked call would throw or hang.
  @visibleForTesting
  AdsService.test();

  static final AdsService instance = AdsService._();

  @visibleForTesting
  static AdsService? debugOverride;

  static AdsService get I => debugOverride ?? instance;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Whether ads may be requested at all right now.
  ///
  /// False until consent has been resolved, so no request can slip out ahead
  /// of the UMP form in a jurisdiction that requires one.
  bool _canRequestAds = false;
  bool get canRequestAds => _canRequestAds;

  RewardedAd? _rewarded;
  InterstitialAd? _interstitial;
  bool _loadingRewarded = false;
  bool _loadingInterstitial = false;

  /// Whether a rewarded ad is loaded and can be shown right now.
  ///
  /// Read by the UI so the offer is only advertised when it can be honoured:
  /// a "watch for coins" button that does nothing is worse than no button.
  bool get isRewardedReady => _rewarded != null;

  /// Initialises the SDK, after gathering consent.
  ///
  /// Safe to call repeatedly. Returns false when ads are unavailable, in
  /// which case every later call here is a harmless no-op and the UI simply
  /// never offers one.
  Future<bool> initialize({AdAudience audience = AdAudience.unknown}) async {
    if (!AppRuntimeConfig.adsEnabled) return false;
    if (_initialized) return true;

    if (kReleaseMode && AppRuntimeConfig.usingTestAdUnits) {
      // Loud on purpose. A release build on test units earns nothing at all,
      // and the symptom — ads that show perfectly well — looks like success.
      debugPrint('ADS: release build is still using Google test ad units');
    }

    try {
      await _gatherConsent(audience);
      await applyAudience(audience);
      await MobileAds.instance.initialize();
      _initialized = true;
      return true;
    } catch (e) {
      debugPrint('ADS: Initialization failed - $e');
      return false;
    }
  }

  /// Runs the UMP consent flow and records whether ads may be requested.
  ///
  /// The app ships 27 locales, so EU users are a certainty rather than an
  /// edge case, and requesting ads before this resolves is the thing the GDPR
  /// actually prohibits. A failure here fails closed: the cost of wrongly
  /// withholding an ad is a few pennies, and the cost of wrongly showing one
  /// is regulatory.
  ///
  /// The three steps have to happen in this order — ask the SDK what this
  /// user's jurisdiction requires, show the form if one is required, then
  /// read the verdict. Skipping to the verdict returns a stale cached answer
  /// from a previous session.
  Future<void> _gatherConsent(AdAudience audience) async {
    try {
      await _requestConsentInfoUpdate(audience);
      await _showConsentFormIfRequired();
    } catch (e) {
      debugPrint('ADS: Consent flow failed - $e');
    }

    try {
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
    } catch (e) {
      debugPrint('ADS: Consent status unavailable - $e');
      _canRequestAds = false;
    }
  }

  /// Wraps UMP's callback-style consent lookup in a future.
  ///
  /// [AdAudience.unknown] is tagged as under the age of consent alongside
  /// [AdAudience.child], for the same reason [applyAudience] does.
  Future<void> _requestConsentInfoUpdate(AdAudience audience) {
    final done = Completer<void>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(
        tagForUnderAgeOfConsent: audience != AdAudience.general,
      ),
      () {
        if (!done.isCompleted) done.complete();
      },
      (error) {
        debugPrint('ADS: Consent info update failed - $error');
        if (!done.isCompleted) done.complete();
      },
    );

    return done.future;
  }

  /// Shows the consent form when this user's jurisdiction requires one.
  Future<void> _showConsentFormIfRequired() {
    final dismissed = Completer<void>();

    unawaited(ConsentForm.loadAndShowConsentFormIfRequired((error) {
      if (error != null) {
        debugPrint('ADS: Consent form failed - $error');
      }
      if (!dismissed.isCompleted) dismissed.complete();
    }));

    return dismissed.future;
  }

  /// Applies the age treatment for [audience] to every later ad request.
  ///
  /// [AdAudience.unknown] is treated exactly like [AdAudience.child]: until
  /// the player has answered, the conservative request is the only lawful
  /// one. That costs some revenue on the ads served before the question is
  /// answered, which is the cheaper side of the mistake — the other side is a
  /// COPPA problem.
  Future<void> applyAudience(AdAudience audience) async {
    final restricted = audience != AdAudience.general;

    try {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          ageRestrictedTreatment: restricted
              ? AgeRestrictedTreatment.child
              : AgeRestrictedTreatment.unspecified,
          // G for a restricted audience; unspecified lets AdMob's own rating
          // apply for everyone else.
          maxAdContentRating: restricted
              ? MaxAdContentRating.g
              : MaxAdContentRating.unspecified,
        ),
      );
    } catch (e) {
      debugPrint('ADS: Request configuration failed - $e');
    }
  }

  /// Whether the SDK is in a state where a request is worth making.
  bool get _ready => _initialized && _canRequestAds;

  // ==================== REWARDED ====================

  /// Preloads a rewarded ad so the offer is ready when the player taps it.
  ///
  /// Called ahead of time — from the shop and the wardrobe — because a
  /// rewarded ad takes seconds to fetch, and a player who taps "watch for
  /// coins" and then waits on a blank screen assumes it is broken.
  ///
  /// Resolves when the ad has actually arrived (or failed), not merely when
  /// the request was posted — the UI reads [isRewardedReady] straight
  /// afterwards to decide whether to offer the button at all, so a future
  /// that completed early would make it permanently answer "not yet".
  Future<bool> loadRewarded() async {
    if (!_ready) return false;
    if (_rewarded != null) return true;
    if (_loadingRewarded) return false;
    _loadingRewarded = true;

    final loaded = Completer<bool>();

    try {
      await RewardedAd.load(
        adUnitId: AppRuntimeConfig.rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewarded = ad;
            _loadingRewarded = false;
            if (!loaded.isCompleted) loaded.complete(true);
          },
          onAdFailedToLoad: (error) {
            debugPrint('ADS: Rewarded failed to load - $error');
            _rewarded = null;
            _loadingRewarded = false;
            if (!loaded.isCompleted) loaded.complete(false);
          },
        ),
      );
      return await loaded.future;
    } catch (e) {
      debugPrint('ADS: Rewarded load threw - $e');
      _loadingRewarded = false;
      return false;
    }
  }

  /// Shows the loaded rewarded ad, resolving true only if the reward was
  /// actually earned.
  ///
  /// True means AdMob fired `onUserEarnedReward` — the player watched enough
  /// of it to be paid. Everything else, including backing out halfway and
  /// failing to show at all, resolves false, and the caller must then neither
  /// pay nor consume one of the day's slots. That is the whole contract of
  /// this method; see `AdsProvider.watchRewarded`.
  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) return false;

    // Cleared up front so a second tap during the ad cannot show the same
    // instance twice — an AdMob ad object is single-use.
    _rewarded = null;

    final earned = Completer<bool>();
    var didEarn = false;

    void finish() {
      if (!earned.isCompleted) earned.complete(didEarn);
      // Always queue the next one: whoever just watched an ad is the likeliest
      // person to want another.
      unawaited(loadRewarded());
    }

    try {
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          finish();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('ADS: Rewarded failed to show - $error');
          ad.dispose();
          finish();
        },
      );

      await ad.show(onUserEarnedReward: (_, __) => didEarn = true);
      return await earned.future;
    } catch (e) {
      debugPrint('ADS: Rewarded show threw - $e');
      finish();
      return false;
    }
  }

  // ==================== INTERSTITIAL ====================

  /// Preloads an interstitial. Called once at startup and after each one is
  /// shown, so a quiz result never waits on a fetch.
  Future<bool> loadInterstitial() async {
    if (!_ready) return false;
    if (_interstitial != null) return true;
    if (_loadingInterstitial) return false;
    _loadingInterstitial = true;

    final loaded = Completer<bool>();

    try {
      await InterstitialAd.load(
        adUnitId: AppRuntimeConfig.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitial = ad;
            _loadingInterstitial = false;
            if (!loaded.isCompleted) loaded.complete(true);
          },
          onAdFailedToLoad: (error) {
            debugPrint('ADS: Interstitial failed to load - $error');
            _interstitial = null;
            _loadingInterstitial = false;
            if (!loaded.isCompleted) loaded.complete(false);
          },
        ),
      );
      return await loaded.future;
    } catch (e) {
      debugPrint('ADS: Interstitial load threw - $e');
      _loadingInterstitial = false;
      return false;
    }
  }

  /// Shows a loaded interstitial, resolving true if one actually appeared.
  ///
  /// The return value is what the cooldown gets recorded against: an ad that
  /// never appeared must not start an hour of silence, or a player on a flaky
  /// connection would quietly stop seeing ads at all.
  Future<bool> showInterstitial() async {
    final ad = _interstitial;
    if (ad == null) {
      // Nothing to show, but this is the moment we found that out — get one
      // in flight for next time.
      unawaited(loadInterstitial());
      return false;
    }

    _interstitial = null;

    final shown = Completer<bool>();
    var didShow = false;

    void finish() {
      if (!shown.isCompleted) shown.complete(didShow);
      unawaited(loadInterstitial());
    }

    try {
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (_) => didShow = true,
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          finish();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('ADS: Interstitial failed to show - $error');
          ad.dispose();
          finish();
        },
      );

      await ad.show();
      return await shown.future;
    } catch (e) {
      debugPrint('ADS: Interstitial show threw - $e');
      finish();
      return false;
    }
  }
}
