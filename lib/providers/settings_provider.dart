import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  bool _usePixelFont = true;

  bool get usePixelFont => _usePixelFont;

  void togglePixelFont(bool value) {
    _usePixelFont = value;
    notifyListeners();
  }
}
