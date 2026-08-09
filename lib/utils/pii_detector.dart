/// PII Detector Utility
///
/// Detects and redacts common personal data patterns in user-provided text
/// before persistence or model submission.
class PIIDetector {
  PIIDetector._();

  static final List<RegExp> _piiPatterns = [
    RegExp(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b'), // Phone numbers
    RegExp(r'\b\d{5}(?:-\d{4})?\b'), // Postal codes
    RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b'), // Emails
    RegExp(r'\b\d{3}-\d{2}-\d{4}\b'), // SSN-like format
    RegExp(r'\b(password|passcode|pin|secret)\b\s*[:=]\s*\S+',
        caseSensitive: false), // Credentials-like input
  ];

  static bool hasSensitiveData(String input) {
    if (input.isEmpty) return false;
    return _piiPatterns.any((pattern) => pattern.hasMatch(input));
  }

  static String redactSensitiveData(String input) {
    if (input.isEmpty) return input;

    var redacted = input;
    for (final pattern in _piiPatterns) {
      redacted = redacted.replaceAll(pattern, '[REDACTED]');
    }
    return redacted;
  }
}
