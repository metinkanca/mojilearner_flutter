import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/character_sprite.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// The petting reaction has to be *visible*. The first version of it was a
/// happy-mood breath — 0.8% more vertical scale and a slightly quicker tail —
/// which was indistinguishable from an idle pet on a real screen, so petting
/// looked broken however many times you did it.
///
/// These tests hold the two halves of the fix. The pet must actually be in a
/// petting state that the art can key off, and it must stay pettable forever:
/// the cooldown rations happiness, not affection.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSettingsProvider mockSettings;

  setUp(() {
    mockSettings = MockSettingsProvider();
    when(() => mockSettings.usePixelFont).thenReturn(true);
  });

  /// Mid-afternoon, and pinned rather than left to the wall clock: the pet
  /// sleeps between 22:00 and 07:00, a sleeping pet holds its eyes shut, and
  /// the squint this file is about is suppressed while it does. Run against
  /// the real clock, the art test below passes all day and fails all night.
  final daytime = DateTime(2026, 3, 1, 15, 0);

  CharacterProvider buildCharacter({int happiness = 50}) {
    SharedPreferences.setMockInitialValues({
      'pet_hunger': 20,
      'pet_happiness': happiness,
      'pet_health': 100,
    });
    return CharacterProvider(startDecayTimer: false, now: () => daytime);
  }

  group('the petting state', () {
    test('petting puts the pet in a state of its own, not just a good mood',
        () {
      final character = buildCharacter();

      character.petThePet();

      expect(character.isBeingPetted, isTrue);
      expect(character.visualState, PetVisualState.petted);
    });

    test('which outranks a happy mood, so a rub reads through contentment', () {
      final character = buildCharacter(happiness: 100);

      character.petThePet();

      expect(character.visualState, PetVisualState.petted);
    });

    // testWidgets rather than test, purely for its fake clock: the reaction
    // clears itself on a timer, and nothing here needs a widget tree.
    testWidgets('and drops shortly after the hand comes off', (tester) async {
      final character = buildCharacter();
      character.petThePet();

      await tester.pump(const Duration(seconds: 2));

      expect(character.isBeingPetted, isFalse);
    });
  });

  group('petting is unlimited', () {
    test('the pet reacts to every rub, cooldown or not', () {
      final character = buildCharacter();

      expect(character.petThePet(), isTrue, reason: 'first rub pays');
      expect(character.isBeingPetted, isTrue);

      // Straight into the cooldown: no payout, but the pet still reacts.
      expect(character.petThePet(), isFalse, reason: 'cooldown, no payout');
      expect(character.isBeingPetted, isTrue);
      expect(character.canEarnFromPetting, isFalse);
    });

    test('happiness is what the cooldown rations, not the reaction', () {
      final character = buildCharacter(happiness: 50);
      character.petThePet();
      final afterFirst = character.happiness;

      for (var i = 0; i < 5; i++) {
        character.petThePet();
      }

      expect(character.happiness, afterFirst,
          reason: 'rubs during the cooldown pay nothing');
    });
  });

  group('the hearts', () {
    test('only count a rub that actually paid happiness', () {
      final character = buildCharacter();

      expect(character.petPayouts, 0);
      character.petThePet();
      expect(character.petPayouts, 1, reason: 'the paying rub');

      // Every rub from here is inside the cooldown: the pet still reacts, but
      // hearts would be promising a reward that is not being paid.
      for (var i = 0; i < 5; i++) {
        character.petThePet();
      }
      expect(character.petPayouts, 1);
      expect(character.isBeingPetted, isTrue,
          reason: 'still reacting, just not paying');
    });
  });

  /// Petting is unlimited on purpose, so a sustained scratch lands in the
  /// cooldown branch dozens of times. Persisting on each of those was ~15
  /// writes per ten seconds of fussing — invisible against SharedPreferences,
  /// but the single most expensive path in the app once this state syncs to a
  /// backend that bills per write.
  ///
  /// `pet_last_interaction` is the probe: `_savePetState` always writes it, so
  /// clearing the key and finding it still absent proves no save happened.
  group('what a rub costs in writes', () {
    test('a rub inside the cooldown does not rewrite the pet state', () async {
      final character = buildCharacter();
      await pumpEventQueue();

      character.petThePet(); // the paying rub, which does save
      await pumpEventQueue();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pet_last_interaction');

      for (var i = 0; i < 5; i++) {
        character.petThePet();
      }
      await pumpEventQueue();

      expect(prefs.getInt('pet_last_interaction'), isNull,
          reason: 'rubs inside the cooldown changed nothing worth persisting');
    });

    test('but a rub that wakes a dozing pet still persists the wake window',
        () async {
      // Gone 23:00: the same cooldown branch, except now the rub moves the
      // wake window, which the pet has to still be inside after a restart.
      final character = CharacterProvider(
        startDecayTimer: false,
        now: () => DateTime(2026, 3, 1, 23, 0),
      );
      await pumpEventQueue();

      character.petThePet();
      await pumpEventQueue();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pet_awake_until');

      character.petThePet(); // inside the cooldown
      await pumpEventQueue();

      expect(prefs.getInt('pet_awake_until'), isNotNull,
          reason: 'the wake window is worth a write even during the cooldown');
    });
  });

  group('the art', () {
    testWidgets('renders the pet differently while it is being petted',
        (tester) async {
      final character = buildCharacter();

      await pumpApp(
        tester,
        const SizedBox(
          width: 222,
          height: 328,
          child: CharacterSprite(
            width: 222,
            height: 328,
            motionProfile: CharacterMotionProfile.full,
          ),
        ),
        settingsProvider: mockSettings,
        characterProvider: character,
      );
      await tester.pump(const Duration(milliseconds: 100));

      // The eyes are the loudest part of the reaction: a squint the idle pet
      // never holds. Reading the eye layer's own transform is what tells the
      // two apart without a golden file.
      //
      // Found by its pivot, the cat's eye anchor: the eyes are the one layer
      // scaled about a point on the face, and every other transform in the
      // sprite is anchored at the pet's feet or is a plain translation.
      const eyePivot = Alignment(0.248, 0.091);
      double eyeScale() {
        final eyes = tester
            .widgetList<Transform>(find.descendant(
              of: find.byType(CharacterSprite),
              matching: find.byType(Transform),
            ))
            .where((t) => t.alignment == eyePivot);
        expect(eyes, hasLength(1), reason: 'exactly one eye layer');
        return eyes.first.transform.getColumn(1)[1];
      }

      final idle = eyeScale();

      character.petThePet();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(eyeScale(), lessThan(idle * 0.6),
          reason: 'a petted pet squints; an idle one does not');

      // And it goes back to normal once the hand is off.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 16));
      expect(eyeScale(), closeTo(idle, 0.2));
    });
  });
}
