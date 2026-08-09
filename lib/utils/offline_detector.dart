import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../constants/app_runtime_config.dart';

class OfflineDetector {
  static String? _getEnvValue(String key) {
    try {
      return dotenv.env[key];
    } catch (_) {
      // dotenv may not be initialized yet
      return null;
    }
  }

  static String? _getConfigValue(String key) {
    if (key == 'AI_PROXY_BASE_URL') {
      final value = AppRuntimeConfig.aiProxyBaseUrl.trim();
      if (value.isNotEmpty) {
        return value;
      }
    }

    if (key == 'ALLOW_CLIENT_AI_FALLBACK') {
      return AppRuntimeConfig.allowClientAiFallback ? 'true' : 'false';
    }

    if (key == 'FORCE_ONLINE_ASSESSMENT') {
      return AppRuntimeConfig.forceOnlineAssessment ? 'true' : 'false';
    }

    return _getEnvValue(key);
  }

  static bool get forceOnlineAssessment {
    final value =
        _getConfigValue('FORCE_ONLINE_ASSESSMENT')?.toLowerCase().trim();
    return value == '1' || value == 'true' || value == 'yes';
  }

  static bool get hasConfiguredBackend {
    final backendUrl = _getConfigValue('AI_PROXY_BASE_URL')?.trim();
    return backendUrl != null && backendUrl.isNotEmpty;
  }

  static bool get isOfflineMode {
    if (forceOnlineAssessment) {
      return false;
    }

    if (hasConfiguredBackend) {
      return false;
    }

    final apiKey = _getEnvValue('GEMINI_API_KEY');
    return apiKey == null || apiKey.isEmpty || apiKey == 'offline';
  }

  static bool get shouldUseConversationalAssessment {
    return forceOnlineAssessment || !isOfflineMode;
  }

  static bool get hasValidApiKey {
    if (hasConfiguredBackend) {
      return true;
    }

    final apiKey = _getEnvValue('GEMINI_API_KEY');
    return apiKey != null && apiKey.isNotEmpty && apiKey != 'offline';
  }
}
