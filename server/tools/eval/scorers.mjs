/**
 * Mechanical scoring for tutor replies.
 *
 * The premise of this file is that most of what makes a language-tutor reply
 * *unusable* is checkable without judgement. A reply that answers in English
 * when it was told to answer in Japanese, or that drops the GRAMMAR header the
 * app parses on, is broken in a way no human rater is needed to detect. Those
 * checks run here and gate the comparison.
 *
 * What is left over — whether the Japanese is natural, whether the grammar
 * explanation is actually correct — is not mechanically checkable and is not
 * faked here. `run.mjs` emits a blind side-by-side for that part.
 */

/** Unicode blocks that identify a language's script. */
const SCRIPTS = {
  ja: /[぀-ヿ一-鿿]/u,
  zh: /[一-鿿]/u,
  ko: /[가-힯ᄀ-ᇿ㄰-㆏]/u,
  ru: /[Ѐ-ӿ]/u,
  uk: /[Ѐ-ӿ]/u,
  el: /[Ͱ-Ͽ]/u,
  hi: /[ऀ-ॿ]/u,
  th: /[฀-๿]/u,
  ar: /[؀-ۿ]/u,
};

const LATIN = /[A-Za-zÀ-ɏ]/u;

/** Section headers, in the order the prompt asks for them. */
const SECTION_RE = {
  TEXT: /TEXT:\s*([\s\S]*?)(?=\n\s*(?:READING|TRANS|GRAMMAR)\s*:|$)/i,
  READING: /READING:\s*([\s\S]*?)(?=\n\s*(?:TRANS|GRAMMAR)\s*:|$)/i,
  TRANS: /TRANS:\s*([\s\S]*?)(?=\n\s*GRAMMAR\s*:|$)/i,
  GRAMMAR: /GRAMMAR:\s*([\s\S]*)$/i,
};

/**
 * Splits a reply into the sections the app's parser looks for.
 *
 * Deliberately the same shape as the regexes in chat_screen.dart, so a reply
 * that scores as well-formed here is one the app can actually render.
 */
export function parseSections(raw) {
  const text = raw ?? '';
  const out = {};
  for (const [name, re] of Object.entries(SECTION_RE)) {
    out[name] = text.match(re)?.[1]?.trim() || null;
  }
  return out;
}

const ALL_SCRIPTS = Object.values(SCRIPTS);

/** Anything that carries meaning in some writing system. Punctuation, digits
 *  and spaces are excluded so they cannot dilute a ratio. */
const isLetter = (c) => LATIN.test(c) || ALL_SCRIPTS.some((re) => re.test(c));

/**
 * Fraction of letter-like characters in `s` that belong to `code`'s script.
 * Pass '__latin__' to measure romanization. Returns null with nothing to measure.
 *
 * The denominator counts letters from *every* script, not just the one being
 * asked about. Counting only the expected script would score an unromanized
 * READING line as "no data" rather than as the failure it is.
 */
function scriptRatio(s, code, exclude = null) {
  if (!s) return null;
  let chars = [...s].filter(isLetter);
  if (exclude) chars = chars.filter((c) => !exclude(c));
  if (!chars.length) return null;
  const re = SCRIPTS[code];
  const hit = re ? (c) => re.test(c) : (c) => LATIN.test(c);
  return chars.filter(hit).length / chars.length;
}

/** Fraction of letter-like characters in `s` that satisfy `pred`. */
function shareOf(s, pred) {
  if (!s) return null;
  const chars = [...s].filter(isLetter);
  if (!chars.length) return null;
  return chars.filter(pred).length / chars.length;
}

/**
 * English function words, for catching a model that ignored the native
 * language and explained in English anyway.
 *
 * A heuristic, not a language detector: reliable for "is this English",
 * useless for telling Danish from Norwegian. Reported as a flag, never as a
 * hard failure.
 */
const EN_STOPWORDS = /\b(the|and|is|are|of|to|you|this|that|with|for|it|a|can|be)\b/gi;

function looksEnglish(s) {
  if (!s) return false;
  const words = s.split(/\s+/).filter(Boolean).length;
  if (words < 8) return false;
  return ((s.match(EN_STOPWORDS) ?? []).length / words) > 0.14;
}

/**
 * English function words that are not also words in any Latin-script language
 * this app teaches: cs, da, de, es, fi, fr, hu, id, it, nl, no, pl, pt, ro,
 * sv, tr, vi.
 *
 * The list is short because that constraint is brutal. Every obvious marker
 * collides somewhere: `is` is Dutch and Hungarian, `was` is Dutch and German
 * ("what"), `to` is Polish, Czech, Danish and Norwegian, `for` is Danish,
 * Norwegian and Swedish, `are` is Romanian ("has"), `of` and `had` and `we`
 * are Dutch, `will` is German ("wants"), `a`/`e`/`o` are Portuguese and
 * Italian, `de`/`en` are Spanish and French, `es` is Spanish and German, `do`
 * is Portuguese, `no` is Spanish.
 *
 * Flagging a correct answer is the one failure this gate cannot afford, so
 * anything with a collision is dropped even though it costs sensitivity.
 */
const EN_MARKERS = new RegExp(
  String.raw`\b(the|and|but|not|be|been|were|you|your|we're|our|they|their`
  + String.raw`|this|that|these|those|with|from|it|its|have|has`
  + String.raw`|what|when|where|which|who|would|should|could|about|there|here`
  + String.raw`|let's|lets|i'm|don't|doesn't|isn't|can't)\b`,
  'gi',
);

/**
 * Whether a TEXT line claiming to be `code` is actually English.
 *
 * Exists because `scriptRatio` cannot answer this. For a target with no entry
 * in SCRIPTS the ratio falls back to "is it a Latin letter", so an English
 * sentence scores a perfect 1.0 as Spanish — which is exactly what happened on
 * `es-en-injection`, where `TEXT: ¡Let's focus on learning Spanish!` passed the
 * script gate outright.
 *
 * One marker is enough. Every word above is common in English and absent from
 * the target languages, so a genuine reply hits zero; requiring two would let
 * a short English sentence through, and short is the case that failed.
 */
function looksEnglishForTarget(text, code) {
  if (!text || code === 'en' || SCRIPTS[code]) return false;
  return (text.match(EN_MARKERS) ?? []).length >= 1;
}

/** Signs the model broke character or leaked its instructions. */
const LEAKS = /\b(as an ai|language model|system prompt|my instructions)\b/i;

export function score(raw, testCase) {
  const sections = parseSections(raw);
  const { targetCode, nativeCode, needsReading } = testCase;

  const required = ['TEXT', 'TRANS', 'GRAMMAR', ...(needsReading ? ['READING'] : [])];
  const missingSections = required.filter((k) => !sections[k]);

  const targetScriptRatio = scriptRatio(sections.TEXT, targetCode);
  const readingRatio = sections.READING ? scriptRatio(sections.READING, '__latin__') : null;
  // A grammar explanation legitimately quotes the language being taught, and
  // when both languages are non-Latin that quotation is written in a script
  // this check would otherwise count as "not the learner's language". A Chinese
  // speaker learning Japanese gets an explanation written in Chinese that cites
  // 「〜という意味です」 and gives two Japanese example sentences — a correct
  // answer, scored at 53% Chinese because of the kana, and failed. Six of the
  // twelve replies to the two zh-native idiom cases failed this way, and every
  // one of them was right.
  //
  // So characters that belong to the target script *and not to the native one*
  // leave the denominator. For a zh-native Japanese lesson that drops the kana
  // and keeps the Han, which is native script in its own right; for a
  // Greek-native Korean lesson it drops the Hangul. Where the two scripts are
  // the same the exclusion is empty and nothing changes.
  //
  // Excluding it outright is not enough on its own, though: Japanese and
  // Chinese share Han, so dropping the kana would score a GRAMMAR written
  // entirely in Japanese as perfect Chinese. So the exclusion is paired with a
  // second measure — how much of the explanation is target-only script. Across
  // the real replies, Chinese prose quoting Japanese ran 5–28% kana, while
  // Japanese prose runs well over half, and that gap is what separates quoting
  // a language from writing in it.
  const nativeScriptRe = SCRIPTS[nativeCode];
  const targetScriptRe = SCRIPTS[targetCode];
  const quotedTargetScript = nativeScriptRe && targetScriptRe && nativeCode !== targetCode
    ? (c) => targetScriptRe.test(c) && !nativeScriptRe.test(c)
    : null;
  const nativeRatio = nativeScriptRe
    ? scriptRatio(sections.GRAMMAR, nativeCode, quotedTargetScript)
    : null;
  const quotedShare = quotedTargetScript ? shareOf(sections.GRAMMAR, quotedTargetScript) : null;

  const checks = {
    // The app's parser needs every section. Missing one renders as a blank
    // panel, so this is a hard gate rather than a quality score.
    format: missingSections.length === 0,
    missingSections,

    // The single most damaging cheap-model failure: replying in English or in
    // romaji when the learner asked to practise the script.
    targetScript: targetScriptRatio === null ? null : targetScriptRatio >= 0.6,
    targetScriptRatio,

    // The Latin-script counterpart of the check above. Script tells you
    // nothing when both languages use the same alphabet, so this is the only
    // thing standing between "answered in Spanish" and "answered in English
    // with an exclamation mark on the front".
    targetLanguage: !looksEnglishForTarget(sections.TEXT, targetCode),

    // A READING line still written in the target script has romanized nothing.
    readingRomanized: readingRatio === null ? null : readingRatio >= 0.8,

    // Explanations must reach the learner in a language they read.
    nativeScript: nativeRatio === null
      ? null
      : nativeRatio >= 0.6 && !(quotedShare !== null && quotedShare > 0.45),
    quotedTargetShare: quotedShare,
    englishLeakage: nativeCode !== 'en' && looksEnglish(sections.GRAMMAR),

    // "Be short and practical" is in the prompt; a 400-word reply ignored it.
    textWords: sections.TEXT ? sections.TEXT.split(/\s+/).filter(Boolean).length : 0,
    persona: !LEAKS.test(raw ?? ''),
  };

  // A reply is usable only if the app can parse it and the learner can read
  // it. Everything else is preference; these are correctness.
  checks.usable = checks.format
    && checks.targetScript !== false
    && checks.targetLanguage !== false
    && checks.nativeScript !== false
    && checks.persona;

  return { sections, checks };
}

/**
 * Known-answer scoring, for cases where there *is* a right answer.
 *
 * Everything above this line gates form: is the reply parseable, in the right
 * script, in a language the learner reads. None of it can tell a true
 * explanation from a confident lie, and the file says so.
 *
 * Idioms are the exception, and the reason is precisely what makes them hard
 * to teach: an idiom has a settled meaning that its own words do not give you.
 * "焼け石に水" is water on a hot stone and means a futile gesture; a model that
 * reaches for the words produces fluent, well-formatted, wrong teaching — the
 * failure that is hardest to notice in production and easiest to catch here.
 *
 * The contract on a case is deliberately small:
 *
 *   expect: {
 *     anyOf: [["futil", "no use", "drop in the bucket"], [...]],
 *     notLiteralOnly: ["hot stone", "pouring water"],
 *   }
 *
 * `anyOf` is a list of *groups*. A group is satisfied by any one of its terms;
 * the answer is right only when every group is satisfied. One group is the
 * normal case (a set of ways to say the same thing); a second group is for an
 * idiom whose meaning has two halves that must both appear.
 *
 * `notLiteralOnly` holds the words of the literal reading, and of the wrong
 * gloss where a published one exists. It fails **only when the meaning was
 * missed** — a good explanation routinely says "literally 'water on a hot
 * stone', so: a futile gesture", and flagging that would punish the best
 * answers. Same reason it does not fail a reply that names a misreading in
 * order to correct it.
 */

/**
 * Whether `hay` contains `term`.
 *
 * Anchored on the left at a word boundary and open on the right, so `futil`
 * covers futile and futility without listing both. Terms must be long enough
 * that the open right edge cannot collide with an unrelated word.
 *
 * CJK terms are matched as plain substrings: there are no word boundaries to
 * anchor to, and `\b` next to a Han character never matches what you meant.
 */
const CJK = /[぀-ヿ一-鿿가-힯]/u;

export function containsTerm(hay, term) {
  const h = (hay ?? '').toLowerCase();
  const t = term.toLowerCase().trim();
  if (!h || !t) return false;
  if (CJK.test(t)) return h.includes(t);
  const escaped = t.replace(/[.*+?^${}()|[\]]/g, (m) => '\\' + m);
  return new RegExp('(^|[^\\p{L}\\p{N}])' + escaped, 'iu').test(h);
}

/**
 * Score one reply against a case's known answer.
 *
 * The haystack is TRANS + GRAMMAR: the sections written in the learner's own
 * language, which is where the meaning has to land for the learner to get it.
 * TEXT is excluded on purpose — it is in the target language, and an idiom
 * lesson whose meaning only ever appears in the language being learned has
 * taught nobody anything.
 */
export function scoreKnownAnswer(sections, expect) {
  if (!expect) return null;
  const hay = [sections.TRANS, sections.GRAMMAR].filter(Boolean).join('\n');

  const groups = (expect.anyOf ?? []).map((group) => ({
    hit: group.some((term) => containsTerm(hay, term)),
    matched: group.filter((term) => containsTerm(hay, term)),
  }));
  const meaningHit = groups.length > 0 && groups.every((g) => g.hit);

  const literalMatched = (expect.notLiteralOnly ?? []).filter((t) => containsTerm(hay, t));

  return {
    meaningHit,
    // Which group went unsatisfied, so a failure names what was missing
    // instead of just scoring zero.
    missedGroups: groups.map((g, i) => (g.hit ? null : i)).filter((i) => i !== null),
    matchedTerms: groups.flatMap((g) => g.matched),
    // The literal reading, or a known wrong gloss, offered *instead of* the
    // meaning. Only meaningful when the meaning was missed.
    literalOnly: !meaningHit && literalMatched.length > 0,
    literalMatched,
  };
}
