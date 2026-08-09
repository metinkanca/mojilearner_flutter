class LevelValidator {
  LevelValidator._();

  static const String beginner = 'beginner';
  static const String intermediate = 'intermediate';
  static const String advanced = 'advanced';

  static const Set<String> validLevels = {
    beginner,
    intermediate,
    advanced,
  };

  static String normalizeLevel(String? value, {String fallback = beginner}) {
    final normalizedFallback =
        validLevels.contains(fallback) ? fallback : beginner;
    final normalized = value?.trim().toLowerCase();

    if (normalized == null || normalized.isEmpty) {
      return normalizedFallback;
    }

    if (validLevels.contains(normalized)) {
      return normalized;
    }

    return normalizedFallback;
  }
}
