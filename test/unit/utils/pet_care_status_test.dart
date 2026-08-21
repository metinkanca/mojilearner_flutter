import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/utils/pet_care_status.dart';

CareReading read(
  CareStat stat, {
  int hunger = 20,
  int happiness = 90,
  int health = 100,
}) =>
    PetCareStatus.reading(stat,
        hunger: hunger, happiness: happiness, health: health);

CareReading? concern({
  int hunger = 20,
  int happiness = 90,
  int health = 100,
}) =>
    PetCareStatus.topConcern(
        hunger: hunger, happiness: happiness, health: health);

void main() {
  group('display orientation', () {
    test('hunger is inverted into fullness, so higher is always better', () {
      expect(read(CareStat.fullness, hunger: 0).value, equals(100));
      expect(read(CareStat.fullness, hunger: 30).value, equals(70));
      expect(read(CareStat.fullness, hunger: 100).value, equals(0));
    });

    test('happiness and health pass through unchanged', () {
      expect(read(CareStat.happiness, happiness: 64).value, equals(64));
      expect(read(CareStat.health, health: 41).value, equals(41));
    });

    test('out-of-range stats are clamped rather than overflowing a bar', () {
      expect(read(CareStat.fullness, hunger: 150).value, equals(0));
      expect(read(CareStat.happiness, happiness: -20).value, equals(0));
      expect(read(CareStat.health, health: 500).value, equals(100));
      expect(read(CareStat.health, health: 500).fraction, equals(1.0));
    });

    test('fraction is a 0-1 bar width', () {
      expect(read(CareStat.fullness, hunger: 25).fraction, closeTo(0.75, 1e-9));
    });
  });

  group('severity thresholds', () {
    test('a well-kept pet reports nothing', () {
      final all =
          PetCareStatus.readings(hunger: 10, happiness: 90, health: 100);

      expect(all.every((r) => r.severity == CareSeverity.fine), isTrue);
      expect(all.any((r) => r.needsAttention), isFalse);
    });

    test('hunger climbing crosses low then critical', () {
      expect(read(CareStat.fullness, hunger: 55).severity,
          equals(CareSeverity.fine));
      expect(read(CareStat.fullness, hunger: 65).severity,
          equals(CareSeverity.low));
      expect(read(CareStat.fullness, hunger: 85).severity,
          equals(CareSeverity.critical));
    });

    test('health below the sick line is critical', () {
      // Matches CharacterProvider's own sick threshold, which is what
      // actually halves rewards.
      expect(read(CareStat.health, health: 31).severity,
          isNot(equals(CareSeverity.critical)));
      expect(read(CareStat.health, health: 30).severity,
          equals(CareSeverity.critical));
    });

    test('happiness below the sad line is critical', () {
      expect(read(CareStat.happiness, happiness: 25).severity,
          equals(CareSeverity.low));
      expect(read(CareStat.happiness, happiness: 15).severity,
          equals(CareSeverity.critical));
    });
  });

  group('topConcern', () {
    test('says nothing about a healthy pet', () {
      expect(concern(), isNull);
      expect(
        PetCareStatus.needsCare(hunger: 10, happiness: 90, health: 100),
        isFalse,
      );
    });

    test('surfaces the single most urgent thing', () {
      final result = concern(hunger: 90, happiness: 90, health: 100);

      expect(result, isNotNull);
      expect(result!.stat, equals(CareStat.fullness));
      expect(result.severity, equals(CareSeverity.critical));
    });

    test('critical always beats merely low', () {
      // Happiness is critical, fullness only low: the worse one wins even
      // though fullness sorts higher on ties.
      final result = concern(hunger: 65, happiness: 10, health: 100);

      expect(result!.stat, equals(CareStat.happiness));
    });

    test('health wins ties because it is the one that taxes the player', () {
      // All three critical: sickness halves every reward, so saying "Moji is
      // peckish" instead would bury the expensive news.
      final result = concern(hunger: 95, happiness: 5, health: 10);

      expect(result!.stat, equals(CareStat.health));
    });

    test('fullness outranks happiness at equal severity', () {
      final result = concern(hunger: 95, happiness: 5, health: 100);

      expect(result!.stat, equals(CareStat.fullness));
    });

    test('needsCare agrees with topConcern', () {
      for (final stats in [
        [10, 90, 100],
        [65, 90, 100],
        [10, 25, 100],
        [10, 90, 20],
        [95, 5, 5],
      ]) {
        final has = PetCareStatus.needsCare(
            hunger: stats[0], happiness: stats[1], health: stats[2]);
        final top = PetCareStatus.topConcern(
            hunger: stats[0], happiness: stats[1], health: stats[2]);

        expect(has, equals(top != null), reason: 'for $stats');
      }
    });
  });

  group('readings', () {
    test('always returns all three in a stable order', () {
      final all =
          PetCareStatus.readings(hunger: 50, happiness: 50, health: 50);

      expect(all.map((r) => r.stat).toList(),
          equals([CareStat.fullness, CareStat.happiness, CareStat.health]));
    });

    test('order does not change when a stat becomes critical', () {
      final all =
          PetCareStatus.readings(hunger: 99, happiness: 1, health: 1);

      expect(all.map((r) => r.stat).toList(),
          equals([CareStat.fullness, CareStat.happiness, CareStat.health]));
    });
  });
}
