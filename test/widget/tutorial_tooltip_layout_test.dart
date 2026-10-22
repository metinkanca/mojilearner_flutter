import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/tutorial/retro_showcase.dart';
import 'package:mojilearner_flutter/components/tutorial/tutorial_offer_host.dart';
import 'package:mojilearner_flutter/components/tutorial/tutorial_scope.dart';
import 'package:mojilearner_flutter/constants/tutorials.dart';
import 'package:mojilearner_flutter/l10n/app_localizations.dart';
import 'package:mojilearner_flutter/providers/tutorial_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// The coach mark is a narrow card with three buttons along the bottom, and
/// every one of those buttons translates. German's "ÜBERSPRINGEN" is three
/// times the width of "SKIP", and the card is only wide enough for so much —
/// so the card has to be able to take the longest locale on the narrowest
/// phone without a RenderFlex overflow, which fails these tests on its own.
///
/// The offer dialog underneath it has the same exposure, and is checked here
/// for the same reason.
void main() {
  const handset = Size(400, 844);

  /// The scripts that stretch this layout: long compounds, and the two the
  /// pixel faces draw widest.
  const locales = [
    Locale('de'),
    Locale('hu'),
    Locale('ro'),
    Locale('fi'),
    Locale('ja'),
    Locale('ru'),
    Locale('ar'),
  ];

  late MockSettingsProvider settings;
  final stepKey = GlobalKey();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    settings = MockSettingsProvider();
    when(() => settings.usePixelFont).thenReturn(true);
  });

  Future<TutorialProvider> pumpTour(WidgetTester tester, Locale locale) async {
    final tutorials = TutorialProvider();
    await tutorials.load();

    await pumpApp(
      tester,
      TutorialScope(
        child: TutorialOfferHost(
          id: TutorialId.home,
          steps: () => [stepKey],
          child: Center(
            child: RetroShowcase(
              showcaseKey: stepKey,
              // The longest step copy in the catalogue, so the card is
              // measured at its worst rather than its average.
              description: lookupAppLocalizations(locale).tutorialReviewGrades,
              isLast: true,
              child: const SizedBox(width: 48, height: 48),
            ),
          ),
        ),
      ),
      tutorialProvider: tutorials,
      settingsProvider: settings,
      userProvider: MockUserProvider(),
      locale: locale,
      surfaceSize: handset,
    );
    await tester.pumpAndSettle();
    return tutorials;
  }

  for (final locale in locales) {
    final code = locale.languageCode;

    testWidgets('the offer dialog fits a handset in $code', (tester) async {
      await pumpTour(tester, locale);

      final l10n = lookupAppLocalizations(locale);
      expect(find.text(l10n.tutorialOfferHome), findsOneWidget);
      expect(find.text(l10n.tutorialWatch), findsOneWidget);

      // Nothing may run off the side of the phone.
      for (final label in [l10n.tutorialWatch, l10n.tutorialSkip]) {
        expect(tester.getRect(find.text(label)).right,
            lessThanOrEqualTo(handset.width),
            reason: '$code: $label');
      }
    });

    testWidgets('the coach mark fits a handset in $code', (tester) async {
      final l10n = lookupAppLocalizations(locale);
      await pumpTour(tester, locale);

      await tester.tap(find.text(l10n.tutorialWatch));
      await tester.pumpAndSettle();

      expect(find.text(l10n.tutorialReviewGrades), findsOneWidget);

      // The three buttons: SKIP on one side, BACK and DONE on the other.
      for (final label in [l10n.tutorialSkip, l10n.tutorialDone]) {
        final rect = tester.getRect(find.text(label));
        expect(rect.left, greaterThanOrEqualTo(0), reason: '$code: $label');
        expect(rect.right, lessThanOrEqualTo(handset.width),
            reason: '$code: $label');
      }

      await tester.tap(find.text(l10n.tutorialDone));
      await tester.pumpAndSettle();
    });
  }
}
