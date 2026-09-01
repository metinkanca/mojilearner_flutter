/**
 * OpenRouter adapter.
 *
 * A sibling to `GeminiProvider`, not a replacement. It exists because the two
 * routes do not serve the same catalogue: `gemini-2.5-flash-lite` is closed to
 * new Google API keys and answers them with a 404, while OpenRouter reaches it
 * through its own account. On 2026-08-30 that model scored 140/140 against the
 * tutor prompt — as good as the 3.1 the app ships, faster, and about a third
 * the price — which is the whole reason this file exists.
 *
 * Same `fetch`-only approach as the Gemini adapter, for the same reason: one
 * endpoint is not worth an SDK dependency.
 */

const ENDPOINT = 'https://openrouter.ai/api/v1/chat/completions';

/**
 * The app's `{role, text}` history as OpenAI-shaped messages.
 *
 * `model` is this app's word for the assistant turn — it comes from Gemini's
 * vocabulary, which the Dart client also speaks. Everything that is not
 * explicitly an assistant turn is treated as the user's, so a malformed role
 * degrades to the safe reading rather than being dropped.
 */
export function toMessages(history, systemInstruction) {
  const messages = [];
  if (systemInstruction) messages.push({ role: 'system', content: systemInstruction });
  for (const m of history ?? []) {
    messages.push({
      role: m.role === 'model' ? 'assistant' : 'user',
      content: String(m.text ?? ''),
    });
  }
  return messages;
}

/**
 * The app's generation settings in OpenAI's vocabulary.
 *
 * `thinkingBudget` has no equivalent here, and that asymmetry is deliberate
 * rather than an oversight: OpenAI-shaped APIs express reasoning as an effort
 * level, not a token budget. A budget of 0 means "do not reason", which maps
 * onto omitting the reasoning field; any other value is dropped rather than
 * guessed at, since inventing an effort level would silently change what the
 * request costs.
 */
export function toOpenAiParams(config) {
  if (!config || typeof config !== 'object') return {};
  const out = {};
  if (Number.isFinite(config.maxOutputTokens)) out.max_tokens = config.maxOutputTokens;
  if (Number.isFinite(config.temperature)) out.temperature = config.temperature;
  return out;
}

/** Reply text, or '' when the response carried none. */
export function extractText(payload) {
  const content = payload?.choices?.[0]?.message?.content;
  return typeof content === 'string' ? content.trim() : '';
}

/**
 * Token counts, or null when absent.
 *
 * `completion_tokens` already includes reasoning tokens on this API, so unlike
 * the Gemini adapter there is nothing to add — adding
 * `reasoning_tokens` on top would bill them twice.
 */
export function extractUsage(payload) {
  const u = payload?.usage;
  if (!u) return null;
  const n = (v) => (Number.isFinite(v) ? v : 0);
  return {
    inputTokens: n(u.prompt_tokens),
    outputTokens: n(u.completion_tokens),
    cachedInputTokens: n(u.prompt_tokens_details?.cached_tokens),
  };
}

export class OpenRouterProvider {
  /**
   * @param {{apiKey: string, fetchImpl?: typeof fetch, timeoutMs?: number,
   *   referer?: string, title?: string}} opts
   *   `timeoutMs` defaults lower than the Gemini adapter's 25s on purpose. When
   *   this provider is the primary in a fallback pair, the whole point is to
   *   fail fast enough that the backup still fits inside the app's 30s budget —
   *   a fallback that arrives after the client has given up is not a fallback.
   */
  constructor({ apiKey, fetchImpl = fetch, timeoutMs = 8_000, referer, title } = {}) {
    if (!apiKey) throw new Error('OPENROUTER_API_KEY is required');
    this.apiKey = apiKey;
    this.fetchImpl = fetchImpl;
    this.timeoutMs = timeoutMs;
    this.referer = referer;
    this.title = title;
  }

  async generate({ model, history, systemInstruction, generationConfig }) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.timeoutMs);
    try {
      const headers = {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${this.apiKey}`,
      };
      // Optional attribution headers. OpenRouter uses them for its dashboards;
      // neither carries user content.
      if (this.referer) headers['HTTP-Referer'] = this.referer;
      if (this.title) headers['X-Title'] = this.title;

      const res = await this.fetchImpl(ENDPOINT, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          model,
          messages: toMessages(history, systemInstruction),
          ...toOpenAiParams(generationConfig),
        }),
        signal: controller.signal,
      });

      if (!res.ok) {
        // Body withheld for the same reason as the Gemini adapter: an upstream
        // error can quote the prompt back.
        const err = new Error(`upstream ${res.status}`);
        err.upstreamStatus = res.status;
        throw err;
      }

      const payload = await res.json();
      // `payload.model` is what OpenRouter actually routed to, which can differ
      // from what was asked when it substitutes a variant; fall back to the
      // request. The ledger needs the served id, not the requested one.
      return {
        text: extractText(payload),
        usage: extractUsage(payload),
        model: typeof payload.model === 'string' && payload.model ? payload.model : model,
      };
    } finally {
      clearTimeout(timer);
    }
  }
}
