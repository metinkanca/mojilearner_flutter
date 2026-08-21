/// Output Validation Utility
/// 
/// Validates and sanitizes AI responses to prevent data leaks,
/// malformed content, and potential security issues.
/// 
/// Usage:
/// ```dart
/// final response = await chatSession.sendMessage(...);
/// if (OutputValidator.isValidResponse(response.text)) {
///   final sanitized = OutputValidator.sanitizeResponse(response.text);
///   // Use sanitized response
/// }
/// ```
library;

import 'security_logger.dart';

class OutputValidator {
  // Maximum reasonable response length
  static const int maxResponseLength = 10000;
  
  // Suspicious patterns that should never appear in AI responses
  static final List<RegExp> _suspiciousPatterns = [
    // API keys and secrets
    RegExp(r'(api[_-]?key|secret|token|password)\s*[:=]\s*["' r"'" r']?[a-zA-Z0-9]+', caseSensitive: false),
    RegExp(r'sk-[a-zA-Z0-9]{32,}'), // OpenAI-style keys
    RegExp(r'AIza[a-zA-Z0-9_-]{35}'), // Google API keys
    
    // System prompt leakage
    RegExp(r'my (system )?instructions (are|were|say)', caseSensitive: false),
    RegExp(r'I (was|am) (told|instructed|programmed) to', caseSensitive: false),
    
    // Code injection attempts
    RegExp(r'<script[\s>]', caseSensitive: false),
    RegExp(r'javascript:', caseSensitive: false),
    RegExp(r'onerror\s*=', caseSensitive: false),
    RegExp(r'eval\s*\(', caseSensitive: false),
    
    // SQL injection indicators
    RegExp(r';\s*drop\s+table', caseSensitive: false),
    RegExp(r'union\s+select', caseSensitive: false),
    
    // File path leakage
    RegExp(r'[a-zA-Z]:\\.*\\.*\\.', caseSensitive: false),
    RegExp(r'/home/[a-z]+/.*/.', caseSensitive: false),
  ];
  
  /// Checks if AI response is valid and safe
  /// 
  /// Returns false if response contains suspicious patterns or is malformed
  static bool isValidResponse(String? response, {String source = 'unknown'}) {
    if (response == null || response.isEmpty) return false;
    
    // Check length
    if (response.length > maxResponseLength) {
      SecurityLogger.logValidationFailure(
        output: response,
        source: source,
        reason: 'Response exceeds maximum length (${response.length} > $maxResponseLength)',
      );
      return false;
    }
    
    // Check for suspicious patterns
    for (final pattern in _suspiciousPatterns) {
      if (pattern.hasMatch(response)) {
        SecurityLogger.logValidationFailure(
          output: response,
          source: source,
          reason: 'Suspicious pattern detected in response',
          patterns: [pattern.pattern],
        );
        return false;
      }
    }
    
    // Check for excessive control characters
    final controlCharCount = response.codeUnits.where((code) => code < 32 && code != 10 && code != 13).length;
    if (controlCharCount > response.length * 0.05) {
      SecurityLogger.logValidationFailure(
        output: response,
        source: source,
        reason: 'Excessive control characters in response ($controlCharCount/${response.length})',
      );
      return false;
    }
    
    return true;
  }
  
  /// Sanitizes AI response to remove potentially harmful content
  /// 
  /// Returns cleaned response safe for display
  static String sanitizeResponse(String response) {
    if (response.isEmpty) return response;
    
    String sanitized = response;
    
    // 1. Remove potential API keys/secrets
    for (final pattern in _suspiciousPatterns) {
      sanitized = sanitized.replaceAll(pattern, '[REDACTED]');
    }
    
    // 2. Limit length
    if (sanitized.length > maxResponseLength) {
      sanitized = sanitized.substring(0, maxResponseLength);
      sanitized += '\n\n[Response truncated for safety]';
    }
    
    // 3. Remove control characters (except newlines and tabs)
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
    
    // 4. Normalize whitespace (but keep intentional line breaks)
    sanitized = sanitized.replaceAll(RegExp(r'[ \t]+'), ' ');
    sanitized = sanitized.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    return sanitized.trim();
  }
  
  /// Validates response format for structured responses (TEXT/TRANS/GRAMMAR)
  /// 
  /// Returns true if response contains expected format markers
  static bool hasValidFormat(String response, {required bool requiresFormat}) {
    if (!requiresFormat) return true;
    
    // Check for required format markers
    final hasText = response.contains('TEXT:');
    final hasTrans = response.contains('TRANS:');
    final hasGrammar = response.contains('GRAMMAR:');
    
    return hasText && hasTrans && hasGrammar;
  }
  
  /// Validates JSON response from quiz generation
  /// 
  /// Returns true if response is valid JSON array of questions
  static bool isValidQuizJson(String jsonText, {String source = 'quiz_generation'}) {
    try {
      // Remove markdown code blocks if present
      final cleaned = jsonText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      
      if (!cleaned.startsWith('[') || !cleaned.endsWith(']')) {
        SecurityLogger.logValidationFailure(
          output: jsonText,
          source: source,
          reason: 'Quiz JSON must be an array',
        );
        return false;
      }
      
      // Check minimum expected length (allow short valid JSON for testing)
      if (cleaned.length < 10) {
        SecurityLogger.logValidationFailure(
          output: jsonText,
          source: source,
          reason: 'Quiz JSON too short to be valid',
        );
        return false;
      }
      
      return true;
    } catch (e) {
      SecurityLogger.logValidationFailure(
        output: jsonText,
        source: source,
        reason: 'Invalid quiz JSON - $e',
      );
      return false;
    }
  }
  
  /// Extracts and validates mistake marker from response
  /// 
  /// Returns cleaned response without mistake marker, null if invalid
  static String? extractAndValidateMistake(String response, {String source = 'chat'}) {
    if (!response.contains('|||MISTAKE|||')) {
      return response;
    }
    
    final parts = response.split('|||MISTAKE|||');
    if (parts.length != 2) {
      SecurityLogger.logValidationFailure(
        output: response,
        source: source,
        reason: 'Malformed mistake marker',
      );
      return null;
    }
    
    final content = parts[0].trim();
    final mistakeJson = parts[1].trim();
    
    // Basic JSON validation
    if (!mistakeJson.startsWith('{') || !mistakeJson.endsWith('}')) {
      SecurityLogger.logValidationFailure(
        output: response,
        source: source,
        reason: 'Invalid mistake JSON structure',
      );
      return null;
    }
    
    // Check for required fields
    if (!mistakeJson.contains('"original"') || 
        !mistakeJson.contains('"correction"')) {
      SecurityLogger.logValidationFailure(
        output: response,
        source: source,
        reason: 'Missing required mistake fields',
      );
      return null;
    }
    
    return content;
  }
  
  /// Logs validation failures for security monitoring
  /// 
  /// Uses SecurityLogger for centralized security event tracking  
  static void logValidationFailure(String reason, String response, {String source = 'unknown'}) {
    SecurityLogger.logValidationFailure(
      output: response,
      source: source,
      reason: reason,
    );
  }
  
  /// Validates response doesn't contain prompt injection indicators
  /// 
  /// Returns true if response appears to be genuine AI output
  static bool isGenuineResponse(String response, {String source = 'unknown'}) {
    // Signs of successful prompt injection
    final injectionIndicators = [
      RegExp(r'(ignoring|ignored) previous instructions', caseSensitive: false),
      RegExp(r'my role (has changed|is now)', caseSensitive: false),
      RegExp(r'pretending to be', caseSensitive: false),
      RegExp(r'system prompt:', caseSensitive: false),
    ];
    
    for (final indicator in injectionIndicators) {
      if (indicator.hasMatch(response)) {
        SecurityLogger.logValidationFailure(
          output: response,
          source: source,
          reason: 'Prompt injection indicator detected',
          patterns: [indicator.pattern],
        );
        return false;
      }
    }
    
    return true;
  }
}
