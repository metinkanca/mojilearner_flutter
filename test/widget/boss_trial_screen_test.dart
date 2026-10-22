import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/character_sprite.dart';
import 'package:mojilearner_flutter/constants/boss_trial_words.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/screens/boss_trial_screen.dart';
import 'package:mojilearner_flutter/utils/boss_trial.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCharacterProvider mockCharacter;
  late MockLanguageProvider mockLanguage;
  late List<TrialWord> stock;

  void learning(String target, String native) {
    when(() => mockLanguage.targetLanguage)
        .thenReturn(Language(code: target, name: target));
    when(() => mockLanguage.nativeLanguage)
        .thenReturn(Language(code: native, name: native));
    stock = bossTrialStockWords(targetCode: target, nativeCode: native);
  }

  setUp(() {
    mockCharacter = MockCharacterProvider();
    mockLanguage = MockLanguageProvider();
    when(() => mockCharacter.currentCharacterType).thenReturn('cat');
    learning('es', 'en');
  });

  // Never loaded from storage: awaiting SecureStorage under testWidgets'
  // FakeAsync deadlocks. See quiz_screen_srs_test.
  Future<void> pumpTrial(WidgetTester tester) async {
    await pumpApp(
      tester,
      const BossTrialScreen(),
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

  /// The word the boss shouted, read off the speech bubble.
  List<TrialWord> shouted() =>
      stock.where((w) => find.text(w.target).evaluate().isNotEmpty).toList();

  /// Rubble currently falling, read off its meanings.
  List<TrialWord> rubble() =>
      stock.where((w) => find.text(w.meaning).evaluate().isNotEmpty).toList();

  Future<void> waitForRubble(WidgetTester tester) async {
    for (var i = 0; i < 400; i++) {
      if (rubble().length == BossTrialRules.wordsPerWave) return;
      await tester.pump(const Duration(milliseconds: 16));
    }
    fail('no rubble fell');
  }

  Future<void> start(WidgetTester tester) async {
    await tester.tap(find.text('START TRIAL'));
    await tester.pump();
  }

  testWidgets('opens on the intro, topped up with test words', (tester) async {
    await pumpTrial(tester);

    expect(find.text('Mossback'), findsOneWidget);
    expect(find.text('12 WORDS · 0 YOURS · 12 TEST'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the boss jumps and shouts before any rubble falls',
      (tester) async {
    await pumpTrial(tester);
    await start(tester);

    // The gap, then partway up the jump: nothing to pick yet.
    await advance(tester, 700);
    expect(rubble(), isEmpty);

    await waitForRubble(tester);
    expect(shouted(), hasLength(1));
    expect(rubble(), hasLength(BossTrialRules.wordsPerWave));
    expect(rubble(), contains(shouted().single));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shouts in the language being learned, rubble in the player\'s',
      (tester) async {
    learning('en', 'tr');
    await pumpTrial(tester);
    expect(find.text('START TRIAL'), findsOneWidget);

    await start(tester);
    await waitForRubble(tester);

    final word = shouted().single;
    expect(find.text(word.target), findsOneWidget); // e.g. "dog"
    expect(find.text(word.meaning), findsOneWidget); // e.g. "köpek"
    expect(tester.takeException(), isNull);
  });

  testWidgets('the right piece is thrown back and hits on impact',
      (tester) async {
    await pumpTrial(tester);
    await start(tester);
    await waitForRubble(tester);

    await tester.tap(find.text(shouted().single.meaning));
    await tester.pump();
    // The pet running under it, catching it, winding up: nothing has hit the
    // boss yet.
    await advance(tester, 700);
    expect(find.text('x0'), findsOneWidget);

    // Then it is thrown, and lands.
    for (var i = 0; i < 200 && find.text('x1').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text('x1'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^-\d+$')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // ---- the pet's body: Catch -----------------------------------------------

  /// How far the pet is tipped over (radians, clockwise), how squashed it is,
  /// and whether it is turned to face left.
  double tiltNow(WidgetTester tester) {
    final m = tester
        .widget<Transform>(find.byKey(const ValueKey('pet-tilt')))
        .transform
        .storage;
    return atan2(m[1], m[0]);
  }

  double squashNow(WidgetTester tester) => tester
      .widget<Transform>(find.byKey(const ValueKey('pet-squash')))
      .transform
      .storage[5];

  bool facesLeft(WidgetTester tester) => tester
      .widget<Transform>(find.byKey(const ValueKey('pet-flip')))
      .transform
      .storage[0] < 0;

  testWidgets('catch: the pet runs under the piece, winds up leaning back and '
      'throws leaning forward', (tester) async {
    await pumpTrial(tester);
    await start(tester);
    await waitForRubble(tester);

    final pet = find.byType(CharacterSprite).first;
    final home = tester.getRect(pet).center.dx;
    final meaning = shouted().single.meaning;
    final lane = tester.getCenter(find.text(meaning)).dx;
    // The boss stands in the middle: from a lane left of it, it is to the
    // right, and the pet faces right.
    final bossRight = lane < home;
    await tester.tap(find.text(meaning));
    await tester.pump();

    // Running: facing the way it runs, not there yet.
    await advance(tester, 64);
    if ((lane - home).abs() > 1) {
      expect(facesLeft(tester), lane < home, reason: 'running to $lane');
      final x = tester.getRect(pet).center.dx;
      expect((x - home).abs(), greaterThan(1));
      expect((x - lane).abs(), greaterThan(1), reason: 'it must not snap there');
    }

    // Every other piece is plunging: still there, and lower a moment later...
    final others = rubble();
    expect(others, hasLength(BossTrialRules.wordsPerWave - 1));
    expect(others.map((w) => w.meaning), isNot(contains(meaning)));
    final before = tester.getCenter(find.text(others.first.meaning)).dy;
    await advance(tester, 96);
    final after = tester.getCenter(find.text(others.first.meaning)).dy;
    expect(after, greaterThan(before + 10), reason: 'it falls, and speeds up');

    // Caught, wound up, thrown: tipped back, then forward, toward the boss.
    final tilts = <double>[];
    final squashes = <double>[];
    final faces = <bool>[];
    final crumbled = <bool>[];
    for (var i = 0; i < 125; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      tilts.add(tiltNow(tester));
      squashes.add(squashNow(tester));
      faces.add(facesLeft(tester));
      crumbled.add(rubble().isEmpty);
    }
    final lean = bossRight ? 1.0 : -1.0;
    final toward = [for (final a in tilts) a * lean];
    final back = toward.reduce(min);
    final forward = toward.reduce(max);
    expect(back, lessThan(-0.2), reason: 'it leans away to wind up');
    expect(forward, greaterThan(0.25), reason: 'then snaps toward the boss');
    expect(toward.indexOf(back), lessThan(toward.indexOf(forward)));
    // The picked piece squishes it as it lands, and the others crumble at the
    // same moment, on the ground.
    expect(squashes.reduce(min), lessThan(0.6), reason: 'the stone squishes it');
    final squished = squashes.indexWhere((s) => s < 0.75);
    final gone = crumbled.indexOf(true);
    expect(gone, greaterThanOrEqualTo(0), reason: 'the others crumbled');
    expect((gone - squished).abs(), lessThanOrEqualTo(8));
    // Held down for a beat before it gets out from under.
    expect(squashes.where((s) => s < 0.75).length * 16, greaterThan(150));
    // Facing the boss for the throw, whichever way it ran to get there.
    expect(faces[toward.indexOf(forward)], !bossRight);

    // Then it is back in the middle, standing as its art is drawn.
    await advance(tester, 2500);
    expect(tester.getRect(pet).center.dx, closeTo(home, 6));
    expect(facesLeft(tester), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catch: a wrong piece flattens the pet, which springs back up',
      (tester) async {
    await pumpTrial(tester);
    await start(tester);
    await waitForRubble(tester);

    final pet = find.byType(CharacterSprite).first;
    final asked = shouted().single;
    final wrong = rubble().firstWhere((w) => w != asked);
    final lane = tester.getCenter(find.text(wrong.meaning)).dx;
    await tester.tap(find.text(wrong.meaning));
    await tester.pump();

    // It runs for the piece it picked, and is pressed flat under it.
    final squashes = <double>[];
    final feet = <double>[];
    final xs = <double>[];
    for (var i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      squashes.add(squashNow(tester));
      final box = tester.getRect(pet);
      feet.add(box.bottom - box.height * 0.1);
      xs.add(box.center.dx);
    }
    final flattest = squashes.indexOf(squashes.reduce(min));
    expect(squashes[flattest], closeTo(0.5, 0.06));
    // (The hurt shake it takes as it is hit moves it a few pixels.)
    expect(xs[flattest], closeTo(lane, 6), reason: 'under the piece it picked');

    // Held flat for a good half second, not a blink...
    final flat = squashes.where((s) => s < 0.6).length;
    expect(flat * 16, greaterThan(400));

    // ...then up with a small hop of its own.
    final ground = feet.reduce(max);
    final flatEnds = squashes.lastIndexWhere((s) => s < 0.6);
    expect(feet.skip(flatEnds).take(30).reduce(min), lessThan(ground - 20));
    expect(tester.takeException(), isNull);
  });

  testWidgets('rubble left to land costs only the combo', (tester) async {
    await pumpTrial(tester);
    await start(tester);
    await waitForRubble(tester);

    await advance(tester, 5200);

    expect(find.text('too slow'), findsOneWidget);
    expect(find.text('x0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('winning the finale\'s round 1 brings the roar into round 2',
      (tester) async {
    await pumpTrial(tester);
    await tester.tap(find.text('FINALE'));
    await tester.pump();
    await start(tester);

    for (var hits = 0; hits < 50; hits++) {
      await waitForRubble(tester);
      await tester.tap(find.text(shouted().single.meaning));
      await tester.pump();
      // The pet's run, catch, wind-up and throw, the impact, the gap, and the
      // roar's banner at the top of its jump.
      for (var i = 0; i < 320; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (find.text('ROUND 2').evaluate().isNotEmpty) break;
      }
      if (find.text('ROUND 2').evaluate().isNotEmpty) break;
    }
    expect(find.text('ROUND 2'), findsOneWidget);
    // Under it, the opening the round is fought with: the next level's.
    expect(find.text('SHELLS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('winning a level before the finale: it gets away',
      (tester) async {
    await pumpTrial(tester);
    expect(find.text('LEVEL 1 · CATCH'), findsOneWidget);
    await start(tester);

    for (var hits = 0; hits < 50; hits++) {
      if (find.text('IT GOT AWAY!').evaluate().isNotEmpty) break;
      await waitForRubble(tester);
      await tester.tap(find.text(shouted().single.meaning));
      await tester.pump();
      for (var i = 0; i < 320; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (find.text('IT GOT AWAY!').evaluate().isNotEmpty) break;
      }
    }
    expect(find.text('IT GOT AWAY!'), findsOneWidget);
    expect(find.text('ROUND 2'), findsNothing,
        reason: 'a level is its one opening, no Spells round');
    expect(find.textContaining('at level 5 it is beaten for good'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('three wrong pieces end the trial and list the words',
      (tester) async {
    await pumpTrial(tester);
    await start(tester);

    for (var i = 0; i < BossTrialRules.maxHearts; i++) {
      await waitForRubble(tester);
      final asked = shouted().single;
      final wrong = rubble().firstWhere((w) => w != asked);
      await tester.tap(find.text(wrong.meaning));
      await tester.pump();
      await advance(tester, 100);
    }
    // The pet runs under the last one and is flattened before it ends.
    await advance(tester, 2400);

    expect(find.text('MOSSBACK HELD ITS GROUND'), findsOneWidget);
    expect(find.text('WORDS TO PRACTISE'), findsOneWidget);
    expect(find.text('TRY AGAIN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
