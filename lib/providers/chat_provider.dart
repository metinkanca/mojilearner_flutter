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
        _chats = chatsData.map(Chat.fromJson).toList();
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
          _messages[chat.id] = messagesData.map(Message.fromJson).toList();
        }
      }

      _sortChats();
    } catch (e) {
      debugPrint('⚠️ CHAT_PROVIDER: Error loading chats - $e');
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
    final chatsData = _chats.map((c) => c.toJson()).toList();
    try {
      // Save to SecureStorage (encrypted)
      await SecureStorage.saveAllChats(chatsData);

      // Remove any stale plaintext copy left behind by older builds.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chats');
    } catch (e) {
      debugPrint('⚠️ CHAT_PROVIDER: Error saving chats - $e');
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('chats', jsonEncode(chatsData));
    }
  }

  Future<void> _saveMessages(String chatId) async {
    final messages = _messages[chatId];
    if (messages == null) return;
    final messagesData = messages.map((m) => m.toJson()).toList();
    try {
      await SecureStorage.saveChatHistory(chatId, messagesData);

      // Remove any stale plaintext copy left behind by older builds.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('messages_$chatId');
    } catch (e) {
      debugPrint('⚠️ CHAT_PROVIDER: Error saving messages for $chatId - $e');
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('messages_$chatId', jsonEncode(messagesData));
    }
  }

  // Get messages for a chat
  List<Message> getMessages(String chatId) {
    return _messages[chatId] ?? [];
  }

  // Create a new chat
  Future<String> createNewChat({
    String title = "New Chat",
    String type = "free_chat",
    String? scenarioId,
  }) async {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newChat = Chat(
      id: newId,
      title: title,
      createdAt: DateTime.now(),
      type: type,
      scenarioId: scenarioId,
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
      debugPrint('🔄 CHAT_PROVIDER: Starting migration to SecureStorage...');
      
      // Check if there's data to migrate in SharedPreferences
      final String? chatsJson = prefs.getString('chats');
      
      if (chatsJson != null) {
        debugPrint('🔄 CHAT_PROVIDER: Found chat data in SharedPreferences, migrating...');
        
        // Parse and normalize the chat data through the model classes.
        final List<dynamic> decoded = jsonDecode(chatsJson);
        final chatsData = decoded
            .map((json) =>
                Chat.fromJson(Map<String, dynamic>.from(json as Map)).toJson())
            .toList();

        // Save to SecureStorage
        await SecureStorage.saveAllChats(chatsData);

        // Migrate messages for each chat
        for (var chatData in chatsData) {
          final chatId = chatData['id'];
          final String? msgsJson = prefs.getString('messages_$chatId');

          if (msgsJson != null) {
            final List<dynamic> decodedMsgs = jsonDecode(msgsJson);
            final messagesData = decodedMsgs
                .map((json) =>
                    Message.fromJson(Map<String, dynamic>.from(json as Map))
                        .toJson())
                .toList();

            await SecureStorage.saveChatHistory(chatId.toString(), messagesData);
            
            // Delete from SharedPreferences after successful migration
            await prefs.remove('messages_$chatId');
          }
        }
        
        // Delete old chat data from SharedPreferences
        await prefs.remove('chats');
        
        // Mark migration as complete
        await prefs.setBool('chat_migration_complete', true);
        debugPrint('✅ CHAT_PROVIDER: Migration completed successfully');
      } else {
        // No data to migrate, just mark as complete
        await prefs.setBool('chat_migration_complete', true);
        debugPrint('ℹ️ CHAT_PROVIDER: No data to migrate');
      }
    } catch (e) {
      debugPrint('⚠️ CHAT_PROVIDER: Migration failed - $e');
      // Don't set migration_complete flag so it will retry next time
      // This allows fallback to old storage if migration fails
    }
  }

  /// Fallback method to load from SharedPreferences if SecureStorage fails
  Future<void> _loadFromSharedPreferences() async {
    try {
      debugPrint('🔄 CHAT_PROVIDER: Loading from SharedPreferences (fallback)...');
      final prefs = await SharedPreferences.getInstance();
      
      final String? chatsJson = prefs.getString('chats');
      if (chatsJson != null) {
        final List<dynamic> decoded = jsonDecode(chatsJson);
        _chats = decoded
            .map((json) => Chat.fromJson(Map<String, dynamic>.from(json as Map)))
            .toList();

        // Load messages
        for (var chat in _chats) {
          final String? msgsJson = prefs.getString('messages_${chat.id}');
          if (msgsJson != null) {
            final List<dynamic> decodedMsgs = jsonDecode(msgsJson);
            _messages[chat.id] = decodedMsgs
                .map((json) =>
                    Message.fromJson(Map<String, dynamic>.from(json as Map)))
                .toList();
          }
        }

        _sortChats();
      } else {
        _chats = [];
      }
    } catch (e) {
      debugPrint('⚠️ CHAT_PROVIDER: Fallback load failed - $e');
      _chats = [];
    }
  }
}
