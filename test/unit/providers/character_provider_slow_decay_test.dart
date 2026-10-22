import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/entitlements.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The slower decay a membership pays for.
///
/// The case that matters is the long absence, so every test here is the
/// offline pass — the batch of decay applied at launch for the hours the app
/// was shut. What is pinned is the *shape* of the curve rather than its
/// numbers: that a member's pet still declines, that an ordinary missed day
/// stops costing a crisis, and that a real absence costs one anyway.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The instant every pet in this file is loaded at.
  ///
  /// The pet's night is a wall-clock fact - `isNightHours` is true between
  /// 22:00 and 07:00 - and `mood` reports 'sleeping' ahead of 'starving', so
  /// "costs a free pet its evening meal" passed all day and failed after ten
  /// at night. Nothing here is about the time of day, so the time of day is
  /// pinned to an afternoon; `CharacterProvider(now:)` exists for exactly
  /// this.
  final midday = DateTime(2026, 6, 15, 13, 0);
  DateTime clock() => midday;

  /// A pet loaded from a save written [hours] ago.
  Future<CharacterProvider> petAfter(
    int hours, {
    required bool slowDecay,
    int hunger = 50,
    int happiness = 70,
    int health = 100,
  }) async {
    SharedPreferences.setMockInitialValues({
      'pet_hunger': hunger,
      'pet_happiness': happiness,
      'pet_health': health,
      'pet_slow_decay': slowDecay,
      // Measured back from the same pinned instant the provider reads, or
      // the elapsed hours would drift by however far the real clock has
      // moved from it.
      'pet_last_update':
          midday.subtract(Duration(hours: hours)).millisecondsSinceEpoch,
    });

    final provider = CharacterProvider(startDecayTimer: false, now: clock);
    await Future.delayed(const Duration(milliseconds: 100));
    return provider;
  }

  group('a day away', () {
    // Sixteen hours is a single skipped evening, and on the free rate it is
    // already past the starving line.
    test('costs a free pet its evening meal and then some', () async {
      final pet = await petAfter(16, slowDecay: false);

      expect(pet.hunger, 82);
      expect(pet.mood, 'starving');
    });

    test('costs a member four hours of the same slide', () async {
      final pet = await petAfter(16, slowDecay: true);

      expect(pet.hunger, 58);
      expect(pet.happiness, 62);
      expect(pet.mood, isNot('starving'));
    });
  });

  group('what a membership does not buy', () {
    // A pet that could not get into trouble would stop being a pet, and the
    // food that fixes it is the catalogue's one recurring coin sink.
    test('a long enough absence still ends in a sick, starving pet', () async {
      final pet = await petAfter(24 * 14, slowDecay: true);

      expect(pet.hunger, 100);
      expect(pet.happiness, 0);
      expect(pet.isSick, isTrue);
    });

    test('the pet still declines while the member is simply busy', () async {
      final pet = await petAfter(24, slowDecay: true);

      expect(pet.hunger, greaterThan(50));
      expect(pet.happiness, lessThan(70));
    });

    test('decay is only slowed, never reversed', () async {
      final pet = await petAfter(
        24,
        slowDecay: true,
        hunger: 95,
        happiness: 5,
        health: 40,
      );

      expect(pet.hunger, greaterThanOrEqualTo(95));
      expect(pet.happiness, lessThanOrEqualTo(5));
      expect(pet.health, lessThanOrEqualTo(40));
    });
  });

  group('the arithmetic', () {
    // A multiplier on the amounts would have to round two points an hour to
    // something, and rounding it up is half speed rather than a quarter.
    test('a member decays at exactly the divisor', () async {
      // Twenty hours, because both stats have to stay off their 0-100 clamps
      // for a ratio between them to mean anything.
      const hours = 20;
      final fast = await petAfter(hours, slowDecay: false);
      final slow = await petAfter(hours, slowDecay: true);

      expect(
        slow.hunger - 50,
        (fast.hunger - 50) ~/ PlusCareConstants.decayDivisor,
      );
      expect(
        70 - slow.happiness,
        (70 - fast.happiness) ~/ PlusCareConstants.decayDivisor,
      );
    });

    // Hours short of a step are not lost, or a pet on a timer that ticks every
    // minute would decay a great deal more slowly than one checked twice a day.
    test('hours short of a whole step keep accruing', () async {
      final threeHours = await petAfter(3, slowDecay: true);
      expect(threeHours.hunger, 50, reason: 'not yet a step');

      final fourHours = await petAfter(4, slowDecay: true);
      expect(fourHours.hunger, 52, reason: 'the step arrives whole');

      final sevenHours = await petAfter(7, slowDecay: true);
      expect(sevenHours.hunger, 52, reason: 'and the remainder waits');
    });
  });

  group('the flag itself', () {
    test('survives a restart, because the offline pass runs before any '
        'provider has loaded a membership', () async {
      final pet = await petAfter(1, slowDecay: false);
      expect(pet.hasSlowDecay, isFalse);

      pet.updateSlowDecay(active: true);
      await Future.delayed(const Duration(milliseconds: 50));

      final reloaded = CharacterProvider(startDecayTimer: false, now: clock);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(reloaded.hasSlowDecay, isTrue);
    });
  });
}
