import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../utils/secure_storage.dart';

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
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if migration is needed
      final migrationComplete = prefs.getBool('chat_migration_complete') ?? false;
      
      if (!migrationComplete) {
        await _migrateToSecureStorage(prefs);
      }

      // Load from SecureStorage (encrypted)
      final chatsData = await SecureStorage.readAllChats();
      
      if (chatsData != null) {
        _chats = chatsData.map((json) => Chat(
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
        // If encrypted storage has no data but legacy data exists, use fallback.
        final hasLegacyChats = prefs.getString('chats') != null;
        if (hasLegacyChats) {
          await _loadFromSharedPreferences();
          return;
        }
        _chats = [];
      }

      // Load Messages for each chat from SecureStorage
      for (var chat in _chats) {
        final messagesData = await SecureStorage.readChatHistory(chat.id);
        if (messagesData != null) {
          _messages[chat.id] = messagesData.map((json) => Message(
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
    } catch (e) {
      print('⚠️ CHAT_PROVIDER: Error loading chats - $e');
      // Fallback to SharedPreferences if SecureStorage fails
      await _loadFromSharedPreferences();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _sortChats() {
    _chats.sort((a, b) {
      DateTime aTime = a.lastMessage?.timestamp ?? a.createdAt;
      DateTime bTime = b.lastMessage?.timestamp ?? b.createdAt;
      return bTime.compareTo(aTime);
    });
  }

  Future<void> _saveChats() async {
    try {
      // Save to SecureStorage (encrypted)
      final chatsData = _chats.map((c) => {
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
      }).toList();
      
      await SecureStorage.saveAllChats(chatsData);

      // Keep legacy backup for compatibility and tests.
      final prefs = await SharedPreferences.getInstance();
      final chatsJson = jsonEncode(chatsData);
      await prefs.setString('chats', chatsJson);
    } catch (e) {
      print('⚠️ CHAT_PROVIDER: Error saving chats - $e');
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
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
  }

  Future<void> _saveMessages(String chatId) async {
    try {
      if (_messages[chatId] != null) {
        final messagesData = _messages[chatId]!.map((m) => {
          'id': m.id,
          'content': m.content,
          'sender': m.sender,
          'timestamp': m.timestamp.toIso8601String(),
          'translation': m.translation,
          'grammarAnalysis': m.grammarAnalysis,
        }).toList();
        
        await SecureStorage.saveChatHistory(chatId, messagesData);

        // Keep legacy backup for compatibility and tests.
        final prefs = await SharedPreferences.getInstance();
        final msgsJson = jsonEncode(messagesData);
        await prefs.setString('messages_$chatId', msgsJson);
      }
    } catch (e) {
      print('⚠️ CHAT_PROVIDER: Error saving messages for $chatId - $e');
      // Fallback to SharedPreferences
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

  // ===== MIGRATION HELPERS =====
  
  /// Migrate chat data from SharedPreferences to SecureStorage
  Future<void> _migrateToSecureStorage(SharedPreferences prefs) async {
    try {
      print('🔄 CHAT_PROVIDER: Starting migration to SecureStorage...');
      
      // Check if there's data to migrate in SharedPreferences
      final String? chatsJson = prefs.getString('chats');
      
      if (chatsJson != null) {
        print('🔄 CHAT_PROVIDER: Found chat data in SharedPreferences, migrating...');
        
        // Parse the chat data
        final List<dynamic> decoded = jsonDecode(chatsJson);
        final chatsData = decoded.map((json) => {
          'id': json['id'],
          'title': json['title'],
          'createdAt': json['createdAt'],
          'type': json['type'] ?? 'free_chat',
          'lastMessage': json['lastMessage'],
        }).toList();
        
        // Save to SecureStorage
        await SecureStorage.saveAllChats(chatsData);
        
        // Migrate messages for each chat
        for (var chatData in chatsData) {
          final chatId = chatData['id'];
          final String? msgsJson = prefs.getString('messages_$chatId');
          
          if (msgsJson != null) {
            final List<dynamic> decodedMsgs = jsonDecode(msgsJson);
            final messagesData = decodedMsgs.map((json) => {
              'id': json['id'],
              'content': json['content'],
              'sender': json['sender'],
              'timestamp': json['timestamp'],
              'translation': json['translation'],
              'grammarAnalysis': json['grammarAnalysis'],
            }).toList();
            
            await SecureStorage.saveChatHistory(chatId.toString(), messagesData);
            
            // Delete from SharedPreferences after successful migration
            await prefs.remove('messages_$chatId');
          }
        }
        
        // Delete old chat data from SharedPreferences
        await prefs.remove('chats');
        
        // Mark migration as complete
        await prefs.setBool('chat_migration_complete', true);
        print('✅ CHAT_PROVIDER: Migration completed successfully');
      } else {
        // No data to migrate, just mark as complete
        await prefs.setBool('chat_migration_complete', true);
        print('ℹ️ CHAT_PROVIDER: No data to migrate');
      }
    } catch (e) {
      print('⚠️ CHAT_PROVIDER: Migration failed - $e');
      // Don't set migration_complete flag so it will retry next time
      // This allows fallback to old storage if migration fails
    }
  }

  /// Fallback method to load from SharedPreferences if SecureStorage fails
  Future<void> _loadFromSharedPreferences() async {
    try {
      print('🔄 CHAT_PROVIDER: Loading from SharedPreferences (fallback)...');
      final prefs = await SharedPreferences.getInstance();
      
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
        
        // Load messages
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
      } else {
        _chats = [];
      }
    } catch (e) {
      print('⚠️ CHAT_PROVIDER: Fallback load failed - $e');
      _chats = [];
    }
  }
}
