/// Security Event Logger
///
/// Centralized logging system for security events including injection attempts,
/// rate limit violations, and validation failures.
///
/// Events are tracked in-memory and persisted (encrypted, capped at
/// [SecurityLogger.maxPersistedEvents]) so they survive app restarts.
/// Call [SecurityLogger.init] once at startup to restore persisted events.
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

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'secure_storage.dart';

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

  factory SecurityEvent.fromJson(Map<String, dynamic> json) => SecurityEvent(
        timestamp: DateTime.parse(json['timestamp']),
        eventType: json['eventType'],
        source: json['source'],
        input: json['input'],
        output: json['output'],
        patterns: (json['patterns'] as List?)?.cast<String>(),
        reason: json['reason'],
        metadata: json['metadata'] != null
            ? Map<String, dynamic>.from(json['metadata'] as Map)
            : null,
      );
}

class SecurityLogger {
  // Private constructor to prevent instantiation
  SecurityLogger._();

  // In-memory event storage, backed by encrypted local persistence.
  static final List<SecurityEvent> _events = [];

  // Configuration
  static const int maxEventsInMemory = 1000;
  static const int maxPersistedEvents = 200;
  static bool _enabled = true;

  static const String _storageKey = 'security_events';
  static Future<void>? _initFuture;
  static Timer? _persistTimer;

  /// Enable or disable security logging
  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Restores persisted events. Call once at app startup; later calls are
  /// no-ops. Logging works without it, but persisted history stays hidden
  /// until init runs.
  static Future<void> init() => _initFuture ??= _loadPersisted();

  static Future<void> _loadPersisted() async {
    try {
      final data = await SecureStorage.readEncrypted<List>(_storageKey);
      if (data == null) return;
      final restored = data
          .map((e) =>
              SecurityEvent.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      // Persisted events predate anything logged this session.
      _events.insertAll(0, restored);
      while (_events.length > maxEventsInMemory) {
        _events.removeAt(0);
      }
    } catch (e) {
      debugPrint('⚠️ SECURITY: Failed to load persisted events - $e');
    }
  }

  /// Debounced persistence: bursts of events collapse into a single write.
  static void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(seconds: 2), persistNow);
  }

  /// Writes the most recent [maxPersistedEvents] events to encrypted
  /// storage immediately.
  static Future<void> persistNow() async {
    _persistTimer?.cancel();
    _persistTimer = null;
    try {
      await init();
      final recent = _events.length > maxPersistedEvents
          ? _events.sublist(_events.length - maxPersistedEvents)
          : _events;
      await SecureStorage.saveEncrypted(
        _storageKey,
        recent.map((e) => e.toJson()).toList(),
      );
    } catch (e) {
      debugPrint('⚠️ SECURITY: Failed to persist events - $e');
    }
  }

  /// Test hook: clears in-memory state without touching persisted data,
  /// simulating an app restart.
  @visibleForTesting
  static void resetForTest() {
    _events.clear();
    _persistTimer?.cancel();
    _persistTimer = null;
    _initFuture = null;
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
    debugPrint('⚠️ SECURITY [INJECTION]: Attempt from $source');
    debugPrint('   Patterns: ${patterns.join(", ")}');
    debugPrint('   Input preview: ${_preview(input)}');
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
    debugPrint('⚠️ SECURITY [RATE_LIMIT]: Violation in $source');
    debugPrint('   Type: $limitType');
    debugPrint('   Count: $requestCount/$maxRequests');
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
    debugPrint('⚠️ SECURITY [VALIDATION]: Failure in $source');
    debugPrint('   Reason: $reason');
    debugPrint('   Output preview: ${_preview(output)}');
    if (patterns != null && patterns.isNotEmpty) {
      debugPrint('   Patterns: ${patterns.join(", ")}');
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
    debugPrint('⚠️ SECURITY [SUSPICIOUS]: Activity in $source');
    debugPrint('   Description: $description');
    if (input != null) {
      debugPrint('   Input preview: ${_preview(input)}');
    }
  }

  /// Add event to storage with size management
  static void _addEvent(SecurityEvent event) {
    _events.add(event);

    // Prevent memory overflow by removing oldest events
    if (_events.length > maxEventsInMemory) {
      _events.removeAt(0);
    }

    _schedulePersist();
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

  /// Clear all events, including the persisted copy
  ///
  /// Useful for testing or after exporting logs
  static Future<void> clearEvents() async {
    _events.clear();
    _persistTimer?.cancel();
    _persistTimer = null;
    try {
      await init();
      await SecureStorage.delete(_storageKey);
    } catch (e) {
      debugPrint('⚠️ SECURITY: Failed to clear persisted events - $e');
    }
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
    debugPrint('');
    debugPrint('═══════════════════════════════════════');
    debugPrint('   SECURITY EVENT SUMMARY');
    debugPrint('═══════════════════════════════════════');
    debugPrint('Total Events: ${summary['total_events']}');
    debugPrint('Last 24 Hours: ${summary['events_last_24h']}');
    debugPrint('');
    debugPrint('By Type:');
    final byType = summary['by_type'] as Map<String, dynamic>;
    byType.forEach((type, count) {
      debugPrint('  - ${type.padRight(25)}: $count');
    });
    debugPrint('═══════════════════════════════════════');
    debugPrint('');
  }
}
