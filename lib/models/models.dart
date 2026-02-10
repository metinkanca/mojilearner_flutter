import 'package:flutter/foundation.dart';

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
  final String openFace;
  final String closedFace;
  final String color;
  final String backgroundColor;

  CharacterCustomization({
    this.openFace = '(•_•)',
    this.closedFace = '(-_-)',
    this.color = '#FFFFFF', // Default white
    this.backgroundColor = '#60A5FA', // Default blue-400 equivalent
  });
}
