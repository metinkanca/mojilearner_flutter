import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/boss_trial/angler_pieces.dart';
import 'package:mojilearner_flutter/components/boss_trial/trial_skin.dart';
import 'package:mojilearner_flutter/components/boss_trial/sphinx_pieces.dart';
import 'package:mojilearner_flutter/components/boss_trial/trial_boss.dart';
import 'package:mojilearner_flutter/constants/boss_trial_en_tr.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/screens/boss_trial_screen.dart';
import 'package:mojilearner_flutter/utils/boss_trial_dragon.dart';
import 'package:mojilearner_flutter/utils/boss_trial_sphinx.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pet_probe.dart';
import '../helpers/pump_app.dart';

/// The openers with English and Turkish content only — Lanternmaw's Shoal,
/// Sableth's Riddle, Door and Tablets, Pyrewing's Parley, Gaze and Hoard —
/// played through the screen, learning Turkish with English meanings.
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

  Future<void> pumpTrial(WidgetTester tester, TrialBoss boss) async {
    await pumpApp(
      tester,
      BossTrialScreen(key: UniqueKey(), boss: boss),
      characterProvider: mockCharacter,
      languageProvider: mockLanguage,
      vocabProvider: VocabProvider(),
    );
    await tester.pump();
  }

  Future<void> startWith(
      WidgetTester tester, TrialBoss boss, String opening) async {
    await pumpTrial(tester, boss);
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

  testWidgets('the intros: six bosses, and the new trials\' openers',
      (tester) async {
    await pumpTrial(tester, TrialBosses.sphinx);
    expect(find.text('LEVEL 21 · RIDDLE'), findsOneWidget);
    for (final name in ['RIDDLE', 'DOOR', 'TABLETS']) {
      expect(find.text(name), findsOneWidget);
    }
    await pumpTrial(tester, TrialBosses.dragon);
    expect(find.text('LEVEL 26 · PARLEY'), findsOneWidget);
    for (final name in ['PARLEY', 'LINK', 'EMBERS', 'HOARD']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('LV 30\nPYREWING'), findsOneWidget);
    expect(find.text('ENGLISH + TURKISH TEST CONTENT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('another pair fights them in English and Turkish, and is told',
      (tester) async {
    when(() => mockLanguage.targetLanguage)
        .thenReturn(const Language(code: 'es', name: 'es'));
    await pumpTrial(tester, TrialBosses.dragon);
    expect(find.textContaining('only has English and Turkish'), findsOneWidget);
    expect(find.textContaining('(ES → EN)'), findsOneWidget);
    expect(find.textContaining('this run is in TR with EN'), findsOneWidget);

    // Lanternmaw opens with the Lure, which works in any pair: no note until
    // the Shoal is picked.
    await pumpTrial(tester, TrialBosses.angler);
    expect(find.textContaining('only has English and Turkish'), findsNothing);
    await tester.tap(find.text('SHOAL'));
    await tester.pump();
    expect(find.textContaining('only has English and Turkish'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shoal: the stray is the one not of the group', (tester) async {
    await startWith(tester, TrialBosses.angler, 'SHOAL');
    await waitFor(tester, find.byType(WordFish));
    final labels = tester
        .widgetList<WordFish>(find.byType(WordFish))
        .map((f) => f.label)
        .toList();
    String groupOf(String word) => content.categories.entries
        .firstWhere((e) => e.value.any((w) => w.target == word))
        .key;
    final groups = labels.map(groupOf).toList();
    final stray = labels
        .firstWhere((l) => groups.where((g) => g == groupOf(l)).length == 1);
    await tester.tap(
        find.byWidgetPredicate((w) => w is WordFish && w.label == stray),
        warnIfMissed: false);
    await tester.pump();
    // The pet hits it, and it swims at the boss: the damage lands on arrival.
    await waitFor(tester, damage, frames: 150);
    expect(tester.takeException(), isNull);
  });

  String groupOf(String word) => content.categories.entries
      .firstWhere((e) => e.value.any((w) => w.target == word))
      .key;
  List<String> shoalLabels(WidgetTester tester) => tester
      .widgetList<WordFish>(find.byType(WordFish))
      .map((f) => f.label)
      .toList();
  Finder fishLabelled(String label) =>
      find.byWidgetPredicate((w) => w is WordFish && w.label == label);

  testWidgets('shoal: a fish that belonged makes the pet cringe',
      (tester) async {
    await startWith(tester, TrialBosses.angler, 'SHOAL');
    await waitFor(tester, find.byType(WordFish));
    await advance(tester, 300);
    final pet = PetProbe(tester);

    final labels = shoalLabels(tester);
    final groups = labels.map(groupOf).toList();
    final belonging = labels
        .firstWhere((l) => groups.where((g) => g == groupOf(l)).length > 1);

    await tester.tap(fishLabelled(belonging), warnIfMissed: false);
    await tester.pump();
    final cringe = await pet.track(20);
    expect(cringe.lowestSquash, lessThan(0.9));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shoal: the stray — the pet DARTS at it in a straight line, '
      'stretched and tipped along it, and hits it; the fish swims at the boss '
      'and rams it as the damage lands, then rebounds spinning till it is '
      'gone, while the pet is knocked back and drifts home', (tester) async {
    await startWith(tester, TrialBosses.angler, 'SHOAL');
    await waitFor(tester, find.byType(WordFish));
    await advance(tester, 300);
    final pet = PetProbe(tester);
    final ground = pet.feet;
    final home = pet.x;

    final labels = shoalLabels(tester);
    final groups = labels.map(groupOf).toList();
    final stray = labels
        .firstWhere((l) => groups.where((g) => g == groupOf(l)).length == 1);
    final fish = fishLabelled(stray);
    // The fish, once it is tipped along its swim or spinning off.
    final turning = find.byWidgetPredicate((w) =>
        w is Transform &&
        w.child is WordFish &&
        (w.child as WordFish).label == stray);
    // The boss's belly, where blows land, as drawn this frame.
    final bossArt = find.byWidgetPredicate((w) =>
        w is SvgPicture &&
        w.bytesLoader is SvgAssetLoader &&
        [TrialBosses.angler.asset, TrialBosses.angler.openAsset]
            .contains((w.bytesLoader as SvgAssetLoader).assetName));
    Offset belly() {
      final r = tester.getRect(bossArt.first);
      return r.topLeft +
          Offset(r.width * TrialBosses.angler.hitX,
              r.height * TrialBosses.angler.hitY);
    }

    // Wait for it to swim well off to one side.
    for (var i = 0;
        i < 600 && (tester.getCenter(fish).dx - home).abs() < 90;
        i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final at = tester.getCenter(fish);
    final side = at.dx < home ? -1.0 : 1.0;
    await tester.tap(fish, warnIfMissed: false);
    await tester.pump();

    final run = <PetSample>[];
    final fishAt = <Offset?>[];
    final bellyAt = <Offset>[];
    final angle = <double?>[];
    var struck = -1;
    for (var i = 0; i < 180; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      run.add(pet.sample);
      fishAt.add(fish.evaluate().isEmpty ? null : tester.getCenter(fish));
      bellyAt.add(belly());
      final m = turning.evaluate().isEmpty
          ? null
          : tester.widget<Transform>(turning).transform.storage;
      angle.add(m == null ? null : atan2(m[1], m[0]));
      if (struck < 0 && damage.evaluate().isNotEmpty) struck = i;
    }
    // Wound up low, then stretched out along its line like an arrow...
    expect(run.lowestSquash, lessThan(0.85));
    expect(run.map((s) => s.squash).reduce(max), greaterThan(1.08));
    // ...tipped into it, the whole way there, at once...
    expect(run.first.facesLeft, side < 0);
    expect(run.map((s) => s.tilt * side).reduce(max), greaterThan(0.25));
    final reached = run.map((s) => (s.x - home) * side).reduce(max);
    expect(reached, greaterThan((at.dx - home).abs() * 0.8));
    final hit = run.indexWhere((s) => (s.x - home) * side > reached - 4);
    expect(run.sublist(0, hit).msUntil((s) => (s.x - home) * side > 20),
        lessThan(260),
        reason: 'a dart, not a run');
    // ...and the fish was held still till it hit...
    expect((fishAt.first! - at).distance, lessThan(8));
    final launched =
        fishAt.indexWhere((p) => p == null || (p - at).distance > 24);
    expect(launched, greaterThanOrEqualTo(hit - 4));
    // ...then swims at the boss, a swim you can watch, and RAMS it: the damage
    // lands as its nose gets there, not before.
    expect(struck, greaterThan(hit + 18), reason: 'a swim, not a pop');
    final rammed = fishAt[struck]!;
    expect((rammed - bellyAt[struck]).distance, lessThan(140),
        reason: 'it is on the boss when it lands');
    expect(
        (fishAt[struck - 1]! - bellyAt[struck - 1]).distance,
        lessThan((fishAt[hit + 10]! - bellyAt[hit + 10]).distance),
        reason: 'it swam towards the boss, not away');
    final swimming = angle.sublist(hit, struck).whereType<double>();
    expect(swimming, isNotEmpty, reason: 'tipped along its line as it swims');
    // Then it REBOUNDS off the belly: away from it, spinning round and round,
    // until it is gone.
    final off12 = (fishAt[struck + 12]! - bellyAt[struck]).distance;
    final off36 = (fishAt[struck + 36]! - bellyAt[struck]).distance;
    expect(off12, greaterThan((rammed - bellyAt[struck]).distance + 20));
    expect(off36, greaterThan(off12 + 20), reason: 'it keeps going');
    // (Later frames may hold the next school, with the same word on a fish.)
    final gone = fishAt.indexWhere((p) => p == null, struck);
    expect(gone, inInclusiveRange(struck + 40, struck + 70),
        reason: 'it falls out of sight, not at once and not never');
    var spun = 0.0;
    for (var i = struck + 1; i < gone; i++) {
      final a = angle[i], b = angle[i - 1];
      if (a == null || b == null) continue;
      var step = a - b;
      if (step > pi) step -= 2 * pi;
      if (step < -pi) step += 2 * pi;
      spun += step;
    }
    expect(spun.abs(), greaterThan(3 * pi), reason: 'spinning off');
    // The pet is knocked back by its blow, and then drifts home.
    final after = run.sublist(hit);
    expect(reached - after.map((s) => (s.x - home) * side).reduce(min),
        greaterThan(12));
    expect(run.last.x, closeTo(home, 2));
    expect(run.last.feet, closeTo(ground, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('riddle: a wrong answer is struck out, the right one hits',
      (tester) async {
    await startWith(tester, TrialBosses.sphinx, 'RIDDLE');
    await waitFor(tester, find.byType(SkinTile));
    final riddle =
        content.riddles.firstWhere((r) => talk(tester).contains(r.question));
    await tester.tap(tablet(riddle.answers[1]));
    await tester.pump();
    expect(find.text('wrong'), findsOneWidget);
    expect(tester.widget<SkinTile>(tablet(riddle.answers[1])).state,
        TileState.flashing);
    await tester.tap(tablet(riddle.answers.first));
    await tester.pump();
    // The pet stamps it first.
    await waitFor(tester, damage, frames: 150);
    expect(tester.takeException(), isNull);
  });

  testWidgets('door: a wrong push stays sealed; the right form opens it',
      (tester) async {
    await startWith(tester, TrialBosses.sphinx, 'DOOR');
    await waitFor(tester, find.byType(SealedDoor));
    SealedDoor door() => tester.widget<SealedDoor>(find.byType(SealedDoor));
    final asked = content.doors.firstWhere((d) => d.base == door().base);
    expect(door().dial, isNot(asked.answer));

    await tester.tap(find.text('PUSH'));
    await tester.pump();
    expect(find.text('sealed'), findsOneWidget);

    for (var i = 0; i < 3 && door().dial != asked.answer; i++) {
      await tester.tap(find.text(door().dial));
      await tester.pump();
    }
    expect(door().dial, asked.answer);
    await tester.tap(find.text('PUSH'));
    await tester.pump();
    // The pet gathers itself before it throws itself at the door.
    await waitFor(tester, damage, frames: 150);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablets: lifted in the order the story happens', (tester) async {
    await startWith(tester, TrialBosses.sphinx, 'TABLETS');
    await waitFor(tester, find.byType(SkinTile));
    final story = content.stories
        .firstWhere((s) => find.text(s.lines.first).evaluate().isNotEmpty);
    await tester.tap(tablet(story.lines[2]));
    await tester.pump();
    expect(find.text('not yet'), findsOneWidget);
    for (final line in story.lines) {
      await tester.tap(tablet(line));
      await tester.pump();
    }
    // Every tablet taken off the stack, to be carried to its slot.
    for (final line in story.lines) {
      expect(tester.widget<SkinTile>(tablet(line)).state, TileState.spent);
    }
    // The pet carries them, then rears back to cast the whole story.
    await waitFor(tester, damage, frames: 400);
    expect(tester.takeException(), isNull);
  });

  // ---- Sableth's pet ---------------------------------------------------------

  /// How much sand there is heaped over the pet.
  double sandOverPet(WidgetTester tester) {
    final paint = tester.widget<CustomPaint>(find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is SandPilePainter));
    return (paint.painter! as SandPilePainter).fill;
  }

  testWidgets('the sand: it heaps over the pet as the clock runs down, buries '
      'it when the clock is out, and the pet bursts out with a hop',
      (tester) async {
    await startWith(tester, TrialBosses.sphinx, 'RIDDLE');
    await waitFor(tester, find.byType(SkinTile));
    await advance(tester, 300);
    final pet = PetProbe(tester);
    final ground = pet.feet;

    final run = <PetSample>[];
    final sand = <double>[];
    var buried = -1;
    for (var i = 0; i < 3000 && buried < 0; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      run.add(pet.sample);
      sand.add(sandOverPet(tester));
      if (find.text('buried').evaluate().isNotEmpty) buried = run.length - 1;
    }
    expect(buried, greaterThan(0), reason: 'the clock ran out');
    // Nothing early on; a low mound by the time it runs out.
    expect(sand.take(30).every((f) => f == 0), isTrue);
    expect(sand[buried - 1], inInclusiveRange(0.2, 0.35));

    // Buried: the sand swells over it and sinks it a little.
    for (var i = 0; i < 140; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      run.add(pet.sample);
      sand.add(sandOverPet(tester));
    }
    expect(sand[buried + 30], greaterThan(0.95));
    expect(run[buried + 30].feet, greaterThan(ground + 4));
    // It struggles in the last stretch, then bursts out of it with a hop.
    expect(run.sublist(buried + 75, buried + 95).xSpread, greaterThan(2));
    expect(sand.last, 0);
    expect(run.sublist(buried + 95).hops(ground, by: 10), 1);
    expect(run.last.feet, closeTo(ground, 1));
    expect(tester.takeException(), isNull);
  });

  // ---- Pyrewing's pet --------------------------------------------------------

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

  testWidgets('the ash: it creeps over the pet as the clock runs down, takes '
      'hold when the fire gets loose, and the pet shakes it off with a hop',
      (tester) async {
    await startWith(tester, TrialBosses.dragon, 'PARLEY');
    await waitFor(tester, find.byType(SkinTile));
    await advance(tester, 300);
    final pet = PetProbe(tester);
    final ground = pet.feet;

    final run = <PetSample>[];
    final ash = <double>[];
    var scorched = -1;
    for (var i = 0; i < 3000 && scorched < 0; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      run.add(pet.sample);
      ash.add(ashOnPet(tester));
      if (find.text('scorched').evaluate().isNotEmpty) scorched = run.length - 1;
    }
    expect(scorched, greaterThan(0), reason: 'the clock ran out');
    expect(ash.take(30).every((a) => a == 0), isTrue);
    expect(ash[scorched - 1], inInclusiveRange(0.2, 0.35));

    for (var i = 0; i < 140; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      run.add(pet.sample);
      ash.add(ashOnPet(tester));
    }
    expect(ash[scorched + 30], greaterThan(0.95));
    // It shakes in the last stretch, then is clean again, with a hop.
    expect(run.sublist(scorched + 75, scorched + 95).xSpread, greaterThan(2));
    expect(ash.last, 0);
    expect(run.sublist(scorched + 95).hops(ground, by: 10), 1);
    expect(run.last.feet, closeTo(ground, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('parley: every turn answered, and it lands a blow at the end',
      (tester) async {
    await startWith(tester, TrialBosses.dragon, 'PARLEY');
    await waitFor(tester, find.byType(SkinTile));
    final script =
        content.parleys.firstWhere((p) => talk(tester) == p.turns.first.line);
    for (final turn in script.turns) {
      expect(talk(tester), turn.line);
      await tester.tap(tablet(turn.replies.first));
      await tester.pump();
    }
    // The pet bows first, then casts a big spell.
    await waitFor(tester, damage, frames: 250);
    expect(tester.takeException(), isNull);
  });

  testWidgets('parley: the fire getting loose scorches the pet',
      (tester) async {
    await startWith(tester, TrialBosses.dragon, 'PARLEY');
    await waitFor(tester, find.byType(SkinTile));
    await waitFor(tester, find.text('scorched'));
    expect(damage, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('flame link: a wrong rune stokes it; the right one joins them',
      (tester) async {
    await startWith(tester, TrialBosses.dragon, 'LINK');
    await waitFor(tester, find.byType(SkinTile));
    final item = content.links
        .firstWhere((l) => find.text(l.left).evaluate().isNotEmpty);
    expect(find.text(item.right), findsOneWidget);
    await tester.tap(tablet(item.links[1]), warnIfMissed: false);
    await tester.pump();
    expect(find.text('wrong'), findsOneWidget);
    await tester.tap(tablet(item.links.first), warnIfMissed: false);
    await tester.pump();
    // The pet rears back and lobs a bolt at the rune, the flames are bridged,
    // and only then does the spell go on from it to the boss.
    await waitFor(tester, damage, frames: 240);
    expect(tester.takeException(), isNull);
  });

  testWidgets('embers: tapping the one that means the same, before it goes',
      (tester) async {
    await startWith(tester, TrialBosses.dragon, 'EMBERS');
    await waitFor(tester, find.byType(SkinTile));
    final item = content.paraphrases.firstWhere((p) => talk(tester) == p.line);
    await tester.tap(tablet(item.options.first), warnIfMissed: false);
    await tester.pump();
    // The pet catches it, and flings it back.
    await waitFor(tester, damage, frames: 160);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'embers: they go out one by one, and the round with the right '
      'one', (tester) async {
    await startWith(tester, TrialBosses.dragon, 'EMBERS');
    await waitFor(tester, find.byType(SkinTile));
    expect(find.byType(SkinTile), findsNWidgets(3));
    await waitFor(tester, find.text('scorched'));
    expect(damage, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hoard: pairing the halves, with a wrong pair refused',
      (tester) async {
    await startWith(tester, TrialBosses.dragon, 'HOARD');
    final coinTiles = find
        .byWidgetPredicate((w) => w is SkinTile && w.shape == TileShape.coin);
    await waitFor(tester, coinTiles);
    final coins =
        tester.widgetList<SkinTile>(coinTiles).map((c) => c.label).toList();
    Finder coin(int i) => coinTiles.at(i);
    final phrases = content.phrases
        .where((p) => coins.contains(p.first) && coins.contains(p.second))
        .toList();
    expect(phrases.length, greaterThanOrEqualTo(DragonRules.hoardPairs));

    // Two first halves: refused.
    final firsts = [
      for (var i = 0; i < coins.length; i++)
        if (phrases.any((p) => p.first == coins[i])) i,
    ];
    await tester.tap(coin(firsts[0]));
    await tester.pump();
    await tester.tap(coin(firsts[1]));
    await tester.pump();
    expect(find.text('no'), findsOneWidget);
    // The coin the pet was carrying flies back to its place.
    await advance(tester, 400);

    final paired = <int>{};
    for (final p in phrases) {
      final a = [
        for (var i = 0; i < coins.length; i++)
          if (coins[i] == p.first && !paired.contains(i)) i,
      ];
      final b = [
        for (var i = 0; i < coins.length; i++)
          if (coins[i] == p.second && !paired.contains(i)) i,
      ];
      if (a.isEmpty || b.isEmpty) continue;
      await tester.tap(coin(a.first));
      await tester.pump();
      await tester.tap(coin(b.first));
      await tester.pump();
      paired.addAll([a.first, b.first]);
    }
    expect(paired, hasLength(coins.length));
    // The pet carries each coin to its match first.
    await waitFor(tester, damage, frames: 400);
    expect(tester.takeException(), isNull);
  });

  // ---- the finales: one opening after another ------------------------------

  final round2 = find.text('ROUND 2');

  Future<void> waitUntil(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 4000 && !done(); i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(done(), isTrue, reason: 'it never came');
  }

  testWidgets('sableth\'s finale: its riddles won, the door is next',
      (tester) async {
    await startWith(tester, TrialBosses.sphinx, 'FINALE');
    String? last;
    TrialRiddle? asking() {
      if (find.byType(TalkPanel).evaluate().isEmpty ||
          find.byType(SkinTile).evaluate().isEmpty) {
        return null;
      }
      final said = talk(tester);
      for (final r in content.riddles) {
        if (r.question != last && said.contains(r.question)) return r;
      }
      return null;
    }

    for (var i = 0; i < 60 && round2.evaluate().isEmpty; i++) {
      await waitUntil(
          tester, () => round2.evaluate().isNotEmpty || asking() != null);
      final riddle = asking();
      if (riddle == null) break;
      last = riddle.question;
      await tester.tap(tablet(riddle.answers.first), warnIfMissed: false);
      await tester.pump();
    }
    expect(round2, findsOneWidget);
    expect(find.text('DOOR'), findsOneWidget, reason: 'the round it roars in');
    // The door's round starts, rather than the boss standing there.
    await waitFor(tester, find.byType(SealedDoor), frames: 400);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pyrewing\'s finale: its parleys won, the link is next',
      (tester) async {
    await startWith(tester, TrialBosses.dragon, 'FINALE');
    final turns = content.parleys.expand((p) => p.turns).toList();
    String? last;
    ParleyTurn? asking() {
      if (find.byType(TalkPanel).evaluate().isEmpty ||
          find.byType(SkinTile).evaluate().isEmpty) {
        return null;
      }
      final said = talk(tester);
      if (said == last) return null;
      for (final t in turns) {
        if (t.line == said) return t;
      }
      return null;
    }

    for (var i = 0; i < 120 && round2.evaluate().isEmpty; i++) {
      await waitUntil(
          tester, () => round2.evaluate().isNotEmpty || asking() != null);
      final turn = asking();
      if (turn == null) break;
      last = turn.line;
      await tester.tap(tablet(turn.replies.first), warnIfMissed: false);
      await tester.pump();
    }
    expect(round2, findsOneWidget);
    expect(find.text('LINK'), findsOneWidget, reason: 'the round it roars in');
    await waitUntil(tester,
        () => content.links.any((l) => find.text(l.left).evaluate().isNotEmpty));
    expect(tester.takeException(), isNull);
  });
}
