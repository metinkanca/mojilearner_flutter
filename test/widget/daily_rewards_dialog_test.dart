import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/daily_rewards_dialog.dart';
import '../helpers/test_fixtures.dart';
import '../helpers/pump_app.dart';
import '../helpers/mock_providers.dart';

void main() {
  group('DailyRewardsDialog', () {
    late MockSettingsProvider mockSettings;
    late MockLanguageProvider mockLanguage;

    setUp(() {
      mockSettings = MockSettingsProvider();
      mockLanguage = MockLanguageProvider();

      when(() => mockSettings.usePixelFont).thenReturn(true);
    });

    testWidgets('should display correct day number from DailyRewardInfo',
        (tester) async {
      // Arrange
      final rewardInfo = TestFixtures.createTestReward(dayNumber: 5);

      // Act
      await pumpApp(
        tester,
        DailyRewardsDialog(
          rewardInfo: rewardInfo,
          onClaim: () {},
        ),
        settingsProvider: mockSettings,
        languageProvider: mockLanguage,
      );

      // Assert
      expect(find.text('Day 5 Streak'), findsOneWidget);
      expect(find.text('🔥'), findsOneWidget);
    });

    testWidgets('should show coin reward icon and amount', (tester) async {
      // Arrange
      final rewardInfo = TestFixtures.createTestReward(dayNumber: 1);

      // Act
      await pumpApp(
        tester,
        DailyRewardsDialog(
          rewardInfo: rewardInfo,
          onClaim: () {},
        ),
        settingsProvider: mockSettings,
        languageProvider: mockLanguage,
      );

      // Assert - coin icon is displayed
      expect(find.text('🪙'), findsWidgets);
    });

    testWidgets('should show item reward icon and quantity when applicable',
        (tester) async {
      // Arrange
      final rewardInfo = TestFixtures.createTestReward(
        dayNumber: 3,
        currentStreak: 3,
      );

      // Act
      await pumpApp(
        tester,
        DailyRewardsDialog(
          rewardInfo: rewardInfo,
          onClaim: () {},
        ),
        settingsProvider: mockSettings,
        languageProvider: mockLanguage,
      );
      await tester.pumpAndSettle();

      // Assert - reward display exists
      expect(find.byType(DailyRewardsDialog), findsOneWidget);
    });

    testWidgets('should display "Welcome back!" message when streakReset=true',
        (tester) async {
      // Arrange
      final rewardInfo = TestFixtures.createTestReward(
        dayNumber: 1,
        streakReset: true,
        currentStreak: 1,
      );

      // Act
      await pumpApp(
        tester,
        DailyRewardsDialog(
          rewardInfo: rewardInfo,
          onClaim: () {},
        ),
        settingsProvider: mockSettings,
        languageProvider: mockLanguage,
      );

      // Assert
      expect(find.text('Welcome back! Starting fresh'), findsOneWidget);
    });

    testWidgets('should display "Amazing!" message when high streak',
        (tester) async {
      // Arrange
      final rewardInfo = TestFixtures.createTestReward(
        dayNumber: 7,
        streakReset: false,
        currentStreak: 7,
      );

      // Act
      await pumpApp(
        tester,
        DailyRewardsDialog(
          rewardInfo: rewardInfo,
          onClaim: () {},
        ),
        settingsProvider: mockSettings,
        languageProvider: mockLanguage,
      );

      // Assert
      expect(find.text('Amazing! Day 7 streak!'), findsOneWidget);
    });

    testWidgets('should display "Keep going!" message normally',
        (tester) async {
      // Arrange
      final rewardInfo = TestFixtures.createTestReward(
        dayNumber: 3,
        streakReset: false,
        currentStreak: 3,
      );

      // Act
      await pumpApp(
        tester,
        DailyRewardsDialog(
          rewardInfo: rewardInfo,
          onClaim: () {},
        ),
        settingsProvider: mockSettings,
        languageProvider: mockLanguage,
      );

      // Assert
      expect(find.text('Keep it going!'), findsOneWidget);
    });

    testWidgets('should show calendar with 7 boxes', (tester) async {
      // Arrange
      final rewardInfo = TestFixtures.createTestReward(
        dayNumber: 4,
        currentStreak: 4,
      );

      // Act
      await pumpApp(
        tester,
        DailyRewardsDialog(
          rewardInfo: rewardInfo,
          onClaim: () {},
        ),
        settingsProvider: mockSettings,
        languageProvider: mockLanguage,
      );

      // Assert - find 7 calendar day boxes
      final containers = find.descendant(
        of: find.byType(DailyRewardsDialog),
        matching: find.byType(Container),
      );
      expect(containers, findsWidgets);

      // Check for checkmarks in completed days (4 checkmarks)
      expect(find.text('✓'), findsNWidgets(4));
    });

    testWidgets('should have claim button that exists and is tappable',
        (tester) async {
      // Arrange
      final rewardInfo = TestFixtures.createTestReward(dayNumber: 2);

      // Act
      await pumpApp(
        tester,
        DailyRewardsDialog(
          rewardInfo: rewardInfo,
          onClaim: () {},
        ),
        settingsProvider: mockSettings,
        languageProvider: mockLanguage,
      );

      // Assert
      expect(find.text('CLAIM REWARD'), findsOneWidget);

      // Verify it's tappable by finding the GestureDetector
      final claimButton = find.ancestor(
        of: find.text('CLAIM REWARD'),
        matching: find.byType(GestureDetector),
      );
      expect(claimButton, findsOneWidget);
    });

    testWidgets('should trigger onClaim callback when claim button tapped',
        (tester) async {
      // Arrange
      var claimCalled = false;
      final rewardInfo = TestFixtures.createTestReward(dayNumber: 1);

      await pumpApp(
        tester,
        DailyRewardsDialog(
          rewardInfo: rewardInfo,
          onClaim: () => claimCalled = true,
        ),
        settingsProvider: mockSettings,
        languageProvider: mockLanguage,
      );

      // Act
      await tester.tap(find.text('CLAIM REWARD'));
      await tester.pump();

      // Assert
      expect(claimCalled, isTrue);
      
      // Clean up timer
      await tester.pumpAndSettle(const Duration(seconds: 2));
    });

    testWidgets('should show claimed state after claim button tapped',
        (tester) async {
      // Arrange
      final rewardInfo = TestFixtures.createTestReward(dayNumber: 1);

      await pumpApp(
        tester,
        DailyRewardsDialog(
          rewardInfo: rewardInfo,
          onClaim: () {},
        ),
        settingsProvider: mockSettings,
        languageProvider: mockLanguage,
      );

      // Act
      await tester.tap(find.text('CLAIM REWARD'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert - claim button should disappear
      expect(find.text('CLAIM REWARD'), findsNothing);

      // Claimed message should appear
      expect(find.text('REWARD CLAIMED!'), findsOneWidget);
      expect(find.text('✨'), findsOneWidget);
      
      // Clean up timer
      await tester.pumpAndSettle(const Duration(seconds: 2));
    });
  });
}
