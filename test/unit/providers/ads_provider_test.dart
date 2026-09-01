import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/ads.dart';
import 'package:mojilearner_flutter/constants/gold.dart';
import 'package:mojilearner_flutter/providers/ads_provider.dart';
import 'package:mojilearner_flutter/repositories/ads_repository.dart';
import 'package:mojilearner_flutter/services/ads_service.dart';

import '../../helpers/fake_ads.dart';
import '../../helpers/mock_providers.dart';

/// Keeps the ledger in memory, so the provider can be exercised without
/// SharedPreferences or a platform binding.
class _FakeAdsRepository extends AdsRepository {
  _FakeAdsRepository({AdLedger? ledger, this.birthYear})
      : stored = ledger ?? const AdLedger();

  AdLedger stored;
  int? birthYear;
  int saveCount = 0;

  @override
  Future<AdLedger> load() async => stored;

  @override
  Future<void> save(AdLedger ledger) async {
    stored = ledger;
    saveCount++;
  }

  @override
  Future<int?> loadBirthYear() async => birthYear;

  @override
  Future<void> saveBirthYear(int year) async => birthYear = year;
}

void main() {
  late FakeAdsService ads;

  setUp(() {
    ads = FakeAdsService(initializes: true, rewardedReady: true);
    AdsService.debugOverride = ads;
  });

  tearDown(() => AdsService.debugOverride = null);

  /// A provider for someone who has already studied today, which is the
  /// normal case and the only one where the offer appears at all.
  AdsProvider provider({AdsRepository? repository, bool learnedToday = true}) =>
      AdsProvider(repository: repository ?? _FakeAdsRepository())
        ..updateEligibility(isPremium: false, hasLearnedToday: learnedToday);

  group('watching a rewarded ad', () {
    test('pays the amount the offer promised', () async {
      final user = MockUserProvider();
      final ads = provider();

      final earned = await ads.watchRewarded(user);

      expect(earned, equals(AdsConstants.rewardedCoinLadder.first));
      expect(user.addedCoins, equals([AdsConstants.rewardedCoinLadder.first]));
    });

    test('pays through addCoins, never the learning ledger', () async {
      // The invariant this whole file exists for. Routing ad coins through
      // awardLearningGold would let watching an ad advance the daily taper,
      // and so quietly reduce what the next quiz paid.
      final user = MockUserProvider();
      final ads = provider();

      await ads.watchRewarded(user);

      expect(user.awardedGold, isEmpty);
      expect(user.goldFrom(GoldSource.quiz), isZero);
    });

    test('walks up the ladder across a day', () async {
      final user = MockUserProvider();
      final ads = provider();

      for (var i = 0; i < AdsConstants.rewardedDailyLimit; i++) {
        await ads.watchRewarded(user);
      }

      expect(user.addedCoins, equals(AdsConstants.rewardedCoinLadder));
    });

    test('stops once the day is used up', () async {
      final user = MockUserProvider();
      final ads = provider();

      for (var i = 0; i < AdsConstants.rewardedDailyLimit; i++) {
        await ads.watchRewarded(user);
      }
      final extra = await ads.watchRewarded(user);

      expect(extra, isZero);
      expect(user.addedCoins.length, equals(AdsConstants.rewardedDailyLimit));
      expect(ads.canOfferRewarded, isFalse);
    });

    test('an unearned reward costs the player nothing', () async {
      // Backing out halfway, or an ad that fails to show. Neither pays, and
      // neither may consume one of the five slots.
      ads.rewardEarned = false;
      final user = MockUserProvider();
      final adsProvider = provider();

      final earned = await adsProvider.watchRewarded(user);

      expect(earned, isZero);
      expect(user.addedCoins, isEmpty);
      expect(adsProvider.rewardedRemaining,
          equals(AdsConstants.rewardedDailyLimit));
    });

    test('an unearned reward is not persisted', () async {
      ads.rewardEarned = false;
      final repository = _FakeAdsRepository();
      final adsProvider = provider(repository: repository);

      await adsProvider.watchRewarded(MockUserProvider());

      expect(repository.saveCount, isZero);
    });

    test('the offer hides while an ad is on screen', () async {
      final ads = provider();
      var offeredDuringAd = true;

      ads.addListener(() {
        if (ads.isWatchingRewarded) offeredDuringAd = ads.canOfferRewarded;
      });

      await ads.watchRewarded(MockUserProvider());

      expect(offeredDuringAd, isFalse);
    });

    test('is not offered when no ad has loaded', () async {
      ads.rewardedReady = false;

      expect(provider().canOfferRewarded, isFalse);
    });
  });

  /// The rule that keeps ads a top-up rather than a substitute for study.
  /// Without it, five ads a day pay more than a casual player earns from a
  /// real session, and someone who never opens a quiz can buy the whole
  /// purchasable catalogue in about four months. See `gold.dart`.
  group('ads have to be earned by learning first', () {
    test('nothing is offered to a player who has not studied today', () {
      expect(provider(learnedToday: false).canOfferRewarded, isFalse);
    });

    test('the offer appears as soon as they do', () {
      final adsProvider = provider(learnedToday: false);

      adsProvider.updateEligibility(isPremium: false, hasLearnedToday: true);

      expect(adsProvider.canOfferRewarded, isTrue);
    });

    test('no inventory is even fetched for a player who has not', () async {
      await provider(learnedToday: false).prepareRewarded();

      expect(ads.rewardedLoadCount, isZero);
    });

    test('a day of learning is read straight off the user', () {
      final user = MockUserProvider();
      final adsProvider = provider(learnedToday: false)..updateFromUser(user);

      expect(adsProvider.canOfferRewarded, isFalse);

      // One quiz is enough; the gate asks whether they studied, not how much.
      user.awardLearningGold(6, GoldSource.quiz);
      adsProvider.updateFromUser(user);

      expect(adsProvider.canOfferRewarded, isTrue);
    });

    test('interstitials are not gated on it', () async {
      // They follow a finished quiz or scenario, so the learning has by
      // definition just happened -- and unlike the rewarded offer they are
      // not a coin source, so there is nothing here to game.
      expect(
        await provider(learnedToday: false).maybeShowInterstitial(),
        isTrue,
      );
    });
  });

  group('the interstitial', () {
    test('shows the first time and then holds off for an hour', () async {
      final adsProvider = provider();

      expect(await adsProvider.maybeShowInterstitial(), isTrue);
      expect(await adsProvider.maybeShowInterstitial(), isFalse);
      expect(ads.interstitialShowCount, equals(1));
    });

    test('is suppressed for a member', () async {
      final adsProvider = provider()
        ..updateEligibility(isPremium: true, hasLearnedToday: true);

      expect(await adsProvider.maybeShowInterstitial(), isFalse);
      expect(ads.interstitialShowCount, isZero);
    });

    test('leaves a member their rewarded ads', () async {
      final user = MockUserProvider();
      final adsProvider = provider()
        ..updateEligibility(isPremium: true, hasLearnedToday: true);

      final earned = await adsProvider.watchRewarded(user);

      expect(earned, equals(AdsConstants.rewardedCoinLadder.first));
    });

    test('an ad that never appeared does not start the cooldown', () async {
      // Otherwise a player on a poor connection drifts into seeing none at
      // all: every failed show would buy another hour of silence.
      ads.interstitialShows = false;
      final adsProvider = provider();

      expect(await adsProvider.maybeShowInterstitial(), isFalse);

      ads.interstitialShows = true;
      expect(await adsProvider.maybeShowInterstitial(), isTrue);
    });
  });

  group('the age answer', () {
    test('is unknown until the player gives one', () async {
      final adsProvider = provider();
      await adsProvider.load();

      expect(adsProvider.needsBirthYear, isTrue);
      expect(adsProvider.audience, equals(AdAudience.unknown));
    });

    test('an adult year lifts the restricted treatment', () async {
      final adsProvider = provider();

      await adsProvider.setBirthYear(DateTime.now().year - 30);

      expect(adsProvider.audience, equals(AdAudience.general));
      expect(ads.lastAudience, equals(AdAudience.general));
    });

    test('a child year keeps it', () async {
      final adsProvider = provider();

      await adsProvider.setBirthYear(DateTime.now().year - 8);

      expect(adsProvider.audience, equals(AdAudience.child));
      expect(ads.lastAudience, equals(AdAudience.child));
    });

    test('is remembered, so the question is asked once', () async {
      final repository = _FakeAdsRepository();
      await provider(repository: repository)
          .setBirthYear(DateTime.now().year - 30);

      final relaunched = provider(repository: repository);
      await relaunched.load();

      expect(relaunched.needsBirthYear, isFalse);
      expect(relaunched.audience, equals(AdAudience.general));
    });

    test('is carried into the SDK on bootstrap', () async {
      final repository = _FakeAdsRepository(
        birthYear: DateTime.now().year - 30,
      );
      final adsProvider = provider(repository: repository);
      await adsProvider.load();

      await adsProvider.bootstrap();

      expect(ads.lastAudience, equals(AdAudience.general));
    });
  });

  group('the stored ledger', () {
    test('is picked up on load', () async {
      final repository = _FakeAdsRepository(
        ledger: AdLedger(day: DateTime.now(), rewardedWatchedToday: 2),
      );
      final adsProvider = provider(repository: repository);

      await adsProvider.load();

      expect(adsProvider.rewardedRemaining,
          equals(AdsConstants.rewardedDailyLimit - 2));
    });

    test('a yesterday ledger is rolled over on load', () async {
      final repository = _FakeAdsRepository(
        ledger: AdLedger(
          day: DateTime.now().subtract(const Duration(days: 1)),
          rewardedWatchedToday: AdsConstants.rewardedDailyLimit,
        ),
      );
      final adsProvider = provider(repository: repository);

      await adsProvider.load();

      expect(adsProvider.rewardedRemaining,
          equals(AdsConstants.rewardedDailyLimit));
    });
  });
}
