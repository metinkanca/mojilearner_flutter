import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../utils/notification_planner.dart';

/// The text one scheduled notification should display.
///
/// Resolved by the caller from [AppLocalizations], because the service has no
/// build context and the strings have to be in the user's language.
class NotificationCopy {
  const NotificationCopy({required this.title, required this.body});

  final String title;
  final String body;
}

/// Thin wrapper over `flutter_local_notifications`.
///
/// Deliberately holds no policy: *what* to send and *when* is
/// [NotificationPlanner]'s job, and the copy comes from the caller. This
/// class only knows how to talk to the platform, which is the part that
/// can't be unit-tested anyway.
///
/// Every method is a no-op that swallows platform errors rather than
/// throwing. A notification that fails to schedule must never take down the
/// screen that asked for it.
class NotificationService {
  NotificationService._();

  /// Subclass hook for tests. Lets a fake stand in for the platform channel
  /// without pulling the plugin into a unit test.
  @visibleForTesting
  NotificationService.test();

  static final NotificationService instance = NotificationService._();

  @visibleForTesting
  static NotificationService? debugOverride;

  static NotificationService get I => debugOverride ?? instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Android channel ids. Separate channels per kind so a player can mute the
  /// pet nag without losing review reminders.
  static const String petChannelId = 'moji_pet_care';
  static const String reviewChannelId = 'moji_review_due';
  static const String rewardChannelId = 'moji_daily_reward';

  static String channelIdFor(NotificationKind kind) {
    switch (kind) {
      case NotificationKind.petNeedsCare:
        return petChannelId;
      case NotificationKind.reviewDue:
        return reviewChannelId;
      case NotificationKind.dailyReward:
        return rewardChannelId;
    }
  }

  /// Prepares the plugin and the timezone database.
  ///
  /// Safe to call repeatedly. Returns false when the platform refused, in
  /// which case every later call is a harmless no-op.
  Future<bool> init() async {
    if (_initialized) return true;

    try {
      tz_data.initializeTimeZones();
      // Scheduling in the device's own zone is what keeps "8am" meaning 8am
      // after the player flies somewhere.
      final localZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localZone.identifier));
    } catch (e) {
      // A missing or unrecognised zone must not disable notifications
      // outright; UTC is wrong but still fires.
      debugPrint('⚠️ NOTIFY: Timezone setup failed, falling back to UTC - $e');
    }

    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // Permission is requested explicitly in [requestPermission] so the
          // prompt lands when the player opts in, not at cold start.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );

      await _plugin.initialize(settings: settings);
      _initialized = true;
      return true;
    } catch (e) {
      debugPrint('⚠️ NOTIFY: Initialization failed - $e');
      return false;
    }
  }

  /// Asks the OS for permission. Returns true when notifications may be sent.
  ///
  /// Call this from an explicit opt-in, never at startup — a permission
  /// prompt before the player knows what the app is gets denied.
  Future<bool> requestPermission() async {
    if (!await init()) return false;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final granted = await android?.requestNotificationsPermission();
        return granted ?? false;
      }

      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        final darwin = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final granted = await darwin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      return false;
    } catch (e) {
      debugPrint('⚠️ NOTIFY: Permission request failed - $e');
      return false;
    }
  }

  /// Replaces the pending schedule with [planned].
  ///
  /// Cancels first so a stale reminder can't outlive the state that justified
  /// it — a player who just fed the pet should not get "Moji is hungry" from
  /// the schedule written an hour ago.
  Future<void> applyPlan(
    List<PlannedNotification> planned,
    Map<NotificationKind, NotificationCopy> copy,
  ) async {
    if (!await init()) return;

    await cancelAll();

    for (final notification in planned) {
      final text = copy[notification.kind];
      if (text == null) continue;
      await _schedule(notification, text);
    }
  }

  Future<void> _schedule(
    PlannedNotification notification,
    NotificationCopy copy,
  ) async {
    try {
      final when = tz.TZDateTime.from(notification.fireAt, tz.local);
      // A time already in the past would fire immediately, which reads as a
      // bug to the player.
      if (!when.isAfter(tz.TZDateTime.now(tz.local))) return;

      await _plugin.zonedSchedule(
        id: notification.id,
        title: copy.title,
        body: copy.body,
        scheduledDate: when,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channelIdFor(notification.kind),
            _channelNameFor(notification.kind),
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        // Inexact is deliberate: none of these are time-critical, and exact
        // alarms need a special permission on Android 12+ that reviewers
        // rightly question for a pet reminder.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: notification.kind.name,
      );
    } catch (e) {
      debugPrint('⚠️ NOTIFY: Failed to schedule ${notification.kind} - $e');
    }
  }

  /// Fallback channel names, used only if the OS creates the channel before
  /// the localized names are available.
  static String _channelNameFor(NotificationKind kind) {
    switch (kind) {
      case NotificationKind.petNeedsCare:
        return 'Moji needs you';
      case NotificationKind.reviewDue:
        return 'Review reminders';
      case NotificationKind.dailyReward:
        return 'Daily reward';
    }
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('⚠️ NOTIFY: Failed to cancel notifications - $e');
    }
  }

  Future<void> cancel(NotificationKind kind) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id: kind.id);
    } catch (e) {
      debugPrint('⚠️ NOTIFY: Failed to cancel $kind - $e');
    }
  }
}
