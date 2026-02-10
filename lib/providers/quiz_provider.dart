import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizProvider extends ChangeNotifier {
  int? _savedQuestionIndex;
  int? _savedScore;
  bool _hasSavedProgress = false;

  int? get savedQuestionIndex => _savedQuestionIndex;
  int? get savedScore => _savedScore;
  bool get hasSavedProgress => _hasSavedProgress;

  QuizProvider() {
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    _savedQuestionIndex = prefs.getInt('quiz_saved_index');
    _savedScore = prefs.getInt('quiz_saved_score');
    
    if (_savedQuestionIndex != null && _savedScore != null) {
      _hasSavedProgress = true;
    } else {
      _hasSavedProgress = false;
    }
    notifyListeners();
  }

  Future<void> saveProgress(int index, int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quiz_saved_index', index);
    await prefs.setInt('quiz_saved_score', score);
    
    _savedQuestionIndex = index;
    _savedScore = score;
    _hasSavedProgress = true;
    notifyListeners();
  }

  Future<void> clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('quiz_saved_index');
    await prefs.remove('quiz_saved_score');
    
    _savedQuestionIndex = null;
    _savedScore = null;
    _hasSavedProgress = false;
    notifyListeners();
  }
}
