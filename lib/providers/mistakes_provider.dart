import 'dart:async';

import 'package:flutter/foundation.dart';
import '../constants/app_runtime_config.dart';
import '../constants/sample_mistakes.dart';
import '../models/models.dart';
import '../utils/secure_storage.dart';

class MistakesProvider extends ChangeNotifier {
  final List<Mistake> _mistakes = [];
  bool _isLoaded = false;

  /// Emitted whenever a new mistake is recorded, so VocabProvider can turn it
  /// into a review item without every call site having to know about SRS.
  /// Mirrors UserProvider.onReward / CharacterProvider.subscribeToRewards.
  final StreamController<Mistake> _mistakeController =
      StreamController<Mistake>.broadcast();
  Stream<Mistake> get onMistake => _mistakeController.stream;

  List<Mistake> get mistakes => List.unmodifiable(_mistakes);

  @override
  void dispose() {
    _mistakeController.close();
    super.dispose();
  }

  /// Load mistakes from SecureStorage
  Future<void> loadMistakes() async {
    if (_isLoaded) return;

    try {
      final mistakesData = await SecureStorage.readMistakes();
      if (mistakesData != null && mistakesData.isNotEmpty) {
        _mistakes.clear();
        _mistakes.addAll(
          mistakesData.map((json) => Mistake.fromJson(json)).toList(),
        );
        debugPrint('✅ MISTAKES: Loaded ${_mistakes.length} mistakes from SecureStorage');
      }
      if (AppRuntimeConfig.sampleMistakes) _addSamples();

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ MISTAKES: Failed to load mistakes - $e');
      // Even on error, mark as loaded to prevent infinite retry loops
      _isLoaded = true;
    }
  }

  void _addSamples() {
    for (final sample in kSampleMistakes) {
      if (!_mistakes.any((m) => m.id == sample.id)) _mistakes.add(sample);
    }
  }

  /// Save mistakes to SecureStorage
  Future<void> _saveMistakes() async {
    try {
      // Samples are only ever shown, never kept.
      final mistakesData = _mistakes
          .where((m) => !m.id.startsWith(kSampleMistakeIdPrefix))
          .map((m) => m.toJson())
          .toList();
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
    _mistakeController.add(mistake);
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
