import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/app_runtime_config.dart';
import 'package:mojilearner_flutter/constants/sample_mistakes.dart';

void main() {
  test('the samples are off unless asked for', () {
    expect(AppRuntimeConfig.sampleMistakes, isFalse);
  });

  test('every sample is a wrong English sentence with a correction and an '
      'explanation', () {
    expect(kSampleMistakes, isNotEmpty);
    for (final sample in kSampleMistakes) {
      expect(sample.original.trim(), isNotEmpty);
      expect(sample.correction.trim(), isNotEmpty);
      expect(sample.explanation.trim(), isNotEmpty);
      expect(sample.original, isNot(sample.correction), reason: sample.id);
      expect(['grammar', 'vocabulary'], contains(sample.type));
    }
  });

  test('ids are unique and marked, so a sample is never added twice or saved',
      () {
    final ids = kSampleMistakes.map((m) => m.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(ids.every((id) => id.startsWith(kSampleMistakeIdPrefix)), isTrue);
  });

  test('the explanations are in Turkish', () {
    // Every one carries at least one letter only Turkish has.
    final turkish = RegExp('[çğıöşüÇĞİÖŞÜ]');
    for (final sample in kSampleMistakes) {
      expect(turkish.hasMatch(sample.explanation), isTrue, reason: sample.id);
    }
  });
}
