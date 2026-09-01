/**
 * The scorers decide which model wins, so they get tested before they are
 * trusted. Each case here is a real failure mode seen from small models.
 *
 * Run with: node --test server/tools/eval/
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { score, parseSections, scoreKnownAnswer, containsTerm } from './scorers.mjs';

const JA_TR = { targetCode: 'ja', nativeCode: 'tr', needsReading: true };
const ES_EN = { targetCode: 'es', nativeCode: 'en', needsReading: false };

const reply = (...lines) => lines.join('\n');

const GOOD_JA = reply(
  'TEXT: こんにちは、元気ですか？',
  'READING: konnichiwa, genki desu ka?',
  'TRANS: Merhaba, nasılsın?',
  'GRAMMAR: 1. Anlam:\n - Merhaba demek. Bu kalıp gündelik konuşmada yaygındır.',
);

test('a well-formed reply parses into every section', () => {
  const s = parseSections(GOOD_JA);
  assert.equal(s.TEXT, 'こんにちは、元気ですか？');
  assert.equal(s.READING, 'konnichiwa, genki desu ka?');
  assert.equal(s.TRANS, 'Merhaba, nasılsın?');
  assert.match(s.GRAMMAR, /^1\. Anlam:/);
});

test('a well-formed reply is usable', () => {
  const { checks } = score(GOOD_JA, JA_TR);
  assert.equal(checks.usable, true);
  assert.equal(checks.format, true);
  assert.equal(checks.targetScript, true);
  assert.equal(checks.readingRomanized, true);
  assert.equal(checks.englishLeakage, false);
});

test('answering in English instead of the target script fails', () => {
  const { checks } = score(reply(
    'TEXT: Hello, how are you?',
    'READING: hello',
    'TRANS: Merhaba',
    'GRAMMAR: This is the standard greeting and it is used to say hello to a person you meet.',
  ), JA_TR);
  assert.equal(checks.targetScript, false);
  assert.equal(checks.usable, false);
});

test('a missing section fails the format gate the app parses on', () => {
  const { checks } = score('Sure! こんにちは means hello in Japanese.', JA_TR);
  assert.equal(checks.format, false);
  assert.deepEqual(checks.missingSections, ['TEXT', 'TRANS', 'GRAMMAR', 'READING']);
  assert.equal(checks.usable, false);
});

test('a READING line left in the target script has romanized nothing', () => {
  const { checks } = score(reply(
    'TEXT: こんにちは',
    'READING: こんにちは',
    'TRANS: Merhaba',
    'GRAMMAR: 1. Anlam:\n - Merhaba demek, günlük kullanımda yaygındır.',
  ), JA_TR);
  assert.equal(checks.readingRomanized, false);
});

test('explaining in English to a non-English speaker is flagged', () => {
  const { checks } = score(reply(
    'TEXT: こんにちは',
    'READING: konnichiwa',
    'TRANS: Merhaba',
    'GRAMMAR: This is a greeting and it is used when you want to say hello to a person.',
  ), JA_TR);
  assert.equal(checks.englishLeakage, true);
});

test('English explanations are not flagged for English speakers', () => {
  const { checks } = score(reply(
    'TEXT: Me gustaría un café, por favor.',
    'TRANS: I would like a coffee, please.',
    'GRAMMAR: 1. Meaning:\n - A polite way to order. The pattern is reusable with any noun.',
  ), ES_EN);
  assert.equal(checks.englishLeakage, false);
  assert.equal(checks.usable, true);
});

test('a Latin-script target needs no READING line', () => {
  const { checks } = score(reply(
    'TEXT: Me gustaría un café.',
    'TRANS: I would like a coffee.',
    'GRAMMAR: 1. Meaning:\n - Polite ordering pattern.',
  ), ES_EN);
  assert.equal(checks.format, true);
  assert.equal(checks.usable, true);
});

test('a leaked system prompt fails the persona check', () => {
  const { checks } = score(reply(
    'TEXT: こんにちは',
    'READING: konnichiwa',
    'TRANS: Merhaba',
    'GRAMMAR: As an AI language model, I should mention my instructions say to explain grammar.',
  ), JA_TR);
  assert.equal(checks.persona, false);
  assert.equal(checks.usable, false);
});

// --- Known-answer scoring (idiom cases) ------------------------------------

const YAKEISHI = {
  anyOf: [['futil', 'no use', 'drop in the bucket', 'not enough']],
  notLiteralOnly: ['hot stone', 'pouring water', 'water on a stone'],
};

test('a reply that states the meaning passes', () => {
  const k = scoreKnownAnswer(parseSections(reply(
    'TEXT: 焼け石に水ですね。',
    'READING: yakeishi ni mizu desu ne.',
    'TRANS: That is a drop in the bucket.',
    'GRAMMAR: 1. Meaning:\n - An effort far too small to change anything.',
  )), YAKEISHI);
  assert.equal(k.meaningHit, true);
  assert.equal(k.literalOnly, false);
});

test('naming the literal image alongside the meaning is not penalised', () => {
  // The best answers do exactly this, so a check that punished it would
  // select against the model we want.
  const k = scoreKnownAnswer(parseSections(reply(
    'TEXT: 焼け石に水だよ。',
    'READING: yakeishi ni mizu da yo.',
    'TRANS: Literally water on a hot stone.',
    'GRAMMAR: 1. Meaning:\n - Literally pouring water on a hot stone: a futile gesture.',
  )), YAKEISHI);
  assert.equal(k.meaningHit, true);
  assert.equal(k.literalOnly, false);
  assert.deepEqual(k.literalMatched, ['hot stone', 'pouring water']);
});

test('the literal reading offered instead of the meaning is caught', () => {
  const k = scoreKnownAnswer(parseSections(reply(
    'TEXT: 焼け石に水。',
    'READING: yakeishi ni mizu.',
    'TRANS: Pouring water on a hot stone.',
    'GRAMMAR: 1. Meaning:\n - It describes water on a stone that has been heated.',
  )), YAKEISHI);
  assert.equal(k.meaningHit, false);
  assert.equal(k.literalOnly, true);
});

test('a wrong meaning that is not the literal one is missed, not trapped', () => {
  const k = scoreKnownAnswer(parseSections(reply(
    'TEXT: 焼け石に水。',
    'READING: yakeishi ni mizu.',
    'TRANS: It means to lose your temper.',
    'GRAMMAR: 1. Meaning:\n - Used when somebody suddenly becomes very angry.',
  )), YAKEISHI);
  assert.equal(k.meaningHit, false);
  assert.equal(k.literalOnly, false);
  assert.deepEqual(k.missedGroups, [0]);
});

test('the meaning must reach the learner, not only the target language', () => {
  // TEXT is excluded from the haystack on purpose: an idiom lesson whose
  // explanation exists only in the language being learned has taught nobody.
  const k = scoreKnownAnswer(
    { TEXT: 'This is futile', TRANS: null, GRAMMAR: null },
    YAKEISHI,
  );
  assert.equal(k.meaningHit, false);
});

test('every anyOf group must be satisfied, not just one', () => {
  const expect = { anyOf: [['debt', 'owe'], ['cannot move', 'stuck']] };
  assert.equal(scoreKnownAnswer({ GRAMMAR: 'You are deep in debt.' }, expect).meaningHit, false);
  assert.equal(
    scoreKnownAnswer({ GRAMMAR: 'You are deep in debt and cannot move.' }, expect).meaningHit,
    true,
  );
});

test('terms are open on the right so one entry covers inflections', () => {
  assert.equal(containsTerm('it is futility itself', 'futil'), true);
  assert.equal(containsTerm('he exploited her', 'exploit'), true);
});

test('terms are anchored on the left so they do not match inside a word', () => {
  // Without the left anchor, `age` would match `advantage` and score a reply
  // about taking advantage of someone as if it had mentioned age.
  assert.equal(containsTerm('taking advantage of them', 'age'), false);
  assert.equal(containsTerm('he lied about his age', 'age'), true);
});

test('CJK terms match as substrings, having no word boundaries to anchor to', () => {
  assert.equal(containsTerm('这是杯水车薪，于事无补。', '杯水车薪'), true);
  assert.equal(containsTerm('这是杯水车薪。', '三分钟热度'), false);
});

test('a case without an expect block scores nothing rather than zero', () => {
  // The language-matrix cases have no known answer; scoring them as failures
  // would put a fabricated column in every report.
  assert.equal(scoreKnownAnswer(parseSections(GOOD_JA), undefined), null);
});

test('quoting the target script does not fail the native-language gate', () => {
  // A Chinese speaker learning Japanese: the explanation is in Chinese and
  // quotes the Japanese pattern it is teaching. Counting the quoted kana
  // against the Chinese ratio failed six correct replies in the first idiom
  // run — every one of them a good answer.
  const { checks } = score(reply(
    'TEXT: 「焼け石に水」は、小さな努力では大きな問題を解決できないという意味です。',
    'READING: yakeishi ni mizu wa, chiisana doryoku dewa ookina mondai o kaiketsu dekinai to iu imi desu.',
    'TRANS: “杯水车薪”的意思是，微小的努力无法解决大问题。',
    'GRAMMAR: 1. 意思:\n - 比喻力量微小，无济于事。\n'
      + '2. 句型:\n - 「〜という意味です」用来解释词语的含义。\n'
      + '3. 试着换一下:\n - 「ありがとう」は、感謝を伝える言葉という意味です。',
  ), { targetCode: 'ja', nativeCode: 'zh', needsReading: true });
  assert.equal(checks.nativeScript, true);
  assert.equal(checks.usable, true);
});

test('an explanation actually written in the target language still fails', () => {
  // The exclusion must not blind the gate: here the Chinese speaker is given
  // an explanation in Japanese, which is the failure the check exists for.
  const { checks } = score(reply(
    'TEXT: 「焼け石に水」は、効果がないという意味です。',
    'READING: yakeishi ni mizu wa, kouka ga nai to iu imi desu.',
    'TRANS: 没有效果的意思。',
    'GRAMMAR: この表現は、努力が小さすぎて役に立たないときに使います。'
      + 'たとえば、大きな問題に対して小さな助けしかないときです。',
  ), { targetCode: 'ja', nativeCode: 'zh', needsReading: true });
  assert.equal(checks.nativeScript, false);
  assert.equal(checks.usable, false);
});
