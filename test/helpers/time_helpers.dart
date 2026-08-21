/// Time manipulation helpers for testing time-dependent features
/// 
/// Provides utilities to control time in tests for:
/// - Daily reward streaks
/// - Pet vitals decay
/// - Offline decay calculations
/// - Date-based logic
library;

class TestTime {
  static DateTime _currentTime = DateTime(2026, 2, 11, 12, 0, 0);
  
  /// Get the current test time
  static DateTime get now => _currentTime;
  
  /// Set the current test time
  static void setTestTime(DateTime time) {
    _currentTime = time;
  }
  
  /// Reset to default test time
  static void reset() {
    _currentTime = DateTime(2026, 2, 11, 12, 0, 0);
  }
  
  /// Advance time by a duration
  static void advance(Duration duration) {
    _currentTime = _currentTime.add(duration);
  }
  
  /// Advance time by hours
  static void advanceHours(int hours) {
    _currentTime = _currentTime.add(Duration(hours: hours));
  }
  
  /// Advance time by days
  static void advanceDays(int days) {
    _currentTime = _currentTime.add(Duration(days: days));
  }
  
  /// Get yesterday's date (date only, no time)
  static DateTime getYesterday() {
    final yesterday = _currentTime.subtract(const Duration(days: 1));
    return DateTime(yesterday.year, yesterday.month, yesterday.day);
  }
  
  /// Get date N days ago (date only, no time)
  static DateTime getDaysAgo(int days) {
    final daysAgo = _currentTime.subtract(Duration(days: days));
    return DateTime(daysAgo.year, daysAgo.month, daysAgo.day);
  }
  
  /// Get today's date (date only, no time)
  static DateTime getToday() {
    return DateTime(_currentTime.year, _currentTime.month, _currentTime.day);
  }
  
  /// Get tomorrow's date (date only, no time)
  static DateTime getTomorrow() {
    final tomorrow = _currentTime.add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
  }
  
  /// Create a DateTime at a specific time today
  static DateTime todayAt({int hour = 12, int minute = 0, int second = 0}) {
    return DateTime(
      _currentTime.year,
      _currentTime.month,
      _currentTime.day,
      hour,
      minute,
      second,
    );
  }
  
  /// Create a DateTime at a specific time yesterday
  static DateTime yesterdayAt({int hour = 12, int minute = 0, int second = 0}) {
    final yesterday = _currentTime.subtract(const Duration(days: 1));
    return DateTime(
      yesterday.year,
      yesterday.month,
      yesterday.day,
      hour,
      minute,
      second,
    );
  }
}
