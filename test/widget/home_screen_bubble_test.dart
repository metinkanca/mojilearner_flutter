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

/// The speech bubble is the pet's voice, and it is also the only channel left
/// explaining why the input box is dead — the scrolling ticker and the sleep
/// placeholder that used to say the same thing twice more are gone.
///
/// That puts two requirements in tension, and these tests hold both. A remark
/// has to clear itself, or the idle screen is permanently half text. A state
/// the player cannot act on has to stay up, or a greyed-out input has no
/// explanation anywhere on the screen.
void main() {
  const handset = Size(400, 844);
  const greeting = 'I love learning! What shall we practice today?';
  const reconnect =
      'Zzz... Moji is dozing while the language link reconnects. Try again soon.';

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

    // A contented pet, so no care badge competes for the top row.
    when(() => mockCharacter.hunger).thenReturn(90);
    when(() => mockCharacter.happiness).thenReturn(90);
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
    when(() => mockCharacter.petThePet()).thenReturn(true);

    when(() => mockLanguage.targetLanguage).thenReturn(
      const Language(code: 'es', name: 'Spanish', flag: '🇪🇸'),
    );
    when(() => mockSettings.usePixelFont).thenReturn(true);
    when(() => mockVocab.dueCount(languageCode: any(named: 'languageCode')))
        .thenReturn(0);
  });

  Future<void> pumpHome(WidgetTester tester) async {
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
    );
    // Not pumpAndSettle: the pet's breathing animation never settles.
    await tester.pump(const Duration(seconds: 1));
  }

  /// The bubble stays mounted when it goes quiet, so "is the pet speaking" is
  /// the opacity it is animating towards, not whether the text exists.
  double bubbleOpacity(WidgetTester tester, String text) {
    return tester
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.text(text),
            matching: find.byType(AnimatedOpacity),
          ).first,
        )
        .opacity;
  }

  /// Past the six seconds a remark gets, and past the fade itself.
  Future<void> waitOutTheRemark(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 7));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('the pet says its greeting on arrival', (tester) async {
    await pumpHome(tester);

    expect(bubbleOpacity(tester, greeting), 1);
  });

  testWidgets('and then goes quiet, leaving the scene to the pet',
      (tester) async {
    await pumpHome(tester);
    await waitOutTheRemark(tester);

    expect(bubbleOpacity(tester, greeting), 0);
  });

  // A faded bubble is still in the tree. If it kept swallowing taps it would
  // leave an invisible dead zone across the top of the scene.
  testWidgets('a quiet bubble does not swallow taps', (tester) async {
    await pumpHome(tester);
    await waitOutTheRemark(tester);

    final ignorePointer = tester.widget<IgnorePointer>(
      find.ancestor(
        of: find.text(greeting),
        // Nearest first: the route adds IgnorePointers of its own further up.
        matching: find.byType(IgnorePointer),
      ).first,
    );
    expect(ignorePointer.ignoring, isTrue);
  });

  // The bubble clearing itself would otherwise make a missed message
  // unrecoverable, so tapping the pet is what brings it back.
  testWidgets('tapping the pet brings the last remark back', (tester) async {
    await pumpHome(tester);
    await waitOutTheRemark(tester);
    expect(bubbleOpacity(tester, greeting), 0);

    await tester.tap(find.byType(HomeScreen));
    await tester.pump(const Duration(milliseconds: 300));

    expect(bubbleOpacity(tester, greeting), 1);
  });

  // Petting is the scratch, and only the scratch. A tap that also petted
  // would pay the same reward for a poke, and then the motion that is
  // supposed to be the affectionate one would be the slow way to do it.
  testWidgets('but does not pet it', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byType(HomeScreen));
    await tester.pump(const Duration(milliseconds: 300));

    verifyNever(() => mockCharacter.petThePet());
  });

  group('states the player cannot act on', () {
    setUp(() {
      when(() => mockCharacter.isAiIssueSleepMode).thenReturn(true);
      when(() => mockCharacter.isSleeping).thenReturn(true);
    });

    // The reconnect message is the only thing on screen explaining the greyed
    // out input, now that the ticker and the placeholder copy of it are gone.
    testWidgets('pin the bubble open past the fade', (tester) async {
      await pumpHome(tester);
      await waitOutTheRemark(tester);

      expect(bubbleOpacity(tester, reconnect), 1);
    });

    // Derived from the provider rather than stored, so a pet that falls asleep
    // while the bubble is down cannot come back showing a stale remark.
    testWidgets('say why, not whatever was said last', (tester) async {
      await pumpHome(tester);

      expect(find.text(reconnect), findsOneWidget);
      expect(find.text(greeting), findsNothing);
    });
  });
}
