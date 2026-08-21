import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/constants/accessories.dart';
import 'package:mojilearner_flutter/models/models.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/screens/wardrobe_screen.dart';
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
      const Language(code: 'es', name: 'Spanish', flag: '\u{1F1EA}\u{1F1F8}'),
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

  Future<CharacterProvider> pumpWardrobe(
    WidgetTester tester, {
    int bondPoints = 0,
    String? assessedLevel,
  }) async {
    if (bondPoints > 0) {
      SharedPreferences.setMockInitialValues({'pet_bond_points': bondPoints});
    }
    if (assessedLevel != null) {
      when(() => mockCalibration.getLanguageProficiency('es')).thenReturn(
        LanguageProficiency(
          languageCode: 'es',
          aiDeterminedLevel: assessedLevel,
          isCalibrated: true,
        ),
      );
    }
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
  // changes here. Note it takes both halves: stages are fluency-gated too, so
  // bond points alone leave a beginner short of Attached.
  testWidgets('reaching the stage makes a bond-gated accessory wearable',
      (tester) async {
    final character = await pumpWardrobe(
      tester,
      bondPoints: 400,
      assessedLevel: 'intermediate',
    );

    await tester.tap(find.text('Top Hat'));
    await tester.pump();

    expect(character.equippedInSlot(AccessorySlots.hat), 'tophat');
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
}
