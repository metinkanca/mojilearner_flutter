import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/daily_rewards_dialog.dart';
import 'package:mojilearner_flutter/components/reward_art.dart';
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
      // The flame is drawn, not typed. See [kFlameAsset].
      expect(find.text('🔥'), findsNothing);
      expect(
        find.byWidgetPredicate((w) =>
            w is SvgPicture &&
            (w.bytesLoader as SvgAssetLoader).assetName == kFlameAsset),
        findsOneWidget,
      );
    });

    // The reward is drawn from the app's own art, not from whatever the
    // platform's emoji font happens to ship, so the assertion is that a
    // picture is there and that no emoji is left doubling it.
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

      // Assert - the coin is a picture, and the amount reads as coins
      expect(find.byType(SvgPicture), findsWidgets);
      expect(find.text('🪙'), findsNothing);
      expect(find.text('12 coins'), findsOneWidget);
    });

    testWidgets('should show item reward icon and quantity when applicable',
        (tester) async {
      // Arrange
      final rewardInfo = TestFixtures.createTestReward(
        dayNumber: 3,
        claimCount: 3,
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

    // The pill is the only place the run of days is shown, and it is a
    // different number from the position in the cycle the seven boxes below
    // it draw. Someone thirty days in on the sixth reward sees both.
    testWidgets('shows the run of days, not the place in the cycle',
        (tester) async {
      final rewardInfo = TestFixtures.createTestReward(
        dayNumber: 6,
        claimCount: 34,
        loginStreak: 30,
      );

      await pumpApp(
        tester,
        DailyRewardsDialog(
          rewardInfo: rewardInfo,
          onClaim: () {},
        ),
        settingsProvider: mockSettings,
        languageProvider: mockLanguage,
      );

      expect(find.text('Day 30 Streak'), findsOneWidget);
      expect(find.text('Day 6 Streak'), findsNothing);
    });

    // Coming back after a gap is not an event the dialog marks. The cycle
    // carries on from where it stopped, so day one after a month away is the
    // same day one as any other — there is nothing to apologise for.
    testWidgets('never greets a returning player with a broken run',
        (tester) async {
      final rewardInfo = TestFixtures.createTestReward(
        dayNumber: 1,
        claimCount: 1,
      );

      await pumpApp(
        tester,
        DailyRewardsDialog(
          rewardInfo: rewardInfo,
          onClaim: () {},
        ),
        settingsProvider: mockSettings,
        languageProvider: mockLanguage,
      );

      expect(find.textContaining('Starting fresh'), findsNothing);
      expect(find.text('Keep it going!'), findsOneWidget);
    });

    testWidgets('should display "Amazing!" message when high streak',
        (tester) async {
      // Arrange
      final rewardInfo = TestFixtures.createTestReward(
        dayNumber: 7,
        claimCount: 7,
        loginStreak: 7,
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
        claimCount: 3,
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
        claimCount: 4,
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

      // Days 1-3 are collected and show a check. Day 4 is today: its reward
      // is still on the table until the claim button is pressed, so it draws
      // the reward rather than a check.
      expect(find.text('✓'), findsNWidgets(3));
      for (var day = 1; day <= 7; day++) {
        expect(find.byKey(ValueKey('daily-reward-day-$day')), findsOneWidget);
      }
    });

    // The boundary box: today is only stamped once the reward is actually
    // taken, so the row never claims credit for a day still in progress.
    testWidgets("today's box turns into a check once claimed",
        (tester) async {
      final rewardInfo = TestFixtures.createTestReward(
        dayNumber: 4,
        claimCount: 4,
      );

      await pumpApp(
        tester,
        DailyRewardsDialog(
          rewardInfo: rewardInfo,
          onClaim: () {},
        ),
        settingsProvider: mockSettings,
        languageProvider: mockLanguage,
      );

      expect(find.text('✓'), findsNWidgets(3));

      await tester.tap(find.text('CLAIM REWARD'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('✓'), findsNWidgets(4));

      await tester.pumpAndSettle(const Duration(seconds: 2));
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
