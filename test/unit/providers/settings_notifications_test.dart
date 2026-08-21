import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/providers/settings_provider.dart';
import 'package:mojilearner_flutter/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stands in for the plugin wrapper so the permission path can be exercised
/// without a platform channel.
class _FakeNotificationService extends NotificationService {
  _FakeNotificationService({required this.grantPermission}) : super.test();

  final bool grantPermission;

  int permissionRequests = 0;
  int cancelAllCalls = 0;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return grantPermission;
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    NotificationService.debugOverride = null;
  });

  _FakeNotificationService useService({required bool granted}) {
    final fake = _FakeNotificationService(grantPermission: granted);
    NotificationService.debugOverride = fake;
    return fake;
  }

  group('SettingsProvider - defaults', () {
    test('notifications start off, so nothing is sent unasked', () {
      final provider = SettingsProvider();

      expect(provider.notificationsEnabled, isFalse);
      expect(provider.notificationsDenied, isFalse);
    });

    test('pixel font still defaults on', () {
      expect(SettingsProvider().usePixelFont, isTrue);
    });
  });

  group('SettingsProvider.setNotificationsEnabled', () {
    test('asks for permission only when switching on', () async {
      final service = useService(granted: true);
      final provider = SettingsProvider();

      await provider.setNotificationsEnabled(true);

      expect(service.permissionRequests, equals(1));
      expect(provider.notificationsEnabled, isTrue);
      expect(provider.notificationsDenied, isFalse);
    });

    test('a refusal leaves the switch off and flags why', () async {
      useService(granted: false);
      final provider = SettingsProvider();

      final result = await provider.setNotificationsEnabled(true);

      expect(result, isFalse);
      expect(provider.notificationsEnabled, isFalse);
      expect(provider.notificationsDenied, isTrue);
    });

    test('switching off cancels anything already scheduled', () async {
      final service = useService(granted: true);
      final provider = SettingsProvider();
      await provider.setNotificationsEnabled(true);

      await provider.setNotificationsEnabled(false);

      expect(service.cancelAllCalls, equals(1));
      expect(provider.notificationsEnabled, isFalse);
    });

    test('switching off clears a previous refusal', () async {
      useService(granted: false);
      final provider = SettingsProvider();
      await provider.setNotificationsEnabled(true);
      expect(provider.notificationsDenied, isTrue);

      await provider.setNotificationsEnabled(false);

      expect(provider.notificationsDenied, isFalse);
    });

    test('switching off never asks the OS for anything', () async {
      final service = useService(granted: true);
      final provider = SettingsProvider();

      await provider.setNotificationsEnabled(false);

      expect(service.permissionRequests, equals(0));
    });
  });

  group('SettingsProvider - persistence', () {
    test('a granted opt-in survives a reload', () async {
      useService(granted: true);
      await SettingsProvider().setNotificationsEnabled(true);

      final reloaded = SettingsProvider();
      await reloaded.load();

      expect(reloaded.notificationsEnabled, isTrue);
    });

    test('a refusal is not persisted as enabled', () async {
      useService(granted: false);
      await SettingsProvider().setNotificationsEnabled(true);

      final reloaded = SettingsProvider();
      await reloaded.load();

      expect(reloaded.notificationsEnabled, isFalse);
    });

    test('the font preference survives a reload', () async {
      await SettingsProvider().togglePixelFont(false);

      final reloaded = SettingsProvider();
      await reloaded.load();

      expect(reloaded.usePixelFont, isFalse);
    });

    test('load is idempotent', () async {
      final provider = SettingsProvider();
      await provider.load();
      await provider.load();

      expect(provider.isLoaded, isTrue);
    });
  });
}
