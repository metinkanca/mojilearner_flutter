import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/constants/bond.dart';
import 'package:mojilearner_flutter/constants/entitlements.dart';
import 'package:mojilearner_flutter/constants/gold.dart';
import 'package:mojilearner_flutter/constants/scenes.dart';
import 'package:mojilearner_flutter/models/models.dart';
import 'package:mojilearner_flutter/utils/play_games.dart';
import 'package:mojilearner_flutter/utils/season_pass_progress.dart';
import 'package:mojilearner_flutter/providers/user_provider.dart';
import 'package:mojilearner_flutter/providers/daily_reward_provider.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/chat_provider.dart';
import 'package:mojilearner_flutter/providers/quiz_provider.dart';
import 'package:mojilearner_flutter/providers/mistakes_provider.dart';
import 'package:mojilearner_flutter/providers/settings_provider.dart';
import 'package:mojilearner_flutter/providers/calibration_provider.dart';
import 'package:mojilearner_flutter/providers/premium_provider.dart';

/// Mock classes for all providers used in testing
/// 
/// Usage:
/// ```dart
/// final mockUserProvider = MockUserProvider();
/// when(() => mockUserProvider.coins).thenReturn(100);
/// ```

/// Coin awards are implemented rather than stubbed.
///
/// The review, quiz and scenario flows all pay out through
/// [awardLearningGold], so leaving it to `when()` would make every test that
/// merely grades a card fail on a missing stub for the economy — the same
/// reason bond is implemented on [MockCharacterProvider]. It pays in full
/// here: the taper and the source caps have their own tests
/// (`test/unit/constants/gold_test.dart`), and screen tests should not have
/// to know today's ledger to assert on a payout.
///
/// [awardedGold] records every call for tests that do care.
class MockUserProvider extends Mock implements UserProvider {
  /// Every coin award, in call order.
  final List<({int raw, GoldSource source})> awardedGold = [];

  @override
  Future<GoldAward> awardLearningGold(int raw, GoldSource source) async {
    awardedGold.add((raw: raw, source: source));
    return GoldAward(paid: raw, raw: raw);
  }

  /// Coins awarded from [source] across the test so far.
  int goldFrom(GoldSource source) => awardedGold
      .where((a) => a.source == source)
      .fold(0, (sum, a) => sum + a.raw);

  /// Untapered coin grants, in call order.
  ///
  /// Implemented for the same reason [awardLearningGold] is, and kept
  /// separate from it on purpose: this is the path a rewarded ad pays
  /// through, and the two lists staying distinct is what lets a test assert
  /// that ad coins never went near the learning ledger. See
  /// `constants/ads.dart`.
  final List<int> addedCoins = [];

  @override
  Future<void> addCoins(int amount) async => addedCoins.add(amount);

  /// Today's pre-taper learning coins, derived from [awardedGold].
  ///
  /// Implemented rather than stubbed because the rewarded-ad offer is gated
  /// on it: a screen test that merely renders the shop should not have to
  /// stub the economy to say whether the player has studied today.
  @override
  int get learningGoldEarnedToday =>
      awardedGold.fold(0, (sum, a) => sum + a.raw);

  /// The learning ledger, and the pet's bond stage with it.
  ///
  /// A plain field rather than a stub because the home screen projects the
  /// pet's stage from it on every build (see `utils/bond_context.dart`), so
  /// every screen test would otherwise need a stub for a feature it is not
  /// about. Tests that want a grown pet set this.
  @override
  int totalXP = 0;

  /// Every XP grant, in call order, kept separate from [addedCoins] so a test
  /// can assert learning paid the ledger without the coins getting in the way.
  final List<int> addedXp = [];

  @override
  Future<void> addXp(int amount) async {
    addedXp.add(amount);
    totalXP += amount;
  }

  /// The toy chest games' XP, through the real (pure) daily cap, so a game
  /// screen test can finish a game without stubbing the economy. Lands in
  /// [addedXp] too, as the real one does through [addXp].
  int playXpToday = 0;

  @override
  Future<int> awardPlayXp(int earned) async {
    final paid =
        PlayRewards.xpAllowed(earned: earned, paidToday: playXpToday);
    if (paid <= 0) return 0;
    playXpToday += paid;
    await addXp(paid);
    return paid;
  }

  /// Membership. A plain field so a test can flip it without a stub.
  @override
  bool isPremium = false;

  /// Season passes owned. Implemented rather than stubbed because the
  /// wardrobe reads the claimed set on every shelf, so a missing stub would
  /// fail every test that merely opens it. Empty is a player who has bought
  /// none, which is what a test run is unless it says otherwise.
  @override
  List<OwnedPass> ownedPasses = const [];

  @override
  Set<String> claimedPassItemIds = const {};

  @override
  bool ownsPass(String passId) =>
      ownedPasses.any((p) => p.passId == passId);

  /// Implemented for the same reason [ownedPasses] is: the pass screen and its
  /// profile tile both ask on every build, so a stub would have to be set up
  /// by every test that so much as opens the profile. Runs the real (pure)
  /// arithmetic against [ownedPasses] and [totalXP], so a test can set a
  /// purchase baseline and watch the track fill.
  @override
  PassProgress? passProgress(String passId) {
    for (final owned in ownedPasses) {
      if (owned.passId == passId) {
        return SeasonPassProgress.progressFor(owned, totalXP: totalXP);
      }
    }
    return null;
  }

  /// The daily model allowance, implemented rather than stubbed for the same
  /// reason the coin awards are: the quiz and chat screens ask before every
  /// generation, so a missing stub would fail every test that merely opens
  /// one. The real (pure) ledger runs, so a test can spend it down and watch
  /// the wall appear.
  AiUsageLedger aiUsage = const AiUsageLedger();

  @override
  AiAllowance get aiAllowance =>
      EntitlementConstants.forTier(isPremium: isPremium);

  @override
  int aiRemaining(AiSpend spend) => aiUsage.remaining(spend, aiAllowance);

  @override
  int aiLimit(AiSpend spend) => aiUsage.limitFor(spend, aiAllowance);

  @override
  int get aiBonusQuizzesToday => aiUsage.bonusQuizzesToday;

  @override
  bool canSpendAi(AiSpend spend) => aiUsage.canSpend(spend, aiAllowance);

  @override
  Future<bool> spendAi(AiSpend spend) async {
    if (!aiUsage.canSpend(spend, aiAllowance)) return false;
    aiUsage = aiUsage.recording(spend, aiAllowance);
    return true;
  }

  @override
  Future<void> addRewardedQuiz() async {
    aiUsage = aiUsage.recordingRewardedQuiz();
  }

  /// Spends [spend] all the way down, for tests about what happens at the
  /// wall rather than about the arithmetic getting there.
  void exhaustAi(AiSpend spend) {
    while (aiUsage.canSpend(spend, aiAllowance)) {
      aiUsage = aiUsage.recording(spend, aiAllowance);
    }
  }

  /// Whether the opening is behind this player. A plain field for the same
  /// reason as [isPremium], and true by default because every main screen is
  /// only reachable once it is — the tour hosts gate on it, so leaving it to
  /// `when()` would make each of them throw on a screen they are not about.
  @override
  bool hasCompletedOnboarding = true;
}

class MockDailyRewardProvider extends Mock implements DailyRewardProvider {}

/// The store, which in a test never answers.
///
/// Implemented rather than stubbed for the usual reason: the paywall reads it
/// on every build, and every other screen sits under the same provider. The
/// defaults describe a build with no product ids configured, which is what a
/// test run actually is.
class MockPremiumProvider extends Mock implements PremiumProvider {
  @override
  bool isAvailable = false;

  @override
  List<ProductDetails> products = const [];

  @override
  bool isPurchasePending = false;

  @override
  bool isRestoring = false;

  /// The store's listing for the season pass, or null for the ordinary state
  /// before the console has one. Set it to put a price on the pass screen.
  ProductDetails? seasonPassProduct;

  /// Passes [buyPass] was asked for, in order. Recorded rather than verified
  /// through mocktail because the method is implemented here, not stubbed.
  final List<String> boughtPassIds = [];

  @override
  ProductDetails? passProduct(String passId) => seasonPassProduct;

  @override
  bool isPassAvailable(String passId) =>
      isAvailable && seasonPassProduct != null;

  @override
  Future<void> buyPass(String passId) async => boughtPassIds.add(passId);

  /// The store's listing for every coin pack, or null for the ordinary state
  /// before the console has one. One listing for all of them: the top-up page
  /// is about the ladder, and a test that wants prices wants them on every
  /// rung.
  ProductDetails? coinPackListing;

  /// Per-pack listings, for a test that cares which rung costs what.
  /// Consulted before [coinPackListing], which stays the blanket fallback.
  final Map<String, ProductDetails> coinPackListings = {};

  /// Packs [buyCoinPack] was asked for, in order.
  final List<String> boughtCoinPackIds = [];

  /// What [takeCoinsGranted] hands back next. Set it to put a completed
  /// purchase in front of the page.
  int? coinsGranted;

  @override
  ProductDetails? coinPackProduct(String packId) =>
      coinPackListings[packId] ?? coinPackListing;

  @override
  bool isCoinPackAvailable(String packId) =>
      isAvailable && coinPackProduct(packId) != null;

  @override
  Future<void> buyCoinPack(String packId) async =>
      boughtCoinPackIds.add(packId);

  @override
  int? takeCoinsGranted() {
    final granted = coinsGranted;
    coinsGranted = null;
    return granted;
  }

  @override
  void attach(UserProvider user) {}
}

/// Bond is implemented rather than stubbed.
///
/// The home screen reads it on every build and the review/quiz/chat flows
/// write to it, so leaving it to `when()` would make every existing test that
/// merely renders a screen fail on a missing stub for a feature it is not
/// about.
///
/// The stage itself is no longer here to mock: it is projected from the XP on
/// `UserProvider`, so a test that wants a grown pet sets that instead. What
/// remains is the warmth flag and [learningMoments], which gives bond-aware
/// tests something to assert on without needing `verify()`.
class MockCharacterProvider extends Mock implements CharacterProvider {
  @override
  PetWarmth warmth = PetWarmth.warm;

  /// The world the home screen paints. Implemented rather than stubbed for
  /// the same reason bond is: every screen test renders the scene, and none
  /// of them are about which one is showing.
  @override
  SceneTheme scene = kDefaultScene;

  /// Derived, not stubbed separately, so a test that moves the pet to another
  /// world cannot leave the two disagreeing about where it lives.
  @override
  String get sceneId => scene.id;

  @override
  bool ownsScene(String id) => isFreeScene(id) || scene.id == id;

  /// Petting payouts, read by the home screen on every build to decide whether
  /// to play hearts. Implemented rather than stubbed for the same reason bond
  /// is: otherwise every test that merely renders the screen fails on a
  /// missing stub for a feature it is not about.
  @override
  int petPayouts = 0;

  /// How many times a learning event was recorded, in call order.
  ///
  /// A count rather than a list of sources: every learning event now says the
  /// same thing to the pet ("you were here today"), and what each one is
  /// *worth* is XP, asserted against `UserProvider` instead.
  int learningMoments = 0;

  @override
  void recordLearningMoment() => learningMoments++;
}

class MockLanguageProvider extends Mock implements LanguageProvider {}

class MockChatProvider extends Mock implements ChatProvider {}

class MockQuizProvider extends Mock implements QuizProvider {}

class MockMistakesProvider extends Mock implements MistakesProvider {}

class MockSettingsProvider extends Mock implements SettingsProvider {}

/// The assessed levels behind the pet's fluency gate.
///
/// [calibratedProficiencies] is implemented rather than stubbed for the same
/// reason the XP is: the bond stage reads it on every home-screen build, so a
/// missing stub would fail tests that are not about calibration at all.
class MockCalibrationProvider extends Mock implements CalibrationProvider {
  /// Languages the player has been assessed in. Empty reads as beginner.
  @override
  Iterable<LanguageProficiency> calibratedProficiencies = const [];
}
