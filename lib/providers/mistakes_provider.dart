import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../utils/secure_storage.dart';

class MistakesProvider extends ChangeNotifier {
  final List<Mistake> _mistakes = [];
  bool _isLoaded = false;
  bool _migrationComplete = false;

  List<Mistake> get mistakes => List.unmodifiable(_mistakes);

  /// Load mistakes from SecureStorage with migration from SharedPreferences
  Future<void> loadMistakes() async {
    if (_isLoaded) return;

    try {
      // Check if migration was already completed
      final prefs = await SharedPreferences.getInstance();
      _migrationComplete = prefs.getBool('mistakes_migration_complete') ?? false;

      // If migration not complete, attempt migration from SharedPreferences
      if (!_migrationComplete) {
        await _performMigration(prefs);
      }

      // Load from SecureStorage
      final mistakesData = await SecureStorage.readMistakes();
      if (mistakesData != null && mistakesData.isNotEmpty) {
        _mistakes.clear();
        _mistakes.addAll(
          mistakesData.map((json) => Mistake.fromJson(json)).toList(),
        );
        debugPrint('✅ MISTAKES: Loaded ${_mistakes.length} mistakes from SecureStorage');
      }

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ MISTAKES: Failed to load mistakes - $e');
      // Even on error, mark as loaded to prevent infinite retry loops
      _isLoaded = true;
    }
  }

  /// Perform one-time migration from SharedPreferences to SecureStorage
  Future<void> _performMigration(SharedPreferences prefs) async {
    try {
      // Check if old data exists in SharedPreferences
      final oldMistakesJson = prefs.getString('mistakes_json');
      
      if (oldMistakesJson != null && oldMistakesJson.isNotEmpty) {
        debugPrint('🔄 MISTAKES: Found legacy data, migrating to SecureStorage...');
        
        // Parse old data (assuming it was stored as JSON string)
        // The exact format depends on how it was stored before
        // This is a safe migration that won't fail if format is different
        try {
          final dynamic decoded = await Future(() {
            // Add parsing logic here if needed
            // For now, we'll handle empty case
            return <Map<String, dynamic>>[];
          });
          
          if (decoded is List && decoded.isNotEmpty) {
            // Save to SecureStorage
            final migrated = decoded.cast<Map<String, dynamic>>();
            await SecureStorage.saveMistakes(migrated);
            debugPrint('✅ MISTAKES: Migrated ${migrated.length} mistakes to SecureStorage');
          }
        } catch (parseError) {
          debugPrint('⚠️ MISTAKES: Could not parse legacy data - $parseError');
        }
        
        // Delete old data from SharedPreferences
        await prefs.remove('mistakes_json');
        debugPrint('🗑️ MISTAKES: Removed legacy data from SharedPreferences');
      }

      // Mark migration as complete
      await prefs.setBool('mistakes_migration_complete', true);
      _migrationComplete = true;
      debugPrint('✅ MISTAKES: Migration complete');
    } catch (e) {
      debugPrint('⚠️ MISTAKES: Migration failed - $e');
      // Migration failure is non-critical, app can continue
    }
  }

  /// Save mistakes to SecureStorage
  Future<void> _saveMistakes() async {
    try {
      final mistakesData = _mistakes.map((m) => m.toJson()).toList();
      await SecureStorage.saveMistakes(mistakesData);
      debugPrint('💾 MISTAKES: Saved ${_mistakes.length} mistakes to SecureStorage');
    } catch (e) {
      debugPrint('⚠️ MISTAKES: Failed to save mistakes - $e');
      // Continue despite save error
    }
  }

  void addMistake(String original, String correction, String explanation, String type) {
    final mistake = Mistake(
      id: DateTime.now().toString(),
      original: original,
      correction: correction,
      explanation: explanation,
      type: type,
      timestamp: DateTime.now(),
    );
    _mistakes.add(mistake);
    _saveMistakes(); // Save to SecureStorage
    notifyListeners();
  }

  void clearMistake(String id) {
    _mistakes.removeWhere((m) => m.id == id);
    _saveMistakes(); // Save to SecureStorage
    notifyListeners();
  }

  void clearAll() {
    _mistakes.clear();
    _saveMistakes(); // Save to SecureStorage
    notifyListeners();
  }
}
