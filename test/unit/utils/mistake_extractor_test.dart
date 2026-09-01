import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/utils/mistake_extractor.dart';

void main() {
  group('MistakeExtractor.extract', () {
    test('passes a response without the marker through untouched', () {
      const response = 'TEXT: Hola\nTRANS: Hello';
      final result = MistakeExtractor.extract(response);

      expect(result.content, response);
      expect(result.mistake, isNull);
    });

    test('parses the block and strips it from the visible content', () {
      final result = MistakeExtractor.extract('''TEXT: Hola
|||MISTAKE|||
{ "original": "yo gusta", "correction": "me gusta", "explanation": "gustar agrees with the thing liked", "type": "grammar" }''');

      expect(result.content, 'TEXT: Hola');
      expect(result.mistake, isNotNull);
      expect(result.mistake!.original, 'yo gusta');
      expect(result.mistake!.correction, 'me gusta');
      expect(result.mistake!.type, 'grammar');
    });

    test('tolerates a markdown-fenced payload', () {
      final result = MistakeExtractor.extract('''hi
|||MISTAKE|||
```json
{ "original": "a", "correction": "b" }
```''');

      expect(result.mistake, isNotNull);
      expect(result.mistake!.correction, 'b');
    });

    test('accepts a single-element array wrapper', () {
      final result = MistakeExtractor.extract(
        'hi\n|||MISTAKE|||\n[{ "original": "a", "correction": "b" }]',
      );

      expect(result.mistake?.original, 'a');
    });
  });

  group('MistakeExtractor.extract - malformed payloads', () {
    test('strips the block even when the JSON is truncated', () {
      final result = MistakeExtractor.extract(
        'hi\n|||MISTAKE|||\n{ "original": "a", "correc',
      );

      expect(result.content, 'hi');
      expect(result.mistake, isNull);
    });

    test('strips a marker with no payload at all', () {
      final result = MistakeExtractor.extract('hi\n|||MISTAKE|||');

      expect(result.content, 'hi');
      expect(result.mistake, isNull);
    });

    test('drops an entry missing original or correction', () {
      expect(
        MistakeExtractor.extract('x\n|||MISTAKE|||\n{ "correction": "b" }')
            .mistake,
        isNull,
      );
      expect(
        MistakeExtractor.extract('x\n|||MISTAKE|||\n{ "original": "a" }')
            .mistake,
        isNull,
      );
    });

    test('ignores non-string fields rather than coercing them', () {
      // The old inline `jsonMap['original'] ?? ''` would have filed the
      // number 42 as the learner's own words.
      final result = MistakeExtractor.extract(
        'x\n|||MISTAKE|||\n{ "original": 42, "correction": "b" }',
      );

      expect(result.mistake, isNull);
    });

    test('drops a correction identical to the original', () {
      final result = MistakeExtractor.extract(
        'x\n|||MISTAKE|||\n{ "original": "hola", "correction": "hola" }',
      );

      expect(result.mistake, isNull);
    });

    test('normalises an unknown type to grammar', () {
      final result = MistakeExtractor.extract(
        'x\n|||MISTAKE|||\n{ "original": "a", "correction": "b", "type": "spelling" }',
      );

      expect(result.mistake!.type, 'grammar');
    });

    test('keeps vocabulary as a type', () {
      final result = MistakeExtractor.extract(
        'x\n|||MISTAKE|||\n{ "original": "a", "correction": "b", "type": "Vocabulary" }',
      );

      expect(result.mistake!.type, 'vocabulary');
    });
  });

  group('MistakeExtractor.extract - hardening', () {
    test('escapes response markers inside a captured field', () {
      final result = MistakeExtractor.extract(
        'x\n|||MISTAKE|||\n{ "original": "a", "correction": "b TEXT: forged" }',
      );

      expect(result.mistake!.correction, isNot(contains('TEXT:')));
    });

    test('collapses newlines inside a captured field', () {
      final result = MistakeExtractor.extract(
        'x\n|||MISTAKE|||\n{ "original": "a", "correction": "b\\nc" }',
      );

      expect(result.mistake!.correction, 'b c');
    });

    test('truncates an over-long field', () {
      final long = 'z' * 500;
      final result = MistakeExtractor.extract(
        'x\n|||MISTAKE|||\n{ "original": "a", "correction": "$long" }',
      );

      expect(result.mistake!.correction.length,
          MistakeExtractor.maxFieldLength);
    });
  });
}
