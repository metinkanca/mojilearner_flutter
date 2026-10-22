import 'package:flutter/foundation.dart';

import '../constants/ads.dart';
import '../repositories/ads_repository.dart';
import '../services/ads_service.dart';
import 'user_provider.dart';

/// Owns the ad ledger and decides when an ad may actually be asked for.
///
/// The middle layer of the three the ad system is split into: [AdLedger] in
/// `constants/ads.dart` holds the rules and is pure, [AdsService] talks to
/// AdMob and holds no rules, and this joins them to the app's state — the
/// membership flag, the coin balance, and prefs.
class AdsProvider extends ChangeNotifier {
  AdsProvider({AdsRepository? repository})
      : _repository = repository ?? AdsRepository();

  final AdsRepository _repository;

  AdLedger _ledger = const AdLedger();

  /// The player's stated birth year, or null until they answer.
  int? _birthYear;

  /// Whether the player has a membership, pushed in from [UserProvider] by
  /// the proxy provider in `main.dart`. Suppresses interstitials and nothing
  /// else — see [AdLedger.canShowInterstitial].
  bool _isPremium = false;

  /// Whether the player has earned any learning coins today.
  ///
  /// Also pushed in from [UserProvider], and the thing that makes ads a
  /// *top-up* rather than a substitute. See [canOfferRewarded].
  bool _hasLearnedToday = false;

  /// True while a rewarded ad is on screen.
  ///
  /// A rewarded ad covers the app, but the button underneath it is still
  /// mounted; without this a queued second tap would try to show an ad that
  /// has already been consumed.
  bool _watchingRewarded = false;

  AdLedger get ledger => _ledger;
  bool get isWatchingRewarded => _watchingRewarded;

  /// The age treatment every ad request should carry.
  ///
  /// [AdAudience.unknown] until the player answers, which [AdsService] then
  /// treats exactly as it treats a child — the conservative default, and the
  /// only lawful one before the question has been asked.
  AdAudience get audience =>
      audienceForBirthYear(_birthYear, DateTime.now());

  /// Whether the age question still needs asking.
  bool get needsBirthYear => _birthYear == null;

  /// Coins the next rewarded ad would pay, or null when today's are used up.
  int? get nextRewardValue => _ledger.nextRewardValue;

  /// Rewarded ads left today.
  int get rewardedRemaining => _ledger.rewardedRemaining;

  /// Whether to show the "watch for coins" offer at all.
  ///
  /// Three conditions, and the interesting one is the first.
  ///
  /// **The player must have learned something today.** Without it the ladder
  /// quietly breaks the rule the whole economy is built on — that coins come
  /// from doing the content. Five ads a day pay 50 coins against a casual
  /// player's 20 from a real session, so an ungated offer would tell the
  /// marginal learner their study was worth less than their attention, and
  /// would let someone who never opens a quiz buy the entire purchasable
  /// catalogue in about four months instead of five years. Gating on the
  /// day's learning ledger keeps every coin of the reward while removing the
  /// player who was only ever going to watch. See `gold.dart`.
  ///
  /// Then the ordinary two: a slot left today, and an ad actually in hand —
  /// an offer that does nothing when tapped is worse than no offer.
  bool get canOfferRewarded =>
      _hasLearnedToday &&
      _ledger.hasRewardedLeft &&
      !_watchingRewarded &&
      AdsService.I.isRewardedReady;

  Future<void> load() async {
    _ledger = (await _repository.load()).rolledOver(DateTime.now());
    _birthYear = await _repository.loadBirthYear();
    notifyListeners();
  }

  /// Boots the SDK and gets the first ads in flight.
  ///
  /// Called once from the app shell rather than from `main`, because the UMP
  /// consent form is a native dialog and needs an activity on screen to
  /// appear over. Everything here is best-effort: with no consent, no
  /// network, or ads switched off, the loads quietly do nothing and the UI
  /// simply never offers one.
  Future<void> bootstrap() async {
    if (!await AdsService.I.initialize(audience: audience)) return;

    // Both formats are fetched ahead of use. An interstitial that starts
    // loading when the quiz ends arrives after the player has already moved
    // on, and a rewarded ad that is not in hand keeps its own offer hidden.
    await Future.wait([
      AdsService.I.loadRewarded(),
      AdsService.I.loadInterstitial(),
    ]);
    notifyListeners();
  }

  /// Records the player's stated birth year and re-tags every later request.
  ///
  /// Applied immediately rather than at the next launch: the ads served in
  /// this session should already reflect the answer just given.
  Future<void> setBirthYear(int year) async {
    _birthYear = year;
    await _repository.saveBirthYear(year);
    await AdsService.I.applyAudience(audience);
    notifyListeners();
  }

  /// Pushed in from the proxy provider whenever [UserProvider] changes.
  ///
  /// Both facts this needs from the user live there and change during play —
  /// the membership flag, and whether anything has been learned today — so
  /// they arrive together rather than through two paths that could disagree.
  void updateFromUser(UserProvider user) => updateEligibility(
        isPremium: user.isPremium,
        hasLearnedToday: user.learningGoldEarnedToday > 0,
      );

  /// The same, stated directly. Kept separate so the rules can be tested
  /// without standing up a [UserProvider].
  void updateEligibility({
    required bool isPremium,
    required bool hasLearnedToday,
  }) {
    if (_isPremium == isPremium && _hasLearnedToday == hasLearnedToday) return;
    _isPremium = isPremium;
    _hasLearnedToday = hasLearnedToday;
    notifyListeners();
  }

  /// Fetches a rewarded ad so the offer can be shown.
  ///
  /// Called from `initState` on the screens that carry the offer. Notifies
  /// on completion because [canOfferRewarded] depends on the result, and the
  /// SDK has no way to tell a widget it is ready.
  Future<void> prepareRewarded() async {
    if (!_hasLearnedToday || !_ledger.hasRewardedLeft) return;
    await AdsService.I.loadRewarded();
    notifyListeners();
  }

  /// Shows a rewarded ad and pays for it. Returns the coins granted, or 0.
  ///
  /// The ordering here is the whole point of the method:
  ///
  ///   * the coins are read from the ledger *before* the ad, so the amount
  ///     paid is the one the button promised;
  ///   * nothing is paid and no slot is consumed unless [AdsService]
  ///     confirms the reward was earned, so an ad that failed to load, or
  ///     that the player backed out of, costs them nothing; and
  ///   * payment goes through [UserProvider.addCoins], never
  ///     `awardLearningGold`. Ad coins are not learning, so they must not be
  ///     tapered — and, more importantly, must not *advance* the taper.
  ///     Routing them through the ledger would mean watching an ad quietly
  ///     reduced what the next quiz paid. See `gold.dart`.
  Future<int> watchRewarded(UserProvider user) async {
    if (_watchingRewarded) return 0;

    _rolloverIfNeeded();
    final reward = _ledger.nextRewardValue;
    if (reward == null) return 0;

    _watchingRewarded = true;
    notifyListeners();

    try {
      final earned = await AdsService.I.showRewarded();
      if (!earned) return 0;

      _ledger = _ledger.recordingRewarded();
      await _repository.save(_ledger);
      await user.addCoins(reward);

      // One ad, both rewards. The scarce thing is the slot, not which screen
      // the offer was taken from, so an ad watched in the shop is worth the
      // same extra quiz as one watched at the wall — and a player who is out
      // of quizzes never has to guess which button was the right one. See
      // `constants/entitlements.dart`.
      await user.addRewardedQuiz();
      return reward;
    } finally {
      _watchingRewarded = false;
      notifyListeners();
    }
  }

  /// Whether to offer a revive after a lost boss fight.
  ///
  /// The same slot and the same ad as the coin offer, so a revive shares the
  /// five a day. What it does not need is the learning gate: it pays nothing,
  /// so there is no coin to protect, only a fight to carry on with. Members
  /// still see it, as they see every rewarded ad.
  bool get canOfferRevive =>
      _ledger.hasRewardedLeft &&
      !_watchingRewarded &&
      AdsService.I.isRewardedReady;

  /// Fetches a rewarded ad ahead of a fight, so the revive is in hand by the
  /// time the hearts run out. The coin offer's own prepare is gated on having
  /// learned today; a fight is not.
  Future<void> prepareRevive() async {
    if (!_ledger.hasRewardedLeft) return;
    await AdsService.I.loadRewarded();
    notifyListeners();
  }

  /// Shows a rewarded ad for a revive. True when it was watched to the end.
  ///
  /// Uses a slot like any rewarded ad and pays no coins and no quiz: the
  /// reward is the heart, and it is the screen's to give. Nothing is consumed
  /// unless the ad confirms, so one that failed to load or was backed out of
  /// costs the player nothing.
  Future<bool> watchForRevive() async {
    if (_watchingRewarded) return false;
    _rolloverIfNeeded();
    if (!_ledger.hasRewardedLeft) return false;

    _watchingRewarded = true;
    notifyListeners();
    try {
      final earned = await AdsService.I.showRewarded();
      if (!earned) return false;
      _ledger = _ledger.recordingRewarded();
      await _repository.save(_ledger);
      return true;
    } finally {
      _watchingRewarded = false;
      notifyListeners();
    }
  }

  /// Shows an interstitial if the cooldown has elapsed and the player is not
  /// a member. Returns true if one was actually shown.
  ///
  /// The cooldown is recorded only on a confirmed show. An ad that never
  /// appeared must not start an hour of silence, or a player on a poor
  /// connection would drift into seeing none at all.
  Future<bool> maybeShowInterstitial() async {
    _rolloverIfNeeded();

    final now = DateTime.now();
    if (!_ledger.canShowInterstitial(now, isPremium: _isPremium)) return false;

    final shown = await AdsService.I.showInterstitial();
    if (!shown) return false;

    _ledger = _ledger.recordingInterstitial(DateTime.now());
    await _repository.save(_ledger);
    notifyListeners();
    return true;
  }

  void _rolloverIfNeeded() {
    final rolled = _ledger.rolledOver(DateTime.now());
    if (identical(rolled, _ledger)) return;
    _ledger = rolled;
  }
}
