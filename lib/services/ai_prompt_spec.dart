/// Names a prompt and supplies its data, without containing a word of it.
///
/// The app used to build every system instruction and one-shot prompt itself
/// and send the finished text to the proxy. That made the proxy a
/// general-purpose model relay for anyone who pulled `AI_PROXY_TOKEN` out of
/// the bundle, and it meant a wording fix needed a store release.
///
/// Now the wording lives in `server/src/prompts.js` and the app names a mode.
/// Everything in [params] is data the server escapes, caps and frames before
/// interpolating: language codes, a level, a scenario's objectives, the
/// review queue, an assessment transcript. There is no field here that can
/// carry a sentence of instruction, and that is the point.
library;

import '../models/models.dart';

/// The prompts the service knows how to build.
///
/// Split the way the endpoints are: [chat] and [assessment] open a session,
/// [quiz] and [level] answer a single generate call. The server refuses a
/// generate mode used as a persona and vice versa, so the split is enforced on
/// both sides.
enum AiPromptMode {
  chat('chat'),
  assessment('assessment'),
  quiz('quiz'),
  level('level');

  const AiPromptMode(this.wireName);

  /// What the server calls this mode.
  final String wireName;
}

/// One review item, in the shape the prompt builders read.
class AiReviewItem {
  const AiReviewItem({
    required this.id,
    required this.prompt,
    required this.answer,
    required this.isCorrection,
    this.lapses = 0,
  });

  /// Built from a stored [ReviewItem].
  factory AiReviewItem.from(ReviewItem item) => AiReviewItem(
        id: item.id,
        prompt: item.prompt,
        answer: item.answer,
        isCorrection: item.kind == ReviewItemKind.correction,
        lapses: item.lapses,
      );

  final String id;
  final String prompt;
  final String answer;
  final bool isCorrection;
  final int lapses;

  Map<String, Object?> toJson() => {
        'id': id,
        'prompt': prompt,
        'answer': answer,
        'kind': isCorrection ? 'correction' : 'vocabulary',
        if (lapses > 0) 'lapses': lapses,
      };
}

/// One scenario objective, as the roleplay brief needs it.
class AiObjective {
  const AiObjective({
    required this.id,
    required this.label,
    required this.isBonus,
    required this.isCleared,
  });

  final String id;
  final String label;
  final bool isBonus;
  final bool isCleared;

  Map<String, Object?> toJson() => {
        'id': id,
        'label': label,
        if (isBonus) 'bonus': true,
        if (isCleared) 'cleared': true,
      };
}

/// One turn of an assessment transcript.
class AiTranscriptLine {
  const AiTranscriptLine({required this.isLearner, required this.text});

  final bool isLearner;
  final String text;

  Map<String, Object?> toJson() => {
        'speaker': isLearner ? 'learner' : 'assessor',
        'text': text,
      };
}

/// A prompt request: which prompt, and the data to fill it with.
class AiPromptSpec {
  const AiPromptSpec._(this.mode, this.params);

  final AiPromptMode mode;
  final Map<String, Object?> params;

  /// The language tutor.
  ///
  /// [troubleSpots] and [dueItems] are already trimmed by the caller, which
  /// decides what is worth showing the tutor. The server caps them again, so
  /// sending more simply wastes the request rather than growing the prompt.
  ///
  /// [scenarioHost] is the pet type playing the scene's other side, which the
  /// tutor is cast as.
  ///
  /// [level] is the player's assessed level in [targetCode], one of the three
  /// words the server recognises.
  factory AiPromptSpec.chat({
    required String? targetCode,
    required String? nativeCode,
    String? scenarioTitle,
    String? scenarioHost,
    String? level,
    List<AiObjective> objectives = const [],
    List<AiReviewItem> troubleSpots = const [],
    List<AiReviewItem> dueItems = const [],
  }) {
    return AiPromptSpec._(AiPromptMode.chat, {
      'targetCode': targetCode,
      'nativeCode': nativeCode,
      // The tutor's own wording does not change with it. It pitches the related
      // words it adds to the vocabulary block, and only those.
      if (level != null && level.isNotEmpty) 'level': level,
      if (scenarioTitle != null && scenarioTitle.isNotEmpty)
        'scenario': {
          'title': scenarioTitle,
          if (scenarioHost != null) 'host': scenarioHost,
          if (objectives.isNotEmpty)
            'objectives': objectives.map((o) => o.toJson()).toList(),
        },
      if (troubleSpots.isNotEmpty || dueItems.isNotEmpty)
        'review': {
          if (troubleSpots.isNotEmpty)
            'trouble': troubleSpots.map((i) => i.toJson()).toList(),
          if (dueItems.isNotEmpty)
            'due': dueItems.map((i) => i.toJson()).toList(),
        },
    });
  }

  /// The onboarding assessment conversation.
  factory AiPromptSpec.assessment({
    required String? targetCode,
    required String selfLevel,
  }) =>
      AiPromptSpec._(AiPromptMode.assessment, {
        'targetCode': targetCode,
        'selfLevel': selfLevel,
      });

  /// A generated quiz.
  factory AiPromptSpec.quiz({
    required String? targetCode,
    required String? nativeCode,
    required String level,
    List<AiReviewItem> troubleSpots = const [],
    List<AiReviewItem> dueItems = const [],
  }) {
    return AiPromptSpec._(AiPromptMode.quiz, {
      'targetCode': targetCode,
      'nativeCode': nativeCode,
      'level': level,
      if (troubleSpots.isNotEmpty || dueItems.isNotEmpty)
        'review': {
          if (troubleSpots.isNotEmpty)
            'trouble': troubleSpots.map((i) => i.toJson()).toList(),
          if (dueItems.isNotEmpty)
            'due': dueItems.map((i) => i.toJson()).toList(),
        },
    });
  }

  /// Turning an assessment transcript into one proficiency word.
  factory AiPromptSpec.level({
    required String? targetCode,
    required String selfLevel,
    required List<AiTranscriptLine> transcript,
  }) =>
      AiPromptSpec._(AiPromptMode.level, {
        'targetCode': targetCode,
        'selfLevel': selfLevel,
        'transcript': transcript.map((l) => l.toJson()).toList(),
      });
}
