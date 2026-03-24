/// Input Sanitization Utility
/// 
/// Protects against prompt injection attacks by filtering malicious patterns
/// from user input before sending to AI models.
/// 
/// Usage:
/// ```dart
/// final sanitized = InputSanitizer.sanitizeUserInput(userMessage);
/// await chatSession.sendMessage(Content.text(sanitized));
/// ```

import 'security_logger.dart';

class InputSanitizer {
  // Maximum allowed input length to prevent abuse
  static const int maxInputLength = 500;
  
  // Dangerous patterns that could manipulate AI behavior
  static final List<RegExp> _dangerousPatterns = [
    // Attempts to override instructions (broader patterns first for better matching)
    RegExp(r'ignore\s+(all\s+)?(previous\s+|prior\s+)?instructions?', caseSensitive: false),
    RegExp(r'disregard\s+(all\s+)?(previous\s+|prior\s+)?instructions?', caseSensitive: false),
    RegExp(r'forget\s+(all\s+)?(previous\s+|prior\s+)?instructions?', caseSensitive: false),
    
    // Role manipulation attempts
    RegExp(r'you\s+are\s+(now|a)\s+', caseSensitive: false),
    RegExp(r'pretend\s+(to\s+be|you|that)', caseSensitive: false),
    RegExp(r'act\s+as\s+(a|an|if)', caseSensitive: false),
    RegExp(r'simulate\s+(being|a)', caseSensitive: false),
    
    // System/meta commands
    RegExp(r'system\s*:', caseSensitive: false),
    RegExp(r'assistant\s*:', caseSensitive: false),
    RegExp(r'user\s*:', caseSensitive: false),
    
    // Special marker injection
    RegExp(r'\|\|\|MISTAKE\|\|\|', caseSensitive: false),
    RegExp(r'TEXT\s*:', caseSensitive: false),
    RegExp(r'TRANS\s*:', caseSensitive: false),
    RegExp(r'GRAMMAR\s*:', caseSensitive: false),
    
    // Prompt leaking attempts
    RegExp(r'show\s+(me\s+)?(your|the)\s+(system\s+)?(prompt|instructions)', caseSensitive: false),
    RegExp(r'what\s+(are|is)\s+your\s+(system\s+)?(prompt|instructions)', caseSensitive: false),
    RegExp(r'reveal\s+(your|the)\s+prompt', caseSensitive: false),
    
    // Code injection attempts
    RegExp(r'<script', caseSensitive: false),
    RegExp(r'javascript:', caseSensitive: false),
    RegExp(r'eval\s*\(', caseSensitive: false),
    
    // SQL-like injection attempts
    RegExp(r';\s*drop\s+table', caseSensitive: false),
    RegExp(r'union\s+select', caseSensitive: false),
  ];
  
  /// Sanitizes user input to prevent prompt injection attacks
  /// 
  /// Returns cleaned input that is safe to send to AI models
  static String sanitizeUserInput(String input, {String source = 'unknown'}) {
    if (input.isEmpty) return input;
    
    // Check for suspicious patterns before sanitization
    if (isSuspicious(input)) {
      final matchedPatterns = <String>[];
      for (final pattern in _dangerousPatterns) {
        if (pattern.hasMatch(input)) {
          matchedPatterns.add(pattern.pattern);
        }
      }
      
      SecurityLogger.logInjectionAttempt(
        input: input,
        source: source,
        patterns: matchedPatterns,
      );
    }
    
    String sanitized = input;
    
    // 1. Remove dangerous patterns
    for (final pattern in _dangerousPatterns) {
      sanitized = sanitized.replaceAll(pattern, '');
    }
    
    // 2. Escape special markers used in app
    sanitized = escapeSpecialMarkers(sanitized);
    
    // 3. Limit length to prevent token exhaustion
    if (sanitized.length > maxInputLength) {
      sanitized = sanitized.substring(0, maxInputLength);
    }
    
    // 4. Remove excessive whitespace
    sanitized = sanitized.trim();
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');
    
    // 5. Remove control characters that could break formatting
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
    
    return sanitized;
  }
  
  /// Escapes special markers used in app responses
  /// 
  /// Prevents users from injecting fake mistake markers or response format indicators
  static String escapeSpecialMarkers(String input) {
    return input
        .replaceAll('|||MISTAKE|||', '[MISTAKE]')
        .replaceAll('|||', '|')
        .replaceAll('TEXT:', 'TEXT -')
        .replaceAll('TRANS:', 'TRANS -')
        .replaceAll('GRAMMAR:', 'GRAMMAR -');
  }
  
  /// Validates language name input (used in onboarding)
  /// 
  /// Returns sanitized language name or null if invalid
  static String? sanitizeLanguageName(String? languageName) {
    if (languageName == null || languageName.isEmpty) return null;
    
    // Language names should only contain letters, spaces, and basic punctuation
    final cleaned = languageName.replaceAll(RegExp(r'[^a-zA-Z\s\-]'), '');
    
    // Reasonable length for language names
    if (cleaned.length > 50) return cleaned.substring(0, 50);
    
    return cleaned.trim();
  }
  
  /// Checks if input contains suspicious patterns
  /// 
  /// Returns true if input appears to be an injection attempt
  static bool isSuspicious(String input) {
    for (final pattern in _dangerousPatterns) {
      if (pattern.hasMatch(input)) return true;
    }
    
    // Check for excessive special characters
    final specialCharCount = input.replaceAll(RegExp(r'[a-zA-Z0-9\s]'), '').length;
    if (specialCharCount > input.length * 0.3) return true;
    
    // Check for suspicious repetition
    if (RegExp(r'(.+)\1{5,}').hasMatch(input)) return true;
    
    return false;
  }
  
  /// Logs suspicious input attempts for monitoring
  /// 
  /// Uses SecurityLogger for centralized security event tracking
  static void logSuspiciousInput(String input, String source) {
    final matchedPatterns = <String>[];
    for (final pattern in _dangerousPatterns) {
      if (pattern.hasMatch(input)) {
        matchedPatterns.add(pattern.pattern);
      }
    }
    
    SecurityLogger.logSuspiciousActivity(
      source: source,
      description: 'Suspicious input patterns detected',
      input: input,
      metadata: {'matched_patterns': matchedPatterns},
    );
  }
}
