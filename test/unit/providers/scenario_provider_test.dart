import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/scenarios.dart';
import 'package:mojilearner_flutter/models/models.dart';
import 'package:mojilearner_flutter/providers/scenario_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ScenarioProvider provider;
  late ScenarioDefinition coffee;

  setUp(() {
    provider = ScenarioProvider();
    coffee = ScenarioCatalog.byId('coffee')!;
  });

  group('ScenarioProvider - reading', () {
    test('an untouched scenario reports empty progress', () {
      final progress = provider.forScenario('coffee');

      expect(progress.scenarioId, equals('coffee'));
      expect(progress.clearedObjectiveIds, isEmpty);
      expect(progress.timesCompleted, equals(0));
      expect(progress.hasEverCompleted, isFalse);
      expect(provider.clearedRequiredCount(coffee), equals(0));
      expect(provider.isComplete(coffee), isFalse);
    });
  });

  group('ScenarioProvider.markObjectives', () {
    test('records objectives and reports which were new', () {
      final newly = provider.markObjectives(coffee, ['order']);

      expect(newly, equals({'order'}));
      expect(provider.forScenario('coffee').isCleared('order'), isTrue);
      expect(provider.clearedRequiredCount(coffee), equals(1));
    });

    test('re-reporting an objective returns nothing new', () {
      provider.markObjectives(coffee, ['order']);
      final again = provider.markObjectives(coffee, ['order']);

      expect(again, isEmpty);
      expect(provider.clearedRequiredCount(coffee), equals(1));
    });

    test('ignores ids the catalogue does not define', () {
      final newly = provider.markObjectives(
        coffee,
        ['all_done', 'order', 'definitely_not_real'],
      );

      expect(newly, equals({'order'}));
      expect(provider.forScenario('coffee').clearedObjectiveIds,
          equals({'order'}));
    });

    test('a bonus objective does not count toward required progress', () {
      provider.markObjectives(coffee, ['small_talk']);

      expect(provider.forScenario('coffee').isCleared('small_talk'), isTrue);
      expect(provider.clearedRequiredCount(coffee), equals(0));
      expect(provider.isComplete(coffee), isFalse);
    });

    test('completes once every required objective is cleared', () {
      for (final objective in coffee.required) {
        expect(provider.isComplete(coffee), isFalse);
        provider.markObjectives(coffee, [objective.id]);
      }

      expect(provider.isComplete(coffee), isTrue);
    });

    test('notifies listeners only when something actually changed', () {
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider.markObjectives(coffee, ['order']);
      expect(notifications, equals(1));

      provider.markObjectives(coffee, ['order']);
      expect(notifications, equals(1));

      provider.markObjectives(coffee, ['not_a_real_id']);
      expect(notifications, equals(1));
    });
  });

  group('ScenarioProvider.completeRun', () {
    test('the first clear is reported as such, later ones are not', () {
      expect(provider.completeRun(coffee), isTrue);
      expect(provider.completeRun(coffee), isFalse);
      expect(provider.forScenario('coffee').timesCompleted, equals(2));
    });

    test('resets the checklist so a replay starts empty', () {
      provider.markObjectives(coffee, ['order', 'price']);
      provider.completeRun(coffee);

      expect(provider.forScenario('coffee').clearedObjectiveIds, isEmpty);
      expect(provider.clearedRequiredCount(coffee), equals(0));
    });

    test('remembers the clear after the checklist resets', () {
      provider.markObjectives(coffee, ['order']);
      provider.completeRun(coffee);

      expect(provider.hasEverCompleted('coffee'), isTrue);
      expect(provider.clearedRequiredCount(coffee), equals(0));
    });

    test('keeps the original first-clear timestamp across replays', () {
      final first = DateTime(2026, 1, 1);
      final second = DateTime(2026, 6, 1);

      provider.completeRun(coffee, now: first);
      provider.completeRun(coffee, now: second);

      final progress = provider.forScenario('coffee');
      expect(progress.firstCompletedAt, equals(first));
      expect(progress.lastPlayedAt, equals(second));
    });
  });

  group('ScenarioProvider.resetRun', () {
    test('clears the current run without recording a completion', () {
      provider.markObjectives(coffee, ['order']);
      provider.resetRun('coffee');

      expect(provider.forScenario('coffee').clearedObjectiveIds, isEmpty);
      expect(provider.hasEverCompleted('coffee'), isFalse);
    });

    test('is a no-op when there is nothing to reset', () {
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider.resetRun('coffee');

      expect(notifications, equals(0));
    });
  });

  group('ScenarioProgress serialization', () {
    test('survives a JSON round trip', () {
      final original = ScenarioProgress(
        scenarioId: 'coffee',
        clearedObjectiveIds: const {'order', 'price'},
        timesCompleted: 3,
        firstCompletedAt: DateTime(2026, 1, 1),
        lastPlayedAt: DateTime(2026, 6, 1),
      );

      final restored = ScenarioProgress.fromJson(original.toJson());

      expect(restored.scenarioId, equals('coffee'));
      expect(restored.clearedObjectiveIds, equals({'order', 'price'}));
      expect(restored.timesCompleted, equals(3));
      expect(restored.firstCompletedAt, equals(DateTime(2026, 1, 1)));
      expect(restored.lastPlayedAt, equals(DateTime(2026, 6, 1)));
    });

    test('tolerates a payload missing the optional fields', () {
      final restored = ScenarioProgress.fromJson({'scenarioId': 'coffee'});

      expect(restored.clearedObjectiveIds, isEmpty);
      expect(restored.timesCompleted, equals(0));
      expect(restored.firstCompletedAt, isNull);
      expect(restored.lastPlayedAt, isNull);
    });
  });

  group('ScenarioCatalog', () {
    test('every scenario has required objectives and exactly one bonus', () {
      for (final scenario in ScenarioCatalog.all) {
        expect(scenario.requiredCount, greaterThan(0),
            reason: '${scenario.id} has no required objectives');
        expect(scenario.objectives.where((o) => o.isBonus), hasLength(1),
            reason: '${scenario.id} should have one bonus objective');
      }
    });

    test('objective ids are unique within each scenario', () {
      for (final scenario in ScenarioCatalog.all) {
        final ids = scenario.objectives.map((o) => o.id).toList();
        expect(ids.toSet(), hasLength(ids.length),
            reason: '${scenario.id} has duplicate objective ids');
      }
    });

    test('scenario ids are unique', () {
      final ids = ScenarioCatalog.all.map((s) => s.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('byId resolves known ids and rejects everything else', () {
      expect(ScenarioCatalog.byId('coffee')?.id, equals('coffee'));
      expect(ScenarioCatalog.byId('nope'), isNull);
      expect(ScenarioCatalog.byId(null), isNull);
    });
  });
}
