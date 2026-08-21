import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock SharedPreferences for testing persistence logic
/// 
/// Provides an in-memory implementation of SharedPreferences
/// that can be used in tests without actual file system access.
/// 
/// Usage:
/// ```dart
/// final prefs = FakeSharedPreferences();
/// await prefs.setInt('coins', 100);
/// final coins = prefs.getInt('coins'); // 100
/// ```
class FakeSharedPreferences extends Fake implements SharedPreferences {
  final Map<String, Object> _store = {};
  
  @override
  Future<bool> setInt(String key, int value) async {
    _store[key] = value;
    return true;
  }
  
  @override
  int? getInt(String key) {
    return _store[key] as int?;
  }
  
  @override
  Future<bool> setString(String key, String value) async {
    _store[key] = value;
    return true;
  }
  
  @override
  String? getString(String key) {
    return _store[key] as String?;
  }
  
  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _store[key] = value;
    return true;
  }
  
  @override
  List<String>? getStringList(String key) {
    return _store[key] as List<String>?;
  }
  
  @override
  Future<bool> setBool(String key, bool value) async {
    _store[key] = value;
    return true;
  }
  
  @override
  bool? getBool(String key) {
    return _store[key] as bool?;
  }
  
  @override
  Future<bool> setDouble(String key, double value) async {
    _store[key] = value;
    return true;
  }
  
  @override
  double? getDouble(String key) {
    return _store[key] as double?;
  }
  
  @override
  Future<bool> remove(String key) async {
    _store.remove(key);
    return true;
  }
  
  @override
  Future<bool> clear() async {
    _store.clear();
    return true;
  }
  
  @override
  Set<String> getKeys() {
    return _store.keys.toSet();
  }
  
  @override
  bool containsKey(String key) {
    return _store.containsKey(key);
  }
  
  @override
  Object? get(String key) {
    return _store[key];
  }
  
  /// Helper to pre-populate the store for testing
  void populate(Map<String, Object> data) {
    _store.addAll(data);
  }
  
  /// Helper to verify stored values in tests
  Map<String, Object> getAll() {
    return Map.from(_store);
  }
}

/// Mock for testing SharedPreferences.getInstance()
class MockSharedPreferences extends Mock implements SharedPreferences {}
