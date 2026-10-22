import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/home_action_bar.dart';
import 'package:mojilearner_flutter/components/play/toy_chest.dart';

import '../helpers/pump_app.dart';

/// The row of big buttons under the home scene.
void main() {
  late int toys;
  late int mistakes;
  late int climb;

  setUp(() {
    toys = 0;
    mistakes = 0;
    climb = 0;
  });

  Future<void> pumpBar(
    WidgetTester tester, {
    bool canPlay = true,
    bool withClimb = false,
  }) {
    return pumpApp(
      tester,
      Scaffold(
        body: HomeActionBar(
          canPlay: canPlay,
          onToys: () => toys++,
          onMistakes: () => mistakes++,
          onClimb: withClimb ? () => climb++ : null,
        ),
      ),
    );
  }

  testWidgets('each button does its own thing', (tester) async {
    await pumpBar(tester, withClimb: true);

    await tester.tap(find.byKey(HomeActionBar.toysKey));
    await tester.tap(find.byKey(HomeActionBar.mistakesKey));
    await tester.tap(find.byKey(HomeActionBar.mistakesKey));
    await tester.tap(find.byKey(HomeActionBar.climbKey));

    expect([toys, mistakes, climb], [1, 2, 1]);
  });

  testWidgets('the chest itself is a tap target too', (tester) async {
    await pumpBar(tester);

    await tester.tap(find.byType(ToyChest));

    expect(toys, 1);
  });

  testWidgets('no climb callback, no climb button', (tester) async {
    await pumpBar(tester);

    expect(find.byKey(HomeActionBar.climbKey), findsNothing);
    expect(find.byKey(HomeActionBar.mistakesKey), findsOneWidget);
  });

  testWidgets('a sleeping pet leaves the chest shut, but the rest work',
      (tester) async {
    await pumpBar(tester, canPlay: false);

    await tester.tap(find.byKey(HomeActionBar.toysKey));
    await tester.tap(find.byType(ToyChest));
    await tester.tap(find.byKey(HomeActionBar.mistakesKey));

    expect([toys, mistakes], [0, 1]);
  });

  testWidgets('the buttons are the size the layout was built around',
      (tester) async {
    await pumpBar(tester, withClimb: true);

    for (final key in [
      HomeActionBar.toysKey,
      HomeActionBar.mistakesKey,
      HomeActionBar.climbKey,
    ]) {
      final rect = tester.getRect(find.byKey(key));
      // The 3pt border is inside the square; the icons must fit within it.
      expect(rect.size, const Size.square(HomeActionBar.buttonSize));
    }
  });
}
