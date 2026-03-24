import 'package:flutter_dotenv/flutter_dotenv.dart';

class OfflineDetector {
  static bool get isOfflineMode {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    return apiKey == null || apiKey.isEmpty || apiKey == 'offline';
  }

  static bool get hasValidApiKey {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    return apiKey != null && apiKey.isNotEmpty && apiKey != 'offline';
  }
}
