import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/boss_trial/angler_pieces.dart';
import 'package:mojilearner_flutter/components/boss_trial/spell_pieces.dart';
import 'package:mojilearner_flutter/components/boss_trial/trial_boss.dart';
import 'package:mojilearner_flutter/constants/boss_trial_sentences.dart';
import 'package:mojilearner_flutter/constants/boss_trial_words.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/screens/boss_trial_screen.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pet_probe.dart';
import '../helpers/pump_app.dart';

/// Lanternmaw, trial 4: its two openers under test, the Lure and the
/// Bubbles, and its bubble in the Spells round.
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
  Future<void> pumpTrial(WidgetTester tester) async {
    await pumpApp(
      tester,
      BossTrialScreen(key: UniqueKey(), boss: TrialBosses.angler),
      characterProvider: mockCharacter,
      languageProvider: mockLanguage,
      vocabProvider: VocabProvider(),
    );
    await tester.pump();
  }

  Future<void> startWith(WidgetTester tester, String opening) async {
    await pumpTrial(tester);
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

  /// The bubbles that can be tapped now: not one the pet is already on its way
  /// to, which waits where it was picked.
  Finder bubbleLabelled(String label) => find.byWidgetPredicate(
      (w) => w is LetterBubble && w.label == label && w.onTapDown != null);
  Finder strayBubble(String word) => find.byWidgetPredicate((w) =>
      w is LetterBubble && !word.contains(w.label) && w.onTapDown != null);

  testWidgets('is trial 4, at level 20, with both openers to try',
      (tester) async {
    await pumpTrial(tester);
    expect(find.text('LEVEL 16 · LURE'), findsOneWidget);
    expect(find.text('LEVELS 16–20 · PICK ONE TO TRY'), findsOneWidget);
    expect(find.text('Lanternmaw'), findsOneWidget);
    expect(find.text('LURE'), findsOneWidget);
    expect(find.text('BUBBLES'), findsOneWidget);
    expect(find.text('LV 20\nLANTERNMAW'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the lure: hooking the fish that fills the gap hits it',
      (tester) async {
    await startWith(tester, 'LURE');
    await waitFor(tester, find.byType(WordFish));

    final board = tester.widget<LureBoard>(find.byType(LureBoard));
    expect(board.state, LureGap.waiting);
    // What it says in English is up, and it is one of the stock sentences.
    final said =
        sentences.firstWhere((s) => find.text(s.meaning).evaluate().isNotEmpty);
    expect(board.words, said.tokens);

    final missing = board.words[board.gap];
    final fish =
        find.byWidgetPredicate((w) => w is WordFish && w.label == missing);
    expect(fish, findsOneWidget);
    await tester.tap(fish, warnIfMissed: false);
    await tester.pump();

    expect(
        tester.widget<LureBoard>(find.byType(LureBoard)).state, LureGap.hooked);
    // The pet dashes, nips it, and spits before the spell flies.
    await waitFor(tester, damage, frames: 150);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the lure: a wrong fish darts off; the light going out gulps',
      (tester) async {
    await startWith(tester, 'LURE');
    await waitFor(tester, find.byType(WordFish));

    final board = tester.widget<LureBoard>(find.byType(LureBoard));
    final missing = board.words[board.gap];
    final wrong =
        find.byWidgetPredicate((w) => w is WordFish && w.label != missing);
    final label = tester.widget<WordFish>(wrong.first).label;
    await tester.tap(wrong.first, warnIfMissed: false);
    await tester.pump();
    expect(find.text('wrong'), findsOneWidget);
    await advance(tester, 400);
    expect(
      find.byWidgetPredicate((w) => w is WordFish && w.label == label),
      findsNothing,
    );

    // Let the lantern go out.
    await waitFor(tester, find.text('blub'));
    expect(
        tester.widget<LureBoard>(find.byType(LureBoard)).state, LureGap.missed);
    expect(damage, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the bubbles: popping the letters in order spells the word',
      (tester) async {
    await startWith(tester, 'BUBBLES');
    await waitFor(tester, find.byType(LetterBubble));

    final asked =
        words.firstWhere((w) => find.text(w.meaning).evaluate().isNotEmpty);
    final letters = asked.target.split('');
    for (final letter in letters) {
      final bubble = bubbleLabelled(letter);
      expect(bubble, findsWidgets, reason: 'no bubble for "$letter"');
      await tester.tap(bubble.first, warnIfMissed: false);
      await tester.pump();
    }
    final line = tester.widget<SpellLine>(find.byType(SpellLine));
    expect(line.filled.join(), asked.target);
    // The pet rears back and casts the whole word before it flies.
    await waitFor(tester, damage, frames: 120);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the bubbles: a wrong letter is refused; the gulp traps the pet',
      (tester) async {
    await startWith(tester, 'BUBBLES');
    await waitFor(tester, find.byType(LetterBubble));

    final asked =
        words.firstWhere((w) => find.text(w.meaning).evaluate().isNotEmpty);
    final stray = strayBubble(asked.target);
    await tester.tap(stray.first, warnIfMissed: false);
    await tester.pump();
    expect(find.text('wrong'), findsOneWidget);
    expect(tester.widget<SpellLine>(find.byType(SpellLine)).filled, isEmpty);

    await waitFor(tester, find.text('blub'));
    // The line shows the word it wanted.
    expect(tester.widget<SpellLine>(find.byType(SpellLine)).filled.join(),
        asked.target);
    expect(tester.takeException(), isNull);
  });

  // ---- the pet's body --------------------------------------------------------

  Finder fishLabelled(String label) =>
      find.byWidgetPredicate((w) => w is WordFish && w.label == label);

  /// How much bubble there is round the pet.
  double petBubble(WidgetTester tester) {
    final paint = tester.widget<CustomPaint>(find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is PetBubblePainter));
    return (paint.painter! as PetBubblePainter).fill;
  }

  testWidgets('lure: the pet dashes along the seabed to under the fish, nips '
      'it, and spits the spell at the boss from its mouth', (tester) async {
    await startWith(tester, 'LURE');
    await waitFor(tester, find.byType(WordFish));
    await advance(tester, 400);
    final pet = PetProbe(tester);
    final ground = pet.feet;
    final rest = pet.head;
    final home = pet.x;
    final reach = pet.size.height * 2;

    final board = tester.widget<LureBoard>(find.byType(LureBoard));
    final fish = fishLabelled(board.words[board.gap]);
    // Wait for the fish to swim well off to one side of the pet.
    for (var i = 0;
        i < 250 && (tester.getCenter(fish).dx - home).abs() < 80;
        i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final rect = tester.getRect(fish);
    final across = rect.center.dx - home;
    final side = across < 0 ? -1.0 : 1.0;
    await tester.tap(fish, warnIfMissed: false);
    await tester.pump();

    // The dash: low and stretched along the seabed, tipped into it, at once.
    final dash = await pet.track(16);
    if (across.abs() > 80) {
      expect(dash.map((s) => (s.x - home) * side).reduce(max),
          greaterThan(across.abs() * 0.6));
      expect(dash.first.facesLeft, across < 0);
      expect(dash.map((s) => s.tilt * side).reduce(max), greaterThan(0.15));
    }
    expect(dash.every((s) => s.feet > ground - 6), isTrue,
        reason: 'it stays on the seabed');
    expect(dash.lowestSquash, lessThan(0.95));

    // The nip: up at the fish from under it, which is gone in a gulp.
    final nip = <PetSample>[];
    for (var i = 0; i < 90 && fish.evaluate().isNotEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      nip.add(pet.sample);
    }
    expect(fish, findsNothing);
    expect(nip.highestHead,
        closeTo(min(rest, max(rect.bottom - 10, rest - reach)), 20));
    expect(damage, findsNothing);

    // The spit: it drops, turns to the boss, rears back and thrusts, and only
    // then does the spell fly.
    final spit = <PetSample>[];
    for (var i = 0; i < 200 && damage.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      spit.add(pet.sample);
    }
    // (From when it has dropped back down and the tip of the nip is gone.)
    final landed =
        spit.indexWhere((s) => s.feet > ground - 3 && s.tilt.abs() < 0.08);
    expect(landed, greaterThanOrEqualTo(0), reason: 'it drops back down');
    final cast = spit.sublist(landed);
    final thrust =
        cast.reduce((a, b) => a.tilt.abs() > b.tilt.abs() ? a : b);
    final lean = thrust.tilt < 0 ? -1.0 : 1.0;
    expect(thrust.tilt * lean, greaterThan(0.2));
    // The rear-back comes BEFORE the thrust, and is the other way.
    final reared = cast.take(cast.indexOf(thrust)).map((s) => s.tilt * lean);
    expect(reared.reduce(min), lessThan(-0.1));

    // Then it trots home.
    final back = await pet.track(60);
    expect(back.last.feet, closeTo(ground, 1));
    expect(back.last.x, closeTo(home, 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('lure: a wrong fish makes the pet cringe, turned to it',
      (tester) async {
    await startWith(tester, 'LURE');
    await waitFor(tester, find.byType(WordFish));
    await advance(tester, 400);
    final pet = PetProbe(tester);

    final board = tester.widget<LureBoard>(find.byType(LureBoard));
    final missing = board.words[board.gap];
    final wrong = find
        .byWidgetPredicate((w) => w is WordFish && w.label != missing)
        .first;
    final at = tester.getCenter(wrong);
    final home = pet.x;
    await tester.tap(wrong, warnIfMissed: false);
    await tester.pump();
    final run = await pet.track(20);
    expect(run.lowestSquash, lessThan(0.9));
    if ((at.dx - home).abs() > 12) {
      expect(run.first.facesLeft, at.dx < home);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('bubbles: the pet SWIMS up to each letter\'s bubble — no crouch, '
      'no spring, paddling as it goes — and noses it; the bubble waits where '
      'it was picked until it does', (tester) async {
    await startWith(tester, 'BUBBLES');
    await waitFor(tester, find.byType(LetterBubble));
    await advance(tester, 300);
    final pet = PetProbe(tester);
    final rest = pet.head;
    final home = pet.x;

    final asked =
        words.firstWhere((w) => find.text(w.meaning).evaluate().isNotEmpty);
    final bubble = bubbleLabelled(asked.target[0]).first;
    final at = tester.getCenter(bubble);
    final total = find.byType(LetterBubble).evaluate().length;
    await tester.tap(bubble, warnIfMissed: false);
    await tester.pump();

    final run = <PetSample>[];
    var burst = -1;
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      run.add(pet.sample);
      if (burst < 0 && find.byType(LetterBubble).evaluate().length < total) {
        burst = i;
      }
    }
    // A swim, not a leap: never squashed, never launched, every frame a small
    // step on from the last.
    expect(run.lowestSquash, greaterThan(0.95));
    for (var i = 1; i < run.length; i++) {
      expect((run[i].head - run[i - 1].head).abs(), lessThan(14),
          reason: 'frame $i');
    }
    // Paddling: it tips one way and the other as it goes.
    var tips = 0;
    for (var i = 1; i < 30; i++) {
      if (run[i].tilt * run[i - 1].tilt < 0) tips++;
    }
    expect(tips, greaterThanOrEqualTo(2));
    // It takes its time getting there, and the bubble bursts as its nose is
    // under it.
    expect(burst, greaterThan(20));
    if (rest - at.dy > 40) {
      expect(run.highestHead, closeTo(max(at.dy + 22, rest - pet.size.height * 2.6), 20));
    }
    expect((run[burst].x - at.dx).abs(), lessThan(40));
    // And it sinks slowly back down, rather than dropping (if it had gone up).
    if (rest - run.highestHead > 30) {
      expect((run.last.head - run[burst].head), greaterThan(8));
    }
    expect(run.first.x, closeTo(home, 40));
    expect(tester.takeException(), isNull);
  });

  testWidgets('bubbles: a letter tapped on the heels of another does not drop '
      'the pet to the ground between the leaps', (tester) async {
    await startWith(tester, 'BUBBLES');
    await waitFor(tester, find.byType(LetterBubble));
    await advance(tester, 300);
    final pet = PetProbe(tester);

    final asked =
        words.firstWhere((w) => find.text(w.meaning).evaluate().isNotEmpty);
    Future<void> tapLetter(int i) async {
      final bubble = bubbleLabelled(asked.target[i]).first;
      await tester.tap(bubble, warnIfMissed: false);
      await tester.pump();
    }

    await tapLetter(0);
    await advance(tester, 112);
    final during = pet.sample;
    await tapLetter(1);
    final run = <PetSample>[during, ...await pet.track(60)];
    for (var i = 1; i < run.length; i++) {
      expect((run[i].feet - run[i - 1].feet).abs(), lessThan(40),
          reason: 'frame $i');
      expect((run[i].x - run[i - 1].x).abs(), lessThan(40),
          reason: 'frame $i');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('bubbles: a wrong letter makes the pet cringe', (tester) async {
    await startWith(tester, 'BUBBLES');
    await waitFor(tester, find.byType(LetterBubble));
    await advance(tester, 300);
    final pet = PetProbe(tester);

    final asked =
        words.firstWhere((w) => find.text(w.meaning).evaluate().isNotEmpty);
    final stray = strayBubble(asked.target).first;
    await tester.tap(stray, warnIfMissed: false);
    await tester.pump();
    final run = await pet.track(20);
    expect(run.lowestSquash, lessThan(0.9));
    expect(tester.takeException(), isNull);
  });

  testWidgets('bubbles: the whole word spelt, the pet rears back and casts it',
      (tester) async {
    await startWith(tester, 'BUBBLES');
    await waitFor(tester, find.byType(LetterBubble));
    await advance(tester, 300);
    final pet = PetProbe(tester);

    final asked =
        words.firstWhere((w) => find.text(w.meaning).evaluate().isNotEmpty);
    for (final letter in asked.target.split('')) {
      final bubble = bubbleLabelled(letter).first;
      await tester.tap(bubble, warnIfMissed: false);
      await tester.pump();
      await advance(tester, 450);
    }
    final run = await pet.track(70);
    final thrust =
        run.map((s) => s.tilt).reduce((a, b) => a.abs() > b.abs() ? a : b);
    final lean = thrust < 0 ? -1.0 : 1.0;
    expect(run.map((s) => s.tilt * lean).reduce(min), lessThan(-0.12));
    expect(run.map((s) => s.tilt * lean).reduce(max), greaterThan(0.25));
    await waitFor(tester, damage, frames: 90);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the gulp: the water draws the pet up as the maw closes, the '
      'bubble swells round it, and it falls out with a hop', (tester) async {
    await startWith(tester, 'BUBBLES');
    await waitFor(tester, find.byType(LetterBubble));
    await advance(tester, 300);
    final pet = PetProbe(tester);
    final ground = pet.feet;

    final run = <PetSample>[];
    var blub = -1;
    for (var i = 0; i < 2000 && blub < 0; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      run.add(pet.sample);
      if (find.text('blub').evaluate().isNotEmpty) blub = run.length - 1;
    }
    expect(blub, greaterThan(0), reason: 'the gulp came');
    // Early on it stands on the seabed; drawn up a little as the gulp closes.
    expect(run.take(30).every((s) => (s.feet - ground).abs() < 1), isTrue);
    expect(run.sublist(0, blub).highest, lessThan(ground - 8));
    expect(petBubble(tester), lessThan(0.6), reason: 'swelling');

    run.addAll(await pet.track(150));
    // No jumps once the arena has stopped shaking: the pop is a fall, not a
    // drop out of the air.
    for (var i = blub + 25; i < run.length; i++) {
      expect((run[i].feet - run[i - 1].feet).abs(), lessThan(10),
          reason: 'frame $i');
    }
    // Floating in it.
    final floating = run[blub + 30];
    expect(floating.feet, closeTo(ground - 17, 5));
    // Then out of it, to the seabed, and up again with a hop.
    expect(run.sublist(blub + 25).hops(ground, by: 10), 2);
    expect(run.last.feet, closeTo(ground, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('net: the pet LEAPS and casts a net over each fish — the net '
      'opens in the air and settles on it — and lands crouched',
      (tester) async {
    await startWith(tester, 'NET');
    await waitFor(tester, find.byType(WordFish));
    await advance(tester, 400);
    final pet = PetProbe(tester);
    final ground = pet.feet;

    final said =
        sentences.firstWhere((s) => find.text(s.meaning).evaluate().isNotEmpty);
    Future<Offset> net(String token) async {
      final candidates = fishLabelled(token);
      for (var i = 0; i < candidates.evaluate().length; i++) {
        final w = tester.widget<WordFish>(candidates.at(i));
        if (w.state == FishState.plain) {
          final at = tester.getCenter(candidates.at(i));
          await tester.tap(candidates.at(i), warnIfMissed: false);
          await tester.pump();
          return at;
        }
      }
      fail('no fish for $token');
    }

    expect(find.byType(NetMesh), findsNothing);
    final first = await net(said.tokens.first);
    final run = <PetSample>[];
    var opening = false;
    for (var i = 0; i < 45; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      run.add(pet.sample);
      opening |= tester
          .widgetList<NetMesh>(find.byType(NetMesh))
          .any((m) => m.grow > 0 && m.grow < 1);
    }
    // Up on a real leap, arm back then swung over, and down crouched...
    expect(run.highest, lessThan(ground - 30));
    expect(run.lowestSquash, lessThan(0.9));
    final thrust =
        run.map((s) => s.tilt).reduce((a, b) => a.abs() > b.abs() ? a : b);
    final lean = thrust < 0 ? -1.0 : 1.0;
    expect(run.map((s) => s.tilt * lean).reduce(min), lessThan(-0.2));
    expect(run.map((s) => s.tilt * lean).reduce(max), greaterThan(0.3));
    // ...turned to the fish it threw at,
    if ((first.dx - pet.x).abs() > 12) {
      expect(run.first.facesLeft, first.dx < pet.x);
    }
    // ...and the net it threw opened out in the air, and lies over it.
    expect(opening, isTrue);
    await advance(tester, 400);
    expect(find.byType(NetMesh), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('net: the last fish netted, the pet LEANS BACK, digs in and '
      'hauls the net on its cords — three tugs, the fish dragged to it — then '
      'heaves, the fish burst and the spell leaves', (tester) async {
    await startWith(tester, 'NET');
    await waitFor(tester, find.byType(WordFish));
    await advance(tester, 400);
    final pet = PetProbe(tester);
    final ground = pet.feet;
    final home = pet.x;

    final said =
        sentences.firstWhere((s) => find.text(s.meaning).evaluate().isNotEmpty);
    for (final token in said.tokens) {
      final candidates = fishLabelled(token);
      var tapped = false;
      for (var i = 0; i < candidates.evaluate().length && !tapped; i++) {
        final w = tester.widget<WordFish>(candidates.at(i));
        if (w.state == FishState.plain) {
          await tester.tap(candidates.at(i), warnIfMissed: false);
          await tester.pump();
          tapped = true;
        }
      }
      expect(tapped, isTrue, reason: 'a fish for $token');
      await advance(tester, 450);
    }
    // The last cast has landed; nothing hauled yet, so no cords.
    final cords = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is NetRopesPainter);

    // Wait for the haul to begin: the cords appear, the pet leaning away.
    final haul = <PetSample>[];
    var fishAt = <Offset>[];
    final nearest = <double>[];
    var started = -1;
    for (var i = 0; i < 300 && find.byType(WordFish).evaluate().isNotEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      haul.add(pet.sample);
      if (cords.evaluate().isNotEmpty) {
        if (started < 0) started = haul.length - 1;
        fishAt = [
          for (final e in find.byType(WordFish).evaluate())
            tester.getCenter(find.byWidget(e.widget))
        ];
        final hands = Offset(pet.x, pet.head + 20);
        nearest.add(fishAt.map((p) => (p - hands).distance).reduce(min));
      }
    }
    expect(started, greaterThanOrEqualTo(0), reason: 'the cords came out');
    // The fish are dragged in: each tug brings them closer, and they end up
    // much nearer the pet than they began.
    expect(nearest.first - nearest.last, greaterThan(40));
    var closer = 0;
    for (var i = 1; i < nearest.length; i++) {
      if (nearest[i] < nearest[i - 1] - 0.5) closer++;
    }
    expect(closer, greaterThan(6));
    // The pet pulls: tipped away from the fish, back and forth in three tugs.
    final hauling = haul.sublist(started);
    final tips = hauling.map((s) => s.tilt).toList();
    final away = tips.reduce((a, b) => a.abs() > b.abs() ? a : b).sign;
    expect(tips.map((t) => t * away).reduce(max), greaterThan(0.4));
    var tugs = 0;
    for (var i = 1; i < tips.length - 1; i++) {
      final a = tips[i - 1] * away, b = tips[i] * away, c = tips[i + 1] * away;
      if (b > 0.45 && b >= a && b > c) tugs++;
    }
    expect(tugs, greaterThanOrEqualTo(3));
    // Digging in: it stays on the seabed and keeps its place while it does.
    expect(hauling.every((s) => s.feet > ground - 6), isTrue);
    expect(hauling.xSpread, lessThan(16));
    expect((hauling.last.x - home).abs(), lessThan(14));
    // The heave: the fish burst, and the spell leaves.
    expect(find.byType(WordFish), findsNothing);
    expect(cords, findsNothing);
    await waitFor(tester, damage, frames: 90);
    expect(tester.takeException(), isNull);
  });
}
