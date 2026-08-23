import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/navigation_wrapper.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/screens/home_screen.dart';
import 'package:mojilearner_flutter/utils/fonts.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';
import '../helpers/test_fixtures.dart';

class MockVocabProvider extends Mock implements VocabProvider {}

/// Every script is drawn a quarter larger than its nominal size so it carries
/// the same weight as the Latin pixel face — see [AppFonts.nonLatinOpticalScale].
/// That is a global change to text metrics, and the layouts were measured
/// before it existed.
///
/// The other overflow tests pin Greek, which Press Start 2P draws itself and
/// which therefore never scales. These pump the scripts that do: a RenderFlex
/// overflow fails the test on its own, which is the whole point.
void main() {
  const handset = Size(400, 844);

  /// The scripts the scale applies to. Japanese, Chinese and Korean are drawn
  /// by the bundled faces; Hindi and Thai are not, and fall back to whatever
  /// the platform has — the test font here, which is no narrower than a real
  /// one.
  const scaledScripts = ['ja', 'zh', 'ko', 'ar', 'hi', 'th'];

  late MockUserProvider mockUser;
  late MockDailyRewardProvider mockDailyReward;
  late MockCharacterProvider mockCharacter;
  late MockLanguageProvider mockLanguage;
  late MockSettingsProvider mockSettings;
  late MockVocabProvider mockVocab;

  setUpAll(() async {
    // The bundled faces, so the CJK laid out here has its real advances
    // rather than the uniform squares of the test font.
    Future<void> load(String family, String path) async =>
        (FontLoader(family)
              ..addFont(
                  rootBundle.load(path).then((d) => d.buffer.asByteData())))
            .load();
    await load('PressStart2P', 'assets/fonts/PressStart2P-Regular.ttf');
    await load('PixelAEArabic', 'assets/fonts/pixelae/PixelAE-Regular.ttf');
    await load('ArkPixelJa',
        'assets/fonts/ark/ark-pixel-12px-proportional-ja.ttf');
    await load('ArkPixelZhCn',
        'assets/fonts/ark/ark-pixel-12px-proportional-zh_cn.ttf');
    await load('ArkPixelZhTw',
        'assets/fonts/ark/ark-pixel-12px-proportional-zh_tw.ttf');
    await load('GalmuriKo', 'assets/fonts/galmuri/Galmuri11-Bold.ttf');
  });

  tearDown(() => AppFonts.setAppLocale(const Locale('en')));

  setUp(() {
    mockUser = MockUserProvider();
    mockDailyReward = MockDailyRewardProvider();
    mockCharacter = MockCharacterProvider();
    mockLanguage = MockLanguageProvider();
    mockSettings = MockSettingsProvider();
    mockVocab = MockVocabProvider();

    when(() => mockUser.stats).thenReturn(
      TestFixtures.buildUserStats(
        level: 12,
        totalXP: 1272,
        currentLevelXP: 72,
        nextLevelXP: 100,
        coins: 1240,
        streak: 14,
        progress: 0.72,
      ),
    );
    when(() => mockUser.isLoading).thenReturn(false);
    when(() => mockDailyReward.checkDailyReward()).thenAnswer((_) async => null);
    when(() => mockDailyReward.pendingDailyReward).thenReturn(null);
    // Low enough to surface the care badge, the widest thing on the top row.
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
    when(() => mockLanguage.targetLanguage)
        .thenReturn(const Language(code: 'es', name: 'Spanish'));
    when(() => mockSettings.usePixelFont).thenReturn(true);
    // A review badge on the top row alongside the care badge — the fullest
    // that row ever gets.
    when(() => mockVocab.dueCount(languageCode: any(named: 'languageCode')))
        .thenReturn(12);
  });

  for (final code in scaledScripts) {
    testWidgets('the home screen lays out in $code', (tester) async {
      final locale = Locale(code);
      AppFonts.setAppLocale(locale);
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
        surfaceSize: handset,
      );
      // Not pumpAndSettle: the pet's breathing animation never settles.
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
    });
  }

  // The pill holds a level, an XP line and a bar, and shares its row with the
  // badges. Its inner Row used to fill whatever the badges left over, so on a
  // screen with no care or review badge a short "XP: 0/100" sat adrift in a
  // pill most of a handset wide.
  testWidgets('the level pill is only as wide as what is in it',
      (tester) async {
    // A settled pet and nothing due: the two badges that do not appear are
    // what leaves the pill room to stretch into.
    when(() => mockCharacter.hunger).thenReturn(100);
    when(() => mockCharacter.happiness).thenReturn(100);
    when(() => mockVocab.dueCount(languageCode: any(named: 'languageCode')))
        .thenReturn(0);

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
      surfaceSize: handset,
    );
    await tester.pump(const Duration(seconds: 1));

    final pill = tester.getSize(find.byKey(levelPillKey)).width;
    // Level square, gap, the XP line, and the pill's own frame — nowhere near
    // the 280-odd points the row would hand it if it asked.
    expect(pill, lessThan(200),
        reason: 'the pill stretched to fill the row again');
    expect(pill, greaterThan(100), reason: 'the pill collapsed');
  });

  // The nav labels are the tightest text in the app: a fixed slot with a
  // FittedBox behind it, so an over-wide label does not overflow — it silently
  // shrinks back off the pixel grid, which is the thing worth catching.
  //
  // Only the scripts a bundled pixel face actually draws are held to it.
  // Hangul, Devanagari and Thai come from whatever the platform has, so they
  // are smooth either way and lose nothing by being scaled down a few percent
  // — and the box-per-glyph test font here is no measure of their real width.
  for (final code in ['ja', 'zh', 'ar']) {
    testWidgets('the longest nav label still fits its slot in $code',
        (tester) async {
      const longest = {
        'ja': 'プロフィール',
        'zh': '个人资料',
        'ko': '프로필',
        'ar': 'الملف الشخصي',
        'hi': 'प्रोफ़ाइल',
        'th': 'โปรไฟล์',
      };
      final locale = Locale(code);
      AppFonts.setAppLocale(locale);
      final label = longest[code]!.toUpperCase();
      // The nav item's own rule for which size a label gets.
      final size = label.length > 8 ? 7.0 : 8.0;
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: AppFonts.pressStart2p(fontSize: size, locale: locale),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      expect(painter.width, lessThanOrEqualTo(navLabelSlotWidth),
          reason: '$code: "${longest[code]}" gets shrunk off the pixel grid');
    });
  }
}
