import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/providers/chat_provider.dart';
import 'package:mojilearner_flutter/models/models.dart';
import 'package:mojilearner_flutter/utils/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SecureStorage.deleteAll();
  });

  group('ChatProvider', () {
    test('should start with empty chats when no persisted data', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      
      // Act
      final provider = ChatProvider();
      await provider.loadFuture;
      
      // Assert
      expect(provider.chats, isEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('should load chats from SharedPreferences JSON', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'chats': jsonEncode([
          {
            'id': 'chat_1',
            'title': 'Test Chat',
            'createdAt': '2026-02-11T12:00:00.000',
            'type': 'free_chat',
          },
        ]),
      });
      
      // Act
      final provider = ChatProvider();
      await provider.loadFuture;
      
      // Assert
      expect(provider.chats.length, equals(1));
      expect(provider.chats[0].title, equals('Test Chat'));
      expect(provider.chats[0].id, equals('chat_1'));
      expect(provider.chats[0].type, equals('free_chat'));
    });

    test('should load messages for each chat', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'chats': jsonEncode([
          {
            'id': 'chat_1',
            'title': 'Test Chat',
            'createdAt': '2026-02-11T12:00:00.000',
            'type': 'free_chat',
          },
        ]),
        'messages_chat_1': jsonEncode([
          {
            'id': 'msg_1',
            'content': 'Hello',
            'sender': 'user',
            'timestamp': '2026-02-11T12:00:00.000',
          },
          {
            'id': 'msg_2',
            'content': 'Hi there!',
            'sender': 'ai',
            'timestamp': '2026-02-11T12:01:00.000',
          },
        ]),
      });
      
      // Act
      final provider = ChatProvider();
      await provider.loadFuture;
      
      // Assert
      final messages = provider.getMessages('chat_1');
      expect(messages.length, equals(2));
      expect(messages[0].content, equals('Hello'));
      expect(messages[1].content, equals('Hi there!'));
    });

    test('should create new chat and persist', () async {
      // Arrange
      final provider = ChatProvider();
      await provider.loadFuture;
      
      // Act
      await provider.createNewChat(title: 'New Chat', type: 'lesson');
      
      // Assert
      expect(provider.chats.length, equals(1));
      expect(provider.chats[0].title, equals('New Chat'));
      expect(provider.chats[0].type, equals('lesson'));
      
      final saved = await SecureStorage.readAllChats();
      expect(saved, isNotNull);
      expect(saved![0]['title'], equals('New Chat'));
    });

    test('should add message to chat and persist', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'chats': jsonEncode([
          {
            'id': 'chat_1',
            'title': 'Test Chat',
            'createdAt': '2026-02-11T12:00:00.000',
            'type': 'free_chat',
          },
        ]),
      });
      final provider = ChatProvider();
      await provider.loadFuture;
      
      // Act
      final message = Message(
        id: 'msg_new',
        content: 'New message',
        sender: 'user',
        timestamp: DateTime(2026, 2, 11, 12, 30),
      );
      await provider.addMessage('chat_1', message);
      
      // Assert
      final messages = provider.getMessages('chat_1');
      expect(messages.length, equals(1));
      expect(messages[0].content, equals('New message'));
      
      final saved = await SecureStorage.readChatHistory('chat_1');
      expect(saved, isNotNull);
      expect(saved![0]['content'], equals('New message'));
    });

    test('should update last message in chat when adding message', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'chats': jsonEncode([
          {
            'id': 'chat_1',
            'title': 'Test Chat',
            'createdAt': '2026-02-11T12:00:00.000',
            'type': 'free_chat',
          },
        ]),
      });
      final provider = ChatProvider();
      await provider.loadFuture;
      
      final message = Message(
        id: 'msg_1',
        content: 'Latest message',
        sender: 'user',
        timestamp: DateTime(2026, 2, 11, 12, 30),
      );
      
      // Act
      await provider.addMessage('chat_1', message);
      
      // Assert
      expect(provider.chats[0].lastMessage?.content, equals('Latest message'));
    });

    test('should sort chats by most recent message timestamp', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'chats': jsonEncode([
          {
            'id': 'chat_old',
            'title': 'Old Chat',
            'createdAt': '2026-02-09T12:00:00.000',
            'type': 'free_chat',
          },
          {
            'id': 'chat_new',
            'title': 'New Chat',
            'createdAt': '2026-02-11T12:00:00.000',
            'type': 'free_chat',
          },
        ]),
      });
      
      // Act
      final provider = ChatProvider();
      await provider.loadFuture;
      
      // Assert
      expect(provider.chats[0].id, equals('chat_new'));
      expect(provider.chats[1].id, equals('chat_old'));
    });

  });
}
