import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/daily_rewards_dialog.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';
import '../helpers/test_fixtures.dart';

/// The seven-day streak calendar lays out seven fixed 32pt markers in one
/// un-wrapping [Row]. Every other dialog test pumps the default 800x600 test
/// surface, wider than any phone, so the row was never exercised — on a real
/// 400pt handset it ran 16px past the dialog edge.
///
/// Two things are asserted, because fixing only the first is how the markers
/// end up unreadable instead of overflowing: a RenderFlex overflow fails the
/// test on its own, and every marker is then checked for still being big
/// enough to read the reward inside it.
///
/// The markers used to carry day numbers, and this file checked those labels
/// for having been ellipsed. They draw the day's reward now, so what is
/// measured is the marker itself.
void main() {
  const handset = Size(400, 844);

  /// Below this a marker is a coloured speck: its 2-3pt border eats the frame
  /// and the sprite inside has nothing left. The tightest supported handset
  /// leaves about 21pt, so real layouts clear this with room to spare.
  const minReadableMarker = 18.0;

  late MockSettingsProvider mockSettings;
  late MockLanguageProvider mockLanguage;

  setUp(() {
    mockSettings = MockSettingsProvider();
    mockLanguage = MockLanguageProvider();
    when(() => mockSettings.usePixelFont).thenReturn(true);
  });

  Future<void> pumpDialog(
    WidgetTester tester, {
    required int dayNumber,
    Locale? locale,
    Size size = handset,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpApp(
      tester,
      DailyRewardsDialog(
        rewardInfo: TestFixtures.createTestReward(dayNumber: dayNumber),
        onClaim: () {},
      ),
      settingsProvider: mockSettings,
      languageProvider: mockLanguage,
      locale: locale,
    );
    await tester.pumpAndSettle();
  }

  /// Fails if any of the seven markers is missing or has been squeezed below
  /// [minReadableMarker] to buy the row its space.
  void expectMarkers(WidgetTester tester) {
    for (var day = 1; day <= 7; day++) {
      final finder = find.byKey(ValueKey('daily-reward-day-$day'));
      expect(finder, findsOneWidget, reason: 'day $day marker not rendered');
      expect(
        tester.getSize(finder).width,
        greaterThanOrEqualTo(minReadableMarker),
        reason: 'day $day marker was shrunk to fit',
      );
    }
  }

  testWidgets('streak calendar fits a handset on day 1', (tester) async {
    await pumpDialog(tester, dayNumber: 1);
    expectMarkers(tester);
  });

  testWidgets('streak calendar fits a handset mid-streak', (tester) async {
    await pumpDialog(tester, dayNumber: 4);
    expectMarkers(tester);
  });

  testWidgets('streak calendar fits a narrow handset', (tester) async {
    await pumpDialog(tester, dayNumber: 1, size: const Size(320, 640));
    expectMarkers(tester);
  });

  // Greek carries the longest translations, so it decides whether the copy
  // above and below the calendar leaves the row any room.
  // Greek is the longest translation, but Press Start 2P draws it itself, so
  // it never takes the quarter-size bump every non-Latin script gets — see
  // [AppFonts.nonLatinOpticalScale]. These are the ones that do.
  for (final code in ['ja', 'zh', 'ko', 'ar', 'hi', 'th']) {
    testWidgets('streak calendar fits a handset in $code', (tester) async {
      await pumpDialog(tester, dayNumber: 1, locale: Locale(code));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('streak calendar fits a handset in the longest locale',
      (tester) async {
    await pumpDialog(tester, dayNumber: 1, locale: const Locale('el'));
    expectMarkers(tester);
  });
}
