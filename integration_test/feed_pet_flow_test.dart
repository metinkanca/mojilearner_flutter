import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mojilearner_flutter/main.dart' as app;
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

  group('Feed Pet Flow', () {
    setUp(() async {
      // Reset SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should feed pet and update stats successfully', (tester) async {
      // Arrange - Setup with inventory and initial stats
      SharedPreferences.setMockInitialValues({
        'inventory': ['apple', 'coffee'],
        'pet_hunger': 80,
        'pet_happiness': 50,
        'pet_health': 100,
      });

      // Pump full app
      await tester.pumpWidget(const app.MojiLearnerApp());
      await tester.pumpAndSettle();

      final characterProvider = readProvider<CharacterProvider>(tester);

      // Verify initial state
      expect(characterProvider.hunger, 80);
      expect(characterProvider.happiness, 50);
      expect(characterProvider.inventory.length, 2);

      // Act - Find and tap pet avatar to open feed dialog
      // The pet avatar is the GestureDetector wrapping the SVG
      final petAvatar = find.byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.onTap != null,
      ).first;
      await tester.tap(petAvatar);
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.text('FEED YOUR PET'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);

      // Tap apple to feed
      await tester.tap(find.text('Apple').first);
      await tester.pumpAndSettle();

      // Assert - Verify state changes
      expect(characterProvider.hunger, lessThan(80)); // Hunger decreased
      expect(characterProvider.happiness, greaterThan(50)); // Happiness increased
      expect(characterProvider.inventory.length, 1); // One item consumed
      expect(characterProvider.inventory.contains('coffee'), true);
      expect(characterProvider.inventory.contains('apple'), false);
      
      // Verify snackbar appeared
      expect(find.text('Fed Apple!'), findsOneWidget);
    });

    testWidgets('should restore health when feeding with good stats', (tester) async {
      // Arrange - Setup with good stats but low health
      SharedPreferences.setMockInitialValues({
        'inventory': ['pizza'],
        'pet_hunger': 30,
        'pet_happiness': 60,
        'pet_health': 80,
      });

      await tester.pumpWidget(const app.MojiLearnerApp());
      await tester.pumpAndSettle();

      final characterProvider = readProvider<CharacterProvider>(tester);

      final initialHealth = characterProvider.health;
      expect(initialHealth, 80);

      // Act - Tap pet avatar to open feed dialog
      final petAvatar = find.byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.onTap != null,
      ).first;
      await tester.tap(petAvatar);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pizza').first);
      await tester.pumpAndSettle();

      // Assert - Health should increase by 5 (since hunger < 50 and happiness > 50 after feeding)
      final finalHunger = characterProvider.hunger;
      final finalHappiness = characterProvider.happiness;
      final finalHealth = characterProvider.health;

      expect(finalHunger, lessThan(50)); // Should be well-fed
      expect(finalHappiness, greaterThan(50)); // Should be happy
      expect(finalHealth, greaterThan(initialHealth)); // Health increased
    });

    testWidgets('should show empty inventory message when no food items', (tester) async {
      // Arrange - Setup with empty inventory
      SharedPreferences.setMockInitialValues({
        'inventory': [],
        'pet_hunger': 80,
      });

      await tester.pumpWidget(const app.MojiLearnerApp());
      await tester.pumpAndSettle();

      // Act - Tap pet avatar to open feed dialog
      final petAvatar = find.byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.onTap != null,
      ).first;
      await tester.tap(petAvatar);
      await tester.pumpAndSettle();

      // Assert - Should show empty message
      expect(find.text('FEED YOUR PET'), findsOneWidget);
      expect(find.textContaining('No food items'), findsOneWidget);
      expect(find.textContaining('Buy some from the shop'), findsOneWidget);
      
      // No food items should be displayed
      expect(find.text('Apple'), findsNothing);
      expect(find.text('Coffee'), findsNothing);
    });
  });
}
