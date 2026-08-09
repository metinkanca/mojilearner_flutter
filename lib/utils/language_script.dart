/// Which target languages need a pronunciation guide, and what to call it.
///
/// Nine of the app's target languages are written in scripts a beginner
/// cannot sound out. Without a reading, `こんにちは` is an image with a
/// translation attached — the learner can recognise it but never say it.
///
/// Pure lookup so the policy is testable and lives in one place rather than
/// being re-derived at each call site.
library;

/// The romanisation system a language conventionally uses.
///
/// Named rather than generic because learners search for these by name, and
/// "Pinyin" tells a Chinese learner far more than "Reading" does.
enum ScriptGuide {
  /// Japanese — Hepburn romaji.
  romaji,

  /// Mandarin Chinese — Hanyu Pinyin, with tone marks.
  pinyin,

  /// Korean — Revised Romanization.
  romaja,

  /// Everything else non-Latin: Arabic, Hindi, Thai, Russian, Greek,
  /// Ukrainian. These have no single household-name system, so the generic
  /// label is the honest one.
  romanization,
}

extension ScriptGuideLabel on ScriptGuide {
  /// What to call the reading in the UI and in the prompt.
  String get label {
    switch (this) {
      case ScriptGuide.romaji:
        return 'Romaji';
      case ScriptGuide.pinyin:
        return 'Pinyin';
      case ScriptGuide.romaja:
        return 'Romaja';
      case ScriptGuide.romanization:
        return 'Reading';
    }
  }

  /// The instruction given to the tutor. Specific enough that the model
  /// produces the system a learner of that language actually expects.
  String get promptInstruction {
    switch (this) {
      case ScriptGuide.romaji:
        return 'Hepburn romaji, with long vowels marked (e.g. "koohii" as '
            '"kōhī"), spaced at word boundaries';
      case ScriptGuide.pinyin:
        return 'Hanyu Pinyin with tone marks (e.g. "nǐ hǎo"), spaced at word '
            'boundaries';
      case ScriptGuide.romaja:
        return 'Revised Romanization of Korean (e.g. "annyeonghaseyo")';
      case ScriptGuide.romanization:
        return 'a simple romanization a beginner can read aloud';
    }
  }
}

class LanguageScript {
  LanguageScript._();

  /// Target languages written in a non-Latin script, mapped to the reading
  /// system a learner of that language expects.
  ///
  /// Keyed by the same codes [LanguageProvider.availableLanguages] uses.
  static const Map<String, ScriptGuide> _guides = {
    'ja': ScriptGuide.romaji,
    'zh': ScriptGuide.pinyin,
    'ko': ScriptGuide.romaja,
    'ar': ScriptGuide.romanization,
    'hi': ScriptGuide.romanization,
    'th': ScriptGuide.romanization,
    'ru': ScriptGuide.romanization,
    'el': ScriptGuide.romanization,
    'uk': ScriptGuide.romanization,
  };

  /// The reading system for [languageCode], or null when the language is
  /// written in Latin script and needs no guide.
  static ScriptGuide? guideFor(String? languageCode) {
    if (languageCode == null) return null;
    return _guides[languageCode.toLowerCase()];
  }

  /// True when learners of [languageCode] need a pronunciation guide.
  static bool needsReading(String? languageCode) =>
      guideFor(languageCode) != null;

  /// What to call the reading for [languageCode]. Falls back to the generic
  /// label so a caller never has to null-check purely to render a heading.
  static String labelFor(String? languageCode) =>
      guideFor(languageCode)?.label ?? ScriptGuide.romanization.label;

  /// Every language code that needs a reading. Exposed for tests and for
  /// anything that wants to reason about coverage.
  static Iterable<String> get codesNeedingReading => _guides.keys;
}
