/// What each language calls itself.
///
/// A language picker written in English is only usable by people who already
/// read English — which is the one thing a first-launch language picker cannot
/// assume. Endonyms need no translation matrix: `Français` is right whatever
/// the app's current locale is, so 27 names cover all 27 x 27 combinations.
///
/// `Language.name` stays English on purpose: it is what the tutor prompts say
/// ("an advanced learner of Spanish"), and the model expects English names.
library;

const Map<String, String> languageEndonyms = {
  'en': 'English',
  'es': 'Español',
  'fr': 'Français',
  'de': 'Deutsch',
  'it': 'Italiano',
  'pt': 'Português',
  'ru': 'Русский',
  'ja': '日本語',
  'zh': '中文',
  'ko': '한국어',
  'ar': 'العربية',
  'hi': 'हिन्दी',
  'tr': 'Türkçe',
  'nl': 'Nederlands',
  'sv': 'Svenska',
  'pl': 'Polski',
  'id': 'Bahasa Indonesia',
  'vi': 'Tiếng Việt',
  'th': 'ไทย',
  'el': 'Ελληνικά',
  'uk': 'Українська',
  'da': 'Dansk',
  'fi': 'Suomi',
  'no': 'Norsk',
  'cs': 'Čeština',
  'ro': 'Română',
  'hu': 'Magyar',
};
