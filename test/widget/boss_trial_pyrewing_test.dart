import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/boss_trial/dragon_pieces.dart';
import 'package:mojilearner_flutter/components/boss_trial/sphinx_pieces.dart';
import 'package:mojilearner_flutter/components/boss_trial/spell_pieces.dart';
import 'package:mojilearner_flutter/components/boss_trial/trial_boss.dart';
import 'package:mojilearner_flutter/components/boss_trial/trial_skin.dart';
import 'package:mojilearner_flutter/constants/boss_trial_en_tr.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/screens/boss_trial_screen.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pet_probe.dart';
import '../helpers/pump_app.dart';

/// What the pet does with its body in Pyrewing's four openers, each its own:
/// the Parley's steps, nods, bow and big spell; the Link's arched overhand lob
/// and the bridge of light; the Embers' catch and fling, and the singed
/// whiskers; the Hoard's tiptoe, the carried coin and the dragon's eye.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCharacterProvider mockCharacter;
  late MockLanguageProvider mockLanguage;
  final content = EnTrContent.of('tr', 'en')!;

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
      BossTrialScreen(key: UniqueKey(), boss: TrialBosses.dragon),
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

  double screenWidth(WidgetTester tester) =>
      tester.getSize(find.byType(BossTrialScreen)).width;

  /// Where the pet's head reaches under [thing]: into its lower edge, as far
  /// as a leap goes.
  double headAt(PetProbe pet, Rect thing, {required double rest}) =>
      min(rest, max(thing.bottom - 10, rest - pet.size.height * 2.6));

  /// How much of the ash there is over the pet, 0 to 1 (of the grey it is
  /// scorched to).
  double ashOnPet(WidgetTester tester) {
    final filtered = tester.widget<ColorFiltered>(find
        .ancestor(
            of: find.byKey(const ValueKey('pet-flip')),
            matching: find.byType(ColorFiltered))
        .first);
    final text = '${filtered.colorFilter}';
    final alpha = RegExp(r'alpha: ([0-9.]+)').firstMatch(text)?.group(1);
    if (alpha != null) return double.parse(alpha) / 0.75;
    final hex = RegExp(r'Color\(0x([0-9a-fA-F]{8})\)').firstMatch(text)!;
    return int.parse(hex.group(1)!.substring(0, 2), radix: 16) / 255 / 0.75;
  }

  testWidgets('the ash: scorched, the pet SHAKES it off — its whole body going, '
      'head and all, ash flying off it, the grey fading as it does — and is '
      'clean with a hop', (tester) async {
    await startWith(tester, 'PARLEY');
    await waitFor(tester, find.byType(SkinTile));
    await advance(tester, 300);
    final pet = PetProbe(tester);
    final ground = pet.feet;
    for (var i = 0; i < 3000 && find.text('scorched').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text('scorched'), findsOneWidget);

    final run = <PetSample>[];
    final ash = <double>[];
    for (var i = 0; i < 140; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      run.add(pet.sample);
      ash.add(ashOnPet(tester));
    }
    // Grey right through at first, and still...
    expect(ash[28], greaterThan(0.95));
    expect(run.sublist(30, 60).xSpread, lessThan(2));
    // ...then the shake, shoulders and head going back and forth...
    final shaking = run.sublist(64, 98);
    expect(shaking.xSpread, greaterThan(5));
    var swings = 0;
    for (var i = 1; i < shaking.length; i++) {
      if (shaking[i].tilt * shaking[i - 1].tilt < 0) swings++;
    }
    expect(swings, greaterThanOrEqualTo(2));
    // ...the ash fading as it comes off, till there is hardly any...
    expect(ash[50], greaterThan(ash[75]));
    expect(ash[75], greaterThan(ash[95]));
    expect(ash[95], lessThan(0.3));
    // ...and a hop when it is clean.
    expect(run.sublist(98).hops(ground, by: 10), 1);
    expect(tester.takeException(), isNull);
  });

  // ---- Parley ---------------------------------------------------------------

  testWidgets('parley: the pet keeps well back from the dragon, steps a step '
      'closer with every reply and nods on it; a wrong reply is a shake of the '
      'head', (tester) async {
    await startWith(tester, 'PARLEY');
    await waitFor(tester, find.byType(SkinTile));
    await advance(tester, 900);
    final pet = PetProbe(tester);
    final w = screenWidth(tester);
    final script =
        content.parleys.firstWhere((p) => talk(tester) == p.turns.first.line);

    // It has gone back, well to one side, to start with.
    final start = pet.x;
    expect(start, closeTo(w * 0.2, 10));

    // A wrong reply: it shakes its head, and stays where it is.
    await tester.tap(tablet(script.turns.first.replies[1]));
    await tester.pump();
    final no = await pet.track(50);
    var shakes = 0;
    for (var i = 1; i < no.length; i++) {
      if (no[i].tilt * no[i - 1].tilt < 0 && no[i].tilt.abs() > 0.05) shakes++;
    }
    expect(shakes, greaterThanOrEqualTo(4));
    expect(no.map((s) => s.tilt.abs()).reduce(max), greaterThan(0.25));
    expect(no.xSpread, lessThan(3));
    await advance(tester, 300);

    // The right one: it nods twice, taking a step closer.
    await tester.tap(tablet(script.turns.first.replies.first));
    await tester.pump();
    final nod = await pet.track(70);
    var nods = 0;
    for (var i = 1; i < nod.length - 1; i++) {
      if (nod[i].tilt > 0.25 &&
          nod[i].tilt >= nod[i - 1].tilt &&
          nod[i].tilt > nod[i + 1].tilt) {
        nods++;
      }
    }
    expect(nods, 2);
    // A step of it: closer to the middle, where the dragon is, and facing it.
    expect(nod.last.x - start, closeTo(w * 0.15, 10));
    expect(nod.every((s) => !s.facesLeft), isTrue);
    await waitFor(tester, damage, frames: 90);
    expect(tester.takeException(), isNull);
  });

  testWidgets('parley: the last reply, a BOW — right down, held — and then a '
      'big spell', (tester) async {
    await startWith(tester, 'PARLEY');
    await waitFor(tester, find.byType(SkinTile));
    await advance(tester, 900);
    final pet = PetProbe(tester);
    final w = screenWidth(tester);
    final script =
        content.parleys.firstWhere((p) => talk(tester) == p.turns.first.line);
    for (final turn in script.turns.take(script.turns.length - 1)) {
      expect(talk(tester), turn.line);
      await tester.tap(tablet(turn.replies.first));
      await tester.pump();
      await advance(tester, 2000);
    }
    // Each reply a step closer: right under the dragon for the last.
    expect(pet.x, closeTo(w * 0.5, 10));
    expect(talk(tester), script.turns.last.line);

    await tester.tap(tablet(script.turns.last.replies.first));
    await tester.pump();
    final run = <PetSample>[];
    var big = false;
    var struck = -1;
    for (var i = 0; i < 160; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      run.add(pet.sample);
      big |= find
          .byType(SpellBolt)
          .evaluate()
          .any((e) => tester.getSize(find.byWidget(e.widget)).width == 40);
      if (struck < 0 && damage.evaluate().isNotEmpty) struck = i;
    }
    // Down in a bow, held...
    final lean = run.map((s) => s.tilt).reduce((a, b) => a.abs() > b.abs() ? a : b);
    final side = lean < 0 ? -1.0 : 1.0;
    final bowed = run.where((s) => s.tilt * side > 0.7).length;
    expect(bowed, greaterThan(25), reason: 'held low');
    expect(run.lowestSquash, lessThan(0.85));
    // ...up, and a big spell, bigger than the stings.
    expect(big, isTrue);
    expect(struck, greaterThan(70));
    expect(tester.takeException(), isNull);
  });

  // ---- Link -----------------------------------------------------------------

  final bridgePaint = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is BridgePainter);

  testWidgets('link: the right rune, the pet rears right back arched on its '
      'toes, snaps forward off the ground and lobs the bolt overhand, and where '
      'it lands a BRIDGE of light forms between the flames', (tester) async {
    await startWith(tester, 'LINK');
    await waitFor(tester, find.byType(SkinTile));
    await advance(tester, 300);
    final pet = PetProbe(tester);
    final ground = pet.feet;
    final item = content.links
        .firstWhere((l) => find.text(l.left).evaluate().isNotEmpty);

    // A wrong rune: a cringe, and nothing joined.
    await tester.tap(tablet(item.links[1]), warnIfMissed: false);
    await tester.pump();
    final cringe = await pet.track(20);
    expect(cringe.lowestSquash, lessThan(0.9));
    expect(bridgePaint, findsNothing);
    await advance(tester, 400);

    await tester.tap(tablet(item.links.first), warnIfMissed: false);
    await tester.pump();
    final run = <PetSample>[];
    final bridge = <double?>[];
    var bolt = false;
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      run.add(pet.sample);
      bolt |= find.byType(SpellBolt).evaluate().isNotEmpty;
      final p = bridgePaint.evaluate().isEmpty
          ? null
          : (tester.widget<CustomPaint>(bridgePaint).painter! as BridgePainter)
              .progress;
      bridge.add(p);
    }
    final thrust = run.map((s) => s.tilt).reduce((a, b) => a.abs() > b.abs() ? a : b);
    final lean = thrust < 0 ? -1.0 : 1.0;
    // Right back, and held there a while, arched...
    expect(run.where((s) => s.tilt * lean < -0.4).length, greaterThan(20));
    expect(run.map((s) => s.tilt * lean).reduce(min), lessThan(-0.5));
    // ...then over the top, off the ground, and follows through.
    expect(run.map((s) => s.tilt * lean).reduce(max), greaterThan(0.5));
    expect(run.highest, lessThan(ground - 14));
    // The bolt flies at the rune, and the bridge forms only when it lands.
    expect(bolt, isTrue);
    final first = bridge.indexWhere((p) => p != null);
    expect(first, greaterThan(50), reason: 'not until the bolt lands');
    expect(bridge.whereType<double>().reduce(max), greaterThanOrEqualTo(1.0));
    expect(damage, findsNothing);
    await waitFor(tester, damage, frames: 100);
    expect(tester.takeException(), isNull);
  });

  // ---- Embers ---------------------------------------------------------------

  final heldEmber = find.byKey(const ValueKey('held-ember'));
  final soot = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is WhiskerSootPainter);

  testWidgets('embers: a wrong ember FLARES in the pet\'s face — whiskers '
      'singed, smoking — and throws it off, tipped away', (tester) async {
    await startWith(tester, 'EMBERS');
    await waitFor(tester, find.byType(SkinTile));
    await advance(tester, 300);
    final pet = PetProbe(tester);
    final rest = pet.head;
    final item = content.paraphrases.firstWhere((p) => talk(tester) == p.line);
    final wrong = tablet(item.options[1]);
    final box = tester.getRect(wrong);

    expect(soot, findsNothing);
    await tester.tap(wrong, warnIfMissed: false);
    await tester.pump();
    final run = <PetSample>[];
    var singed = false;
    for (var i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      run.add(pet.sample);
      singed |= soot.evaluate().isNotEmpty;
    }
    expect(run.highestHead, closeTo(headAt(pet, box, rest: rest), 16));
    expect(singed, isTrue);
    // Thrown back off it at once, tipped away.
    final top = run.highestHead;
    expect(run.where((s) => s.head < top + 6).length, lessThan(8));
    expect(run.map((s) => s.tilt.abs()).reduce(max), greaterThan(0.4));
    // The soot fades in a couple of seconds.
    await advance(tester, 1700);
    expect(soot, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('embers: the right ember is CAUGHT — the pet leaps and snatches '
      'it, comes down hugging it, rears back and flings it as a fireball',
      (tester) async {
    await startWith(tester, 'EMBERS');
    await waitFor(tester, find.byType(SkinTile));
    await advance(tester, 300);
    final pet = PetProbe(tester);
    final ground = pet.feet;
    final rest = pet.head;
    final item = content.paraphrases.firstWhere((p) => talk(tester) == p.line);
    final right = tablet(item.options.first);
    final box = tester.getRect(right);

    expect(heldEmber, findsNothing);
    await tester.tap(right, warnIfMissed: false);
    await tester.pump();
    final run = <PetSample>[];
    final held = <Offset?>[];
    var thrown = false;
    var taken = false;
    var struck = -1;
    for (var i = 0; i < 130; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      run.add(pet.sample);
      held.add(heldEmber.evaluate().isEmpty ? null : tester.getCenter(heldEmber));
      taken |= right.evaluate().isNotEmpty &&
          tester.widget<SkinTile>(right).state == TileState.spent;
      // Once the pet has let go of it, a fireball is in the air.
      if (i > 20 && heldEmber.evaluate().isEmpty) {
        thrown |= find.byType(FireballSprite).evaluate().isNotEmpty;
      }
      if (struck < 0 && damage.evaluate().isNotEmpty) struck = i;
    }
    // Up at it, head into it...
    expect(run.highestHead, closeTo(headAt(pet, box, rest: rest), 16));
    // ...the ember taken off its place and held over the pet's head, riding it
    // down...
    expect(taken, isTrue);
    final carried = [
      for (var i = 0; i < run.length; i++)
        if (held[i] != null) i,
    ];
    expect(carried.length, greaterThan(15), reason: 'hugged on the way down');
    for (final i in carried) {
      expect((held[i]!.dx - run[i].x).abs(), lessThan(16), reason: 'frame $i');
    }
    // ...then a rear back, and the fling.
    final thrust = run.map((s) => s.tilt).reduce((a, b) => a.abs() > b.abs() ? a : b);
    final lean = thrust < 0 ? -1.0 : 1.0;
    expect(run.map((s) => s.tilt * lean).reduce(min), lessThan(-0.3));
    expect(run.map((s) => s.tilt * lean).reduce(max), greaterThan(0.4));
    expect(thrown, isTrue);
    expect(struck, greaterThan(carried.last));
    final back = await pet.track(60);
    expect(back.last.feet, closeTo(ground, 1));
    expect(tester.takeException(), isNull);
  });

  // ---- Hoard ----------------------------------------------------------------

  testWidgets('hoard: a coin is lifted onto the pet\'s head to be carried — '
      'it hops, quietly, to catch it — and the dragon\'s eye opens a little '
      'with each pair got wrong', (tester) async {
    await startWith(tester, 'HOARD');
    final coinTiles = find
        .byWidgetPredicate((w) => w is SkinTile && w.shape == TileShape.coin);
    await waitFor(tester, coinTiles);
    await advance(tester, 300);
    final pet = PetProbe(tester);
    final ground = pet.feet;
    final coins =
        tester.widgetList<SkinTile>(coinTiles).map((c) => c.label).toList();
    final phrases = content.phrases
        .where((p) => coins.contains(p.first) && coins.contains(p.second))
        .toList();
    final firsts = [
      for (var i = 0; i < coins.length; i++)
        if (phrases.any((p) => p.first == coins[i])) i,
    ];
    double eye() => tester.widget<DragonEyelids>(find.byType(DragonEyelids)).open;

    // The dragon is asleep: its eyes shut, opening a little as the sand runs.
    expect(eye(), lessThan(0.15));

    // The first coin lifts off the hoard to the pet's head.
    final taken = firsts[0];
    final trip = find.byKey(ValueKey('trip-$taken'));
    await tester.tap(coinTiles.at(taken));
    await tester.pump();
    // A ghost of it is left where it was, to tap to put it back.
    expect(tester.widget<SkinTile>(coinTiles.at(taken)).state, TileState.held);
    final hop = <PetSample>[];
    final coinAt = <Offset?>[];
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      hop.add(pet.sample);
      coinAt.add(trip.evaluate().isEmpty ? null : tester.getCenter(trip));
    }
    // A small quiet hop, up on its toes...
    expect(hop.highest, lessThan(ground - 5));
    expect(hop.highest, greaterThan(ground - 16));
    expect(hop.map((s) => s.squash).reduce(max), greaterThan(1.04));
    // ...and the coin is over its head, riding it.
    expect(coinAt.last, isNotNull);
    expect((coinAt.last!.dx - hop.last.x).abs(), lessThan(8));
    expect(coinAt.last!.dy, lessThan(hop.last.head + 6));

    // Tap the ghost, and the coin goes back to where it was.
    await advance(tester, 400);
    await tester.tap(coinTiles.at(taken));
    await tester.pump();
    await advance(tester, 600);
    expect(trip, findsNothing);
    expect(tester.widget<SkinTile>(coinTiles.at(taken)).state, TileState.plain);

    // A wrong pair: the coin goes back, and the dragon's eye opens a little.
    await tester.tap(coinTiles.at(taken));
    await tester.pump();
    await advance(tester, 400);
    final before = eye();
    await tester.tap(coinTiles.at(firsts[1]));
    await tester.pump();
    expect(find.text('no'), findsOneWidget);
    await advance(tester, 700);
    expect(eye() - before, greaterThan(0.14));
    expect(tester.widget<SkinTile>(coinTiles.at(taken)).state,
        isNot(TileState.spent));
    expect(trip, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hoard: a pair found — the pet TIPTOES under the second coin '
      'with the first on its head, in small quiet hops, and lifts it up to its '
      'match', (tester) async {
    await startWith(tester, 'HOARD');
    final coinTiles = find
        .byWidgetPredicate((w) => w is SkinTile && w.shape == TileShape.coin);
    await waitFor(tester, coinTiles);
    await advance(tester, 300);
    final pet = PetProbe(tester);
    final ground = pet.feet;
    final home = pet.x;
    final coins =
        tester.widgetList<SkinTile>(coinTiles).map((c) => c.label).toList();
    final p = content.phrases
        .where((p) => coins.contains(p.first) && coins.contains(p.second))
        .first;
    final a = coins.indexOf(p.first), b = coins.indexOf(p.second);
    final target = tester.getRect(coinTiles.at(b));

    await tester.tap(coinTiles.at(a));
    await tester.pump();
    await advance(tester, 500);
    await tester.tap(coinTiles.at(b));
    await tester.pump();
    final run = <PetSample>[];
    final coinAt = <Offset?>[];
    var sawB = true;
    var struck = -1;
    for (var i = 0; i < 160; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      run.add(pet.sample);
      final trip = find.byKey(ValueKey('trip-$a'));
      coinAt.add(trip.evaluate().isEmpty ? null : tester.getCenter(trip));
      if (struck < 0 && damage.evaluate().isNotEmpty) struck = i;
    }
    // It goes to under the second coin, across, in small quiet hops: none
    // anywhere near the height of a run, and always up on its toes.
    final half = pet.size.width / 2;
    final toX = target.center.dx.clamp(half - 6, screenWidth(tester) - half + 6);
    if ((toX - home).abs() > 40) {
      expect(run.map((s) => (s.x - home) * (toX - home).sign).reduce(max),
          greaterThan((toX - home).abs() * 0.8));
      final arrived = run.indexWhere((s) => (s.x - toX).abs() <= 12);
      expect(arrived, greaterThan(10));
      final travelling = run.sublist(0, arrived);
      expect(travelling.map((s) => ground - s.feet).reduce(max), lessThan(8));
      expect(travelling.map((s) => s.squash).reduce(min), greaterThanOrEqualTo(1.0));
      expect(travelling.map((s) => s.squash).reduce(max), greaterThan(1.04));
    }
    // The coin rides over its head the while.
    final riding = [
      for (var i = 0; i < run.length; i++)
        if (coinAt[i] != null && (coinAt[i]!.dx - run[i].x).abs() < 10) i,
    ];
    expect(riding.length, greaterThan(15));
    // At the end it rises on its toes and lifts it to its match.
    expect(run.map((s) => s.squash).reduce(max), greaterThan(1.1));
    expect(sawB, isTrue);
    // The pair goes at the boss after, when they have come together.
    expect(struck, greaterThan(riding.last));
    expect(tester.takeException(), isNull);
  });
}
