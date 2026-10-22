import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/components/boss_trial/angler_pieces.dart';
import 'package:mojilearner_flutter/components/boss_trial/arena_pieces.dart';
import 'package:mojilearner_flutter/components/boss_trial/hoothex_pieces.dart';
import 'package:mojilearner_flutter/components/boss_trial/mossback_pieces.dart';
import 'package:mojilearner_flutter/components/boss_trial/sphinx_pieces.dart';
import 'package:mojilearner_flutter/components/boss_trial/spell_pieces.dart';
import 'package:mojilearner_flutter/components/boss_trial/trial_skin.dart';
import 'package:mojilearner_flutter/components/boss_trial/trial_boss.dart';
import 'package:mojilearner_flutter/components/character_sprite.dart';
import 'package:mojilearner_flutter/constants/boss_trial_en_tr.dart';
import 'package:mojilearner_flutter/constants/boss_trial_sentences.dart';
import 'package:mojilearner_flutter/constants/boss_trial_words.dart';
import 'package:mojilearner_flutter/providers/language_provider.dart';
import 'package:mojilearner_flutter/providers/vocab_provider.dart';
import 'package:mojilearner_flutter/screens/boss_trial_screen.dart';
import 'package:mojilearner_flutter/utils/boss_trial.dart';
import 'package:mojilearner_flutter/utils/boss_trial_angler.dart';
import 'package:mojilearner_flutter/utils/boss_trial_sphinx.dart';
import 'package:mojilearner_flutter/utils/pet_recolor.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// A camera on the boss trials, for tuning their layout by eye: Mossback's
/// intro, a wave mid-fall and his Spells round; Amethyst's three openings,
/// the pet sealed in amethyst and its crystal spells; Mossback's and the
/// witch's openings under test; the witch's swoop, scroll, hex and brewing.
/// Same idea as `home_capture_test.dart`.
///
/// Skipped unless told where to write:
///
///     flutter test test/widget/boss_trial_capture_test.dart \
///         --dart-define=CAPTURE_DIR=<somewhere>
void main() {
  const dir = String.fromEnvironment('CAPTURE_DIR');

  testWidgets('draw the levels: the picker, a getaway, and a finale',
      (tester) async {
    await tester.runAsync(() async {
      final loader = FontLoader('PressStart2P')
        ..addFont(rootBundle.load('assets/fonts/PressStart2P-Regular.ttf'));
      await loader.load();
    });

    final character = MockCharacterProvider();
    final language = MockLanguageProvider();
    when(() => character.currentCharacterType).thenReturn('cat');
    when(() => character.currentCharacterAsset)
        .thenReturn('assets/svgs/cat.svg');
    when(() => character.colorSpecFor(any())).thenReturn(const PetColorSpec(
      bodyColor: '#959379',
      eyeMode: EyeMode.solid,
      eyeColor1: '#F4C430',
      eyeColor2: '#5AA0E0',
    ));
    when(() => character.equippedAccessoriesFor(any())).thenReturn(const []);
    when(() => language.targetLanguage)
        .thenReturn(const Language(code: 'es', name: 'Spanish'));
    when(() => language.nativeLanguage)
        .thenReturn(const Language(code: 'en', name: 'English'));

    Future<void> advance(int ms) async {
      for (var t = 0; t < ms; t += 16) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    Future<void> pumpBoss() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpApp(
        tester,
        BossTrialScreen(key: UniqueKey(), boss: TrialBosses.mossback),
        characterProvider: character,
        languageProvider: language,
        vocabProvider: VocabProvider(),
      );
      await advance(300);
    }

    final words = bossTrialStockWords(targetCode: 'es', nativeCode: 'en');
    final damage = find.textContaining(RegExp(r'^-\d+$'));

    /// Catches waves until [done] shows. After each hit lands, [afterHit]
    /// gets a look — the last one is the hit that ends it.
    Future<void> catchUntil(Finder done,
        {Future<void> Function()? afterHit}) async {
      bool over() => done.evaluate().isNotEmpty;
      TrialWord? shouted() {
        for (final w in words) {
          if (find.text(w.target).evaluate().isNotEmpty) return w;
        }
        return null;
      }

      for (var hits = 0; hits < 50 && !over(); hits++) {
        while (!over() &&
            (shouted() == null ||
                find.byType(RubbleTile).evaluate().isEmpty)) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        if (over()) break;
        await advance(100);
        await tester.tap(find.text(shouted()!.meaning));
        await tester.pump();
        while (!over() && damage.evaluate().isEmpty) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        await afterHit?.call();
      }
    }

    // The picker, on level 1 and on the finale.
    await pumpBoss();
    await _shoot(tester, '$dir/levels_intro.png');
    await tester.tap(find.text('FINALE'));
    await tester.pump();
    await _shoot(tester, '$dir/levels_intro_finale.png');

    // Level 1 won: it leaps away — caught mid-leap after the last hit — and
    // then the results.
    await pumpBoss();
    await tester.tap(find.text('START TRIAL'));
    await tester.pump();
    await catchUntil(find.text('IT GOT AWAY!'), afterHit: () async {
      // Deep in its crouch, powering up — then mid-leap.
      await advance(760);
      await _shoot(tester, '$dir/levels_powerup.png');
      await advance(420);
      await _shoot(tester, '$dir/levels_getaway.png');
    });
    await _shoot(tester, '$dir/levels_got_away.png');

    // The finale: round 1 won, the roar into round 2 over a ticked bar.
    await pumpBoss();
    await tester.tap(find.text('FINALE'));
    await tester.pump();
    await tester.tap(find.text('START TRIAL'));
    await tester.pump();
    await catchUntil(find.text('ROUND 2'));
    await advance(300);
    await _shoot(tester, '$dir/levels_finale_round2.png');

    await tester.pumpWidget(const SizedBox.shrink());
  }, skip: dir.isEmpty);

  testWidgets('draw the pet in the lanternmaw phases', (tester) async {
    await tester.runAsync(() async {
      final loader = FontLoader('PressStart2P')
        ..addFont(rootBundle.load('assets/fonts/PressStart2P-Regular.ttf'));
      await loader.load();
    });

    final character = MockCharacterProvider();
    final language = MockLanguageProvider();
    when(() => character.currentCharacterType).thenReturn('cat');
    when(() => character.currentCharacterAsset)
        .thenReturn('assets/svgs/cat.svg');
    when(() => character.colorSpecFor(any())).thenReturn(const PetColorSpec(
      bodyColor: '#959379',
      eyeMode: EyeMode.solid,
      eyeColor1: '#F4C430',
      eyeColor2: '#5AA0E0',
    ));
    when(() => character.equippedAccessoriesFor(any())).thenReturn(const []);
    when(() => language.targetLanguage)
        .thenReturn(const Language(code: 'es', name: 'Spanish'));
    when(() => language.nativeLanguage)
        .thenReturn(const Language(code: 'en', name: 'English'));

    Future<void> advance(int ms) async {
      for (var t = 0; t < ms; t += 16) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    Future<void> waitFor(Finder finder) async {
      for (var i = 0; i < 2000 && finder.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    Future<void> pumpAngler() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpApp(
        tester,
        BossTrialScreen(key: UniqueKey(), boss: TrialBosses.angler),
        characterProvider: character,
        languageProvider: language,
        vocabProvider: VocabProvider(),
      );
      await advance(100);
    }

    Future<void> startWith(String opening) async {
      await pumpAngler();
      await tester.tap(find.text(opening));
      await tester.pump();
      await tester.ensureVisible(find.text('START TRIAL'));
      await tester.tap(find.text('START TRIAL'));
      await tester.pump();
    }

    final words = bossTrialStockWords(targetCode: 'es', nativeCode: 'en');
    final sentences =
        bossTrialStockSentences(targetCode: 'es', nativeCode: 'en');
    TrialWord askedWord() =>
        words.firstWhere((w) => find.text(w.meaning).evaluate().isNotEmpty);
    TrialSentence askedSentence() =>
        sentences.firstWhere((s) => find.text(s.meaning).evaluate().isNotEmpty);
    Finder fish(String label) =>
        find.byWidgetPredicate((w) => w is WordFish && w.label == label);

    // Names shots by when they were taken, in milliseconds since [mark].
    var mark = 0;
    Future<void> frame(int ms, String name) async {
      await advance(ms - mark);
      mark = ms;
      await _shoot(tester, '$dir/$name.png');
    }

    // Lure: a wrong fish's cringe, then the dash, nip and spit at the hooked
    // fish.
    await startWith('LURE');
    await waitFor(find.byType(WordFish));
    await advance(300);
    final board = tester.widget<LureBoard>(find.byType(LureBoard));
    final wrong = find
        .byWidgetPredicate(
            (w) => w is WordFish && w.label != board.words[board.gap])
        .first;
    await tester.tap(wrong, warnIfMissed: false);
    await tester.pump();
    mark = 0;
    await frame(70, 'lan_lure_cringe');
    final right = fish(board.words[board.gap]);
    final petBox = find.byType(CharacterSprite).first;
    for (var i = 0;
        i < 200 &&
            right.evaluate().isNotEmpty &&
            (tester.getCenter(right).dx - tester.getCenter(petBox).dx).abs() <
                90;
        i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.tap(right, warnIfMissed: false);
    await tester.pump();
    mark = 0;
    for (final ms in [64, 144, 224, 304, 384, 464, 544, 624, 704, 784, 864, 960, 1100]) {
      await frame(ms, 'lan_lure_${ms.toString().padLeft(4, '0')}');
    }

    // Bubbles: the swim up to a letter's bubble (the bubble held where it was
    // picked), then the cast.
    await startWith('BUBBLES');
    await waitFor(find.byType(LetterBubble));
    await advance(500);
    final target = askedWord().target;
    var letters = 0;
    for (final letter in target.split('')) {
      final bubble = find
          .byWidgetPredicate((w) => w is LetterBubble && w.label == letter)
          .first;
      await tester.tap(bubble, warnIfMissed: false);
      await tester.pump();
      mark = 0;
      if (letters == 0) {
        for (final ms in [80, 200, 320, 440, 560, 680, 800, 1000, 1200]) {
          await frame(ms, 'lan_bubbles_1_${ms.toString().padLeft(4, '0')}');
        }
        await advance(300);
      } else {
        await advance(450);
      }
      letters++;
    }
    mark = 0;
    await frame(150, 'lan_bubbles_cast_back');
    await frame(450, 'lan_bubbles_cast');

    // The gulp: the pet drawn up as the maw closes, the bubble swelling round
    // it, floating, the pop, the fall, and the hop.
    await startWith('BUBBLES');
    await waitFor(find.byType(LetterBubble));
    var ticks = 0;
    var drifted = false;
    while (find.text('blub').evaluate().isEmpty && ticks < 3000) {
      await tester.pump(const Duration(milliseconds: 16));
      ticks++;
      if (!drifted &&
          tester.widget<ChargeBar>(find.byType(ChargeBar).first).charge >
              0.9) {
        drifted = true;
        await _shoot(tester, '$dir/lan_gulp_drift.png');
      }
    }
    mark = 0;
    await frame(50, 'lan_gulp_1_swell');
    await frame(130, 'lan_gulp_2_swell');
    await frame(250, 'lan_gulp_3_swell');
    await frame(700, 'lan_gulp_4_float');
    await frame(1500, 'lan_gulp_5_before_pop');
    await frame(1620, 'lan_gulp_6_pop');
    await frame(1700, 'lan_gulp_7_fall');
    await frame(1780, 'lan_gulp_8_fall');
    await frame(1860, 'lan_gulp_9_land');
    await frame(1990, 'lan_gulp_10_hop');
    await frame(2120, 'lan_gulp_11_hop');

    // Net: a leap and a cast for each fish, then the lean-back haul and the
    // burst.
    await startWith('NET');
    await waitFor(find.byType(WordFish));
    await advance(400);
    final said = askedSentence();
    var netted = 0;
    for (final token in said.tokens) {
      final candidates = fish(token);
      for (var i = 0; i < candidates.evaluate().length; i++) {
        if (tester.widget<WordFish>(candidates.at(i)).state ==
            FishState.plain) {
          await tester.tap(candidates.at(i), warnIfMissed: false);
          await tester.pump();
          break;
        }
      }
      netted++;
      mark = 0;
      if (netted == 1) {
        for (final ms in [64, 128, 192, 256, 320, 400, 500, 600]) {
          await frame(ms, 'lan_net_first_${ms.toString().padLeft(4, '0')}');
        }
      } else if (netted < said.tokens.length) {
        await advance(700);
      }
    }
    mark = 0;
    for (final ms in [100, 250, 400, 550, 700, 850, 1000, 1150, 1300, 1450, 1600, 1750, 1900, 2100]) {
      await frame(ms, 'lan_net_haul_${ms.toString().padLeft(4, '0')}');
    }

    await tester.pumpWidget(const SizedBox.shrink());
  }, skip: dir.isEmpty);

  testWidgets('draw the pet in the shoal', (tester) async {
    await tester.runAsync(() async {
      final loader = FontLoader('PressStart2P')
        ..addFont(rootBundle.load('assets/fonts/PressStart2P-Regular.ttf'));
      await loader.load();
    });

    final character = MockCharacterProvider();
    final language = MockLanguageProvider();
    when(() => character.currentCharacterType).thenReturn('cat');
    when(() => character.currentCharacterAsset)
        .thenReturn('assets/svgs/cat.svg');
    when(() => character.colorSpecFor(any())).thenReturn(const PetColorSpec(
      bodyColor: '#959379',
      eyeMode: EyeMode.solid,
      eyeColor1: '#F4C430',
      eyeColor2: '#5AA0E0',
    ));
    when(() => character.equippedAccessoriesFor(any())).thenReturn(const []);
    when(() => language.targetLanguage)
        .thenReturn(const Language(code: 'tr', name: 'Turkish'));
    when(() => language.nativeLanguage)
        .thenReturn(const Language(code: 'en', name: 'English'));

    Future<void> advance(int ms) async {
      for (var t = 0; t < ms; t += 16) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    await pumpApp(
      tester,
      BossTrialScreen(key: UniqueKey(), boss: TrialBosses.angler),
      characterProvider: character,
      languageProvider: language,
      vocabProvider: VocabProvider(),
    );
    await advance(100);
    await tester.tap(find.text('SHOAL'));
    await tester.pump();
    await tester.ensureVisible(find.text('START TRIAL'));
    await tester.tap(find.text('START TRIAL'));
    await tester.pump();
    for (var i = 0; i < 2000 && find.byType(WordFish).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await advance(300);

    final content = EnTrContent.of('tr', 'en')!;
    String groupOf(String w) => content.categories.entries
        .firstWhere((e) => e.value.any((x) => x.target == w))
        .key;
    final labels =
        tester.widgetList<WordFish>(find.byType(WordFish)).map((f) => f.label);
    final groups = labels.map(groupOf).toList();
    final stray = labels
        .firstWhere((l) => groups.where((g) => g == groupOf(l)).length == 1);
    final strayFish =
        find.byWidgetPredicate((w) => w is WordFish && w.label == stray);
    final petBox = find.byType(CharacterSprite).first;
    for (var i = 0;
        i < 150 &&
            (tester.getCenter(strayFish).dx - tester.getCenter(petBox).dx)
                    .abs() <
                90;
        i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.tap(strayFish, warnIfMissed: false);
    await tester.pump();
    var mark = 0;
    // The pet's dart and hit, the fish's swim at the boss and its ram, and the
    // rebound off the belly, spinning, till it is gone.
    for (final ms in [
      96, 192, 288, 384, 480, 560, 640, 720, 800, 864, 928, 992, 1056, 1136, //
      1216, 1296, 1376, 1456, 1600,
    ]) {
      await advance(ms - mark);
      mark = ms;
      await _shoot(tester, '$dir/lan_shoal_${ms.toString().padLeft(4, '0')}.png');
    }

    await tester.pumpWidget(const SizedBox.shrink());
  }, skip: dir.isEmpty);

  testWidgets('draw the pet in the sableth phases', (tester) async {
    await tester.runAsync(() async {
      final loader = FontLoader('PressStart2P')
        ..addFont(rootBundle.load('assets/fonts/PressStart2P-Regular.ttf'));
      await loader.load();
    });

    final character = MockCharacterProvider();
    final language = MockLanguageProvider();
    when(() => character.currentCharacterType).thenReturn('cat');
    when(() => character.currentCharacterAsset)
        .thenReturn('assets/svgs/cat.svg');
    when(() => character.colorSpecFor(any())).thenReturn(const PetColorSpec(
      bodyColor: '#959379',
      eyeMode: EyeMode.solid,
      eyeColor1: '#F4C430',
      eyeColor2: '#5AA0E0',
    ));
    when(() => character.equippedAccessoriesFor(any())).thenReturn(const []);
    // Sableth's content is English and Turkish.
    when(() => language.targetLanguage)
        .thenReturn(const Language(code: 'tr', name: 'Turkish'));
    when(() => language.nativeLanguage)
        .thenReturn(const Language(code: 'en', name: 'English'));
    final content = EnTrContent.of('tr', 'en')!;

    Future<void> advance(int ms) async {
      for (var t = 0; t < ms; t += 16) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    Future<void> waitFor(Finder finder) async {
      for (var i = 0; i < 4000 && finder.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    Future<void> startWith(String opening) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpApp(
        tester,
        BossTrialScreen(key: UniqueKey(), boss: TrialBosses.sphinx),
        characterProvider: character,
        languageProvider: language,
        vocabProvider: VocabProvider(),
      );
      await advance(100);
      await tester.tap(find.text(opening));
      await tester.pump();
      await tester.ensureVisible(find.text('START TRIAL'));
      await tester.tap(find.text('START TRIAL'));
      await tester.pump();
    }

    Finder tablet(String label) =>
        find.byWidgetPredicate((w) => w is SkinTile && w.label == label);
    String said() => tester.widget<TalkPanel>(find.byType(TalkPanel)).text;

    var mark = 0;
    Future<void> frame(int ms, String name) async {
      await advance(ms - mark);
      mark = ms;
      await _shoot(tester, '$dir/$name.png');
    }

    // Riddle: a wrong tablet rammed and cracked, then the right one stamped.
    await startWith('RIDDLE');
    await waitFor(find.byType(SkinTile));
    await advance(400);
    final riddle = content.riddles.firstWhere((r) => said().contains(r.question));
    await tester.tap(tablet(riddle.answers[1]));
    await tester.pump();
    mark = 0;
    for (final ms in [64, 144, 224, 304, 384, 464, 544, 640, 760, 900]) {
      await frame(ms, 'sab_riddle_ram_${ms.toString().padLeft(4, '0')}');
    }
    await advance(400);
    await tester.tap(tablet(riddle.answers.first));
    await tester.pump();
    mark = 0;
    for (final ms in [64, 144, 224, 304, 384, 464, 544, 624, 704, 784, 864, 960, 1100]) {
      await frame(ms, 'sab_riddle_stamp_${ms.toString().padLeft(4, '0')}');
    }

    // Door: the dial twirled, a wrong push bounced off; the right form, the
    // crouch and the shoulder charge.
    await startWith('DOOR');
    await waitFor(find.byType(SealedDoor));
    await advance(400);
    SealedDoor door() => tester.widget<SealedDoor>(find.byType(SealedDoor));
    final asked = content.doors.firstWhere((d) => d.base == door().base);
    await tester.tap(find.text(door().dial));
    await tester.pump();
    mark = 0;
    for (final ms in [32, 80, 128, 176, 224, 272, 340, 420]) {
      await frame(ms, 'sab_door_twirl_${ms.toString().padLeft(4, '0')}');
    }
    await advance(300);
    // The first push must be a wrong one.
    for (var i = 0; i < 3 && door().dial == asked.answer; i++) {
      await tester.tap(find.text(door().dial));
      await tester.pump();
      await advance(500);
    }
    await tester.tap(find.text('PUSH'));
    await tester.pump();
    mark = 0;
    for (final ms in [100, 250, 400, 550, 700, 900]) {
      await frame(ms, 'sab_door_bounce_${ms.toString().padLeft(4, '0')}');
    }
    for (var i = 0; i < 3 && door().dial != asked.answer; i++) {
      await tester.tap(find.text(door().dial));
      await tester.pump();
      await advance(500);
    }
    await advance(500);
    await tester.tap(find.text('PUSH'));
    await tester.pump();
    mark = 0;
    for (final ms in [200, 500, 800, 1000, 1080, 1160, 1250, 1360, 1500, 1700]) {
      await frame(ms, 'sab_door_charge_${ms.toString().padLeft(4, '0')}');
    }

    // Tablets: each carried to its slot, then the cast of the whole story.
    await startWith('TABLETS');
    await waitFor(find.byType(SkinTile));
    await advance(400);
    final story = content.stories
        .firstWhere((s) => find.text(s.lines.first).evaluate().isNotEmpty);
    var lifted = 0;
    for (final line in story.lines) {
      await tester.tap(tablet(line));
      await tester.pump();
      mark = 0;
      if (lifted == 0) {
        for (final ms in [64, 160, 260, 360, 460, 560, 660, 760, 860, 1000]) {
          await frame(ms, 'sab_tablets_1_${ms.toString().padLeft(4, '0')}');
        }
        await advance(300);
      } else if (lifted < story.lines.length - 1) {
        await advance(1200);
      }
      lifted++;
    }
    mark = 0;
    for (final ms in [200, 500, 800, 1100, 1300, 1450, 1600, 1800, 2000]) {
      await frame(ms, 'sab_tablets_cast_${ms.toString().padLeft(4, '0')}');
    }

    // Storm: the lean into the wind, then the howl.
    await startWith('STORM');
    await waitFor(find.byType(TalkPanel));
    await advance(500);
    await _shoot(tester, '$dir/sab_storm_lean.png');
    final stock = bossTrialStockWords(targetCode: 'tr', nativeCode: 'en');
    final target = stock.firstWhere((w) => w.meaning == said());
    final grid = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is SandGridPainter);
    final letters = tester
        .widgetList<Text>(find.descendant(of: grid, matching: find.byType(Text)))
        .map((t) => t.data!)
        .toList();
    final box = tester.getRect(grid);
    final cell = box.width / StormWave.cols;
    final word = BubbleWave.lettersOf(target.target)!;
    int? from, to;
    for (var y = 0; y < StormWave.rows && from == null; y++) {
      for (var x = 0; x < StormWave.cols && from == null; x++) {
        if (x + word.length <= StormWave.cols &&
            List.generate(word.length, (i) => letters[y * StormWave.cols + x + i])
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
        Offset((c % StormWave.cols + 0.5) * cell, (c ~/ StormWave.cols + 0.5) * cell);
    await tester.tapAt(centre(from!));
    await tester.pump();
    await tester.tapAt(centre(to!));
    await tester.pump();
    mark = 0;
    for (final ms in [64, 144, 224, 304, 400, 500, 600, 700, 800, 900, 1000, 1150, 1300]) {
      await frame(ms, 'sab_storm_howl_${ms.toString().padLeft(4, '0')}');
    }

    // The sand: heaped as the clock runs down, buried, struggling, out.
    await startWith('RIDDLE');
    await waitFor(find.byType(SkinTile));
    var ticks = 0;
    var heaped = false;
    while (find.text('buried').evaluate().isEmpty && ticks < 4000) {
      await tester.pump(const Duration(milliseconds: 16));
      ticks++;
      if (!heaped &&
          tester.widget<TalkPanel>(find.byType(TalkPanel)).clock > 0.92) {
        heaped = true;
        await _shoot(tester, '$dir/sab_sand_mound.png');
      }
    }
    mark = 0;
    await frame(60, 'sab_sand_1');
    await frame(150, 'sab_sand_2');
    await frame(300, 'sab_sand_3');
    await frame(800, 'sab_sand_4_buried');
    await frame(1250, 'sab_sand_5_struggle');
    await frame(1450, 'sab_sand_6_struggle');
    await frame(1620, 'sab_sand_7_out');
    await frame(1720, 'sab_sand_8_hop');
    await frame(1830, 'sab_sand_9_hop');

    await tester.pumpWidget(const SizedBox.shrink());
  }, skip: dir.isEmpty);

  testWidgets('draw the pet in the pyrewing phases', (tester) async {
    await tester.runAsync(() async {
      final loader = FontLoader('PressStart2P')
        ..addFont(rootBundle.load('assets/fonts/PressStart2P-Regular.ttf'));
      await loader.load();
    });

    final character = MockCharacterProvider();
    final language = MockLanguageProvider();
    when(() => character.currentCharacterType).thenReturn('cat');
    when(() => character.currentCharacterAsset)
        .thenReturn('assets/svgs/cat.svg');
    when(() => character.colorSpecFor(any())).thenReturn(const PetColorSpec(
      bodyColor: '#959379',
      eyeMode: EyeMode.solid,
      eyeColor1: '#F4C430',
      eyeColor2: '#5AA0E0',
    ));
    when(() => character.equippedAccessoriesFor(any())).thenReturn(const []);
    when(() => language.targetLanguage)
        .thenReturn(const Language(code: 'tr', name: 'Turkish'));
    when(() => language.nativeLanguage)
        .thenReturn(const Language(code: 'en', name: 'English'));
    final content = EnTrContent.of('tr', 'en')!;

    Future<void> advance(int ms) async {
      for (var t = 0; t < ms; t += 16) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    Future<void> waitFor(Finder finder) async {
      for (var i = 0; i < 4000 && finder.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    Future<void> startWith(String opening) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpApp(
        tester,
        BossTrialScreen(key: UniqueKey(), boss: TrialBosses.dragon),
        characterProvider: character,
        languageProvider: language,
        vocabProvider: VocabProvider(),
      );
      await advance(100);
      await tester.tap(find.text(opening));
      await tester.pump();
      await tester.ensureVisible(find.text('START TRIAL'));
      await tester.tap(find.text('START TRIAL'));
      await tester.pump();
    }

    Finder tablet(String label) =>
        find.byWidgetPredicate((w) => w is SkinTile && w.label == label);
    String said() => tester.widget<TalkPanel>(find.byType(TalkPanel)).text;

    var mark = 0;
    Future<void> frame(int ms, String name) async {
      await advance(ms - mark);
      mark = ms;
      await _shoot(tester, '$dir/$name.png');
    }

    // Parley: it keeps back; a wrong reply shaken off, a turn answered with a
    // nod and a step, and the last turn's bow and big spell.
    await startWith('PARLEY');
    await waitFor(find.byType(SkinTile));
    await advance(900);
    final script = content.parleys.firstWhere((p) => said() == p.turns.first.line);
    await _shoot(tester, '$dir/pyr_parley_start.png');
    await tester.tap(tablet(script.turns.first.replies[1]));
    await tester.pump();
    mark = 0;
    for (final ms in [80, 160, 240, 320, 400, 480]) {
      await frame(ms, 'pyr_parley_no_${ms.toString().padLeft(4, '0')}');
    }
    await advance(300);
    await tester.tap(tablet(script.turns.first.replies.first));
    await tester.pump();
    mark = 0;
    for (final ms in [80, 160, 240, 320, 400, 560, 720, 900, 1100]) {
      await frame(ms, 'pyr_parley_step_${ms.toString().padLeft(4, '0')}');
    }
    await advance(800);
    for (final turn in script.turns.skip(1)) {
      await tester.tap(tablet(turn.replies.first));
      await tester.pump();
      if (turn != script.turns.last) await advance(2000);
    }
    mark = 0;
    for (final ms in [200, 400, 700, 900, 1100, 1300, 1500, 1700, 1850, 2000, 2200]) {
      await frame(ms, 'pyr_parley_bow_${ms.toString().padLeft(4, '0')}');
    }

    // Flame link: the lob and the bridge.
    await startWith('LINK');
    await waitFor(find.byType(SkinTile));
    await advance(400);
    final item =
        content.links.firstWhere((l) => find.text(l.left).evaluate().isNotEmpty);
    await tester.tap(tablet(item.links.first), warnIfMissed: false);
    await tester.pump();
    mark = 0;
    for (final ms in [150, 300, 450, 600, 700, 780, 860, 960, 1100, 1250, 1350, 1450, 1550, 1700, 1850]) {
      await frame(ms, 'pyr_link_${ms.toString().padLeft(4, '0')}');
    }

    // Embers: the wrong one flares in its face; the right one is caught and
    // flung.
    await startWith('EMBERS');
    await waitFor(find.byType(SkinTile));
    await advance(400);
    final ember = content.paraphrases.firstWhere((p) => said() == p.line);
    await tester.tap(tablet(ember.options[1]), warnIfMissed: false);
    await tester.pump();
    mark = 0;
    for (final ms in [80, 200, 320, 440, 560, 700, 900, 1200]) {
      await frame(ms, 'pyr_embers_wrong_${ms.toString().padLeft(4, '0')}');
    }
    await advance(1000);
    await tester.tap(tablet(ember.options.first), warnIfMissed: false);
    await tester.pump();
    mark = 0;
    for (final ms in [100, 220, 340, 460, 580, 700, 820, 940, 1060, 1200]) {
      await frame(ms, 'pyr_embers_catch_${ms.toString().padLeft(4, '0')}');
    }

    // Hoard: the first coin lifted, a wrong pair, a matched pair carried.
    await startWith('HOARD');
    final coinTiles = find
        .byWidgetPredicate((w) => w is SkinTile && w.shape == TileShape.coin);
    await waitFor(coinTiles);
    await advance(400);
    await _shoot(tester, '$dir/pyr_hoard_asleep.png');
    final coins =
        tester.widgetList<SkinTile>(coinTiles).map((c) => c.label).toList();
    final phrases = content.phrases
        .where((p) => coins.contains(p.first) && coins.contains(p.second))
        .toList();
    final firsts = [
      for (var i = 0; i < coins.length; i++)
        if (phrases.any((p) => p.first == coins[i])) i,
    ];
    await tester.tap(coinTiles.at(firsts[0]));
    await tester.pump();
    mark = 0;
    for (final ms in [80, 160, 260, 400]) {
      await frame(ms, 'pyr_hoard_take_${ms.toString().padLeft(4, '0')}');
    }
    await advance(300);
    await tester.tap(coinTiles.at(firsts[1]));
    await tester.pump();
    mark = 0;
    for (final ms in [80, 200, 400, 700]) {
      await frame(ms, 'pyr_hoard_wrong_${ms.toString().padLeft(4, '0')}');
    }
    await advance(600);
    final pair = phrases.first;
    await tester.tap(coinTiles.at(coins.indexOf(pair.first)));
    await tester.pump();
    await advance(500);
    await tester.tap(coinTiles.at(coins.indexOf(pair.second)));
    await tester.pump();
    mark = 0;
    for (final ms in [100, 250, 400, 550, 700, 850, 1000, 1150, 1300, 1450, 1600, 1800]) {
      await frame(ms, 'pyr_hoard_match_${ms.toString().padLeft(4, '0')}');
    }

    // The ash: creeping as the clock runs down, taking hold, shaken off.
    await startWith('PARLEY');
    await waitFor(find.byType(SkinTile));
    var ticks = 0;
    var warm = false;
    while (find.text('scorched').evaluate().isEmpty && ticks < 4000) {
      await tester.pump(const Duration(milliseconds: 16));
      ticks++;
      if (!warm && tester.widget<TalkPanel>(find.byType(TalkPanel)).clock > 0.92) {
        warm = true;
        await _shoot(tester, '$dir/pyr_ash_creep.png');
      }
    }
    mark = 0;
    await frame(60, 'pyr_ash_1');
    await frame(150, 'pyr_ash_2');
    await frame(300, 'pyr_ash_3');
    await frame(800, 'pyr_ash_4_scorched');
    await frame(1250, 'pyr_ash_5_shake');
    await frame(1450, 'pyr_ash_6_shake');
    await frame(1620, 'pyr_ash_7_clean');
    await frame(1720, 'pyr_ash_8_hop');
    await frame(1830, 'pyr_ash_9_hop');

    await tester.pumpWidget(const SizedBox.shrink());
  }, skip: dir.isEmpty);

  testWidgets('draw the openers under test for mossback and the witch',
      (tester) async {
    await tester.runAsync(() async {
      final loader = FontLoader('PressStart2P')
        ..addFont(rootBundle.load('assets/fonts/PressStart2P-Regular.ttf'));
      await loader.load();
    });

    final character = MockCharacterProvider();
    final language = MockLanguageProvider();
    when(() => character.currentCharacterType).thenReturn('cat');
    when(() => character.currentCharacterAsset)
        .thenReturn('assets/svgs/cat.svg');
    when(() => character.colorSpecFor(any())).thenReturn(const PetColorSpec(
      bodyColor: '#959379',
      eyeMode: EyeMode.solid,
      eyeColor1: '#F4C430',
      eyeColor2: '#5AA0E0',
    ));
    when(() => character.equippedAccessoriesFor(any())).thenReturn(const []);
    when(() => language.targetLanguage)
        .thenReturn(const Language(code: 'es', name: 'Spanish'));
    when(() => language.nativeLanguage)
        .thenReturn(const Language(code: 'en', name: 'English'));

    Future<void> advance(int ms) async {
      for (var t = 0; t < ms; t += 16) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    Future<void> waitFor(Finder finder) async {
      for (var i = 0; i < 1200 && finder.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    Future<void> startWith(TrialBoss boss, String opening) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpApp(
        tester,
        BossTrialScreen(key: UniqueKey(), boss: boss),
        characterProvider: character,
        languageProvider: language,
        vocabProvider: VocabProvider(),
      );
      await advance(100);
      await tester.tap(find.text(opening));
      await tester.pump();
      await tester.ensureVisible(find.text('START TRIAL'));
      await tester.tap(find.text('START TRIAL'));
      await tester.pump();
    }

    final words = bossTrialStockWords(targetCode: 'es', nativeCode: 'en');
    String meaningOfShout() => words
        .firstWhere((w) => find.text(w.target).evaluate().isNotEmpty)
        .meaning;

    // Mossback's shell game: showing, shuffling, and a pick.
    await startWith(TrialBosses.mossback, 'SHELLS');
    await waitFor(find.byType(ShellSlab));
    await advance(500);
    await _shoot(tester, '$dir/moss_shells_reveal.png');
    final answer = meaningOfShout();
    await advance(2400);
    await _shoot(tester, '$dir/moss_shells_shuffle.png');
    await advance(3000);
    await tester.tap(find.widgetWithText(ShellSlab, answer));
    await tester.pump();
    // The pet stays put: the cup lifts and its stone goes up at the boss.
    await advance(150);
    await _shoot(tester, '$dir/moss_shells_pick.png');

    // A wrong cup: its stone comes down on the pet instead.
    await startWith(TrialBosses.mossback, 'SHELLS');
    await waitFor(find.byType(ShellSlab));
    await advance(500);
    final rightOne = meaningOfShout();
    final wrongOne = tester
        .widgetList<ShellSlab>(find.byType(ShellSlab))
        .firstWhere((s) => s.label != rightOne)
        .label;
    await advance(5400);
    await tester.tap(find.widgetWithText(ShellSlab, wrongOne));
    await tester.pump();
    await advance(180);
    await _shoot(tester, '$dir/moss_shells_wrong_flying.png');
    await advance(280);
    await _shoot(tester, '$dir/moss_shells_wrong.png');

    // Pebble Pop, a few pops in, then a pounce on the right pebble.
    await startWith(TrialBosses.mossback, 'PEBBLES');
    await waitFor(find.byType(PebbleTile));
    await advance(1300);
    await _shoot(tester, '$dir/moss_pebbles.png');
    final bonkWord = words
        .firstWhere((w) => find.text(w.meaning).evaluate().isNotEmpty)
        .target;
    await waitFor(find.widgetWithText(PebbleTile, bonkWord));
    await advance(100);
    await tester.tap(find.widgetWithText(PebbleTile, bonkWord));
    await tester.pump();
    // In the air at once, and onto the pebble.
    await advance(130);
    await _shoot(tester, '$dir/moss_pebbles_jump.png');
    await advance(190);
    await _shoot(tester, '$dir/moss_pebbles_pounce.png');

    // Stepping Stones: the stones rising out of the river as the boss jumps,
    // on the bank, then a hop out.
    final liveStone = find.byWidgetPredicate(
        (w) => w is SteppingStone && w.onTapDown != null);
    await startWith(TrialBosses.mossback, 'STONES');
    await waitFor(find.byType(SteppingStone));
    await advance(350);
    await _shoot(tester, '$dir/moss_stones_rising.png');
    await waitFor(liveStone);
    await advance(600);
    await _shoot(tester, '$dir/moss_stones.png');
    final meaning = meaningOfShout();
    await tester.tap(find.byWidgetPredicate((w) =>
        w is SteppingStone && w.label == meaning && w.onTapDown != null));
    await tester.pump();
    await advance(1500);
    await _shoot(tester, '$dir/moss_stones_hop.png');

    // A wrong stone: the pet going under, then back on the bank.
    await startWith(TrialBosses.mossback, 'STONES');
    await waitFor(liveStone);
    await advance(300);
    final right = meaningOfShout();
    final wrong = tester
        .widgetList<SteppingStone>(liveStone)
        .firstWhere((s) => s.label != right)
        .label;
    await tester.tap(find.byWidgetPredicate((w) =>
        w is SteppingStone && w.label == wrong && w.onTapDown != null));
    await advance(200);
    await _shoot(tester, '$dir/moss_stones_sinking_early.png');
    await advance(250);
    await _shoot(tester, '$dir/moss_stones_sinking.png');
    await advance(700);
    await _shoot(tester, '$dir/moss_stones_comeback.png');

    // The headbutt: crouched on the last stone facing the boss, then tipped
    // over toward it at the top of the leap.
    await startWith(TrialBosses.mossback, 'STONES');
    await waitFor(liveStone);
    await advance(300);
    for (var row = 0; row < 4; row++) {
      final hop = meaningOfShout();
      await tester.tap(find.byWidgetPredicate((w) =>
          w is SteppingStone && w.label == hop && w.onTapDown != null));
      await tester.pump();
      await advance(250);
    }
    await advance(450);
    await _shoot(tester, '$dir/moss_stones_crouch.png');
    await advance(600);
    await _shoot(tester, '$dir/moss_stones_butt.png');

    // The witch's clones, her tangle and the chase.
    await startWith(TrialBosses.witch, 'CLONES');
    await waitFor(find.byType(OwlBubble));
    await advance(1500);
    await _shoot(tester, '$dir/witch_clones.png');

    await startWith(TrialBosses.witch, 'TANGLE');
    await waitFor(find.byType(Cauldron));
    await advance(900);
    await _shoot(tester, '$dir/witch_tangle.png');

    await startWith(TrialBosses.witch, 'CHASE');
    await waitFor(find.byType(WordGate));
    await advance(1800);
    await _shoot(tester, '$dir/witch_chase.png');

    await tester.pumpWidget(const SizedBox.shrink());
  }, skip: dir.isEmpty);

  testWidgets('draw the English and Turkish trials', (tester) async {
    await tester.runAsync(() async {
      final loader = FontLoader('PressStart2P')
        ..addFont(rootBundle.load('assets/fonts/PressStart2P-Regular.ttf'));
      await loader.load();
    });

    final character = MockCharacterProvider();
    final language = MockLanguageProvider();
    when(() => character.currentCharacterType).thenReturn('cat');
    when(() => character.currentCharacterAsset)
        .thenReturn('assets/svgs/cat.svg');
    when(() => character.colorSpecFor(any())).thenReturn(const PetColorSpec(
      bodyColor: '#959379',
      eyeMode: EyeMode.solid,
      eyeColor1: '#F4C430',
      eyeColor2: '#5AA0E0',
    ));
    when(() => character.equippedAccessoriesFor(any())).thenReturn(const []);
    // Learning Turkish, with English meanings: the owner's pair.
    when(() => language.targetLanguage)
        .thenReturn(const Language(code: 'tr', name: 'Turkish'));
    when(() => language.nativeLanguage)
        .thenReturn(const Language(code: 'en', name: 'English'));

    Future<void> advance(int ms) async {
      for (var t = 0; t < ms; t += 16) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    Future<void> waitFor(Finder finder) async {
      for (var i = 0; i < 2000; i++) {
        if (finder.evaluate().isNotEmpty) return;
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    for (final (device, size) in [
      ('iphone15', const Size(393, 759)),
      ('iphonese', const Size(375, 647)),
    ]) {
      Future<void> startWith(TrialBoss boss, String opening) async {
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpApp(
          tester,
          BossTrialScreen(key: UniqueKey(), boss: boss),
          characterProvider: character,
          languageProvider: language,
          vocabProvider: VocabProvider(),
          surfaceSize: size,
        );
        await advance(100);
        await tester.tap(find.text(opening));
        await tester.pump();
        await tester.ensureVisible(find.text('START TRIAL'));
        await tester.tap(find.text('START TRIAL'));
        await tester.pump();
      }

      final prefix = '$dir/entr_$device';

      await startWith(TrialBosses.angler, 'SHOAL');
      await waitFor(find.byType(WordFish));
      await advance(900);
      await _shoot(tester, '${prefix}_shoal.png');

      for (final (boss, opening, piece) in [
        (TrialBosses.sphinx, 'RIDDLE', find.byType(SkinTile)),
        (TrialBosses.sphinx, 'DOOR', find.byType(SealedDoor)),
        (TrialBosses.sphinx, 'TABLETS', find.byType(SkinTile)),
        (TrialBosses.sphinx, 'STORM', find.byType(TalkPanel)),
        (TrialBosses.dragon, 'PARLEY', find.byType(SkinTile)),
        (TrialBosses.dragon, 'LINK', find.byType(SkinTile)),
        (TrialBosses.dragon, 'EMBERS', find.byType(SkinTile)),
        (TrialBosses.dragon, 'HOARD', find.byType(SkinTile)),
        (TrialBosses.amethyst, 'VEIN', find.byType(SkinTile)),
        (TrialBosses.angler, 'NET', find.byType(WordFish)),
        (TrialBosses.mossback, 'CATCH', find.byType(RubbleTile)),
        (TrialBosses.witch, 'CLONES', find.byType(OwlBubble)),
      ]) {
        await startWith(boss, opening);
        await waitFor(piece);
        await advance(700);
        await _shoot(tester, '${prefix}_${opening.toLowerCase()}.png');
      }

      // A timeout on each boss: the sphinx's sand, the dragon's fire.
      await startWith(TrialBosses.sphinx, 'TABLETS');
      await waitFor(find.text('buried'));
      await advance(200);
      await _shoot(tester, '${prefix}_buried.png');
      await startWith(TrialBosses.dragon, 'LINK');
      await waitFor(find.text('scorched'));
      await advance(200);
      await _shoot(tester, '${prefix}_scorched.png');

      // Their intros, and every boss's Spells round in its own look.
      for (final (boss, name) in [
        (TrialBosses.mossback, 'mossback'),
        (TrialBosses.amethyst, 'amethyst'),
        (TrialBosses.witch, 'witch'),
        (TrialBosses.angler, 'angler'),
        (TrialBosses.sphinx, 'sphinx'),
        (TrialBosses.dragon, 'dragon'),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpApp(
          tester,
          BossTrialScreen(key: UniqueKey(), boss: boss),
          characterProvider: character,
          languageProvider: language,
          vocabProvider: VocabProvider(),
          surfaceSize: size,
        );
        await advance(300);
        await _shoot(tester, '${prefix}_${name}_intro.png');
      }
    }

    await tester.pumpWidget(const SizedBox.shrink());
  }, skip: dir.isEmpty);
}

Future<void> _shoot(WidgetTester tester, String path) async {
  await tester.runAsync(() async {
    final repaint =
        _firstBoundary(tester.binding.rootElement!.findRenderObject()!)!;
    final image = await repaint.toImage(pixelRatio: 2);
    final png = await image.toByteData(format: ImageByteFormat.png);
    File(path).writeAsBytesSync(png!.buffer.asUint8List());
  });
}

RenderRepaintBoundary? _firstBoundary(RenderObject node) {
  if (node is RenderRepaintBoundary) return node;
  RenderRepaintBoundary? found;
  node.visitChildren((child) {
    found ??= _firstBoundary(child);
  });
  return found;
}
