import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mojilearner_flutter/main.dart' as app;
import 'package:mojilearner_flutter/providers/user_provider.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() async {
    // Initialize dotenv with test values
    await dotenv.load(fileName: ".env.test");
  });

  group('Quiz Flow', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should increase happiness and hunger after completing quiz (passed)', (tester) async {
      // Arrange - Setup initial pet stats
      SharedPreferences.setMockInitialValues({
        'pet_happiness': 50,
        'pet_hunger': 40,
        'total_xp': 50,
      });

      await tester.pumpWidget(const app.MojiLearnerApp());
      await tester.pumpAndSettle();

      final characterProvider = readProvider<CharacterProvider>(tester);
      final userProvider = readProvider<UserProvider>(tester);

      final initialHappiness = characterProvider.happiness;
      final initialHunger = characterProvider.hunger;
      final initialXP = userProvider.stats.totalXP;

      expect(initialHappiness, 50);
      expect(initialHunger, 40);

      // Act - Simulate completing a quiz by calling rewardQuiz directly
      // In a real integration test, we would navigate to quiz screen and complete it
      // For now, we'll trigger the reward directly to test the integration
      characterProvider.rewardQuiz(true); // Passed = true
      
      // Simulate XP gain from quiz (typical quiz grants 250-300 XP)
      await userProvider.addXp(250);
      await tester.pumpAndSettle();

      // Assert - Happiness increased (passed quiz)
      expect(characterProvider.happiness, greaterThan(initialHappiness));
      expect(characterProvider.happiness, 65); // 50 + 15 for passing
      
      // Hunger increased (quiz is tiring)
      expect(characterProvider.hunger, greaterThan(initialHunger));
      expect(characterProvider.hunger, 50); // 40 + 10 from quiz
      
      // XP increased
      expect(userProvider.stats.totalXP, greaterThan(initialXP));
      expect(userProvider.stats.totalXP, 300); // 50 + 250
    });

    testWidgets('should decrease happiness after failing quiz', (tester) async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'pet_happiness': 60,
        'pet_hunger': 30,
      });

      await tester.pumpWidget(const app.MojiLearnerApp());
      await tester.pumpAndSettle();

      final characterProvider = readProvider<CharacterProvider>(tester);

      final initialHappiness = characterProvider.happiness;
      final initialHunger = characterProvider.hunger;

      // Act - Simulate failing a quiz
      characterProvider.rewardQuiz(false); // Passed = false
      await tester.pumpAndSettle();

      // Assert - Happiness decreased (failed quiz)
      expect(characterProvider.happiness, lessThan(initialHappiness));
      expect(characterProvider.happiness, 55); // 60 - 5 for failing
      
      // Hunger still increased (quiz is tiring regardless)
      expect(characterProvider.hunger, greaterThan(initialHunger));
      expect(characterProvider.hunger, 40); // 30 + 10 from quiz
    });

    testWidgets('should grant XP and potentially level up after quiz completion', (tester) async {
      // Arrange - User close to level up
      SharedPreferences.setMockInitialValues({
        'total_xp': 90, // Close to level 2 (100 XP)
        'coins': 100,
        'pet_happiness': 50,
      });

      await tester.pumpWidget(const app.MojiLearnerApp());
      await tester.pumpAndSettle();

      final userProvider = readProvider<UserProvider>(tester);
      final characterProvider = readProvider<CharacterProvider>(tester);

      final initialLevel = userProvider.stats.level;
      final initialCoins = userProvider.coins;
      final initialHappiness = characterProvider.happiness;

      expect(initialLevel, 1);
      expect(initialCoins, 100);

      // Act - Complete quiz successfully
      characterProvider.rewardQuiz(true); // Increase happiness
      await userProvider.addXp(250); // Grant quiz XP
      await tester.pumpAndSettle();

      // Assert - Level up occurred (90 + 250 = 340 XP -> Level 3)
      final newLevel = userProvider.stats.level;
      expect(newLevel, greaterThan(initialLevel));
      expect(newLevel, greaterThanOrEqualTo(3)); // Should reach at least level 3
      
      // Coins increased from level up rewards
      expect(userProvider.coins, greaterThan(initialCoins));
      
      // Happiness increased from quiz
      expect(characterProvider.happiness, greaterThan(initialHappiness));
    });
  });
}
