import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/boss_trial/crystal_pieces.dart';
import 'package:mojilearner_flutter/components/boss_trial/trial_boss.dart';
import 'package:mojilearner_flutter/components/boss_trial/trial_skin.dart';
import 'package:mojilearner_flutter/constants/boss_trial_advanced.dart';
import 'package:mojilearner_flutter/constants/boss_trial_sentences.dart';
import 'package:mojilearner_flutter/constants/boss_trial_words.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/screens/boss_trial_screen.dart';
import 'package:mojilearner_flutter/utils/boss_trial_crystal.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pet_probe.dart';
import '../helpers/pump_app.dart';

/// Amethyst's trial: its three openings under test — Crystal Spikes, Crystal
/// Echo and Shard Volley — and its crystal spells.
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
  String meaningOf(String target) =>
      words.firstWhere((w) => w.target == target).meaning;

  // Never loaded from storage: awaiting SecureStorage under testWidgets'
  // FakeAsync deadlocks. See quiz_screen_srs_test.
  Future<void> pumpTrial(WidgetTester tester, {String? opening}) async {
    await pumpApp(
      tester,
      BossTrialScreen(key: UniqueKey(), boss: TrialBosses.amethyst),
      characterProvider: mockCharacter,
      languageProvider: mockLanguage,
      vocabProvider: VocabProvider(),
    );
    await tester.pump();
    if (opening != null) {
      await tester.tap(find.text(opening));
      await tester.pump();
    }
  }

  /// Runs the game clock frame by frame, the way a device would.
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

  Future<void> start(WidgetTester tester) async {
    // Below the fold on a short screen: the pickers make its intro tall.
    await tester.ensureVisible(find.text('START TRIAL'));
    await tester.tap(find.text('START TRIAL'));
    await tester.pump();
  }

  final damage = find.textContaining(RegExp(r'^-\d+$'));

  testWidgets('opens on its intro, with three openings to try',
      (tester) async {
    await pumpTrial(tester);

    expect(find.text('LEVEL 6 · SPIKES'), findsOneWidget);
    expect(find.text('LEVELS 6–10 · PICK ONE TO TRY'), findsOneWidget);
    for (final name in ['SPIKES', 'ECHO', 'VOLLEY']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.textContaining('crystal spike grows down'), findsOneWidget);

    await tester.tap(find.text('ECHO'));
    await tester.pump();
    expect(find.textContaining('three crystals rise'), findsOneWidget);
    expect(find.textContaining('crystal spike grows down'), findsNothing);

    // Mossback offers its own openings; back to Amethyst starts over on its
    // first.
    await tester.tap(find.text('LV 5\nMOSSBACK'));
    await tester.pump();
    expect(find.text('CATCH'), findsOneWidget);
    expect(find.text('SPIKES'), findsNothing);
    await tester.tap(find.text('LV 10\nAMETHYST'));
    await tester.pump();
    expect(find.textContaining('crystal spike grows down'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // ---- advanced English -----------------------------------------------------

  Future<void> pickAdvanced(WidgetTester tester) async {
    await tester.tap(find.text('ADVANCED EN'));
    await tester.pump();
  }

  testWidgets('advanced English swaps in its own words', (tester) async {
    await pumpTrial(tester);
    await pickAdvanced(tester);
    expect(find.textContaining('plain-English meanings'), findsOneWidget);

    await start(tester);
    await waitFor(tester, find.byType(CrystalSpike));
    final advanced = advancedEnglishWords.map((w) => w.target).toSet();
    expect(
      tester
          .widgetList<CrystalSpike>(find.byType(CrystalSpike))
          .every((s) => advanced.contains(s.label)),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the advanced echo roars an advanced sentence', (tester) async {
    await pumpTrial(tester, opening: 'ECHO');
    await pickAdvanced(tester);
    await start(tester);
    await waitFor(tester, find.byType(EchoCrystal));

    final roared = advancedEnglishSentences
        .where((s) => find.text(s.target).evaluate().isNotEmpty);
    expect(roared, hasLength(1));
    expect(
      tester
          .widgetList<EchoCrystal>(find.byType(EchoCrystal))
          .map((c) => c.label),
      contains(roared.single.meaning),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching boss goes back to normal content', (tester) async {
    await pumpTrial(tester);
    await pickAdvanced(tester);
    await tester.tap(find.text('LV 5\nMOSSBACK'));
    await tester.pump();
    expect(find.text('ADVANCED EN'), findsNothing);

    await tester.tap(find.text('LV 10\nAMETHYST'));
    await tester.pump();
    expect(find.textContaining('plain-English meanings'), findsNothing);
    expect(find.textContaining('12 WORDS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // ---- Crystal Spikes --------------------------------------------------------

  List<CrystalSpike> spikes(WidgetTester tester) =>
      tester.widgetList<CrystalSpike>(find.byType(CrystalSpike)).toList();

  testWidgets('a spike and its gem shatter together and hit the bear',
      (tester) async {
    await pumpTrial(tester);
    await start(tester);
    await waitFor(tester, find.byType(CrystalSpike));

    expect(find.byType(CrystalSpike), findsNWidgets(4));
    expect(find.byType(CrystalGem), findsNWidgets(4));
    final roared = spikes(tester).first.label;

    await tester.tap(find.byType(CrystalSpike).first);
    await tester.pump();
    expect(spikes(tester).first.state, CrystalPieceState.held);
    await tester.tap(find.widgetWithText(CrystalGem, meaningOf(roared)));
    await tester.pump();

    // The pet runs to the gem, scoops it up and leaps with it at the spike's
    // base: the spike stands till then, and the hit lands a second or two on.
    expect(find.byType(CrystalSpike), findsNWidgets(4));
    await advance(tester, 300);
    expect(find.text('x0'), findsOneWidget);
    await waitFor(tester, find.text('x1'), frames: 260);
    expect(find.byType(CrystalSpike), findsNWidgets(3));
    expect(damage, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a wrong pair costs the streak, not a heart', (tester) async {
    await pumpTrial(tester);
    await start(tester);
    await waitFor(tester, find.byType(CrystalSpike));

    final roared = spikes(tester).first.label;
    final other = tester
        .widgetList<CrystalGem>(find.byType(CrystalGem))
        .firstWhere((g) => g.label != meaningOf(roared))
        .label;
    await tester.tap(find.byType(CrystalSpike).first);
    await tester.pump();
    await tester.tap(find.widgetWithText(CrystalGem, other));
    await tester.pump();

    expect(find.text('wrong'), findsOneWidget);
    expect(find.byType(CrystalSpike), findsNWidgets(4));
    expect(find.text('sealed'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a spike reaching the pet seals it in; three end the trial',
      (tester) async {
    await pumpTrial(tester);
    await start(tester);

    await waitFor(tester, find.text('sealed'));
    // The rest crumble with it.
    expect(find.byType(CrystalSpike), findsNothing);

    await waitFor(tester, find.text('AMETHYST WOULD NOT BUDGE'));
    expect(find.text('WORDS TO PRACTISE'), findsOneWidget);
    expect(find.textContaining('0 SHATTERED'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // ---- Crystal Echo ----------------------------------------------------------

  List<EchoCrystal> crystals(WidgetTester tester) =>
      tester.widgetList<EchoCrystal>(find.byType(EchoCrystal)).toList();

  testWidgets('the echo: a wrong crystal flashes; the right one hits',
      (tester) async {
    await pumpTrial(tester, opening: 'ECHO');
    await start(tester);
    await waitFor(tester, find.byType(EchoCrystal));

    expect(find.byType(EchoCrystal), findsNWidgets(3));
    // It roars in the language being learned; the crystals are in the
    // player's.
    final roared =
        sentences.firstWhere((s) => find.text(s.target).evaluate().isNotEmpty);
    final labels = crystals(tester).map((c) => c.label).toList();
    expect(labels, contains(roared.meaning));

    final wrong = labels.indexWhere((l) => l != roared.meaning);
    await tester.tap(find.byType(EchoCrystal).at(wrong));
    await tester.pump();
    expect(find.text('wrong'), findsOneWidget);
    await advance(tester, 300);
    expect(crystals(tester)[wrong].state, CrystalPieceState.wrong);

    await tester.tap(find.widgetWithText(EchoCrystal, roared.meaning));
    await tester.pump();
    // The pet jumps at the crystal first; the crystal bursts into the hit.
    await advance(tester, 200);
    expect(find.text('x0'), findsOneWidget);
    await waitFor(tester, find.text('x1'), frames: 200);
    expect(damage, findsOneWidget);
    expect(find.text('sealed'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the echo left unanswered seals the pet and lists the sentence',
      (tester) async {
    await pumpTrial(tester, opening: 'ECHO');
    await start(tester);

    await waitFor(tester, find.text('sealed'));
    // What it said is lit for the aftermath.
    expect(
      crystals(tester).where((c) => c.state == CrystalPieceState.revealed),
      hasLength(1),
    );

    await waitFor(tester, find.text('AMETHYST WOULD NOT BUDGE'));
    expect(find.text('SENTENCES TO PRACTISE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // ---- Shard Volley ----------------------------------------------------------

  /// Waits for a shard in the air that is [truth]ful, or lies.
  Future<VolleyShardTile> waitForShard(WidgetTester tester,
      {required bool truth}) async {
    for (var i = 0; i < 2000; i++) {
      final match = tester
          .widgetList<VolleyShardTile>(find.byType(VolleyShardTile))
          .where((s) => (meaningOf(s.word) == s.claim) == truth);
      if (match.isNotEmpty) return match.first;
      await tester.pump(const Duration(milliseconds: 16));
    }
    fail('no ${truth ? 'true' : 'lying'} shard was thrown');
  }

  testWidgets('a lie smashed is swatted back at the bear', (tester) async {
    await pumpTrial(tester, opening: 'VOLLEY');
    await start(tester);

    final lie = await waitForShard(tester, truth: false);
    await tester.tap(find.byWidget(lie));
    await tester.pump();
    expect(find.text('lie!'), findsOneWidget);
    // The pet leaps at it and swats it first.
    await waitFor(tester, damage, frames: 120);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a true shard smashed costs the streak, not a heart',
      (tester) async {
    await pumpTrial(tester, opening: 'VOLLEY');
    await start(tester);

    final truth = await waitForShard(tester, truth: true);
    await tester.tap(find.byWidget(truth));
    await tester.pump();
    expect(find.text('it was true'), findsOneWidget);
    expect(find.text('x0'), findsOneWidget);
    expect(find.text('sealed'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a lie let through seals the pet and ends the volley',
      (tester) async {
    await pumpTrial(tester, opening: 'VOLLEY');
    await start(tester);

    await waitFor(tester, find.text('sealed'));
    expect(find.byType(VolleyShardTile), findsNothing);
    expect(tester.takeException(), isNull);
  });

  // ---- crystal spells --------------------------------------------------------

  // ---- the pet's body --------------------------------------------------------

  double spread(Iterable<double> values) =>
      values.reduce(max) - values.reduce(min);

  /// The pet sealed in amethyst — which has just happened — stays where it
  /// is, shivers as the crystal cracks, and breaks out with a hop.
  Future<void> expectBreaksOut(WidgetTester tester) async {
    final run = await PetProbe(tester).track(135);
    final ground = run.map((s) => s.feet).reduce(max);
    // Frozen where it was sealed, once the blow's own shake is over...
    expect(spread(run.skip(25).take(40).map((s) => s.x)), lessThan(1.5));
    // ...trembling hard in the last half second of the seal...
    expect(spread(run.skip(72).take(26).map((s) => s.x)), greaterThan(3));
    // ...and up with a hop when the crystal breaks.
    expect(run.skip(100).map((s) => s.feet).reduce(min), lessThan(ground - 15));
  }

  testWidgets('spikes: a matched pair — the pet runs to its gem, squats and '
      'scoops it up, then LEAPS with it at the spike\'s base, which breaks as '
      'it hits', (tester) async {
    await pumpTrial(tester);
    await start(tester);
    await waitFor(tester, find.byType(CrystalSpike));
    await advance(tester, 300);
    final pet = PetProbe(tester);
    final home = pet.x;
    final rest = pet.head;

    final roared = spikes(tester).first.label;
    final gem = find.widgetWithText(CrystalGem, meaningOf(roared));
    final gemX = tester.getCenter(gem).dx;
    final plate = tester.getRect(find.byType(CrystalSpike).first);
    await tester.tap(find.byType(CrystalSpike).first);
    await tester.pump();
    await tester.tap(gem);
    await tester.pump();

    // It sets off at once, facing the gem, and does not snap there...
    await advance(tester, 64);
    expect(pet.facesLeft, gemX < home, reason: 'running to $gemX from $home');
    expect((pet.x - home).abs(), greaterThan(1));
    expect((pet.x - gemX).abs(), greaterThan(1));

    final held = find.byKey(const ValueKey('held-crystal'));
    final run = <PetSample>[];
    final carried = <Offset?>[];
    final standing = <bool>[];
    var struck = -1;
    for (var i = 0; i < 200; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      run.add(pet.sample);
      carried.add(held.evaluate().isEmpty ? null : tester.getCenter(held));
      standing.add(find.byType(CrystalSpike).evaluate().length == 4);
      if (struck < 0 && find.text('x1').evaluate().isNotEmpty) struck = i;
    }
    // ...gets there, squats to take the gem...
    expect(run.any((s) => (s.x - gemX).abs() < 6), isTrue);
    expect(run.lowestSquash, lessThan(0.75));
    // ...and up at the spike's base, the gem held over its head all the way up,
    // as far as a leap goes.
    final root = plate.bottom - 4;
    expect(run.highestHead,
        closeTo(min(rest, max(root, rest - pet.size.height * 2.6)), 24));
    final riding = [
      for (var i = 0; i < run.length; i++)
        if (carried[i] != null) i,
    ];
    expect(riding.length, greaterThan(15));
    for (final i in riding) {
      expect((carried[i]!.dx - run[i].x).abs(), lessThan(16), reason: 'frame $i');
    }
    // The spike stands till the pet's head is at it, and the hit follows its
    // breaking.
    final broke = standing.indexOf(false);
    expect(broke, greaterThan(riding.last - 8));
    expect(struck, greaterThan(broke - 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('spikes: a wrong pair makes the pet cringe, turned to the spike',
      (tester) async {
    await pumpTrial(tester);
    await start(tester);
    await waitFor(tester, find.byType(CrystalSpike));
    await advance(tester, 300);
    final pet = PetProbe(tester);
    final home = pet.x;

    final roared = spikes(tester).first.label;
    final other = tester
        .widgetList<CrystalGem>(find.byType(CrystalGem))
        .firstWhere((g) => g.label != meaningOf(roared))
        .label;
    final spikeX = tester.getCenter(find.byType(CrystalSpike).first).dx;
    await tester.tap(find.byType(CrystalSpike).first);
    await tester.pump();
    await tester.tap(find.widgetWithText(CrystalGem, other));
    await tester.pump();

    final cringe = await pet.track(20);
    expect(cringe.lowestSquash, lessThan(0.9));
    expect(cringe.first.facesLeft, spikeX < home);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a pet sealed by a spike stays put, shivers as the crystal '
      'cracks, and breaks out with a hop', (tester) async {
    await pumpTrial(tester);
    await start(tester);
    await waitFor(tester, find.text('sealed'));
    await expectBreaksOut(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the echo: the amethyst creeping up the pet makes it shiver',
      (tester) async {
    await pumpTrial(tester, opening: 'ECHO');
    await start(tester);
    await waitFor(tester, find.byType(EchoCrystal));
    final pet = PetProbe(tester);
    await advance(tester, 4000);
    final run = await pet.track(40);
    expect(spread(run.map((s) => s.x)), greaterThan(1.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the echo: the shiver slows and the pet sags as the amethyst '
      'climbs it', (tester) async {
    await pumpTrial(tester, opening: 'ECHO');
    await start(tester);
    await waitFor(tester, find.byType(EchoCrystal));
    final pet = PetProbe(tester);
    // How many times it goes from one side of its trembling to the other.
    int swings(List<PetSample> run) {
      final mid =
          (run.map((s) => s.x).reduce(max) + run.map((s) => s.x).reduce(min)) / 2;
      var n = 0;
      var side = 0.0;
      for (final s in run) {
        final d = s.x - mid;
        if (d.abs() < 0.5) continue;
        if (side != 0 && d.sign != side) n++;
        side = d.sign;
      }
      return n;
    }

    double creeping() => tester
        .widgetList<CustomPaint>(find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is CrystalCasePainter))
        .map((c) => (c.painter! as CrystalCasePainter).fill)
        .first;
    Future<void> until(double creep) async {
      for (var i = 0; i < 2000 && creeping() < creep; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    // Early on: the amethyst has barely begun, and it stands tall.
    await advance(tester, 300);
    final early = await pet.track(30);
    expect(early.lowestSquash, greaterThan(0.97));
    // Climbing: heavier, and the shiver, harder, is slower.
    await until(0.45);
    final mid = await pet.track(50);
    await until(0.85);
    final late = await pet.track(50);
    expect(late.lowestSquash, lessThan(mid.lowestSquash + 0.001));
    expect(late.lowestSquash, lessThan(0.95));
    expect(spread(late.map((s) => s.x)), greaterThan(spread(mid.map((s) => s.x))));
    expect(swings(late), lessThan(swings(mid)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the echo: the pet springs straight up at the right crystal and '
      'HEADBUTTS it — head back on the way up, then down into it — and the '
      'crystal, lit till then, bursts', (tester) async {
    await pumpTrial(tester, opening: 'ECHO');
    await start(tester);
    await waitFor(tester, find.byType(EchoCrystal));
    await advance(tester, 300);
    final pet = PetProbe(tester);
    final ground = pet.feet;
    final home = pet.x;

    final roared =
        sentences.firstWhere((s) => find.text(s.target).evaluate().isNotEmpty);
    final right =
        crystals(tester).indexWhere((c) => c.label == roared.meaning);
    await tester.tap(find.widgetWithText(EchoCrystal, roared.meaning));
    await tester.pump();

    // Off the ground at once, and the crystal still up, lit...
    await advance(tester, 150);
    expect(pet.feet, lessThan(ground - 10));
    expect(crystals(tester)[right].state, CrystalPieceState.held);
    // ...the crystal burst as the pet's head hit it, a third of a second on...
    final early = await pet.track(20);
    expect(crystals(tester)[right].state, CrystalPieceState.spent);
    final run = [...early, ...await pet.track(40)];
    expect(run.highest, lessThan(ground - 40));
    // ...head thrown back on the way up, then butted down into it...
    final dir = run.map((s) => s.tilt).reduce((a, b) => a.abs() > b.abs() ? a : b) < 0
        ? -1.0
        : 1.0;
    expect(run.map((s) => s.tilt * dir).reduce(max), greaterThan(0.45));
    expect(run.map((s) => s.tilt * dir).reduce(min), lessThan(-0.1));
    // (Before the bear is hit: the hit shakes the whole screen a moment.)
    expect(run.take(30).every((s) => (s.x - home).abs() < 1.5), isTrue);
    // ...and the hit landed.
    expect(find.text('x1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the echo: a pet sealed by it shivers and breaks out with a hop',
      (tester) async {
    await pumpTrial(tester, opening: 'ECHO');
    await start(tester);
    await waitFor(tester, find.text('sealed'));
    await expectBreaksOut(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('volley: a lie smashed hangs in the air where it was struck, and '
      'the pet LEAPS at it — head cocked back, then swept round — and swats it '
      'at the bear', (tester) async {
    await pumpTrial(tester, opening: 'VOLLEY');
    await start(tester);
    final ground = PetProbe(tester).feet;

    final lie = await waitForShard(tester, truth: false);
    final at = tester.getCenter(find.byWidget(lie));
    await tester.tap(find.byWidget(lie));
    await tester.pump();
    final pet = PetProbe(tester);
    final run = <PetSample>[];
    final chunk = <Offset?>[];
    var struck = -1;
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      run.add(pet.sample);
      // The nearest to where the lie was struck: an earlier shard, caught and
      // thrown back, may still be in the air beside it.
      final near = [
        for (final e in find.byType(CrystalChunk).evaluate())
          tester.getCenter(find.byWidget(e.widget)),
      ]..sort((a, b) => (a - at).distance.compareTo((b - at).distance));
      chunk.add(near.isEmpty ? null : near.first);
      if (struck < 0 && damage.evaluate().isNotEmpty) struck = i;
    }
    expect(run.msUntil((s) => s.feet < ground - 20), lessThan(150));
    expect(run.highest, lessThan(ground - 40));
    // Cocked back, then swept round at it.
    final dir = run.map((s) => s.tilt).reduce((a, b) => a.abs() > b.abs() ? a : b) < 0
        ? -1.0
        : 1.0;
    expect(run.map((s) => s.tilt * dir).reduce(max), greaterThan(0.7));
    expect(run.map((s) => s.tilt * dir).reduce(min), lessThan(-0.4));
    // Hanging where it was struck until then.
    expect(chunk.first, isNotNull);
    expect((chunk.first! - at).distance, lessThan(30));
    expect(struck, greaterThan(10));
    expect(tester.takeException(), isNull);
  });

  testWidgets('volley: the pet runs to keep under the shards, facing the way '
      'it goes', (tester) async {
    await pumpTrial(tester, opening: 'VOLLEY');
    await start(tester);
    final pet = PetProbe(tester);
    final home = pet.x;
    await waitFor(tester, find.byType(VolleyShardTile));

    final run = await pet.track(120);
    final away = run.indexWhere((s) => (s.x - home).abs() > 30);
    expect(away, greaterThanOrEqualTo(0), reason: 'it never ran off');
    // While it is running, it faces the way it runs.
    final moving = run.indexWhere((s) => (s.x - home).abs() > 10);
    expect(run[moving].facesLeft, run[moving].x < home);
    expect(tester.takeException(), isNull);
  });

  testWidgets('volley: a true shard let through is caught with a squat and '
      'thrown back', (tester) async {
    await pumpTrial(tester, opening: 'VOLLEY');
    await start(tester);

    // Smash every lie as it comes; let the true ones through.
    for (var i = 0; i < 3000 && find.text('true').evaluate().isEmpty; i++) {
      for (final shard in tester
          .widgetList<VolleyShardTile>(find.byType(VolleyShardTile))
          .where((s) => meaningOf(s.word) != s.claim)
          .toList()) {
        await tester.tap(find.byWidget(shard), warnIfMissed: false);
      }
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text('true'), findsOneWidget);

    final pet = PetProbe(tester);
    final run = <PetSample>[];
    var held = false;
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      run.add(pet.sample);
      held |= find.byKey(const ValueKey('held-crystal')).evaluate().isNotEmpty;
    }
    // A squat to take it, low...
    expect(run.lowestSquash, lessThan(0.75), reason: 'it squats to catch');
    expect(held, isTrue, reason: 'held up over its head');
    // ...and a spinning throw: right round in the air, once.
    expect(run.map((s) => s.width).reduce(min), lessThan(-0.8));
    var edges = 0;
    for (var i = 1; i < run.length; i++) {
      if (run[i].width * run[i - 1].width < 0) edges++;
    }
    expect(edges, 2);
    expect(run.highest, lessThan(run.first.feet - 8));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the volley: a pet sealed by a lie breaks out with a hop',
      (tester) async {
    await pumpTrial(tester, opening: 'VOLLEY');
    await start(tester);
    await waitFor(tester, find.text('sealed'));
    final run = await PetProbe(tester).track(135);
    final ground = run.map((s) => s.feet).reduce(max);
    // Cracking, shivering, and up with a hop when it breaks.
    expect(spread(run.skip(72).take(26).map((s) => s.x)), greaterThan(3));
    expect(run.skip(100).map((s) => s.feet).reduce(min), lessThan(ground - 15));
    expect(tester.takeException(), isNull);
  });

  testWidgets('vein: the pet looks up at the wall, a hop for each crystal lit, '
      'turned to it; the whole vein is cast at the bear as a crystal',
      (tester) async {
    await pumpTrial(tester, opening: 'VEIN');
    await start(tester);
    await waitFor(tester, find.byType(SkinTile));
    await advance(tester, 300);
    final pet = PetProbe(tester);
    final home = pet.x;
    final ground = pet.feet;
    // Looking up at the wall: nose up, a quarter of a radian back.
    final looking = await pet.track(10);
    expect(looking.every((s) => (s.tilt + 0.25).abs() < 0.03), isTrue);

    // The vein: each word of the sentence, in order, in the crystal beside
    // the one before.
    final sentence = sentences
        .firstWhere((s) => find.text(s.meaning).evaluate().isNotEmpty);
    List<SkinTile> wall() =>
        tester.widgetList<SkinTile>(find.byType(SkinTile)).toList();
    final labels = wall().map((t) => t.label).toList();
    var previous = -1;
    var first = true;
    for (final token in sentence.tokens) {
      final candidates = [
        for (var i = 0; i < labels.length; i++)
          if (labels[i] == token &&
              wall()[i].badge == null &&
              (previous < 0 || VeinWave.neighbours(previous).contains(i)))
            i,
      ];
      var lit = false;
      for (final cell in candidates) {
        final at = tester.getCenter(find.byType(SkinTile).at(cell));
        await tester.tap(find.byType(SkinTile).at(cell));
        await tester.pump();
        if (wall()[cell].badge != null) {
          lit = true;
          previous = cell;
          if (first) {
            // The first crystal: a hop, and the pet turned to it.
            first = false;
            if ((at.dx - home).abs() > 12) {
              expect(pet.facesLeft, at.dx < home);
            }
            final hop = await pet.track(10);
            expect(hop.highest, lessThan(ground - 8));
          }
          break;
        }
      }
      expect(lit, isTrue, reason: 'no crystal for "$token"');
      if (token != sentence.tokens.last) await advance(tester, 350);
    }

    // Lit through the wind-up, cast at the bear at the end — as a crystal:
    // back, then forward.
    final run = <PetSample>[];
    var crystal = false;
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      run.add(pet.sample);
      crystal |= find.byType(CrystalChunk).evaluate().isNotEmpty;
    }
    final thrust =
        run.map((s) => s.tilt).reduce((a, b) => a.abs() > b.abs() ? a : b);
    final lean = thrust < 0 ? -1.0 : 1.0;
    expect(run.map((s) => s.tilt * lean).reduce(min), lessThan(-0.15));
    expect(run.map((s) => s.tilt * lean).reduce(max), greaterThan(0.25));
    expect(run.lowestSquash, lessThan(0.95));
    expect(crystal, isTrue);
    expect(find.text('x1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
