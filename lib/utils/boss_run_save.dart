import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'boss_trial.dart';

/// A boss fight put down mid-way, so closing the app does not end it.
///
/// A fight is saved between throws and again as each one begins. Leaving —
/// the app closed, the phone rung, a crash — and coming back offers to carry
/// on from there. Nothing is lost to an unexpected problem.
///
/// Saved at the *boundary* of a throw rather than in the middle of one. A
/// throw's state is a different shape for each of the 24 openings, and
/// rebuilding it would mean a serialiser per opening. Instead the save records
/// whether a throw was in the air, and picking it back up **costs the throw a
/// heart**: leaving mid-throw counts as letting it land. That closes the one
/// thing resuming could be abused for — looking at the answer, quitting, and
/// returning to a new throw, or quitting with the last heart about to go to
/// dodge the loss.
///
/// Held in prefs under [_key] and kept on this device (`LocalSnapshot` lists
/// it): a half-finished fight means nothing on another phone.
class BossRunSave {
  const BossRunSave({
    required this.bossId,
    required this.step,
    required this.round,
    required this.inThrow,
    required this.run,
    required this.languageCode,
    required this.nativeCode,
  });

  /// The prefs key. `LocalSnapshot` keeps it off the cloud copy.
  static const String key = 'boss_run_save';

  final String bossId;

  /// Which of the boss's levels, counted from 0.
  final int step;

  /// The round of a finale the fight had reached; 0 for any other level.
  final int round;

  /// Whether a throw was in the air when this was saved.
  final bool inThrow;

  final TrialRun run;

  /// The pair the fight was in. A different pair now means a different fight.
  final String? languageCode;
  final String? nativeCode;

  bool matches({
    required String bossId,
    required int step,
    required String? languageCode,
    required String? nativeCode,
  }) =>
      this.bossId == bossId &&
      this.step == step &&
      this.languageCode == languageCode &&
      this.nativeCode == nativeCode;

  /// The run to carry on with: this one, less a heart if a throw was in the
  /// air when it was left.
  TrialRun resumed() => inThrow ? run.leftMidThrow() : run;

  Map<String, Object?> toJson() => {
        'boss': bossId,
        'step': step,
        'round': round,
        'inThrow': inThrow,
        'lang': languageCode,
        'native': nativeCode,
        'hearts': run.hearts,
        'patience': run.patience,
        'combo': run.combo,
        'bestCombo': run.bestCombo,
        'caught': run.caught,
        'broken': run.broken,
        'letSlip': run.letSlip,
        'endsAt': run.endsAt,
        'last': run.last,
        'missed': [
          for (final w in run.missed)
            {'t': w.target, 'm': w.meaning, if (w.reading != null) 'r': w.reading},
        ],
        'missedSentences': [
          for (final s in run.missedSentences)
            {'tokens': s.tokens, 'target': s.target, 'meaning': s.meaning},
        ],
      };

  /// Null for anything that is not a fight this build could have saved, so a
  /// corrupt or older save is simply not offered.
  static BossRunSave? fromJson(Object? decoded) {
    if (decoded is! Map) return null;
    try {
      int n(String k) => (decoded[k] as num).toInt();
      return BossRunSave(
        bossId: decoded['boss'] as String,
        step: n('step'),
        round: n('round'),
        inThrow: decoded['inThrow'] as bool,
        languageCode: decoded['lang'] as String?,
        nativeCode: decoded['native'] as String?,
        run: TrialRun(
          hearts: n('hearts').clamp(0, BossTrialRules.maxHearts),
          patience: n('patience').clamp(0, BossTrialRules.maxPatience * 2),
          combo: n('combo'),
          bestCombo: n('bestCombo'),
          caught: n('caught'),
          broken: n('broken'),
          letSlip: n('letSlip'),
          endsAt: n('endsAt'),
          last: decoded['last'] as bool,
          missed: [
            for (final w in decoded['missed'] as List)
              TrialWord(
                target: w['t'] as String,
                meaning: w['m'] as String,
                reading: w['r'] as String?,
              ),
          ],
          missedSentences: [
            for (final s in decoded['missedSentences'] as List)
              TrialSentence(
                tokens: [for (final t in s['tokens'] as List) t as String],
                target: s['target'] as String,
                meaning: s['meaning'] as String,
              ),
          ],
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// The saved fight, or null when there is none. Never throws: a fight that
  /// cannot be read is a fight that is not offered.
  static Future<BossRunSave?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return null;
      return fromJson(jsonDecode(raw));
    } catch (e) {
      debugPrint('BOSS RUN: could not read the saved fight - $e');
      return null;
    }
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(toJson()));
    } catch (e) {
      debugPrint('BOSS RUN: could not save the fight - $e');
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      debugPrint('BOSS RUN: could not clear the saved fight - $e');
    }
  }
}
