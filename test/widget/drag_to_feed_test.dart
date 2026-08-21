import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/carried_food.dart';
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

  CharacterProvider buildCharacter({
    int hunger = 80,
    List<String> inventory = const ['apple'],
  }) {
    SharedPreferences.setMockInitialValues({
      'pet_hunger': hunger,
      'pet_happiness': 90,
      'pet_health': 100,
      'inventory': inventory,
    });
    return CharacterProvider(startDecayTimer: false);
  }

  /// Mirrors the home screen: a drop target standing in for the pet, with the
  /// carried food below it.
  Future<void> pumpFeedingArea(
    WidgetTester tester,
    CharacterProvider character,
  ) async {
    await pumpApp(
      tester,
      Column(
        children: [
          DragTarget<String>(
            onWillAcceptWithDetails: (d) => d.data == character.heldFoodId,
            onMove: (_) => character.setFoodHovering(true),
            onLeave: (_) => character.setFoodHovering(false),
            onAcceptWithDetails: (_) => character.feedHeldFood(),
            builder: (context, _, __) => Container(
              key: const Key('pet'),
              height: 200,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 40),
          const CarriedFood(),
        ],
      ),
      settingsProvider: mockSettings,
      characterProvider: character,
    );
    await tester.pumpAndSettle();
  }

  group('CarriedFood visibility', () {
    testWidgets('shows nothing when the player is not carrying food',
        (tester) async {
      await pumpFeedingArea(tester, buildCharacter());

      expect(find.textContaining('Drag onto Moji'), findsNothing);
      expect(find.text('🍎'), findsNothing);
    });

    testWidgets('appears once food is picked up', (tester) async {
      final character = buildCharacter();
      await pumpFeedingArea(tester, character);

      character.pickUpFood('apple');
      await tester.pumpAndSettle();

      expect(find.text('Drag onto Moji to feed'), findsOneWidget);
      expect(find.text('🍎'), findsWidgets);
    });

    testWidgets('the cancel button puts the food back', (tester) async {
      final character = buildCharacter();
      await pumpFeedingArea(tester, character);
      character.pickUpFood('apple');
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(character.heldFoodId, isNull);
      expect(character.inventory, contains('apple'));
      expect(find.textContaining('Drag onto Moji'), findsNothing);
    });
  });

  group('dragging food onto the pet', () {
    testWidgets('the mouth stays open while food hovers over the pet',
        (tester) async {
      // This is what the whole interaction is for: the sprite holds
      // `mouthOpen` for the entire `waiting` phase, so the pet must stay in
      // that phase until the food is actually released.
      final character = buildCharacter();
      await pumpFeedingArea(tester, character);
      character.pickUpFood('apple');
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('🍎').first),
      );
      await tester.pump();

      await gesture.moveTo(tester.getCenter(find.byKey(const Key('pet'))));
      await tester.pump();

      expect(character.eatingPhase, equals(PetEatingPhase.waiting));
      expect(character.isFoodHovering, isTrue);

      // Still hovering several frames later — not a one-frame flicker.
      await tester.pump(const Duration(milliseconds: 300));
      expect(character.isFoodHovering, isTrue);
      // And nothing is eaten until release.
      expect(character.inventory, contains('apple'));

      // Released over the pet, so it eats: pump the chew out so no timer
      // outlives the test.
      await gesture.up();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('releasing over the pet feeds it', (tester) async {
      final character = buildCharacter(hunger: 80);
      await pumpFeedingArea(tester, character);
      character.pickUpFood('apple');
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('🍎').first),
      );
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byKey(const Key('pet'))));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(character.hunger, lessThan(80));
      expect(character.inventory, isEmpty);
      expect(character.heldFoodId, isNull);

      // Let the chew animation finish so no timer outlives the test.
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('moving away from the pet closes its mouth again',
        (tester) async {
      final character = buildCharacter();
      await pumpFeedingArea(tester, character);
      character.pickUpFood('apple');
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('🍎').first),
      );
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byKey(const Key('pet'))));
      await tester.pump();
      expect(character.isFoodHovering, isTrue);

      // Clear of the pet: it occupies the top 200px of the column.
      await gesture.moveTo(const Offset(400, 420));
      await tester.pump();

      expect(character.isFoodHovering, isFalse);
      expect(character.eatingPhase, equals(PetEatingPhase.none));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('abandoning the drag does not leave the mouth hanging open',
        (tester) async {
      final character = buildCharacter();
      await pumpFeedingArea(tester, character);
      character.pickUpFood('apple');
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('🍎').first),
      );
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byKey(const Key('pet'))));
      await tester.pump();
      expect(character.isFoodHovering, isTrue);

      // Released in mid-air, clear of the pet.
      await gesture.moveTo(const Offset(400, 420));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(character.isFoodHovering, isFalse);
      expect(character.inventory, contains('apple'));
    });
  });
}
