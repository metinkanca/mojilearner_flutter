import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/boss_trial/sphinx_pieces.dart';
import 'package:mojilearner_flutter/components/boss_trial/trial_boss.dart';
import 'package:mojilearner_flutter/components/boss_trial/trial_skin.dart';
import 'package:mojilearner_flutter/constants/boss_trial_en_tr.dart';
import 'package:mojilearner_flutter/constants/boss_trial_words.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/screens/boss_trial_screen.dart';
import 'package:mojilearner_flutter/utils/boss_trial_angler.dart';
import 'package:mojilearner_flutter/utils/boss_trial_sphinx.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pet_probe.dart';
import '../helpers/pump_app.dart';

/// What the pet does with its body in Sableth's four openers, each its own:
/// the Riddle's stamp and the crack, the Door's pirouette dial and its
/// shoulder charge, the Tablets carried to their slots, and the Storm's lean
/// into the wind and the howl.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCharacterProvider mockCharacter;
  late MockLanguageProvider mockLanguage;
  final content = EnTrContent.of('tr', 'en')!;
  final words = bossTrialStockWords(targetCode: 'tr', nativeCode: 'en');

  setUp(() {
    mockCharacter = MockCharacterProvider();
    mockLanguage = MockLanguageProvider();
    when(() => mockCharacter.currentCharacterType).thenReturn('cat');
    when(() => mockLanguage.targetLanguage)
        .thenReturn(const Language(code: 'tr', name: 'tr'));
    when(() => mockLanguage.nativeLanguage)
        .thenReturn(const Language(code: 'en', name: 'en'));
  });

  Future<void> startWith(WidgetTester tester, String opening) async {
    await pumpApp(
      tester,
      BossTrialScreen(key: UniqueKey(), boss: TrialBosses.sphinx),
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

  Finder tablet(String label) =>
      find.byWidgetPredicate((w) => w is SkinTile && w.label == label);

  String talk(WidgetTester tester) =>
      tester.widget<TalkPanel>(find.byType(TalkPanel)).text;

  /// Where the pet's head can reach under [thing]: into its lower edge, as far
  /// as a leap goes.
  double headAt(PetProbe pet, Rect thing, {required double rest}) => min(
      rest, max(thing.bottom - 10, rest - pet.size.height * 2.6));

  // ---- Riddle ---------------------------------------------------------------

  testWidgets('riddle: the right tablet is STAMPED — the pet springs up under '
      'it, drives its head in and pushes, the stone shoved up with a seal cut '
      'in it', (tester) async {
    await startWith(tester, 'RIDDLE');
    await waitFor(tester, find.byType(SkinTile));
    await advance(tester, 300);
    final pet = PetProbe(tester);
    final ground = pet.feet;
    final rest = pet.head;
    final riddle =
        content.riddles.firstWhere((r) => talk(tester).contains(r.question));
    final right = tablet(riddle.answers.first);
    final box = tester.getRect(right);

    expect(find.byType(SealMark), findsNothing);
    await tester.tap(right);
    await tester.pump();
    final stamp = <PetSample>[];
    final tops = <double>[];
    var sealed = false;
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      stamp.add(pet.sample);
      tops.add(tester.getRect(right).top);
      sealed |= find.byType(SealMark).evaluate().isNotEmpty;
    }
    // Up at the stone at once, stretched, its head driven into the edge...
    final top = stamp.highestHead;
    expect(top, closeTo(headAt(pet, box, rest: rest), 14));
    expect(stamp.map((s) => s.squash).reduce(max), greaterThan(1.1));
    // ...and pushing there a while, rather than bouncing off it...
    final held = stamp.where((s) => s.head < top + 6).length;
    expect(held, greaterThan(14), reason: 'pressed against it');
    // ...the stone shoved up into its place, with the pet's seal cut in it.
    expect(box.top - tops.reduce(min), greaterThan(4));
    expect(sealed, isTrue);
    // Then it lets go and drops with a thud, and the spell is on its way.
    await waitFor(tester, damage, frames: 150);
    final back = await pet.track(60);
    expect(back.last.feet, closeTo(ground, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('riddle: a wrong tablet is rammed and CRACKS, and the pet is '
      'thrown straight off it, tipped away, and lands wincing', (tester) async {
    await startWith(tester, 'RIDDLE');
    await waitFor(tester, find.byType(SkinTile));
    await advance(tester, 300);
    final pet = PetProbe(tester);
    final ground = pet.feet;
    final rest = pet.head;
    final riddle =
        content.riddles.firstWhere((r) => talk(tester).contains(r.question));
    final wrong = tablet(riddle.answers[1]);
    final box = tester.getRect(wrong);

    expect(find.byType(TabletCrack), findsNothing);
    await tester.tap(wrong);
    await tester.pump();
    final ram = await pet.track(80);
    expect(ram.highestHead, closeTo(headAt(pet, box, rest: rest), 14));
    expect(find.byType(TabletCrack), findsOneWidget);
    // Flung back at once, not held there — and tipped over away from it...
    final top = ram.highestHead;
    expect(ram.where((s) => s.head < top + 6).length, lessThan(7));
    expect(ram.map((s) => s.tilt.abs()).reduce(max), greaterThan(0.35));
    // ...to land in a wince, and stand up again.
    expect(ram.lowestSquash, lessThan(0.85));
    expect(ram.last.feet, closeTo(ground, 2));
    expect(tester.takeException(), isNull);
  });

  // ---- Door -----------------------------------------------------------------

  SealedDoor door(WidgetTester tester) =>
      tester.widget<SealedDoor>(find.byType(SealedDoor));

  testWidgets('door: each turn of the dial is a pirouette — the pet spins '
      'round on the spot like a top, with a hop at the top of it',
      (tester) async {
    await startWith(tester, 'DOOR');
    await waitFor(tester, find.byType(SealedDoor));
    await advance(tester, 300);
    final pet = PetProbe(tester);
    final ground = pet.feet;
    final before = door(tester).dial;

    await tester.tap(find.text(before));
    await tester.pump();
    final spin = await pet.track(45);
    expect(door(tester).dial, isNot(before));
    // Round in one whole turn: as drawn, edge on, turned right round, edge on,
    // as drawn again...
    expect(spin.map((s) => s.width).reduce(min), lessThan(-0.8));
    var edges = 0;
    for (var i = 1; i < spin.length; i++) {
      if (spin[i].width * spin[i - 1].width < 0) edges++;
    }
    expect(edges, 2);
    expect(spin.last.width, 1.0);
    // ...a hop at the top, and not going anywhere.
    expect(spin.highest, lessThan(ground - 8));
    expect(spin.xSpread, lessThan(3));
    expect(spin.last.feet, closeTo(ground, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('door: a wrong push throws the pet up at the door and it '
      'bounces off dizzy', (tester) async {
    await startWith(tester, 'DOOR');
    await waitFor(tester, find.byType(SealedDoor));
    await advance(tester, 300);
    final pet = PetProbe(tester);
    final ground = pet.feet;
    final rest = pet.head;
    final asked = content.doors.firstWhere((d) => d.base == door(tester).base);
    final box = tester.getRect(find.byType(SealedDoor));

    expect(door(tester).dial, isNot(asked.answer));
    await tester.tap(find.text('PUSH'));
    await tester.pump();
    final bounce = await pet.track(80);
    expect(bounce.highestHead, closeTo(headAt(pet, box, rest: rest), 14));
    expect(bounce.map((s) => s.tilt.abs()).reduce(max), greaterThan(0.2));
    expect(bounce.last.feet, closeTo(ground, 2));
    expect(bounce.last.tilt.abs(), lessThan(0.05));
    expect(tester.takeException(), isNull);
  });

  testWidgets('door: the right form — a full second crouched, shaking harder '
      'and harder, then a SHOULDER CHARGE that bursts the door',
      (tester) async {
    await startWith(tester, 'DOOR');
    await waitFor(tester, find.byType(SealedDoor));
    await advance(tester, 300);
    final pet = PetProbe(tester);
    final ground = pet.feet;
    final rest = pet.head;
    final asked = content.doors.firstWhere((d) => d.base == door(tester).base);
    final box = tester.getRect(find.byType(SealedDoor));
    for (var i = 0; i < 3 && door(tester).dial != asked.answer; i++) {
      await tester.tap(find.text(door(tester).dial));
      await tester.pump();
    }
    await advance(tester, 700);

    await tester.tap(find.text('PUSH'));
    await tester.pump();
    // Down on its haunches, leaning back, trembling — not leaving the ground.
    final crouch = await pet.track(54);
    expect(crouch.lowestSquash, lessThan(0.72));
    expect(crouch.every((s) => s.feet > ground - 3), isTrue);
    expect(crouch.xSpread, greaterThan(2));
    expect(crouch.map((s) => s.tilt.abs()).reduce(max), greaterThan(0.12));
    expect(damage, findsNothing);
    expect(find.byType(SealedDoor), findsOneWidget);
    // Then the charge: tipped right over on to its shoulder, up into the door.
    final charge = await pet.track(34);
    expect(charge.map((s) => s.tilt.abs()).reduce(max), greaterThan(0.55));
    expect(charge.highestHead, closeTo(headAt(pet, box, rest: rest), 14));
    expect(charge.map((s) => s.squash).reduce(max), greaterThan(1.12));
    // The door burst as the pet hit it.
    expect(find.byType(SealedDoor), findsNothing);
    await waitFor(tester, damage, frames: 90);
    final back = await pet.track(80);
    expect(back.last.feet, closeTo(ground, 1));
    expect(tester.takeException(), isNull);
  });

  // ---- Tablets --------------------------------------------------------------

  double scaleOf(WidgetTester tester, Finder plaque) {
    final m = tester
        .widget<Transform>(
            find.descendant(of: plaque, matching: find.byType(Transform)))
        .transform
        .storage;
    return m[5];
  }

  testWidgets('tablets: each tablet is CARRIED — the pet hops to catch it on '
      'its head, takes it overhead along the ground to its slot, squats and '
      'lets it fall in, and it lands with a squash', (tester) async {
    await startWith(tester, 'TABLETS');
    await waitFor(tester, find.byType(SkinTile));
    await advance(tester, 300);
    final pet = PetProbe(tester);
    final ground = pet.feet;
    final story = content.stories
        .firstWhere((s) => find.text(s.lines.first).evaluate().isNotEmpty);
    final n = story.lines.length;

    // The slots lie along the ground under its feet, the first at the left.
    expect(find.byType(PlaqueSlot), findsNWidgets(n));
    final slots = [
      for (var k = 0; k < n; k++) tester.getRect(find.byType(PlaqueSlot).at(k))
    ];
    expect(slots.every((r) => r.top > ground), isTrue);
    expect(slots.first.center.dx, lessThan(slots.last.center.dx));

    // A tablet out of order is just refused: nothing is carried.
    await tester.tap(tablet(story.lines[2]));
    await tester.pump();
    expect(find.byKey(const ValueKey('plaque-0')), findsNothing);
    await advance(tester, 400);

    // The first, in order, is taken off the stack and carried.
    final plaque = find.byKey(const ValueKey('plaque-0'));
    await tester.tap(tablet(story.lines.first));
    await tester.pump();
    expect(tester.widget<SkinTile>(tablet(story.lines.first)).state,
        TileState.spent);
    final run = <PetSample>[];
    final at = <Offset?>[];
    final scale = <double>[];
    for (var i = 0; i < 130; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      run.add(pet.sample);
      final here = plaque.evaluate().isNotEmpty;
      at.add(here ? tester.getCenter(plaque) : null);
      scale.add(here ? scaleOf(tester, plaque) : 1);
    }
    // It hops to catch it...
    expect(run.take(20).map((s) => s.squash).reduce(max), greaterThan(1.05));
    // ...and carries it on its head, the pet going to the slot...
    final overhead = [
      for (var i = 16; i < run.length; i++)
        if (at[i] != null && at[i]!.dy < run[i].head + 6) i
    ];
    expect(overhead.length, greaterThan(14), reason: 'riding on its head');
    for (final i in overhead.take(overhead.length - 6)) {
      expect((at[i]!.dx - run[i].x).abs(), lessThan(10), reason: 'frame $i');
    }
    final reached = run.indexWhere(
        (s) => (s.x - slots.first.center.dx).abs() < 8 && s.squash < 0.85);
    expect(reached, greaterThan(0), reason: 'it squats over the slot');
    // ...and squats there to let it go.
    expect(run.lowestSquash, lessThan(0.8));
    // The plaque drops into its slot, and is squashed flat as it lands.
    expect((at.last! - slots.first.center).distance, lessThan(4));
    expect(scale.reduce(min), lessThan(0.7));
    expect(scale.last, 1.0);

    // The rest in order, each to its own slot; and the last, carried, the pet
    // casts the whole story, which bursts as the spell leaves.
    for (var l = 1; l < n; l++) {
      await advance(tester, 700);
      await tester.tap(tablet(story.lines[l]));
      await tester.pump();
    }
    for (var l = 1; l < n; l++) {
      await waitFor(tester, find.byKey(ValueKey('plaque-$l')), frames: 20);
    }
    await waitFor(tester, damage, frames: 400);
    for (var l = 0; l < n; l++) {
      expect(find.byKey(ValueKey('plaque-$l')), findsNothing,
          reason: 'burst as the spell left');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablets: a tablet lifted on the heels of another does not wait '
      'for the pet: the first is let go where it has got to, and both end in '
      'their slots', (tester) async {
    await startWith(tester, 'TABLETS');
    await waitFor(tester, find.byType(SkinTile));
    await advance(tester, 300);
    final story = content.stories.firstWhere(
        (s) => s.lines.length > 2 && find.text(s.lines.first).evaluate().isNotEmpty,
        orElse: () => content.stories
            .firstWhere((s) => find.text(s.lines.first).evaluate().isNotEmpty));
    final n = story.lines.length;
    if (n < 3) return;
    final slots = [
      for (var k = 0; k < n; k++) tester.getRect(find.byType(PlaqueSlot).at(k))
    ];
    await tester.tap(tablet(story.lines[0]));
    await tester.pump();
    await advance(tester, 160);
    await tester.tap(tablet(story.lines[1]));
    await tester.pump();
    // Let go on the spot — not carried on to the slot with the pet a long way
    // off — the first has fallen into its slot well before the second is
    // anywhere near.
    await advance(tester, 560);
    expect(
        (tester.getCenter(find.byKey(const ValueKey('plaque-0'))) -
                slots[0].center)
            .distance,
        lessThan(4));
    await advance(tester, 1400);
    for (var k = 0; k < 2; k++) {
      final plaque = find.byKey(ValueKey('plaque-$k'));
      expect(plaque, findsOneWidget);
      expect((tester.getCenter(plaque) - slots[k].center).distance, lessThan(4),
          reason: 'plaque $k in its slot');
    }
    expect(tester.takeException(), isNull);
  });

  // ---- the sand --------------------------------------------------------------

  double sandOverPet(WidgetTester tester) {
    final paint = tester.widget<CustomPaint>(find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is SandPilePainter));
    return (paint.painter! as SandPilePainter).fill;
  }

  testWidgets('the sand: buried, the pet DIGS itself out — a stroke of one paw '
      'and then the other, sand flung off to either side, the heap going down '
      'and the pet coming up out of it — and is out with a hop',
      (tester) async {
    await startWith(tester, 'RIDDLE');
    await waitFor(tester, find.byType(SkinTile));
    await advance(tester, 300);
    final pet = PetProbe(tester);
    final ground = pet.feet;
    for (var i = 0; i < 3000 && find.text('buried').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text('buried'), findsOneWidget);

    final run = <PetSample>[];
    final sand = <double>[];
    for (var i = 0; i < 140; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      run.add(pet.sample);
      sand.add(sandOverPet(tester));
    }
    // Buried at first: heaped right over it, and sunk.
    expect(sand[28], greaterThan(0.95));
    expect(run[28].feet, greaterThan(ground + 4));
    // Then the digging, a stroke to each side...
    final strokes = run.sublist(46, 98).map((s) => s.tilt).toList();
    var sides = 0;
    var last = 0.0;
    for (final t in strokes) {
      if (t.abs() < 0.08) continue;
      if (last != 0 && t.sign != last) sides++;
      last = t.sign;
    }
    expect(sides, greaterThanOrEqualTo(3));
    expect(strokes.map((t) => t.abs()).reduce(max), greaterThan(0.15));
    // ...the heap going down a little with each, the pet rising out of it...
    expect(sand[50], greaterThan(sand[75]));
    expect(sand[75], greaterThan(sand[95]));
    expect(sand[95], lessThan(0.35));
    expect(run[96].feet, lessThan(run[28].feet - 3));
    // ...and out with a hop.
    expect(run.sublist(98).hops(ground, by: 10), 1);
    expect(run.last.feet, closeTo(ground, 1));
    expect(tester.takeException(), isNull);
  });

  // ---- Storm ----------------------------------------------------------------

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

  final windPaint = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is WindStreaksPainter);
  final howlPaint = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is HowlRingsPainter);

  testWidgets('storm: the pet leans ten degrees into the wind — which blows '
      'sand across the grid from the right — the whole time it hunts',
      (tester) async {
    await startWith(tester, 'STORM');
    await waitFor(tester, find.byType(TalkPanel));
    double wind() =>
        (tester.widget<CustomPaint>(windPaint).painter! as WindStreaksPainter)
            .strength;
    double clock() => tester.widget<TalkPanel>(find.byType(TalkPanel)).clock;
    final early = wind();
    await advance(tester, 300);
    final pet = PetProbe(tester);
    expect(windPaint, findsOneWidget);
    final run = await pet.track(60);
    for (final s in run) {
      expect(s.tilt, closeTo(pi / 18, 0.03));
    }
    // Facing the wind: as it is drawn, toward the right.
    expect(run.every((s) => !s.facesLeft), isTrue);
    // The wind picks up as the sand runs through (while there is sand left).
    for (var i = 0; i < 2000 && clock() < 0.6; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(wind(), greaterThan(early + 0.2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('storm: the word found, the pet HOWLS — crouching, then its head '
      'thrown back and held there, rings of sound going up — and the sand is '
      'blown off the word, which the spell leaves', (tester) async {
    await startWith(tester, 'STORM');
    await waitFor(tester, find.byType(TalkPanel));
    await tester.pump(const Duration(milliseconds: 16));
    final pet = PetProbe(tester);
    final ground = pet.feet;
    final word = words.firstWhere((w) => w.meaning == talk(tester));
    final (grid, rect) = readGrid(tester);
    final letters = BubbleWave.lettersOf(word.target)!;
    final (first, last) = locate(grid, letters);

    await tester.tapAt(cellCentre(rect, first));
    await tester.pump();
    await tester.tapAt(cellCentre(rect, last));
    await tester.pump();

    final run = <PetSample>[];
    var rings = false;
    var gone = 0;
    var struck = -1;
    for (var i = 0; i < 160; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      run.add(pet.sample);
      rings |= howlPaint.evaluate().isNotEmpty;
      if (gone == 0) {
        final now = readGrid(tester).$1.length;
        if (now < grid.length) gone = grid.length - now;
      }
      if (struck < 0 && damage.evaluate().isNotEmpty) struck = i;
    }
    // Down low to draw breath, then its head thrown right back, up on its
    // toes, and held there shaking...
    expect(run.lowestSquash, lessThan(0.86));
    final back = run.where((s) => s.tilt < -0.45).length;
    expect(back, greaterThan(30), reason: 'held with its head back');
    expect(run.map((s) => s.tilt).reduce(min), lessThan(-0.55));
    expect(run.highest, lessThan(ground - 6));
    // ...rings of sound spreading up from it...
    expect(rings, isTrue);
    // ...the word's letters blown off the sand...
    expect(gone, letters.length);
    // ...and the spell leaving from where the word was.
    expect(struck, greaterThan(40));
    expect(run.last.tilt.abs(), lessThan(0.2));
    expect(tester.takeException(), isNull);
  });
}
