/// Rate Limiting Utility
/// 
/// Prevents API abuse by limiting how frequently users can send requests.
/// Implements client-side throttling with configurable cooldown periods.
/// 
/// Usage:
/// ```dart
/// if (!RateLimiter.canSendMessage('chat_screen')) {
///   showSnackBar('Please wait before sending another message');
///   return;
/// }
/// RateLimiter.recordRequest('chat_screen');
/// // ... send message
/// ```
library;

import 'security_logger.dart';

class RateLimiter {
  // Track last request time for each feature
  static final Map<String, DateTime> _lastRequest = {};
  
  // Track request counts within time windows
  static final Map<String, List<DateTime>> _requestHistory = {};
  
  // Configuration
  static const int _messagesCooldownSeconds = 3; // 3 seconds between chat messages
  static const int _quizCooldownSeconds = 2; // 2 seconds between quiz generations
  static const int _assessmentCooldownSeconds = 2; // 2 seconds between assessment messages
  
  // Burst protection: max requests per time window
  static const int _maxRequestsPerMinute = 20;
  static const int _windowDurationSeconds = 60;
  
  /// Check if a message can be sent (general chat)
  static bool canSendMessage(String context) {
    final passedCooldown = _checkCooldown(context, _messagesCooldownSeconds);
    final passedBurstLimit = _checkBurstLimit(context);
    return passedCooldown && passedBurstLimit;
  }
  
  /// Check if a quiz can be generated
  static bool canGenerateQuiz(String context) {
    final passedCooldown = _checkCooldown(context, _quizCooldownSeconds);
    final passedBurstLimit = _checkBurstLimit(context);
    return passedCooldown && passedBurstLimit;
  }
  
  /// Check if an assessment message can be sent
  static bool canSendAssessment(String context) {
    final passedCooldown = _checkCooldown(context, _assessmentCooldownSeconds);
    final passedBurstLimit = _checkBurstLimit(context);
    return passedCooldown && passedBurstLimit;
  }
  
  /// Record a request for rate limiting tracking
  static void recordRequest(String context) {
    _lastRequest[context] = DateTime.now();
    
    // Add to history for burst protection
    _requestHistory.putIfAbsent(context, () => []);
    _requestHistory[context]!.add(DateTime.now());
    
    // Clean old history entries
    _cleanHistory(context);
  }
  
  /// Get remaining cooldown time in seconds
  static int getRemainingCooldown(String context, int cooldownSeconds) {
    final lastTime = _lastRequest[context];
    if (lastTime == null) return 0;
    
    final elapsed = DateTime.now().difference(lastTime).inSeconds;
    final remaining = cooldownSeconds - elapsed;
    
    return remaining > 0 ? remaining : 0;
  }
  
  /// Check cooldown period
  static bool _checkCooldown(String context, int cooldownSeconds) {
    final lastTime = _lastRequest[context];
    if (lastTime == null) return true;
    
    final elapsed = DateTime.now().difference(lastTime).inSeconds;
    final withinCooldown = elapsed >= cooldownSeconds;
    
    // Log cooldown violation
    if (!withinCooldown) {
      SecurityLogger.logRateLimitViolation(
        source: context,
        limitType: 'cooldown',
        requestCount: 1,
        maxRequests: 1,
        metadata: {
          'cooldown_seconds': cooldownSeconds,
          'elapsed_seconds': elapsed,
          'remaining_seconds': cooldownSeconds - elapsed,
        },
      );
    }
    
    return withinCooldown;
  }
  
  /// Check burst limit (prevents rapid-fire requests)
  static bool _checkBurstLimit(String context) {
    final history = _requestHistory[context];
    if (history == null || history.isEmpty) return true;
    
    // Count requests in the last minute
    final now = DateTime.now();
    final recentRequests = history.where((time) {
      return now.difference(time).inSeconds <= _windowDurationSeconds;
    }).length;
    
    final withinLimit = recentRequests < _maxRequestsPerMinute;
    
    // Log rate limit violation
    if (!withinLimit) {
      SecurityLogger.logRateLimitViolation(
        source: context,
        limitType: 'burst_limit',
        requestCount: recentRequests,
        maxRequests: _maxRequestsPerMinute,
        metadata: {
          'window_seconds': _windowDurationSeconds,
        },
      );
    }
    
    return withinLimit;
  }
  
  /// Clean old history entries outside the time window
  static void _cleanHistory(String context) {
    final history = _requestHistory[context];
    if (history == null) return;
    
    final now = DateTime.now();
    history.removeWhere((time) {
      return now.difference(time).inSeconds > _windowDurationSeconds;
    });
  }
  
  /// Get request count in current time window
  static int getRequestCount(String context) {
    final history = _requestHistory[context];
    if (history == null) return 0;
    
    final now = DateTime.now();
    return history.where((time) {
      return now.difference(time).inSeconds <= _windowDurationSeconds;
    }).length;
  }
  
  /// Reset rate limiter for a specific context (useful for testing)
  static void reset(String context) {
    _lastRequest.remove(context);
    _requestHistory.remove(context);
  }
  
  /// Reset all rate limiters
  static void resetAll() {
    _lastRequest.clear();
    _requestHistory.clear();
  }
  
  /// Check if user is being rate limited
  static bool isRateLimited(String context) {
    return !_checkBurstLimit(context);
  }
  
  /// Get user-friendly message for rate limit
  static String getRateLimitMessage(String context, int cooldownSeconds) {
    final remaining = getRemainingCooldown(context, cooldownSeconds);
    
    if (remaining > 0) {
      return 'Please wait $remaining second${remaining > 1 ? 's' : ''} before trying again';
    }
    
    if (isRateLimited(context)) {
      final count = getRequestCount(context);
      return 'Too many requests ($count in last minute). Please slow down.';
    }
    
    return 'Please wait a moment before trying again';
  }
}
