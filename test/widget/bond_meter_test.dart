import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/bond_meter.dart';
import 'package:mojilearner_flutter/constants/bond.dart';
import 'package:mojilearner_flutter/models/models.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// The bond splits across two surfaces: a one-line strip that is always on the
/// home screen, and a details sheet one tap away. The split is the point — the
/// strip used to be a four-line card holding permanent screen space for a
/// number that moves about once a week.
///
/// So these tests pin two things. On the strip: which single label wins the one
/// line there is, and that it survives a handset in the longest locale. In the
/// sheet: which of the three captions is currently true, which is the same
/// priority order the old card's caption used.
void main() {
  late MockCharacterProvider mockCharacter;
  late MockCalibrationProvider mockCalibration;
  late MockLanguageProvider mockLanguage;
  late MockSettingsProvider mockSettings;

  setUp(() {
    mockCharacter = MockCharacterProvider();
    mockCalibration = MockCalibrationProvider();
    mockLanguage = MockLanguageProvider();
    mockSettings = MockSettingsProvider();

    when(() => mockSettings.usePixelFont).thenReturn(true);
    when(() => mockLanguage.targetLanguage).thenReturn(
      const Language(code: 'es', name: 'Spanish'),
    );
    when(() => mockCalibration.getLanguageProficiency(any())).thenReturn(null);
  });

  /// [LanguageProficiency] runs its level through [LevelValidator], so the
  /// only values that survive storage are beginner/intermediate/advanced —
  /// raw CEFR bands are normalised away. Tests use what is actually stored.
  void setAssessedLevel(String level) {
    when(() => mockCalibration.getLanguageProficiency('es')).thenReturn(
      LanguageProficiency(
        languageCode: 'es',
        aiDeterminedLevel: level,
        isCalibrated: true,
      ),
    );
  }

  Future<void> pumpMeter(WidgetTester tester, {Locale? locale}) async {
    await pumpApp(
      tester,
      const Center(child: BondMeter()),
      characterProvider: mockCharacter,
      calibrationProvider: mockCalibration,
      languageProvider: mockLanguage,
      settingsProvider: mockSettings,
      locale: locale,
    );
    await tester.pump();
  }

  /// Opens the details sheet the way a player does.
  Future<void> openDetails(WidgetTester tester) async {
    await tester.tap(find.byType(BondMeter));
    await tester.pumpAndSettle();
  }

  /// Scoped to the sheet, because the strip stays mounted behind it and the
  /// two deliberately name the same stage.
  Finder inSheet(Finder matching) => find.descendant(
        of: find.byType(BondDetailsSheet),
        matching: matching,
      );

  group('strip', () {
    testWidgets('names the stage the pet currently holds', (tester) async {
      await pumpMeter(tester);

      expect(find.text('Curious'), findsOneWidget);
    });

    testWidgets('moves up the ladder as bond is earned', (tester) async {
      mockCharacter.bondPoints = 700;
      setAssessedLevel('intermediate');

      await pumpMeter(tester);

      expect(find.text('Devoted'), findsOneWidget);
    });

    // The strip has one line, and a pet that noticed you were gone is the more
    // useful thing to put in it than the rung it happens to be sitting on.
    testWidgets('an absence takes the line from the stage name',
        (tester) async {
      mockCharacter.bondPoints = 60;
      mockCharacter.warmth = PetWarmth.missingYou;

      await pumpMeter(tester);

      expect(find.text('Moji misses you'), findsOneWidget);
      expect(find.text('Curious'), findsNothing);
    });

    testWidgets('escalates after a week away', (tester) async {
      mockCharacter.warmth = PetWarmth.lonely;

      await pumpMeter(tester);

      expect(find.text('Moji has been waiting for you'), findsOneWidget);
    });

    // Greek carries the longest translations, and the strip is a row of pips
    // and a label — the shape that overflowed twice already elsewhere.
    testWidgets('fits a handset in the longest locale', (tester) async {
      mockCharacter.bondPoints = 60;

      await pumpMeter(tester, locale: const Locale('el'));

      final label = find.text('Περίεργος');
      expect(label, findsOneWidget);
      expect(
        tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
        isFalse,
        reason: 'the stage name was truncated to fit',
      );
      expect(
        tester.getSize(find.byType(BondMeter)).width,
        lessThanOrEqualTo(kHandsetSurface.width),
      );
    });
  });

  group('details sheet', () {
    testWidgets('a new pet counts down to the first stage', (tester) async {
      await pumpMeter(tester);
      await openDetails(tester);

      expect(inSheet(find.text('BOND')), findsOneWidget);
      expect(inSheet(find.text('Curious')), findsOneWidget);
      expect(inSheet(find.text('100 to Friendly')), findsOneWidget);
    });

    testWidgets('counts down to the next stage as bond is earned',
        (tester) async {
      mockCharacter.bondPoints = 60;

      await pumpMeter(tester);
      await openDetails(tester);

      expect(inSheet(find.text('40 to Friendly')), findsOneWidget);
    });

    // The bar sits full while fluency-blocked, so the caption has to explain
    // why nothing is happening or it reads as a broken meter.
    testWidgets('says to keep learning when fluency is the blocker',
        (tester) async {
      mockCharacter.bondPoints = 5000;
      setAssessedLevel('beginner');

      await pumpMeter(tester);
      await openDetails(tester);

      expect(inSheet(find.text('Friendly')), findsOneWidget);
      expect(
        inSheet(find.text('Keep learning to grow closer')),
        findsOneWidget,
      );
    });

    testWidgets('the final stage asks for nothing further', (tester) async {
      mockCharacter.bondPoints = 5000;
      setAssessedLevel('advanced');

      await pumpMeter(tester);
      await openDetails(tester);

      expect(inSheet(find.text('Inseparable')), findsOneWidget);
      expect(inSheet(find.textContaining('to ')), findsNothing);
    });

    // Absence outranks progress in the caption too: a pet that noticed you
    // were gone is the more useful thing to say than a points countdown.
    testWidgets('an absence outranks the countdown', (tester) async {
      mockCharacter.bondPoints = 60;
      mockCharacter.warmth = PetWarmth.missingYou;

      await pumpMeter(tester);
      await openDetails(tester);

      expect(inSheet(find.text('Moji misses you')), findsOneWidget);
      expect(inSheet(find.text('40 to Friendly')), findsNothing);
    });

    // The softened failure state: an absence changes what the pet says and
    // nothing else. The stage it reached is still the stage it is at, which
    // the strip hides behind the absence line but the sheet still names.
    testWidgets('does not cost the pet its stage', (tester) async {
      mockCharacter.bondPoints = 700;
      mockCharacter.warmth = PetWarmth.lonely;
      setAssessedLevel('intermediate');

      await pumpMeter(tester);
      await openDetails(tester);

      expect(inSheet(find.text('Devoted')), findsOneWidget);
    });
  });
}
