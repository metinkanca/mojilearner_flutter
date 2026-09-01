/// PII Detector Utility
///
/// Detects and redacts common personal data patterns in user-provided text
/// before persistence or model submission.
class PIIDetector {
  PIIDetector._();

  /// Patterns specific enough that a match is far more likely to be personal
  /// data than ordinary practice text.
  ///
  /// A bare five-digit "postal code" pattern used to live here. In an app
  /// where learners talk about prices it matched "12000 yen", "50000 won" and
  /// every other round number, redacting them out of both the message sent to
  /// the tutor and the copy stored on the device. Only the unambiguous ZIP+4
  /// form survives; a lone five-digit number is a number. The phone pattern
  /// is untouched — ten digits in a row is not a price.
  static final List<RegExp> _piiPatterns = [
    RegExp(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b'), // Phone numbers
    RegExp(r'\b\d{5}-\d{4}\b'), // ZIP+4
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
