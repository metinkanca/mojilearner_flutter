import 'package:mojilearner_flutter/constants/ads.dart';
import 'package:mojilearner_flutter/services/ads_service.dart';

/// Stands in for AdMob.
///
/// Uses the `AdsService.test()` hook rather than a mocktail mock, because
/// every screen reaches the service through `AdsService.I` — a static — and
/// the point is to make sure nothing under test ever touches the real plugin.
/// There is no AdMob behind the test binder, so an un-faked call would throw
/// or, worse, hang on a platform channel that never answers.
///
/// Defaults to the quietest possible behaviour: not initialised, no ad
/// loaded, so the offer stays hidden and the interstitial hook is a no-op.
/// Tests that want to exercise an ad opt in explicitly.
class FakeAdsService extends AdsService {
  FakeAdsService({
    this.initializes = false,
    this.rewardedReady = false,
    this.rewardEarned = true,
    this.interstitialShows = true,
  }) : super.test();

  /// Whether [initialize] reports success.
  final bool initializes;

  /// Whether a rewarded ad is loaded and can be shown.
  bool rewardedReady;

  /// Whether the player watches far enough through to earn the reward.
  bool rewardEarned;

  /// Whether an interstitial actually appears when asked for.
  bool interstitialShows;

  int rewardedShowCount = 0;
  int interstitialShowCount = 0;
  int rewardedLoadCount = 0;

  /// The last age treatment applied, for the age-gate tests.
  AdAudience? lastAudience;

  @override
  bool get isRewardedReady => rewardedReady;

  @override
  Future<bool> initialize({AdAudience audience = AdAudience.unknown}) async {
    lastAudience = audience;
    return initializes;
  }

  @override
  Future<void> applyAudience(AdAudience audience) async {
    lastAudience = audience;
  }

  @override
  Future<bool> loadRewarded() async {
    rewardedLoadCount++;
    return rewardedReady;
  }

  @override
  Future<bool> showRewarded() async {
    rewardedShowCount++;
    return rewardEarned;
  }

  @override
  Future<bool> loadInterstitial() async => true;

  @override
  Future<bool> showInterstitial() async {
    interstitialShowCount++;
    return interstitialShows;
  }
}
