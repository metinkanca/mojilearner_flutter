/// Input preparation for text on its way to a model.
///
/// This file used to be a keyword blocklist: it deleted English phrases like
/// "you are a" out of the middle of a message, and `AiGuard` refused to send
/// anything that matched. That approach cost more than it bought. It punished
/// the honest learner — "you are a good teacher!" was rewritten mid-sentence —
/// and a character-ratio heuristic rejected *every* message written in a
/// non-Latin script, which in a language-learning app is the entire point of
/// the product. It stopped no determined attacker either, because the same
/// payload written in Turkish matched nothing at all.
///
/// What survives is the part that is structural rather than lexical:
/// [escapeSpecialMarkers], which stops user text from forging the response
/// sections the app parses, and a length cap. Intent is handled where it
/// belongs — in the system prompt, and in `OutputValidator` on the way back.
/// The pattern list below is kept, but only as a telemetry signal: it records
/// what people try, and never edits or rejects a message.
///
/// Usage:
/// ```dart
/// final sanitized = InputSanitizer.sanitizeUserInput(userMessage);
/// await chatSession.sendMessage(Content.text(sanitized));
/// ```
library;

import 'security_logger.dart';

class InputSanitizer {
  /// Cap on outbound user text. This is the real defence against token
  /// exhaustion, and unlike a blocklist it is language-neutral.
  static const int maxInputLength = 500;

  /// Share of a message that may be neither letter, digit, mark nor space
  /// before it looks like symbol spam rather than a sentence.
  static const double _symbolRatioLimit = 0.3;

  /// Anything outside the Unicode letter/number/mark classes.
  ///
  /// The ASCII version of this check (`[^a-zA-Z0-9\s]`) treated Japanese,
  /// Korean, Chinese, Russian, Arabic and even "¿Qué tal?" as 100% suspicious
  /// characters. Counting by Unicode class is the difference between "this
  /// learner is writing in their target language" and "this is spam".
  static final RegExp _symbolRun =
      RegExp(r'[^\p{L}\p{N}\p{M}\s]', unicode: true);

  /// Phrases worth recording when they show up. Logged, never acted on.
  ///
  /// Deliberately narrower than the old list wherever a phrase is also
  /// ordinary English: "act as if" and "you are a" are things learners write,
  /// and a signal that fires on them is noise rather than intelligence.
  static final List<RegExp> _injectionSignals = [
    // Instruction override
    RegExp(r'ignore\s+(all\s+)?(previous\s+|prior\s+)?instructions?',
        caseSensitive: false),
    RegExp(r'disregard\s+(all\s+)?(previous\s+|prior\s+)?instructions?',
        caseSensitive: false),
    RegExp(r'forget\s+(all\s+)?(previous\s+|prior\s+)?instructions?',
        caseSensitive: false),

    // Role replacement, in the phrasings that are not also small talk
    RegExp(r'you\s+are\s+now\s+', caseSensitive: false),
    RegExp(r'pretend\s+(to\s+be|that\s+you)', caseSensitive: false),
    RegExp(r'simulate\s+being', caseSensitive: false),

    // Turn forgery
    RegExp(r'^\s*(system|assistant)\s*:',
        caseSensitive: false, multiLine: true),

    // Response-section forgery. Escaped by [escapeSpecialMarkers] regardless;
    // this only records the attempt.
    RegExp(r'\|\|\|'),

    // Prompt extraction
    RegExp(r'show\s+(me\s+)?(your|the)\s+(system\s+)?(prompt|instructions)',
        caseSensitive: false),
    RegExp(r'what\s+(are|is)\s+your\s+(system\s+)?(prompt|instructions)',
        caseSensitive: false),
    RegExp(r'reveal\s+(your|the)\s+prompt', caseSensitive: false),
  ];

  /// Prepares user text for a model without changing what the user said.
  ///
  /// Escapes the app's own response markers, strips control characters,
  /// collapses whitespace and caps the length. A message that trips an
  /// injection signal is logged and then sent as written — the system prompt
  /// decides how to answer it.
  static String sanitizeUserInput(String input, {String source = 'unknown'}) {
    if (input.isEmpty) return input;

    if (isSuspicious(input)) {
      logSuspiciousInput(input, source);
    }

    // 1. Escape the markers the app parses out of model output, so user text
    //    cannot forge a section or a hidden block.
    var sanitized = escapeSpecialMarkers(input);

    // 2. Remove control characters that would break the section format.
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

    // 3. Collapse whitespace, then cap. Collapsing first means a message
    //    padded with blank space is not truncated to nothing.
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (sanitized.length > maxInputLength) {
      sanitized = sanitized.substring(0, maxInputLength).trim();
    }

    return sanitized;
  }

  /// Escapes the markers the app uses to delimit model output.
  ///
  /// This is the load-bearing defence in this file. Without it a learner
  /// could type `|||VOCAB|||` and have their own JSON parsed into the review
  /// queue when the conversation is replayed to the model as history.
  static String escapeSpecialMarkers(String input) {
    return input
        .replaceAll('|||MISTAKE|||', '[MISTAKE]')
        .replaceAll('|||VOCAB|||', '[VOCAB]')
        .replaceAll('|||OBJECTIVE|||', '[OBJECTIVE]')
        .replaceAll('|||', '|')
        .replaceAll('TEXT:', 'TEXT -')
        .replaceAll('READING:', 'READING -')
        .replaceAll('TRANS:', 'TRANS -')
        .replaceAll('GRAMMAR:', 'GRAMMAR -');
  }

  /// Validates a language or level name before it is interpolated into a
  /// prompt.
  ///
  /// Safe to restrict to ASCII: `Language.name` is deliberately the English
  /// name (see `constants/language_names.dart`), and levels are English
  /// words. Returns null rather than an empty string when nothing survives,
  /// so a caller's `?? 'Spanish'` fallback actually fires.
  static String? sanitizeLanguageName(String? languageName) {
    if (languageName == null || languageName.isEmpty) return null;

    final cleaned = languageName
        .replaceAll(RegExp(r'[^a-zA-Z\s\-]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return null;

    return cleaned.length > 50 ? cleaned.substring(0, 50).trim() : cleaned;
  }

  /// Whether the input is worth recording as a possible injection attempt.
  ///
  /// Advisory only — nothing in the app refuses a message on this basis.
  static bool isSuspicious(String input) {
    if (input.isEmpty) return false;

    for (final pattern in _injectionSignals) {
      if (pattern.hasMatch(input)) return true;
    }

    // Symbol spam, counted by Unicode class so that writing in the language
    // being learned is not itself suspicious.
    final symbols = _symbolRun.allMatches(input).length;
    if (symbols > input.length * _symbolRatioLimit) return true;

    // A short fragment repeated many times is a padding payload, not a
    // sentence.
    if (RegExp(r'(.+)\1{5,}').hasMatch(input)) return true;

    return false;
  }

  /// Records a suspicious message for monitoring.
  static void logSuspiciousInput(String input, String source) {
    final matchedPatterns = <String>[];
    for (final pattern in _injectionSignals) {
      if (pattern.hasMatch(input)) {
        matchedPatterns.add(pattern.pattern);
      }
    }

    SecurityLogger.logInjectionAttempt(
      input: input,
      source: source,
      patterns: matchedPatterns,
    );
  }
}
