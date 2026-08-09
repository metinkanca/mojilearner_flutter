/// Semantic Validator Utility
///
/// Adds lightweight conversation-aware checks to detect likely jailbreak
/// attempts that bypass strict regex-based input sanitization.
class SemanticValidator {
  SemanticValidator._();

  static const List<String> _jailbreakSignals = [
    'ignore instructions',
    'disregard instructions',
    'forget instructions',
    'bypass',
    'jailbreak',
    'without rules',
    'override',
    'pretend to be',
    'act as',
    'you are now',
    'system prompt',
    'reveal prompt',
    'roleplay',
    'developer message',
  ];

  static bool hasJailbreakSignals(String input) {
    if (input.isEmpty) return false;

    final normalized = input.toLowerCase();
    for (final signal in _jailbreakSignals) {
      if (normalized.contains(signal)) {
        return true;
      }
    }

    // Detect repeated fragments that often appear in abuse payloads.
    if (RegExp(r'(.{3,})\1{3,}', caseSensitive: false).hasMatch(normalized)) {
      return true;
    }

    return false;
  }

  static bool hasAnomalousShift({
    required List<String> recentUserMessages,
    required String newInput,
  }) {
    if (newInput.isEmpty) return false;

    final newLooksSuspicious = hasJailbreakSignals(newInput);
    if (!newLooksSuspicious) return false;

    // Treat abrupt shift as suspicious if previous user turns looked normal.
    final priorSuspiciousCount = recentUserMessages
        .where((message) => hasJailbreakSignals(message))
        .length;

    return priorSuspiciousCount == 0;
  }
}
