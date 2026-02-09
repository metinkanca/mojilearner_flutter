import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/translations.dart';

// Simple model for Language
class Language {
  final String code;
  final String name;
  final String flag;

  const Language({required this.code, required this.name, required this.flag});
}

class LanguageProvider extends ChangeNotifier {
  Language _nativeLanguage = const Language(code: 'en', name: 'English', flag: '🇺🇸');
  // Default to Spanish for immediate app usage
  Language? _targetLanguage = const Language(code: 'es', name: 'Spanish', flag: '🇪🇸');
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
  
  Map<String, String> getTranslations() {
    return getTranslation(_nativeLanguage.code);
  }

  // Helper to get available languages
  List<Language> get availableLanguages => const [
    Language(code: 'en', name: 'English', flag: '🇺🇸'),
    Language(code: 'es', name: 'Spanish', flag: '🇪🇸'),
    Language(code: 'fr', name: 'French', flag: '🇫🇷'),
    Language(code: 'de', name: 'German', flag: '🇩🇪'),
    Language(code: 'it', name: 'Italian', flag: '🇮🇹'),
    Language(code: 'pt', name: 'Portuguese', flag: '🇵🇹'),
    Language(code: 'ru', name: 'Russian', flag: '🇷🇺'),
    Language(code: 'ja', name: 'Japanese', flag: '🇯🇵'),
    Language(code: 'zh', name: 'Chinese', flag: '🇨🇳'),
    Language(code: 'ko', name: 'Korean', flag: '🇰🇷'),
    Language(code: 'ar', name: 'Arabic', flag: '🇸🇦'),
    Language(code: 'hi', name: 'Hindi', flag: '🇮🇳'),
    Language(code: 'tr', name: 'Turkish', flag: '🇹🇷'),
    Language(code: 'nl', name: 'Dutch', flag: '🇳🇱'),
    Language(code: 'sv', name: 'Swedish', flag: '🇸🇪'),
    Language(code: 'pl', name: 'Polish', flag: '🇵🇱'),
    Language(code: 'id', name: 'Indonesian', flag: '🇮🇩'),
    Language(code: 'vi', name: 'Vietnamese', flag: '🇻🇳'),
    Language(code: 'th', name: 'Thai', flag: '🇹🇭'),
    Language(code: 'el', name: 'Greek', flag: '🇬🇷'),
    Language(code: 'he', name: 'Hebrew', flag: '🇮🇱'),
    Language(code: 'uk', name: 'Ukrainian', flag: '🇺🇦'),
    Language(code: 'da', name: 'Danish', flag: '🇩🇰'),
    Language(code: 'fi', name: 'Finnish', flag: '🇫🇮'),
    Language(code: 'no', name: 'Norwegian', flag: '🇳🇴'),
    Language(code: 'cs', name: 'Czech', flag: '🇨🇿'),
    Language(code: 'ro', name: 'Romanian', flag: '🇷🇴'),
    Language(code: 'hu', name: 'Hungarian', flag: '🇭🇺'),
  ];
}
