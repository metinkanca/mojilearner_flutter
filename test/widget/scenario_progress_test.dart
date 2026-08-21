import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/scenario_complete_popup.dart';
import 'package:mojilearner_flutter/components/scenario_objective_tracker.dart';
import 'package:mojilearner_flutter/constants/scenarios.dart';
import 'package:mojilearner_flutter/providers/scenario_provider.dart';
import 'package:mojilearner_flutter/screens/scenarios_screen.dart';
import 'package:mojilearner_flutter/utils/progression_utils.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSettingsProvider mockSettings;
  late ScenarioDefinition coffee;

  setUp(() {
    mockSettings = MockSettingsProvider();
    when(() => mockSettings.usePixelFont).thenReturn(true);
    coffee = ScenarioCatalog.byId('coffee')!;
  });

  /// Built synchronously and never loaded from storage — `testWidgets` runs
  /// under FakeAsync and awaiting SecureStorage would deadlock. Same reason
  /// as review_screen_test.
  ScenarioProvider buildProgress({
    List<String> cleared = const [],
    bool completed = false,
  }) {
    final provider = ScenarioProvider();
    if (completed) provider.completeRun(coffee);
    if (cleared.isNotEmpty) provider.markObjectives(coffee, cleared);
    return provider;
  }

  group('ScenariosScreen - card progress', () {
    Future<void> pumpGrid(
      WidgetTester tester,
      ScenarioProvider scenarios,
    ) async {
      tester.view.physicalSize = const Size(1200, 2700);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpApp(
        tester,
        const ScenariosScreen(),
        settingsProvider: mockSettings,
        scenarioProvider: scenarios,
      );
      await tester.pump();
    }

    testWidgets('a fresh scenario shows zero of its required objectives',
        (tester) async {
      await pumpGrid(tester, ScenarioProvider());

      expect(find.text('0/${coffee.requiredCount}'), findsWidgets);
      expect(find.text('CLEARED'), findsNothing);
    });

    testWidgets('a part-finished scenario shows its running tally',
        (tester) async {
      await pumpGrid(tester, buildProgress(cleared: ['order', 'price']));

      expect(find.text('2/${coffee.requiredCount}'), findsOneWidget);
    });

    testWidgets('a cleared scenario is stamped rather than tallied',
        (tester) async {
      await pumpGrid(tester, buildProgress(completed: true));

      expect(find.text('CLEARED'), findsOneWidget);
    });

    testWidgets('replaying a cleared scenario shows the tally again',
        (tester) async {
      await pumpGrid(
        tester,
        buildProgress(completed: true, cleared: ['order']),
      );

      expect(find.text('CLEARED'), findsNothing);
      expect(find.text('1/${coffee.requiredCount}'), findsOneWidget);
    });

    testWidgets('a bonus objective does not move the required tally',
        (tester) async {
      await pumpGrid(tester, buildProgress(cleared: ['small_talk']));

      expect(find.text('0/${coffee.requiredCount}'), findsWidgets);
    });
  });

  group('ScenarioObjectiveTracker', () {
    Future<void> pumpTracker(
      WidgetTester tester,
      ScenarioProvider scenarios,
    ) async {
      await pumpApp(
        tester,
        ScenarioObjectiveTracker(scenario: coffee),
        settingsProvider: mockSettings,
        scenarioProvider: scenarios,
      );
      await tester.pump();
    }

    testWidgets('lists every objective, bonus included', (tester) async {
      await pumpTracker(tester, ScenarioProvider());

      expect(find.text('Order a drink'), findsOneWidget);
      expect(find.text('Ask what it costs'), findsOneWidget);
      expect(find.text('Make small talk with the barista (Bonus)'),
          findsOneWidget);
    });

    testWidgets('shows the required-objective count, not the total',
        (tester) async {
      await pumpTracker(tester, ScenarioProvider());

      expect(find.text('0/${coffee.requiredCount}'), findsOneWidget);
      expect(coffee.requiredCount, lessThan(coffee.objectives.length));
    });

    testWidgets('ticks live when an objective is recorded', (tester) async {
      final scenarios = ScenarioProvider();
      await pumpTracker(tester, scenarios);

      expect(find.byIcon(Icons.check), findsNothing);

      scenarios.markObjectives(coffee, ['order']);
      await tester.pump();

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('1/${coffee.requiredCount}'), findsOneWidget);
    });

    testWidgets('collapses so it does not eat the conversation',
        (tester) async {
      await pumpTracker(tester, ScenarioProvider());

      expect(find.text('Order a drink'), findsOneWidget);

      await tester.tap(find.text('OBJECTIVES'));
      await tester.pump();

      expect(find.text('Order a drink'), findsNothing);
      expect(find.text('0/${coffee.requiredCount}'), findsOneWidget);
    });
  });

  group('ScenarioCompletePopup', () {
    Future<void> pumpPopup(
      WidgetTester tester, {
      required bool isFirstClear,
      Set<String> cleared = const {'order', 'customize', 'price'},
    }) async {
      tester.view.physicalSize = const Size(1200, 2700);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpApp(
        tester,
        ScenarioCompletePopup(
          scenario: coffee,
          clearedObjectiveIds: cleared,
          reward: ProgressionUtils.getScenarioRewardOutcome(
            bonusObjectivesCleared: cleared.contains('small_talk') ? 1 : 0,
            bonusObjectivesTotal: 1,
            isFirstClear: isFirstClear,
          ),
          grantedXp: 35,
          grantedCoins: 12,
          onContinue: () {},
        ),
        settingsProvider: mockSettings,
      );
      await tester.pump();
    }

    testWidgets('celebrates a first clear and omits the replay note',
        (tester) async {
      await pumpPopup(tester, isFirstClear: true);

      expect(find.text('FIRST CLEAR!'), findsOneWidget);
      expect(find.textContaining('first clears pay more'), findsNothing);
    });

    testWidgets('explains the smaller payout on a replay', (tester) async {
      await pumpPopup(tester, isFirstClear: false);

      expect(find.text('FIRST CLEAR!'), findsNothing);
      expect(find.textContaining('first clears pay more'), findsOneWidget);
    });

    testWidgets('tallies cleared objectives against the full list',
        (tester) async {
      await pumpPopup(tester, isFirstClear: true);

      expect(find.text('3 of ${coffee.objectives.length} objectives'),
          findsOneWidget);
    });

    testWidgets('shows the granted rewards, not the unscaled ones',
        (tester) async {
      await pumpPopup(tester, isFirstClear: true);

      expect(find.text('+35 XP'), findsOneWidget);
      expect(find.text('+12 Coins'), findsOneWidget);
    });

    testWidgets('marks an unfinished bonus objective as unchecked',
        (tester) async {
      await pumpPopup(tester, isFirstClear: true);

      // Three required cleared, the bonus left undone.
      expect(find.byIcon(Icons.check), findsNWidgets(3));
    });
  });
}
