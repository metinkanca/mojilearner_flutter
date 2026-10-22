import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/constants/entitlements.dart';
import 'package:mojilearner_flutter/screens/premium_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// The paywall.
///
/// Two things worth pinning. The comparison table has to state the *real*
/// allowances, because the whole page is the argument that Plus is a bigger
/// number rather than a promise — a hardcoded "10" that drifted from
/// `EntitlementConstants` would be a paywall that lies. And a build with no
/// store products has to say so instead of drawing a button that cannot
/// charge, which is the state every build is in until the store console
/// catches up.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockUserProvider mockUser;
  late MockSettingsProvider mockSettings;
  late MockPremiumProvider mockPremium;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockUser = MockUserProvider();
    mockSettings = MockSettingsProvider();
    mockPremium = MockPremiumProvider();

    when(() => mockSettings.usePixelFont).thenReturn(true);
    when(() => mockUser.coins).thenReturn(0);
  });

  Future<void> pumpPaywall(WidgetTester tester) async {
    await pumpApp(
      tester,
      const PremiumScreen(),
      userProvider: mockUser,
      settingsProvider: mockSettings,
      premiumProvider: mockPremium,
      surfaceSize: const Size(400, 1200),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('states both tiers from the real allowances', (tester) async {
    await pumpPaywall(tester);

    expect(find.text('Free'), findsOneWidget);
    expect(find.text('Plus'), findsOneWidget);
    expect(
      find.text('${EntitlementConstants.free.quizzes}'),
      findsOneWidget,
    );
    expect(
      find.text('${EntitlementConstants.premium.quizzes}'),
      findsOneWidget,
    );
    expect(
      find.text('${EntitlementConstants.free.messages}'),
      findsOneWidget,
    );
    expect(
      find.text('${EntitlementConstants.premium.messages}'),
      findsOneWidget,
    );
  });

  // The page opens straight onto the table. Both doors into it — the shop's
  // Plus tab and `/premium` — have named the product by the time anyone
  // arrives, so a banner over the table was a screenful of height spent
  // repeating the tab that had just been tapped.
  testWidgets('opens on the comparison, with no banner above it',
      (tester) async {
    await pumpPaywall(tester);

    expect(find.text('MIMIKIN\nPLUS'), findsNothing);
    expect(find.textContaining('More room for the tutor'), findsNothing);

    // What the first row of the table says, still first.
    expect(find.text('AI quizzes a day'), findsOneWidget);
  });

  // The two rows that are not numbers. Both exist because the numbers alone
  // described the product badly: an allowance nobody reaches is not worth
  // paying for, and what a lapsed player actually dreads is the state they
  // will find the pet in.
  testWidgets('sells the two things that are not a bigger number',
      (tester) async {
    await pumpPaywall(tester);

    expect(find.text('Unused quizzes'), findsOneWidget);
    expect(find.text('Roll over'), findsOneWidget);
    expect(find.text('Pet stats'), findsOneWidget);
    expect(find.text('Decay slower'), findsOneWidget);
  });

  // Both halves of that row say the same verb on purpose. A cell reading
  // "Looked after" against "Declines" would promise an exemption, and the pet
  // still declines — it is time that was bought, not immunity.
  testWidgets('sells the slower slope as a rate, not an exemption',
      (tester) async {
    await pumpPaywall(tester);

    expect(find.text('Decay'), findsOneWidget);
    expect(find.text('Decay slower'), findsOneWidget);
  });

  testWidgets('admits when there is nothing to sell yet', (tester) async {
    mockPremium.isAvailable = false;

    await pumpPaywall(tester);

    expect(find.text('Subscriptions are not open yet.'), findsOneWidget);
    expect(find.text('Restore a purchase'), findsNothing);
  });

  testWidgets('tells an existing member they already have it', (tester) async {
    mockUser.isPremium = true;

    await pumpPaywall(tester);

    expect(find.text('Mimikin Plus is active.'), findsOneWidget);
    // Nothing to buy and nothing to restore for someone already subscribed.
    expect(find.text('Restore a purchase'), findsNothing);
  });

  testWidgets('waits quietly while the store finishes', (tester) async {
    mockPremium.isAvailable = true;
    mockPremium.isPurchasePending = true;

    await pumpPaywall(tester);

    expect(find.text('Finishing with the store…'), findsOneWidget);
  });
}
