import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/language_names.dart';

// Simple model for Language
class Language {
  final String code;

  /// The English name, which is what the tutor prompts are written with.
  /// Never show this in the UI — see [nativeName].
  final String name;

  const Language({required this.code, required this.name});

  /// What the language calls itself, for anything a player reads.
  ///
  /// Looked up by code rather than stored on the instance so a Language
  /// rebuilt anywhere — restored from prefs, constructed in a test — still
  /// shows the right name.
  String get nativeName => languageEndonyms[code] ?? name;
}

class LanguageProvider extends ChangeNotifier {
  Language _nativeLanguage = const Language(code: 'en', name: 'English');
  // Default to Spanish for immediate app usage
  Language? _targetLanguage = const Language(code: 'es', name: 'Spanish');
  bool _isLoading = true;

  Language get nativeLanguage => _nativeLanguage;
  Language? get targetLanguage => _targetLanguage;
  bool get isLoading => _isLoading;

  bool get hasSelectedLanguages => _targetLanguage != null;

  LanguageProvider() {
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    final prefs = await SharedPreferences.getInstance();
    final nativeCode = prefs.getString('native_language_code');
    final targetCode = prefs.getString('target_language_code');

    if (nativeCode != null) {
      final found = availableLanguages.where((l) => l.code == nativeCode);
      if (found.isNotEmpty) {
        _nativeLanguage = found.first;
      }
    }

    if (targetCode != null) {
      final found = availableLanguages.where((l) => l.code == targetCode);
      if (found.isNotEmpty) {
        _targetLanguage = found.first;
      }
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setNativeLanguage(Language lang) async {
    _nativeLanguage = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('native_language_code', lang.code);
  }

  Future<void> setTargetLanguage(Language lang) async {
    _targetLanguage = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('target_language_code', lang.code);
  }
  
  // Helper to get available languages
  List<Language> get availableLanguages => const [
    Language(code: 'en', name: 'English'),
    Language(code: 'es', name: 'Spanish'),
    Language(code: 'fr', name: 'French'),
    Language(code: 'de', name: 'German'),
    Language(code: 'it', name: 'Italian'),
    Language(code: 'pt', name: 'Portuguese'),
    Language(code: 'ru', name: 'Russian'),
    Language(code: 'ja', name: 'Japanese'),
    Language(code: 'zh', name: 'Chinese'),
    Language(code: 'ko', name: 'Korean'),
    Language(code: 'ar', name: 'Arabic'),
    Language(code: 'hi', name: 'Hindi'),
    Language(code: 'tr', name: 'Turkish'),
    Language(code: 'nl', name: 'Dutch'),
    Language(code: 'sv', name: 'Swedish'),
    Language(code: 'pl', name: 'Polish'),
    Language(code: 'id', name: 'Indonesian'),
    Language(code: 'vi', name: 'Vietnamese'),
    Language(code: 'th', name: 'Thai'),
    Language(code: 'el', name: 'Greek'),
    Language(code: 'uk', name: 'Ukrainian'),
    Language(code: 'da', name: 'Danish'),
    Language(code: 'fi', name: 'Finnish'),
    Language(code: 'no', name: 'Norwegian'),
    Language(code: 'cs', name: 'Czech'),
    Language(code: 'ro', name: 'Romanian'),
    Language(code: 'hu', name: 'Hungarian'),
  ];
}
