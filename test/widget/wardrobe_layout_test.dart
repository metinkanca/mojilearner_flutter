import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/constants/accessories.dart';
import 'package:mojilearner_flutter/constants/bond.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:mojilearner_flutter/screens/wardrobe_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('equipping an accessory does not shift the panels below',
      (tester) async {
    final character = CharacterProvider();
    final settings = MockSettingsProvider();
    final user = MockUserProvider();
    when(() => settings.usePixelFont).thenReturn(true);
    // The shelves price every locked tile, so they need a balance to compare
    // against even when the test is only about layout.
    when(() => user.coins).thenReturn(0);

    await pumpApp(
      tester,
      const WardrobeScreen(),
      characterProvider: character,
      settingsProvider: settings,
      userProvider: user,
      // Handset width, but tall enough that every shelf lays out without
      // scrolling — the assertions compare positions across sections.
      surfaceSize: Size(kHandsetSurface.width, 2400),
    );
    // The pet sprite animates continuously, so settle with bounded pumps.
    await tester.pump(const Duration(milliseconds: 100));

    // A section below the hat shelf — its position must not move.
    final neckSection = find.text('NECK');
    expect(neckSection, findsOneWidget);
    final before = tester.getTopLeft(neckSection);

    // Equip the first hat — the free starter, so no purchase is involved.
    final hat = accessoriesForSlot(AccessorySlots.hat).first;
    expect(hat.isFreeStarter, isTrue);
    character.equipAccessory(hat.id, stage: PetStage.curious);
    await tester.pump(const Duration(milliseconds: 100));

    expect(character.equippedInSlot(AccessorySlots.hat), equals(hat.id));
    expect(
      tester.getTopLeft(neckSection),
      equals(before),
      reason: 'equipping must not reflow the panels below it',
    );

    // Tear the tree down and stop the provider's periodic decay timer before
    // the test framework's pending-timer check runs.
    await tester.pumpWidget(const SizedBox.shrink());
    character.dispose();
  });
}
