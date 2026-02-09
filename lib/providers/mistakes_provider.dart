import 'package:flutter/foundation.dart';
import '../models/models.dart';

class MistakesProvider extends ChangeNotifier {
  final List<Mistake> _mistakes = [];

  List<Mistake> get mistakes => List.unmodifiable(_mistakes);

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
    notifyListeners();
  }

  void clearMistake(String id) {
    _mistakes.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  void clearAll() {
    _mistakes.clear();
    notifyListeners();
  }
}
