import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    // Clean up any timers
  });

  group('CharacterProvider - Initialization', () {
    test('should load persisted pet state from SharedPreferences', () async {
      // Arrange
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues({
        'pet_hunger': 60,
        'pet_happiness': 80,
        'pet_health': 95,
        'pet_last_update': now.millisecondsSinceEpoch,
        'unlocked_items': ['apple', 'coffee', 'pizza'],
        'inventory': ['apple', 'coffee'],
      });

      // Act
      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(provider.hunger, equals(60));
      expect(provider.happiness, equals(80));
      expect(provider.health, equals(95));
      expect(provider.unlockedItems.length, greaterThanOrEqualTo(3));
      expect(provider.inventory.length, greaterThanOrEqualTo(2));
    });

    test('should start decay timer on creation', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});

      // Act
      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert - Timer should be active (no exception thrown)
      expect(provider.hunger, isNotNull);
      expect(provider.happiness, isNotNull);
      expect(provider.health, isNotNull);
    });
  });

  group('CharacterProvider - Character Assets', () {
    test('should use top-level asset path for default character type',
        () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});

      // Act
      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(provider.currentCharacterType, equals('cat'));
      expect(provider.currentCharacterAsset, equals('assets/svgs/cat.svg'));
    });

    test('should use top-level asset path after character type updates',
        () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});

      // Act
      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      await provider.updateCharacterType('dog');

      // Assert
      expect(provider.currentCharacterType, equals('dog'));
      expect(provider.currentCharacterAsset, equals('assets/svgs/dog.svg'));

      // Act
      await provider.updateCharacterType('bird');

      // Assert
      expect(provider.currentCharacterType, equals('bird'));
      expect(provider.currentCharacterAsset, equals('assets/svgs/bird.svg'));
    });

    test('should sanitize invalid persisted character type to cat asset path',
        () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'character_type': 'dragon',
      });

      // Act
      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(provider.currentCharacterType, equals('cat'));
      expect(provider.currentCharacterAsset, equals('assets/svgs/cat.svg'));
    });
  });

  group('CharacterProvider - Vitals Decay', () {
    test('should increase hunger over time (simulated)', () async {
      // Arrange
      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
      SharedPreferences.setMockInitialValues({
        'pet_hunger': 50,
        'pet_happiness': 70,
        'pet_health': 100,
        'pet_last_update': twoHoursAgo.millisecondsSinceEpoch,
      });

      // Act
      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert - Hunger should increase by 3 per hour (2 hours = 6)
      expect(provider.hunger, equals(56));
    });

    test('should decrease happiness over time (simulated)', () async {
      // Arrange
      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
      SharedPreferences.setMockInitialValues({
        'pet_hunger': 50,
        'pet_happiness': 70,
        'pet_health': 100,
        'pet_last_update': twoHoursAgo.millisecondsSinceEpoch,
      });

      // Act
      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert - Happiness should decrease by 2 per hour (2 hours = 4)
      expect(provider.happiness, equals(66));
    });

    test('should decrease health when hunger > 80', () async {
      // Arrange
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      SharedPreferences.setMockInitialValues({
        'pet_hunger': 85,
        'pet_happiness': 70,
        'pet_health': 100,
        'pet_last_update': oneHourAgo.millisecondsSinceEpoch,
      });

      // Act
      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert - Health should decrease by 1 per hour when hungry
      expect(provider.health, lessThan(100));
    });

    test('should decrease health when happiness < 20', () async {
      // Arrange
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      SharedPreferences.setMockInitialValues({
        'pet_hunger': 50,
        'pet_happiness': 15,
        'pet_health': 100,
        'pet_last_update': oneHourAgo.millisecondsSinceEpoch,
      });

      // Act
      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert - Health should decrease when very unhappy
      expect(provider.health, lessThan(100));
    });

    test('should not decrease health when stats are healthy', () async {
      // Arrange
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      SharedPreferences.setMockInitialValues({
        'pet_hunger': 50,
        'pet_happiness': 70,
        'pet_health': 100,
        'pet_last_update': oneHourAgo.millisecondsSinceEpoch,
      });

      // Act
      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert - Health should remain 100 when stats are good
      expect(provider.health, equals(100));
    });

    test('should apply offline decay correctly for 6-hour gap', () async {
      // Arrange
      final sixHoursAgo = DateTime.now().subtract(const Duration(hours: 6));
      SharedPreferences.setMockInitialValues({
        'pet_hunger': 50,
        'pet_happiness': 70,
        'pet_health': 100,
        'pet_last_update': sixHoursAgo.millisecondsSinceEpoch,
      });

      // Act
      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      // Hunger: 50 + (6 * 3) = 68
      expect(provider.hunger, equals(68));
      // Happiness: 70 - (6 * 2) = 58
      expect(provider.happiness, equals(58));
      // Health: 100 (no critical stats)
      expect(provider.health, equals(100));
    });
  });

  group('CharacterProvider - Mood States', () {
    test('should return sick mood when health < 30', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'pet_hunger': 50,
        'pet_happiness': 70,
        'pet_health': 25,
      });

      // Act
      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      provider.wakeUp();

      // Assert
      expect(provider.mood, equals('sick'));
    });

    test('should return starving mood when hunger > 80', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'pet_hunger': 85,
        'pet_happiness': 50,
        'pet_health': 100,
      });

      // Act
      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      provider.wakeUp();

      // Assert
      expect(provider.mood, equals('starving'));
    });

    test('should return sad mood when happiness < 30', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'pet_hunger': 50,
        'pet_happiness': 25,
        'pet_health': 100,
      });

      // Act
      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      provider.wakeUp();

      // Assert
      expect(provider.mood, equals('sad'));
    });

    test('should return happy mood when happy & fed', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'pet_hunger': 20,
        'pet_happiness': 85,
        'pet_health': 100,
      });

      // Act
      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      provider.wakeUp();

      // Assert
      expect(provider.mood, equals('happy'));
    });

    test('should return neutral mood otherwise', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'pet_hunger': 50,
        'pet_happiness': 50,
        'pet_health': 100,
      });

      // Act
      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      provider.wakeUp();

      // Assert
      expect(provider.mood, equals('neutral'));
    });
  });

  group('CharacterProvider - Feeding', () {
    test('should consume item from inventory when feeding', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'pet_hunger': 80,
        'pet_happiness': 50,
        'pet_health': 80,
        'inventory': ['apple', 'coffee'],
      });

      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.inventory.contains('apple'), isTrue);

      // Act
      provider.feedPet('apple');
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(provider.inventory.contains('apple'), isFalse);
    });

    test('should restore hunger when feeding item', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'pet_hunger': 80,
        'pet_happiness': 50,
        'pet_health': 80,
        'inventory': ['apple', 'coffee'],
      });

      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      provider.feedPet('apple');
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert - Hunger should decrease (apple restores 10)
      expect(provider.hunger, lessThan(80));
    });

    test('should restore happiness when feeding item', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'pet_hunger': 50,
        'pet_happiness': 50,
        'pet_health': 80,
        'inventory': ['apple', 'coffee'],
      });

      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      final initialHappiness = provider.happiness;

      // Act
      provider.feedPet('apple');
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert - Happiness should increase
      expect(provider.happiness, greaterThanOrEqualTo(initialHappiness));
    });

    test('should recover health when well-fed and happy', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'pet_hunger': 30,
        'pet_happiness': 60,
        'pet_health': 80,
        'inventory': ['apple', 'coffee'],
      });

      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      provider.feedPet('apple');
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert - Health should increase by 5 when well-fed and happy
      expect(provider.health, equals(85));
    });
  });

  group('CharacterProvider - Petting Cooldown', () {
    test('first pet grants happiness', () async {
      SharedPreferences.setMockInitialValues({
        'pet_hunger': 50,
        'pet_happiness': 50,
        'pet_health': 80,
      });

      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.canEarnFromPetting, isTrue);
      expect(provider.petThePet(), isTrue);
      expect(provider.happiness, equals(58));
    });

    test('repeated petting inside the cooldown grants nothing', () async {
      SharedPreferences.setMockInitialValues({
        'pet_hunger': 50,
        'pet_happiness': 50,
        'pet_health': 80,
      });

      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      provider.petThePet();
      final afterFirstPet = provider.happiness;

      for (var i = 0; i < 20; i++) {
        expect(provider.petThePet(), isFalse);
      }

      expect(provider.happiness, equals(afterFirstPet));
      expect(provider.canEarnFromPetting, isFalse);
      expect(provider.petCooldownRemaining, greaterThan(Duration.zero));
    });

    test('cooldown survives a restart', () async {
      SharedPreferences.setMockInitialValues({
        'pet_hunger': 50,
        'pet_happiness': 50,
        'pet_health': 80,
      });

      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      provider.petThePet();
      await Future.delayed(const Duration(milliseconds: 50));

      // A fresh provider reads the persisted timestamp, so quitting the app
      // can't be used to farm happiness.
      final restarted = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(restarted.canEarnFromPetting, isFalse);
      expect(restarted.petThePet(), isFalse);
    });

    test('petting is available again once the cooldown has elapsed', () async {
      SharedPreferences.setMockInitialValues({
        'pet_hunger': 50,
        'pet_happiness': 50,
        'pet_health': 80,
        'pet_last_petted': DateTime.now()
            .subtract(CharacterProvider.petCooldown)
            .subtract(const Duration(minutes: 1))
            .millisecondsSinceEpoch,
      });

      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.canEarnFromPetting, isTrue);
      expect(provider.petCooldownRemaining, equals(Duration.zero));
      expect(provider.petThePet(), isTrue);
    });
  });

  group('CharacterProvider - Sickness Penalty', () {
    test('a healthy pet earns full rewards', () async {
      SharedPreferences.setMockInitialValues({
        'pet_hunger': 20,
        'pet_happiness': 80,
        'pet_health': 100,
      });

      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.isSick, isFalse);
      expect(provider.scaleReward(50), equals(50));
      expect(provider.scaleReward(20), equals(20));
    });

    test('a sick pet halves XP and coin rewards', () async {
      SharedPreferences.setMockInitialValues({
        'pet_hunger': 50,
        'pet_happiness': 50,
        'pet_health': 20, // below the sick threshold
      });

      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.isSick, isTrue);
      expect(provider.scaleReward(50), equals(25));
      expect(provider.scaleReward(15), equals(8)); // rounds, never to zero
    });

    test('medicine cures sickness and food alone does not', () async {
      SharedPreferences.setMockInitialValues({
        'pet_hunger': 60,
        'pet_happiness': 40,
        'pet_health': 20,
        'inventory': ['apple', 'medicine'],
      });

      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.isSick, isTrue);

      // An apple nudges hunger but leaves the pet sick.
      provider.feedPet('apple');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.isSick, isTrue);

      provider.feedPet('medicine');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.health, equals(70));
      expect(provider.isSick, isFalse);
      expect(provider.scaleReward(50), equals(50));
    });

    test('stale inventory ids are dropped rather than fed as a substitute',
        () async {
      SharedPreferences.setMockInitialValues({
        'pet_hunger': 60,
        'pet_happiness': 50,
        'pet_health': 80,
        'inventory': ['from_an_older_build'],
      });

      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      provider.feedPet('from_an_older_build');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.inventory, isEmpty);
      expect(provider.hunger, equals(60)); // unchanged
    });
  });

  group('CharacterProvider - ASCII Face', () {
    test('should change currentAsciiFace based on mood', () async {
      // Arrange - Test sick mood
      SharedPreferences.setMockInitialValues({
        'pet_hunger': 50,
        'pet_happiness': 50,
        'pet_health': 25, // Sick
      });

      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      provider.wakeUp();

      // Assert - Should show confused face when sick
      expect(provider.currentAsciiFace, isNotEmpty);
      expect(provider.mood, equals('sick'));

      // We can't test exact face since it depends on Faces constants,
      // but we can verify it returns a non-empty string
      expect(provider.currentAsciiFace.length, greaterThan(0));
    });
  });

  group('CharacterProvider - Persistence', () {
    test('should save pet state to SharedPreferences', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'pet_hunger': 50,
        'pet_happiness': 70,
        'pet_health': 100,
        'inventory': ['apple'],
      });

      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      provider.feedPet('apple');
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert - State should be persisted
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pet_hunger'), isNotNull);
      expect(prefs.getInt('pet_happiness'), isNotNull);
      expect(prefs.getInt('pet_health'), isNotNull);
    });

    test('should load pet state from SharedPreferences on creation', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'pet_hunger': 75,
        'pet_happiness': 60,
        'pet_health': 90,
      });

      // Act
      final provider = CharacterProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(provider.hunger, equals(75));
      expect(provider.happiness, equals(60));
      expect(provider.health, equals(90));
    });
  });
}
