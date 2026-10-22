import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/character_sprite.dart';
import 'package:mojilearner_flutter/constants/pets.dart';
import 'package:mojilearner_flutter/components/purchase_dialogs.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:mojilearner_flutter/providers/user_provider.dart';
import 'package:mojilearner_flutter/screens/design_moji_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';
import '../helpers/test_fixtures.dart';

/// The character picker is a carousel: the chosen pet is centred, and the
/// swipe itself is what chooses. It goes through the real [CharacterProvider]
/// because the thing being checked is that the swipe reaches it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSettingsProvider mockSettings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockSettings = MockSettingsProvider();
    when(() => mockSettings.usePixelFont).thenReturn(true);
  });

  /// The pet sprites animate continuously, so nothing here ever settles —
  /// every wait is a bounded pump: one frame to start whatever was just
  /// triggered, then long enough for the page to snap into place.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  /// Less than a page, but past the halfway point, so the carousel snaps
  /// exactly one pet along — a longer drag would skip past its neighbour.
  const onePet = 120.0;

  Future<CharacterProvider> pumpPicker(
    WidgetTester tester, {
    UserProvider? user,
  }) async {
    final character = CharacterProvider(startDecayTimer: false);
    final mockUser = MockUserProvider();
    when(() => mockUser.coins).thenReturn(0);

    await pumpApp(
      tester,
      const DesignMojiScreen(),
      characterProvider: character,
      settingsProvider: mockSettings,
      userProvider: user ?? mockUser,
    );
    await settle(tester);

    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      character.dispose();
    });
    return character;
  }

  testWidgets('every pet is on the carousel, each drawn as itself',
      (tester) async {
    await pumpPicker(tester);

    // previewType is what makes a tile show that pet in its own saved design
    // rather than the pet currently out. Only the pets near the centred one
    // are built — a PageView does not build the whole rank — so this is the
    // cat it opens on and the neighbours either side of it.
    for (final type in const ['dog', 'cat', 'bird']) {
      expect(
        find.byWidgetPredicate(
          (w) => w is CharacterSprite && w.previewType == type,
        ),
        findsOneWidget,
        reason: '$type should have its own preview tile',
      );
    }
  });

  testWidgets('swiping to the next pet picks it', (tester) async {
    final character = await pumpPicker(tester);
    expect(character.currentCharacterType, 'cat'); // centred at the start

    await tester.drag(find.byType(PageView), const Offset(-onePet, 0));
    await settle(tester);

    expect(character.currentCharacterType, 'bird');
  });

  testWidgets('tapping a neighbour brings it to the centre', (tester) async {
    final character = await pumpPicker(tester);

    await tester.tap(find.text('Dog'));
    await settle(tester);

    expect(character.currentCharacterType, 'dog');
  });

  testWidgets('the pet already chosen is the one centred on open',
      (tester) async {
    SharedPreferences.setMockInitialValues({'character_type': 'bird'});
    final character = await pumpPicker(tester);

    // Opening the picker must not change the choice, and swiping back one
    // page from the centred pet lands on its left-hand neighbour.
    expect(character.currentCharacterType, 'bird');

    await tester.drag(find.byType(PageView), const Offset(onePet, 0));
    await settle(tester);

    expect(character.currentCharacterType, 'cat');
  });

  // The point of the layout: the chosen pet is the big one, and the pets to
  // either side are visibly there to be swiped to rather than slivers at the
  // edge of the screen.
  testWidgets('the rank has ends here — it does not wrap', (tester) async {
    await pumpPicker(tester);

    // Forward to the end of the rank from the cat it opens on, then on past
    // it — one more drag than there is rank to cover.
    for (var i = kPetTypes.indexOf('cat'); i < kPetTypes.length; i++) {
      await tester.drag(find.byType(PageView), const Offset(-onePet, 0));
      await settle(tester);
    }

    // The opening wraps so a short rank never dead-ends; this screen is
    // reached from the app with a pet already chosen, and keeps its ends:
    // the last pet is in the middle, and the first is nowhere near.
    Finder tileOf(String type) => find.byWidgetPredicate(
          (w) => w is CharacterSprite && w.previewType == type,
        );
    final centre = tester.getRect(tileOf(kPetTypes.last));
    final rank = tester.getRect(find.byType(PageView));
    expect(centre.center.dx, closeTo(rank.center.dx, 24));
    expect(tileOf(kPetTypes.first), findsNothing);
  });

  // ---- buying pets ---------------------------------------------------------

  /// Swipes from the cat to the first pet that is not a starter.
  Future<void> toFirstForSale(WidgetTester tester) async {
    final target = kPetTypes.indexWhere((t) => !isStarterPet(t));
    for (var i = kPetTypes.indexOf('cat'); i < target; i++) {
      await tester.drag(find.byType(PageView), const Offset(-onePet, 0));
      await settle(tester);
    }
  }

  String forSale() => kPetTypes.firstWhere((t) => !isStarterPet(t));

  testWidgets('a pet for sale shows its price and is not adopted by a swipe',
      (tester) async {
    final character = await pumpPicker(tester);

    await toFirstForSale(tester);

    // The last owned pet it passed is still the one out.
    expect(character.currentCharacterType, 'bird');
    expect(find.textContaining('$kPetPrice'), findsWidgets);
    expect(find.textContaining('BUY'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the starters carry no price', (tester) async {
    await pumpPicker(tester);

    // Dog, cat and bird are what is built around the opening centre.
    expect(find.textContaining('$kPetPrice'), findsNothing);
    expect(find.textContaining('BUY'), findsNothing);
  });

  testWidgets('buying a pet takes the coins and brings it out',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      ...TestFixtures.welcomeGiftAlreadyGiven,
      'coins': 1000,
    });
    final user = UserProvider();
    // Let its load finish before the screen reads the purse.
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)));
    final character = await pumpPicker(tester, user: user);

    await toFirstForSale(tester);
    await tester.tap(find.textContaining('BUY'));
    await settle(tester);
    expect(find.byType(BuyDialog), findsOneWidget);

    // The dialog's own BUY, not the one under the carousel behind it.
    await tester.tap(find.descendant(
      of: find.byType(BuyDialog),
      matching: find.text('BUY'),
    ));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)));
    await settle(tester);

    expect(character.ownsPet(forSale()), isTrue);
    expect(character.currentCharacterType, forSale());
    expect(user.coins, 1000 - kPetPrice);
    // Owned now, so no price is left on it.
    expect(find.textContaining('BUY'), findsNothing);
  });

  testWidgets('short of coins, it says so and sells nothing', (tester) async {
    final character = await pumpPicker(tester);

    await toFirstForSale(tester);
    await tester.tap(find.textContaining('BUY'));
    await settle(tester);

    expect(find.text('Not enough coins!'), findsOneWidget);
    expect(find.byType(BuyDialog), findsNothing);
    expect(character.ownsPet(forSale()), isFalse);
  });

  testWidgets('the chosen pet is the largest, the others clearly beside it',
      (tester) async {
    await pumpPicker(tester);

    Rect rectOf(String type) => tester.getRect(
          find.byWidgetPredicate(
            (w) => w is CharacterSprite && w.previewType == type,
          ),
        );

    final centre = rectOf('cat');
    final left = rectOf('dog');
    final right = rectOf('bird');
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;

    expect(centre.width, greaterThan(left.width));
    expect(centre.width, greaterThan(right.width));

    // Two thirds of each neighbour is on screen, and neither runs into the
    // chosen pet — the centre tile is drawn enlarged, so this is what keeps
    // it clear of them.
    expect(left.right, greaterThan(left.width * 0.6));
    expect(right.left, lessThan(screen.width - right.width * 0.6));
    expect(left.right, lessThan(centre.left));
    expect(right.left, greaterThan(centre.right));
  });

  testWidgets('the carousel lays out without overflowing a handset',
      (tester) async {
    await pumpPicker(tester);
    expect(tester.takeException(), isNull);
  });
}
