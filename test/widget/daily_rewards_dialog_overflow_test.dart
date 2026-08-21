import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
/// test on its own, and the day labels are then checked for not having been
/// ellipsed away to buy that space.
void main() {
  const handset = Size(400, 844);

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

  /// Fails if [text] is missing or rendered with an ellipsis.
  void expectLabel(WidgetTester tester, String text) {
    final finder = find.text(text);
    expect(finder, findsOneWidget, reason: 'day marker "$text" not rendered');
    expect(
      tester.renderObject<RenderParagraph>(finder).didExceedMaxLines,
      isFalse,
      reason: 'day marker "$text" was truncated to fit',
    );
  }

  testWidgets('streak calendar fits a handset on day 1', (tester) async {
    await pumpDialog(tester, dayNumber: 1);

    // Day 1 is complete (a check); days 2-7 still show their numbers.
    for (var day = 2; day <= 7; day++) {
      expectLabel(tester, '$day');
    }
  });

  testWidgets('streak calendar fits a handset mid-streak', (tester) async {
    await pumpDialog(tester, dayNumber: 4);

    for (var day = 5; day <= 7; day++) {
      expectLabel(tester, '$day');
    }
  });

  testWidgets('streak calendar fits a narrow handset', (tester) async {
    await pumpDialog(tester, dayNumber: 1, size: const Size(320, 640));

    for (var day = 2; day <= 7; day++) {
      expectLabel(tester, '$day');
    }
  });

  // Greek carries the longest translations, so it decides whether the copy
  // above and below the calendar leaves the row any room.
  testWidgets('streak calendar fits a handset in the longest locale',
      (tester) async {
    await pumpDialog(tester, dayNumber: 1, locale: const Locale('el'));

    for (var day = 2; day <= 7; day++) {
      expectLabel(tester, '$day');
    }
  });
}
