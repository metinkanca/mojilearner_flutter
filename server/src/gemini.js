/**
 * Gemini adapter.
 *
 * Talks to the REST API with `fetch` rather than pulling in an SDK: the whole
 * surface used here is one endpoint, and an SDK would add a dependency whose
 * release cadence we would then have to track for a service whose entire job
 * is to hold an API key.
 */

const API_ROOT = 'https://generativelanguage.googleapis.com/v1beta/models';

/**
 * Maps the app's generation config onto Gemini's shape.
 *
 * `thinkingBudget` is the one that does not map one-to-one: it lives under
 * `thinkingConfig`, and 0 is meaningful (it disables thinking) so it must not
 * be dropped as falsy.
 */
export function toGeminiGenerationConfig(config) {
  if (!config || typeof config !== 'object') return undefined;
  const out = {};
  if (Number.isFinite(config.maxOutputTokens)) out.maxOutputTokens = config.maxOutputTokens;
  if (Number.isFinite(config.temperature)) out.temperature = config.temperature;
  if (Number.isFinite(config.thinkingBudget)) {
    out.thinkingConfig = { thinkingBudget: config.thinkingBudget };
  }
  return Object.keys(out).length ? out : undefined;
}

/** `{role, text}` as the app sends it -> Gemini `contents` entries. */
export function toGeminiContents(history) {
  return history.map((m) => ({
    role: m.role === 'model' ? 'model' : 'user',
    parts: [{ text: String(m.text ?? '') }],
  }));
}

/**
 * Pulls the reply text out of a response.
 *
 * Returns '' rather than throwing when there is no text. Empty is a real
 * outcome — a low `maxOutputTokens` with thinking enabled spends the budget on
 * reasoning and returns nothing — and the app is built to treat empty as
 * "fall back", so turning it into a 5xx here would convert a soft degradation
 * into a hard failure.
 */
export function extractText(payload) {
  const parts = payload?.candidates?.[0]?.content?.parts;
  if (!Array.isArray(parts)) return '';
  return parts.map((p) => (typeof p?.text === 'string' ? p.text : '')).join('').trim();
}

/**
 * Pulls token counts out of a response, or null when the field is absent.
 *
 * Two details decide whether the number that reaches the budget ledger is the
 * number that reaches the bill:
 *
 * - `thoughtsTokenCount` is reasoning, and it is billed at the *output* rate.
 *   Counting only `candidatesTokenCount` would under-report every call made
 *   without `thinkingBudget: 0` — which, before the clamp in app.js, was every
 *   chat turn the app makes.
 * - `cachedContentTokenCount` is a subset of `promptTokenCount`, not an
 *   addition to it, and bills at roughly a tenth of the rate. It is reported
 *   separately so `costOf` can discount it rather than double-count it.
 */
export function extractUsage(payload) {
  const meta = payload?.usageMetadata;
  if (!meta) return null;
  const n = (v) => (Number.isFinite(v) ? v : 0);
  return {
    inputTokens: n(meta.promptTokenCount),
    outputTokens: n(meta.candidatesTokenCount) + n(meta.thoughtsTokenCount),
    cachedInputTokens: n(meta.cachedContentTokenCount),
  };
}

export class GeminiProvider {
  constructor({ apiKey, fetchImpl = fetch, timeoutMs = 25_000 }) {
    if (!apiKey) throw new Error('GEMINI_API_KEY is required');
    this.apiKey = apiKey;
    this.fetchImpl = fetchImpl;
    // Below the app's own 30s timeout, so a slow upstream surfaces as a real
    // error from here rather than as a client-side timeout with no detail.
    this.timeoutMs = timeoutMs;
  }

  /**
   * @param {{model: string, history: Array<{role: string, text: string}>,
   *   systemInstruction?: string, generationConfig?: object}} req
   *   `history` and `generationConfig` are in the app's own neutral shape;
   *   translating them to this provider's wire format is this class's job, not
   *   the caller's. That is what lets a second provider sit beside this one
   *   without either format becoming the protocol.
   * @returns {Promise<{text: string, usage: object|null}>} reply text (possibly
   *   empty) and the token counts to bill it against. Callers normalise a bare
   *   string too, so a stub provider in a test need not return usage.
   */
  async generate({ model, history, systemInstruction, generationConfig }) {
    const body = { contents: toGeminiContents(history ?? []) };
    if (systemInstruction) {
      body.systemInstruction = { parts: [{ text: systemInstruction }] };
    }
    const cfg = toGeminiGenerationConfig(generationConfig);
    if (cfg) body.generationConfig = cfg;

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.timeoutMs);
    try {
      const res = await this.fetchImpl(
        `${API_ROOT}/${encodeURIComponent(model)}:generateContent`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': this.apiKey,
          },
          body: JSON.stringify(body),
          signal: controller.signal,
        },
      );

      if (!res.ok) {
        // The upstream body can quote the prompt back, so it is not forwarded
        // to the caller and not logged.
        const err = new Error(`upstream ${res.status}`);
        err.upstreamStatus = res.status;
        throw err;
      }

      const payload = await res.json();
      // The id that actually answered, so the spend ledger prices what was
      // served rather than what was asked for. They differ whenever a
      // FallbackProvider rewrites the model on its way through.
      return { text: extractText(payload), usage: extractUsage(payload), model };
    } finally {
      clearTimeout(timer);
    }
  }
}
