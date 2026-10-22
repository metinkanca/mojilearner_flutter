import 'package:mojilearner_flutter/components/boss_trial/trial_boss.dart';
import 'package:mojilearner_flutter/constants/boss_rewards.dart';
import 'package:mojilearner_flutter/utils/boss_trial.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/accessories.dart';
import 'package:mojilearner_flutter/constants/ads.dart';
import 'package:mojilearner_flutter/constants/gold.dart';
import 'package:mojilearner_flutter/constants/pets.dart';
import 'package:mojilearner_flutter/constants/progression.dart';
import 'package:mojilearner_flutter/constants/shop.dart';
import 'package:mojilearner_flutter/utils/pet_recolor.dart';
import 'package:mojilearner_flutter/utils/play_games.dart';
import 'package:mojilearner_flutter/utils/progression_utils.dart';

/// End-to-end guard on the shape of the economy.
///
/// Every other test here checks one payout in isolation, which is exactly how
/// the old curve went wrong: each number looked defensible, and together they
/// made logging in the best-paid activity in the game and neglecting the pet
/// more profitable than feeding it. This walks the whole catalogue at several
/// play rates so a change to any single price has to answer for what it does
/// to the curve.
///
/// The bands are deliberately wide. They are here to catch a tenfold mistake,
/// not to freeze the tuning.
void main() {
  /// The pets the economy is tuned for: 27 on top of the three starters. This
  /// build ships four of them while the art for the rest is finished, but a
  /// curve checked against four pets would pass for the wrong reason.
  const plannedBoughtPets = 27;

  /// Everything a player can buy: accessories, backgrounds, coats, eyes and
  /// every pet but the starters.
  final catalogueTotal = [
    visibleAccessories
        .where((a) => a.price != null)
        .fold(0, (s, a) => s + a.price!),
    shopItems
        .where((i) => i.type == 'background')
        .fold(0, (s, i) => s + i.price),
    kFancyBodySwatches.fold(0, (s, w) => s + w.price!),
    kFancyEyeSwatches.fold(0, (s, w) => s + w.price!),
    plannedBoughtPets * kPetPrice,
  ].fold(0, (a, b) => a + b);

  /// What the boss levels pay, once each, by level (`BossRewards`).
  final bossCoins = BossRewards.coinsByLevel(
    levelsPerBoss: BossTrialRules.levelsPerBoss,
    bosses: TrialBosses.all.length,
  );

  const hungerPerDay = 2 * 24; // CharacterProvider's decay rate
  const cheapestFoodHungerPerCoin = 2; // apple: 10 hunger for 5 coins

  final loginCoinsPerWeek = dailyRewards
      .where((r) => r.type == RewardType.coins)
      .fold(0, (s, r) => s + r.value);

  final loginFoodPerWeek =
      dailyRewards.where((r) => r.type == RewardType.item).fold(0, (s, r) {
    final item = shopItems.firstWhere((i) => i.id == r.itemId);
    return s + (item.hungerRestore ?? 0) * r.value;
  });

  /// How a player spends a day.
  ///
  /// [correct] is out of five, so it sets the accuracy tier.
  ({String name, int quizzes, int correct, int chats, int reviews, int scenarios})
      profile(String name, int quizzes, int correct, int chats, int reviews,
              int scenarios) =>
          (
            name: name,
            quizzes: quizzes,
            correct: correct,
            chats: chats,
            reviews: reviews,
            scenarios: scenarios
          );

  /// Coins from one day of learning, after the source caps and the taper.
  int learningGoldFor(
    ({
      String name,
      int quizzes,
      int correct,
      int chats,
      int reviews,
      int scenarios
    }) p, {
    required int firstClears,
    required bool sick,
  }) {
    var ledger = const GoldLedger();
    var paid = 0;

    void pay(int raw) {
      // Sickness halves what reaches the ledger, exactly as the screens do.
      final scaled = sick ? (raw * 0.5).round() : raw;
      final source = _currentSource;
      final award = ledger.award(scaled, source);
      ledger = ledger.recording(award, source);
      paid += award.paid;
    }

    // Quizzes. The review schedule realistically supports about five real
    // sets a day; past that they are repeats and pay the reduced rate.
    _currentSource = GoldSource.quiz;
    for (var i = 0; i < p.quizzes; i++) {
      final reward = ProgressionUtils.getQuizRewardOutcome(
        correctAnswers: p.correct,
        totalQuestions: 5,
      );
      pay(i < 5
          ? reward.coinReward
          : (reward.coinReward * GoldConstants.repeatQuizRate).round());
    }

    _currentSource = GoldSource.conversation;
    for (var i = 0; i < p.chats; i++) {
      pay(GoldConstants.conversation);
    }

    _currentSource = GoldSource.review;
    for (var i = 0; i < p.reviews; i++) {
      pay(GoldConstants.review);
    }

    _currentSource = GoldSource.scenario;
    var clearsLeft = firstClears;
    for (var i = 0; i < p.scenarios; i++) {
      final isFirst = clearsLeft > 0;
      if (isFirst) clearsLeft--;
      pay(ProgressionUtils.getScenarioRewardOutcome(
        bonusObjectivesCleared: 1,
        bonusObjectivesTotal: 1,
        isFirstClear: isFirst,
      ).coinReward);
    }

    return paid;
  }

  /// XP from one day of learning. Never halved by sickness: XP is the
  /// relationship's ledger, not the wallet's (see `chat_screen.dart`).
  int learningXpFor(
    ({
      String name,
      int quizzes,
      int correct,
      int chats,
      int reviews,
      int scenarios
    }) p, {
    required int firstClears,
  }) {
    var xp = p.quizzes *
            ProgressionUtils.getQuizRewardOutcome(
              correctAnswers: p.correct,
              totalQuestions: 5,
            ).xpReward +
        p.chats * 5 +
        p.reviews * 3;
    var clearsLeft = firstClears;
    for (var i = 0; i < p.scenarios; i++) {
      final isFirst = clearsLeft > 0;
      if (isFirst) clearsLeft--;
      xp += ProgressionUtils.getScenarioRewardOutcome(
        bonusObjectivesCleared: 1,
        bonusObjectivesTotal: 1,
        isFirstClear: isFirst,
      ).xpReward;
    }
    return xp;
  }

  /// Days to buy [target], playing [p] every day.
  ///
  /// A neglected pet earns half from learning but pays nothing for food —
  /// which is precisely the trade the old economy got backwards.
  ///
  /// Level rewards are in: the coins the XP curve pays out on the way up,
  /// and the backgrounds it hands over, which are then not bought. On a
  /// quick curve they arrive early and are a large share of the whole — the
  /// model once left them out and put the catalogue at 83 days for a regular
  /// player when it was really 27.
  int daysToAfford(
    ({
      String name,
      int quizzes,
      int correct,
      int chats,
      int reviews,
      int scenarios
    }) p, {
    required int target,
    bool caresForPet = true,
    /// Rewarded ads watched every day. Added straight in, with no taper and
    /// no source cap -- ads never touch the learning ledger, so this is
    /// deliberately additive. They only pay on a day the player actually
    /// learned something, which is what `AdsProvider.canOfferRewarded`
    /// enforces. See `constants/ads.dart`.
    int adsPerDay = 0,
    /// XP from the toy chest's games every day, on top of the learning.
    /// XP buys no coins directly, but levels do: the level rewards pay coins
    /// and backgrounds, so a faster climb is a cheaper catalogue.
    int playXpPerDay = 0,
  }) {
    // UserProvider.startingCoins, and the welcome gift on first load.
    var coins = 50 +
        levelRewards
            .firstWhere(
                (r) => r.level == ProgressionConstants.welcomeRewardLevel)
            .value;
    var owed = target;
    var totalXP = 0;
    var day = 0;
    var firstClears = 6; // one per scenario in the catalogue

    while (coins < owed && day < 20000) {
      day++;
      final reward = dailyRewards[(day - 1) % dailyRewards.length];

      final learned =
          learningGoldFor(p, firstClears: firstClears, sick: !caresForPet);
      coins += learned;

      final levelBefore = ProgressionUtils.getLevelFromTotalXP(totalXP);
      totalXP += learningXpFor(p, firstClears: firstClears) + playXpPerDay;
      final levelAfter = ProgressionUtils.getLevelFromTotalXP(totalXP);
      for (var level = levelBefore + 1; level <= levelAfter; level++) {
        for (final r in levelRewards.where((r) => r.level == level)) {
          if (r.type == RewardType.coins) coins += r.value;
          // A background won by levelling is one fewer to buy.
          if (r.type == RewardType.unlock) {
            owed -= shopItems.firstWhere((i) => i.id == r.itemId).price;
          }
        }
        if (level == 20) coins += 1000; // UserProvider's level-20 bonus
        // The boss at this level, cleared the first time: 15 an opening, 100
        // a finale. A player who has reached a level is assumed to clear it.
        if (level <= bossCoins.length) coins += bossCoins[level - 1];
      }

      if (p.scenarios > 0 && firstClears > 0) firstClears--;

      // No learning, no offer. This is the gate, and it is what stops a
      // player who never opens a quiz from buying the catalogue out of pure
      // attention.
      if (learned > 0) {
        for (var i = 0;
            i < adsPerDay && i < AdsConstants.rewardedDailyLimit;
            i++) {
          coins += AdsConstants.rewardedCoinLadder[i];
        }
      }

      if (reward.type == RewardType.coins) coins += reward.value;

      if (caresForPet) {
        final shortfallPerDay = hungerPerDay - loginFoodPerWeek / 7;
        coins -= shortfallPerDay > 0
            ? (shortfallPerDay / cheapestFoodHungerPerCoin).round()
            : 0;
      }
    }
    return day;
  }

  final casual = profile('casual', 1, 3, 3, 3, 0);
  final struggler = profile('struggler', 3, 2, 5, 8, 0);
  final regular = profile('regular', 3, 4, 10, 8, 1);
  final keen = profile('keen', 6, 5, 20, 10, 2);
  final grinder = profile('grinder', 15, 5, 40, 20, 5);

  group('the shape of the whole curve', () {
    test('the catalogue takes months, not a weekend or a lifetime', () {
      expect(daysToAfford(regular, target: catalogueTotal),
          inInclusiveRange(60, 150));
      expect(daysToAfford(casual, target: catalogueTotal),
          inInclusiveRange(150, 450));
    });

    test('grinding cannot empty the catalogue in a fortnight', () {
      // Before the taper a 15-quiz day earned ~330 coins and finished
      // everything in 22 days, which left nothing to want and nothing to sell.
      expect(daysToAfford(grinder, target: catalogueTotal),
          greaterThan(35));
    });

    test('more play is always worth more, but sublinearly', () {
      final regularDays = daysToAfford(regular, target: catalogueTotal);
      final grinderDays = daysToAfford(grinder, target: catalogueTotal);

      expect(grinderDays, lessThan(regularDays));
      // Five times the quizzes must not be five times the speed.
      expect(grinderDays * 3, greaterThan(regularDays));
    });

    test('something is affordable in the first few days', () {
      // The cheapest thing in the wardrobe should not feel far away, whatever
      // the long tail costs.
      final cheapest = visibleAccessories
          .where((a) => a.price != null)
          .map((a) => a.price!)
          .reduce((a, b) => a < b ? a : b);

      expect(daysToAfford(casual, target: cheapest), lessThanOrEqualTo(5));
    });
  });

  group('what the curve must not reward', () {
    test('learning slowly is not punished with a long grind', () {
      // A 40% learner against an 80% one. The gap used to be 3.3x on quiz
      // coins alone, which charged the player likeliest to quit the most.
      final slow = daysToAfford(struggler, target: catalogueTotal);
      final fast = daysToAfford(regular, target: catalogueTotal);

      expect(slow / fast, lessThan(1.6));
    });

    test('caring for the pet beats neglecting it, at every play rate', () {
      // The old economy failed this: for a light player, skipping food saved
      // more than the sickness penalty cost, so the profitable move was to
      // let the pet get ill.
      for (final p in [casual, struggler, regular, keen, grinder]) {
        expect(
          daysToAfford(p, target: catalogueTotal, caresForPet: true),
          lessThan(daysToAfford(p, target: catalogueTotal, caresForPet: false)),
          reason: '${p.name}: neglecting the pet must never pay better',
        );
      }
    });

    test('showing up is a greeting, not an income', () {
      // Logging in used to pay 375 coins a week, over half of an average
      // player's income. It should now be a rounding error against learning.
      final regularLearningPerDay =
          learningGoldFor(regular, firstClears: 0, sick: false);

      expect(loginCoinsPerWeek / 7, lessThan(regularLearningPerDay * 0.25));
    });

    test('a player who only logs in gets nowhere', () {
      // Not literally never: the login coins slightly outrun the food
      // shortfall, so an idle balance drifts up by about a coin a day. What
      // matters is the order of magnitude — this used to be 282 days, i.e. a
      // player could own the entire catalogue without once opening a quiz.
      final idle = profile('idle', 0, 0, 0, 0, 0);

      expect(daysToAfford(idle, target: catalogueTotal),
          greaterThan(5 * 365));
    });
  });

  group('the pet is fed by showing up, not by the wardrobe budget', () {
    test('the daily cycle roughly covers what the pet burns', () {
      expect(loginFoodPerWeek, greaterThan(hungerPerDay * 7 * 0.75));
      // But not so much that food piles up and feeding stops being an act.
      expect(loginFoodPerWeek, lessThan(hungerPerDay * 7 * 1.1));
    });

    test('upkeep is a rounding error against a day of learning', () {
      final shortfallPerDay = hungerPerDay - loginFoodPerWeek / 7;
      final upkeepCoins = shortfallPerDay / cheapestFoodHungerPerCoin;
      final casualLearningPerDay =
          learningGoldFor(casual, firstClears: 0, sick: false);

      expect(upkeepCoins, lessThan(casualLearningPerDay * 0.5));
    });
  });

  /// Ads are the one income source that is not earned by doing the content,
  /// which is exactly why the curve has to be re-checked against them. What
  /// these ask is not "are ads good value" but "can attention replace study".
  group('watching ads tops the curve up without replacing it', () {
    final maxAds = AdsConstants.rewardedDailyLimit;


    test('a full day of ads is worth well under a day of learning', () {
      final regularLearningPerDay =
          learningGoldFor(regular, firstClears: 0, sick: false);

      expect(AdsConstants.rewardedDailyTotal, lessThan(regularLearningPerDay));
    });

    test('but is worth more than showing up', () {
      // If five ads paid less than the login cycle, nobody would watch one
      // and the whole thing would be UI for no revenue.
      expect(AdsConstants.rewardedDailyTotal,
          greaterThan(loginCoinsPerWeek / 7));
    });

    test('ads are worth nothing at all to a non-learner', () {
      // The load-bearing one, and the reason the offer is gated rather than
      // merely small. Coins buy appearance and the route to them has to stay
      // the content: ungated, five ads a day took someone who never opens a
      // quiz from five years to four months, which is faster than a casual
      // learner who watches none.
      final idle = profile('idle', 0, 0, 0, 0, 0);

      expect(
        daysToAfford(idle, target: catalogueTotal, adsPerDay: maxAds),
        equals(daysToAfford(idle, target: catalogueTotal)),
      );
    });

    test('a learner who also watches ads is faster, but not transformed', () {
      final withoutAds = daysToAfford(regular, target: catalogueTotal);
      final withAds =
          daysToAfford(regular, target: catalogueTotal, adsPerDay: maxAds);

      expect(withAds, lessThan(withoutAds));
      // Two and a half minutes of watching must not halve a months-long
      // catalogue. If this ever fails, the ladder has outgrown the economy.
      expect(withAds * 2, greaterThan(withoutAds));
    });

    test('the catalogue still takes months for an ad-watching regular', () {
      expect(
        daysToAfford(regular, target: catalogueTotal, adsPerDay: maxAds),
        greaterThan(45),
      );
    });

    test('caring for the pet still beats neglecting it, ads included', () {
      for (final p in [casual, struggler, regular, keen, grinder]) {
        expect(
          daysToAfford(p,
              target: catalogueTotal, caresForPet: true, adsPerDay: maxAds),
          lessThan(daysToAfford(p,
              target: catalogueTotal, caresForPet: false, adsPerDay: maxAds)),
          reason: '${p.name}: neglecting the pet must never pay better',
        );
      }
    });
  });


  /// The toy chest's games pay XP, which is the one learning payout a player
  /// could repeat for an hour without tiring — so it is capped, and these ask
  /// whether the cap keeps it a top-up. See `PlayRewards.dailyXpCap`.
  group('the toy chest tops XP up without replacing learning', () {
    const cap = PlayRewards.dailyXpCap;

    test('its whole daily cap is a small share of a regular day', () {
      final regularXp = learningXpFor(regular, firstClears: 0);

      expect(cap, lessThan(regularXp * 0.25));
    });

    test('maxing it every day still leaves the catalogue months away', () {
      expect(daysToAfford(regular, target: catalogueTotal, playXpPerDay: cap),
          inInclusiveRange(60, 150));
      expect(daysToAfford(casual, target: catalogueTotal, playXpPerDay: cap),
          inInclusiveRange(150, 450));
    });

    test('a learner who also plays is faster, but not transformed', () {
      for (final p in [casual, regular]) {
        final without = daysToAfford(p, target: catalogueTotal);
        final withGames =
            daysToAfford(p, target: catalogueTotal, playXpPerDay: cap);

        expect(withGames, lessThanOrEqualTo(without), reason: p.name);
        expect(withGames * 1.25, greaterThan(without), reason: p.name);
      }
    });
  });

  group('the boss payouts', () {
    test('are a small share of the catalogue, never a way round it', () {
      final bossTotal = bossCoins.fold(0, (a, b) => a + b);
      expect(bossTotal, 960);
      expect(bossTotal / catalogueTotal, lessThan(0.08),
          reason: 'first clears are a bonus on the way, not an income');
    });
  });
}

/// The source the current payout belongs to.
///
/// A mutable module-level cursor rather than a parameter, so the walk above
/// reads as a day of play rather than as plumbing. Only this file touches it.
GoldSource _currentSource = GoldSource.quiz;
