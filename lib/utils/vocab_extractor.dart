/// Pulls the vocabulary block out of a tutor response.
///
/// The tutor appends a hidden block listing the words worth remembering from
/// its own reply. Parsing it here — pure, no providers, no widgets — keeps the
/// tolerance rules testable, which matters because the payload is model output
/// and will occasionally be malformed.
library;

import 'dart:convert';

import 'input_sanitizer.dart';

/// One word or phrase the tutor taught in a reply.
class ExtractedVocab {
  const ExtractedVocab({
    required this.term,
    required this.meaning,
    this.example,
    this.reading,
  });

  /// The target-language word or phrase.
  final String term;

  /// Its meaning, in the learner's native language.
  final String meaning;

  /// Optional example sentence, stored as the review item's context.
  final String? example;

  /// Romanized pronunciation of [term]. Present only for target languages
  /// written in a non-Latin script.
  final String? reading;
}

/// The response with the block removed, plus whatever parsed out of it.
class VocabExtraction {
  const VocabExtraction({required this.content, required this.entries});

  final String content;
  final List<ExtractedVocab> entries;
}

class VocabExtractor {
  VocabExtractor._();

  static const String marker = '|||VOCAB|||';

  /// Cap per reply. A tutor that dumps twenty words in one turn would bury
  /// the review queue in items the learner never actually engaged with.
  static const int maxEntries = 5;

  /// Field cap, matching the review item's own display constraints.
  static const int maxFieldLength = 120;

  /// Splits [response] on [marker] and parses the trailing JSON array.
  ///
  /// A missing, truncated, or malformed block is not an error: the block is
  /// always stripped from the visible content, and the entries simply come
  /// back empty. Losing a word is acceptable; showing raw JSON in the chat
  /// bubble is not.
  static VocabExtraction extract(String response) {
    if (!response.contains(marker)) {
      return VocabExtraction(content: response, entries: const []);
    }

    final parts = response.split(marker);
    final content = parts.first.trim();
    if (parts.length < 2) {
      return VocabExtraction(content: content, entries: const []);
    }

    return VocabExtraction(
      content: content,
      entries: _parse(parts[1]),
    );
  }

  static List<ExtractedVocab> _parse(String payload) {
    final cleaned = payload
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
    if (cleaned.isEmpty) return const [];

    final Object? decoded;
    try {
      decoded = json.decode(cleaned);
    } catch (_) {
      return const [];
    }

    // Accept a bare object too — models drop the array wrapper when there is
    // only one word.
    final List<Object?> raw;
    if (decoded is List) {
      raw = decoded;
    } else if (decoded is Map) {
      raw = [decoded];
    } else {
      return const [];
    }

    final entries = <ExtractedVocab>[];
    final seen = <String>{};
    for (final element in raw) {
      if (entries.length >= maxEntries) break;
      if (element is! Map) continue;

      final term = _field(element['term']);
      final meaning = _field(element['meaning']);
      if (term.isEmpty || meaning.isEmpty) continue;
      if (!seen.add(term.toLowerCase())) continue;

      final example = _field(element['example']);
      final reading = _field(element['reading']);
      entries.add(ExtractedVocab(
        term: term,
        meaning: meaning,
        example: example.isEmpty ? null : example,
        reading: reading.isEmpty ? null : reading,
      ));
    }
    return entries;
  }

  /// Normalises one field: markers escaped so a captured word can't forge a
  /// response section when it is later replayed into the tutor's prompt,
  /// whitespace collapsed, and length capped.
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
