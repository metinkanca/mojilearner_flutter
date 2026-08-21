import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/utils/pii_detector.dart';

void main() {
  group('PIIDetector - hasSensitiveData', () {
    test('detects dashed phone numbers', () {
      expect(PIIDetector.hasSensitiveData('call me at 555-123-4567'), isTrue);
    });

    test('detects dotted phone numbers', () {
      expect(PIIDetector.hasSensitiveData('call me at 555.123.4567'), isTrue);
    });

    test('detects bare 10-digit numbers', () {
      expect(PIIDetector.hasSensitiveData('my number is 5551234567'), isTrue);
    });

    test('detects email addresses', () {
      expect(
          PIIDetector.hasSensitiveData('reach me at bob.smith@example.co.uk'),
          isTrue);
    });

    test('detects SSN-like formats', () {
      expect(PIIDetector.hasSensitiveData('ssn 123-45-6789'), isTrue);
    });

    test('detects postal codes', () {
      expect(PIIDetector.hasSensitiveData('I live at 90210'), isTrue);
      expect(PIIDetector.hasSensitiveData('zip is 12345-6789'), isTrue);
    });

    test('detects credential-style input', () {
      expect(PIIDetector.hasSensitiveData('password: hunter2'), isTrue);
      expect(PIIDetector.hasSensitiveData('PIN = 9999'), isTrue);
      expect(PIIDetector.hasSensitiveData('secret=abc123'), isTrue);
    });

    test('allows normal conversation text', () {
      expect(PIIDetector.hasSensitiveData('How do I say hello in Spanish?'),
          isFalse);
      expect(PIIDetector.hasSensitiveData('I ate 3 apples today'), isFalse);
    });

    test('returns false for empty input', () {
      expect(PIIDetector.hasSensitiveData(''), isFalse);
    });
  });

  group('PIIDetector - redactSensitiveData', () {
    test('redacts while preserving surrounding text', () {
      final result =
          PIIDetector.redactSensitiveData('email me at bob@mail.com please');
      expect(result, equals('email me at [REDACTED] please'));
    });

    test('redacts multiple PII instances in one message', () {
      final result = PIIDetector.redactSensitiveData(
          'phone 555-123-4567 and email a@b.io');
      expect(result, isNot(contains('555-123-4567')));
      expect(result, isNot(contains('a@b.io')));
      expect('[REDACTED]'.allMatches(result).length, equals(2));
    });

    test('leaves clean text untouched', () {
      const text = 'Can you teach me some French verbs?';
      expect(PIIDetector.redactSensitiveData(text), equals(text));
    });

    test('returns empty input unchanged', () {
      expect(PIIDetector.redactSensitiveData(''), equals(''));
    });
  });
}
