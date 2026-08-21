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
   * @param {{model: string, contents: Array, systemInstruction?: string, generationConfig?: object}} req
   * @returns {Promise<string>} reply text, possibly empty
   */
  async generate({ model, contents, systemInstruction, generationConfig }) {
    const body = { contents };
    if (systemInstruction) {
      body.systemInstruction = { parts: [{ text: systemInstruction }] };
    }
    if (generationConfig) body.generationConfig = generationConfig;

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

      return extractText(await res.json());
    } finally {
      clearTimeout(timer);
    }
  }
}
