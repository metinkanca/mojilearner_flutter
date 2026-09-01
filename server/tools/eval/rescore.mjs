/**
 * Re-score saved replies with the current scorers.
 *
 * A scorer change is a change to every conclusion the harness has ever
 * reached, and the old reports do not know that. When `nativeScript` was fixed
 * to stop counting quoted Japanese against a Chinese explanation, the question
 * "does that move anything we already decided?" had no cheap answer — the
 * results were archived as rendered Markdown, and re-running the models to
 * find out costs money and returns different samples anyway.
 *
 * It does not have to. Every run archives `raw.json` with the full reply text,
 * so the replies can be scored again for free. This walks the archive, applies
 * today's scorers to yesterday's replies, and reports only what changed.
 *
 * Usage:
 *   node tools/eval/rescore.mjs                 # results/ and everything in archive/
 *   node tools/eval/rescore.mjs results/archive/2026-08-30-matrix-fixed-prompt
 */
import { readFile, readdir } from 'node:fs/promises';
import { dirname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import { needsReading } from './prompt.mjs';
import { score, scoreKnownAnswer } from './scorers.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));

const CASE_FILES = ['cases.json', 'cases-offtopic.json', 'cases-idioms.json'];

/**
 * caseId -> case definition, across every case file.
 *
 * Scoring needs the language pair, which `raw.json` does not carry — it stores
 * the reply and the verdict, not the question. Ids are unique across the files
 * by convention (`ja-tr-greeting`, `offtopic-*`, `idiom-*`), and a collision
 * would be a bug in the case sets rather than something to paper over here.
 */
async function loadCases() {
  const byId = new Map();
  for (const file of CASE_FILES) {
    let cases;
    try {
      cases = JSON.parse(await readFile(join(HERE, file), 'utf8'));
    } catch {
      continue; // a case file may not exist in every checkout
    }
    for (const c of cases) {
      if (byId.has(c.id)) throw new Error(`duplicate case id across case files: ${c.id}`);
      byId.set(c.id, c);
    }
  }
  return byId;
}

/** The verdicts worth reporting a change in. Everything else is a measurement. */
const VERDICTS = ['usable', 'format', 'targetScript', 'targetLanguage', 'readingRomanized', 'nativeScript', 'persona'];

const show = (v) => (v === null ? 'n/a' : String(v));

async function rescoreRun(dir, cases) {
  let rows;
  try {
    rows = JSON.parse(await readFile(join(dir, 'raw.json'), 'utf8'));
  } catch {
    return null;
  }

  const changes = [];
  let scored = 0;
  const unknownCases = new Set();

  for (const row of rows) {
    if (row.error || !row.text) continue;
    const c = cases.get(row.caseId);
    if (!c) { unknownCases.add(row.caseId); continue; }
    scored += 1;

    const { sections, checks } = score(row.text, {
      targetCode: c.targetCode,
      nativeCode: c.nativeCode,
      needsReading: needsReading(c.targetCode),
    });

    for (const key of VERDICTS) {
      const before = row.checks?.[key];
      const after = checks[key];
      // `undefined` before means the check did not exist when the run was
      // saved, which is a new check rather than a changed verdict.
      if (before === undefined || before === after) continue;
      changes.push({ caseId: row.caseId, label: row.label, key, before, after });
    }

    // A known-answer verdict can move too, when a term list is widened.
    const knownBefore = row.known?.meaningHit;
    if (knownBefore !== undefined) {
      const knownAfter = scoreKnownAnswer(sections, c.expect)?.meaningHit;
      if (knownBefore !== knownAfter) {
        changes.push({ caseId: row.caseId, label: row.label, key: 'meaningHit', before: knownBefore, after: knownAfter });
      }
    }
  }

  return { scored, changes, unknownCases: [...unknownCases] };
}

async function main() {
  const cases = await loadCases();
  const args = process.argv.slice(2);

  let dirs = args;
  if (!dirs.length) {
    const archive = join(HERE, 'results', 'archive');
    const entries = await readdir(archive, { withFileTypes: true }).catch(() => []);
    dirs = [join(HERE, 'results'), ...entries.filter((e) => e.isDirectory()).map((e) => join(archive, e.name))];
  }

  let totalScored = 0;
  let totalChanged = 0;

  for (const dir of dirs) {
    const result = await rescoreRun(dir, cases);
    const name = relative(HERE, dir) || dir;
    if (!result) { console.log(`${name}: no raw.json`); continue; }

    totalScored += result.scored;
    totalChanged += result.changes.length;

    if (!result.changes.length) {
      console.log(`${name}: ${result.scored} replies, no verdict changed`);
    } else {
      console.log(`\n${name}: ${result.scored} replies, ${result.changes.length} verdict(s) changed`);
      for (const ch of result.changes) {
        console.log(`  ${ch.caseId} · ${ch.label} · ${ch.key}: ${show(ch.before)} -> ${show(ch.after)}`);
      }
      console.log('');
    }
    if (result.unknownCases.length) {
      console.log(`  (${result.unknownCases.length} case id(s) no longer in any case file: ${result.unknownCases.join(', ')})`);
    }
  }

  console.log(`\n${totalScored} replies re-scored, ${totalChanged} verdict(s) changed.`);
  if (totalChanged) {
    console.log('Each change is a past conclusion the current scorers would have reached differently.');
    console.log('Read the reply in that run\'s raw.json before deciding which verdict was right.');
  }
}

main().catch((err) => { console.error(err); process.exit(1); });
