import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/boss_trial/trial_boss.dart';
import 'package:mojilearner_flutter/constants/boss_rewards.dart';
import 'package:mojilearner_flutter/constants/progression.dart';
import 'package:mojilearner_flutter/constants/shop.dart';
import 'package:mojilearner_flutter/utils/boss_trial.dart';

int coinsOf(List<RewardDef> rewards) => rewards
    .where((r) => r.type == RewardType.coins)
    .fold(0, (sum, r) => sum + r.value);

void main() {
  final last = BossTrialRules.levelsPerBoss - 1;

  group('BossRewards.firstClear', () {
    test('an opening pays 15 coins and one care item', () {
      for (var step = 0; step < last; step++) {
        final rewards =
            BossRewards.firstClear(level: step + 1, step: step, finale: false);
        expect(coinsOf(rewards), BossRewards.openingCoins);
        expect(BossRewards.openingCoins, 15);
        final items = rewards.where((r) => r.type == RewardType.item).toList();
        expect(items, hasLength(1), reason: 'step $step');
        expect(items.single.value, 1);
      }
    });

    test('a finale pays 100 coins and a cure and a meal', () {
      final rewards = BossRewards.firstClear(level: 5, step: last, finale: true);
      expect(coinsOf(rewards), 100);
      final ids = rewards
          .where((r) => r.type == RewardType.item)
          .map((r) => r.itemId)
          .toList();
      expect(ids, ['medicine', 'pizza']);
    });

    test('every item handed over is a real food in the shop', () {
      final foods =
          shopItems.where((i) => i.type == 'food').map((i) => i.id).toSet();
      for (final step in [0, 1, 2, 3]) {
        for (final r in BossRewards.firstClear(
            level: 1, step: step, finale: false)) {
          if (r.itemId != null) expect(foods, contains(r.itemId));
        }
      }
      for (final r in BossRewards.firstClear(level: 5, step: 4, finale: true)) {
        if (r.itemId != null) expect(foods, contains(r.itemId));
      }
    });

    test('the four openings stock four different items', () {
      final ids = [
        for (var step = 0; step < last; step++)
          BossRewards.firstClear(level: 1, step: step, finale: false)
              .firstWhere((r) => r.itemId != null)
              .itemId,
      ];
      expect(ids.toSet(), hasLength(last));
    });

    test('carries the level it was earned at', () {
      final rewards = BossRewards.firstClear(level: 12, step: 1, finale: false);
      expect(rewards.every((r) => r.level == 12), isTrue);
    });
  });

  group('the whole climb', () {
    test('all six bosses pay 960 coins, once, across the 30 levels', () {
      final bosses = TrialBosses.all.length;
      expect(bosses, 6);
      final byLevel = BossRewards.coinsByLevel(
        levelsPerBoss: BossTrialRules.levelsPerBoss,
        bosses: bosses,
      );
      expect(byLevel, hasLength(30));
      expect(byLevel.fold(0, (a, b) => a + b), 960);
      // A finale every fifth level, and nothing else that big.
      for (var i = 0; i < byLevel.length; i++) {
        expect(byLevel[i], (i + 1) % 5 == 0 ? 100 : 15, reason: 'level ${i + 1}');
      }
    });
  });
}
