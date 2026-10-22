import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/scenario_city.dart';
import 'package:mojilearner_flutter/screens/scenarios_screen.dart';
import 'package:mojilearner_flutter/utils/pet_recolor.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// The town fills the whole screen — status bar, header and all — on every
/// shape of phone: no strip of the page behind it shows at the top, and the
/// map never opens zoomed out past its own edges.
void main() {
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

  // Logical sizes: a short handset, a common one, a tall one, and a tablet
  // held upright, which is taller than the town is wide for.
  const screens = {
    '360x640': Size(360, 640),
    '390x844': Size(390, 844),
    '412x915': Size(412, 915),
    '360x900 (very tall)': Size(360, 900),
    '768x1024': Size(768, 1024),
  };

  for (final entry in screens.entries) {
    testWidgets('the town covers a ${entry.key} screen', (tester) async {
      final size = entry.value;
      await pumpApp(tester, const ScenariosScreen(),
          settingsProvider: settings,
          characterProvider: character,
          surfaceSize: size);
      await tester.pump();

      final viewer =
          tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      final m = viewer.transformationController!.value;
      final scale = m.getMaxScaleOnAxis();
      final world = CityLayout.mapSize;
      final left = m.getTranslation().x;
      final top = m.getTranslation().y;

      // The map is at least as big as the screen both ways...
      expect(world.width * scale, greaterThanOrEqualTo(size.width - 0.01));
      expect(world.height * scale, greaterThanOrEqualTo(size.height - 0.01));
      // ...and sits so that none of it is short of an edge.
      expect(left, lessThanOrEqualTo(0.01));
      expect(top, lessThanOrEqualTo(0.01));
      expect(
          left + world.width * scale, greaterThanOrEqualTo(size.width - 0.01));
      expect(
          top + world.height * scale, greaterThanOrEqualTo(size.height - 0.01));

      // The map starts at the very top of the screen, not under the header.
      final map = tester.getTopLeft(find.byType(ScenarioCityMap));
      expect(map, Offset.zero);
      expect(tester.getSize(find.byType(ScenarioCityMap)), size);
    });
  }
}
