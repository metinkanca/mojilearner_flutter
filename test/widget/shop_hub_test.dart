import 'dart:io';
import 'dart:typed_data' show ByteData, Uint8List;
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/constants/coin_packs.dart';
import 'package:mojilearner_flutter/screens/coin_shop_screen.dart';
import 'package:mojilearner_flutter/screens/shop_hub_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// The shop's slider, and the top-up counter behind one of its tabs.
///
/// What is worth pinning here is that the sections are **tabs and not pages**.
/// A tap must swap what is under the strip while leaving the strip, the title
/// and the balance exactly where they were — if any of those moved, the shop
/// would be navigating, which is the thing this screen exists not to do.
///
/// Set `SHOT_DIR` to also write a PNG of each state, for looking at the screen
/// without building the app:
///
///     flutter test test/widget/shop_hub_test.dart --dart-define=SHOT_DIR=/tmp/shots
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const shotDir = String.fromEnvironment('SHOT_DIR');

  late MockSettingsProvider settings;
  late MockUserProvider user;
  late MockCharacterProvider character;
  late MockPremiumProvider store;

  setUpAll(() async {
    // flutter_test renders every glyph as a box unless the real font is
    // loaded, which makes a captured PNG useless for judging the screen.
    if (shotDir.isEmpty) return;
    final loader = FontLoader('PressStart2P')
      ..addFont(File('assets/fonts/PressStart2P-Regular.ttf')
          .readAsBytes()
          .then((b) => ByteData.view(Uint8List.fromList(b).buffer)));
    await loader.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    settings = MockSettingsProvider();
    user = MockUserProvider();
    character = MockCharacterProvider();
    store = MockPremiumProvider();
    when(() => settings.usePixelFont).thenReturn(true);
    when(() => user.coins).thenReturn(250);
    // The shelves read the unlocked set on every tile to grey out what is
    // already owned; nothing here is owned.
    when(() => character.unlockedItems).thenReturn(<String>{});
  });

  /// Puts a price on every coin pack. One listing for all of them: most of
  /// these tests are about the ladder, not about which rung costs what.
  void listEveryPack() {
    store.isAvailable = true;
    store.coinPackListing = _FakeProduct('£0.99');
  }

  /// Prices the rungs the way a console actually would, for the screenshots
  /// and for the one test that reads a price off a particular row. Sterling,
  /// because the point of a store price is that it is not the dollar figure
  /// the ladder is written in.
  void priceEachPack() {
    listEveryPack();
    const prices = ['£0.89', '£1.69', '£3.29', '£5.99', '£11.49', '£21.99'];
    for (var i = 0; i < coinPacks.length; i++) {
      store.coinPackListings[coinPacks[i].id] = _FakeProduct(prices[i]);
    }
  }

  Future<void> pumpShop(WidgetTester tester, {String? shot}) async {
    await pumpApp(
      tester,
      const ShopHubScreen(),
      settingsProvider: settings,
      userProvider: user,
      characterProvider: character,
      premiumProvider: store,
      // Tall enough that a whole section lays out without scrolling, so a row
      // below the fold cannot silently fail to be tappable.
      surfaceSize: const Size(400, 1400),
    );
    await tester.pumpAndSettle();
    if (shot != null && shotDir.isNotEmpty) {
      await _capture(tester, '$shotDir/$shot.png');
    }
  }

  /// Moves to a section by tapping its tab, as a player would.
  Future<void> openTab(WidgetTester tester, String title,
      {String? shot}) async {
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
    if (shot != null && shotDir.isNotEmpty) {
      await _capture(tester, '$shotDir/$shot.png');
    }
  }

  group('the slider', () {
    testWidgets('names all four sections and nothing else', (tester) async {
      await pumpShop(tester);

      for (final title in ['ITEMS', 'TOP UP', 'PLUS', 'SEASON PASS']) {
        expect(find.text(title), findsOneWidget);
      }
    });

    testWidgets('opens on the shelves', (tester) async {
      await pumpShop(tester, shot: '1-items');

      // The category row belongs to the shelves, so its presence is what says
      // which section is showing.
      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('a tab swaps the section under the strip', (tester) async {
      listEveryPack();
      await pumpShop(tester);
      await openTab(tester, 'TOP UP');

      expect(find.text('${coinPacks.first.coins} COINS'), findsOneWidget);
      expect(find.text('Food'), findsNothing);
    });

    testWidgets('the strip, the title and the balance never move',
        (tester) async {
      listEveryPack();
      await pumpShop(tester);
      final stripBefore = tester.getRect(find.text('SEASON PASS'));

      await openTab(tester, 'TOP UP');

      expect(tester.getRect(find.text('SEASON PASS')), stripBefore);
      expect(find.text('SHOP'), findsOneWidget);
      expect(find.text('250'), findsOneWidget);
    });

    testWidgets('no section is a page, so there is nothing to go back from',
        (tester) async {
      await pumpShop(tester);
      await openTab(tester, 'PLUS');

      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('a section keeps its state while another is on top',
        (tester) async {
      await pumpShop(tester);
      // Filter the shelves, leave, come back.
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      await openTab(tester, 'PLUS');
      await openTab(tester, 'ITEMS');

      expect(find.text('Apple'.toUpperCase()), findsOneWidget);
      expect(find.text('Meadow'.toUpperCase()), findsNothing);
    });
  });

  group('the top-up counter', () {
    testWidgets('falls back to the list price when the store has no listings',
        (tester) async {
      await pumpShop(tester);
      await openTab(tester, 'TOP UP', shot: '3-topup-unlisted');

      // The ladder is still readable — the piles, the coins and what each one
      // lists for — under a line saying the counter is not open.
      expect(find.text('Coin packs are not open yet.'), findsOneWidget);
      expect(find.text(coinPacks.first.usdPrice), findsOneWidget);
      expect(find.text(coinPacks.last.usdPrice), findsOneWidget);
      // And nothing on the page is the store's, because the store said
      // nothing.
      expect(find.text('£0.89'), findsNothing);
    });

    testWidgets('a rung that cannot be bought yet says so when tapped',
        (tester) async {
      await pumpShop(tester);
      await openTab(tester, 'TOP UP');

      await tester.tap(find.text('${coinPacks.first.coins} COINS'));
      await tester.pump();

      // Twice on the screen now: the line above the ladder, and the bar that
      // answered the tap. A tile that did nothing at all would read as broken.
      expect(find.text('Coin packs are not open yet.'), findsNWidgets(2));
      expect(store.boughtCoinPackIds, isEmpty);
    });

    testWidgets('a store price beats the list price', (tester) async {
      priceEachPack();
      await pumpShop(tester);
      await openTab(tester, 'TOP UP');

      expect(find.text('£0.89'), findsOneWidget);
      expect(find.text(coinPacks.first.usdPrice), findsNothing);
    });

    testWidgets('shows every rung with the coins it hands over',
        (tester) async {
      priceEachPack();
      await pumpShop(tester);
      await openTab(tester, 'TOP UP', shot: '2-topup');

      for (final pack in coinPacks) {
        expect(find.text('${pack.coins} COINS'), findsOneWidget,
            reason: '${pack.id} is missing from the ladder');
      }
    });

    testWidgets('draws a coin for every rung it climbs', (tester) async {
      listEveryPack();
      await pumpShop(tester);
      await openTab(tester, 'TOP UP');

      // One coin on the first rung, six on the last: the picture of the
      // difference between the packs is more of the same coin.
      for (var i = 0; i < coinPacks.length; i++) {
        final pile = tester.widget<CoinPile>(find.byType(CoinPile).at(i));
        expect(pile.count, i + 1);
      }
    });

    testWidgets('badges the bonus on every rung but the anchor',
        (tester) async {
      listEveryPack();
      await pumpShop(tester);
      await openTab(tester, 'TOP UP');

      // The base pack sets the rate, so it has no bonus to advertise.
      expect(find.text('+0% COINS'), findsNothing);
      for (final pack in coinPacks.skip(1)) {
        expect(find.text('+${pack.bonusPercent}% COINS'), findsOneWidget);
      }
    });

    testWidgets('quotes the price the store gave it, rung by rung',
        (tester) async {
      // Never a price built here out of the store's and the ladder's: the
      // store's string carries the player's currency and their region's tax
      // rules, and it wins whole.
      priceEachPack();
      await pumpShop(tester);
      await openTab(tester, 'TOP UP');

      expect(find.text('£0.89'), findsOneWidget);
      expect(find.text('£21.99'), findsOneWidget);
    });

    testWidgets('flags only the top rung as the best value', (tester) async {
      listEveryPack();
      await pumpShop(tester);
      await openTab(tester, 'TOP UP');

      expect(find.text('BEST VALUE'), findsOneWidget);
    });

    testWidgets('says nothing about what coins are for', (tester) async {
      listEveryPack();
      await pumpShop(tester);
      await openTab(tester, 'TOP UP');

      // The counter is the ladder and nothing else — a player on this screen
      // has already spent coins and does not need them explained.
      expect(find.textContaining('Coins buy'), findsNothing);
      expect(find.textContaining('coins per'), findsNothing);
    });

    testWidgets('tapping a rung asks the store for that pack', (tester) async {
      listEveryPack();
      await pumpShop(tester);
      await openTab(tester, 'TOP UP');

      final pack = coinPacks[2];
      await tester.tap(find.text('${pack.coins} COINS'));
      await tester.pump();

      expect(store.boughtCoinPackIds, [pack.id]);
    });

    testWidgets('a completed purchase says what it added', (tester) async {
      listEveryPack();
      store.coinsGranted = 1200;
      await pumpShop(tester);
      await openTab(tester, 'TOP UP');

      expect(find.text('Added 1200 coins.'), findsOneWidget);
    });
  });

  group('the pass', () {
    testWidgets('no longer lists what it does not contain', (tester) async {
      await pumpShop(tester);
      await openTab(tester, 'SEASON PASS', shot: '4-pass');

      expect(
        find.text('Cosmetics only. No coins, no food, no XP.'),
        findsNothing,
      );
    });
  });
}

class _FakeProduct extends Fake implements ProductDetails {
  _FakeProduct(this.price);

  @override
  final String price;
}

/// Writes what the screen currently looks like to a PNG.
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
