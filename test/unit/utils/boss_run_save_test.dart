import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/utils/boss_run_save.dart';
import 'package:mojilearner_flutter/utils/boss_trial.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  const word = TrialWord(target: 'gato', meaning: 'cat', reading: null);
  const sentence = TrialSentence(
    tokens: ['yo', 'leo'],
    target: 'yo leo',
    meaning: 'I read',
  );

  BossRunSave saveOf({
    bool inThrow = false,
    TrialRun? run,
    String boss = 'mossback',
    int step = 2,
  }) =>
      BossRunSave(
        bossId: boss,
        step: step,
        round: 1,
        inThrow: inThrow,
        languageCode: 'es',
        nativeCode: 'en',
        run: run ??
            const TrialRun(
              hearts: 2,
              patience: 61,
              combo: 3,
              bestCombo: 4,
              caught: 7,
              broken: 1,
              letSlip: 2,
              endsAt: 20,
              last: false,
              missed: [word],
              missedSentences: [sentence],
            ),
      );

  group('TrialRun.leftMidThrow', () {
    test('costs a heart and the streak, and counts the throw as landed', () {
      const run = TrialRun(hearts: 3, combo: 5, letSlip: 1);
      final left = run.leftMidThrow();
      expect(left.hearts, 2);
      expect(left.combo, 0);
      expect(left.letSlip, 2);
    });

    test('can take the last heart, which ends the fight', () {
      final left = const TrialRun(hearts: 1).leftMidThrow();
      expect(left.hearts, 0);
      expect(left.lost, isTrue);
    });

    test('never goes below no hearts', () {
      expect(const TrialRun(hearts: 0).leftMidThrow().hearts, 0);
    });
  });

  group('TrialRun.revived', () {
    test('hands back two hearts and keeps the boss as worn down as it was', () {
      final lost = const TrialRun(hearts: 0, patience: 33, combo: 4, caught: 6);
      final revived = lost.revived();
      expect(BossTrialRules.reviveHearts, 2);
      expect(revived.hearts, 2);
      expect(revived.patience, 33);
      expect(revived.caught, 6);
      expect(revived.combo, 0);
      expect(revived.lost, isFalse);
    });

    test('is never the full three: a second chance, not a reset', () {
      expect(BossTrialRules.reviveHearts, lessThan(BossTrialRules.maxHearts));
    });
  });

  group('BossRunSave', () {
    test('a fight left between throws resumes exactly as it was', () {
      final save = saveOf();
      expect(save.resumed().hearts, 2);
      expect(save.resumed().combo, 3);
      expect(save.resumed().patience, 61);
    });

    test('a fight left with a throw in the air resumes a heart down', () {
      final save = saveOf(inThrow: true);
      expect(save.resumed().hearts, 1);
      expect(save.resumed().combo, 0);
      expect(save.resumed().patience, 61, reason: 'the boss keeps its ground');
    });

    test('survives being written and read back', () async {
      await saveOf(inThrow: true).save();

      final back = (await BossRunSave.load())!;

      expect(back.bossId, 'mossback');
      expect(back.step, 2);
      expect(back.round, 1);
      expect(back.inThrow, isTrue);
      expect(back.languageCode, 'es');
      expect(back.nativeCode, 'en');
      expect(back.run.hearts, 2);
      expect(back.run.patience, 61);
      expect(back.run.bestCombo, 4);
      expect(back.run.caught, 7);
      expect(back.run.broken, 1);
      expect(back.run.letSlip, 2);
      expect(back.run.endsAt, 20);
      expect(back.run.last, isFalse);
      expect(back.run.missed, [word]);
      expect(back.run.missedSentences.single.tokens, ['yo', 'leo']);
      expect(back.run.missedSentences.single.meaning, 'I read');
    });

    test('only matches the same boss, level and pair', () {
      final save = saveOf();
      bool matches({
        String boss = 'mossback',
        int step = 2,
        String? lang = 'es',
        String? native = 'en',
      }) =>
          save.matches(
              bossId: boss, step: step, languageCode: lang, nativeCode: native);

      expect(matches(), isTrue);
      expect(matches(boss: 'witch'), isFalse);
      expect(matches(step: 3), isFalse);
      expect(matches(lang: 'fr'), isFalse);
      expect(matches(native: 'tr'), isFalse);
    });

    test('is none when nothing was saved', () async {
      expect(await BossRunSave.load(), isNull);
    });

    test('clear removes it', () async {
      await saveOf().save();
      await BossRunSave.clear();
      expect(await BossRunSave.load(), isNull);
    });

    test('a corrupt save is not offered, and does not throw', () async {
      SharedPreferences.setMockInitialValues({BossRunSave.key: '{not json'});
      expect(await BossRunSave.load(), isNull);

      SharedPreferences.setMockInitialValues(
          {BossRunSave.key: jsonEncode({'boss': 'mossback'})});
      expect(await BossRunSave.load(), isNull);

      SharedPreferences.setMockInitialValues(
          {BossRunSave.key: jsonEncode([1, 2, 3])});
      expect(await BossRunSave.load(), isNull);
    });

    test('hearts and patience are held to what a fight can have', () {
      final save = BossRunSave.fromJson({
        ...saveOf().toJson(),
        'hearts': 99,
        'patience': 9999,
      })!;
      expect(save.run.hearts, BossTrialRules.maxHearts);
      expect(save.run.patience, BossTrialRules.maxPatience * 2);
    });
  });
}
