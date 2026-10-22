import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/boss_trial/hoothex_pieces.dart';
import 'package:mojilearner_flutter/components/boss_trial/mossback_pieces.dart';
import 'package:mojilearner_flutter/components/boss_trial/trial_boss.dart';
import 'package:mojilearner_flutter/components/character_sprite.dart';
import 'package:mojilearner_flutter/constants/boss_trial_sentences.dart';
import 'package:mojilearner_flutter/constants/boss_trial_words.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/screens/boss_trial_screen.dart';
import 'package:mojilearner_flutter/utils/boss_trial.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// Mossback's and the witch's openers under test beside their own: Shell
/// Game, Pebble Pop and Stepping Stones; Mirror Clones, Tangled Spells and
/// Broom Chase.
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

  final words = bossTrialStockWords(targetCode: 'es', nativeCode: 'en');
  final sentences = bossTrialStockSentences(targetCode: 'es', nativeCode: 'en');

  // Never loaded from storage: awaiting SecureStorage under testWidgets'
  // FakeAsync deadlocks. See quiz_screen_srs_test.
  Future<void> startWith(
    WidgetTester tester,
    TrialBoss boss,
    String opening,
  ) async {
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

  Future<void> advance(WidgetTester tester, int ms) async {
    for (var t = 0; t < ms; t += 16) {
      await tester.pump(const Duration(milliseconds: 16));
    }
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

  /// The stock word Mossback is shouting.
  TrialWord shouted() =>
      words.firstWhere((w) => find.text(w.target).evaluate().isNotEmpty);

  // ---- Mossback: Shell Game ------------------------------------------------

  /// From the cups coming up to the end of a fresh boss's shuffle: rising,
  /// the meanings, the flip, and three half-second swaps.
  const shuffled = 250 + 2400 + 200 + 3 * 500;

  testWidgets('shells: no pick until the cups stop; then the right one hits',
      (tester) async {
    await startWith(tester, TrialBosses.mossback, 'SHELLS');
    await waitFor(tester, find.byType(ShellSlab));
    await advance(tester, 400);
    final right = shouted().meaning;

    // While the meanings show: nothing.
    await tester.tap(find.widgetWithText(ShellSlab, right));
    await tester.pump();
    await advance(tester, 450);
    expect(damage, findsNothing);
    expect(find.text('wrong'), findsNothing);

    // Nor mid-shuffle.
    await advance(tester, 2400);
    await tester.tap(find.widgetWithText(ShellSlab, right), warnIfMissed: false);
    await tester.pump();
    expect(damage, findsNothing);

    // Once they stop, the cup it went under.
    await advance(tester, shuffled - 400 - 450 - 2400 + 100);
    await tester.tap(find.widgetWithText(ShellSlab, right), warnIfMissed: false);
    await tester.pump();
    // The stone goes up out of the cup at the boss.
    await advance(tester, 150);
    expect(find.text('x0'), findsOneWidget);
    await advance(tester, 300);
    expect(find.text('x1'), findsOneWidget);
    expect(damage, findsOneWidget);
    expect(find.text('quick!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shells: a wrong cup costs a heart, and slowness the streak',
      (tester) async {
    await startWith(tester, TrialBosses.mossback, 'SHELLS');
    await waitFor(tester, find.byType(ShellSlab));
    await advance(tester, 400);

    final right = shouted().meaning;
    final wrong = tester
        .widgetList<ShellSlab>(find.byType(ShellSlab))
        .firstWhere((s) => s.label != right)
        .label;
    await advance(tester, shuffled - 400 + 100);
    await tester.tap(find.widgetWithText(ShellSlab, wrong), warnIfMissed: false);
    await tester.pump();
    // The stone is on its way to the pet; the sting is when it lands.
    expect(find.text('wrong'), findsNothing);
    await advance(tester, 500);
    expect(find.text('wrong'), findsOneWidget);

    // The next game, left alone until it gives up.
    await waitFor(tester, find.text('too slow'));
    expect(tester.takeException(), isNull);
  });

  // ---- Mossback: Pebble Pop ------------------------------------------------

  /// The word whose meaning the sign asks for.
  TrialWord asked() =>
      words.firstWhere((w) => find.text(w.meaning).evaluate().isNotEmpty);

  testWidgets('pebbles: bonking the one asked for hits', (tester) async {
    await startWith(tester, TrialBosses.mossback, 'PEBBLES');
    await waitFor(tester, find.text('BONK THE WORD FOR'));
    final target = asked().target;
    await waitFor(tester, find.widgetWithText(PebbleTile, target));
    await advance(tester, 150);

    await tester.tap(find.widgetWithText(PebbleTile, target));
    await tester.pump();
    // The pet jumps at once, and the pebble bursts into the shot as it lands.
    await advance(tester, 250);
    expect(find.text('x0'), findsOneWidget);
    await advance(tester, 600);
    expect(find.text('x1'), findsOneWidget);
    expect(damage, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'pebbles: a wrong pebble costs a heart; missing them all the '
      'streak', (tester) async {
    await startWith(tester, TrialBosses.mossback, 'PEBBLES');
    await waitFor(tester, find.text('BONK THE WORD FOR'));
    final target = asked().target;
    await waitFor(
      tester,
      find.byWidgetPredicate((w) => w is PebbleTile && w.label != target),
    );
    await advance(tester, 150);
    await tester.tap(find
        .byWidgetPredicate((w) => w is PebbleTile && w.label != target)
        .first);
    await tester.pump();
    expect(find.text('wrong'), findsOneWidget);

    await waitFor(tester, find.text('too slow'));
    expect(tester.takeException(), isNull);
  });

  // ---- Mossback: Stepping Stones -------------------------------------------

  Finder stoneFor(String meaning) => find.byWidgetPredicate(
      (w) => w is SteppingStone && w.label == meaning && w.onTapDown != null);

  /// The stones to hop onto, once they are up out of the river and the boss
  /// has landed; before that they are there but under the water.
  final liveStone = find.byWidgetPredicate(
      (w) => w is SteppingStone && w.onTapDown != null);

  final river = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is RiverPainter);

  testWidgets('stones: four right hops land a headbutt', (tester) async {
    await startWith(tester, TrialBosses.mossback, 'STONES');
    await waitFor(tester, liveStone);
    await advance(tester, 200);

    for (var row = 0; row < 4; row++) {
      await tester.tap(stoneFor(shouted().meaning));
      await tester.pump();
      await advance(tester, 250);
    }
    expect(find.text('across!'), findsOneWidget);
    // The pet gathers itself for a second, then the headbutt lands.
    expect(damage, findsNothing);
    await advance(tester, 1250);
    expect(find.text('x4'), findsOneWidget);
    expect(damage, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stones: the headbutt leaps off the last stone and falls back '
      'to the start of the arena', (tester) async {
    await startWith(tester, TrialBosses.mossback, 'STONES');
    await waitFor(tester, liveStone);
    await advance(tester, 200);

    // Where the pet starts the crossing: on the bank, at its stone-hopping
    // size. The sprite's box runs a tenth below its feet (`_buildPet`).
    final pet = find.byType(CharacterSprite).first;
    final start = tester.getRect(pet);
    final startFeet = start.bottom - start.height * 0.1;

    for (var row = 0; row < 3; row++) {
      await tester.tap(stoneFor(shouted().meaning));
      await tester.pump();
      await advance(tester, 250);
    }
    final last = stoneFor(shouted().meaning);
    final stone = tester.getRect(last);
    await tester.tap(last);

    // Where the pet's feet are, where its middle is, how big it is and how
    // far it is tipped over, frame by frame, for a little past the end.
    final feet = <double>[];
    final middle = <double>[];
    final heights = <double>[];
    final tilt = <double>[];
    for (var i = 0; i < 140; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final box = tester.getRect(pet);
      feet.add(box.bottom - box.height * 0.1);
      middle.add(box.center.dx);
      heights.add(box.height);
      final m = tester
          .widget<Transform>(find.byKey(const ValueKey('pet-tilt')))
          .transform
          .storage;
      tilt.add(math.atan2(m[1], m[0]));
    }

    // The frame the pet is back on the bank is the end of the headbutt.
    final end = feet.indexWhere((f) => (f - startFeet).abs() < 1.5);
    expect(end, greaterThan(0), reason: 'it never came back to the bank');

    // It gathers itself for a full second before it leaves the stone...
    final launch = feet.indexWhere((f) => f < stone.top - 20);
    expect(launch * 16, inInclusiveRange(950, 1250));
    // Upright and on its stone — shivering, but not leaving it — until then.
    expect(tilt.take(55).every((a) => a.abs() < 0.001), isTrue);
    expect(feet.skip(30).take(25).every((f) => f > stone.top - 4), isTrue);

    // ...goes up well clear of it, the damage landing at the top...
    final apex = feet.take(end).reduce((a, b) => a < b ? a : b);
    expect(apex, lessThan(stone.top - 40));

    // ...tipped over 30 degrees there, and upright again on the way down...
    final peak = tilt.take(end).reduce((a, b) => a.abs() > b.abs() ? a : b);
    expect(peak.abs(), closeTo(math.pi / 6, 0.01));
    expect(tilt[end - 1].abs(), lessThan(0.1));

    // ...then it is back where it started the crossing — on the bank, in the
    // middle, and full size again — not on the stone it leapt from. The
    // leap and the fall are quick: the whole headbutt is under two seconds.
    expect(middle[end], closeTo(start.center.dx, 1));
    expect(heights[end], closeTo(start.height / 0.6, 2));
    // The fall itself gets there — no snap from the stone on the last frame.
    expect(feet[end - 1], closeTo(startFeet, 40));
    expect(middle[end - 1], closeTo(start.center.dx, 20));
    expect(startFeet, greaterThan(stone.top + 60));
    expect((end + 1) * 16, inInclusiveRange(1700, 2200));
    expect(tester.takeException(), isNull);
  });

  /// Whether the pet is turned to face left (its art faces right).
  bool facesLeft(WidgetTester tester) => tester
      .widget<Transform>(find.byKey(const ValueKey('pet-flip')))
      .transform
      .storage[0] < 0;

  /// The pet's feet for [frames] frames running, each frame: its sprite's box
  /// runs a tenth below them.
  Future<List<double>> trackFeet(WidgetTester tester, int frames) async {
    final pet = find.byType(CharacterSprite).first;
    final feet = <double>[];
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final box = tester.getRect(pet);
      feet.add(box.bottom - box.height * 0.1);
    }
    return feet;
  }

  double squashOf(WidgetTester tester) => tester
      .widget<Transform>(find.byKey(const ValueKey('pet-squash')))
      .transform
      .storage[5];

  testWidgets('shells: the pet does not move; the stone of a right cup goes '
      'at the boss', (tester) async {
    await startWith(tester, TrialBosses.mossback, 'SHELLS');
    await waitFor(tester, find.byType(ShellSlab));
    await advance(tester, 400);
    final right = shouted().meaning;
    await advance(tester, shuffled - 400 + 100);

    final pet = find.byType(CharacterSprite).first;
    final start = tester.getRect(pet);
    final startFeet = start.bottom - start.height * 0.1;
    await tester.tap(find.widgetWithText(ShellSlab, right),
        warnIfMissed: false);
    await tester.pump();

    // Through the whole throw and after, the pet stays where it stands: on
    // the ground, in place, not squashed or tipped.
    final feet = await trackFeet(tester, 60);
    expect(feet.every((f) => (f - startFeet).abs() < 1.5), isTrue);
    expect(tester.getRect(pet).center.dx, closeTo(start.center.dx, 1));
    expect(squashOf(tester), 1);
    // And the stone hit the boss.
    expect(find.text('x1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shells: the stone of a wrong cup comes down on the pet, which '
      'is squashed and springs back up', (tester) async {
    await startWith(tester, TrialBosses.mossback, 'SHELLS');
    await waitFor(tester, find.byType(ShellSlab));
    await advance(tester, 400);
    final right = shouted().meaning;
    final wrong = tester
        .widgetList<ShellSlab>(find.byType(ShellSlab))
        .firstWhere((s) => s.label != right)
        .label;
    await advance(tester, shuffled - 400 + 100);

    final pet = find.byType(CharacterSprite).first;
    final start = tester.getRect(pet);
    await tester.tap(find.widgetWithText(ShellSlab, wrong),
        warnIfMissed: false);
    await tester.pump();

    final squashes = <double>[];
    final feet = <double>[];
    final xs = <double>[];
    for (var i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      squashes.add(squashOf(tester));
      final box = tester.getRect(pet);
      feet.add(box.bottom - box.height * 0.1);
      xs.add(box.center.dx);
    }
    // Nothing happens to it until the stone lands, a third of a second on...
    final hit = squashes.indexWhere((s) => s < 0.99);
    expect(hit * 16, inInclusiveRange(250, 700));
    expect(squashes.take(hit).every((s) => s == 1), isTrue);
    // ...then it is pressed flat for a good beat...
    expect(squashes.reduce(math.min), closeTo(0.5, 0.06));
    expect(squashes.where((s) => s < 0.6).length * 16, greaterThan(400));
    // ...without ever leaving where it stands, bar its hurt shake...
    expect(
        xs.map((x) => (x - start.center.dx).abs()).reduce(math.max), lessThan(12));
    // ...and springs back up with a hop.
    final ground = feet.reduce(math.max);
    final flatEnds = squashes.lastIndexWhere((s) => s < 0.6);
    expect(feet.skip(flatEnds).take(30).reduce(math.min), lessThan(ground - 20));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pebbles: the pet watches each pop, and jumps the moment the '
      'right one is bonked', (tester) async {
    await startWith(tester, TrialBosses.mossback, 'PEBBLES');
    await waitFor(tester, find.text('BONK THE WORD FOR'));
    final target = asked().target;
    final pet = find.byType(CharacterSprite).first;

    // The first pebble up: the pet is turned to it.
    await waitFor(tester, find.byType(PebbleTile));
    final firstX = tester.getCenter(find.byType(PebbleTile).first).dx;
    final standing = tester.getRect(pet);
    if ((firstX - standing.center.dx).abs() > 12) {
      expect(facesLeft(tester), firstX < standing.center.dx);
    }

    await waitFor(tester, find.widgetWithText(PebbleTile, target));
    await advance(tester, 150);
    // Where it stands, settled, before it jumps.
    final start = tester.getRect(pet);
    final startFeet = start.bottom - start.height * 0.1;
    final pebble = find.widgetWithText(PebbleTile, target);
    final pebbleX = tester.getCenter(pebble).dx;
    await tester.tap(pebble);
    await tester.pump();
    if ((pebbleX - start.center.dx).abs() > 1) {
      expect(facesLeft(tester), pebbleX < start.center.dx);
    }

    // No gathering: a moment later it is already in the air, and the pebble
    // is held up where it was...
    await advance(tester, 150);
    expect(find.widgetWithText(PebbleTile, target), findsOneWidget);
    final box = tester.getRect(pet);
    expect(box.bottom - box.height * 0.1, lessThan(startFeet - 20));

    // ...up to the pebble, which bursts as the pet lands on it...
    final feet = await trackFeet(tester, 100);
    final apex = feet.reduce(math.min);
    expect(apex, lessThan(startFeet - 60));
    expect(find.widgetWithText(PebbleTile, target), findsNothing);
    // ...and back down where it began, standing as its art is drawn.
    expect(tester.getRect(pet).center.dx, closeTo(start.center.dx, 1));
    expect(facesLeft(tester), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stones: the pet faces the way it hops, and the boss for the '
      'headbutt', (tester) async {
    await startWith(tester, TrialBosses.mossback, 'STONES');
    final pet = find.byType(CharacterSprite).first;

    // Two crossings, so the lanes drawn at random send it both ways.
    var hops = 0;
    var leftHops = 0;
    for (var crossing = 0; crossing < 2; crossing++) {
      await waitFor(tester, liveStone);
      await advance(tester, 200);
      // At the start of a crossing it stands as its art is drawn, on the bank
      // in the middle of the arena — which is where the boss is.
      expect(facesLeft(tester), isFalse);
      final middle = tester.getRect(pet).center.dx;

      late double lastStone;
      for (var row = 0; row < 4; row++) {
        final stone = stoneFor(shouted().meaning);
        final from = tester.getRect(pet).center.dx;
        lastStone = tester.getCenter(stone).dx;
        final before = facesLeft(tester);
        await tester.tap(stone);
        await tester.pump();

        // Turned to the stone it hops to; straight up, it keeps its facing.
        final across = (lastStone - from).abs() > 0.5;
        expect(facesLeft(tester), across ? lastStone < from : before,
            reason: 'hop $row of crossing $crossing, from $from to $lastStone');
        if (across) hops++;
        if (across && lastStone < from) leftHops++;
        await advance(tester, 250);
      }

      // Landed on the last stone, it turns to the boss in the middle: the two
      // left-hand stones face right, the two right-hand ones face left...
      await advance(tester, 350);
      expect(facesLeft(tester), lastStone > middle,
          reason: 'on the last stone, at $lastStone, the middle at $middle');
      // ...and stays turned to it through the leap and the fall.
      await advance(tester, 700);
      expect(facesLeft(tester), lastStone > middle);
    }
    expect(hops, greaterThan(0));
    expect(leftHops, lessThanOrEqualTo(hops));
    expect(tester.takeException(), isNull);
  });

  testWidgets('stones: a dunked pet comes back on the bank as itself, with a '
      'hop', (tester) async {
    await startWith(tester, TrialBosses.mossback, 'STONES');
    await waitFor(tester, liveStone);
    await advance(tester, 200);

    final pet = find.byType(CharacterSprite).first;
    final start = tester.getRect(pet);
    final startFeet = start.bottom - start.height * 0.1;

    final right = shouted().meaning;
    final wrong = tester
        .widgetList<SteppingStone>(find.byWidgetPredicate(
            (w) => w is SteppingStone && w.onTapDown != null))
        .firstWhere((s) => s.label != right)
        .label;
    final wrongX = tester.getCenter(stoneFor(wrong)).dx;
    await tester.tap(stoneFor(wrong));
    await tester.pump();
    // It hopped toward the wrong stone, facing it...
    expect(facesLeft(tester),
        (wrongX - start.center.dx).abs() > 0.5 ? wrongX < start.center.dx : false);

    // Under the water, and back on the bank, frame by frame: whether the pet
    // is cut off at the water line, and where its feet are.
    final feet = <double>[];
    final underwater = <bool>[];
    final waterBox = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == RiverPainter.water);
    for (var i = 0; i < 92; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final box = tester.getRect(pet);
      feet.add(box.bottom - box.height * 0.1);
      final clip = tester
          .widget<ClipRect>(find.byKey(const ValueKey('pet-waterline')))
          .clipper as WaterlineClipper;
      underwater.add(clip.line != null);
      // No blue square over the pet, going under or coming back.
      expect(waterBox, findsNothing);
    }

    // It goes under the water line for about the first 0.9s...
    final up = underwater.lastIndexOf(true);
    expect(underwater.take(up + 1).every((u) => u), isTrue);
    expect((up + 1) * 16, inInclusiveRange(800, 1000));

    // ...and is back where it began, at full size, not sunk into the bank,
    // standing as its art is drawn again.
    final box = tester.getRect(pet);
    expect(feet.last, closeTo(startFeet, 1));
    expect(box.height, closeTo(start.height / 0.6, 2));
    expect(facesLeft(tester), isFalse);

    // Having hopped up on the bank on the way, a small jump.
    final hop = startFeet - feet.skip(up + 2).reduce((a, b) => a < b ? a : b);
    expect(hop, inInclusiveRange(10, 40));
    expect(tester.takeException(), isNull);
  });

  testWidgets('stones: the river stays up between crossings, and the stones '
      'rise out of it while the boss jumps', (tester) async {
    await startWith(tester, TrialBosses.mossback, 'STONES');
    await waitFor(tester, find.byType(SteppingStone));

    // The boss has just jumped: the river is there, the stones are under it.
    List<SteppingStone> stones() =>
        tester.widgetList<SteppingStone>(find.byType(SteppingStone)).toList();
    expect(river, findsOneWidget);
    expect(stones().every((s) => s.sunk > 0.8 && s.onTapDown == null), isTrue);

    // Rising bottom row first, the top row not as far up yet...
    await advance(tester, 300);
    expect(river, findsOneWidget);
    expect(stones().first.sunk, lessThan(stones().last.sunk));
    expect(stones().first.sunk, lessThan(0.6));
    expect(stones().last.sunk, greaterThan(0));

    // ...all up, and tappable, as the boss lands.
    await waitFor(tester, liveStone);
    await advance(tester, 100);
    expect(stones().every((s) => s.sunk == 0), isTrue);

    // Across, the headbutt, the stones sinking away, the gap, and the next
    // jump: the river never goes, whatever the stones are doing.
    for (var row = 0; row < 4; row++) {
      await tester.tap(stoneFor(shouted().meaning));
      await tester.pump();
      await advance(tester, 250);
    }
    var gapSeen = false;
    var sinkingSeen = false;
    var nextRiseSeen = false;
    for (var i = 0; i < 260; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(river, findsOneWidget, reason: 'the river went at frame $i');
      final now = stones();
      if (now.isEmpty) gapSeen = true;
      if (!gapSeen && now.any((s) => s.sunk > 0 && s.onTapDown == null)) {
        sinkingSeen = true;
      }
      if (gapSeen && now.isNotEmpty && now.every((s) => s.sunk == 1)) {
        nextRiseSeen = true;
      }
    }
    expect(sinkingSeen, isTrue, reason: 'the stones never sank away');
    expect(gapSeen, isTrue, reason: 'there was never a gap with only water');
    expect(nextRiseSeen, isTrue, reason: 'the next stones never came up');
    expect(tester.takeException(), isNull);
  });

  testWidgets('stones: a wrong stone dunks the pet and costs a heart',
      (tester) async {
    await startWith(tester, TrialBosses.mossback, 'STONES');
    await waitFor(tester, liveStone);
    await advance(tester, 200);

    final right = shouted().meaning;
    final wrong = tester
        .widgetList<SteppingStone>(find.byWidgetPredicate(
            (w) => w is SteppingStone && w.onTapDown != null))
        .firstWhere((s) => s.label != right)
        .label;
    await tester.tap(stoneFor(wrong));
    await tester.pump();
    expect(find.text('wrong'), findsOneWidget);

    // A fresh crossing follows, from the bank.
    await advance(tester, 2500);
    await waitFor(tester, liveStone);
    expect(tester.takeException(), isNull);
  });

  // ---- the witch: Mirror Clones --------------------------------------------

  TrialSentence prompted() =>
      sentences.firstWhere((s) => find.text(s.meaning).evaluate().isNotEmpty);

  bool frogOnStage(WidgetTester tester) => tester
      .widgetList<CharacterSprite>(find.byType(CharacterSprite))
      .any((s) => s.previewType == 'frog');

  testWidgets('clones: tapping the real one hits her; a clone burns the fuse',
      (tester) async {
    await startWith(tester, TrialBosses.witch, 'CLONES');
    await waitFor(tester, find.byType(OwlBubble));
    await advance(tester, 500);

    expect(find.byType(OwlBubble), findsNWidgets(3));
    final real = prompted().target;
    final clone = tester
        .widgetList<OwlBubble>(find.byType(OwlBubble))
        .firstWhere((b) => b.text != real)
        .text;
    await tester.tap(find.widgetWithText(OwlBubble, clone));
    await tester.pump();
    expect(find.text('clone!'), findsOneWidget);
    expect(find.byType(OwlBubble), findsNWidgets(2));

    await tester.tap(find.widgetWithText(OwlBubble, real));
    await tester.pump();
    // The pet leaps for her first; the spell leaves it at the top.
    await advance(tester, 200);
    expect(damage, findsNothing);
    await waitFor(tester, damage, frames: 120);
    expect(damage, findsOneWidget);
    expect(find.text('ribbit'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clones: the fuse running out hexes the pet', (tester) async {
    await startWith(tester, TrialBosses.witch, 'CLONES');
    await waitFor(tester, find.text('ribbit'));
    expect(frogOnStage(tester), isTrue);
    expect(tester.takeException(), isNull);
  });

  // ---- the witch: Tangled Spells -------------------------------------------

  testWidgets('tangle: sorting every word hits her word by word',
      (tester) async {
    await startWith(tester, TrialBosses.witch, 'TANGLE');
    await waitFor(tester, find.byType(Cauldron));
    await advance(tester, 500);

    final pots = tester.widgetList<Cauldron>(find.byType(Cauldron)).toList();
    TrialSentence spellOf(Cauldron pot) =>
        sentences.firstWhere((s) => s.meaning == pot.meaning);

    // Every word of both spells, one after another.
    var sorted = 0;
    while (sorted < 20) {
      // The pet hop-walks each word over to its pot and lobs it in, which
      // takes it a moment; the next word waits on its own meanwhile.
      for (var f = 0;
          f < 300 && find.byType(TangleTile).evaluate().length != 1;
          f++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final word = tester.widget<TangleTile>(find.byType(TangleTile)).label;
      final pot = pots.firstWhere((p) => spellOf(p).tokens.contains(word));
      await tester.tap(find.widgetWithText(Cauldron, pot.meaning));
      await tester.pump();
      sorted++;
      // No next word waiting: that was the last, and only it is left, riding.
      if (find.byType(TangleTile).evaluate().length == 1) break;
    }
    expect(sorted, greaterThanOrEqualTo(3));
    await waitFor(tester, find.text('x$sorted'), frames: 240);
    expect(find.text('x$sorted'), findsOneWidget);
    expect(find.text('ribbit'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tangle: the wrong pot is refused and burns the fuse',
      (tester) async {
    await startWith(tester, TrialBosses.witch, 'TANGLE');
    await waitFor(tester, find.byType(Cauldron));
    await advance(tester, 500);

    final word = tester.widget<TangleTile>(find.byType(TangleTile)).label;
    final wrong = tester.widgetList<Cauldron>(find.byType(Cauldron)).firstWhere(
        (p) => !sentences
            .firstWhere((s) => s.meaning == p.meaning)
            .tokens
            .contains(word));
    await tester.tap(find.widgetWithText(Cauldron, wrong.meaning));
    await tester.pump();
    expect(find.text('wrong pot'), findsOneWidget);
    // Still waiting to be sorted.
    expect(find.widgetWithText(TangleTile, word), findsOneWidget);

    await waitFor(tester, find.text('ribbit'));
    expect(tester.takeException(), isNull);
  });

  // ---- the witch: Broom Chase ----------------------------------------------

  testWidgets('chase: flying through the right gates fires the spell',
      (tester) async {
    await startWith(tester, TrialBosses.witch, 'CHASE');
    await waitFor(tester, find.byType(WordGate));
    final tokens = prompted().tokens;
    final petX = tester.getSize(find.byType(BossTrialScreen)).width * 0.19;

    for (var i = 0; i < 1200 && damage.evaluate().isEmpty; i++) {
      // The nearest gate not yet reached with a word of the sentence on it
      // is the one to be in the lane of.
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
      if (ahead.isNotEmpty) {
        await tester.tapAt(Offset(petX, ahead.first.dy));
      }
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(damage, findsOneWidget);
    expect(find.text('hex wall'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chase: a wrong gate lets her away; away altogether hexes',
      (tester) async {
    await startWith(tester, TrialBosses.witch, 'CHASE');
    await waitFor(tester, find.byType(WordGate));
    final tokens = prompted().tokens;
    final petX = tester.getSize(find.byType(BossTrialScreen)).width * 0.19;

    // Always in the lane of the wrong gate.
    for (var i = 0; i < 2000 && find.text('ribbit').evaluate().isEmpty; i++) {
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
      if (ahead.isNotEmpty) {
        await tester.tapAt(Offset(petX, ahead.first.dy));
      }
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text('ribbit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
