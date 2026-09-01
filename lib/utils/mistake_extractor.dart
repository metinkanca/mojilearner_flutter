/// Pulls the correction block out of a tutor response.
///
/// The tutor appends a hidden JSON block when the learner gets something
/// wrong, and the app files it into the mistakes list — a store the learner
/// reviews later, so what lands in it is worth validating. Both call sites
/// used to decode the payload inline with `jsonMap['original'] ?? ''`, which
/// accepted a number, a nested object, or three kilobytes of text as a
/// "correction".
///
/// Pure, no providers, no widgets — the same split as [VocabExtractor], and
/// for the same reason: the payload is model output and will occasionally be
/// malformed.
library;

import 'dart:convert';

import 'input_sanitizer.dart';

/// One correction the tutor reported.
class ExtractedMistake {
  const ExtractedMistake({
    required this.original,
    required this.correction,
    required this.explanation,
    required this.type,
  });

  /// What the learner wrote.
  final String original;

  /// What they should have written.
  final String correction;

  /// Why, in the learner's native language. May be empty.
  final String explanation;

  /// Either `grammar` or `vocabulary`.
  final String type;
}

/// The response with the block removed, plus whatever parsed out of it.
class MistakeExtraction {
  const MistakeExtraction({required this.content, this.mistake});

  final String content;

  /// Null when there was no block, or nothing usable in it.
  final ExtractedMistake? mistake;
}

class MistakeExtractor {
  MistakeExtractor._();

  static const String marker = '|||MISTAKE|||';

  /// Field cap. Generous next to vocabulary's 120 because a correction quotes
  /// a whole sentence, but still a cap: this text is persisted and rendered.
  static const int maxFieldLength = 200;

  static const String _grammar = 'grammar';
  static const String _vocabulary = 'vocabulary';

  /// Splits [response] on [marker] and parses the trailing JSON object.
  ///
  /// A missing or malformed block is not an error: the block is always
  /// stripped from the visible content, and the mistake simply comes back
  /// null. Losing a correction is acceptable; showing raw JSON in the chat
  /// bubble is not.
  static MistakeExtraction extract(String response) {
    if (!response.contains(marker)) {
      return MistakeExtraction(content: response);
    }

    final parts = response.split(marker);
    final content = parts.first.trim();
    if (parts.length < 2) {
      return MistakeExtraction(content: content);
    }

    return MistakeExtraction(content: content, mistake: _parse(parts[1]));
  }

  static ExtractedMistake? _parse(String payload) {
    final cleaned =
        payload.replaceAll('```json', '').replaceAll('```', '').trim();
    if (cleaned.isEmpty) return null;

    final Object? decoded;
    try {
      decoded = json.decode(cleaned);
    } catch (_) {
      return null;
    }

    // Accept the first element of an array too — models occasionally wrap a
    // single correction the way the vocabulary block is wrapped.
    final Object? candidate =
        decoded is List ? (decoded.isEmpty ? null : decoded.first) : decoded;
    if (candidate is! Map) return null;

    final original = _field(candidate['original']);
    final correction = _field(candidate['correction']);
    // A correction identical to the original is not a mistake, and filing one
    // teaches the learner nothing.
    if (original.isEmpty || correction.isEmpty || original == correction) {
      return null;
    }

    final rawType = _field(candidate['type']).toLowerCase();
    return ExtractedMistake(
      original: original,
      correction: correction,
      explanation: _field(candidate['explanation']),
      type: rawType == _vocabulary ? _vocabulary : _grammar,
    );
  }

  /// Normalises one field: markers escaped so captured text cannot forge a
  /// response section when it is replayed into a later prompt, whitespace
  /// collapsed, length capped. Non-strings are dropped rather than coerced.
  static String _field(Object? value) {
    if (value is! String) return '';
    final cleaned = InputSanitizer.escapeSpecialMarkers(value)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.length <= maxFieldLength
        ? cleaned
        : cleaned.substring(0, maxFieldLength).trim();
  }
}
