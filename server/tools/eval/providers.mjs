/**
 * One call shape per API, so the runner can treat models as interchangeable.
 *
 * Two providers because the choice under evaluation is exactly this: keep
 * talking to Gemini directly, or route through OpenRouter to reach models
 * Google does not serve. Each adapter returns the same record so the scorers
 * and the cost table never learn which API produced a reply.
 */

/**
 * Prices and costing live in `src/pricing.js`, because the running service
 * needs the same numbers to hold its daily budget ceiling. Two tables would
 * drift, and the drift would show up as a ceiling that does not hold rather
 * than as a wrong number in a report.
 *
 * Re-exported here so this module stays the one import the runner needs.
 */
export { PRICES, costOf } from '../../src/pricing.js';

const timed = async (fn) => {
  const t0 = Date.now();
  const value = await fn();
  return { ...value, latencyMs: Date.now() - t0 };
};

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/**
 * POST with backoff on the two statuses that mean "ask again later".
 *
 * Free-tier keys rate-limit at single-digit requests per minute, so without
 * this a run of any size reports a model as broken when it was only throttled
 * — which would be the worst possible way to lose a model comparison.
 *
 * Note the retries are excluded from the caller's latency measurement: a p50
 * inflated by throttling would say nothing about the model.
 */
async function postWithRetry(url, init, { attempts = 4 } = {}) {
  let wait = 2000;
  for (let i = 0; i < attempts; i += 1) {
    const res = await fetch(url, init);
    if (res.status !== 429 && res.status !== 503) return res;
    if (i === attempts - 1) return res;
    const retryAfter = Number(res.headers.get('retry-after'));
    await sleep(Number.isFinite(retryAfter) && retryAfter > 0 ? retryAfter * 1000 : wait);
    wait *= 2;
  }
  throw new Error('unreachable');
}

/**
 * Gemini's own endpoint — the path the app uses today via `server/src/gemini.js`.
 * `thinkingBudget: 0` is the setting that matters commercially: Gemini bills
 * reasoning at the output rate, so leaving it unset is what makes the current
 * bill what it is.
 */
export async function callGemini({ model, system, user, apiKey, thinkingBudget = 0, maxOutputTokens = 1024 }) {
  const bare = model.replace(/^google\//, '');
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${bare}:generateContent?key=${apiKey}`;

  return timed(async () => {
    const res = await postWithRetry(url, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: system }] },
        contents: [{ role: 'user', parts: [{ text: user }] }],
        generationConfig: {
          temperature: 0.7,
          maxOutputTokens,
          ...(thinkingBudget === null ? {} : { thinkingConfig: { thinkingBudget } }),
        },
      }),
    });
    if (!res.ok) throw new Error(`gemini ${res.status}: ${(await res.text()).slice(0, 300)}`);
    const json = await res.json();
    const u = json.usageMetadata ?? {};
    return {
      text: (json.candidates?.[0]?.content?.parts ?? []).map((p) => p.text ?? '').join(''),
      usage: {
        inputTokens: u.promptTokenCount ?? 0,
        // Reasoning is billed as output, so it belongs in the output column
        // even though the API reports it separately.
        outputTokens: (u.candidatesTokenCount ?? 0) + (u.thoughtsTokenCount ?? 0),
        reasoningTokens: u.thoughtsTokenCount ?? 0,
      },
    };
  });
}

/** OpenRouter, OpenAI-shaped. Everything that is not Gemini goes through here. */
export async function callOpenRouter({ model, system, user, apiKey, maxOutputTokens = 1024, reasoningEffort = null }) {
  return timed(async () => {
    const res = await postWithRetry('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${apiKey}`,
        // OpenRouter attributes traffic by these; harmless and useful in the dashboard.
        'HTTP-Referer': 'https://mimikin.app',
        'X-Title': 'Mimikin model eval',
      },
      body: JSON.stringify({
        model,
        messages: [
          { role: 'system', content: system },
          { role: 'user', content: user },
        ],
        temperature: 0.7,
        max_tokens: maxOutputTokens,
        ...(reasoningEffort ? { reasoning: { effort: reasoningEffort } } : {}),
      }),
    });
    if (!res.ok) throw new Error(`openrouter ${res.status}: ${(await res.text()).slice(0, 300)}`);
    const json = await res.json();
    const u = json.usage ?? {};
    return {
      text: json.choices?.[0]?.message?.content ?? '',
      usage: {
        inputTokens: u.prompt_tokens ?? 0,
        outputTokens: u.completion_tokens ?? 0,
        reasoningTokens: u.completion_tokens_details?.reasoning_tokens ?? 0,
      },
    };
  });
}

/** Routes a model id to whichever adapter can serve it. */
export function callModel(spec) {
  const viaOpenRouter = spec.provider === 'openrouter';
  const apiKey = viaOpenRouter ? process.env.OPENROUTER_API_KEY : process.env.GEMINI_API_KEY;
  if (!apiKey || apiKey === 'offline') {
    return Promise.reject(new Error(
      `missing ${viaOpenRouter ? 'OPENROUTER_API_KEY' : 'GEMINI_API_KEY'} for ${spec.model}`,
    ));
  }
  return (viaOpenRouter ? callOpenRouter : callGemini)({ ...spec, apiKey });
}
