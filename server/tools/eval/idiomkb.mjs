/**
 * IdiomKB as a *candidate source*, not as an answer key.
 *
 * IdiomKB (AAAI 2024, https://github.com/lisd0929/IdiomKB) ships 12,903
 * idioms across English, Chinese and Japanese, each with a gloss in all three
 * languages. That is the right shape for a known-answer eval: an idiom is the
 * sharpest test of a tutor, because the literal reading of one is confidently,
 * fluently wrong.
 *
 * It cannot be used as the key directly. Its own README says the glosses were
 * distilled from `gpt-3.5-turbo-0613`, and the Japanese set has inherited that
 * model's failure mode wholesale: `鯖を読む` (to fudge a number) is glossed
 * "to read the room", `一杯食う` (to be taken in) as "to eat a lot",
 * `首が回らない` (to be up to one's neck in debt) as "lack of flexibility".
 * Scoring a model against those would penalise it for being right — an eval
 * that selects for the weaker model is worse than no eval.
 *
 * So this module does the mechanical half: load, validate, and surface
 * candidates. The semantic half — deciding what each idiom actually means —
 * is done by hand and lives in `cases-idioms.json`, where every case records
 * the IdiomKB gloss alongside the verified one so a reviewer can check the
 * call rather than take it on trust.
 *
 * CLI:
 *   node tools/eval/idiomkb.mjs --dir <path>              # validation report
 *   node tools/eval/idiomkb.mjs --dir <path> --lang ja --sample 40
 *   node tools/eval/idiomkb.mjs --dir <path> --lang ja --find 足元
 */
import { readFile } from 'node:fs/promises';
import { join } from 'node:path';

export const LANGS = ['en', 'ja', 'zh'];

/** Scripts each meaning field must be written in to count as that language. */
const HAN = /[\u4e00-\u9fff]/u;
const KANA = /[\u3040-\u30ff]/u;
const LATIN = /[A-Za-z]/u;

const JAPANESE = (s) => KANA.test(s) || HAN.test(s);

/** Share of letter-like characters that are Latin. Punctuation and digits are
 *  excluded so a gloss like `"相生相克" (Sōsei sōkoku)` is measured on its
 *  letters rather than on its quotation marks. */
function latinShare(s) {
  const letters = [...(s ?? '')].filter((c) => LATIN.test(c) || HAN.test(c) || KANA.test(c));
  if (!letters.length) return 0;
  return letters.filter((c) => LATIN.test(c)).length / letters.length;
}

/**
 * Everything mechanically wrong with one entry.
 *
 * Deliberately only mechanical. "This gloss is the wrong meaning" is the
 * commonest defect in the set and none of these checks can see it — that is
 * what the hand-verification step in `cases-idioms.json` is for, and pretending
 * otherwise here would be the whole trap this module exists to avoid.
 */
export function validateEntry(row) {
  const problems = [];
  const need = ['idiom', 'en_meaning', 'zh_meaning', 'ja_meaning'];
  for (const k of need) {
    if (!row[k] || !String(row[k]).trim()) problems.push(`${k} missing`);
  }
  if (problems.length) return { ok: false, problems };

  // A failed generation left literally the string "error" in 11 rows.
  for (const k of need.slice(1)) {
    if (/^\s*error\s*$/i.test(row[k])) problems.push(`${k} is a generation error`);
  }

  // Field contamination: a meaning written in the wrong language. The Japanese
  // field is the usual offender — it holds English for 25 entries across the
  // three files, which would hand a Chinese-native learner an English answer.
  if (!JAPANESE(row.ja_meaning)) problems.push('ja_meaning not in Japanese');
  else if (latinShare(row.ja_meaning) > 0.5) problems.push('ja_meaning mostly Latin');
  if (!HAN.test(row.zh_meaning)) problems.push('zh_meaning not in Chinese');
  if (KANA.test(row.en_meaning)) problems.push('en_meaning contains kana');

  // A gloss that only repeats the idiom (sometimes with a romanization) has
  // defined nothing. `"相生相克" (Sōsei sōkoku)` is the shape.
  for (const k of ['en_meaning', 'ja_meaning', 'zh_meaning']) {
    const stripped = String(row[k]).replace(row.idiom, '').replace(/[\s"'“”「」()（）.,、。]/gu, '');
    if (stripped.length < 4) problems.push(`${k} restates the idiom`);
  }

  return { ok: problems.length === 0, problems };
}

export async function loadIdiomKB(dir) {
  const out = {};
  for (const lang of LANGS) {
    out[lang] = JSON.parse(await readFile(join(dir, `${lang}_idiom_meaning.json`), 'utf8'));
  }
  return out;
}

function parseArgs(argv) {
  const get = (flag, fallback) => {
    const i = argv.indexOf(flag);
    return i === -1 ? fallback : argv[i + 1];
  };
  return {
    dir: get('--dir', process.env.IDIOMKB_DIR ?? null),
    lang: get('--lang', null),
    sample: get('--sample', null),
    find: get('--find', null),
  };
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (!args.dir) {
    console.error('Point at a checkout of https://github.com/lisd0929/IdiomKB:');
    console.error('  node tools/eval/idiomkb.mjs --dir /path/to/IdiomKB/data');
    console.error('  (or set IDIOMKB_DIR)');
    process.exit(2);
  }
  const kb = await loadIdiomKB(args.dir);

  if (args.find || args.sample) {
    const rows = kb[args.lang ?? 'ja'];
    const picked = args.find
      ? rows.filter((r) => r.idiom.includes(args.find))
      : rows.slice(0, Number(args.sample));
    for (const r of picked) console.log(JSON.stringify(r));
    return;
  }

  console.log('# IdiomKB validation\n');
  console.log('| File | Entries | Duplicate idioms | Entries with problems |');
  console.log('|---|---|---|---|');
  const allProblems = new Map();
  for (const lang of LANGS) {
    const rows = kb[lang];
    const dups = rows.length - new Set(rows.map((r) => r.idiom)).size;
    let bad = 0;
    for (const r of rows) {
      const { ok, problems } = validateEntry(r);
      if (ok) continue;
      bad += 1;
      for (const p of problems) allProblems.set(p, (allProblems.get(p) ?? 0) + 1);
    }
    console.log(`| ${lang}_idiom_meaning.json | ${rows.length} | ${dups} | ${bad} |`);
  }

  console.log('\n| Problem | Entries |\n|---|---|');
  for (const [p, n] of [...allProblems].sort((a, b) => b[1] - a[1])) {
    console.log(`| ${p} | ${n} |`);
  }

  console.log('\nMechanical checks only. The commonest defect in this dataset —');
  console.log('a gloss that is simply the wrong meaning — is invisible here and is');
  console.log('why cases-idioms.json carries hand-verified answers instead.');
}

if (process.argv[1] && process.argv[1].endsWith('idiomkb.mjs')) {
  main().catch((err) => { console.error(err); process.exit(1); });
}
