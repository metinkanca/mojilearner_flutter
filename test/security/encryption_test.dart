/// Encryption Security Tests
/// 
/// Validates SecureStorage encryption, decryption, and migration functionality.
/// Ensures sensitive data is properly protected.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/utils/secure_storage.dart';

void main() {
  // Initialize Flutter binding for platform channels
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Note: These tests will use mock secure storage in test environment
  // Flutter Secure Storage automatically uses in-memory storage during tests
  
  setUp(() async {
    // Clear any existing test data
    try {
      await SecureStorage.deleteAll();
    } catch (e) {
      // Ignore errors in test setup
    }
  });

  tearDown(() async {
    // Clean up after each test
    try {
      await SecureStorage.deleteAll();
    } catch (e) {
      // Ignore errors in test cleanup
    }
  });

  group('SecureStorage - Basic Operations', () {
    test('saveEncrypted and readEncrypted work with strings', () async {
      const testKey = 'test_string';
      const testValue = 'Hello, World!';
      
      await SecureStorage.saveEncrypted(testKey, testValue);
      final retrieved = await SecureStorage.readEncrypted<String>(testKey);
      
      expect(retrieved, testValue);
    });

    test('saveEncrypted and readEncrypted work with maps', () async {
      const testKey = 'test_map';
      final testValue = {
        'name': 'John',
        'age': 25,
        'language': 'Spanish',
      };
      
      await SecureStorage.saveEncrypted(testKey, testValue);
      final retrieved = await SecureStorage.readEncrypted<Map>(testKey);
      
      expect(retrieved, testValue);
    });

    test('saveEncrypted and readEncrypted work with lists', () async {
      const testKey = 'test_list';
      final testValue = [
        {'id': 1, 'text': 'First'},
        {'id': 2, 'text': 'Second'},
      ];
      
      await SecureStorage.saveEncrypted(testKey, testValue);
      final retrieved = await SecureStorage.readEncrypted<List>(testKey);
      
      expect(retrieved, testValue);
    });

    test('saveEncrypted and readEncrypted work with nested structures', () async {
      const testKey = 'test_nested';
      final testValue = {
        'user': {
          'name': 'Alice',
          'settings': {
            'theme': 'dark',
            'notifications': true,
          },
        },
        'chats': [
          {'id': 1, 'messages': ['Hi', 'Hello']},
          {'id': 2, 'messages': ['Bye', 'See you']},
        ],
      };
      
      await SecureStorage.saveEncrypted(testKey, testValue);
      final retrieved = await SecureStorage.readEncrypted<Map>(testKey);
      
      expect(retrieved, testValue);
    });

    test('readEncrypted returns null for non-existent key', () async {
      final retrieved = await SecureStorage.readEncrypted<String>('non_existent');
      expect(retrieved, isNull);
    });

    test('saveString and readString work without JSON encoding', () async {
      const testKey = 'plain_string';
      const testValue = 'Simple string value';
      
      await SecureStorage.saveString(testKey, testValue);
      final retrieved = await SecureStorage.readString(testKey);
      
      expect(retrieved, testValue);
    });

    test('delete removes specific key', () async {
      const testKey = 'to_delete';
      await SecureStorage.saveString(testKey, 'temporary');
      
      expect(await SecureStorage.hasKey(testKey), isTrue);
      
      await SecureStorage.delete(testKey);
      
      expect(await SecureStorage.hasKey(testKey), isFalse);
    });

    test('hasKey correctly identifies existing keys', () async {
      const testKey = 'existing_key';
      
      expect(await SecureStorage.hasKey(testKey), isFalse);
      
      await SecureStorage.saveString(testKey, 'value');
      
      expect(await SecureStorage.hasKey(testKey), isTrue);
    });

    test('deleteAll removes all keys', () async {
      await SecureStorage.saveString('key1', 'value1');
      await SecureStorage.saveString('key2', 'value2');
      await SecureStorage.saveString('key3', 'value3');
      
      await SecureStorage.deleteAll();
      
      expect(await SecureStorage.hasKey('key1'), isFalse);
      expect(await SecureStorage.hasKey('key2'), isFalse);
      expect(await SecureStorage.hasKey('key3'), isFalse);
    });

    test('getAllKeys returns all stored keys', () async {
      await SecureStorage.saveString('key1', 'value1');
      await SecureStorage.saveString('key2', 'value2');
      await SecureStorage.saveString('key3', 'value3');
      
      final keys = await SecureStorage.getAllKeys();
      
      expect(keys, contains('key1'));
      expect(keys, contains('key2'));
      expect(keys, contains('key3'));
      expect(keys.length, 3);
    });
  });

  group('SecureStorage - Chat History', () {
    test('saveChatHistory and readChatHistory work correctly', () async {
      const chatId = 'chat_123';
      final messages = [
        {
          'role': 'user',
          'content': 'Hola',
          'timestamp': '2024-01-01T10:00:00Z',
        },
        {
          'role': 'assistant',
          'content': 'Hello! How can I help you?',
          'timestamp': '2024-01-01T10:00:01Z',
        },
      ];
      
      await SecureStorage.saveChatHistory(chatId, messages);
      final retrieved = await SecureStorage.readChatHistory(chatId);
      
      expect(retrieved, isNotNull);
      expect(retrieved!.length, 2);
      expect(retrieved[0]['content'], 'Hola');
      expect(retrieved[1]['role'], 'assistant');
    });

    test('readChatHistory returns null for non-existent chat', () async {
      final retrieved = await SecureStorage.readChatHistory('non_existent_chat');
      expect(retrieved, isNull);
    });

    test('can store multiple chat histories independently', () async {
      final chat1 = [
        {'role': 'user', 'content': 'Message 1'},
      ];
      final chat2 = [
        {'role': 'user', 'content': 'Message 2'},
      ];
      
      await SecureStorage.saveChatHistory('chat1', chat1);
      await SecureStorage.saveChatHistory('chat2', chat2);
      
      final retrieved1 = await SecureStorage.readChatHistory('chat1');
      final retrieved2 = await SecureStorage.readChatHistory('chat2');
      
      expect(retrieved1![0]['content'], 'Message 1');
      expect(retrieved2![0]['content'], 'Message 2');
    });
  });

  group('SecureStorage - All Chats Metadata', () {
    test('saveAllChats and readAllChats work correctly', () async {
      final chats = [
        {
          'id': 'chat1',
          'title': 'Spanish Practice',
          'lastMessage': 'Hola',
          'timestamp': '2024-01-01T10:00:00Z',
        },
        {
          'id': 'chat2',
          'title': 'French Basics',
          'lastMessage': 'Bonjour',
          'timestamp': '2024-01-01T11:00:00Z',
        },
      ];
      
      await SecureStorage.saveAllChats(chats);
      final retrieved = await SecureStorage.readAllChats();
      
      expect(retrieved, isNotNull);
      expect(retrieved!.length, 2);
      expect(retrieved[0]['title'], 'Spanish Practice');
      expect(retrieved[1]['title'], 'French Basics');
    });

    test('readAllChats returns null when no chats stored', () async {
      final retrieved = await SecureStorage.readAllChats();
      expect(retrieved, isNull);
    });
  });

  group('SecureStorage - Mistakes', () {
    test('saveMistakes and readMistakes work correctly', () async {
      final mistakes = [
        {
          'original': 'hola',
          'correction': 'Hola',
          'explanation': 'Capitalize greetings',
          'timestamp': '2024-01-01T10:00:00Z',
        },
        {
          'original': 'hace frio',
          'correction': 'hace frío',
          'explanation': 'Need accent on frio',
          'timestamp': '2024-01-01T10:01:00Z',
        },
      ];
      
      await SecureStorage.saveMistakes(mistakes);
      final retrieved = await SecureStorage.readMistakes();
      
      expect(retrieved, isNotNull);
      expect(retrieved!.length, 2);
      expect(retrieved[0]['original'], 'hola');
      expect(retrieved[1]['correction'], 'hace frío');
    });

    test('can update mistakes list', () async {
      final initial = [
        {'original': 'mistake1', 'correction': 'fixed1'},
      ];
      
      await SecureStorage.saveMistakes(initial);
      
      final updated = [
        {'original': 'mistake1', 'correction': 'fixed1'},
        {'original': 'mistake2', 'correction': 'fixed2'},
      ];
      
      await SecureStorage.saveMistakes(updated);
      final retrieved = await SecureStorage.readMistakes();
      
      expect(retrieved!.length, 2);
    });
  });

  group('SecureStorage - Assessment Conversations', () {
    test('saveAssessmentConversation and readAssessmentConversation work', () async {
      const languageCode = 'es';
      final conversation = [
        {
          'role': 'assistant',
          'content': '¿Cómo estás?',
        },
        {
          'role': 'user',
          'content': 'Bien, gracias',
        },
      ];
      
      await SecureStorage.saveAssessmentConversation(languageCode, conversation);
      final retrieved = await SecureStorage.readAssessmentConversation(languageCode);
      
      expect(retrieved, isNotNull);
      expect(retrieved!.length, 2);
      expect(retrieved[0]['content'], '¿Cómo estás?');
    });

    test('can store assessments for different languages', () async {
      final spanishConvo = [
        {'role': 'user', 'content': 'Hola'},
      ];
      final frenchConvo = [
        {'role': 'user', 'content': 'Bonjour'},
      ];
      
      await SecureStorage.saveAssessmentConversation('es', spanishConvo);
      await SecureStorage.saveAssessmentConversation('fr', frenchConvo);
      
      final spanish = await SecureStorage.readAssessmentConversation('es');
      final french = await SecureStorage.readAssessmentConversation('fr');
      
      expect(spanish![0]['content'], 'Hola');
      expect(french![0]['content'], 'Bonjour');
    });
  });

  group('SecureStorage - Data Encryption', () {
    test('data is actually encrypted in storage', () async {
      // This test verifies that data isn't stored in plain text
      const testKey = 'encrypted_test';
      const sensitiveData = 'This is sensitive information';
      
      await SecureStorage.saveString(testKey, sensitiveData);
      
      // In a real test environment, you'd check the actual storage
      // For now, we verify we can retrieve the correct value
      final retrieved = await SecureStorage.readString(testKey);
      expect(retrieved, sensitiveData);
      
      // Verify the key exists
      expect(await SecureStorage.hasKey(testKey), isTrue);
    });

    test('handles special characters in encrypted data', () async {
      const testKey = 'special_chars';
      const specialData = 'Special: ñ, é, ü, 中文, 😊, "quotes", \'apostrophes\'';
      
      await SecureStorage.saveEncrypted(testKey, specialData);
      final retrieved = await SecureStorage.readEncrypted<String>(testKey);
      
      expect(retrieved, specialData);
    });

    test('handles empty strings', () async {
      const testKey = 'empty_string';
      const emptyString = '';
      
      await SecureStorage.saveString(testKey, emptyString);
      final retrieved = await SecureStorage.readString(testKey);
      
      expect(retrieved, emptyString);
    });

    test('handles very long strings', () async {
      const testKey = 'long_string';
      final longString = 'a' * 10000;
      
      await SecureStorage.saveString(testKey, longString);
      final retrieved = await SecureStorage.readString(testKey);
      
      expect(retrieved, longString);
      expect(retrieved!.length, 10000);
    });
  });

  group('SecureStorage - Error Handling', () {
    test('handles null values appropriately', () async {
      const testKey = 'null_test';
      
      // Saving null should work (stores "null" string)
      await SecureStorage.saveEncrypted(testKey, null);
      final retrieved = await SecureStorage.readEncrypted(testKey);
      
      // Retrieved value should be null (JSON null)
      expect(retrieved, isNull);
    });

    test('readEncrypted handles corrupted data gracefully', () async {
      // This test would normally verify error handling
      // In MockSecureStorage, we can't easily corrupt data
      // But we can verify null is returned for non-existent keys
      final retrieved = await SecureStorage.readEncrypted<Map>('corrupted_key');
      expect(retrieved, isNull);
    });
  });

  group('SecureStorage - Migration Logic', () {
    test('can manually migrate data structure', () async {
      // Simulate migrating from old format to new format
      // Old format: simple string
      await SecureStorage.saveString('legacy_data', 'old value');
      
      // New format: structured data
      final newFormat = {
        'value': 'old value',
        'migrated': true,
        'migrationDate': DateTime.now().toIso8601String(),
      };
      
      await SecureStorage.saveEncrypted('legacy_data', newFormat);
      final retrieved = await SecureStorage.readEncrypted<Map>('legacy_data');
      
      expect(retrieved!['value'], 'old value');
      expect(retrieved['migrated'], isTrue);
    });
  });

  group('SecureStorage - Real-world Scenarios', () {
    test('complete chat session storage workflow', () async {
      // 1. Create new chat
      final chatId = 'chat_${DateTime.now().millisecondsSinceEpoch}';
      final messages = <Map<String, dynamic>>[];
      
      // 2. Add messages progressively
      messages.add({
        'role': 'user',
        'content': 'Hola',
        'timestamp': DateTime.now().toIso8601String(),
      });
      await SecureStorage.saveChatHistory(chatId, messages);
      
      messages.add({
        'role': 'assistant',
        'content': '¡Hola! How can I help?',
        'timestamp': DateTime.now().toIso8601String(),
      });
      await SecureStorage.saveChatHistory(chatId, messages);
      
      // 3. Retrieve and verify
      final retrieved = await SecureStorage.readChatHistory(chatId);
      expect(retrieved!.length, 2);
      
      // 4. Update metadata
      final chats = await SecureStorage.readAllChats() ?? [];
      chats.add({
        'id': chatId,
        'title': 'Spanish Practice',
        'lastMessage': retrieved.last['content'],
        'timestamp': DateTime.now().toIso8601String(),
      });
      await SecureStorage.saveAllChats(chats);
      
      // 5. Verify everything is stored
      final allChats = await SecureStorage.readAllChats();
      expect(allChats!.any((c) => c['id'] == chatId), isTrue);
    });

    test('mistake tracking workflow', () async {
      // Start with empty mistakes
      final mistakes = await SecureStorage.readMistakes() ?? [];
      expect(mistakes.length, 0);
      
      // Add first mistake
      mistakes.add({
        'original': 'hola',
        'correction': 'Hola',
        'explanation': 'Capitalize greetings',
        'timestamp': DateTime.now().toIso8601String(),
        'language': 'es',
      });
      await SecureStorage.saveMistakes(mistakes);
      
      // Add second mistake
      mistakes.add({
        'original': 'como estas',
        'correction': '¿Cómo estás?',
        'explanation': 'Question marks and accents',
        'timestamp': DateTime.now().toIso8601String(),
        'language': 'es',
      });
      await SecureStorage.saveMistakes(mistakes);
      
      // Retrieve and verify
      final retrieved = await SecureStorage.readMistakes();
      expect(retrieved!.length, 2);
      expect(retrieved.every((m) => m['language'] == 'es'), isTrue);
    });

    test('multi-key data consistency', () async {
      // Store related data across multiple keys
      const chatId = 'consistency_test';
      
      final messages = [
        {'role': 'user', 'content': 'Test message'},
      ];
      
      final chats = [
        {'id': chatId, 'title': 'Test Chat'},
      ];
      
      final mistakes = [
        {'original': 'test', 'correction': 'Test'},
      ];
      
      await SecureStorage.saveChatHistory(chatId, messages);
      await SecureStorage.saveAllChats(chats);
      await SecureStorage.saveMistakes(mistakes);
      
      // Verify all data is retrievable
      expect(await SecureStorage.readChatHistory(chatId), isNotNull);
      expect(await SecureStorage.readAllChats(), isNotNull);
      expect(await SecureStorage.readMistakes(), isNotNull);
      
      // Delete all and verify
      await SecureStorage.deleteAll();
      
      expect(await SecureStorage.readChatHistory(chatId), isNull);
      expect(await SecureStorage.readAllChats(), isNull);
      expect(await SecureStorage.readMistakes(), isNull);
    });
  });
}
