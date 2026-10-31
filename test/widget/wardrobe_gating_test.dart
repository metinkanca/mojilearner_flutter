import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/constants/accessories.dart';
import 'package:mojilearner_flutter/constants/bond.dart';
import 'package:mojilearner_flutter/constants/pets.dart';
import 'package:mojilearner_flutter/constants/scenes.dart';
import 'package:mojilearner_flutter/constants/season_pass.dart';
import 'package:mojilearner_flutter/constants/shop.dart';
import 'package:mojilearner_flutter/models/models.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/screens/wardrobe_screen.dart';
import 'package:mojilearner_flutter/utils/pet_recolor.dart';
import 'package:mojilearner_flutter/utils/progression_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// The wardrobe is where the gating is actually felt, so these go through the
/// real [CharacterProvider] rather than a mock — the guard being tested lives
/// in it, and a mock would only prove the screen calls a method.
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
    when(() => mockLanguage.targetLanguage).thenReturn(
      const Language(code: 'es', name: 'Spanish'),
    );
    when(() => mockCalibration.getLanguageProficiency(any())).thenReturn(null);
  });

  /// Tall enough that every shelf lays out without scrolling, at handset
  /// width — the tests tap tiles on more than one shelf.
  final surface = Size(kHandsetSurface.width, 2400);

  /// The pet sprite animates continuously, so nothing in this screen ever
  /// settles — every wait here is a bounded pump.
  Future<void> settle(WidgetTester tester) =>
      tester.pump(const Duration(milliseconds: 300));

  /// Scrolls a tile into view, then taps it.
  ///
  /// The wardrobe is taller than the test surface and grows with every
  /// accessory the catalogue gains, so a bare tap below the shelves lands
  /// outside the view and does nothing. That is not a visible failure here --
  /// it reads as "the tap changed nothing", which is exactly what some of
  /// these tests assert -- so scenery taps go through this rather than
  /// trusting a fixed layout.
  Future<void> tapTile(WidgetTester tester, String label) async {
    final tile = find.text(label);
    await tester.ensureVisible(tile);
    await settle(tester);
    await tester.tap(tile);
  }

  /// Cumulative XP for the level the Attached stage gates on, off the real
  /// curve and gates.
  final attachedXP = ProgressionUtils.getTotalXPForLevel(
      petStageGates.firstWhere((g) => g.stage == PetStage.attached).minLevel);

  Future<CharacterProvider> pumpWardrobe(
    WidgetTester tester, {
    int totalXP = 0,
    List<String> unlockedItems = const [],
  }) async {
    final prefs = <String, Object>{
      if (unlockedItems.isNotEmpty) 'unlocked_items': unlockedItems,
    };
    if (prefs.isNotEmpty) {
      SharedPreferences.setMockInitialValues(prefs);
    }
    mockUser.totalXP = totalXP;
    final character = CharacterProvider(startDecayTimer: false);

    await pumpApp(
      tester,
      const WardrobeScreen(),
      characterProvider: character,
      settingsProvider: mockSettings,
      userProvider: mockUser,
      languageProvider: mockLanguage,
      calibrationProvider: mockCalibration,
      surfaceSize: surface,
    );
    await settle(tester);

    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      character.dispose();
    });
    return character;
  }

  testWidgets('a for-sale accessory shows its price and does not go on',
      (tester) async {
    final character = await pumpWardrobe(tester);
    final bowtie = accessoryById('bowtie')!;

    expect(find.textContaining('${bowtie.price}'), findsWidgets);

    await tester.tap(find.text('Bow Tie'));
    await tester.pump();

    expect(character.equippedInSlot(AccessorySlots.neck), isNull);
  });

  testWidgets('a bond-gated accessory names the stage it needs',
      (tester) async {
    final character = await pumpWardrobe(tester);

    // Top Hat unlocks at Attached, which a new pet is nowhere near.
    expect(find.textContaining('Attached'), findsWidgets);

    await tester.tap(find.text('Top Hat'));
    await tester.pump();

    expect(character.equippedInSlot(AccessorySlots.hat), isNull);
  });

  testWidgets('the free starter goes on with one tap', (tester) async {
    final character = await pumpWardrobe(tester);

    await tester.tap(find.text('Cap'));
    await tester.pump();

    expect(character.equippedInSlot(AccessorySlots.hat), 'cap');
  });

  // Coins are not a way in, so reaching the stage is the only thing that
  // changes here — and XP alone reaches it, whatever the player's language
  // level: activity is rewarded, fluency never is.
  testWidgets('reaching the stage makes a bond-gated accessory wearable',
      (tester) async {
    final character = await pumpWardrobe(tester, totalXP: attachedXP);

    await tester.tap(find.text('Top Hat'));
    await tester.pump();

    expect(character.equippedInSlot(AccessorySlots.hat), 'tophat');
  });

  // Scenery is the one shelf that is not about the pet: it changes the world
  // every pet lives in. The gate is the same as the accessories' — you cannot
  // move somewhere you have not bought — and the payoff is different: a scene
  // you own goes up on one tap, and one goes up the moment it is paid for.
  group('scenery', () {
    testWidgets('an unbought scene is priced and does not go up',
        (tester) async {
      final character = await pumpWardrobe(tester);

      await tapTile(tester, 'Galaxy Purple');
      await tester.pump();

      expect(character.sceneId, kDefaultSceneId);
    });

    testWidgets('an owned scene goes up with one tap', (tester) async {
      final character = await pumpWardrobe(
        tester,
        unlockedItems: const ['bg_forest'],
      );

      await tapTile(tester, 'Forest Green');
      await settle(tester);

      expect(character.sceneId, 'bg_forest');

      // And back: owning several and living in one is the point of the shelf.
      await tapTile(tester, 'Meadow');
      await settle(tester);

      expect(character.sceneId, kMeadowSceneId);

      // The room is a tile like any other, named like any other.
      await tapTile(tester, 'Cozy Room');
      await settle(tester);

      expect(character.sceneId, kCozyRoomSceneId);

      // ...and so is the enchanted meadow, which is free.
      await tapTile(tester, 'Enchanted Meadow');
      await settle(tester);

      expect(character.sceneId, kEnchantedMeadowSceneId);

      // ...and the mushroom glade, which is free too.
      await tapTile(tester, 'Mushroom Glade');
      await settle(tester);

      expect(character.sceneId, kMushroomGladeSceneId);
    });

    testWidgets('buying one moves the pet in straight away', (tester) async {
      when(() => mockUser.coins).thenReturn(500);
      when(() => mockUser.spendCoins(any())).thenAnswer((_) async {});

      final character = await pumpWardrobe(tester);

      await tapTile(tester, 'Ocean Blue');
      await settle(tester);

      expect(find.text('BUY'), findsOneWidget);
      await tester.tap(find.text('BUY'));
      await settle(tester);

      verify(() => mockUser.spendCoins(shopItemById('bg_blue')!.price))
          .called(1);
      expect(character.sceneId, 'bg_blue');
    });
  });

  // Pass worlds have no price, so a tap goes to the pass that carries them. With
  // two passes that has to be the right one: the pass screen opens on season one
  // when it is not told otherwise, and a tile for season two's world that opened
  // season one's track would show the player nothing about how to get it.
  testWidgets('a locked pass world opens the pass that carries it',
      (tester) async {
    final character = CharacterProvider(startDecayTimer: false);
    addTearDown(character.dispose);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const WardrobeScreen()),
      GoRoute(
        path: '/pass',
        name: 'pass',
        builder: (_, state) =>
            Scaffold(body: Text('pass:${state.uri.queryParameters['id']}')),
      ),
    ]);
    addTearDown(router.dispose);

    await pumpAppWithRouter(
      tester,
      router,
      characterProvider: character,
      settingsProvider: mockSettings,
      userProvider: mockUser,
      languageProvider: mockLanguage,
      calibrationProvider: mockCalibration,
      surfaceSize: surface,
    );
    await settle(tester);

    for (final (label, passId) in [
      ('Pumpkin Patch', kSeasonTwoId),
      ('Departures', kSeasonOneId),
    ]) {
      await tapTile(tester, label);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.text('pass:$passId'), findsOneWidget, reason: label);
      // Nothing was bought or moved into.
      expect(character.sceneId, kDefaultSceneId);

      router.pop();
      await settle(tester);
    }
  });

  group('buying from the shelf', () {
    testWidgets('an unaffordable tile explains rather than charging',
        (tester) async {
      final character = await pumpWardrobe(tester);

      await tester.tap(find.text('Bow Tie'));
      await settle(tester);

      expect(find.text('Not enough coins!'), findsOneWidget);
      expect(character.equippedInSlot(AccessorySlots.neck), isNull);
    });

    testWidgets('confirming a purchase equips it straight away',
        (tester) async {
      when(() => mockUser.coins).thenReturn(500);
      when(() => mockUser.spendCoins(any())).thenAnswer((_) async {});

      final character = await pumpWardrobe(tester);

      await tester.tap(find.text('Bow Tie'));
      await settle(tester);

      // The confirm dialog, not the "not enough coins" one.
      expect(find.text('BUY'), findsOneWidget);
      await tester.tap(find.text('BUY'));
      await settle(tester);

      verify(() => mockUser.spendCoins(accessoryById('bowtie')!.price!))
          .called(1);
      expect(character.equippedInSlot(AccessorySlots.neck), 'bowtie');
    });

    testWidgets('cancelling buys nothing', (tester) async {
      when(() => mockUser.coins).thenReturn(500);
      when(() => mockUser.spendCoins(any())).thenAnswer((_) async {});

      final character = await pumpWardrobe(tester);

      await tester.tap(find.text('Bow Tie'));
      await settle(tester);
      await tester.tap(find.text('CANCEL'));
      await settle(tester);

      verifyNever(() => mockUser.spendCoins(any()));
      expect(character.equippedInSlot(AccessorySlots.neck), isNull);
    });
  });

  // Coats and eye colours are the other thing coins buy here. Void heads the
  // exotic tier and is the only swatch on screen at its price, so its price
  // tag identifies exactly one thing to tap.
  group('buying a colour', () {
    const voidCoat = '#262A38';
    const voidPrice = '\u{1FA99} $kCoatPriceExotic';

    testWidgets('a locked coat is priced and does not go on', (tester) async {
      final character = await pumpWardrobe(tester);

      expect(find.text(voidPrice), findsWidgets);

      await tester.tap(find.text(voidPrice).first);
      await settle(tester);

      expect(find.text('Not enough coins!'), findsOneWidget);
      expect(character.design.bodyColor, kDefaultBodyColor);
    });

    testWidgets('confirming a purchase paints the pet with it', (tester) async {
      when(() => mockUser.coins).thenReturn(999);
      when(() => mockUser.spendCoins(any())).thenAnswer((_) async {});

      final character = await pumpWardrobe(tester);

      await tester.tap(find.text(voidPrice).first);
      await settle(tester);

      expect(find.text('BUY'), findsOneWidget);
      await tester.tap(find.text('BUY'));
      await settle(tester);

      verify(() => mockUser.spendCoins(kCoatPriceExotic)).called(1);
      expect(character.design.bodyColor, voidCoat);
    });

    testWidgets('cancelling buys nothing', (tester) async {
      when(() => mockUser.coins).thenReturn(999);
      when(() => mockUser.spendCoins(any())).thenAnswer((_) async {});

      final character = await pumpWardrobe(tester);

      await tester.tap(find.text(voidPrice).first);
      await settle(tester);
      await tester.tap(find.text('CANCEL'));
      await settle(tester);

      verifyNever(() => mockUser.spendCoins(any()));
      expect(character.design.bodyColor, kDefaultBodyColor);
    });
  });

  group('buying from the shelf, continued', () {
    // A crown at any price would turn "earned by learning" back into
    // "bought", so the tap must never reach a purchase dialog.
    testWidgets('a rich player still cannot buy a bond-gated piece',
        (tester) async {
      when(() => mockUser.coins).thenReturn(999999);
      when(() => mockUser.spendCoins(any())).thenAnswer((_) async {});

      final character = await pumpWardrobe(tester);

      await tester.tap(find.text('Crown'));
      await settle(tester);

      expect(find.text('BUY'), findsNothing);
      expect(find.text('Earned, not sold'), findsOneWidget);
      verifyNever(() => mockUser.spendCoins(any()));
      expect(character.equippedInSlot(AccessorySlots.hat), isNull);
    });
  });

  // Only a pet with a beak gets a beak panel, and picking a colour there
  // paints the beak rather than the coat.
  group('the beak colour', () {
    testWidgets('is offered to a bird and not to a cat', (tester) async {
      final character = await pumpWardrobe(tester);

      expect(find.text('BEAK COLOR'), findsNothing);

      await character.updateCharacterType('bird');
      await settle(tester);

      expect(find.text('BEAK COLOR'), findsOneWidget);
    });
  });

  // The parrot is drawn in profile and shows one eye, so odd-eyed would colour
  // a cell nobody can see. It still gets both colour panels -- being rigged is
  // what the pickers are gated on, and the parrot is.
  group('a pet with one eye', () {
    testWidgets('is offered colours but not the odd-eyed mode', (tester) async {
      // The parrot is bought, not a starter.
      final character = await pumpWardrobe(
        tester,
        unlockedItems: [petUnlockId('parrot')],
      );

      expect(find.text('SOLID'), findsOneWidget);
      expect(find.text('ODD-EYED'), findsOneWidget);

      await character.updateCharacterType('parrot');
      await settle(tester);

      expect(find.text('BODY & TAIL COLOR'), findsOneWidget);
      expect(find.text('EYE COLOR'), findsOneWidget);
      expect(find.text('SOLID'), findsNothing);
      expect(find.text('ODD-EYED'), findsNothing);
    });
  });
}
