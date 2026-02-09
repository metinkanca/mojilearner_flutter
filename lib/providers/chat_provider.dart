import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ChatProvider extends ChangeNotifier {
  List<Chat> _chats = [];
  final Map<String, List<Message>> _messages = {};
  bool _isLoading = true;

  List<Chat> get chats => _chats;
  bool get isLoading => _isLoading;
  late Future<void> loadFuture;

  ChatProvider() {
    loadFuture = _loadChats();
  }

  Future<void> _loadChats() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Chats
    final String? chatsJson = prefs.getString('chats');
    if (chatsJson != null) {
      final List<dynamic> decoded = jsonDecode(chatsJson);
      _chats = decoded.map((json) => Chat(
        id: json['id'],
        title: json['title'],
        createdAt: DateTime.parse(json['createdAt']),
        type: json['type'] ?? 'free_chat',
        lastMessage: json['lastMessage'] != null ? Message(
          id: json['lastMessage']['id'],
          content: json['lastMessage']['content'],
          sender: json['lastMessage']['sender'],
          timestamp: DateTime.parse(json['lastMessage']['timestamp']),
        ) : null,
      )).toList();
    } else {
      // Default Empty or Welcome Chat?
      _chats = [];
    }

    // Load Messages for each chat
    for (var chat in _chats) {
      final String? msgsJson = prefs.getString('messages_${chat.id}');
      if (msgsJson != null) {
        final List<dynamic> decodedMsgs = jsonDecode(msgsJson);
        _messages[chat.id] = decodedMsgs.map((json) => Message(
          id: json['id'],
          content: json['content'],
          sender: json['sender'],
          timestamp: DateTime.parse(json['timestamp']),
          translation: json['translation'],
          grammarAnalysis: json['grammarAnalysis'],
        )).toList();
      }
    }

    _sortChats();
    _isLoading = false;
    notifyListeners();
  }

  void _sortChats() {
    _chats.sort((a, b) {
      DateTime aTime = a.lastMessage?.timestamp ?? a.createdAt;
      DateTime bTime = b.lastMessage?.timestamp ?? b.createdAt;
      return bTime.compareTo(aTime);
    });
  }

  Future<void> _saveChats() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save Chats Metadata
    final chatsJson = jsonEncode(_chats.map((c) => {
      'id': c.id,
      'title': c.title,
      'createdAt': c.createdAt.toIso8601String(),
      'type': c.type,
      'lastMessage': c.lastMessage != null ? {
        'id': c.lastMessage!.id,
        'content': c.lastMessage!.content,
        'sender': c.lastMessage!.sender,
        'timestamp': c.lastMessage!.timestamp.toIso8601String(),
      } : null,
    }).toList());
    
    await prefs.setString('chats', chatsJson);
  }

  Future<void> _saveMessages(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    if (_messages[chatId] != null) {
        final msgsJson = jsonEncode(_messages[chatId]!.map((m) => {
        'id': m.id,
        'content': m.content,
        'sender': m.sender,
        'timestamp': m.timestamp.toIso8601String(),
        'translation': m.translation,
        'grammarAnalysis': m.grammarAnalysis,
      }).toList());
      await prefs.setString('messages_${chatId}', msgsJson);
    }
  }

  // Get messages for a chat
  List<Message> getMessages(String chatId) {
    return _messages[chatId] ?? [];
  }

  // Create a new chat
  Future<String> createNewChat({String title = "New Chat", String type = "free_chat"}) async {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newChat = Chat(
      id: newId,
      title: title,
      createdAt: DateTime.now(),
      type: type,
    );

    _chats.insert(0, newChat);
    _messages[newId] = [];
    
    await _saveChats();
    notifyListeners();
    return newId;
  }

  // Add message to a chat
  Future<void> addMessage(String chatId, Message message) async {
    if (_messages[chatId] == null) {
      _messages[chatId] = [];
    }
    _messages[chatId]!.add(message);

    // Update last message in chat list
    final index = _chats.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      final oldChat = _chats[index];
      _chats[index] = Chat(
        id: oldChat.id,
        title: oldChat.title,
        createdAt: oldChat.createdAt,
        type: oldChat.type,
        lastMessage: message,
      );
      _sortChats();
    }

    notifyListeners();
    await _saveChats();
    await _saveMessages(chatId);
  }
}
