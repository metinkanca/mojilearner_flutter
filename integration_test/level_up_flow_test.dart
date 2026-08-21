import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mojilearner_flutter/main.dart' as app;
import 'package:mojilearner_flutter/providers/user_provider.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:mojilearner_flutter/utils/progression_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() async {
    // Initialize dotenv with test values
    await dotenv.load(fileName: ".env.test");
  });

  group('Level Up Flow', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should grant coins on single level up (level 1 to 2)', (tester) async {
      // Arrange - User with 90 XP (close to level 2 at 100 XP)
      SharedPreferences.setMockInitialValues({
        'total_xp': 90,
        'coins': 100,
      });

      await tester.pumpWidget(const app.MojiLearnerApp());
      await tester.pumpAndSettle();

      final userProvider = readProvider<UserProvider>(tester);

      // Verify initial state
      final initialLevel = ProgressionUtils.getLevelFromTotalXP(userProvider.stats.totalXP);
      expect(initialLevel, 1);
      expect(userProvider.coins, 100);

      // Act - Add 20 XP to trigger level up to level 2
      await userProvider.addXp(20); // Total: 110 XP -> Level 2
      await tester.pumpAndSettle();

      // Assert - Level increased
      final newLevel = ProgressionUtils.getLevelFromTotalXP(userProvider.stats.totalXP);
      expect(newLevel, 2);

      // Verify level 2 reward granted (150 coins from level rewards)
      // Total coins should be 100 + 150 = 250
      expect(userProvider.coins, 250);
    });

    testWidgets('should grant items on level up (level 2 to 3)', (tester) async {
      // Arrange - User at level 2 (280 XP is near level 3 threshold)
      SharedPreferences.setMockInitialValues({
        'total_xp': 280,
        'inventory': ['coffee'],
        'coins': 200,
      });

      await tester.pumpWidget(const app.MojiLearnerApp());
      await tester.pumpAndSettle();

      final userProvider = readProvider<UserProvider>(tester);
      final characterProvider = readProvider<CharacterProvider>(tester);

      final initialLevel = ProgressionUtils.getLevelFromTotalXP(userProvider.stats.totalXP);
      expect(initialLevel, 2);
      expect(characterProvider.inventory.length, 1);

      // Act - Add XP to reach level 3 (level 3 starts at 300 XP)
      await userProvider.addXp(30); // Total: 310 XP -> Level 3
      
      // Wait for reward to be processed
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Assert - Level increased to 3
      final newLevel = ProgressionUtils.getLevelFromTotalXP(userProvider.stats.totalXP);
      expect(newLevel, 3);

      // Level 3 reward should grant 3 apples (or other items based on progression.dart)
      // The items should be added to inventory
      expect(characterProvider.inventory.length, greaterThan(1));
    });

    testWidgets('should grant all rewards when skipping multiple levels', (tester) async {
      // Arrange - User at level 1 with 0 XP
      SharedPreferences.setMockInitialValues({
        'total_xp': 0,
        'coins': 0,
        'inventory': [],
      });

      await tester.pumpWidget(const app.MojiLearnerApp());
      await tester.pumpAndSettle();

      final userProvider = readProvider<UserProvider>(tester);
      final characterProvider = readProvider<CharacterProvider>(tester);

      expect(ProgressionUtils.getLevelFromTotalXP(0), 1);
      expect(userProvider.coins, 0);

      // Act - Add massive XP to jump multiple levels
      // Add 1500 XP to reach level ~8-10
      await userProvider.addXp(1500);
      
      // Wait for all rewards to be processed
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Assert - Should have leveled up significantly
      final finalLevel = ProgressionUtils.getLevelFromTotalXP(userProvider.stats.totalXP);
      expect(finalLevel, greaterThanOrEqualTo(5));

      // Should have received multiple rewards:
      // Level 1: 100 coins
      // Level 2: 150 coins
      // Level 3: 3 apples (items)
      // Level 4 and beyond: more coins/items
      
      // Verify coins increased significantly (at least level 1 + level 2 rewards)
      expect(userProvider.coins, greaterThanOrEqualTo(250)); // At minimum 100 + 150
      
      // Verify items were added to inventory
      expect(characterProvider.inventory.isNotEmpty, true);
    });
  });
}
