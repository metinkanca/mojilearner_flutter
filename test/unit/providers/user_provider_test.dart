import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserProvider - Initialization', () {
    test('should load persisted user data from SharedPreferences', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'username': 'TestUser',
        'coins': 500,
        'streak': 5,
        'total_xp': 250,
        'last_login_date': '2026-02-10',
        'last_reward_claim_date': '2026-02-09',
      });

      // Act
      final provider = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100)); // Wait for loading

      // Assert
      expect(provider.username, equals('TestUser'));
      expect(provider.coins, equals(500));
      expect(provider.streak, equals(5));
      expect(provider.stats.totalXP, equals(250));
      expect(provider.isLoading, isFalse);
    });

    test('should initialize with default values when no persisted data', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});

      // Act
      final provider = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(provider.coins, equals(UserProvider.startingCoins));
      expect(provider.streak, equals(0));
      expect(provider.stats.totalXP, equals(0));
      expect(provider.stats.level, equals(1));
    });

    test('retires the legacy 999999 testing-mode balance once', () async {
      // Arrange - a tester carrying the old "infinite gold" sentinel
      SharedPreferences.setMockInitialValues({'coins': 999999});

      // Act
      final provider = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(provider.coins, equals(UserProvider.startingCoins));
    });

    test('does not reset a balance the player legitimately earned', () async {
      // Arrange - migration already ran; 999999 is now a real balance
      SharedPreferences.setMockInitialValues({
        'coins': 999999,
        'coins_testing_mode_migrated': true,
      });

      // Act
      final provider = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(provider.coins, equals(999999));
    });

    test('leaves ordinary balances untouched when migrating', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'coins': 120});

      // Act
      final provider = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(provider.coins, equals(120));
    });

    test('should emit notification when loading completes', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final provider = UserProvider();
      bool notified = false;
      
      provider.addListener(() {
        if (!provider.isLoading) {
          notified = true;
        }
      });

      // Act
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(notified, isTrue);
    });
  });

  group('UserProvider - XP & Leveling', () {
    test('should increase totalXP when addXp is called', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'total_xp': 50});
      final provider = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      await provider.addXp(30);

      // Assert
      expect(provider.stats.totalXP, equals(80));
      
      // Verify persisted
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('total_xp'), equals(80));
    });

    test('should trigger level up when XP crosses threshold', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'total_xp': 90});
      final provider = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.stats.level, equals(1));

      // Act
      await provider.addXp(20); // 90 + 20 = 110, should be level 2

      // Assert
      expect(provider.stats.totalXP, equals(110));
      expect(provider.stats.level, equals(2));
    });

    test('should emit event on onLevelUp stream when leveling up', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'total_xp': 90});
      final provider = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      int? levelUpEvent;
      provider.onLevelUp.listen((level) {
        levelUpEvent = level;
      });

      // Act
      await provider.addXp(20);
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(levelUpEvent, equals(2));
    });

    test('should handle multiple level ups in single addXp call', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'total_xp': 0});
      final provider = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      final levelUps = <int>[];
      provider.onLevelUp.listen((level) {
        levelUps.add(level);
      });

      // Act
      await provider.addXp(1000); // Should trigger multiple level ups (level 3)
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(provider.stats.level, greaterThanOrEqualTo(3));
      expect(levelUps.isNotEmpty, isTrue);
    });

    test('should grant level-up rewards correctly', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'total_xp': 90,
        'coins': 100,
      });
      final provider = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      final initialCoins = provider.coins;

      // Act
      await provider.addXp(20); // Level up to 2, should grant 150 coins
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(provider.coins, equals(initialCoins + 150));
    });
  });

  group('UserProvider - Coins', () {
    test('should increase coins when addCoins is called', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'coins': 100});
      final provider = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      await provider.addCoins(50);

      // Assert
      expect(provider.coins, equals(150));
      
      // Verify persisted
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('coins'), equals(150));
    });

    test('should decrease coins when spendCoins called with sufficient balance', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'coins': 100});
      final provider = UserProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      await provider.spendCoins(30);

      // Assert
      expect(provider.coins, equals(70));
      
      // Try to spend more than available
      await provider.spendCoins(200);
      expect(provider.coins, equals(70)); // Should not change
    });
  });

}
