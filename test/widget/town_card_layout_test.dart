import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/scenario_city.dart';
import 'package:mojilearner_flutter/constants/scenarios.dart';
import 'package:mojilearner_flutter/l10n/app_localizations.dart';
import 'package:mojilearner_flutter/providers/scenario_provider.dart';
import 'package:mojilearner_flutter/screens/scenarios_screen.dart';
import 'package:mojilearner_flutter/utils/pet_recolor.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// The card at the foot of the town, on a small phone, in every language: it
/// has to fit, and it has to stay low enough that the gazebo at the bottom of
/// the map is not behind it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSettingsProvider settings;
  late MockCharacterProvider character;

  setUp(() {
    settings = MockSettingsProvider();
    when(() => settings.usePixelFont).thenReturn(true);
    character = MockCharacterProvider();
    when(() => character.currentCharacterType).thenReturn('cat');
    when(() => character.currentCharacterAsset)
        .thenReturn('assets/svgs/cat.svg');
    when(() => character.colorSpecFor(any())).thenReturn(const PetColorSpec(
      bodyColor: '#959379',
      eyeMode: EyeMode.solid,
      eyeColor1: '#F4C430',
      eyeColor2: '#5AA0E0',
    ));
    when(() => character.equippedAccessoriesFor(any())).thenReturn(const []);
  });

  Future<void> pumpTown(WidgetTester tester, Locale locale) async {
    // 357 x 718 logical points: the phone the owner tests on.
    tester.view.physicalSize = const Size(357 * 3, 718 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(
      tester,
      const ScenariosScreen(),
      settingsProvider: settings,
      characterProvider: character,
      scenarioProvider: ScenarioProvider(),
      locale: locale,
    );
    await tester.pump();
  }

  void pick(WidgetTester tester, ScenarioDefinition scenario) {
    tester
        .widget<CityBuilding>(find.byWidgetPredicate(
            (w) => w is CityBuilding && w.scenario?.id == scenario.id))
        .onTap();
  }

  testWidgets('every place\'s card fits a small phone in every language',
      (tester) async {
    for (final locale in AppLocalizations.supportedLocales) {
      await pumpTown(tester, locale);
      for (final scenario in ScenarioCatalog.all) {
        pick(tester, scenario);
        await tester.pump();

        expect(tester.takeException(), isNull,
            reason: '${locale.languageCode} ${scenario.id}');
        // Two short lines at most: the card hides little of the town.
        final card = tester.getRect(find.byKey(const ValueKey('place-card')));
        expect(card.height, lessThanOrEqualTo(88),
            reason: '${locale.languageCode} ${scenario.id}');
      }
    }
  });
}
