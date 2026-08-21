import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/pet_care_panel.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSettingsProvider mockSettings;

  setUp(() {
    mockSettings = MockSettingsProvider();
    when(() => mockSettings.usePixelFont).thenReturn(true);
  });

  /// Seeds the stats through SharedPreferences rather than mutating the
  /// provider, because `_loadPetState` is async: anything set on the instance
  /// is overwritten the moment that load resolves mid-pump.
  ///
  /// The decay timer is off — `pumpApp` uses `.value` providers, which never
  /// dispose, and a pending periodic timer fails the test before any
  /// assertion runs.
  CharacterProvider buildCharacter({
    int hunger = 20,
    int happiness = 90,
    int health = 100,
    List<String> inventory = const [],
  }) {
    SharedPreferences.setMockInitialValues({
      'pet_hunger': hunger,
      'pet_happiness': happiness,
      'pet_health': health,
      'inventory': inventory,
    });
    return CharacterProvider(startDecayTimer: false);
  }

  Future<void> pumpPanel(
    WidgetTester tester,
    CharacterProvider character,
  ) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(
      tester,
      const PetCarePanel(),
      settingsProvider: mockSettings,
      characterProvider: character,
    );
    // Let the async state load resolve before asserting on any stat.
    await tester.pumpAndSettle();
  }

  /// Interactions kick off short animation timers (chewing, happy burst).
  /// Pumping past them keeps the pending-timer check satisfied.
  Future<void> settleAnimations(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  group('PetCarePanel - stat display', () {
    testWidgets('shows all three stats, hunger converted to fullness',
        (tester) async {
      await pumpPanel(
          tester, buildCharacter(hunger: 30, happiness: 64, health: 80));

      expect(find.text('Fullness'), findsOneWidget);
      expect(find.text('Happiness'), findsOneWidget);
      expect(find.text('Health'), findsOneWidget);

      // hunger 30 reads as 70% full, not 30%.
      expect(find.text('70%'), findsOneWidget);
      expect(find.text('64%'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
    });

    testWidgets('reassures when nothing needs doing', (tester) async {
      await pumpPanel(tester, buildCharacter());

      expect(find.text('Moji is doing great.'), findsOneWidget);
    });

    testWidgets('names the most urgent problem', (tester) async {
      await pumpPanel(tester, buildCharacter(hunger: 95));

      expect(find.text('Moji is hungry'), findsOneWidget);
      expect(find.text('Moji is doing great.'), findsNothing);
    });
  });

  group('PetCarePanel - the invisible penalty', () {
    testWidgets('explains the halved rewards when the pet is sick',
        (tester) async {
      await pumpPanel(tester, buildCharacter(health: 10));

      expect(
        find.text('While Moji is sick, all XP and coins are halved.'),
        findsOneWidget,
      );
    });

    testWidgets('says nothing about the penalty when healthy', (tester) async {
      await pumpPanel(tester, buildCharacter());

      expect(find.textContaining('halved'), findsNothing);
    });
  });

  group('PetCarePanel - feeding', () {
    testWidgets('offers the food the player owns', (tester) async {
      await pumpPanel(tester,
          buildCharacter(inventory: const ['apple', 'apple', 'coffee']));

      expect(find.text('Apple x2'), findsOneWidget);
      // Rows use the localized display name, not the inventory id.
      expect(find.text('Espresso'), findsOneWidget);
      expect(find.textContaining('No food left'), findsNothing);
    });

    testWidgets('tapping food hands it to the player', (tester) async {
      // The panel no longer feeds directly — it hands the food over so the
      // player can carry it to the pet and watch the animation.
      final character = buildCharacter(hunger: 80, inventory: const ['apple']);
      await pumpPanel(tester, character);

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      expect(character.heldFoodId, equals('apple'));
      expect(character.isCarryingFood, isTrue);
      // Carrying is not feeding: nothing eaten yet.
      expect(character.hunger, equals(80));
      expect(character.inventory, contains('apple'));
    });

    testWidgets('the panel gets out of the way so the pet is visible',
        (tester) async {
      // Feeding inside the dialog would play the chew animation behind an
      // opaque panel, which is the same as not having one. Opened through
      // show() so there is a real dialog route to dismiss.
      final character = buildCharacter(hunger: 80, inventory: const ['apple']);

      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () => PetCarePanel.show(context),
            child: const Text('open'),
          ),
        ),
        settingsProvider: mockSettings,
        characterProvider: character,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(PetCarePanel), findsOneWidget);

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      expect(find.byType(PetCarePanel), findsNothing);
      expect(character.heldFoodId, equals('apple'));
    });

    testWidgets('points at the shop when the cupboard is bare',
        (tester) async {
      await pumpPanel(tester, buildCharacter());

      expect(find.textContaining('No food left'), findsOneWidget);
      expect(find.text('GO TO SHOP'), findsOneWidget);
    });
  });

  group('PetCarePanel - petting', () {
    testWidgets('petting raises happiness', (tester) async {
      final character = buildCharacter(happiness: 40);
      await pumpPanel(tester, character);

      await tester.tap(find.text('PET MOJI'));
      await settleAnimations(tester);

      expect(character.happiness, greaterThan(40));
    });

    testWidgets('explains the cooldown instead of a dead button',
        (tester) async {
      final character = buildCharacter(happiness: 40);
      await pumpPanel(tester, character);

      await tester.tap(find.text('PET MOJI'));
      await settleAnimations(tester);

      expect(character.canEarnFromPetting, isFalse);
      expect(find.textContaining('had enough fuss'), findsOneWidget);
    });

    // The panel is a dialog over a dimmed barrier, so a happy reaction played
    // underneath it is a reaction nobody sees. Petting from here has to get
    // out of the way of the thing it paid for.
    testWidgets('petting from the dialog closes it so the pet is visible',
        (tester) async {
      final character = buildCharacter(happiness: 40);
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PetCarePanel.show(context),
            child: const Text('open'),
          ),
        ),
        settingsProvider: mockSettings,
        characterProvider: character,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('PET MOJI'), findsOneWidget);

      await tester.tap(find.text('PET MOJI'));
      await settleAnimations(tester);

      expect(find.text('PET MOJI'), findsNothing);
      expect(character.happiness, greaterThan(40));
    });
  });
}
