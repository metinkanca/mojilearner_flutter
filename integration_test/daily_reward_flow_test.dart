import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mojilearner_flutter/main.dart' as app;
import 'package:mojilearner_flutter/components/daily_rewards_dialog.dart';
import 'package:mojilearner_flutter/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() async {
    // Initialize dotenv with test values
    await dotenv.load(fileName: ".env.test");
  });

  group('Daily Reward Flow', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should NOT show dialog on first-ever app launch', (tester) async {
      // Arrange - First time user (no lastRewardClaimDate)
      SharedPreferences.setMockInitialValues({
        'coins': 100,
        'streak': 0,
      });

      // Act - Pump app
      await tester.pumpWidget(const app.MojiLearnerApp());
      
      // Wait for the daily reward check (500ms delay in HomeScreen)
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Assert - No dialog should appear
      expect(find.byType(DailyRewardsDialog), findsNothing);
    });

    testWidgets('should show and claim daily reward on consecutive day', (tester) async {
      // Arrange - Last reward was yesterday
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
      
      SharedPreferences.setMockInitialValues({
        'last_reward_claim_date': yesterdayDate.toIso8601String(),
        'streak': 1,
        'coins': 100,
      });

      await tester.pumpWidget(const app.MojiLearnerApp());
      
      // Wait for daily reward check
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Assert - Dialog should appear
      expect(find.byType(DailyRewardsDialog), findsOneWidget);
      expect(find.textContaining('Day 2'), findsOneWidget);

      // Get provider to check initial state
      final userProvider = readProvider<UserProvider>(tester);
      final initialCoins = userProvider.coins;
      final initialStreak = userProvider.streak;

      expect(initialStreak, 1);

      // Act - Claim reward
      await tester.tap(find.text('CLAIM REWARD'));
      await tester.pump();
      
      // Wait for claim animation and auto-close (1500ms)
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      // Assert - Dialog closed
      expect(find.byType(DailyRewardsDialog), findsNothing);

      // Verify streak incremented to 2
      expect(userProvider.streak, 2);

      // Verify coins increased (Day 2 reward = 75 coins)
      expect(userProvider.coins, greaterThan(initialCoins));
      
      // Verify success message
      expect(find.text('Reward claimed! 🎉'), findsOneWidget);
    });

    testWidgets('should reset streak when day is missed', (tester) async {
      // Arrange - Last reward was 3 days ago
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final threeDaysAgoDate = DateTime(threeDaysAgo.year, threeDaysAgo.month, threeDaysAgo.day);
      
      SharedPreferences.setMockInitialValues({
        'last_reward_claim_date': threeDaysAgoDate.toIso8601String(),
        'streak': 5, // Old streak that should reset
        'coins': 100,
      });

      await tester.pumpWidget(const app.MojiLearnerApp());
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Assert - Dialog appears with reset message
      expect(find.byType(DailyRewardsDialog), findsOneWidget);
      expect(find.textContaining('Day 1'), findsOneWidget); // Reset to day 1
      
      // Should show "Welcome back!" or "Starting fresh" message
      final welcomeBackText = find.textContaining('Welcome back');
      final startingFreshText = find.textContaining('Starting fresh');
      expect(welcomeBackText.evaluate().isNotEmpty || startingFreshText.evaluate().isNotEmpty, true);

      final userProvider = readProvider<UserProvider>(tester);
      final initialCoins = userProvider.coins;

      // Act - Claim reward
      await tester.tap(find.text('CLAIM REWARD'));
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      // Assert - Streak reset to 1
      expect(userProvider.streak, 1);
      
      // Verify Day 1 reward granted (50 coins)
      expect(userProvider.coins, greaterThan(initialCoins));
    });

    testWidgets('should NOT show dialog if already claimed today', (tester) async {
      // Arrange - Already claimed today
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      SharedPreferences.setMockInitialValues({
        'last_reward_claim_date': today.toIso8601String(),
        'streak': 3,
        'coins': 200,
      });

      await tester.pumpWidget(const app.MojiLearnerApp());
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Assert - No dialog should appear
      expect(find.byType(DailyRewardsDialog), findsNothing);
    });
  });
}
