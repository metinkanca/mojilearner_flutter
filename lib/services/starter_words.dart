import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/calibration_provider.dart';
import '../providers/language_provider.dart';
import '../providers/vocab_provider.dart';
import '../utils/vocab_extractor.dart';
import 'ai_prompt_spec.dart';
import 'ai_service.dart';

/// Gives a player words to practise with.
///
/// Onboarding works out a player's level and leaves them with no words at all,
/// so the toy chest and the boss fights have nothing to draw on until they have
/// chatted for a while. This asks the model for a dozen words at their level
/// when onboarding ends, and again whenever the words the games draw on run
/// thin. They go to the suggested pile: the player has not met them, so they
/// are for the games and not for the review queue.
///
/// Best effort throughout. Offline, over its small allowance, or given nonsense
/// back, it adds nothing and says nothing: the player still has the toys that
/// their own words can fill, and the next try is an hour away.
class StarterWords {
  StarterWords._();

  /// Fewer than this many words in a language and the games are thin, so more
  /// are asked for. Four different meanings fill a throw; this leaves room to
  /// vary it.
  static const int thinBelow = 8;

  /// The least time between two asks for one language, so a player in a tunnel
  /// does not ask on every tap.
  static const Duration minGap = Duration(hours: 1);

  /// How many of the words they already have the model is asked to avoid.
  static const int maxExcluded = 40;

  static String _key(String languageCode) => 'starter_words_asked_$languageCode';

  /// Asks for more words if the player is short of them. Returns how many were
  /// added, which is zero for every reason it did nothing.
  ///
  /// [generate] defaults to the real model, and is what tests replace.
  static Future<int> ensure({
    required VocabProvider vocab,
    required String languageCode,
    required String nativeCode,
    required String level,
    Future<String> Function(AiPromptSpec spec)? generate,
    DateTime Function()? now,
  }) async {
    try {
      final have = vocab.practiseItems
          .where((i) => i.languageCode == languageCode)
          .toList();
      if (have.length >= thinBelow) return 0;

      final clock = (now ?? DateTime.now)();
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getInt(_key(languageCode));
      if (last != null &&
          clock.difference(DateTime.fromMillisecondsSinceEpoch(last)) < minGap) {
        return 0;
      }
      // Recorded before the call, so a call that fails still waits its turn.
      await prefs.setInt(_key(languageCode), clock.millisecondsSinceEpoch);

      final spec = AiPromptSpec.starter(
        targetCode: languageCode,
        nativeCode: nativeCode,
        level: level,
        exclude: [for (final i in have.take(maxExcluded)) i.prompt],
      );
      final reply = generate != null
          ? await generate(spec)
          : await AiService.instance.generateText(
              spec: spec,
              source: 'starter_words',
              config: AiGenerationConfig.structuredJson,
            );
      if (reply.isEmpty) return 0;
      if (generate == null && AiService.instance.isUnavailableResponse(reply)) {
        return 0;
      }

      final words = VocabExtractor.parseList(reply);
      return vocab
          .addSuggested(words, languageCode: languageCode)
          .length;
    } catch (e) {
      debugPrint('STARTER WORDS: could not get words - $e');
      return 0;
    }
  }

  /// [ensure] for the player this context belongs to: their target language,
  /// their native one, and the level they were assessed at. Does nothing before
  /// they have chosen a language.
  ///
  /// Never throws. It is called as onboarding ends and as the toy chest opens,
  /// and getting words must not be able to break either.
  static Future<int> ensureForPlayer(BuildContext context) async {
    try {
      final languages = Provider.of<LanguageProvider>(context, listen: false);
      final code = languages.targetLanguage?.code;
      if (code == null) return 0;
      final level = Provider.of<CalibrationProvider>(context, listen: false)
              .getLanguageProficiency(code)
              ?.aiDeterminedLevel ??
          'beginner';
      return await ensure(
        vocab: Provider.of<VocabProvider>(context, listen: false),
        languageCode: code,
        nativeCode: languages.nativeLanguage.code,
        level: level,
      );
    } catch (e) {
      debugPrint('STARTER WORDS: could not ask for words - $e');
      return 0;
    }
  }
}
