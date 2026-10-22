import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/bond.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What the provider still owns of the bond after the ledger merged into XP:
/// the moment the player last learned something, and the warmth it drives.
///
/// The stage ladder itself is projected from `UserProvider.totalXP` and lives
/// in `utils/bond_progress.dart`, with its own tests. What is pinned here is
/// that an absence is noticed, that it costs nothing, and that coming back
/// clears it.
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

  group('recording a learning moment', () {
    test('starts with nothing learned, and warm rather than lonely', () async {
      final provider = await buildProvider();

      expect(provider.lastLearningAt, isNull);
      expect(provider.sinceLastLearning, isNull);
      expect(provider.warmth, PetWarmth.warm);
    });

    test('stamps the moment', () async {
      final provider = await buildProvider();
      provider.recordLearningMoment();

      expect(provider.lastLearningAt, isNotNull);
      expect(provider.sinceLastLearning!.inSeconds, lessThan(5));
      expect(provider.warmth, PetWarmth.warm);
    });

    // Recording is a timestamp, not a score, so repeating it in one session
    // must not mean anything different from doing it once.
    test('recording twice is the same as recording once', () async {
      final provider = await buildProvider();
      provider.recordLearningMoment();
      final first = provider.lastLearningAt;
      provider.recordLearningMoment();

      expect(provider.lastLearningAt!.isBefore(first!), isFalse);
      expect(provider.warmth, PetWarmth.warm);
    });
  });

  group('what does not count as learning', () {
    // The premise of the game is that the relationship grows through the
    // language. Feeding a pet you have not spoken to in a week must not make
    // it stop noticing.
    test('feeding, petting and activity rewards leave the pet still missing '
        'you', () async {
      final longAgo = DateTime.now().subtract(const Duration(days: 4));
      SharedPreferences.setMockInitialValues({
        'inventory': ['apple', 'apple'],
        'pet_last_learning': longAgo.millisecondsSinceEpoch,
      });
      final provider = await buildProvider();
      expect(provider.warmth, PetWarmth.missingYou);

      provider.feedPet('apple');
      provider.petThePet();
      provider.rewardChat();
      provider.rewardScenario();
      provider.rewardQuiz(true);
      provider.applyQuizRewards(happinessDelta: 5, hungerDelta: 2);

      expect(provider.warmth, PetWarmth.missingYou);
      expect(provider.lastLearningAt!.day, longAgo.day);
    });
  });

  group('persistence', () {
    test('restores the last learning time', () async {
      final learnedAt =
          DateTime.now().subtract(const Duration(days: 3, hours: 2));
      SharedPreferences.setMockInitialValues({
        'pet_last_learning': learnedAt.millisecondsSinceEpoch,
      });
      final provider = await buildProvider();

      expect(provider.sinceLastLearning!.inDays, 3);
      expect(provider.warmth, PetWarmth.missingYou);
    });

    // The ledger that used to live here is gone; a save from before the merge
    // must load without it rather than throwing or resetting the pet.
    test('a save carrying the retired bond keys still loads', () async {
      final longAgo = DateTime.now().subtract(const Duration(days: 9));
      SharedPreferences.setMockInitialValues({
        'pet_bond_points': 640,
        'pet_bond_day': longAgo.millisecondsSinceEpoch,
        'pet_bond_today': 40,
        'pet_last_learning': longAgo.millisecondsSinceEpoch,
      });
      final provider = await buildProvider();

      expect(provider.warmth, PetWarmth.lonely);
    });
  });

  group('absence', () {
    // An absence is the softened failure state: the pet says it noticed, and
    // that is the entire cost.
    test('a long absence costs nothing but the pet noticing', () async {
      final longAgo = DateTime.now().subtract(const Duration(days: 120));
      SharedPreferences.setMockInitialValues({
        'pet_last_learning': longAgo.millisecondsSinceEpoch,
        'pet_hunger': 50,
        'pet_happiness': 70,
        'pet_health': 100,
        'pet_last_update': longAgo.millisecondsSinceEpoch,
      });
      final provider = await buildProvider();

      // The survival stats have decayed all the way down...
      expect(provider.health, lessThan(100));
      // ...and the pet is simply lonely. Nothing else on the provider moved,
      // because an absence has no ledger left to charge.
      expect(provider.warmth, PetWarmth.lonely);
      expect(provider.lastLearningAt!.day, longAgo.day);
    });

    test('one learning event on returning clears the warmth', () async {
      final longAgo = DateTime.now().subtract(const Duration(days: 120));
      SharedPreferences.setMockInitialValues({
        'pet_last_learning': longAgo.millisecondsSinceEpoch,
      });
      final provider = await buildProvider();
      expect(provider.warmth, PetWarmth.lonely);

      provider.recordLearningMoment();
      expect(provider.warmth, PetWarmth.warm);
    });
  });
}
