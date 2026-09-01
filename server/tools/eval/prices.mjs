/**
 * Checks `src/pricing.js` against what OpenRouter is charging today.
 *
 * `npm run eval:prices` has been referenced in three places since the eval was
 * written — the price table, the README, the report footer — and never
 * existed, which is roughly why the table drifted. The prices are the input to
 * two decisions that both go wrong quietly when they are stale: which model to
 * ship, and when the daily budget ceiling has been reached.
 *
 * Usage:
 *   npm run eval:prices              # report drift, change nothing
 *   npm run eval:prices -- --write   # apply live prices to src/pricing.js
 *
 * No API key needed; the models endpoint is public. Reads `cached` from
 * `input_cache_read`, which is what a cache hit actually bills at.
 */
import { readFile, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { PRICES } from '../../src/pricing.js';

const HERE = dirname(fileURLToPath(import.meta.url));
const PRICING_FILE = join(HERE, '..', '..', 'src', 'pricing.js');
const ENDPOINT = 'https://openrouter.ai/api/v1/models';

/** Per-million, from OpenRouter's per-token strings. */
function perMillion(value) {
  const n = Number(value);
  return Number.isFinite(n) ? n * 1e6 : null;
}

/** Trailing zeros dropped, so the file keeps reading like something a human wrote. */
function fmt(n) {
  return String(Number(n.toFixed(6)));
}

async function main() {
  const write = process.argv.includes('--write');

  const res = await fetch(ENDPOINT);
  if (!res.ok) {
    console.error(`OpenRouter returned ${res.status}. Prices unchanged.`);
    process.exit(1);
  }
  const { data } = await res.json();
  const live = new Map(data.map((m) => [m.id, m]));

  const rows = [];
  for (const [id, onFile] of Object.entries(PRICES)) {
    const model = live.get(id);
    if (!model) {
      rows.push({ id, status: 'delisted', onFile });
      continue;
    }
    const fresh = {
      in: perMillion(model.pricing?.prompt),
      out: perMillion(model.pricing?.completion),
      cached: perMillion(model.pricing?.input_cache_read) ?? onFile.cached,
    };
    if (fresh.in == null || fresh.out == null) {
      rows.push({ id, status: 'unpriced', onFile });
      continue;
    }
    const moved = ['in', 'out', 'cached'].some(
      (k) => Math.abs(fresh[k] - onFile[k]) > 1e-6,
    );
    rows.push({ id, status: moved ? 'drift' : 'ok', onFile, fresh });
  }

  const drifted = rows.filter((r) => r.status === 'drift');
  const missing = rows.filter((r) => r.status !== 'drift' && r.status !== 'ok');

  console.log(`Checked ${rows.length} models against ${ENDPOINT}\n`);
  for (const r of rows.filter((x) => x.status === 'ok')) {
    console.log(`  ok      ${r.id}`);
  }
  for (const r of drifted) {
    const pct = (k) => {
      const change = ((r.fresh[k] - r.onFile[k]) / r.onFile[k]) * 100;
      return `${change > 0 ? '+' : ''}${change.toFixed(0)}%`;
    };
    console.log(
      `  DRIFT   ${r.id}\n` +
      `            in  ${r.onFile.in} -> ${fmt(r.fresh.in)} (${pct('in')})\n` +
      `            out ${r.onFile.out} -> ${fmt(r.fresh.out)} (${pct('out')})`,
    );
  }
  for (const r of missing) {
    console.log(`  ${r.status.toUpperCase().padEnd(7)} ${r.id} — left as-is, verify by hand`);
  }

  if (!drifted.length) {
    console.log('\nEverything on file matches. Nothing to do.');
    return;
  }

  if (!write) {
    console.log(
      `\n${drifted.length} model(s) have moved. Re-run with --write to apply, ` +
      'then re-read any decision that was made on the old numbers.',
    );
    // Non-zero so CI can treat stale prices as a failure without parsing stdout.
    process.exitCode = 1;
    return;
  }

  let source = await readFile(PRICING_FILE, 'utf8');
  for (const r of drifted) {
    // Rewrites values in place rather than regenerating the object, so the
    // comments explaining why each row is there survive.
    const pattern = new RegExp(
      `(^\\s*'${r.id.replace(/[.*+?^\${}()|[\\]\\\\]/g, '\\\\$&')}':\\s*\\{ in: )` +
      '([\\d.]+)(, out: )([\\d.]+)(, cached: )([\\d.]+)( \\},)',
      'm',
    );
    if (!pattern.test(source)) {
      console.error(`  could not locate the row for ${r.id}; apply it by hand`);
      continue;
    }
    source = source.replace(
      pattern,
      `$1${fmt(r.fresh.in)}$3${fmt(r.fresh.out)}$5${fmt(r.fresh.cached)}$7`,
    );
  }

  const today = new Date().toISOString().slice(0, 10);
  source = source.replace(
    /Snapshot taken \d{4}-\d{2}-\d{2}/,
    `Snapshot taken ${today}`,
  );

  await writeFile(PRICING_FILE, source);
  console.log(`\nUpdated src/pricing.js and stamped the snapshot ${today}.`);
  console.log('Re-run `npm test` — the eval-report check will fail if a shipped price moved.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
