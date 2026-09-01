/**
 * Token prices, and the one place they are written down.
 *
 * Used for two different jobs that must agree: `tools/eval` costs a candidate
 * model before it is adopted, and `limits.js` costs live traffic against the
 * daily ceiling. Two tables would drift, and the direction of the drift is a
 * ceiling that does not hold.
 *
 * Snapshot taken 2026-08-30 from https://openrouter.ai/api/v1/models — refresh
 * with `npm run eval:prices` before trusting a cost figure. Promotional rates
 * expire, and a stale price here makes the budget ceiling wrong rather than
 * merely out of date.
 */

/** USD per million tokens, keyed by OpenRouter slug. */
export const PRICES = {
  // The 2.5 family is closed to new API keys — generateContent returns 404
  // pointing at a 3.x replacement, even though the models still appear in the
  // models listing. Kept here only so an existing-key deployment can be costed.
  'google/gemini-2.5-flash': { in: 0.30, out: 2.50, cached: 0.030 },
  'google/gemini-2.5-flash-lite': { in: 0.10, out: 0.40, cached: 0.010 },
  'google/gemini-3.7-flash': { in: 0.75, out: 3.75, cached: 0.075 },
  'google/gemini-3.6-flash': { in: 0.75, out: 3.75, cached: 0.075 },
  'google/gemini-3.5-flash-lite': { in: 0.30, out: 2.50, cached: 0.030 },
  'google/gemini-3.1-flash-lite': { in: 0.25, out: 1.50, cached: 0.025 },
  'google/gemini-3-flash-preview': { in: 0.50, out: 3.00, cached: 0.050 },
  'deepseek/deepseek-v4-flash': { in: 0.0812, out: 0.1624, cached: 0.01624 },
  'deepseek/deepseek-v4-flash-0731': { in: 0.065, out: 0.18, cached: 0.016 },
  'deepseek/deepseek-v4-pro': { in: 0.51852, out: 1.03704, cached: 0.04321 },
  'tencent/hy3': { in: 0.132, out: 0.528, cached: 0.033 },

  // Screened 2026-08-30 against the tutor prompt; see tools/eval/results/archive.
  'google/gemma-4-31b-it': { in: 0.09, out: 0.34, cached: 0.05 },
  'google/gemma-4-26b-a4b-it': { in: 0.07, out: 0.34, cached: 0.07 },
  'nvidia/nemotron-3-super-120b-a12b': { in: 0.085, out: 0.4, cached: 0.085 },
  'qwen/qwen3.7-flash': { in: 0.03, out: 0.13, cached: 0.006 },
  'qwen/qwen3.5-flash-02-23': { in: 0.065, out: 0.26, cached: 0.065 },
  'z-ai/glm-5.3-flash': { in: 0.075, out: 0.25, cached: 0.015 },
  'mistralai/mistral-small-3.2-24b-instruct': { in: 0.075, out: 0.2, cached: 0.075 },
  'openai/gpt-5-nano': { in: 0.05, out: 0.4, cached: 0.005 },
  'openai/gpt-4.1-nano': { in: 0.1, out: 0.4, cached: 0.03 },
  'qwen/qwen3-235b-a22b-2507': { in: 0.0875, out: 0.35, cached: 0.0175 },
  'bytedance-seed/seed-2.0-mini': { in: 0.1, out: 0.4, cached: 0.1 },
  'minimax/minimax-m3': { in: 0.3, out: 1.2, cached: 0.06 },
  'minimax/minimax-m2.7': { in: 0.3, out: 1.2, cached: 0.06 },
};

/**
 * Vendor prefixes tried when resolving a bare model id.
 *
 * The table is keyed by OpenRouter slug because that is what the eval speaks,
 * but this service speaks the provider's own id — `gemini-3.1-flash-lite`, not
 * `google/gemini-3.1-flash-lite`. Rather than duplicate every row, resolution
 * tries the bare key first and then each vendor prefix.
 */
const VENDORS = ['google', 'deepseek', 'tencent'];

/**
 * The most expensive row in the table, used as the price of an unknown model.
 *
 * Unknown must never cost zero. A model absent from this table is most likely
 * one added to ALLOWED_MODELS without updating the prices, and pricing that at
 * zero would mean the budget ceiling silently stopped applying to exactly the
 * model nobody has costed yet. Charging it the worst rate on file fails in the
 * direction that protects the bill.
 */
const WORST = Object.values(PRICES).reduce(
  (worst, p) => (p.out > worst.out ? p : worst),
  { in: 0, out: 0, cached: 0 },
);

/** Price row for a model, by slug or bare id. Null when it is not on file. */
export function priceFor(model) {
  if (typeof model !== 'string' || !model) return null;
  if (PRICES[model]) return PRICES[model];
  for (const vendor of VENDORS) {
    const hit = PRICES[`${vendor}/${model}`];
    if (hit) return hit;
  }
  return null;
}

/**
 * Cost in USD of one call.
 *
 * [strict] is what separates the two callers. The eval reports a null cost for
 * an unpriced model, because a blank cell is honest. The budget ceiling cannot
 * afford that answer and passes strict:false, taking [WORST] instead.
 */
export function costOf(model, usage, { strict = true } = {}) {
  if (!usage) return null;
  const price = priceFor(model) ?? (strict ? null : WORST);
  if (!price) return null;
  const input = Number(usage.inputTokens) || 0;
  const output = Number(usage.outputTokens) || 0;
  const cached = Number(usage.cachedInputTokens) || 0;
  return (
    ((input - cached) * price.in + cached * price.cached + output * price.out) / 1e6
  );
}
