import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';

class SettingsProvider with ChangeNotifier {
  static const String _pixelFontKey = 'settings_use_pixel_font';
  static const String _notificationsKey = 'settings_notifications_enabled';

  bool _usePixelFont = true;
  bool _notificationsEnabled = false;

  /// True when the player asked for notifications but the OS refused, so the
  /// settings screen can point them at system settings instead of silently
  /// leaving the switch off.
  bool _notificationsDenied = false;

  bool _isLoaded = false;

  bool get usePixelFont => _usePixelFont;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get notificationsDenied => _notificationsDenied;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    if (_isLoaded) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _usePixelFont = prefs.getBool(_pixelFontKey) ?? true;
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? false;
    } catch (e) {
      debugPrint('⚠️ SETTINGS: Failed to load - $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> togglePixelFont(bool value) async {
    if (_usePixelFont == value) return;
    _usePixelFont = value;
    notifyListeners();
    await _persist(_pixelFontKey, value);
  }

  /// Turns reminders on or off.
  ///
  /// Enabling asks the OS for permission at the moment the player opts in —
  /// never at startup, where a prompt from an app you don't yet understand
  /// gets denied and can't be asked again.
  ///
  /// Returns the state the switch actually ended up in, which is false when
  /// permission was refused.
  Future<bool> setNotificationsEnabled(bool value) async {
    if (!value) {
      _notificationsEnabled = false;
      _notificationsDenied = false;
      notifyListeners();
      await NotificationService.I.cancelAll();
      await _persist(_notificationsKey, false);
      return false;
    }

    final granted = await NotificationService.I.requestPermission();
    _notificationsEnabled = granted;
    _notificationsDenied = !granted;
    notifyListeners();
    await _persist(_notificationsKey, granted);
    return granted;
  }

  Future<void> _persist(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('⚠️ SETTINGS: Failed to save $key - $e');
    }
  }
}
