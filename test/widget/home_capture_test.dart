import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/constants/accessories.dart';
import 'package:mojilearner_flutter/constants/pets.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/screens/home_screen.dart';
import 'package:mojilearner_flutter/utils/pet_recolor.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';
import '../helpers/test_fixtures.dart';

class MockVocabProvider extends Mock implements VocabProvider {}

/// A camera on the home screen, the same idea as
/// `pet_render_capture_test.dart` but pointed at the whole scene: pet size
/// against the world it stands in, and the cast shadow landing on the actual
/// ground rather than a test swatch.
///
/// Skipped unless told where to write:
///
///     flutter test test/widget/home_capture_test.dart \
///         --dart-define=CAPTURE_DIR=<somewhere>
void main() {
  const dir = String.fromEnvironment('CAPTURE_DIR');

  late MockUserProvider mockUser;
  late MockDailyRewardProvider mockDailyReward;
  late MockCharacterProvider mockCharacter;
  late MockLanguageProvider mockLanguage;
  late MockSettingsProvider mockSettings;
  late MockVocabProvider mockVocab;

  setUp(() {
    mockUser = MockUserProvider();
    mockDailyReward = MockDailyRewardProvider();
    mockCharacter = MockCharacterProvider();
    mockLanguage = MockLanguageProvider();
    mockSettings = MockSettingsProvider();
    mockVocab = MockVocabProvider();

    when(() => mockUser.stats).thenReturn(TestFixtures.buildUserStats());
    when(() => mockUser.isLoading).thenReturn(false);
    when(() => mockDailyReward.checkDailyReward()).thenAnswer((_) async => null);
    when(() => mockDailyReward.pendingDailyReward).thenReturn(null);
    when(() => mockCharacter.hunger).thenReturn(90);
    when(() => mockCharacter.happiness).thenReturn(90);
    when(() => mockCharacter.health).thenReturn(100);
    when(() => mockCharacter.inventory).thenReturn(const []);
    when(() => mockCharacter.isSleeping).thenReturn(false);
    when(() => mockCharacter.isTemporarilyAwake).thenReturn(false);
    when(() => mockCharacter.isSleepingForNight).thenReturn(false);
    when(() => mockCharacter.awakeUntil).thenReturn(null);
    when(() => mockLanguage.targetLanguage)
        .thenReturn(const Language(code: 'es', name: 'Spanish'));
    when(() => mockSettings.usePixelFont).thenReturn(true);
    when(() => mockVocab.dueCount(languageCode: any(named: 'languageCode')))
        .thenReturn(0);
  });

  Future<void> shoot(WidgetTester tester, String type,
      {List<AccessoryDef> wearing = const []}) async {
    when(() => mockCharacter.currentCharacterType).thenReturn(type);
    when(() => mockCharacter.currentCharacterAsset)
        .thenReturn('assets/svgs/$type.svg');
    when(() => mockCharacter.colorSpecFor(any())).thenReturn(const PetColorSpec(
      bodyColor: '#959379',
      eyeMode: EyeMode.solid,
      eyeColor1: '#F4C430',
      eyeColor2: '#5AA0E0',
    ));
    when(() => mockCharacter.equippedAccessoriesFor(any())).thenReturn(wearing);

    await pumpApp(
      tester,
      HomeScreen(key: UniqueKey()),
      userProvider: mockUser,
      dailyRewardProvider: mockDailyReward,
      characterProvider: mockCharacter,
      languageProvider: mockLanguage,
      settingsProvider: mockSettings,
      vocabProvider: mockVocab,
    );
    // The pet walks in, so give the arrival time to land before the shutter.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }

    await tester.runAsync(() async {
      final repaint =
          _firstBoundary(tester.binding.rootElement!.findRenderObject()!)!;
      final image = await repaint.toImage(pixelRatio: 2);
      final png = await image.toByteData(format: ImageByteFormat.png);
      final suffix = wearing.isEmpty ? 'plain' : 'dressed';
      File('$dir/home_${type}_$suffix.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    });
    await tester.pumpWidget(const SizedBox.shrink());
  }

  testWidgets('draw the home screen for every pet', (tester) async {
    final wearing = [accessoryById('tophat')!, accessoryById('collar')!];
    for (final type in kPetTypes) {
      await shoot(tester, type);
      await shoot(tester, type, wearing: wearing);
    }
  }, skip: dir.isEmpty);
}

/// The nearest repaint boundary at or under [node] — the render view itself on
/// a test binding, which is what holds the whole surface.
RenderRepaintBoundary? _firstBoundary(RenderObject node) {
  if (node is RenderRepaintBoundary) return node;
  RenderRepaintBoundary? found;
  node.visitChildren((child) {
    found ??= _firstBoundary(child);
  });
  return found;
}
