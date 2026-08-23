import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/screens/profile_screen.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';
import '../helpers/test_fixtures.dart';

/// The two language dropdowns in the profile's settings.
///
/// A DropdownButtonFormField is dense by default, which pins the closed button
/// to a 24pt box — shorter than the line it holds, so "English" lost the tail
/// of its g and the taller scripts lost more than that. And a dropdown lays
/// every option out at the closed button's width, so the longest name in the
/// catalogue used to decide how wide that button was and pushed the arrow off
/// the card.
void main() {
  late MockUserProvider user;
  late MockCharacterProvider character;
  late MockLanguageProvider language;
  late MockSettingsProvider settings;

  setUp(() {
    user = MockUserProvider();
    when(() => user.stats).thenReturn(TestFixtures.buildUserStats(
      level: 3,
      totalXP: 300,
      currentLevelXP: 20,
      nextLevelXP: 100,
      coins: 40,
      streak: 2,
      progress: 0.2,
    ));
    when(() => user.isLoading).thenReturn(false);

    character = MockCharacterProvider();
    when(() => character.currentCharacterAsset)
        .thenReturn('assets/svgs/cat.svg');
    when(() => character.customization)
        .thenReturn(TestFixtures.buildCustomization());
    when(() => character.hunger).thenReturn(80);
    when(() => character.happiness).thenReturn(80);
    when(() => character.health).thenReturn(100);

    language = MockLanguageProvider();
    when(() => language.nativeLanguage)
        .thenReturn(const Language(code: 'en', name: 'English'));
    when(() => language.targetLanguage)
        .thenReturn(const Language(code: 'es', name: 'Spanish'));
    when(() => language.availableLanguages).thenReturn(const [
      Language(code: 'en', name: 'English'),
      Language(code: 'es', name: 'Spanish'),
      Language(code: 'ja', name: 'Japanese'),
      Language(code: 'ko', name: 'Korean'),
      // The longest name the catalogue holds, and the one that used to run
      // off the side of a row it was not even in yet.
      Language(code: 'id', name: 'Indonesian'),
    ]);

    settings = MockSettingsProvider();
    when(() => settings.usePixelFont).thenReturn(true);
  });

  Future<void> pumpProfile(WidgetTester tester) async {
    await pumpApp(
      tester,
      const ProfileScreen(),
      userProvider: user,
      characterProvider: character,
      languageProvider: language,
      settingsProvider: settings,
      surfaceSize: const Size(400, 900),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('every option fits the row it is laid out in', (tester) async {
    await pumpProfile(tester);
    // A RenderFlex overflow fails the test on its own; this says so out loud.
    expect(tester.takeException(), isNull);
  });

  testWidgets('the selected language is drawn at its full height',
      (tester) async {
    await pumpProfile(tester);

    final name = find.text('English');
    expect(name, findsWidgets, reason: 'the selected language is not shown');

    final size = tester.getSize(name.first);
    final style = tester.widget<Text>(name.first).style!;
    // Taller than the em it is set in — a box clamped to the dense 24pt
    // button would cut the descenders off instead.
    expect(size.height, greaterThan(style.fontSize!),
        reason: 'the name is being clipped to a box shorter than its line');
  });
}
