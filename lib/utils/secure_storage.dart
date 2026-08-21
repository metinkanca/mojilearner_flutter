/// Secure Storage Wrapper
/// 
/// Provides encrypted storage for sensitive data using flutter_secure_storage.
/// Use this for chat history, mistakes, API keys, and other sensitive information.
/// Use SharedPreferences for non-sensitive data like UI preferences.
/// 
/// Usage:
/// ```dart
/// // Save encrypted data
/// await SecureStorage.saveEncrypted('chat_history', chatData);
/// 
/// // Read encrypted data
/// final chatData = await SecureStorage.readEncrypted<List>('chat_history');
/// 
/// // Check if key exists
/// final hasData = await SecureStorage.hasKey('chat_history');
/// ```
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class SecureStorage {
  // Private constructor to prevent instantiation
  SecureStorage._();

  // Singleton instance with encryption options
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      // Additional security: require authentication to access
      // screenshotProtection: true, // Android 13+
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      // Additional security: require device authentication
      // accessGroup: 'com.mimikin.app', // For sharing between apps
    ),
  );

  // In-memory fallback used in test environments where the plugin channel
  // is not registered (MissingPluginException).
  static final Map<String, String> _memoryStore = <String, String>{};

  /// Save encrypted data
  /// 
  /// Converts any data type to JSON and encrypts it
  static Future<void> saveEncrypted(String key, dynamic value) async {
    try {
      final jsonString = json.encode(value);
      await _storage.write(key: key, value: jsonString);
    } on MissingPluginException {
      final jsonString = json.encode(value);
      _memoryStore[key] = jsonString;
    } catch (e) {
      debugPrint('⚠️ SECURE STORAGE: Failed to save $key - $e');
      rethrow;
    }
  }

  /// Read encrypted data
  /// 
  /// Returns decrypted data of specified type, null if not found
  static Future<T?> readEncrypted<T>(String key) async {
    try {
      final jsonString = await _storage.read(key: key);
      if (jsonString == null) return null;
      return json.decode(jsonString) as T;
    } on MissingPluginException {
      final jsonString = _memoryStore[key];
      if (jsonString == null) return null;
      return json.decode(jsonString) as T;
    } catch (e) {
      debugPrint('⚠️ SECURE STORAGE: Failed to read $key - $e');
      return null;
    }
  }

  /// Save string directly (without JSON encoding)
  /// 
  /// Use for simple string values like API keys
  static Future<void> saveString(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } on MissingPluginException {
      _memoryStore[key] = value;
    } catch (e) {
      debugPrint('⚠️ SECURE STORAGE: Failed to save string $key - $e');
      rethrow;
    }
  }

  /// Read string directly (without JSON decoding)
  /// 
  /// Returns decrypted string or null if not found
  static Future<String?> readString(String key) async {
    try {
      return await _storage.read(key: key);
    } on MissingPluginException {
      return _memoryStore[key];
    } catch (e) {
      debugPrint('⚠️ SECURE STORAGE: Failed to read string $key - $e');
      return null;
    }
  }

  /// Delete a specific key
  static Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } on MissingPluginException {
      _memoryStore.remove(key);
    } catch (e) {
      debugPrint('⚠️ SECURE STORAGE: Failed to delete $key - $e');
      rethrow;
    }
  }

  /// Check if a key exists
  static Future<bool> hasKey(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value != null;
    } on MissingPluginException {
      return _memoryStore.containsKey(key);
    } catch (e) {
      debugPrint('⚠️ SECURE STORAGE: Failed to check key $key - $e');
      return false;
    }
  }

  /// Delete all encrypted data
  /// 
  /// ⚠️ WARNING: This will permanently delete all encrypted data
  static Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } on MissingPluginException {
      _memoryStore.clear();
    } catch (e) {
      debugPrint('⚠️ SECURE STORAGE: Failed to delete all - $e');
      rethrow;
    }
  }

  /// Get all keys
  /// 
  /// Useful for debugging and data migration
  static Future<List<String>> getAllKeys() async {
    try {
      final all = await _storage.readAll();
      return all.keys.toList();
    } on MissingPluginException {
      return _memoryStore.keys.toList();
    } catch (e) {
      debugPrint('⚠️ SECURE STORAGE: Failed to get all keys - $e');
      return [];
    }
  }

  // ===== Data-Specific Helper Methods =====

  /// Save chat history (encrypted)
  static Future<void> saveChatHistory(String chatId, List<Map<String, dynamic>> messages) async {
    await saveEncrypted('chat_$chatId', messages);
  }

  /// Read chat history (encrypted)
  static Future<List<Map<String, dynamic>>?> readChatHistory(String chatId) async {
    final data = await readEncrypted<List>('chat_$chatId');
    if (data == null) return null;
    return data
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  /// Save all chats metadata (encrypted)
  static Future<void> saveAllChats(List<Map<String, dynamic>> chats) async {
    await saveEncrypted('all_chats', chats);
  }

  /// Read all chats metadata (encrypted)
  static Future<List<Map<String, dynamic>>?> readAllChats() async {
    final data = await readEncrypted<List>('all_chats');
    if (data == null) return null;
    return data
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  /// Save mistakes (encrypted)
  static Future<void> saveMistakes(List<Map<String, dynamic>> mistakes) async {
    await saveEncrypted('mistakes', mistakes);
  }

  /// Read mistakes (encrypted)
  static Future<List<Map<String, dynamic>>?> readMistakes() async {
    final data = await readEncrypted<List>('mistakes');
    if (data == null) return null;
    return data
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  /// Save spaced-repetition review items (encrypted)
  static Future<void> saveReviewItems(List<Map<String, dynamic>> items) async {
    await saveEncrypted('review_items', items);
  }

  /// Read spaced-repetition review items (encrypted)
  static Future<List<Map<String, dynamic>>?> readReviewItems() async {
    final data = await readEncrypted<List>('review_items');
    if (data == null) return null;
    return data
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  /// Save scenario quest progress (encrypted)
  static Future<void> saveScenarioProgress(
      List<Map<String, dynamic>> entries) async {
    await saveEncrypted('scenario_progress', entries);
  }

  /// Read scenario quest progress (encrypted)
  static Future<List<Map<String, dynamic>>?> readScenarioProgress() async {
    final data = await readEncrypted<List>('scenario_progress');
    if (data == null) return null;
    return data
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();
  }

  /// Save assessment conversation (encrypted)
  static Future<void> saveAssessmentConversation(String languageCode, List<Map<String, dynamic>> conversation) async {
    await saveEncrypted('assessment_$languageCode', conversation);
  }

  /// Read assessment conversation (encrypted)
  static Future<List<Map<String, dynamic>>?> readAssessmentConversation(String languageCode) async {
    final data = await readEncrypted<List>('assessment_$languageCode');
    if (data == null) return null;
    return data
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

}

/// Storage Strategy Guidelines
/// 
/// Use SecureStorage for:
/// - Chat history and messages
/// - User mistakes and corrections
/// - Assessment conversations
/// - API keys (when stored locally)
/// - Authentication tokens
/// - Personal user data
/// 
/// Use SharedPreferences for:
/// - UI preferences (theme, language)
/// - Non-sensitive app settings
/// - Feature flags
/// - Last app version
/// - Onboarding completion status
/// - Pet visual customizations
/// - XP/coins (non-critical, can be validated server-side later)
