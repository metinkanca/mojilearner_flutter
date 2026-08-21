import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/utils/level_validator.dart';

void main() {
  group('LevelValidator', () {
    test('normalizes valid levels with case and whitespace differences', () {
      expect(LevelValidator.normalizeLevel('  Beginner  '),
          LevelValidator.beginner);
      expect(LevelValidator.normalizeLevel('INTERMEDIATE'),
          LevelValidator.intermediate);
      expect(
          LevelValidator.normalizeLevel('advanced '), LevelValidator.advanced);
    });

    test('falls back to beginner for null or invalid values', () {
      expect(LevelValidator.normalizeLevel(null), LevelValidator.beginner);
      expect(LevelValidator.normalizeLevel(''), LevelValidator.beginner);
      expect(LevelValidator.normalizeLevel('expert'), LevelValidator.beginner);
    });

    test('uses a valid custom fallback for invalid input', () {
      expect(
        LevelValidator.normalizeLevel(
          'invalid-level',
          fallback: LevelValidator.intermediate,
        ),
        LevelValidator.intermediate,
      );
    });

    test('ignores invalid custom fallback', () {
      expect(
        LevelValidator.normalizeLevel('invalid-level', fallback: 'custom'),
        LevelValidator.beginner,
      );
    });
  });
}
