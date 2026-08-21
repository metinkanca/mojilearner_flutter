import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/screens/home_screen.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';
import '../helpers/test_fixtures.dart';

class MockVocabProvider extends Mock implements VocabProvider {}

/// The top bar used to lay out a level pill, up to two prompt chips, and the
/// settings button in one un-wrapping [Row]. The other HomeScreen tests pump a
/// 1200pt surface, wider than any phone, so that row was never exercised — on a
/// real 400pt handset the care chip pushed it 39px past the edge, and 129px
/// with the review chip alongside. Moving the chips to a [Wrap] below the pill
/// fixed the overflow at the cost of a whole line of screen.
///
/// The prompts are now compact badges back on the pill's row: a "!" glyph for
/// care, a count for review. That is what makes this class of bug structurally
/// impossible — the badges are fixed 40pt squares whose content is a glyph or a
/// number, so no translation can widen them. These tests hold that line: the
/// badges must render at their fixed size on a handset in the longest locale,
/// and a RenderFlex overflow fails the test on its own.
///
/// The wording the chips used to carry now lives in the semantic label, which
/// is asserted here too — dropping it would leave the badges meaningless to a
/// screen reader.
void main() {
  const handset = Size(400, 844);

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

    when(() => mockUser.stats).thenReturn(
      TestFixtures.buildUserStats(
        level: 1,
        totalXP: 72,
        currentLevelXP: 72,
        nextLevelXP: 100,
        coins: 0,
        streak: 1,
        progress: 0.72,
      ),
    );
    when(() => mockUser.isLoading).thenReturn(false);

    when(() => mockDailyReward.checkDailyReward()).thenAnswer((_) async => null);
    when(() => mockDailyReward.pendingDailyReward).thenReturn(null);

    // Happiness low enough to surface the care chip — the widest chip, and the
    // one in the reported screenshot.
    when(() => mockCharacter.hunger).thenReturn(20);
    when(() => mockCharacter.happiness).thenReturn(15);
    when(() => mockCharacter.health).thenReturn(100);
    when(() => mockCharacter.inventory).thenReturn(const []);
    when(() => mockCharacter.currentCharacterAsset)
        .thenReturn('assets/svgs/cat.svg');
    when(() => mockCharacter.customization)
        .thenReturn(TestFixtures.buildCustomization());
    when(() => mockCharacter.isSleeping).thenReturn(false);
    when(() => mockCharacter.isAiIssueSleepMode).thenReturn(false);
    when(() => mockCharacter.isTemporarilyAwake).thenReturn(false);
    when(() => mockCharacter.isSleepingForNight).thenReturn(false);
    when(() => mockCharacter.awakeUntil).thenReturn(null);

    when(() => mockLanguage.targetLanguage).thenReturn(
      const Language(code: 'es', name: 'Spanish', flag: '🇪🇸'),
    );
    when(() => mockSettings.usePixelFont).thenReturn(true);
  });

  Future<void> pumpHome(WidgetTester tester, {Locale? locale}) async {
    await tester.binding.setSurfaceSize(handset);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpApp(
      tester,
      const HomeScreen(),
      userProvider: mockUser,
      dailyRewardProvider: mockDailyReward,
      characterProvider: mockCharacter,
      languageProvider: mockLanguage,
      settingsProvider: mockSettings,
      vocabProvider: mockVocab,
      locale: locale,
    );
    // Not pumpAndSettle: the pet's breathing animation never settles.
    await tester.pump(const Duration(seconds: 1));
  }

  /// The badges carry their wording in the semantic label now that the visible
  /// content is a glyph. Fails if that label is missing.
  void expectBadge(WidgetTester tester, String semanticLabel, String glyph) {
    expect(
      find.bySemanticsLabel(semanticLabel),
      findsOneWidget,
      reason: 'badge "$semanticLabel" not rendered',
    );
    expect(
      find.text(glyph),
      findsOneWidget,
      reason: 'badge glyph "$glyph" not rendered',
    );
    // A fixed square is the whole reason the label can no longer overflow.
    expect(
      tester.getSize(find.ancestor(
        of: find.text(glyph),
        matching: find.byType(Container),
      ).first),
      const Size(40, 40),
    );
  }

  testWidgets('the care badge fits a handset', (tester) async {
    when(() => mockVocab.dueCount(languageCode: any(named: 'languageCode')))
        .thenReturn(0);

    final semantics = tester.ensureSemantics();
    await pumpHome(tester);

    expectBadge(tester, 'Moji is feeling low', '!');
    semantics.dispose();
  });

  testWidgets('the care and review badges fit a handset side by side',
      (tester) async {
    when(() => mockVocab.dueCount(languageCode: any(named: 'languageCode')))
        .thenReturn(12);

    final semantics = tester.ensureSemantics();
    await pumpHome(tester);

    expectBadge(tester, 'Moji is feeling low', '!');
    expectBadge(tester, '12 due', '12');
    semantics.dispose();
  });

  // Greek carried the longest translation of both chip labels, which is what
  // used to decide whether the row overflowed. It no longer can — the badges
  // are the same 40pt squares in every locale, and this pins that.
  testWidgets('the badges are locale-independent in the longest locale',
      (tester) async {
    when(() => mockVocab.dueCount(languageCode: any(named: 'languageCode')))
        .thenReturn(12);

    final semantics = tester.ensureSemantics();
    await pumpHome(tester, locale: const Locale('el'));

    expectBadge(tester, 'Ο Moji έχει πέσει ψυχολογικά', '!');
    expectBadge(tester, '12 για επανάληψη', '12');
    semantics.dispose();
  });

  // A three-digit queue would not fit the square, so it caps rather than
  // reintroducing the overflow through the back door.
  testWidgets('a very large review queue caps instead of widening',
      (tester) async {
    when(() => mockVocab.dueCount(languageCode: any(named: 'languageCode')))
        .thenReturn(412);

    await pumpHome(tester);

    expect(find.text('99+'), findsOneWidget);
    expect(find.text('412'), findsNothing);
  });
}
