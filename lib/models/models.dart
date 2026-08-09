import '../constants/progression.dart';
import '../utils/level_validator.dart';
import '../utils/srs_scheduler.dart';

class Message {
  final String id;
  final String content;
  final String sender; // 'user' or 'bot'
  final DateTime timestamp;
  final String? translation;
  final String? grammarAnalysis;

  /// Romanized pronunciation of [content], for target languages written in a
  /// script the learner cannot yet sound out.
  ///
  /// Null for Latin-script languages, where it would be noise, and for every
  /// message stored before readings existed.
  final String? reading;

  Message({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
    this.translation,
    this.grammarAnalysis,
    this.reading,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'sender': sender,
        'timestamp': timestamp.toIso8601String(),
        'translation': translation,
        'grammarAnalysis': grammarAnalysis,
        'reading': reading,
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'],
        content: json['content'],
        sender: json['sender'],
        timestamp: DateTime.parse(json['timestamp']),
        translation: json['translation'],
        grammarAnalysis: json['grammarAnalysis'],
        // Absent on messages persisted before readings existed.
        reading: json['reading'] as String?,
      );
}

class Chat {
  final String id;
  final String title;
  final DateTime createdAt;
  final Message? lastMessage;
  final String? type; // 'free_chat' or 'scenario'

  /// Which scenario this chat is playing, e.g. 'coffee'.
  ///
  /// Stable across app languages, unlike [title], which is the localized
  /// label the user happened to see. Quest progress keys off this. Null for
  /// free chats, custom scenarios, and any scenario chat created before
  /// scenarios became trackable.
  final String? scenarioId;

  Chat({
    required this.id,
    required this.title,
    required this.createdAt,
    this.lastMessage,
    this.type = 'free_chat',
    this.scenarioId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'type': type,
        'scenarioId': scenarioId,
        'lastMessage': lastMessage?.toJson(),
      };

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
        id: json['id'],
        title: json['title'],
        createdAt: DateTime.parse(json['createdAt']),
        type: json['type'] ?? 'free_chat',
        // Absent on chats persisted before this field existed.
        scenarioId: json['scenarioId'] as String?,
        lastMessage: json['lastMessage'] != null
            ? Message.fromJson(
                Map<String, dynamic>.from(json['lastMessage'] as Map))
            : null,
      );
}

/// A learner's standing with one scenario.
///
/// [clearedObjectiveIds] is the *current* run's progress and resets when the
/// scenario is replayed; [timesCompleted] is the permanent record. Keeping
/// both means a card can show "2/4" mid-run and still remember the scenario
/// was cleared last week.
class ScenarioProgress {
  final String scenarioId;
  final Set<String> clearedObjectiveIds;
  final int timesCompleted;
  final DateTime? firstCompletedAt;
  final DateTime? lastPlayedAt;

  const ScenarioProgress({
    required this.scenarioId,
    this.clearedObjectiveIds = const {},
    this.timesCompleted = 0,
    this.firstCompletedAt,
    this.lastPlayedAt,
  });

  bool get hasEverCompleted => timesCompleted > 0;

  bool isCleared(String objectiveId) =>
      clearedObjectiveIds.contains(objectiveId);

  ScenarioProgress copyWith({
    Set<String>? clearedObjectiveIds,
    int? timesCompleted,
    DateTime? firstCompletedAt,
    DateTime? lastPlayedAt,
  }) {
    return ScenarioProgress(
      scenarioId: scenarioId,
      clearedObjectiveIds: clearedObjectiveIds ?? this.clearedObjectiveIds,
      timesCompleted: timesCompleted ?? this.timesCompleted,
      firstCompletedAt: firstCompletedAt ?? this.firstCompletedAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'scenarioId': scenarioId,
        'clearedObjectiveIds': clearedObjectiveIds.toList(),
        'timesCompleted': timesCompleted,
        'firstCompletedAt': firstCompletedAt?.toIso8601String(),
        'lastPlayedAt': lastPlayedAt?.toIso8601String(),
      };

  factory ScenarioProgress.fromJson(Map<String, dynamic> json) {
    return ScenarioProgress(
      scenarioId: json['scenarioId'] as String,
      clearedObjectiveIds: ((json['clearedObjectiveIds'] as List?) ?? const [])
          .map((id) => id.toString())
          .toSet(),
      timesCompleted: (json['timesCompleted'] as num?)?.toInt() ?? 0,
      firstCompletedAt: json['firstCompletedAt'] != null
          ? DateTime.tryParse(json['firstCompletedAt'] as String)
          : null,
      lastPlayedAt: json['lastPlayedAt'] != null
          ? DateTime.tryParse(json['lastPlayedAt'] as String)
          : null,
    );
  }
}

class Mistake {
  final String id;
  final String original;
  final String correction;
  final String explanation;
  final String type; // 'grammar', 'vocabulary', etc.
  final DateTime timestamp;

  Mistake({
    required this.id,
    required this.original,
    required this.correction,
    required this.explanation,
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'original': original,
        'correction': correction,
        'explanation': explanation,
        'type': type,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Mistake.fromJson(Map<String, dynamic> json) => Mistake(
        id: json['id'] as String,
        original: json['original'] as String,
        correction: json['correction'] as String,
        explanation: json['explanation'] as String,
        type: json['type'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

/// Where a review item came from, which decides how it's presented.
enum ReviewItemKind {
  /// A word or phrase: recall the meaning.
  vocabulary,

  /// Something the learner got wrong: recall the correction.
  correction,
}

/// One thing the learner is trying to remember, plus its SM-2 schedule.
///
/// Items are immutable — [reviewed] returns the rescheduled copy — so the
/// provider can't accidentally mutate an item without persisting it.
class ReviewItem {
  final String id;
  final String languageCode;

  /// What the learner is shown: the target-language word, or the sentence
  /// they originally got wrong.
  final String prompt;

  /// What they have to recall: the meaning, or the correction.
  final String answer;

  /// Optional supporting detail — an example sentence, or the explanation
  /// of why the original was wrong.
  final String? context;

  /// Romanized pronunciation of [prompt], for non-Latin scripts. Without it,
  /// a Japanese review item is a picture the learner can recognise but never
  /// say out loud.
  final String? reading;

  final ReviewItemKind kind;

  // ---- SM-2 scheduling state ----
  final double easeFactor;
  final int intervalDays;
  final int repetitions;

  /// How many times this item has been forgotten. Useful for surfacing a
  /// learner's genuine problem spots.
  final int lapses;
  final DateTime dueAt;
  final DateTime createdAt;
  final DateTime? lastReviewedAt;

  ReviewItem({
    required this.id,
    required this.languageCode,
    required this.prompt,
    required this.answer,
    this.context,
    this.reading,
    this.kind = ReviewItemKind.vocabulary,
    this.easeFactor = SrsScheduler.defaultEaseFactor,
    this.intervalDays = 0,
    this.repetitions = 0,
    this.lapses = 0,
    DateTime? dueAt,
    DateTime? createdAt,
    this.lastReviewedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        // New items are due immediately so they enter rotation the same day
        // they're captured.
        dueAt = dueAt ?? createdAt ?? DateTime.now();

  /// A stable key for de-duplication: the same word captured twice, or the
  /// same mistake made twice, should update one item rather than pile up.
  static String dedupeKey({
    required String languageCode,
    required ReviewItemKind kind,
    required String prompt,
  }) {
    return '$languageCode|${kind.name}|${prompt.trim().toLowerCase()}';
  }

  String get key =>
      dedupeKey(languageCode: languageCode, kind: kind, prompt: prompt);

  bool isDue({DateTime? now}) {
    final moment = now ?? DateTime.now();
    return !dueAt.isAfter(moment);
  }

  /// True once the item has survived enough reviews to count as known.
  bool get isLearned => repetitions >= 3;

  /// Applies a review, returning the rescheduled copy.
  ReviewItem reviewed(ReviewGrade grade, {DateTime? now}) {
    final moment = now ?? DateTime.now();
    final outcome = SrsScheduler.next(
      repetitions: repetitions,
      easeFactor: easeFactor,
      intervalDays: intervalDays,
      grade: grade,
    );

    return copyWith(
      easeFactor: outcome.easeFactor,
      intervalDays: outcome.intervalDays,
      repetitions: outcome.repetitions,
      lapses: grade.isLapse ? lapses + 1 : lapses,
      dueAt: moment.add(Duration(days: outcome.intervalDays)),
      lastReviewedAt: moment,
    );
  }

  ReviewItem copyWith({
    String? prompt,
    String? answer,
    String? context,
    String? reading,
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    int? lapses,
    DateTime? dueAt,
    DateTime? lastReviewedAt,
  }) {
    return ReviewItem(
      id: id,
      languageCode: languageCode,
      prompt: prompt ?? this.prompt,
      answer: answer ?? this.answer,
      context: context ?? this.context,
      reading: reading ?? this.reading,
      kind: kind,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      lapses: lapses ?? this.lapses,
      dueAt: dueAt ?? this.dueAt,
      createdAt: createdAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'languageCode': languageCode,
        'prompt': prompt,
        'answer': answer,
        'context': context,
        'reading': reading,
        'kind': kind.name,
        'easeFactor': easeFactor,
        'intervalDays': intervalDays,
        'repetitions': repetitions,
        'lapses': lapses,
        'dueAt': dueAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'lastReviewedAt': lastReviewedAt?.toIso8601String(),
      };

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    final createdAt =
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now();
    return ReviewItem(
      id: json['id'] as String,
      languageCode: json['languageCode'] as String? ?? 'en',
      prompt: json['prompt'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      context: json['context'] as String?,
      // Absent on items persisted before readings existed.
      reading: json['reading'] as String?,
      kind: ReviewItemKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => ReviewItemKind.vocabulary,
      ),
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ??
          SrsScheduler.defaultEaseFactor,
      intervalDays: (json['intervalDays'] as num?)?.toInt() ?? 0,
      repetitions: (json['repetitions'] as num?)?.toInt() ?? 0,
      lapses: (json['lapses'] as num?)?.toInt() ?? 0,
      dueAt: DateTime.tryParse(json['dueAt'] as String? ?? '') ?? createdAt,
      createdAt: createdAt,
      lastReviewedAt: json['lastReviewedAt'] == null
          ? null
          : DateTime.tryParse(json['lastReviewedAt'] as String),
    );
  }
}

class UserStats {
  final int level;
  final int totalXP;
  final int currentLevelXP;
  final int nextLevelXP;
  final int streak;
  final int coins;
  final double progress;

  UserStats({
    this.level = 1,
    this.totalXP = 0,
    this.currentLevelXP = 0,
    this.nextLevelXP = 100,
    this.streak = 0,
    this.coins = 0,
    this.progress = 0.0,
  });

  int get xp => currentLevelXP;
  int get totalXPInLevel => nextLevelXP; // The denominator
  int get xpToNextLevel => nextLevelXP - currentLevelXP; // Remaining
}

class CharacterCustomization {
  final String characterType; // 'dog', 'cat', 'bird'
  final String openFace;
  final String closedFace;
  final String color;
  final String backgroundColor;

  /// Flat fill for the body + tail (always shared). Defaults to the pet's
  /// original coat so an un-customised pet looks unchanged.
  final String bodyColor;

  /// 'solid' | 'heterochromia' | 'dichroic' — see [EyeMode] in pet_recolor.dart.
  final String eyeMode;

  /// Primary eye colour: both eyes (solid), the left eye (heterochromia) or
  /// the outer ring (dichroic).
  final String eyeColor1;

  /// Secondary eye colour: the right eye (heterochromia) or the pupil
  /// (dichroic). Ignored for solid.
  final String eyeColor2;

  CharacterCustomization({
    this.characterType = 'cat',
    this.openFace = '(•_•)',
    this.closedFace = '(-_-)',
    this.color = '#FFFFFF', // Default white
    this.backgroundColor = '#60A5FA', // Default blue-400 equivalent
    this.bodyColor = '#959379', // Original coat ("Smoke")
    this.eyeMode = 'solid',
    this.eyeColor1 = '#F4C430', // Gold — the most common cat eye colour
    this.eyeColor2 = '#5AA0E0', // Blue — sensible second colour for odd-eyes
  });

  CharacterCustomization copyWith({
    String? characterType,
    String? openFace,
    String? closedFace,
    String? color,
    String? backgroundColor,
    String? bodyColor,
    String? eyeMode,
    String? eyeColor1,
    String? eyeColor2,
  }) {
    return CharacterCustomization(
      characterType: characterType ?? this.characterType,
      openFace: openFace ?? this.openFace,
      closedFace: closedFace ?? this.closedFace,
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      bodyColor: bodyColor ?? this.bodyColor,
      eyeMode: eyeMode ?? this.eyeMode,
      eyeColor1: eyeColor1 ?? this.eyeColor1,
      eyeColor2: eyeColor2 ?? this.eyeColor2,
    );
  }
}

class DailyRewardInfo {
  final int dayNumber;
  final RewardDef reward;
  final bool streakReset;
  final int currentStreak;

  DailyRewardInfo({
    required this.dayNumber,
    required this.reward,
    required this.streakReset,
    required this.currentStreak,
  });
}

class ChatAssessmentMessage {
  final String id;
  final String content;
  final String sender; // 'user' or 'ai'
  final DateTime timestamp;

  ChatAssessmentMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'sender': sender,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatAssessmentMessage.fromJson(Map<String, dynamic> json) =>
      ChatAssessmentMessage(
        id: json['id'],
        content: json['content'],
        sender: json['sender'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

class LanguageProficiency {
  final String languageCode;
  final String selfAssessedLevel; // 'beginner', 'intermediate', 'advanced'
  final String aiDeterminedLevel; // After chat + quiz
  final DateTime calibratedAt;
  final List<ChatAssessmentMessage> assessmentConversation;
  final int quizScore;
  final int totalQuizQuestions;
  final bool isCalibrated;

  LanguageProficiency({
    required this.languageCode,
    String selfAssessedLevel = LevelValidator.beginner,
    String aiDeterminedLevel = LevelValidator.beginner,
    DateTime? calibratedAt,
    this.assessmentConversation = const [],
    this.quizScore = 0,
    this.totalQuizQuestions = 5,
    this.isCalibrated = false,
  })  : selfAssessedLevel = LevelValidator.normalizeLevel(selfAssessedLevel),
        aiDeterminedLevel = LevelValidator.normalizeLevel(aiDeterminedLevel),
        calibratedAt = calibratedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'languageCode': languageCode,
        'selfAssessedLevel': selfAssessedLevel,
        'aiDeterminedLevel': aiDeterminedLevel,
        'calibratedAt': calibratedAt.toIso8601String(),
        'assessmentConversation':
            assessmentConversation.map((m) => m.toJson()).toList(),
        'quizScore': quizScore,
        'totalQuizQuestions': totalQuizQuestions,
        'isCalibrated': isCalibrated,
      };

  factory LanguageProficiency.fromJson(Map<String, dynamic> json) =>
      LanguageProficiency(
        languageCode: json['languageCode'],
        selfAssessedLevel: LevelValidator.normalizeLevel(
          json['selfAssessedLevel'] as String?,
        ),
        aiDeterminedLevel: LevelValidator.normalizeLevel(
          json['aiDeterminedLevel'] as String?,
        ),
        calibratedAt: DateTime.parse(json['calibratedAt']),
        assessmentConversation: (json['assessmentConversation'] as List?)
                ?.map((m) => ChatAssessmentMessage.fromJson(m))
                .toList() ??
            [],
        quizScore: json['quizScore'] ?? 0,
        totalQuizQuestions: json['totalQuizQuestions'] ?? 5,
        isCalibrated: json['isCalibrated'] ?? false,
      );

  LanguageProficiency copyWith({
    String? selfAssessedLevel,
    String? aiDeterminedLevel,
    DateTime? calibratedAt,
    List<ChatAssessmentMessage>? assessmentConversation,
    int? quizScore,
    int? totalQuizQuestions,
    bool? isCalibrated,
  }) =>
      LanguageProficiency(
        languageCode: languageCode,
        selfAssessedLevel: LevelValidator.normalizeLevel(
          selfAssessedLevel,
          fallback: this.selfAssessedLevel,
        ),
        aiDeterminedLevel: LevelValidator.normalizeLevel(
          aiDeterminedLevel,
          fallback: this.aiDeterminedLevel,
        ),
        calibratedAt: calibratedAt ?? this.calibratedAt,
        assessmentConversation:
            assessmentConversation ?? this.assessmentConversation,
        quizScore: quizScore ?? this.quizScore,
        totalQuizQuestions: totalQuizQuestions ?? this.totalQuizQuestions,
        isCalibrated: isCalibrated ?? this.isCalibrated,
      );
}
