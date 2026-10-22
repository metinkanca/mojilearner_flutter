import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/boss_trial/angler_pieces.dart';
import 'package:mojilearner_flutter/components/boss_trial/crystal_pieces.dart';
import 'package:mojilearner_flutter/components/boss_trial/hex_pieces.dart';
import 'package:mojilearner_flutter/components/boss_trial/hoothex_pieces.dart';
import 'package:mojilearner_flutter/components/boss_trial/sphinx_pieces.dart';
import 'package:mojilearner_flutter/components/boss_trial/trial_boss.dart';
import 'package:mojilearner_flutter/components/boss_trial/trial_skin.dart';
import 'package:mojilearner_flutter/constants/boss_trial_en_tr.dart';
import 'package:mojilearner_flutter/constants/boss_trial_sentences.dart';
import 'package:mojilearner_flutter/constants/boss_trial_words.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/screens/boss_trial_screen.dart';
import 'package:mojilearner_flutter/utils/boss_trial_angler.dart';
import 'package:mojilearner_flutter/utils/boss_trial_crystal.dart';
import 'package:mojilearner_flutter/utils/boss_trial_sphinx.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pet_probe.dart';
import '../helpers/pump_app.dart';

/// With animations turned off the trials still play: every answer lands at
/// once, and the pet's body stays where it stands — no leaps, no casts, no
/// curses it has to act out.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCharacterProvider mockCharacter;
  late MockLanguageProvider mockLanguage;
  final content = EnTrContent.of('tr', 'en')!;

  void learning(String target) {
    when(() => mockLanguage.targetLanguage)
        .thenReturn(Language(code: target, name: target));
  }

  setUp(() {
    mockCharacter = MockCharacterProvider();
    mockLanguage = MockLanguageProvider();
    when(() => mockCharacter.currentCharacterType).thenReturn('cat');
    when(() => mockLanguage.nativeLanguage)
        .thenReturn(const Language(code: 'en', name: 'en'));
    learning('es');
  });

  final words = bossTrialStockWords(targetCode: 'es', nativeCode: 'en');
  final sentences = bossTrialStockSentences(targetCode: 'es', nativeCode: 'en');
  final damage = find.textContaining(RegExp(r'^-\d+$'));

  Future<void> pumpTrial(WidgetTester tester, TrialBoss boss) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: BossTrialScreen(key: UniqueKey(), boss: boss),
        ),
      ),
      characterProvider: mockCharacter,
      languageProvider: mockLanguage,
      vocabProvider: VocabProvider(),
    );
    await tester.pump();
  }

  Future<void> startWith(
      WidgetTester tester, TrialBoss boss, String? opening) async {
    await pumpTrial(tester, boss);
    if (opening != null) {
      await tester.tap(find.text(opening));
      await tester.pump();
    }
    await tester.ensureVisible(find.text('START TRIAL'));
    await tester.tap(find.text('START TRIAL'));
    await tester.pump();
  }

  Future<void> waitFor(WidgetTester tester, Finder finder,
      {int frames = 3000}) async {
    for (var i = 0; i < frames; i++) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 16));
    }
    fail('never found $finder');
  }

  /// Plays [frames] frames and checks the pet stood where it was through them.
  Future<void> stillThrough(WidgetTester tester, PetSample start,
      {int frames = 40}) async {
    final pet = PetProbe(tester);
    final run = await pet.track(frames);
    expect(run.xSpread, lessThan(1.5));
    expect(run.highest, greaterThan(start.feet - 2));
    expect(run.map((s) => s.tilt.abs()).reduce(max), lessThan(0.02));
    expect(run.lowestSquash, greaterThan(0.99));
  }

  testWidgets('the lure and the net: answered at once, the pet still',
      (tester) async {
    await startWith(tester, TrialBosses.angler, 'LURE');
    await waitFor(tester, find.byType(WordFish));
    final start = PetProbe(tester).sample;
    final board = tester.widget<LureBoard>(find.byType(LureBoard));
    await tester.tap(
        find.byWidgetPredicate(
            (w) => w is WordFish && w.label == board.words[board.gap]),
        warnIfMissed: false);
    await tester.pump();
    await tester.pump();
    expect(damage, findsOneWidget);
    await stillThrough(tester, start);

    await startWith(tester, TrialBosses.angler, 'NET');
    await waitFor(tester, find.byType(WordFish));
    final said =
        sentences.firstWhere((s) => find.text(s.meaning).evaluate().isNotEmpty);
    for (final token in said.tokens) {
      final fish = find.byWidgetPredicate((w) =>
          w is WordFish && w.label == token && w.state == FishState.plain);
      await tester.tap(fish.first, warnIfMissed: false);
      await tester.pump();
    }
    await tester.pump();
    expect(damage, findsOneWidget);
    // Nothing to haul in: the net bursts at once.
    expect(find.byType(WordFish), findsNothing);
    await stillThrough(tester, start);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the bubbles: the word spelt is cast at once; the gulp still '
      'traps the pet, in a bubble it does not float in', (tester) async {
    await startWith(tester, TrialBosses.angler, 'BUBBLES');
    await waitFor(tester, find.byType(LetterBubble));
    final start = PetProbe(tester).sample;
    final asked =
        words.firstWhere((w) => find.text(w.meaning).evaluate().isNotEmpty);
    for (final letter in asked.target.split('')) {
      await tester.tap(
          find
              .byWidgetPredicate((w) =>
                  w is LetterBubble &&
                  w.label == letter &&
                  w.onTapDown != null)
              .first,
          warnIfMissed: false);
      await tester.pump();
    }
    await tester.pump();
    expect(damage, findsOneWidget);
    await stillThrough(tester, start);

    await startWith(tester, TrialBosses.angler, 'BUBBLES');
    await waitFor(tester, find.byType(LetterBubble));
    final before = PetProbe(tester).sample;
    await waitFor(tester, find.text('blub'));
    await tester.pump();
    final paint = tester.widget<CustomPaint>(find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is PetBubblePainter));
    expect((paint.painter! as PetBubblePainter).fill, 1);
    expect(PetProbe(tester).feet, closeTo(before.feet, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('amethyst: the spikes, the echo, the volley and the vein, '
      'answered at once, the pet still', (tester) async {
    await startWith(tester, TrialBosses.amethyst, 'SPIKES');
    await waitFor(tester, find.byType(CrystalSpike));
    final start = PetProbe(tester).sample;
    final spikes =
        tester.widgetList<CrystalSpike>(find.byType(CrystalSpike)).toList();
    final roared = words.firstWhere((w) => w.target == spikes.first.label);
    await tester.tap(find.byType(CrystalSpike).first);
    await tester.pump();
    await tester.tap(find.widgetWithText(CrystalGem, roared.meaning));
    await tester.pump();
    await tester.pump();
    expect(damage, findsOneWidget);
    expect(find.byType(CrystalSpike), findsNWidgets(3));
    await stillThrough(tester, start);

    await startWith(tester, TrialBosses.amethyst, 'ECHO');
    await waitFor(tester, find.byType(EchoCrystal));
    final said =
        sentences.firstWhere((s) => find.text(s.target).evaluate().isNotEmpty);
    await tester.tap(find.widgetWithText(EchoCrystal, said.meaning));
    await tester.pump();
    await tester.pump();
    expect(damage, findsOneWidget);
    await stillThrough(tester, start);

    await startWith(tester, TrialBosses.amethyst, 'VOLLEY');
    await waitFor(tester, find.byType(VolleyShardTile));
    VolleyShardTile? lie;
    for (var i = 0; i < 1500 && lie == null; i++) {
      for (final s
          in tester.widgetList<VolleyShardTile>(find.byType(VolleyShardTile))) {
        if (words.firstWhere((w) => w.target == s.word).meaning != s.claim) {
          lie = s;
        }
      }
      if (lie == null) await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.tap(find.byWidget(lie!), warnIfMissed: false);
    await tester.pump();
    await tester.pump();
    expect(damage, findsWidgets);
    await stillThrough(tester, start);

    await startWith(tester, TrialBosses.amethyst, 'VEIN');
    await waitFor(tester, find.byType(SkinTile));
    final sentence = sentences
        .firstWhere((s) => find.text(s.meaning).evaluate().isNotEmpty);
    List<SkinTile> wall() =>
        tester.widgetList<SkinTile>(find.byType(SkinTile)).toList();
    final labels = wall().map((t) => t.label).toList();
    var previous = -1;
    for (final token in sentence.tokens) {
      for (var i = 0; i < labels.length; i++) {
        if (labels[i] != token ||
            wall()[i].badge != null ||
            (previous >= 0 && !VeinWave.neighbours(previous).contains(i))) {
          continue;
        }
        await tester.tap(find.byType(SkinTile).at(i));
        await tester.pump();
        if (wall()[i].badge != null) {
          previous = i;
          break;
        }
      }
    }
    await tester.pump();
    expect(damage, findsOneWidget);
    await stillThrough(tester, start);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the witch: a scroll, clones and a spell, answered at once',
      (tester) async {
    await startWith(tester, TrialBosses.witch, null);
    await waitFor(tester, find.byType(ScrollWord));
    final start = PetProbe(tester).sample;
    final truth = sentences
        .firstWhere((s) => find.text(s.meaning).evaluate().isNotEmpty)
        .tokens;
    final said = tester
        .widgetList<ScrollWord>(find.byType(ScrollWord))
        .map((w) => w.label)
        .toList();
    final hexed = [
      for (var i = 0; i < truth.length; i++)
        if (said[i] != truth[i]) i,
    ].single;
    await tester.tap(find.byType(ScrollWord).at(hexed));
    await tester.pump();
    await tester.pump();
    expect(damage, findsOneWidget);
    await stillThrough(tester, start);

    await startWith(tester, TrialBosses.witch, 'CLONES');
    await waitFor(tester, find.byType(OwlBubble));
    // (The game clock takes a frame at a time, 50ms at most.)
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final owl = sentences
        .firstWhere((s) => find.text(s.meaning).evaluate().isNotEmpty)
        .target;
    await tester.tap(find.widgetWithText(OwlBubble, owl), warnIfMissed: false);
    await tester.pump();
    await tester.pump();
    expect(damage, findsOneWidget);
    await stillThrough(tester, start);
    expect(tester.takeException(), isNull);
  });

  group('sableth and pyrewing, in Turkish', () {
    setUp(() => learning('tr'));

    Finder tablet(String label) =>
        find.byWidgetPredicate((w) => w is SkinTile && w.label == label);
    String talk(WidgetTester tester) =>
        tester.widget<TalkPanel>(find.byType(TalkPanel)).text;

    testWidgets('the riddle, the door and the tablets: answered at once, the '
        'door gone', (tester) async {
      await startWith(tester, TrialBosses.sphinx, 'RIDDLE');
      await waitFor(tester, find.byType(SkinTile));
      final start = PetProbe(tester).sample;
      final riddle =
          content.riddles.firstWhere((r) => talk(tester).contains(r.question));
      await tester.tap(tablet(riddle.answers.first));
      await tester.pump();
      await tester.pump();
      expect(damage, findsOneWidget);
      await stillThrough(tester, start);

      await startWith(tester, TrialBosses.sphinx, 'DOOR');
      await waitFor(tester, find.byType(SealedDoor));
      SealedDoor door() => tester.widget<SealedDoor>(find.byType(SealedDoor));
      final asked = content.doors.firstWhere((d) => d.base == door().base);
      for (var i = 0; i < 3 && door().dial != asked.answer; i++) {
        await tester.tap(find.text(door().dial));
        await tester.pump();
      }
      await tester.tap(find.text('PUSH'));
      await tester.pump();
      await tester.pump();
      expect(damage, findsOneWidget);
      expect(find.byType(SealedDoor), findsNothing);
      await stillThrough(tester, start);

      await startWith(tester, TrialBosses.sphinx, 'TABLETS');
      await waitFor(tester, find.byType(SkinTile));
      final story = content.stories
          .firstWhere((s) => find.text(s.lines.first).evaluate().isNotEmpty);
      for (final line in story.lines) {
        await tester.tap(tablet(line));
        await tester.pump();
      }
      await tester.pump();
      expect(damage, findsOneWidget);
      await stillThrough(tester, start);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the storm: found at once, the pet not leaning, the sand gone '
        'at once', (tester) async {
      await startWith(tester, TrialBosses.sphinx, 'STORM');
      await waitFor(tester, find.byType(TalkPanel));
      await tester.pump(const Duration(milliseconds: 16));
      final start = PetProbe(tester).sample;
      expect(start.tilt.abs(), lessThan(0.02));
      final stock = bossTrialStockWords(targetCode: 'tr', nativeCode: 'en');
      final target = stock.firstWhere((w) => w.meaning == talk(tester));
      final grid = find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is SandGridPainter);
      final letters = tester
          .widgetList<Text>(
              find.descendant(of: grid, matching: find.byType(Text)))
          .map((t) => t.data!)
          .toList();
      final box = tester.getRect(grid);
      final cell = box.width / StormWave.cols;
      final word = BubbleWave.lettersOf(target.target)!;
      int? from, to;
      for (var y = 0; y < StormWave.rows && from == null; y++) {
        for (var x = 0; x < StormWave.cols && from == null; x++) {
          if (x + word.length <= StormWave.cols &&
              List.generate(
                          word.length, (i) => letters[y * StormWave.cols + x + i])
                      .join() ==
                  word.join()) {
            from = y * StormWave.cols + x;
            to = from + word.length - 1;
          } else if (y + word.length <= StormWave.rows &&
              List.generate(word.length,
                          (i) => letters[(y + i) * StormWave.cols + x])
                      .join() ==
                  word.join()) {
            from = y * StormWave.cols + x;
            to = (y + word.length - 1) * StormWave.cols + x;
          }
        }
      }
      Offset centre(int c) => box.topLeft +
          Offset((c % StormWave.cols + 0.5) * cell,
              (c ~/ StormWave.cols + 0.5) * cell);
      await tester.tapAt(centre(from!));
      await tester.pump();
      await tester.tapAt(centre(to!));
      await tester.pump();
      await tester.pump();
      expect(damage, findsOneWidget);
      await stillThrough(tester, start);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the hoard: pairs found at once, no coin carried, the pet '
        'still', (tester) async {
      await startWith(tester, TrialBosses.dragon, 'HOARD');
      final coinTiles = find
          .byWidgetPredicate((w) => w is SkinTile && w.shape == TileShape.coin);
      await waitFor(tester, coinTiles);
      final start = PetProbe(tester).sample;
      final coins =
          tester.widgetList<SkinTile>(coinTiles).map((c) => c.label).toList();
      final p = content.phrases
          .where((p) => coins.contains(p.first) && coins.contains(p.second))
          .first;
      await tester.tap(coinTiles.at(coins.indexOf(p.first)));
      await tester.pump();
      expect(find.byKey(ValueKey('trip-${coins.indexOf(p.first)}')),
          findsNothing);
      await tester.tap(coinTiles.at(coins.indexOf(p.second)));
      await tester.pump();
      await tester.pump();
      expect(damage, findsOneWidget);
      await stillThrough(tester, start);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the sand: at once, the pet where it was', (tester) async {
      await startWith(tester, TrialBosses.sphinx, 'RIDDLE');
      await waitFor(tester, find.byType(SkinTile));
      final before = PetProbe(tester).sample;
      await waitFor(tester, find.text('buried'));
      await tester.pump();
      final paint = tester.widget<CustomPaint>(find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is SandPilePainter));
      expect((paint.painter! as SandPilePainter).fill, 1);
      expect(PetProbe(tester).feet, closeTo(before.feet, 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the parley, the link and the embers: answered at once, the '
        'pet still', (tester) async {
      await startWith(tester, TrialBosses.dragon, 'PARLEY');
      await waitFor(tester, find.byType(SkinTile));
      final start = PetProbe(tester).sample;
      final script =
          content.parleys.firstWhere((p) => talk(tester) == p.turns.first.line);
      for (final turn in script.turns) {
        await tester.tap(tablet(turn.replies.first));
        await tester.pump();
      }
      await tester.pump();
      expect(damage, findsWidgets);
      await stillThrough(tester, start);

      await startWith(tester, TrialBosses.dragon, 'LINK');
      await waitFor(tester, find.byType(SkinTile));
      final item = content.links
          .firstWhere((l) => find.text(l.left).evaluate().isNotEmpty);
      await tester.tap(tablet(item.links.first), warnIfMissed: false);
      await tester.pump();
      await tester.pump();
      expect(damage, findsOneWidget);
      await stillThrough(tester, start);

      await startWith(tester, TrialBosses.dragon, 'EMBERS');
      await waitFor(tester, find.byType(SkinTile));
      final ember =
          content.paraphrases.firstWhere((p) => talk(tester) == p.line);
      await tester.tap(tablet(ember.options.first), warnIfMissed: false);
      await tester.pump();
      await tester.pump();
      expect(damage, findsOneWidget);
      await stillThrough(tester, start);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the ash: at once, the pet where it was', (tester) async {
      await startWith(tester, TrialBosses.dragon, 'PARLEY');
      await waitFor(tester, find.byType(SkinTile));
      final before = PetProbe(tester).sample;
      await waitFor(tester, find.text('scorched'));
      await tester.pump();
      expect(PetProbe(tester).feet, closeTo(before.feet, 1));
      expect(tester.takeException(), isNull);
    });
  });
}
