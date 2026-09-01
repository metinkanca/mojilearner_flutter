/**
 * Head-to-head model comparison for the tutor prompt.
 *
 * Produces two things, because the question has two halves:
 *
 *   report.md   what a machine can decide — format compliance, script
 *               correctness, cost, latency. A model that loses here is
 *               disqualified and no human needs to look at it.
 *
 *   blind.md    what a machine cannot decide — whether the Japanese is
 *               natural and the grammar explanation is true. Model identities
 *               are hidden behind A/B labels, shuffled per case, with the key
 *               written to blind-key.json so you can rate without knowing
 *               which is the cheap one.
 *
 * Usage:
 *   OPENROUTER_API_KEY=... GEMINI_API_KEY=... node tools/eval/run.mjs
 *   node tools/eval/run.mjs --models google/gemini-2.5-flash,deepseek/deepseek-v4-flash
 *   node tools/eval/run.mjs --repeat 3     # sample variance, not one lucky roll
 */
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildSystemInstruction, needsReading } from './prompt.mjs';
import { callModel, costOf, PRICES } from './providers.mjs';
import { score, scoreKnownAnswer } from './scorers.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));

/**
 * Where a run writes.
 *
 * `--mock` goes to a subdirectory because it used to land on top of a real
 * run's output, and did: a mock run to check the harness silently replaced a
 * genuine 16-case result with synthetic garbage. Results are gitignored, so
 * there was nothing to recover. Separate directories make that unrepeatable.
 */
function outputDir(mock) {
  return join(HERE, 'results', mock ? 'mock' : '');
}

/**
 * Three models, because the real choice is three-way and framing it as
 * Gemini-vs-DeepSeek hides the middle option.
 *
 * Flash Lite captures most of the saving without leaving the Gemini family,
 * which means keeping image and audio input (the speaking-practice roadmap),
 * the sub-second first token, and the existing integration. DeepSeek is
 * cheaper still, but pays for it in latency and is text-only.
 */
const DEFAULT_MODELS = [
  { model: 'google/gemini-3.1-flash-lite', provider: 'gemini', label: 'gemini-3.1-flash-lite (current)' },
  { model: 'google/gemini-3.7-flash', provider: 'gemini', label: 'gemini-3.7-flash' },
  { model: 'deepseek/deepseek-v4-flash', provider: 'openrouter', label: 'deepseek-v4-flash' },
];

/**
 * Canned replies for `--mock`, so the harness can be exercised — and the
 * scorers seen firing — without an API key or a cent of spend. One model
 * behaves, the other exhibits the failure modes this eval exists to catch.
 */
function mockCall({ model }, testCase) {
  const good = model.includes('gemini');
  const reading = testCase.needsReading ? '\nREADING: konnichiwa' : '';

  // On a known-answer case the canned replies are built from the case's own
  // expectations: the good model states the meaning, the bad one offers the
  // literal reading instead. Without this a `--mock --cases cases-idioms.json`
  // run exercises the plumbing but never fires the scorer it exists to check.
  const gloss = testCase.expect
    ? (good
        ? testCase.expect.anyOf.map((group) => group[0]).join(' and ')
        : (testCase.expect.notLiteralOnly?.[0] ?? 'no idea'))
    : null;

  const text = good
    ? `TEXT: ${testCase.targetCode === 'ja' ? 'こんにちは、元気ですか？' : 'Hola, ¿cómo estás?'}${reading}`
      + `\nTRANS: Hello, how are you?\nGRAMMAR: 1. Meaning:\n - ${gloss ?? 'A everyday greeting.'}`
    : `TEXT: Hello, how are you?${reading}\nTRANS: Hello\n`
      + `GRAMMAR: ${gloss ?? 'This is the greeting and it is used to say hello to a person that you meet.'}`;
  return Promise.resolve({
    text,
    usage: { inputTokens: 850, outputTokens: good ? 420 : 180, reasoningTokens: good ? 120 : 0 },
    latencyMs: good ? 1400 : 700,
  });
}

/**
 * Which ids the Google adapter can actually serve.
 *
 * Not simply `google/`: that vendor prefix covers Gemma too, and Gemma is not
 * on the Gemini API — asking for `google/gemma-4-31b-it:free` there returns a
 * flat 404 for every case, which reads like the model failing rather than like
 * a request sent to the wrong place. The `:free` and `:batch` suffixes are
 * OpenRouter routing variants and never valid upstream either.
 */
const GEMINI_DIRECT = /^google\/gemini-[^:]+$/;

function parseArgs(argv) {
  const get = (flag, fallback) => {
    const i = argv.indexOf(flag);
    return i === -1 ? fallback : argv[i + 1];
  };
  const models = get('--models', null);
  return {
    repeat: Number(get('--repeat', 1)),
    only: get('--only', null),
    mock: argv.includes('--mock'),
    // Alternate case file, so a focused set (adversarial drift, idioms) can be
    // run without diluting it into the 16-case language matrix.
    cases: get('--cases', 'cases.json'),
    // Free-tier keys throttle at single-digit requests per minute. Pacing the
    // run is cheaper than leaning on the retry backoff for every call.
    delayMs: Number(get('--delay', 0)),
    models: models
      ? models.split(',').map((raw) => {
          // `openrouter:<id>` / `gemini:<id>` overrides the heuristic below.
          // Needed because the two routes do not serve the same catalogue:
          // Gemini 2.5 is closed to new API keys and 404s upstream, but
          // OpenRouter reaches it through its own account. Without a way to
          // say which door to use, that model is simply untestable.
          const spec = raw.trim();
          const forced = /^(gemini|openrouter):(.+)$/.exec(spec);
          const model = forced ? forced[2].trim() : spec;
          const provider = forced
            ? forced[1]
            : (GEMINI_DIRECT.test(model) ? 'gemini' : 'openrouter');
          return {
            model,
            provider,
            label: forced ? `${model} (via ${provider})` : model,
          };
        })
      : DEFAULT_MODELS,
  };
}

const pct = (n, d) => (d === 0 ? '—' : `${Math.round((n / d) * 100)}%`);
const usd = (n) => (n == null ? '—' : `$${n.toFixed(6)}`);

async function main() {
  const args = parseArgs(process.argv.slice(2));
  let cases = JSON.parse(await readFile(join(HERE, args.cases), 'utf8'));
  if (args.only) cases = cases.filter((c) => c.id.includes(args.only));

  console.log(`${cases.length} cases x ${args.models.length} models x ${args.repeat} run(s)\n`);

  const rows = [];
  for (const c of cases) {
    const system = buildSystemInstruction({
      targetCode: c.targetCode,
      nativeCode: c.nativeCode,
      scenario: c.scenario ?? null,
    });
    const testCase = { ...c, needsReading: needsReading(c.targetCode) };

    for (const spec of args.models) {
      for (let run = 0; run < args.repeat; run += 1) {
        process.stdout.write(`  ${c.id} · ${spec.label} … `);
        try {
          const r = args.mock
            ? await mockCall(spec, testCase)
            : await callModel({ ...spec, system, user: c.user });
          const { sections, checks } = score(r.text, testCase);
          // Only idiom cases carry `expect`; everything else scores null and
          // the known-answer columns stay out of the report entirely.
          const known = scoreKnownAnswer(sections, c.expect);
          rows.push({
            caseId: c.id, idiom: c.idiom, model: spec.model, label: spec.label, run,
            text: r.text, sections, checks, known,
            usage: r.usage, latencyMs: r.latencyMs,
            cost: costOf(spec.model, r.usage),
          });
          const form = checks.usable ? `ok ${r.latencyMs}ms` : `UNUSABLE ${r.latencyMs}ms`;
          const meaning = !known ? ''
            : known.meaningHit ? ' · meaning ok'
            : known.literalOnly ? ' · MEANING literal'
            : ' · MEANING missed';
          console.log(form + meaning);
          if (args.delayMs) await new Promise((res) => setTimeout(res, args.delayMs));
        } catch (err) {
          rows.push({ caseId: c.id, model: spec.model, label: spec.label, run, error: String(err.message) });
          console.log(`ERROR ${err.message}`);
        }
      }
    }
  }

  const OUT = outputDir(args.mock);
  await mkdir(OUT, { recursive: true });
  await writeFile(join(OUT, 'raw.json'), JSON.stringify(rows, null, 2));
  await writeFile(join(OUT, 'report.md'), buildReport(rows, args));
  const { blind, key } = buildBlind(rows, cases);
  await writeFile(join(OUT, 'blind.md'), blind);
  await writeFile(join(OUT, 'blind-key.json'), JSON.stringify(key, null, 2));

  console.log(`\nWrote ${OUT}/report.md, blind.md, blind-key.json, raw.json`);
  console.log(summaryLine(rows, args));
}

function buildReport(rows, args) {
  const out = ['# Model evaluation', '', `Run ${new Date().toISOString()} · ${args.repeat} sample(s) per case.`, ''];

  // The known-answer column only exists for case files that carry `expect`,
  // so the language-matrix report is unchanged by any of this.
  const hasKnown = rows.some((x) => x.known);
  const meaningHead = hasKnown ? ' Meaning |' : '';
  const meaningRule = hasKnown ? '---|' : '';

  out.push('## Summary', '', `| Model | Usable |${meaningHead} Format | Target script | Native lang | Persona | Median latency | Cost / 1k turns |`, `|---|---|${meaningRule}---|---|---|---|---|---|`);
  for (const spec of args.models) {
    const r = rows.filter((x) => x.model === spec.model && !x.error);
    const n = r.length || 1;
    const lat = r.map((x) => x.latencyMs).sort((a, b) => a - b)[Math.floor(r.length / 2)] ?? 0;
    const avgCost = r.reduce((s, x) => s + (x.cost ?? 0), 0) / n;
    const withKnown = r.filter((x) => x.known);
    out.push(`| ${spec.label} | ${pct(r.filter((x) => x.checks.usable).length, n)} `
      + (hasKnown ? `| ${pct(withKnown.filter((x) => x.known.meaningHit).length, withKnown.length)} ` : '')
      + `| ${pct(r.filter((x) => x.checks.format).length, n)} `
      + `| ${pct(r.filter((x) => x.checks.targetScript !== false).length, n)} `
      + `| ${pct(r.filter((x) => !x.checks.englishLeakage && x.checks.nativeScript !== false).length, n)} `
      + `| ${pct(r.filter((x) => x.checks.persona).length, n)} `
      + `| ${lat}ms | ${usd(avgCost * 1000)} |`);
  }

  if (hasKnown) out.push(...knownAnswerSection(rows));

  out.push('', '## Failures', '');
  const bad = rows.filter((x) => x.error || !x.checks?.usable);
  if (!bad.length) out.push('_None — every reply was parseable and in the right languages._');
  for (const x of bad) {
    const why = x.error
      ? `error: ${x.error}`
      : [
          x.checks.missingSections.length ? `missing ${x.checks.missingSections.join('/')}` : null,
          x.checks.targetScript === false ? `wrong script (${(x.checks.targetScriptRatio * 100).toFixed(0)}% target)` : null,
          x.checks.nativeScript === false ? 'explanation not in native script' : null,
          !x.checks.persona ? 'leaked instructions' : null,
        ].filter(Boolean).join(', ');
    out.push(`- **${x.caseId}** · ${x.label} — ${why}`);
  }

  out.push('', '## Per-case detail', '', '| Case | Model | Usable | Target ratio | EN leak | Words | In | Out | Latency | Cost |', '|---|---|---|---|---|---|---|---|---|---|');
  for (const x of rows.filter((r) => !r.error)) {
    out.push(`| ${x.caseId} | ${x.label} | ${x.checks.usable ? '✓' : '✗'} `
      + `| ${x.checks.targetScriptRatio == null ? '—' : x.checks.targetScriptRatio.toFixed(2)} `
      + `| ${x.checks.englishLeakage ? 'yes' : 'no'} | ${x.checks.textWords} `
      + `| ${x.usage.inputTokens} | ${x.usage.outputTokens} | ${x.latencyMs}ms | ${usd(x.cost)} |`);
  }

  out.push('', '## Prices used', '', '| Model | In /M | Out /M |', '|---|---|---|');
  for (const spec of args.models) {
    const p = PRICES[spec.model];
    out.push(`| ${spec.model} | ${p ? `$${p.in}` : '—'} | ${p ? `$${p.out}` : '—'} |`);
  }
  out.push('', '_Prices as last refreshed by `npm run eval:prices`. Promotional rates expire; re-check before deciding._');
  return out.join('\n');
}

/**
 * The half a machine cannot judge.
 *
 * Identities are shuffled per case rather than per file, so a rater who works
 * out one case learns nothing about the next.
 */
function buildBlind(rows, cases) {
  const out = ['# Blind comparison', '',
    'Rate each pair without knowing which model produced which. For every case pick a winner on:',
    '', '1. **Naturalness** — would a native speaker actually say the TEXT line?',
    '2. **Correctness** — is the GRAMMAR explanation true, and in the right language?',
    '3. **Usefulness** — could the learner reuse the pattern tomorrow?',
    '', 'The key is in `blind-key.json`. Do not open it until you have rated every case.', ''];
  const key = {};

  for (const c of cases) {
    const replies = rows.filter((r) => r.caseId === c.id && !r.error && r.run === 0);
    if (replies.length < 2) continue;
    const shuffled = [...replies].sort(() => Math.random() - 0.5);
    key[c.id] = shuffled.map((r, i) => ({ label: String.fromCharCode(65 + i), model: r.model }));

    out.push(`## ${c.id}`, '', `_${c.note}_`, '',
      `**${c.nativeLang} speaker learning ${c.targetLang}**`
      + (c.scenario ? ` · scenario: ${c.scenario}` : ''), '',
      `> ${c.user}`, '');
    shuffled.forEach((r, i) => {
      out.push(`### ${String.fromCharCode(65 + i)}`, '', '```', r.text.trim(), '```', '');
    });
    out.push('Winner: ____   Notes: ____', '', '---', '');
  }
  return { blind: out.join('\n'), key };
}

/**
 * What the model actually taught, for the cases where there is a right answer.
 *
 * Split by whether the reply reached for the literal reading, because those
 * are different failures with different fixes: a missed meaning is a model
 * that does not know the idiom, while a literal one is a model that thinks it
 * does. The second is worse in an app — it is fluent, confident and wrong,
 * and a learner has no way to tell.
 */
function knownAnswerSection(rows) {
  const out = ['', '## Known answers', '',
    'Idiom cases only. `Meaning` is whether the reply reached the learner with',
    'what the idiom actually means, in the language they read.', '',
    '| Case | Idiom | Model | Meaning | Landed on the literal reading | Matched |',
    '|---|---|---|---|---|---|'];
  for (const x of rows.filter((r) => r.known)) {
    out.push(`| ${x.caseId} | ${x.idiom ?? ''} | ${x.label} `
      + `| ${x.known.meaningHit ? '✓' : '✗'} `
      + `| ${x.known.literalOnly ? 'yes — ' + x.known.literalMatched.join(', ') : 'no'} `
      + `| ${x.known.matchedTerms.slice(0, 3).join(', ') || '—'} |`);
  }
  return out;
}

function summaryLine(rows, args) {
  return args.models.map((spec) => {
    const r = rows.filter((x) => x.model === spec.model && !x.error);
    const usable = r.filter((x) => x.checks.usable).length;
    const known = r.filter((x) => x.known);
    const meaning = known.length
      ? `, ${known.filter((x) => x.known.meaningHit).length}/${known.length} meanings right`
      : '';
    return `${spec.label}: ${usable}/${r.length} usable${meaning}`;
  }).join('  |  ');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
