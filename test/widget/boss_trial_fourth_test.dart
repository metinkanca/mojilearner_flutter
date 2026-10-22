import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/boss_trial/angler_pieces.dart';
import 'package:mojilearner_flutter/components/boss_trial/sphinx_pieces.dart';
import 'package:mojilearner_flutter/components/boss_trial/trial_boss.dart';
import 'package:mojilearner_flutter/components/boss_trial/trial_skin.dart';
import 'package:mojilearner_flutter/constants/boss_trial_sentences.dart';
import 'package:mojilearner_flutter/constants/boss_trial_words.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/screens/boss_trial_screen.dart';
import 'package:mojilearner_flutter/utils/boss_trial_angler.dart';
import 'package:mojilearner_flutter/utils/boss_trial_sphinx.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pet_probe.dart';
import '../helpers/pump_app.dart';

/// The fourth games of Amethyst, Lanternmaw and Sableth — the Vein, the Net
/// and the Sandstorm — played through the screen, learning Spanish.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCharacterProvider mockCharacter;
  late MockLanguageProvider mockLanguage;

  setUp(() {
    mockCharacter = MockCharacterProvider();
    mockLanguage = MockLanguageProvider();
    when(() => mockCharacter.currentCharacterType).thenReturn('cat');
    when(() => mockLanguage.targetLanguage)
        .thenReturn(const Language(code: 'es', name: 'es'));
    when(() => mockLanguage.nativeLanguage)
        .thenReturn(const Language(code: 'en', name: 'en'));
  });

  final sentences = bossTrialStockSentences(targetCode: 'es', nativeCode: 'en');
  final words = bossTrialStockWords(targetCode: 'es', nativeCode: 'en');

  Future<void> startWith(
      WidgetTester tester, TrialBoss boss, String opening) async {
    await pumpApp(
      tester,
      BossTrialScreen(key: UniqueKey(), boss: boss),
      characterProvider: mockCharacter,
      languageProvider: mockLanguage,
      vocabProvider: VocabProvider(),
    );
    await tester.pump();
    await tester.tap(find.text(opening));
    await tester.pump();
    await tester.ensureVisible(find.text('START TRIAL'));
    await tester.tap(find.text('START TRIAL'));
    await tester.pump();
  }

  Future<void> waitFor(WidgetTester tester, Finder finder,
      {int frames = 2000}) async {
    for (var i = 0; i < frames; i++) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 16));
    }
    fail('never found $finder');
  }

  final damage = find.textContaining(RegExp(r'^-\d+$'));

  String talk(WidgetTester tester) =>
      tester.widget<TalkPanel>(find.byType(TalkPanel)).text;

  testWidgets('every boss has four games to try', (tester) async {
    for (final boss in TrialBosses.all) {
      expect(boss.openings, hasLength(4), reason: boss.name);
    }
  });

  testWidgets('vein: off the vein is refused; along it, word by word, hits',
      (tester) async {
    await startWith(tester, TrialBosses.amethyst, 'VEIN');
    await waitFor(tester, find.byType(SkinTile));
    final said = sentences.firstWhere((s) => s.meaning == talk(tester));
    final tiles = find.byType(SkinTile);
    String label(int i) => tester.widget<SkinTile>(tiles.at(i)).label;
    final stray = List.generate(16, (i) => i)
        .firstWhere((i) => !said.tokens.contains(label(i)));
    await tester.tap(tiles.at(stray));
    await tester.pump();
    expect(find.text('off the vein'), findsOneWidget);

    final used = <int>{};
    for (final token in said.tokens) {
      final i = List.generate(16, (i) => i)
          .firstWhere((i) => label(i) == token && !used.contains(i));
      used.add(i);
      await tester.tap(tiles.at(i));
      await tester.pump();
    }
    // The pet gathers itself to cast the whole vein, then the bolt flies.
    await waitFor(tester, damage, frames: 120);
    expect(tester.takeException(), isNull);
  });

  testWidgets('net: a stray is scared off; every word netted hits',
      (tester) async {
    await startWith(tester, TrialBosses.angler, 'NET');
    await waitFor(tester, find.byType(WordFish));
    final said =
        sentences.firstWhere((s) => find.text(s.meaning).evaluate().isNotEmpty);
    expect(find.textContaining('0 OF ${said.tokens.length}'), findsOneWidget);

    Finder fish(String w) =>
        find.byWidgetPredicate((x) => x is WordFish && x.label == w);
    final labels = tester
        .widgetList<WordFish>(find.byType(WordFish))
        .map((f) => f.label)
        .toList();
    final stray = labels.firstWhere((l) => !said.tokens.contains(l));
    await tester.tap(fish(stray), warnIfMissed: false);
    await tester.pump();
    expect(find.text('not in it'), findsOneWidget);

    for (final token in said.tokens) {
      // A word twice in the sentence is two fish: the next one not netted.
      final candidates = fish(token);
      for (var i = 0; i < candidates.evaluate().length; i++) {
        final w = tester.widget<WordFish>(candidates.at(i));
        if (w.state == FishState.plain) {
          await tester.tap(candidates.at(i), warnIfMissed: false);
          await tester.pump();
          break;
        }
      }
    }
    // The pet casts the last net, then leans back and hauls it in on its cords
    // before the spell is thrown.
    await waitFor(tester, damage, frames: 260);
    expect(tester.takeException(), isNull);
  });

  /// The storm's grid as the screen lays it out: every letter, row by row,
  /// and the box it is drawn in.
  (List<String>, Rect) readGrid(WidgetTester tester) {
    final grid = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is SandGridPainter);
    final letters = tester
        .widgetList<Text>(
            find.descendant(of: grid, matching: find.byType(Text)))
        .map((t) => t.data!)
        .toList();
    return (letters, tester.getRect(grid));
  }

  /// Where [word] lies in [grid]: its first and last cells.
  (int, int) locate(List<String> grid, List<String> word) {
    const cols = StormWave.cols, rows = StormWave.rows;
    final n = word.length;
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        if (x + n <= cols &&
            List.generate(n, (i) => grid[y * cols + x + i]).join() ==
                word.join()) {
          return (y * cols + x, y * cols + x + n - 1);
        }
        if (y + n <= rows &&
            List.generate(n, (i) => grid[(y + i) * cols + x]).join() ==
                word.join()) {
          return (y * cols + x, (y + n - 1) * cols + x);
        }
      }
    }
    throw StateError('not in the grid');
  }

  Offset cellCentre(Rect r, int cell) {
    final w = r.width / StormWave.cols;
    return r.topLeft +
        Offset((cell % StormWave.cols + 0.5) * w,
            (cell ~/ StormWave.cols + 0.5) * w);
  }

  testWidgets('sandstorm: a swipe across the word finds it', (tester) async {
    await startWith(tester, TrialBosses.sphinx, 'STORM');
    await waitFor(tester, find.byType(TalkPanel));
    await tester.pump(const Duration(milliseconds: 16));
    final word = words.firstWhere((w) => w.meaning == talk(tester));
    final (grid, rect) = readGrid(tester);
    final (first, last) = locate(grid, BubbleWave.lettersOf(word.target)!);
    final from = cellCentre(rect, first);
    final gesture = await tester.startGesture(from);
    await tester.pump();
    await gesture.moveTo(Offset.lerp(from, cellCentre(rect, last), 0.5)!);
    await tester.pump();
    await gesture.moveTo(cellCentre(rect, last));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    // The pet howls the word off the sand first.
    await waitFor(tester, damage, frames: 200);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sandstorm: or a tap on each end; a wrong line is refused',
      (tester) async {
    await startWith(tester, TrialBosses.sphinx, 'STORM');
    await waitFor(tester, find.byType(TalkPanel));
    await tester.pump(const Duration(milliseconds: 16));
    final word = words.firstWhere((w) => w.meaning == talk(tester));
    final (grid, rect) = readGrid(tester);
    final (first, last) = locate(grid, BubbleWave.lettersOf(word.target)!);

    // A line that is not the word: from its first letter to the cell beside
    // it across the word's direction.
    const cols = StormWave.cols, rows = StormWave.rows;
    final across = last - first < cols;
    final int wrongEnd;
    if (across) {
      wrongEnd = first ~/ cols < rows - 1 ? first + cols : first - cols;
    } else {
      wrongEnd = first % cols < cols - 1 ? first + 1 : first - 1;
    }
    final line = StormWave.line(first, wrongEnd)!;
    final pet = PetProbe(tester);
    await tester.tapAt(cellCentre(rect, first));
    await tester.pump();
    await tester.tapAt(cellCentre(rect, line.last));
    await tester.pump();
    expect(find.text('no'), findsOneWidget);
    // A wrong line makes the pet cringe.
    final cringe = await pet.track(20);
    expect(cringe.lowestSquash, lessThan(0.9));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tapAt(cellCentre(rect, first));
    await tester.pump();
    await tester.tapAt(cellCentre(rect, last));
    await tester.pump();
    // The word found, the pet throws its head back and howls it off the sand.
    final cast = await pet.track(70);
    expect(cast.map((s) => s.tilt).reduce(min), lessThan(-0.55));
    await waitFor(tester, damage, frames: 200);
    expect(tester.takeException(), isNull);
  });
}
