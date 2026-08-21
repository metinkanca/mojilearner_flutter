import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/notification_scheduler.dart';
import 'package:mojilearner_flutter/l10n/app_localizations.dart';
import 'package:mojilearner_flutter/l10n/app_localizations_en.dart';
import 'package:mojilearner_flutter/utils/notification_planner.dart';

void main() {
  final AppLocalizations l10n = AppLocalizationsEn();

  Map<NotificationKind, NotificationCopyForTest> copy({
    required int hunger,
    required int happiness,
    int dueReviewCount = 1,
  }) {
    final built = NotificationScheduler.buildCopy(
      l10n: l10n,
      hunger: hunger,
      happiness: happiness,
      dueReviewCount: dueReviewCount,
    );
    return built.map(
      (kind, value) => MapEntry(
        kind,
        NotificationCopyForTest(value.title, value.body),
      ),
    );
  }

  group('notification copy - pet', () {
    test('leads with hunger when the pet is hungrier than it is sad', () {
      // Hunger 15 past critical, happiness only 5 past low.
      final text = copy(hunger: 95, happiness: 25)[
          NotificationKind.petNeedsCare]!;

      expect(text.title, equals(l10n.notifPetHungryTitle));
      expect(text.body, equals(l10n.notifPetHungryBody));
    });

    test('leads with loneliness when that is the worse problem', () {
      // Happiness 30 past low, hunger nowhere near critical.
      final text =
          copy(hunger: 40, happiness: 0)[NotificationKind.petNeedsCare]!;

      expect(text.title, equals(l10n.notifPetSadTitle));
      expect(text.body, equals(l10n.notifPetSadBody));
    });

    test('a healthy pet still gets a message, since one is scheduled', () {
      final text =
          copy(hunger: 10, happiness: 90)[NotificationKind.petNeedsCare]!;

      expect(text.title, isNotEmpty);
      expect(text.body, isNotEmpty);
    });
  });

  group('notification copy - reviews', () {
    test('uses the singular for one word', () {
      final text =
          copy(hunger: 50, happiness: 50, dueReviewCount: 1)[
              NotificationKind.reviewDue]!;

      expect(text.body, contains('1 word is'));
    });

    test('uses the plural for several', () {
      final text =
          copy(hunger: 50, happiness: 50, dueReviewCount: 7)[
              NotificationKind.reviewDue]!;

      expect(text.body, contains('7 words are'));
    });
  });

  group('notification copy - coverage', () {
    test('every scheduled kind has copy, so none is silently dropped', () {
      final built = copy(hunger: 50, happiness: 50);

      for (final kind in NotificationKind.values) {
        expect(built[kind], isNotNull, reason: 'no copy for $kind');
        expect(built[kind]!.title, isNotEmpty);
        expect(built[kind]!.body, isNotEmpty);
      }
    });
  });
}

/// Plain holder so the assertions don't depend on the service type.
class NotificationCopyForTest {
  const NotificationCopyForTest(this.title, this.body);
  final String title;
  final String body;
}
