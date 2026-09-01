import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/constants/ads.dart';
import 'package:mojilearner_flutter/constants/gold.dart';
import 'package:mojilearner_flutter/providers/ads_provider.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/screens/shop_screen.dart';
import 'package:mojilearner_flutter/services/ads_service.dart';
import 'package:mojilearner_flutter/screens/wardrobe_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_ads.dart';
import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// Where the player is actually offered a rewarded ad, and — just as much —
/// where they are not.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSettingsProvider mockSettings;
  late MockUserProvider mockUser;
  late MockLanguageProvider mockLanguage;
  late MockCalibrationProvider mockCalibration;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockSettings = MockSettingsProvider();
    mockUser = MockUserProvider();
    mockLanguage = MockLanguageProvider();
    mockCalibration = MockCalibrationProvider();
    when(() => mockSettings.usePixelFont).thenReturn(true);
    when(() => mockUser.coins).thenReturn(0);
    // The rewarded offer only appears to someone who has studied today; one
    // quiz payout is what puts them there. See `ads_provider.dart`.
    mockUser.awardLearningGold(6, GoldSource.quiz);
    when(() => mockLanguage.targetLanguage).thenReturn(
      const Language(code: 'es', name: 'Spanish'),
    );
    when(() => mockCalibration.getLanguageProficiency(any())).thenReturn(null);
  });

  /// The pet sprite animates continuously, so nothing here ever settles.
  Future<void> settle(WidgetTester tester) =>
      tester.pump(const Duration(milliseconds: 300));

  /// Tall enough that every wardrobe shelf lays out without scrolling.
  final tallSurface = Size(kHandsetSurface.width, 2400);

  final firstReward = AdsConstants.rewardedCoinLadder.first;

  group('the shop offer', () {
    Future<FakeAdsService> pumpShop(
      WidgetTester tester, {
      required bool rewardedReady,
      AdsProvider? adsProvider,
      MockUserProvider? user,
    }) async {
      final ads = FakeAdsService(
        initializes: true,
        rewardedReady: rewardedReady,
      );

      // The shop reads the unlocked set on every tile to grey out what is
      // already owned; nothing here is owned.
      final character = MockCharacterProvider();
      when(() => character.unlockedItems).thenReturn(<String>{});

      await pumpApp(
        tester,
        const ShopScreen(),
        characterProvider: character,
        settingsProvider: mockSettings,
        userProvider: user ?? mockUser,
        languageProvider: mockLanguage,
        calibrationProvider: mockCalibration,
        adsProvider: adsProvider,
        adsService: ads,
      );
      await settle(tester);
      return ads;
    }

    testWidgets('names the coins on offer and what is left today',
        (tester) async {
      await pumpShop(tester, rewardedReady: true);

      expect(find.text('FREE COINS'), findsOneWidget);
      expect(find.text('+$firstReward'), findsOneWidget);
      expect(
        find.text(
          '${AdsConstants.rewardedDailyLimit} of '
          '${AdsConstants.rewardedDailyLimit} left today',
        ),
        findsOneWidget,
      );
    });

    testWidgets('stays hidden until an ad has actually loaded',
        (tester) async {
      // A "watch for coins" button that does nothing when tapped is worse
      // than no button, so the offer waits for inventory in hand.
      await pumpShop(tester, rewardedReady: false);

      expect(find.text('FREE COINS'), findsNothing);
    });

    testWidgets('paying out credits the coins and counts down', (tester) async {
      final ads = await pumpShop(tester, rewardedReady: true);
      final ledgerBefore = mockUser.awardedGold.length;

      await tester.tap(find.text('FREE COINS'));
      await settle(tester);

      expect(ads.rewardedShowCount, equals(1));
      expect(mockUser.addedCoins, equals([firstReward]));
      // Paid, but never through the learning ledger: an ad must not advance
      // the daily taper and so shrink what the next quiz pays. The only entry
      // there is the one the setup seeded to open the gate. See
      // `constants/ads.dart`.
      expect(mockUser.awardedGold, hasLength(ledgerBefore));
      expect(
        find.text(
          '${AdsConstants.rewardedDailyLimit - 1} of '
          '${AdsConstants.rewardedDailyLimit} left today',
        ),
        findsOneWidget,
      );
    });

    testWidgets('is not offered before the player has studied today',
        (tester) async {
      // The gate that keeps ads a top-up rather than a route around the
      // content. A fresh user has earned nothing yet.
      final freshUser = MockUserProvider();
      when(() => freshUser.coins).thenReturn(0);

      await pumpShop(tester, rewardedReady: true, user: freshUser);

      expect(find.text('FREE COINS'), findsNothing);
    });

    testWidgets('disappears once the day is spent', (tester) async {
      // Installed before the ads are spent, because watchRewarded goes
      // through AdsService.I -- against the real service it would find no ad
      // loaded, pay nothing, and correctly consume no slots.
      AdsService.debugOverride =
          FakeAdsService(initializes: true, rewardedReady: true);
      addTearDown(() => AdsService.debugOverride = null);

      final spent = AdsProvider()
        ..updateEligibility(isPremium: false, hasLearnedToday: true);
      for (var i = 0; i < AdsConstants.rewardedDailyLimit; i++) {
        await spent.watchRewarded(MockUserProvider());
      }
      expect(spent.rewardedRemaining, isZero);

      await pumpShop(tester, rewardedReady: true, adsProvider: spent);

      expect(find.text('FREE COINS'), findsNothing);
    });
  });

  group('the wardrobe offer', () {
    Future<CharacterProvider> pumpWardrobe(
      WidgetTester tester, {
      bool rewardedReady = true,
    }) async {
      final character = CharacterProvider(startDecayTimer: false);

      await pumpApp(
        tester,
        const WardrobeScreen(),
        characterProvider: character,
        settingsProvider: mockSettings,
        userProvider: mockUser,
        languageProvider: mockLanguage,
        calibrationProvider: mockCalibration,
        adsService: FakeAdsService(
          initializes: true,
          rewardedReady: rewardedReady,
        ),
        surfaceSize: tallSurface,
      );
      await settle(tester);

      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        character.dispose();
      });
      return character;
    }

    testWidgets('a piece the player cannot afford offers a way to earn it',
        (tester) async {
      await pumpWardrobe(tester);

      await tester.tap(find.text('Bow Tie'));
      await settle(tester);

      expect(find.text('Not enough coins!'), findsOneWidget);
      expect(
        find.text('WATCH A VIDEO FOR +$firstReward'),
        findsOneWidget,
      );
    });

    testWidgets('a bond-gated piece never does', (tester) async {
      // The rule this test exists for. A bond-gated accessory has no price at
      // any number of coins, so an ad must not become a way around it —
      // that would turn a piece earned by learning into one that is bought.
      // See `accessory_ownership.dart` and `gold.dart`.
      await pumpWardrobe(tester);

      await tester.tap(find.text('Top Hat'));
      await settle(tester);

      expect(find.textContaining('WATCH A VIDEO'), findsNothing);
    });

    testWidgets('no offer appears when no ad has loaded', (tester) async {
      await pumpWardrobe(tester, rewardedReady: false);

      await tester.tap(find.text('Bow Tie'));
      await settle(tester);

      expect(find.text('Not enough coins!'), findsOneWidget);
      expect(find.textContaining('WATCH A VIDEO'), findsNothing);
    });
  });
}
