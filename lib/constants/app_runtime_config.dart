class AppRuntimeConfig {
  AppRuntimeConfig._();

  // Checked-in, non-secret runtime values.
  // Set this to your backend URL when available, for example:
  // https://api.example.com
  static const String aiProxyBaseUrl = '';

  // Keep strict backend-only behavior by default.
  static const bool allowClientAiFallback = false;

  // Force onboarding/quiz routing to stay on online screens.
  // When AI is unavailable, screens should use local safe fallbacks.
  static const bool forceOnlineAssessment = true;
}
