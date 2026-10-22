import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/ai_limit_sheet.dart';
import 'package:mojilearner_flutter/constants/entitlements.dart';
import 'package:mojilearner_flutter/constants/gold.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_ads.dart';
import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// The wall a spent allowance puts up.
///
/// What these pin is the thing that makes a hard cap defensible at all: the
/// sheet always names something free the player can go and do, and the routes
/// out are offers rather than the only way forward. A version of this screen
/// that only said "come back tomorrow" would pass a test for the title and
/// still be the wrong product.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockUserProvider mockUser;
  late MockSettingsProvider mockSettings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockUser = MockUserProvider();
    mockSettings = MockSettingsProvider();

    when(() => mockSettings.usePixelFont).thenReturn(true);
    when(() => mockUser.coins).thenReturn(0);
    // The rewarded offer only appears to someone who has studied today; one
    // quiz payout is what puts them there. See `ads_provider.dart`.
    mockUser.awardLearningGold(6, GoldSource.quiz);
  });

  /// Puts the player at the wall the sheet is about, so the numbers it shows
  /// are the ones a real spent meter would produce.
  void spendMeter(AiSpend spend) => mockUser.exhaustAi(spend);

  Future<void> pumpSheet(
    WidgetTester tester,
    AiSpend spend, {
    bool rewardedReady = true,
  }) async {
    spendMeter(spend);
    await pumpApp(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => AiLimitSheet.show(context, spend),
          child: const Text('open'),
        ),
      ),
      userProvider: mockUser,
      settingsProvider: mockSettings,
      adsService: FakeAdsService(
        initializes: true,
        rewardedReady: rewardedReady,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('the quiz wall', () {
    testWidgets('says what ran out and when it comes back', (tester) async {
      await pumpSheet(tester, AiSpend.quiz);

      expect(find.textContaining('AI quizzes'), findsOneWidget);
      expect(find.text('Your allowance comes back tomorrow.'), findsOneWidget);
    });

    // The load-bearing assertion. Without this line the sheet is a door, and
    // a hard cap on studying is exactly what `gold.dart` refused to ship.
    testWidgets('names something free the player can still do', (tester) async {
      await pumpSheet(tester, AiSpend.quiz);

      expect(
        find.textContaining('Review never needs the tutor'),
        findsOneWidget,
      );
    });

    testWidgets('shows the allowance that was spent', (tester) async {
      await pumpSheet(tester, AiSpend.quiz);

      final quizzes = EntitlementConstants.free.quizzes;
      expect(find.text('$quizzes of $quizzes used today'), findsOneWidget);
    });

    testWidgets('offers the subscription', (tester) async {
      await pumpSheet(tester, AiSpend.quiz);

      expect(find.text('Get Mimikin Plus'), findsOneWidget);
    });

    // A day with no rewarded ad ready must not offer one, or the button is a
    // promise the app cannot keep.
    testWidgets('drops the ad offer when there is none to show',
        (tester) async {
      await pumpSheet(tester, AiSpend.quiz, rewardedReady: false);

      expect(find.text('Watch an ad for one more'), findsNothing);
      expect(find.text('Get Mimikin Plus'), findsOneWidget);
    });
  });

  group('the message wall', () {
    testWidgets('points at the free study that is left', (tester) async {
      await pumpSheet(tester, AiSpend.message);

      expect(find.textContaining('AI messages'), findsOneWidget);
      expect(
        find.text('Quizzes built from your own words are still there.'),
        findsOneWidget,
      );
    });

    // Ads buy quizzes and nothing else, so offering one here would be selling
    // a fix for the wrong meter.
    testWidgets('never offers an ad, which cannot refill it', (tester) async {
      await pumpSheet(tester, AiSpend.message);

      expect(find.text('Watch an ad for one more'), findsNothing);
      expect(find.text('Get Mimikin Plus'), findsOneWidget);
    });
  });
}
