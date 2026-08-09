/// Pulls the objective block out of a scenario reply.
///
/// During a scenario the tutor reports which objectives the learner's last
/// turn satisfied. That report is model output, so it is treated as a claim
/// to be checked, not a fact: ids are whitelisted against the scenario
/// definition, which is what stops an invented `"all_done"` from
/// self-awarding a clear.
library;

import 'dart:convert';

/// The reply with the block removed, plus the ids the tutor claimed.
class ObjectiveExtraction {
  const ObjectiveExtraction({required this.content, required this.objectiveIds});

  final String content;

  /// Claimed ids, already de-duplicated. Still unvalidated — pass them
  /// through [ScenarioProvider.markObjectives], which drops unknown ids.
  final List<String> objectiveIds;
}

class ObjectiveExtractor {
  ObjectiveExtractor._();

  static const String marker = '|||OBJECTIVE|||';

  /// A single turn can plausibly satisfy two goals at once; more than this is
  /// a model over-claiming and gets truncated.
  static const int maxIds = 3;

  /// Ids are short slugs from the catalogue. Anything longer is not one.
  static const int maxIdLength = 40;

  static final RegExp _idPattern = RegExp(r'^[a-z0-9_]+$');

  /// Splits [response] on [marker] and parses the trailing JSON array of ids.
  ///
  /// A missing or malformed block yields no ids and always strips cleanly —
  /// failing to tick an objective is recoverable, leaking JSON into the chat
  /// bubble is not.
  static ObjectiveExtraction extract(String response) {
    if (!response.contains(marker)) {
      return ObjectiveExtraction(content: response, objectiveIds: const []);
    }

    final parts = response.split(marker);
    final content = parts.first.trim();
    if (parts.length < 2) {
      return ObjectiveExtraction(content: content, objectiveIds: const []);
    }

    return ObjectiveExtraction(
      content: content,
      objectiveIds: _parse(parts[1]),
    );
  }

  static List<String> _parse(String payload) {
    final cleaned =
        payload.replaceAll('```json', '').replaceAll('```', '').trim();
    if (cleaned.isEmpty) return const [];

    final Object? decoded;
    try {
      decoded = json.decode(cleaned);
    } catch (_) {
      return const [];
    }
    if (decoded is! List) return const [];

    final ids = <String>[];
    for (final element in decoded) {
      if (ids.length >= maxIds) break;
      if (element is! String) continue;

      final id = element.trim().toLowerCase();
      if (id.isEmpty || id.length > maxIdLength) continue;
      // Shape check only; membership is the catalogue's call.
      if (!_idPattern.hasMatch(id)) continue;
      if (ids.contains(id)) continue;

      ids.add(id);
    }
    return ids;
  }
}
