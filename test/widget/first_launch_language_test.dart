import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/l10n/app_localizations.dart';
import 'package:mojilearner_flutter/components/character_carousel.dart';
import 'package:mojilearner_flutter/screens/onboarding/first_launch/retro_button.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/screens/onboarding/first_launch/language_panel.dart';
import 'package:mojilearner_flutter/screens/onboarding/first_launch_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// The opening screen picks the UI language before the app has one, so the
/// question and the button are written in whichever language is on offer
/// rather than in the app's current locale.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSettingsProvider mockSettings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockSettings = MockSettingsProvider();
    when(() => mockSettings.usePixelFont).thenReturn(true);
  });

  /// The pet sprites animate continuously, so nothing here ever settles —
  /// every wait is a bounded pump.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  String question(String code) =>
      lookupAppLocalizations(Locale(code)).onboardingLanguageQuestion;

  Future<LanguageProvider> pumpFirstLaunch(WidgetTester tester) async {
    final character = CharacterProvider(startDecayTimer: false);
    final language = LanguageProvider();

    await pumpApp(
      tester,
      const FirstLaunchScreen(),
      characterProvider: character,
      languageProvider: language,
      settingsProvider: mockSettings,
    );
    await settle(tester);

    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      character.dispose();
      language.dispose();
    });
    return language;
  }

  testWidgets('every language the app ships can be picked', (tester) async {
    final language = await pumpFirstLaunch(tester);

    // The screen this replaced carried its own hardcoded list, which had
    // drifted from the catalogue and left four translated languages with no
    // way to reach them. Naming them keeps that from silently coming back.
    for (final name in ['Indonesian', 'Ukrainian', 'Romanian', 'Hungarian']) {
      await tester.scrollUntilVisible(
        find.text(name),
        120,
        scrollable: find.descendant(
          of: find.byKey(languageListKey),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text(name), findsOneWidget, reason: '$name is unreachable');
    }

    expect(language.availableLanguages.length, 27);
  });

  testWidgets('the question cycles through languages until one is picked',
      (tester) async {
    await pumpFirstLaunch(tester);

    // Whichever language the loop is on, it must not still be on it after a
    // full interval.
    final first = tester.widget<Text>(
      find.byWidgetPredicate(
        (w) => w is Text && w.key is ValueKey<String>,
      ),
    );

    await tester.pump(FirstLaunchScreen.cycleInterval);
    await settle(tester);

    final second = tester.widget<Text>(
      find.byWidgetPredicate(
        (w) => w is Text && w.key is ValueKey<String>,
      ),
    );

    expect(second.data, isNot(equals(first.data)));
  });

  testWidgets('tapping a language locks the question to it', (tester) async {
    await pumpFirstLaunch(tester);

    await tester.tap(find.text('Spanish'));
    await settle(tester);

    expect(find.text(question('es')), findsOneWidget);

    // The attract loop has to actually stop, not just skip a turn.
    await tester.pump(FirstLaunchScreen.cycleInterval * 3);
    await settle(tester);

    expect(find.text(question('es')), findsOneWidget);
  });

  testWidgets('the language is not adopted until it is confirmed',
      (tester) async {
    final language = await pumpFirstLaunch(tester);
    final before = language.nativeLanguage.code;

    await tester.tap(find.text('Spanish'));
    await settle(tester);

    // Tapping the row shows the language; it does not commit it.
    expect(language.nativeLanguage.code, before);

    await tester.tap(find.text(
      lookupAppLocalizations(const Locale('es')).onboardingLanguageConfirm,
    ));
    await settle(tester);

    expect(language.nativeLanguage.code, 'es');
  });

  testWidgets('confirming moves on to choosing a pet', (tester) async {
    await pumpFirstLaunch(tester);

    await tester.tap(find.text('Spanish'));
    await settle(tester);
    await tester.tap(find.text(
      lookupAppLocalizations(const Locale('es')).onboardingLanguageConfirm,
    ));
    await settle(tester);

    expect(
      find.text(
        lookupAppLocalizations(const Locale('es')).onboardingPetQuestion,
      ),
      findsOneWidget,
    );
  });

  /// Walks past the language step so the pets are what is being chosen.
  Future<void> reachPetPhase(WidgetTester tester) async {
    await tester.tap(find.text('Spanish'));
    await settle(tester);
    await tester.tap(find.text(
      lookupAppLocalizations(const Locale('es')).onboardingLanguageConfirm,
    ));
    await settle(tester);
  }

  testWidgets('all three pets are whole and clear of each other once chosen',
      (tester) async {
    await pumpFirstLaunch(tester);
    await reachPetPhase(tester);

    final rects = [
      for (var i = 0; i < 3; i++)
        tester.getRect(find.byType(CharacterTile).at(i)),
    ];

    // Nothing runs off either edge: all three are on screen whole, rather
    // than the outer two being clipped as the in-app pet-changer shows them.
    for (final rect in rects) {
      expect(rect.left, greaterThanOrEqualTo(0.0));
      expect(rect.right, lessThanOrEqualTo(kHandsetSurface.width));
    }

    // And the enlarged centre still clears its neighbours.
    expect(rects[0].right, lessThan(rects[1].left));
    expect(rects[1].right, lessThan(rects[2].left));
  });

  testWidgets('the pets are drawn bare, with no card and no caption',
      (tester) async {
    await pumpFirstLaunch(tester);
    await reachPetPhase(tester);

    final spanish = lookupAppLocalizations(const Locale('es'));
    for (final label in [
      spanish.characterDog,
      spanish.characterCat,
      spanish.characterBird,
    ]) {
      expect(find.text(label), findsNothing, reason: '$label is captioned');
    }

    expect(
      tester.widgetList<CharacterTile>(find.byType(CharacterTile)),
      everyElement(isA<CharacterTile>().having((t) => t.framed, 'framed', false)),
    );
  });

  testWidgets('the first screen is a plain row, not a rank', (tester) async {
    await pumpFirstLaunch(tester);

    final rects = [
      for (var i = 0; i < 3; i++)
        tester.getRect(find.byType(CharacterTile).at(i)),
    ];

    // Every pet the same size: no singled-out centre before the pets are
    // what is being chosen.
    expect(rects[0].width, closeTo(rects[1].width, 0.5));
    expect(rects[1].width, closeTo(rects[2].width, 0.5));

    // All three whole, side by side, none clipped by either edge.
    for (final rect in rects) {
      expect(rect.left, greaterThanOrEqualTo(0.0));
      expect(rect.right, lessThanOrEqualTo(kHandsetSurface.width));
    }
    expect(rects[0].right, lessThan(rects[1].left));
    expect(rects[1].right, lessThan(rects[2].left));
  });

  testWidgets('the position dots only arrive with the rank', (tester) async {
    await pumpFirstLaunch(tester);

    Opacity dots() => tester.widget<Opacity>(
          find.ancestor(
            of: find.byType(Row).last,
            matching: find.byType(Opacity),
          ).first,
        );

    // Hidden on the language step — there is no rank to be a position in.
    expect(dots().opacity, 0.0);

    await tester.tap(find.text('Spanish'));
    await settle(tester);
    await tester.tap(find.text(
      lookupAppLocalizations(const Locale('es')).onboardingLanguageConfirm,
    ));
    await settle(tester);

    expect(dots().opacity, 1.0);
  });

  testWidgets('there is nothing to confirm until a language is picked',
      (tester) async {
    await pumpFirstLaunch(tester);

    // The button is absent, not merely disabled: it has never been usable,
    // and a greyed control reads as something broken.
    expect(find.byType(RetroButton), findsNothing);

    await tester.tap(find.text('Spanish'));
    await settle(tester);

    expect(find.byType(RetroButton), findsOneWidget);
    expect(
      find.text(
        lookupAppLocalizations(const Locale('es')).onboardingLanguageConfirm,
      ),
      findsOneWidget,
    );
  });

  testWidgets('the opening lays out without overflowing a handset',
      (tester) async {
    await pumpFirstLaunch(tester);
    expect(tester.takeException(), isNull);
  });
}
