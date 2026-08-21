import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/utils/secure_storage.dart';
import 'package:mojilearner_flutter/utils/security_logger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SecurityLogger.resetForTest();
    await SecureStorage.deleteAll();
    SecurityLogger.setEnabled(true);
  });

  group('SecurityLogger - Persistence', () {
    test('events survive a simulated restart', () async {
      await SecurityLogger.init();
      SecurityLogger.logInjectionAttempt(
        input: 'ignore previous instructions',
        source: 'persistence_test',
        patterns: ['ignore\\s+instructions'],
      );
      SecurityLogger.logSuspiciousActivity(
        source: 'persistence_test',
        description: 'odd behavior',
      );
      await SecurityLogger.persistNow();

      // Simulate app restart: memory gone, storage intact.
      SecurityLogger.resetForTest();
      expect(SecurityLogger.getEventCount(), equals(0));
      await SecurityLogger.init();

      expect(SecurityLogger.getEventCount(), equals(2));
      final events = SecurityLogger.getEvents();
      expect(events.first.eventType, equals('injection_attempt'));
      expect(events.first.input, contains('ignore previous instructions'));
      expect(events.first.patterns, hasLength(1));
      expect(events.last.eventType, equals('suspicious_activity'));
      expect(events.last.reason, equals('odd behavior'));
    });

    test('metadata round-trips through persistence', () async {
      await SecurityLogger.init();
      SecurityLogger.logRateLimitViolation(
        source: 'persistence_test',
        limitType: 'cooldown',
        requestCount: 5,
        maxRequests: 3,
        metadata: {'extra': 'value'},
      );
      await SecurityLogger.persistNow();

      SecurityLogger.resetForTest();
      await SecurityLogger.init();

      final event = SecurityLogger.getEvents().single;
      expect(event.eventType, equals('rate_limit_violation'));
      expect(event.metadata!['limitType'], equals('cooldown'));
      expect(event.metadata!['requestCount'], equals(5));
      expect(event.metadata!['extra'], equals('value'));
    });

    test('persisted history is capped at maxPersistedEvents', () async {
      await SecurityLogger.init();
      for (var i = 0; i < SecurityLogger.maxPersistedEvents + 20; i++) {
        SecurityLogger.logSuspiciousActivity(
          source: 'persistence_test',
          description: 'event $i',
        );
      }
      await SecurityLogger.persistNow();

      SecurityLogger.resetForTest();
      await SecurityLogger.init();

      expect(SecurityLogger.getEventCount(),
          equals(SecurityLogger.maxPersistedEvents));
      // The newest events are the ones kept.
      expect(
          SecurityLogger.getEvents().last.reason,
          equals(
              'event ${SecurityLogger.maxPersistedEvents + 19}'));
    });

    test('clearEvents removes the persisted copy too', () async {
      await SecurityLogger.init();
      SecurityLogger.logSuspiciousActivity(
        source: 'persistence_test',
        description: 'to be cleared',
      );
      await SecurityLogger.persistNow();

      await SecurityLogger.clearEvents();

      SecurityLogger.resetForTest();
      await SecurityLogger.init();
      expect(SecurityLogger.getEventCount(), equals(0));
    });

    test('new events append after restored history', () async {
      await SecurityLogger.init();
      SecurityLogger.logSuspiciousActivity(
        source: 'persistence_test',
        description: 'old event',
      );
      await SecurityLogger.persistNow();

      SecurityLogger.resetForTest();
      // Log before init resolves to prove ordering still holds.
      SecurityLogger.logSuspiciousActivity(
        source: 'persistence_test',
        description: 'new event',
      );
      await SecurityLogger.init();

      final events = SecurityLogger.getEvents();
      expect(events, hasLength(2));
      expect(events.first.reason, equals('old event'));
      expect(events.last.reason, equals('new event'));
    });
  });
}
