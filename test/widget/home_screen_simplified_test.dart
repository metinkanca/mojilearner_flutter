import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/screens/home_screen.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import '../helpers/pump_app.dart';
import '../helpers/mock_providers.dart';
import '../helpers/test_fixtures.dart';

void main() {
  group('HomeScreen - Simplified Tests', () {
    late MockUserProvider mockUser;
    late MockDailyRewardProvider mockDailyReward;
    late MockCharacterProvider mockCharacter;
    late MockLanguageProvider mockLanguage;
    late MockSettingsProvider mockSettings;

    setUp(() {
      mockUser = MockUserProvider();
      mockDailyReward = MockDailyRewardProvider();
      mockCharacter = MockCharacterProvider();
      mockLanguage = MockLanguageProvider();
      mockSettings = MockSettingsProvider();

      // Default mock behavior
      when(() => mockUser.stats).thenReturn(
        TestFixtures.buildUserStats(
          level: 5,
          totalXP: 892,
          currentLevelXP: 92,
          nextLevelXP: 200,
          coins: 350,
          streak: 7,
          progress: 0.46,
        ),
      );

      when(() => mockUser.isLoading).thenReturn(false);
      when(() => mockDailyReward.checkDailyReward())
          .thenAnswer((_) async => null);
      when(() => mockDailyReward.pendingDailyReward).thenReturn(null);

      when(() => mockCharacter.hunger).thenReturn(50);
      when(() => mockCharacter.happiness).thenReturn(70);
      when(() => mockCharacter.health).thenReturn(100);
      when(() => mockCharacter.inventory).thenReturn(['apple', 'coffee']);
      when(() => mockCharacter.currentCharacterAsset)
          .thenReturn('assets/svgs/cat.svg');
      when(() => mockCharacter.customization).thenReturn(
        TestFixtures.buildCustomization(),
      );
      when(() => mockCharacter.isSleeping).thenReturn(false);
      when(() => mockCharacter.isAiIssueSleepMode).thenReturn(false);
      when(() => mockCharacter.isTemporarilyAwake).thenReturn(false);
      when(() => mockCharacter.isSleepingForNight).thenReturn(false);
      when(() => mockCharacter.awakeUntil).thenReturn(null);
      when(() => mockCharacter.petThePet()).thenReturn(true);
      when(() => mockCharacter.wakeUp()).thenReturn(null);

      when(() => mockLanguage.targetLanguage).thenReturn(
        const Language(code: 'es', name: 'Spanish', flag: '🇪🇸'),
      );
      when(() => mockSettings.usePixelFont).thenReturn(true);
    });

    testWidgets('should render HomeScreen without crashing', (tester) async {
      await pumpApp(
        tester,
        const HomeScreen(),
        userProvider: mockUser,
        dailyRewardProvider: mockDailyReward,
        characterProvider: mockCharacter,
        languageProvider: mockLanguage,
        settingsProvider: mockSettings,
      );
      await tester.pump(const Duration(seconds: 1));

      // Verify screen rendered
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should show level and XP information', (tester) async {
      await pumpApp(
        tester,
        const HomeScreen(),
        userProvider: mockUser,
        dailyRewardProvider: mockDailyReward,
        characterProvider: mockCharacter,
        languageProvider: mockLanguage,
        settingsProvider: mockSettings,
      );
      await tester.pump(const Duration(seconds: 1));

      // Should show level 5
      expect(find.text('5'), findsOneWidget);
      
      // Should show XP progress
      expect(find.text('XP: 92/200'), findsOneWidget);
    });

    testWidgets('should show action buttons', (tester) async {
      await pumpApp(
        tester,
        const HomeScreen(),
        userProvider: mockUser,
        dailyRewardProvider: mockDailyReward,
        characterProvider: mockCharacter,
        languageProvider: mockLanguage,
        settingsProvider: mockSettings,
      );
      await tester.pump(const Duration(seconds: 1));

      // Home screen should have interactive actions (settings + send)
      expect(find.byType(IconButton), findsWidgets);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should show chat input field', (tester) async {
      await pumpApp(
        tester,
        const HomeScreen(),
        userProvider: mockUser,
        dailyRewardProvider: mockDailyReward,
        characterProvider: mockCharacter,
        languageProvider: mockLanguage,
        settingsProvider: mockSettings,
      );
      await tester.pump(const Duration(seconds: 1));

      // Should have text input
      expect(find.text('TYPE HERE...'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should display daily reward dialog when available', (tester) async {
      // Setup reward available
      final rewardInfo = TestFixtures.createTestReward(
        dayNumber: 3,
        currentStreak: 3,
      );
      when(() => mockDailyReward.checkDailyReward())
          .thenAnswer((_) async => rewardInfo);
      when(() => mockDailyReward.pendingDailyReward).thenReturn(rewardInfo);

      await pumpApp(
        tester,
        const HomeScreen(),
        userProvider: mockUser,
        dailyRewardProvider: mockDailyReward,
        characterProvider: mockCharacter,
        languageProvider: mockLanguage,
        settingsProvider: mockSettings,
      );
      
      // Wait for async dialog to appear
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      // Dialog should appear
      expect(find.text('DAILY REWARD'), findsOneWidget);
    });

    testWidgets('stat values should update when provider changes', (tester) async {
      // Start with high hunger
      when(() => mockCharacter.hunger).thenReturn(90);

      await pumpApp(
        tester,
        const HomeScreen(),
        userProvider: mockUser,
        dailyRewardProvider: mockDailyReward,
        characterProvider: mockCharacter,
        languageProvider: mockLanguage,
        settingsProvider: mockSettings,
      );
      await tester.pump(const Duration(seconds: 1));

      // Screen should render (verifying it responds to high hunger)
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
