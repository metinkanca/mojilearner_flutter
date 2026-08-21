import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/bond.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bond is the slow axis: earned only from learning, capped per day, and never
/// reduced. These tests pin the three properties the rest of the design leans
/// on.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// The decay timer runs forever, so tests build the provider without it.
  Future<CharacterProvider> buildProvider() async {
    final provider = CharacterProvider(startDecayTimer: false);
    await Future.delayed(const Duration(milliseconds: 50));
    return provider;
  }

  group('earning', () {
    test('starts at zero with nothing learned', () async {
      final provider = await buildProvider();
      expect(provider.bondPoints, 0);
      expect(provider.lastLearningAt, isNull);
      expect(provider.sinceLastLearning, isNull);
      expect(provider.warmth, PetWarmth.warm);
    });

    test('a conversation pays its point value', () async {
      final provider = await buildProvider();
      final awarded = provider.recordLearning(BondSource.conversation);
      expect(awarded, BondConstants.conversation);
      expect(provider.bondPoints, BondConstants.conversation);
    });

    test('units settle a whole session in one call', () async {
      final provider = await buildProvider();
      provider.recordLearning(BondSource.correction, units: 4);
      expect(provider.bondPoints, BondConstants.correction * 4);
    });

    test('zero or negative units pay nothing', () async {
      final provider = await buildProvider();
      expect(provider.recordLearning(BondSource.conversation, units: 0), 0);
      expect(provider.recordLearning(BondSource.conversation, units: -3), 0);
      expect(provider.bondPoints, 0);
    });

    test('a quiz pays more the better it went', () async {
      final provider = await buildProvider();
      final poor =
          provider.recordQuizLearning(correctAnswers: 0, totalQuestions: 10);
      final perfect =
          provider.recordQuizLearning(correctAnswers: 10, totalQuestions: 10);
      expect(perfect, greaterThan(poor));
      expect(poor, greaterThan(0));
    });
  });

  group('daily cap', () {
    test('stops paying once the day is spent', () async {
      final provider = await buildProvider();

      // Far more scenario clears than a day can pay for.
      for (var i = 0; i < 50; i++) {
        provider.recordLearning(BondSource.scenario);
      }

      expect(provider.bondPoints, BondConstants.dailyCap);
      expect(provider.bondEarnedToday, BondConstants.dailyCap);
      expect(provider.bondRemainingToday, 0);
      expect(provider.recordLearning(BondSource.conversation), 0);
    });

    test('trims the event that crosses the cap rather than dropping it',
        () async {
      final provider = await buildProvider();
      provider.recordLearning(
        BondSource.conversation,
        units: (BondConstants.dailyCap ~/ BondConstants.conversation) - 1,
      );
      final remaining = provider.bondRemainingToday;
      expect(remaining, greaterThan(0));

      final awarded = provider.recordLearning(BondSource.scenario);
      expect(awarded, remaining);
      expect(provider.bondPoints, BondConstants.dailyCap);
    });

    // Studying past the cap must not read as an absence.
    test('capped-out learning still counts as having shown up', () async {
      final provider = await buildProvider();
      for (var i = 0; i < 50; i++) {
        provider.recordLearning(BondSource.scenario);
      }
      final before = provider.lastLearningAt;

      expect(provider.recordLearning(BondSource.conversation), 0);
      expect(provider.lastLearningAt, isNotNull);
      expect(
        provider.lastLearningAt!.isBefore(before!),
        isFalse,
        reason: 'a capped event should still refresh the learning timestamp',
      );
      expect(provider.warmth, PetWarmth.warm);
    });

    test('a cap spent yesterday does not carry into today', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      SharedPreferences.setMockInitialValues({
        'pet_bond_points': 200,
        'pet_bond_day': yesterday.millisecondsSinceEpoch,
        'pet_bond_today': BondConstants.dailyCap,
      });
      final provider = await buildProvider();

      expect(provider.bondEarnedToday, 0);
      expect(provider.bondRemainingToday, BondConstants.dailyCap);
      expect(
        provider.recordLearning(BondSource.scenario),
        BondConstants.scenario,
      );
    });

    // Otherwise the cap is one app restart away from meaningless.
    test('a restart within the same day does not clear the cap', () async {
      final today = DateTime.now();
      SharedPreferences.setMockInitialValues({
        'pet_bond_points': 40,
        'pet_bond_day': today.millisecondsSinceEpoch,
        'pet_bond_today': BondConstants.dailyCap,
      });
      final provider = await buildProvider();

      expect(provider.bondEarnedToday, BondConstants.dailyCap);
      expect(provider.recordLearning(BondSource.scenario), 0);
    });
  });

  group('persistence', () {
    test('restores bond and the last learning time', () async {
      final learnedAt =
          DateTime.now().subtract(const Duration(days: 3, hours: 2));
      SharedPreferences.setMockInitialValues({
        'pet_bond_points': 420,
        'pet_last_learning': learnedAt.millisecondsSinceEpoch,
      });
      final provider = await buildProvider();

      expect(provider.bondPoints, 420);
      expect(provider.sinceLastLearning!.inDays, 3);
      expect(provider.warmth, PetWarmth.missingYou);
    });
  });

  group('what does not pay bond', () {
    // The premise of the game is that the relationship grows through the
    // language. Anything buyable paying bond would make that false.
    test('feeding, petting and activity rewards leave bond untouched',
        () async {
      SharedPreferences.setMockInitialValues({
        'inventory': ['apple', 'apple'],
      });
      final provider = await buildProvider();
      provider.recordLearning(BondSource.conversation);
      final earned = provider.bondPoints;

      provider.feedPet('apple');
      provider.petThePet();
      provider.rewardChat();
      provider.rewardScenario();
      provider.rewardQuiz(true);
      provider.applyQuizRewards(happinessDelta: 5, hungerDelta: 2);

      expect(provider.bondPoints, earned);
    });
  });

  group('absence', () {
    // Bond is monotonic: neglect never takes back what was learned.
    test('a long absence does not reduce bond', () async {
      final longAgo = DateTime.now().subtract(const Duration(days: 120));
      SharedPreferences.setMockInitialValues({
        'pet_bond_points': 640,
        'pet_last_learning': longAgo.millisecondsSinceEpoch,
        'pet_hunger': 50,
        'pet_happiness': 70,
        'pet_health': 100,
        'pet_last_update': longAgo.millisecondsSinceEpoch,
      });
      final provider = await buildProvider();

      // The survival stats have decayed all the way down...
      expect(provider.health, lessThan(100));
      // ...and the bond has not moved at all.
      expect(provider.bondPoints, 640);
      expect(provider.warmth, PetWarmth.lonely);
    });

    test('one learning event on returning clears the warmth', () async {
      final longAgo = DateTime.now().subtract(const Duration(days: 120));
      SharedPreferences.setMockInitialValues({
        'pet_bond_points': 640,
        'pet_last_learning': longAgo.millisecondsSinceEpoch,
      });
      final provider = await buildProvider();
      expect(provider.warmth, PetWarmth.lonely);

      provider.recordLearning(BondSource.conversation);
      expect(provider.warmth, PetWarmth.warm);
    });
  });

  group('stage', () {
    test('reads the assessed level for the language being learned', () async {
      SharedPreferences.setMockInitialValues({'pet_bond_points': 300});
      final provider = await buildProvider();

      expect(provider.bondStatusFor('beginner').stage, PetStage.friendly);
      expect(provider.bondStatusFor('B1').stage, PetStage.attached);
      expect(provider.bondStatusFor(null).stage, PetStage.friendly);
    });
  });
}
