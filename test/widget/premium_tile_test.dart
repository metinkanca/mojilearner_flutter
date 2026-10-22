import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/premium_tile.dart';
import 'package:mojilearner_flutter/constants/entitlements.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// The profile's way in to Mimikin Plus.
///
/// The reason this component exists is the reason it is tested: before it, the
/// paywall's only entry point was the sheet shown when a day's allowance ran
/// out — so the single moment anyone saw the offer was the moment they had
/// just been refused. What is pinned here is that the tile states the player's
/// real position rather than a slogan, in both directions.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockUserProvider mockUser;
  late MockSettingsProvider mockSettings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockUser = MockUserProvider();
    mockSettings = MockSettingsProvider();
    when(() => mockSettings.usePixelFont).thenReturn(true);
  });

  Future<void> pumpTile(WidgetTester tester) async {
    await pumpApp(
      tester,
      const PremiumTile(),
      userProvider: mockUser,
      settingsProvider: mockSettings,
    );
    await tester.pump();
  }

  testWidgets('offers the upgrade and shows a fresh allowance',
      (tester) async {
    await pumpTile(tester);

    final quizzes = EntitlementConstants.free.quizzes;
    expect(find.text('Get Mimikin Plus'), findsOneWidget);
    expect(find.text('0 of $quizzes used today'), findsOneWidget);
  });

  // The product is a bigger number, so the honest advertisement for it is the
  // number the player currently has.
  testWidgets('counts up as the allowance is spent', (tester) async {
    await mockUser.spendAi(AiSpend.quiz);
    await mockUser.spendAi(AiSpend.quiz);

    await pumpTile(tester);

    final quizzes = EntitlementConstants.free.quizzes;
    expect(find.text('2 of $quizzes used today'), findsOneWidget);
  });

  testWidgets('tells a member they already have it', (tester) async {
    mockUser.isPremium = true;

    await pumpTile(tester);

    expect(find.text('Mimikin Plus is active.'), findsOneWidget);
    expect(find.text('Get Mimikin Plus'), findsNothing);
  });

  // A member's allowance is the larger one, so the count has to follow the
  // tier rather than quoting the free numbers at somebody who paid.
  testWidgets('a member sees the allowance they paid for', (tester) async {
    mockUser.isPremium = true;

    await pumpTile(tester);

    final quizzes = EntitlementConstants.premium.quizzes;
    expect(find.text('0 of $quizzes used today'), findsOneWidget);
  });

  // An ad adds to the meter rather than hiding inside it, so the total the
  // tile quotes has to move when one is watched.
  testWidgets('an ad shows up in the total', (tester) async {
    await mockUser.addRewardedQuiz();

    await pumpTile(tester);

    final total = EntitlementConstants.free.quizzes +
        EntitlementConstants.quizzesPerRewardedAd;
    expect(find.text('0 of $total used today'), findsOneWidget);
  });
}
