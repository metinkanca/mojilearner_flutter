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
  final int xp;
  final int streak;
  final int coins;
  final int xpToNextLevel;

  UserStats({
    this.level = 1,
    this.xp = 0,
    this.streak = 0,
    this.coins = 0,
    this.xpToNextLevel = 100,
  });
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
