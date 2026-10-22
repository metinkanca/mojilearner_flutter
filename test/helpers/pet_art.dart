import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/pet_art_cache.dart';

/// Lets the pet on screen finish loading, so a test can look at its layers.
///
/// A sprite draws nothing until every layer of it is read and parsed -- that is
/// the point of [PetArt] -- and reading the bundle takes real time, which a
/// widget test's clock never lets pass on its own. So: let real time pass,
/// then pump so the sprite sees what arrived. It takes more than one round,
/// because parsing only starts once the reading is done.
Future<void> settlePet(WidgetTester tester) async {
  for (var round = 0; round < 4; round++) {
    await tester.runAsync(PetArt.settled);
    await tester.pump();
  }
}
