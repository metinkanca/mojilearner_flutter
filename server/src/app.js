import express from 'express';
import { randomBytes } from 'node:crypto';

import { MemorySessionStore, newSessionId } from './sessions.js';
import { PromptRequestError, buildPrompt, buildSystemInstruction } from './prompts.js';
// Providers translate the neutral shapes below into their own wire format.
import { SpendLedger, clientKey } from './limits.js';
import { costOf } from './pricing.js';

/**
 * The three endpoints `lib/services/ai_service.dart` calls, and nothing else.
 *
 * Request and response shapes are fixed by that file — it throws a
 * FormatException on a missing `text` or `sessionId` — so they are asserted in
 * test/contract.test.js rather than left to drift.
 */

/** Reply text the client treats as a hard error, so it is never sent as 2xx. */
const MAX_BODY = '256kb';

/**
 * Generation settings applied to every chat turn.
 *
 * The client sends none — `AiGenerationConfig.conversational` is empty — so
 * before this, chat ran on the model's defaults with reasoning enabled and no
 * output cap. Reasoning bills at the output rate, which on Gemini is six times
 * the input rate, and chat is where nearly all the volume is.
 *
 * These are not a guess. They are the exact settings `tools/eval` ran under
 * when it scored this prompt format 16/16 usable, including every format,
 * script and native-language gate — see `tools/eval/providers.mjs`. So the
 * committed report's cost per 1k turns has always described a configuration
 * the live service was not actually using; this is what makes the two agree.
 */
const DEFAULT_CHAT_GENERATION_CONFIG = {
  temperature: 0.7,
  maxOutputTokens: 1024,
  thinkingBudget: 0,
};

/**
 * Ceiling on `maxOutputTokens`, whatever the caller asks for.
 *
 * 2048 is what `AiGenerationConfig.structuredJson` already requests for quiz
 * generation, so nothing the app does today is affected. What it stops is a
 * caller holding the extracted token asking for the model's full output window
 * on every request.
 */
const DEFAULT_MAX_OUTPUT_TOKENS_CAP = 2048;

export function createApp({
  provider,
  sessions = new MemorySessionStore(),
  authToken = null,
  allowedModels,
  defaultModel = 'gemini-3.1-flash-lite',
  corsOrigins = [],
  logger = console,
  // Spend controls. All default to inert, so a caller that knows nothing about
  // them — every existing test — gets exactly the previous behaviour.
  limiter = null,
  spend = new SpendLedger(),
  trustProxy = false,
  chatGenerationConfig = DEFAULT_CHAT_GENERATION_CONFIG,
  maxOutputTokensCap = DEFAULT_MAX_OUTPUT_TOKENS_CAP,
  defaultThinkingBudget = 0,
} = {}) {
  const app = express();
  app.disable('x-powered-by');
  app.use(express.json({ limit: MAX_BODY }));

  /**
   * Cross-origin access, off unless an operator asks for it.
   *
   * Only a browser needs this: `flutter run -d chrome` serves the app from a
   * random localhost port, and without the headers below every call fails at
   * the preflight. Native builds never send an Origin and are unaffected.
   *
   * Off by default, and worth keeping that way in production: a web build
   * carries AI_PROXY_TOKEN in its JS bundle, so opening the origin list turns
   * a readable token into a usable one from any page.
   */
  if (corsOrigins.length) {
    const any = corsOrigins.includes('*');
    app.use((req, res, next) => {
      const origin = req.get('origin');
      const allow = any ? '*' : (corsOrigins.includes(origin) ? origin : null);
      if (allow) {
        res.setHeader('Access-Control-Allow-Origin', allow);
        res.setHeader('Vary', 'Origin');
        res.setHeader('Access-Control-Allow-Headers', 'content-type,authorization');
        res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
      }
      if (req.method === 'OPTIONS') return res.sendStatus(allow ? 204 : 403);
      return next();
    });
  }

  const allowed = new Set(
    allowedModels && allowedModels.length ? allowedModels : [defaultModel],
  );

  /**
   * Bearer auth, when a token is configured.
   *
   * Optional because the client only sends the header when it has a token —
   * but an unauthenticated proxy holding a billable API key is someone else's
   * free Gemini account, so index.js refuses to start without one unless the
   * operator opts out explicitly.
   */
  function requireAuth(req, res, next) {
    if (!authToken) return next();
    const header = req.get('authorization') ?? '';
    const presented = header.startsWith('Bearer ') ? header.slice(7).trim() : '';
    if (presented !== authToken) {
      return res.status(401).json({ error: 'unauthorized' });
    }
    return next();
  }

  /**
   * Rejects a model the operator has not allow-listed.
   *
   * The client picks the model, so without this anyone holding the URL can
   * point the operator's key at the most expensive model available.
   */
  function resolveModel(req, res) {
    const model = typeof req.body?.model === 'string' && req.body.model.trim()
      ? req.body.model.trim()
      : defaultModel;
    if (!allowed.has(model)) {
      res.status(400).json({ error: 'model_not_allowed', model });
      return null;
    }
    return model;
  }

  /** Logs the shape of a call, never its content. */
  function record(req, started, status, extra = '') {
    const source = typeof req.body?.source === 'string' ? req.body.source : 'unknown';
    logger.info(
      `${req.method} ${req.path} source=${source} status=${status} ${Date.now() - started}ms${extra}`,
    );
  }

  /**
   * Rate limit, then daily budget. Applied to the three billable endpoints and
   * not to `/healthz`, which has to stay answerable when the budget is spent —
   * that is precisely when an operator goes looking for it.
   */
  function meter(req, res, next) {
    if (limiter) {
      const verdict = limiter.check(clientKey(req, { trustProxy }));
      if (!verdict.allowed) {
        record(req, Date.now(), 429, ' refused=rate');
        res.setHeader('Retry-After', String(verdict.retryAfterSeconds));
        return res.status(429).json({ error: 'rate_limited' });
      }
    }
    if (spend.exhausted()) {
      // 429 rather than 402 or 503: the app already turns any non-2xx into its
      // local fallback, and this is genuinely "come back later" — the ledger
      // rolls over at midnight UTC.
      record(req, Date.now(), 429, ' refused=budget');
      return res.status(429).json({ error: 'daily_budget_exhausted' });
    }
    return next();
  }

  /**
   * Providers return `{text, usage, model}`; the test stubs return a bare
   * string. Normalising here keeps usage optional, so a stub need not fake
   * token counts to exercise an endpoint.
   *
   * `model` is the id that actually served the call, which is not always the id
   * the caller asked for — a FallbackProvider rewrites it on the way through.
   * It is carried back so the ledger can price what was served.
   */
  function normalizeReply(reply) {
    if (typeof reply === 'string') return { text: reply, usage: null, model: null };
    return {
      text: typeof reply?.text === 'string' ? reply.text : '',
      usage: reply?.usage ?? null,
      model: typeof reply?.model === 'string' && reply.model ? reply.model : null,
    };
  }

  /**
   * Books a completed call against the ledger and returns its log tag.
   *
   * Prices the model that *served* the call, falling back to the requested one.
   * The distinction is the whole point of the daily budget: a deployment
   * routing `gemini-3.1-flash-lite` requests to `google/gemini-2.5-flash-lite`
   * pays roughly a third as much, and billing the requested id would overstate
   * every call by 3x — tripping a $5 ceiling at $1.50 of real spend, and hiding
   * the saving the switch was made for. Failing in the safe direction is not
   * the same as being right.
   */
  function bill(requestedModel, usage, servedModel = null) {
    if (!spend.enabled) return '';
    const model = servedModel ?? requestedModel;
    const cost = spend.record(model, usage, costOf);
    const estimated = usage ? '' : '~';
    const routed = servedModel && servedModel !== requestedModel ? ` via=${servedModel}` : '';
    return ` cost=${estimated}$${cost.toFixed(6)}${routed}`;
  }

  /**
   * Applies the deployment's floor and ceiling to a caller's generation config.
   *
   * Only ever narrows: a caller may ask for less output or less reasoning than
   * the default, never more. `thinkingBudget` is filled in only when absent, so
   * a client that already sends 0 — every structured-JSON request the app makes
   * — is unchanged.
   */
  function clampGenerationConfig(config) {
    const out = { ...(config && typeof config === 'object' ? config : {}) };

    if (!Number.isFinite(out.thinkingBudget) && Number.isFinite(defaultThinkingBudget)) {
      out.thinkingBudget = defaultThinkingBudget;
    }
    if (Number.isFinite(maxOutputTokensCap) && maxOutputTokensCap > 0) {
      out.maxOutputTokens = Number.isFinite(out.maxOutputTokens)
        ? Math.min(out.maxOutputTokens, maxOutputTokensCap)
        : maxOutputTokensCap;
    }
    return out;
  }

  function fail(req, res, started, err) {
    // 502 for an upstream refusal, 500 for a bug here. The distinction is what
    // tells the operator whether to look at their Gemini quota or at this code.
    const status = err?.upstreamStatus ? 502 : 500;
    record(req, started, status, ` err=${err?.message ?? 'unknown'}`);
    res.status(status).json({ error: status === 502 ? 'upstream_error' : 'internal_error' });
  }

  app.get('/healthz', (_req, res) => {
    res.json({
      ok: true,
      sessions: sessions.size,
      budget: spend.snapshot(),
      // Only present when a fallback pair is configured. Watch `fallback`: a
      // number that climbs means the cheap primary is failing and every request
      // is quietly costing backup prices.
      ...(typeof provider.snapshot === 'function' ? { routing: provider.snapshot() } : {}),
    });
  });

  app.post('/v1/ai/generate', requireAuth, meter, async (req, res) => {
    const started = Date.now();
    const model = resolveModel(req, res);
    if (!model) return;

    // The caller names a prompt and supplies its data; it does not write one.
    // See src/prompts.js for why: with a raw `prompt` field this endpoint was
    // a general-purpose model relay for anyone holding the token.
    let prompt;
    try {
      prompt = buildPrompt(req.body?.mode, req.body?.params);
    } catch (err) {
      if (err instanceof PromptRequestError) {
        record(req, started, 400);
        return res.status(400).json({ error: err.code });
      }
      throw err;
    }

    try {
      const { text, usage, model: servedModel } = normalizeReply(await provider.generate({
        model,
        history: [{ role: 'user', text: prompt }],
        generationConfig: clampGenerationConfig(req.body?.generationConfig),
      }));
      record(req, started, 200, ` chars=${text.length}${bill(model, usage, servedModel)}`);
      // Empty text is returned as 200: the app turns it into its own fallback,
      // and a 5xx here would look like an outage instead.
      res.json({ text });
    } catch (err) {
      fail(req, res, started, err);
    }
  });

  app.post('/v1/ai/chat/start', requireAuth, meter, (req, res) => {
    const started = Date.now();
    const model = resolveModel(req, res);
    if (!model) return;

    // Same rule as /generate: the mode picks the persona, and every line of
    // it is written here. A caller can fill in the blanks — language, level,
    // scenario, review queue — and nothing else.
    let systemInstruction;
    try {
      systemInstruction = buildSystemInstruction(req.body?.mode, req.body?.params);
    } catch (err) {
      if (err instanceof PromptRequestError) {
        record(req, started, 400);
        return res.status(400).json({ error: err.code });
      }
      throw err;
    }

    const rawHistory = Array.isArray(req.body?.history) ? req.body.history : [];
    const history = rawHistory
      .filter((m) => m && typeof m.text === 'string')
      .map((m) => ({ role: m.role === 'model' ? 'model' : 'user', text: m.text }));

    const sessionId = newSessionId(randomBytes);
    sessions.create(sessionId, { systemInstruction, history, model });
    record(req, started, 200, ` history=${history.length}`);
    res.json({ sessionId });
  });

  app.post('/v1/ai/chat/send', requireAuth, meter, async (req, res) => {
    const started = Date.now();
    const model = resolveModel(req, res);
    if (!model) return;

    const sessionId = req.body?.sessionId;
    const message = req.body?.message;
    if (typeof sessionId !== 'string' || !sessionId) {
      record(req, started, 400);
      return res.status(400).json({ error: 'session_id_required' });
    }
    if (typeof message !== 'string' || !message.trim()) {
      record(req, started, 400);
      return res.status(400).json({ error: 'message_required' });
    }

    const session = sessions.get(sessionId);
    if (!session) {
      // 410, distinct from a model failure on purpose. A free host that sleeps
      // wakes with an empty session map, and this is what tells the operator
      // that is what happened rather than sending them to look at Gemini.
      record(req, started, 410);
      return res.status(410).json({ error: 'session_expired' });
    }

    // Through the store rather than the array, so the history window is applied
    // on the way in — an untrimmed history is what makes a long chat quadratic.
    sessions.append(sessionId, { role: 'user', text: message });

    try {
      const { text, usage, model: servedModel } = normalizeReply(await provider.generate({
        model,
        // A copy, not the stored array. The provider must not receive a live
        // handle on session state: the model reply is appended to that same
        // array moments later, so anything holding the reference — a retry, a
        // logger, a test recording the call — would see a conversation that
        // changed after it was sent.
        history: [...session.history],
        systemInstruction: session.systemInstruction,
        generationConfig: clampGenerationConfig(chatGenerationConfig),
      }));
      if (text) sessions.append(sessionId, { role: 'model', text });
      record(
        req,
        started,
        200,
        ` turns=${session.history.length} chars=${text.length}${bill(model, usage, servedModel)}`,
      );
      res.json({ text });
    } catch (err) {
      // The user turn is rolled back so a retry does not send it twice.
      session.history.pop();
      fail(req, res, started, err);
    }
  });

  app.use((_req, res) => res.status(404).json({ error: 'not_found' }));

  return app;
}
