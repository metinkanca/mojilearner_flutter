import 'dart:io';
import 'dart:typed_data' show ByteData, Uint8List;
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mojilearner_flutter/constants/season_pass.dart';
import 'package:mojilearner_flutter/screens/season_pass_screen.dart';
import 'package:mojilearner_flutter/utils/season_pass_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// The season pass track.
///
/// The two things worth pinning are the two promises that make this not a
/// battle pass. Progress is measured from the purchase, so a player who buys
/// late is not behind — a pass bought at 9,000 XP shows an empty track, not a
/// completed one. And nothing expires, so a tier reached stays claimable
/// however long the player was away, which is why claiming hands over the
/// whole backlog at once instead of one rung per tap.
///
/// Set `SHOT_DIR` to also write a PNG of each state, for looking at the page
/// without building the app:
///
///     flutter test test/widget/season_pass_screen_test.dart \
///       --dart-define=SHOT_DIR=/tmp/shots
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const shotDir = String.fromEnvironment('SHOT_DIR');

  late MockUserProvider mockUser;
  late MockSettingsProvider mockSettings;
  late MockPremiumProvider mockStore;

  final pass = seasonPassById(kSeasonOneId)!;

  setUpAll(() async {
    // flutter_test renders every glyph as a box unless the real font is
    // loaded, which makes a captured PNG useless for judging the page.
    if (shotDir.isEmpty) return;
    final loader = FontLoader('PressStart2P')
      ..addFont(File('assets/fonts/PressStart2P-Regular.ttf')
          .readAsBytes()
          .then((b) => ByteData.view(Uint8List.fromList(b).buffer)));
    await loader.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockUser = MockUserProvider();
    mockSettings = MockSettingsProvider();
    mockStore = MockPremiumProvider();
    when(() => mockSettings.usePixelFont).thenReturn(true);
  });

  Future<void> pumpPass(WidgetTester tester, {String? shot}) async {
    await pumpApp(
      tester,
      const SeasonPassScreen(),
      userProvider: mockUser,
      settingsProvider: mockSettings,
      premiumProvider: mockStore,
      surfaceSize: const Size(400, 1500),
    );
    await tester.pumpAndSettle();
    if (shot != null && shotDir.isNotEmpty) {
      await _capture(tester, '$shotDir/$shot.png');
    }
  }

  /// Buys the pass with `xpAtPurchase` behind the player, then moves them on.
  void own({required int before, required int since, int claimed = -1}) {
    mockUser.totalXP = before + since;
    mockUser.ownedPasses = [
      OwnedPass(
        passId: pass.id,
        xpAtPurchase: before,
        claimedThroughTier: claimed,
      ),
    ];
  }

  testWidgets('an unowned pass shows the whole track and no price',
      (tester) async {
    await pumpPass(tester, shot: '1-unowned');

    expect(find.text(pass.name), findsWidgets);
    expect(find.text('This pass is not on sale yet.'), findsOneWidget);
    expect(find.text('Claim (1)'), findsNothing);
  });

  // The wardrobe opens the pass that carries the world the player tapped, which
  // is not always the one on sale. Without an id the page is still season one.
  testWidgets('a pass id opens that pass, not the one on sale', (tester) async {
    final two = seasonPassById(kSeasonTwoId)!;
    await pumpApp(
      tester,
      SeasonPassScreen(passId: two.id),
      userProvider: mockUser,
      settingsProvider: mockSettings,
      premiumProvider: mockStore,
      surfaceSize: const Size(400, 1500),
    );
    await tester.pumpAndSettle();

    expect(find.text(two.name), findsWidgets);
    expect(find.text(pass.name), findsNothing);
    // Its one rung is the world, named by the localised key, and nothing is
    // for sale: there is no listing for it.
    expect(find.text('Pumpkin Patch'), findsWidgets);
    expect(find.text('This pass is not on sale yet.'), findsOneWidget);
  });

  testWidgets('buying late is worth what buying early was', (tester) async {
    // A long-time player with a big balance buys today. Progress runs from the
    // purchase, so the track is empty rather than instantly complete.
    own(before: 9000, since: 0);
    await pumpPass(tester, shot: '2-just-bought');

    expect(find.text('Tier 0 / ${pass.tiers.length}'), findsOneWidget);
    expect(find.textContaining('500 XP to the next piece'), findsOneWidget);
  });

  testWidgets('a part-finished track offers everything reached at once',
      (tester) async {
    // Away for a while, back with four rungs owed and none taken.
    own(before: 0, since: 2200);
    await pumpPass(tester, shot: '3-backlog');

    expect(find.text('Tier 4 / ${pass.tiers.length}'), findsOneWidget);
    expect(find.text('Claim (4)'), findsOneWidget);
  });

  testWidgets('claimed rungs stop asking to be claimed', (tester) async {
    own(before: 0, since: 2200, claimed: 3);
    await pumpPass(tester, shot: '4-claimed');

    expect(find.text('Claim (4)'), findsNothing);
    expect(find.textContaining('XP to the next piece'), findsOneWidget);
  });

  testWidgets('a finished track says so', (tester) async {
    own(before: 0, since: pass.xpToComplete, claimed: pass.tiers.length - 1);
    await pumpPass(tester, shot: '5-complete');

    expect(find.text('Track complete.'), findsOneWidget);
  });

  testWidgets('a listed pass shows the price the store gave', (tester) async {
    // Never a price built here: the store's string carries the player's
    // currency and their region's tax rules.
    mockStore.isAvailable = true;
    mockStore.seasonPassProduct = _FakeProduct('£4.99');

    await pumpPass(tester, shot: '6-for-sale');

    expect(find.text('Buy £4.99'), findsOneWidget);
    expect(find.text('This pass is not on sale yet.'), findsNothing);

    await tester.tap(find.text('Buy £4.99'));
    await tester.pumpAndSettle();
    expect(mockStore.boughtPassIds, [pass.id]);
  });

  testWidgets('an owned pass is never offered for sale again', (tester) async {
    own(before: 0, since: 100);
    mockStore.isAvailable = true;
    mockStore.seasonPassProduct = _FakeProduct('£4.99');

    await pumpPass(tester);

    expect(find.textContaining('Buy'), findsNothing);
  });

  // The fitting room is the reason the track is cards rather than rows: a
  // piece is worth wanting only once you have seen it on your own pet, and
  // seeing it must not be the same act as owning it.
  testWidgets('a locked piece can be tried on without being granted',
      (tester) async {
    own(before: 0, since: 2200);
    await pumpPass(tester);

    // The card in the middle is the first unreached rung, which is exactly the
    // piece the player has not earned.
    await tester.tapAt(_onScreen(tester, 'TRY IT ON'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Not yours yet — this is only a look.'), findsOneWidget);
    // A preview is not a purchase: nothing was claimed and nothing equipped.
    verifyNever(() => mockUser.claimPassTiers(any()));
  });

  testWidgets('claiming hands over the backlog in one go', (tester) async {
    own(before: 0, since: 2200);
    when(() => mockUser.claimPassTiers(any()))
        .thenAnswer((_) async => const [0, 1, 2, 3]);

    await pumpPass(tester);
    await tester.tap(find.text('Claim (4)'));
    await tester.pumpAndSettle();

    verify(() => mockUser.claimPassTiers(pass.id)).called(1);
  });
}

/// The centre of the on-screen copy of [label].
///
/// A `PageView` builds the cards either side of the visible one too, so
/// `find.text(...).first` is usually a card that is off the edge of the screen
/// and cannot be tapped.
Offset _onScreen(WidgetTester tester, String label) {
  return find
      .byWidgetPredicate((w) => w is Text && w.data == label)
      .evaluate()
      .map((e) => tester.getCenter(find.byElementPredicate((x) => x == e)))
      .firstWhere((c) => c.dx > 0 && c.dx < 400);
}

/// A store listing, which is only ever read for its formatted price here.
class _FakeProduct extends Fake implements ProductDetails {
  _FakeProduct(this.price);

  @override
  final String price;

  @override
  String get id => seasonPassById(kSeasonOneId)!.productId;
}

/// Writes what the renderer actually produced, rather than a Chrome proxy.
///
/// `toImage` awaited directly inside `testWidgets` hangs until the test times
/// out; the `runAsync` wrapper is the whole trick.
Future<void> _capture(WidgetTester tester, String path) async {
  final boundary = tester.firstRenderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ImageByteFormat.png);
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
