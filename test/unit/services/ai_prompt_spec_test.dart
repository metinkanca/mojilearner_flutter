import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/services/ai_prompt_spec.dart';

void main() {
  group('AiPromptSpec.chat level', () {
    test("carries the player's level to the tutor", () {
      final spec = AiPromptSpec.chat(
        targetCode: 'es',
        nativeCode: 'en',
        level: 'intermediate',
      );
      expect(spec.params['level'], 'intermediate');
    });

    test('sends nothing when there is no assessed level yet', () {
      expect(
        AiPromptSpec.chat(targetCode: 'es', nativeCode: 'en')
            .params
            .containsKey('level'),
        isFalse,
      );
      expect(
        AiPromptSpec.chat(targetCode: 'es', nativeCode: 'en', level: '')
            .params
            .containsKey('level'),
        isFalse,
      );
    });

    test('a scenario chat carries it too', () {
      final spec = AiPromptSpec.chat(
        targetCode: 'fr',
        nativeCode: 'en',
        level: 'advanced',
        scenarioTitle: 'Coffee shop',
      );
      expect(spec.params['level'], 'advanced');
      expect(spec.params['scenario'], isA<Map<String, Object?>>());
    });
  });

  group('AiPromptSpec.starter', () {
    test('names the starter mode and carries the language and level', () {
      final spec = AiPromptSpec.starter(
        targetCode: 'tr',
        nativeCode: 'en',
        level: 'beginner',
      );
      expect(spec.mode, AiPromptMode.starter);
      expect(spec.mode.wireName, 'starter');
      expect(spec.params['targetCode'], 'tr');
      expect(spec.params['level'], 'beginner');
      expect(spec.params.containsKey('exclude'), isFalse);
    });

    test('carries what the player already has, when there is anything', () {
      final spec = AiPromptSpec.starter(
        targetCode: 'es',
        nativeCode: 'en',
        level: 'advanced',
        exclude: ['sol', 'luz'],
      );
      expect(spec.params['exclude'], ['sol', 'luz']);
    });
  });
}

