/// Security Event Logger
/// 
/// Centralized logging system for security events including injection attempts,
/// rate limit violations, and validation failures.
/// 
/// Events are tracked in-memory and can be exported to JSON for analysis.
/// In production, events should be sent to a security monitoring service.
/// 
/// Usage:
/// ```dart
/// SecurityLogger.logInjectionAttempt(
///   input: userInput,
///   source: 'chat_screen',
///   patterns: ['ignore previous instructions'],
/// );
/// 
/// // Export logs for analysis
/// final logs = SecurityLogger.exportToJson();
/// ```

import 'dart:convert';

/// Represents a single security event
class SecurityEvent {
  final DateTime timestamp;
  final String eventType;
  final String source;
  final String? input;
  final String? output;
  final List<String>? patterns;
  final String? reason;
  final Map<String, dynamic>? metadata;

  SecurityEvent({
    required this.timestamp,
    required this.eventType,
    required this.source,
    this.input,
    this.output,
    this.patterns,
    this.reason,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'eventType': eventType,
      'source': source,
      if (input != null) 'input': _truncate(input!, 200),
      if (output != null) 'output': _truncate(output!, 200),
      if (patterns != null) 'patterns': patterns,
      if (reason != null) 'reason': reason,
      if (metadata != null) 'metadata': metadata,
    };
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}... [truncated]';
  }
}

class SecurityLogger {
  // Private constructor to prevent instantiation
  SecurityLogger._();

  // In-memory event storage (in production, send to backend)
  static final List<SecurityEvent> _events = [];
  
  // Configuration
  static const int maxEventsInMemory = 1000;
  static bool _enabled = true;

  /// Enable or disable security logging
  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Log a prompt injection attempt
  /// 
  /// Called when suspicious input patterns are detected
  static void logInjectionAttempt({
    required String input,
    required String source,
    required List<String> patterns,
  }) {
    if (!_enabled) return;

    final event = SecurityEvent(
      timestamp: DateTime.now(),
      eventType: 'injection_attempt',
      source: source,
      input: input,
      patterns: patterns,
    );

    _addEvent(event);
    
    // Log to console for development
    print('⚠️ SECURITY [INJECTION]: Attempt from $source');
    print('   Patterns: ${patterns.join(", ")}');
    print('   Input preview: ${_preview(input)}');
  }

  /// Log a rate limit violation
  /// 
  /// Called when user exceeds request limits
  static void logRateLimitViolation({
    required String source,
    required String limitType,
    required int requestCount,
    required int maxRequests,
    Map<String, dynamic>? metadata,
  }) {
    if (!_enabled) return;

    final event = SecurityEvent(
      timestamp: DateTime.now(),
      eventType: 'rate_limit_violation',
      source: source,
      reason: '$requestCount requests exceeds limit of $maxRequests ($limitType)',
      metadata: {
        'limitType': limitType,
        'requestCount': requestCount,
        'maxRequests': maxRequests,
        ...?metadata,
      },
    );

    _addEvent(event);
    
    // Log to console for development
    print('⚠️ SECURITY [RATE_LIMIT]: Violation in $source');
    print('   Type: $limitType');
    print('   Count: $requestCount/$maxRequests');
  }

  /// Log an output validation failure
  /// 
  /// Called when AI response fails security validation
  static void logValidationFailure({
    required String output,
    required String source,
    required String reason,
    List<String>? patterns,
  }) {
    if (!_enabled) return;

    final event = SecurityEvent(
      timestamp: DateTime.now(),
      eventType: 'validation_failure',
      source: source,
      output: output,
      reason: reason,
      patterns: patterns,
    );

    _addEvent(event);
    
    // Log to console for development
    print('⚠️ SECURITY [VALIDATION]: Failure in $source');
    print('   Reason: $reason');
    print('   Output preview: ${_preview(output)}');
    if (patterns != null && patterns.isNotEmpty) {
      print('   Patterns: ${patterns.join(", ")}');
    }
  }

  /// Log a suspicious activity
  /// 
  /// Generic logging for unusual patterns that don't fit other categories
  static void logSuspiciousActivity({
    required String source,
    required String description,
    String? input,
    Map<String, dynamic>? metadata,
  }) {
    if (!_enabled) return;

    final event = SecurityEvent(
      timestamp: DateTime.now(),
      eventType: 'suspicious_activity',
      source: source,
      input: input,
      reason: description,
      metadata: metadata,
    );

    _addEvent(event);
    
    // Log to console for development
    print('⚠️ SECURITY [SUSPICIOUS]: Activity in $source');
    print('   Description: $description');
    if (input != null) {
      print('   Input preview: ${_preview(input)}');
    }
  }

  /// Add event to storage with size management
  static void _addEvent(SecurityEvent event) {
    _events.add(event);
    
    // Prevent memory overflow by removing oldest events
    if (_events.length > maxEventsInMemory) {
      _events.removeAt(0);
    }
  }

  /// Create a preview of text for logging
  static String _preview(String text, {int maxLength = 100}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Get all events
  static List<SecurityEvent> getEvents() {
    return List.unmodifiable(_events);
  }

  /// Get events by type
  static List<SecurityEvent> getEventsByType(String eventType) {
    return _events.where((e) => e.eventType == eventType).toList();
  }

  /// Get events by source
  static List<SecurityEvent> getEventsBySource(String source) {
    return _events.where((e) => e.source == source).toList();
  }

  /// Get events in time range
  static List<SecurityEvent> getEventsByTimeRange(DateTime start, DateTime end) {
    return _events.where((e) {
      return e.timestamp.isAfter(start) && e.timestamp.isBefore(end);
    }).toList();
  }

  /// Get event count
  static int getEventCount() {
    return _events.length;
  }

  /// Get event count by type
  static int getEventCountByType(String eventType) {
    return _events.where((e) => e.eventType == eventType).length;
  }

  /// Export all events to JSON
  /// 
  /// Returns a JSON-formatted string suitable for analysis or export
  static String exportToJson() {
    final data = {
      'exportDate': DateTime.now().toIso8601String(),
      'totalEvents': _events.length,
      'events': _events.map((e) => e.toJson()).toList(),
      'summary': {
        'injection_attempts': getEventCountByType('injection_attempt'),
        'rate_limit_violations': getEventCountByType('rate_limit_violation'),
        'validation_failures': getEventCountByType('validation_failure'),
        'suspicious_activities': getEventCountByType('suspicious_activity'),
      },
    };
    
    return json.encode(data);
  }

  /// Export events to structured map
  /// 
  /// Returns a Map suitable for further processing
  static Map<String, dynamic> exportToMap() {
    return {
      'exportDate': DateTime.now().toIso8601String(),
      'totalEvents': _events.length,
      'events': _events.map((e) => e.toJson()).toList(),
      'summary': {
        'injection_attempts': getEventCountByType('injection_attempt'),
        'rate_limit_violations': getEventCountByType('rate_limit_violation'),
        'validation_failures': getEventCountByType('validation_failure'),
        'suspicious_activities': getEventCountByType('suspicious_activity'),
      },
    };
  }

  /// Clear all events
  /// 
  /// Useful for testing or after exporting logs
  static void clearEvents() {
    _events.clear();
  }

  /// Get security summary
  /// 
  /// Returns high-level statistics about security events
  static Map<String, dynamic> getSummary() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    final recentEvents = getEventsByTimeRange(last24Hours, now);

    return {
      'total_events': _events.length,
      'events_last_24h': recentEvents.length,
      'by_type': {
        'injection_attempts': getEventCountByType('injection_attempt'),
        'rate_limit_violations': getEventCountByType('rate_limit_violation'),
        'validation_failures': getEventCountByType('validation_failure'),
        'suspicious_activities': getEventCountByType('suspicious_activity'),
      },
      'oldest_event': _events.isNotEmpty 
          ? _events.first.timestamp.toIso8601String() 
          : null,
      'newest_event': _events.isNotEmpty 
          ? _events.last.timestamp.toIso8601String() 
          : null,
    };
  }

  /// Print summary to console
  static void printSummary() {
    final summary = getSummary();
    print('');
    print('═══════════════════════════════════════');
    print('   SECURITY EVENT SUMMARY');
    print('═══════════════════════════════════════');
    print('Total Events: ${summary['total_events']}');
    print('Last 24 Hours: ${summary['events_last_24h']}');
    print('');
    print('By Type:');
    final byType = summary['by_type'] as Map<String, dynamic>;
    byType.forEach((type, count) {
      print('  - ${type.padRight(25)}: $count');
    });
    print('═══════════════════════════════════════');
    print('');
  }
}
