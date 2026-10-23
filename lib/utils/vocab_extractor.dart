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
    this.related = false,
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

  /// A word the tutor added about the topic rather than one it taught in its
  /// reply. These go to the suggested pile the games draw on, not into the
  /// review queue, because the learner has not met them yet.
  final bool related;
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

  /// The words in a bare JSON array, as a starter set comes back, up to
  /// [limit]. Every one is marked related: they are words the learner has not
  /// met, which belong in the suggested pile.
  static List<ExtractedVocab> parseList(String payload, {int limit = 12}) {
    return [
      for (final e in _parse(payload, limit: limit))
        ExtractedVocab(
          term: e.term,
          meaning: e.meaning,
          example: e.example,
          reading: e.reading,
          related: true,
        ),
    ];
  }

  static List<ExtractedVocab> _parse(String payload, {int limit = maxEntries}) {
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
      if (entries.length >= limit) break;
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
        related: element['related'] == true,
      ));
    }
    return entries;
  }

  /// The words worth keeping from [entries]: those the learner did not just
  /// write.
  ///
  /// The learner knows the words they can write, and a game that asks them
  /// back what they just typed teaches nothing. The prompt asks the tutor to
  /// leave them out, and the model does not reliably comply: in a check it
  /// listed `lago` and `montaña` right after the learner had typed both, and
  /// `pazar`, `essen` and `estar` after `pazara`, `esse` and `estás`. So the
  /// app does not rely on it.
  ///
  /// A single word has to match a whole word of [userText], so `a` is not
  /// "found" inside `casa`. A word of five letters or more also matches the
  /// start of one: it is dropped when a written word begins with its stem (the
  /// word less its last two letters), which catches `pazar` after `pazara` and
  /// `essen` after `esse`. That is a heuristic, not a lemmatiser, so it misses
  /// irregular forms (`gitmek` after `gidiyorum`), and now and then drops a
  /// different word that shares a stem. Losing a suggestion costs nothing; a
  /// game asking what you just typed costs the point of it.
  ///
  /// A phrase, or a word in a script with no spaces, is matched anywhere in
  /// [userText], and a phrase is also dropped when every word in it was
  /// written. Accents and case are ignored.
  static List<ExtractedVocab> withoutWritten(
    Iterable<ExtractedVocab> entries, {
    required String userText,
  }) {
    final text = _fold(userText);
    final words = text
        .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
        .where((w) => w.isNotEmpty)
        .toSet();
    return [
      for (final entry in entries)
        if (!_written(entry.term, text, words)) entry,
    ];
  }

  /// The related words worth keeping: those [withoutWritten] leaves, that the
  /// learner does not already have.
  static List<ExtractedVocab> freshRelated(
    Iterable<ExtractedVocab> entries, {
    required String userText,
    required bool Function(String term) isKnown,
  }) {
    return withoutWritten(
      entries.where((e) => e.related && !isKnown(e.term)),
      userText: userText,
    );
  }

  static bool _written(String term, String foldedText, Set<String> words) {
    final t = _fold(term).trim();
    if (t.isEmpty) return true;
    final parts = t
        .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
        .where((w) => w.isNotEmpty)
        .toList();
    final unspaced = t.runes.any((r) => r >= 0x2E80);
    if (unspaced) return foldedText.contains(t);
    if (parts.length > 1) {
      return foldedText.contains(t) || parts.every((w) => _wordWritten(w, words));
    }
    return _wordWritten(t, words);
  }

  static bool _wordWritten(String word, Set<String> written) {
    if (written.contains(word)) return true;
    if (word.length < 5) return false;
    final stem = word.substring(0, word.length - 2);
    return written.any((w) => w.length >= 3 && w.startsWith(stem));
  }

  static const Map<String, String> _accents = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', 'ı': 'i',
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c', 'ñ': 'n', 'ş': 's', 'ğ': 'g',
  };

  static String _fold(String value) {
    final out = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final ch = String.fromCharCode(rune);
      out.write(_accents[ch] ?? ch);
    }
    return out.toString();
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
