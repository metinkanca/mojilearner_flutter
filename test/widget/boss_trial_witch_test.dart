import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/boss_trial/hex_pieces.dart';
import 'package:mojilearner_flutter/components/boss_trial/hoothex_pieces.dart';
import 'package:mojilearner_flutter/components/boss_trial/trial_boss.dart';
import 'package:mojilearner_flutter/components/character_sprite.dart';
import 'package:mojilearner_flutter/constants/boss_trial_sentences.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/screens/boss_trial_screen.dart';
import 'package:mojilearner_flutter/utils/boss_trial.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pet_probe.dart';
import '../helpers/pump_app.dart';

/// The witch's trial: her Hexed Scroll round and her brewing.
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

  final stock = bossTrialStockSentences(targetCode: 'es', nativeCode: 'en');

  // Never loaded from storage: awaiting SecureStorage under testWidgets'
  // FakeAsync deadlocks. See quiz_screen_srs_test.
  Future<void> pumpTrial(
    WidgetTester tester, {
    TrialBoss boss = TrialBosses.witch,
  }) async {
    await pumpApp(
      tester,
      // A fresh screen each time: pumped again without a key, the last
      // one's state — and its boss — would be kept.
      BossTrialScreen(key: UniqueKey(), boss: boss),
      characterProvider: mockCharacter,
      languageProvider: mockLanguage,
      vocabProvider: VocabProvider(),
    );
    await tester.pump();
  }

  /// Runs the game clock frame by frame, the way a device would.
  Future<void> advance(WidgetTester tester, int ms) async {
    for (var t = 0; t < ms; t += 16) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  Future<void> start(WidgetTester tester) async {
    // Below the fold on a short screen: the opening picker makes the intro
    // tall.
    await tester.ensureVisible(find.text('START TRIAL'));
    await tester.tap(find.text('START TRIAL'));
    await tester.pump();
  }

  /// Runs the clock until [finder] is on screen, or fails.
  Future<void> waitFor(WidgetTester tester, Finder finder,
      {int frames = 400}) async {
    for (var i = 0; i < frames; i++) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 16));
    }
    fail('never found $finder');
  }

  List<ScrollWord> words(WidgetTester tester) =>
      tester.widgetList<ScrollWord>(find.byType(ScrollWord)).toList();

  Future<void> waitForScroll(WidgetTester tester) async {
    for (var i = 0; i < 400; i++) {
      if (find.byType(ScrollWord).evaluate().isNotEmpty &&
          words(tester).every((w) => w.state == ScrollWordState.plain)) {
        return;
      }
      await tester.pump(const Duration(milliseconds: 16));
    }
    fail('no scroll was read');
  }

  /// The sentence the scroll should say, read off the prompt.
  TrialSentence reading() =>
      stock.firstWhere((s) => find.text(s.meaning).evaluate().isNotEmpty);

  /// Which word on the scroll is hexed.
  int hexedWord(WidgetTester tester) {
    final truth = reading().tokens;
    final said = words(tester).map((w) => w.label).toList();
    expect(said, hasLength(truth.length));
    final differ = [
      for (var i = 0; i < said.length; i++)
        if (said[i] != truth[i]) i,
    ];
    expect(differ, hasLength(1), reason: 'said $said for $truth');
    return differ.single;
  }

  Future<void> tapWord(WidgetTester tester, int index) async {
    await tester.tap(find.byType(ScrollWord).at(index));
    await tester.pump();
  }

  bool frogOnStage(WidgetTester tester) => tester
      .widgetList<CharacterSprite>(find.byType(CharacterSprite))
      .any((s) => s.previewType == 'frog');

  testWidgets('opens on her intro', (tester) async {
    await pumpTrial(tester);

    expect(find.text('LEVEL 11 · SCROLL'), findsOneWidget);
    expect(find.text('Hoothex'), findsOneWidget);
    expect(find.text('START TRIAL'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the intro switches between the trials', (tester) async {
    await pumpTrial(tester, boss: TrialBosses.mossback);
    expect(find.text('Mossback'), findsOneWidget);

    await tester.tap(find.text('LV 15\nHOOTHEX'));
    await tester.pump();
    expect(find.text('Hoothex'), findsOneWidget);
    expect(find.text('Mossback'), findsNothing);

    await tester.tap(find.text('LV 5\nMOSSBACK'));
    await tester.pump();
    expect(find.text('Mossback'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a pair with nothing to fight with falls back, and says so',
      (tester) async {
    // The same language on both sides: every word would be its own answer.
    when(() => mockLanguage.targetLanguage)
        .thenReturn(const Language(code: 'en', name: 'en'));
    when(() => mockLanguage.nativeLanguage)
        .thenReturn(const Language(code: 'en', name: 'en'));

    for (final boss in TrialBosses.all) {
      await pumpTrial(tester, boss: boss);
      expect(find.textContaining('not enough words'), findsNothing,
          reason: boss.name);
      // An opener with English and Turkish content only moves the run to
      // that pair, and says so instead.
      expect(
        find.textContaining(boss.opener.needsEnTr
            ? 'instead of your languages (EN → EN)'
            : 'Your languages (EN → EN)'),
        findsOneWidget,
        reason: boss.name,
      );
      expect(find.text('START TRIAL'), findsOneWidget, reason: boss.name);
    }

    // And the witch really does read a scroll: English words, Spanish
    // meanings, the first stand-in pair that works.
    await pumpTrial(tester);
    await start(tester);
    for (var i = 0; i < 400; i++) {
      if (find.byType(ScrollWord).evaluate().isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 16));
    }
    final english = bossTrialStockSentences(targetCode: 'en', nativeCode: 'es');
    expect(
      english.where((s) => find.text(s.meaning).evaluate().isNotEmpty),
      hasLength(1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('she reads a scroll with one word hexed', (tester) async {
    await pumpTrial(tester);
    await start(tester);
    await waitForScroll(tester);

    expect(find.text('WHAT IT SHOULD SAY'), findsOneWidget);
    hexedWord(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the hexed word breaks it and hits her', (tester) async {
    await pumpTrial(tester);
    await start(tester);
    await waitForScroll(tester);

    await tapWord(tester, hexedWord(tester));
    expect(find.text('x0'), findsOneWidget, reason: 'still in the air');

    // The pet jumps up at the scroll first; the word flies at her from there.
    await advance(tester, 250);
    expect(find.text('x0'), findsOneWidget);
    await waitFor(tester, find.text('x1'), frames: 120);
    expect(find.textContaining(RegExp(r'^-\d+$')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a wrong word burns the fuse without costing a heart',
      (tester) async {
    await pumpTrial(tester);
    await start(tester);
    await waitForScroll(tester);

    final hexed = hexedWord(tester);
    final wrong = hexed == 0 ? 1 : 0;
    await tapWord(tester, wrong);

    expect(find.text('wrong'), findsOneWidget);
    await advance(tester, 300);
    expect(words(tester)[wrong].state, ScrollWordState.wrong);
    // Tapping it again does nothing; the hex can still be broken.
    await tapWord(tester, wrong);
    await tapWord(tester, hexed);
    await waitFor(tester, find.text('x1'), frames: 120);
    expect(find.text('ribbit'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the fuse running out hexes the pet into a frog', (tester) async {
    await pumpTrial(tester);
    await start(tester);
    await waitForScroll(tester);

    final fuse = BossTrialRules.fuseTime(
      words: words(tester).length,
      patience: BossTrialRules.maxPatience,
    );
    expect(frogOnStage(tester), isFalse);
    await advance(tester, fuse.inMilliseconds + 650);

    expect(find.text('ribbit'), findsOneWidget);
    expect(frogOnStage(tester), isTrue);
    // The scroll stays up showing which word was hexed.
    expect(words(tester).where((w) => w.state == ScrollWordState.hexed),
        hasLength(1));

    // And the pet comes back.
    await advance(tester, 1800);
    expect(frogOnStage(tester), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('three spent fuses end the trial and list the scrolls',
      (tester) async {
    await pumpTrial(tester);
    await start(tester);

    for (var i = 0; i < BossTrialRules.maxHearts; i++) {
      await waitForScroll(tester);
      // Three wrong guesses, and the fuse is gone.
      final hexed = hexedWord(tester);
      for (var w = 0; w < words(tester).length; w++) {
        if (w != hexed) await tapWord(tester, w);
      }
      await advance(tester, 6000);
    }
    await advance(tester, 1500);

    expect(find.text('HOOTHEX FLEW OFF CACKLING'), findsOneWidget);
    expect(find.text('SCROLLS TO PRACTISE'), findsOneWidget);
    expect(find.textContaining('HEX: '), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  // ---- the pet's body --------------------------------------------------------

  double spread(Iterable<double> values) =>
      values.reduce(max) - values.reduce(min);

  Future<void> startWith(WidgetTester tester, String opening) async {
    await pumpTrial(tester);
    await tester.tap(find.text(opening));
    await tester.pump();
    await start(tester);
  }

  testWidgets('scroll: the pet trembles harder as the fuse burns down',
      (tester) async {
    await pumpTrial(tester);
    await start(tester);
    await waitForScroll(tester);
    final fuse = BossTrialRules.fuseTime(
      words: words(tester).length,
      patience: BossTrialRules.maxPatience,
    );

    final pet = PetProbe(tester);
    // Early on it stands steady...
    final early = await pet.track(30);
    expect(spread(early.map((s) => s.x)), lessThan(1.5));
    // ...and near the end it shakes.
    await advance(tester, (fuse.inMilliseconds * 0.75).round() - 500);
    final late = await pet.track(40);
    expect(spread(late.map((s) => s.x)), greaterThan(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('scroll: the pet wobbles, side to side, faster and wider as the '
      'fuse burns down', (tester) async {
    await pumpTrial(tester);
    await start(tester);
    await waitForScroll(tester);
    final fuse = BossTrialRules.fuseTime(
      words: words(tester).length,
      patience: BossTrialRules.maxPatience,
    );
    int crossings(List<PetSample> run) {
      var n = 0;
      for (var i = 1; i < run.length; i++) {
        if (run[i].tilt * run[i - 1].tilt < 0) n++;
      }
      return n;
    }

    final pet = PetProbe(tester);
    final early = await pet.track(60);
    await advance(tester, (fuse.inMilliseconds * 0.75).round() - 1100);
    final late = await pet.track(60);
    // The same second, twice: it goes back and forth more times, further.
    expect(crossings(late), greaterThanOrEqualTo(crossings(early) + 3));
    expect(late.map((s) => s.tilt.abs()).reduce(max),
        greaterThan(early.map((s) => s.tilt.abs()).reduce(max) + 0.04));
    expect(tester.takeException(), isNull);
  });

  testWidgets('scroll: the hexed word tapped, the pet leaps straight up with '
      'its head cocked back and SWATS it off the scroll, which goes flying up '
      'at her turning over', (tester) async {
    await pumpTrial(tester);
    await start(tester);
    await waitForScroll(tester);
    final pet = PetProbe(tester);
    final ground = pet.feet;
    final home = pet.x;

    final scroll = tester.getRect(find.byType(HexScrollBoard));
    final hexed = hexedWord(tester);
    final word = words(tester)[hexed].label;
    expect(find.byType(TangleTile), findsNothing);
    await tapWord(tester, hexed);
    final run = <PetSample>[];
    final flying = <Offset>[];
    final angles = <double>[];
    for (var i = 0; i < 70; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      run.add(pet.sample);
      final tile = find.widgetWithText(TangleTile, word);
      if (tile.evaluate().isNotEmpty) {
        flying.add(tester.getCenter(tile));
        final turn = tester
            .widget<Transform>(find.ancestor(
                of: tile, matching: find.byType(Transform)).first)
            .transform
            .storage;
        angles.add(atan2(turn[1], turn[0]));
      }
    }
    expect(run.msUntil((s) => s.feet < ground - 20), lessThan(150));
    // Up at the scroll: its head goes into the scroll's lower edge...
    expect(run.highestHead, closeTo(scroll.bottom - 10, 10));
    expect(run.take(30).every((s) => (s.x - home).abs() < 1.5), isTrue);
    // ...cocked back on the way up, then swept round at it.
    final dir = run.map((s) => s.tilt).reduce((a, b) => a.abs() > b.abs() ? a : b) < 0
        ? -1.0
        : 1.0;
    expect(run.map((s) => s.tilt * dir).reduce(max), greaterThan(0.7));
    expect(run.map((s) => s.tilt * dir).reduce(min), lessThan(-0.4));
    // The word it swatted goes up toward her, turning over and over.
    expect(flying.length, greaterThan(10));
    expect(flying.first.dy, greaterThan(flying.last.dy));
    var turned = 0.0;
    for (var i = 1; i < angles.length; i++) {
      var d = angles[i] - angles[i - 1];
      if (d > pi) d -= 2 * pi;
      if (d < -pi) d += 2 * pi;
      turned += d.abs();
    }
    expect(turned, greaterThan(pi));
    expect(find.text('x1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a pet hexed into a frog hops twice, then is itself again with '
      'a hop', (tester) async {
    await pumpTrial(tester);
    await start(tester);
    await waitForScroll(tester);
    final ground = PetProbe(tester).feet;

    await waitFor(tester, find.text('ribbit'), frames: 1000);
    final run = await PetProbe(tester).track(135);
    // Two hops as a frog, and one coming back.
    expect(run.hops(ground), 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clones: the pet trots under the lowest owl, facing the way it '
      'goes', (tester) async {
    await startWith(tester, 'CLONES');
    await waitFor(tester, find.byType(OwlBubble));
    await advance(tester, 500);

    final run = await PetProbe(tester).track(150);
    expect(spread(run.map((s) => s.x)), greaterThan(20));
    for (var i = 1; i < run.length; i++) {
      final step = run[i].x - run[i - 1].x;
      if (step.abs() > 1.5) {
        expect(run[i].facesLeft, step < 0, reason: 'frame $i, step $step');
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('clones: the real owl sends the pet leaping tall, across toward '
      'her, to SWAT her at the top of the leap', (tester) async {
    await startWith(tester, 'CLONES');
    await waitFor(tester, find.byType(OwlBubble));
    await advance(tester, 500);
    final pet = PetProbe(tester);
    final ground = pet.feet;

    final real = stock
        .firstWhere((s) => find.text(s.meaning).evaluate().isNotEmpty)
        .target;
    final bubbles = tester.widgetList<OwlBubble>(find.byType(OwlBubble));
    final index = bubbles.toList().indexWhere((b) => b.text == real);
    final owl = find.byKey(ValueKey('owl-$index'));
    // The pet trots under the lowest owl, so wait for a moment when the real
    // one is well to one side of it (unless she is the lowest herself).
    for (var i = 0;
        i < 250 && (tester.getCenter(owl).dx - pet.x).abs() < 50;
        i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final aside = tester.getCenter(owl).dx - pet.x;
    final x0 = pet.x;
    await tester.tap(find.widgetWithText(OwlBubble, real));
    await tester.pump();

    final run = await pet.track(70);
    expect(run.msUntil((s) => s.feet < ground - 20), lessThan(150));
    expect(run.highest, lessThan(ground - 60));
    // Head cocked back on the way up, then swept round at her.
    final side = aside.abs() > 12
        ? (aside < 0 ? -1.0 : 1.0)
        : (run.map((s) => s.tilt).reduce((a, b) => a.abs() > b.abs() ? a : b) < 0
            ? -1.0
            : 1.0);
    expect(run.map((s) => s.tilt * side).reduce(max), greaterThan(0.7));
    expect(run.map((s) => s.tilt * side).reduce(min), lessThan(-0.4));
    if (aside.abs() > 12) {
      // Across toward the owl.
      expect(run.map((s) => (s.x - x0) * side).reduce(max), greaterThan(10));
    }
    await waitFor(tester, find.text('x1'), frames: 120);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clones: a clone makes the pet cringe', (tester) async {
    await startWith(tester, 'CLONES');
    await waitFor(tester, find.byType(OwlBubble));
    await advance(tester, 500);

    final real = stock
        .firstWhere((s) => find.text(s.meaning).evaluate().isNotEmpty)
        .target;
    final clone = tester
        .widgetList<OwlBubble>(find.byType(OwlBubble))
        .firstWhere((b) => b.text != real)
        .text;
    await tester.tap(find.widgetWithText(OwlBubble, clone));
    await tester.pump();
    final run = await PetProbe(tester).track(20);
    expect(run.lowestSquash, lessThan(0.9));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tangle: the pet HOP-WALKS the word on its head to the pot — a '
      'high hop to every step — and lobs it in, high, and the pot fills when it '
      'lands', (tester) async {
    await startWith(tester, 'TANGLE');
    await waitFor(tester, find.byType(Cauldron));
    await advance(tester, 500);
    final pet = PetProbe(tester);
    final home = pet.x;
    final ground = pet.feet;

    final pots = tester.widgetList<Cauldron>(find.byType(Cauldron)).toList();
    final word = tester.widget<TangleTile>(find.byType(TangleTile)).label;
    final pot = pots.firstWhere((p) => stock
        .firstWhere((s) => s.meaning == p.meaning)
        .tokens
        .contains(word));
    final potFinder = find.widgetWithText(Cauldron, pot.meaning);
    final potX = tester.getCenter(potFinder).dx;
    expect(tester.widget<Cauldron>(potFinder).filled, 0);
    await tester.tap(potFinder);
    await tester.pump();

    // Off to the pot at once, facing it, the word riding on its head...
    await advance(tester, 64);
    expect(pet.facesLeft, potX < home);
    expect((pet.x - home).abs(), greaterThan(1));
    // ...lifted onto its head, standing on its ears, and bobbing with it as
    // it goes.
    await advance(tester, 64);
    for (var i = 0; i < 2; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final ridden = tester.getCenter(find.widgetWithText(TangleTile, word));
      expect((ridden.dx - pet.x).abs(), lessThan(6), reason: 'frame $i');
      expect(ridden.dy, closeTo(pet.head - 20, 6), reason: 'frame $i');
    }
    // ...the pot not filled until it has landed in it.
    expect(tester.widget<Cauldron>(potFinder).filled, 0);
    final run = <PetSample>[];
    final lob = <Offset>[];
    final potMouth = tester.getCenter(potFinder);
    for (var i = 0; i < 130; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      run.add(pet.sample);
      final tile = find.widgetWithText(TangleTile, word);
      if (tile.evaluate().isNotEmpty) lob.add(tester.getCenter(tile));
    }
    expect(run.any((s) => (s.x - potX).abs() < 8), isTrue);
    // A hop-walk: a high hop to each step, not a run (which hops ten pixels).
    final walking = run.takeWhile((s) => (s.x - potX).abs() > 14).toList();
    expect(ground - walking.highest, greaterThan(13));
    // Lobbed: the word goes up from its head and over, higher than either end.
    final top = lob.map((o) => o.dy).reduce(min);
    expect(top, lessThan(min(lob.first.dy, potMouth.dy) - 30));
    expect(tester.widget<Cauldron>(potFinder).filled, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tangle: a pot that refuses a word makes the pet hop back from '
      'it', (tester) async {
    await startWith(tester, 'TANGLE');
    await waitFor(tester, find.byType(Cauldron));
    await advance(tester, 500);
    final pet = PetProbe(tester);
    final home = pet.x;

    final word = tester.widget<TangleTile>(find.byType(TangleTile)).label;
    final wrong = tester.widgetList<Cauldron>(find.byType(Cauldron)).firstWhere(
        (p) => !stock
            .firstWhere((s) => s.meaning == p.meaning)
            .tokens
            .contains(word));
    final potX =
        tester.getCenter(find.widgetWithText(Cauldron, wrong.meaning)).dx;
    await tester.tap(find.widgetWithText(Cauldron, wrong.meaning));
    await tester.pump();

    final run = await pet.track(25);
    // Facing the pot, and hopping away from it.
    expect(run.first.facesLeft, potX < home);
    final away = potX < home ? 1.0 : -1.0;
    expect(run.map((s) => (s.x - home) * away).reduce(max), greaterThan(10));
    expect(run.map((s) => s.tilt * away).reduce(max), greaterThan(0.2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('chase: the pet pitches nose up to climb and nose down to dive',
      (tester) async {
    await startWith(tester, 'CHASE');
    await waitFor(tester, find.byType(WordGate));
    final petX = tester.getSize(find.byType(BossTrialScreen)).width * 0.19;
    final ys = tester
        .widgetList<WordGate>(find.byType(WordGate))
        .map((g) => tester.getCenter(find.byWidget(g)).dy);
    final upperY = ys.reduce(min);
    final lowerY = ys.reduce(max);
    final pet = PetProbe(tester);

    // Up: nose up, which on a pet flying right is counter-clockwise.
    await tester.tapAt(Offset(petX, upperY));
    await tester.pump();
    final climb = await pet.track(30);
    expect(climb.map((s) => s.tilt).reduce(min), lessThan(-0.25));
    expect(climb.last.tilt.abs(), lessThan(0.05), reason: 'level again');

    // Down: nose down.
    await tester.tapAt(Offset(petX, lowerY));
    await tester.pump();
    final dive = await pet.track(30);
    expect(dive.map((s) => s.tilt).reduce(max), greaterThan(0.25));
    expect(tester.takeException(), isNull);
  });

  testWidgets('chase: the broom WOBBLES as it flies through a gate — tipped one '
      'way and the other, less each time', (tester) async {
    await startWith(tester, 'CHASE');
    await waitFor(tester, find.byType(WordGate));
    final tokens = stock
        .firstWhere((s) => find.text(s.meaning).evaluate().isNotEmpty)
        .tokens;
    final petX = tester.getSize(find.byType(BossTrialScreen)).width * 0.19;
    final pet = PetProbe(tester);
    final through = find.byWidgetPredicate(
        (w) => w is WordGate && w.state == HexPieceState.right);

    for (var i = 0; i < 1500 && through.evaluate().isEmpty; i++) {
      final ahead = find
          .byWidgetPredicate((w) =>
              w is WordGate &&
              w.state == HexPieceState.plain &&
              tokens.contains(w.label))
          .evaluate()
          .map((e) => tester.getCenter(find.byWidget(e.widget)))
          .where((c) => c.dx > petX - 8)
          .toList()
        ..sort((a, b) => a.dx.compareTo(b.dx));
      if (ahead.isNotEmpty) await tester.tapAt(Offset(petX, ahead.first.dy));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(through, findsWidgets, reason: 'a gate was flown through');
    // Left alone for a moment, it shudders, back and forth.
    final run = await pet.track(30);
    var swings = 0;
    for (var i = 1; i < run.length; i++) {
      if (run[i].tilt * run[i - 1].tilt < 0) swings++;
    }
    expect(swings, greaterThanOrEqualTo(3));
    expect(run.map((s) => s.tilt.abs()).reduce(max), greaterThan(0.15));
    expect(tester.takeException(), isNull);
  });

  testWidgets('chase: a wrong gate spins the pet head over heels',
      (tester) async {
    await startWith(tester, 'CHASE');
    await waitFor(tester, find.byType(WordGate));
    final tokens = stock
        .firstWhere((s) => find.text(s.meaning).evaluate().isNotEmpty)
        .tokens;
    final petX = tester.getSize(find.byType(BossTrialScreen)).width * 0.19;
    final pet = PetProbe(tester);

    // Always in the lane of the wrong gate, until one hits.
    for (var i = 0; i < 2000 && find.text('hex wall').evaluate().isEmpty; i++) {
      final ahead = find
          .byWidgetPredicate((w) =>
              w is WordGate &&
              w.state == HexPieceState.plain &&
              !tokens.contains(w.label))
          .evaluate()
          .map((e) => tester.getCenter(find.byWidget(e.widget)))
          .where((c) => c.dx > petX - 8)
          .toList()
        ..sort((a, b) => a.dx.compareTo(b.dx));
      if (ahead.isNotEmpty) await tester.tapAt(Offset(petX, ahead.first.dy));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text('hex wall'), findsOneWidget);
    final run = await pet.track(50);
    // A whole turn, counter-clockwise (the wall knocks it backwards), and
    // level again after it.
    expect(run.turned, closeTo(-2 * pi, 0.4));
    expect(run.last.tilt.abs(), lessThan(0.1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('chase: the whole spell is cast, the pet rearing back on its '
      'broom, and it hops off at the end', (tester) async {
    await startWith(tester, 'CHASE');
    final bank = PetProbe(tester).sample;
    await waitFor(tester, find.byType(WordGate));
    final tokens = stock
        .firstWhere((s) => find.text(s.meaning).evaluate().isNotEmpty)
        .tokens;
    final petX = tester.getSize(find.byType(BossTrialScreen)).width * 0.19;
    final pet = PetProbe(tester);
    expect(pet.height, lessThan(bank.height * 0.7), reason: 'on the broom');

    final seen = <PetSample>[];
    for (var i = 0; i < 1500 && find.textContaining(RegExp(r'^-\d+$')).evaluate().isEmpty; i++) {
      final ahead = find
          .byWidgetPredicate((w) =>
              w is WordGate &&
              w.state == HexPieceState.plain &&
              tokens.contains(w.label))
          .evaluate()
          .map((e) => tester.getCenter(find.byWidget(e.widget)))
          .where((c) => c.dx > petX - 8)
          .toList()
        ..sort((a, b) => a.dx.compareTo(b.dx));
      if (ahead.isNotEmpty) await tester.tapAt(Offset(petX, ahead.first.dy));
      await tester.pump(const Duration(milliseconds: 16));
      seen.add(pet.sample);
    }
    expect(find.textContaining(RegExp(r'^-\d+$')), findsOneWidget);
    // In the last moments before the hit: leaned back, then forward at her.
    final last = seen.skip(max(0, seen.length - 60)).toList();
    expect(last.map((s) => s.tilt).reduce(min), lessThan(-0.2));
    expect(last.map((s) => s.tilt).reduce(max), greaterThan(0.3));
    // The throw kicks it back, broom and all, off where it sat.
    expect(last.map((s) => s.x).reduce(min), lessThan(petX - 10));

    // Then off the broom: a hop forward, tipped that way, and down to the bank
    // in one fall — not a jump from one place to the other — growing back to
    // its full size as it comes down...
    final after = await pet.track(110);
    final rise = after.indexWhere((s) => s.tilt > 0.15);
    expect(rise, greaterThan(0), reason: 'it hops forward off the broom');
    final landed = after.indexWhere((s) => s.squash < 0.85);
    expect(landed, greaterThan(rise), reason: 'it squats as it lands');
    expect(after[landed].feet, closeTo(bank.feet, 8));
    expect(after[landed].height, greaterThan(bank.height * 0.75));
    expect(
        after.sublist(rise, landed).any((s) =>
            s.height > bank.height * 0.7 && s.height < bank.height * 0.95),
        isTrue,
        reason: 'it grows as it falls');
    for (var i = 1; i <= landed; i++) {
      expect((after[i].feet - after[i - 1].feet).abs(), lessThan(30),
          reason: 'frame $i');
    }
    // ...where it landed, and then home, standing as it did at the start.
    expect(after[landed + 3].x, closeTo(after[landed].x, 1));
    final home = after.indexWhere((s) =>
        s.squash > 0.99 &&
        (s.x - bank.x).abs() < 2 &&
        s.height > bank.height - 1);
    expect(home, greaterThan(landed));
    expect(after[home].feet, closeTo(bank.feet, 3));
    expect(after[home].facesLeft, isFalse);
    expect(tester.takeException(), isNull);
  });
}
