class Message {
  final String id;
  final String content;
  final String sender; // 'user' or 'bot'
  final DateTime timestamp;
  final String? translation;
  final String? grammarAnalysis;

  Message({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
    this.translation,
    this.grammarAnalysis,
  });
}

class Chat {
  final String id;
  final String title;
  final DateTime createdAt;
  final Message? lastMessage;
  final String? type; // 'free_chat' or 'scenario'

  Chat({
    required this.id,
    required this.title,
    required this.createdAt,
    this.lastMessage,
    this.type = 'free_chat',
  });
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

  CharacterCustomization({
    this.characterType = 'cat',
    this.openFace = '(•_•)',
    this.closedFace = '(-_-)',
    this.color = '#FFFFFF', // Default white
    this.backgroundColor = '#60A5FA', // Default blue-400 equivalent
  });
}

class DailyRewardInfo {
  final int dayNumber;
  final dynamic reward; // RewardDef from progression.dart
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

  factory ChatAssessmentMessage.fromJson(Map<String, dynamic> json) => ChatAssessmentMessage(
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
    this.selfAssessedLevel = 'beginner',
    this.aiDeterminedLevel = 'beginner',
    DateTime? calibratedAt,
    this.assessmentConversation = const [],
    this.quizScore = 0,
    this.totalQuizQuestions = 5,
    this.isCalibrated = false,
  }) : calibratedAt = calibratedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'languageCode': languageCode,
    'selfAssessedLevel': selfAssessedLevel,
    'aiDeterminedLevel': aiDeterminedLevel,
    'calibratedAt': calibratedAt.toIso8601String(),
    'assessmentConversation': assessmentConversation.map((m) => m.toJson()).toList(),
    'quizScore': quizScore,
    'totalQuizQuestions': totalQuizQuestions,
    'isCalibrated': isCalibrated,
  };

  factory LanguageProficiency.fromJson(Map<String, dynamic> json) => LanguageProficiency(
    languageCode: json['languageCode'],
    selfAssessedLevel: json['selfAssessedLevel'] ?? 'beginner',
    aiDeterminedLevel: json['aiDeterminedLevel'] ?? 'beginner',
    calibratedAt: DateTime.parse(json['calibratedAt']),
    assessmentConversation: (json['assessmentConversation'] as List?)
        ?.map((m) => ChatAssessmentMessage.fromJson(m))
        .toList() ?? [],
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
  }) => LanguageProficiency(
    languageCode: languageCode,
    selfAssessedLevel: selfAssessedLevel ?? this.selfAssessedLevel,
    aiDeterminedLevel: aiDeterminedLevel ?? this.aiDeterminedLevel,
    calibratedAt: calibratedAt ?? this.calibratedAt,
    assessmentConversation: assessmentConversation ?? this.assessmentConversation,
    quizScore: quizScore ?? this.quizScore,
    totalQuizQuestions: totalQuizQuestions ?? this.totalQuizQuestions,
    isCalibrated: isCalibrated ?? this.isCalibrated,
  );
}
