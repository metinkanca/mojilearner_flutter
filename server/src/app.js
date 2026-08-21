import express from 'express';
import { randomBytes } from 'node:crypto';

import { MemorySessionStore, newSessionId } from './sessions.js';
import { toGeminiContents, toGeminiGenerationConfig } from './gemini.js';

/**
 * The three endpoints `lib/services/ai_service.dart` calls, and nothing else.
 *
 * Request and response shapes are fixed by that file — it throws a
 * FormatException on a missing `text` or `sessionId` — so they are asserted in
 * test/contract.test.js rather than left to drift.
 */

/** Reply text the client treats as a hard error, so it is never sent as 2xx. */
const MAX_BODY = '256kb';

export function createApp({
  provider,
  sessions = new MemorySessionStore(),
  authToken = null,
  allowedModels,
  defaultModel = 'gemini-2.5-flash',
  logger = console,
} = {}) {
  const app = express();
  app.disable('x-powered-by');
  app.use(express.json({ limit: MAX_BODY }));

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

  function fail(req, res, started, err) {
    // 502 for an upstream refusal, 500 for a bug here. The distinction is what
    // tells the operator whether to look at their Gemini quota or at this code.
    const status = err?.upstreamStatus ? 502 : 500;
    record(req, started, status, ` err=${err?.message ?? 'unknown'}`);
    res.status(status).json({ error: status === 502 ? 'upstream_error' : 'internal_error' });
  }

  app.get('/healthz', (_req, res) => {
    res.json({ ok: true, sessions: sessions.size });
  });

  app.post('/v1/ai/generate', requireAuth, async (req, res) => {
    const started = Date.now();
    const model = resolveModel(req, res);
    if (!model) return;

    const prompt = req.body?.prompt;
    if (typeof prompt !== 'string' || !prompt.trim()) {
      record(req, started, 400);
      return res.status(400).json({ error: 'prompt_required' });
    }

    try {
      const text = await provider.generate({
        model,
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        generationConfig: toGeminiGenerationConfig(req.body?.generationConfig),
      });
      record(req, started, 200, ` chars=${text.length}`);
      // Empty text is returned as 200: the app turns it into its own fallback,
      // and a 5xx here would look like an outage instead.
      res.json({ text });
    } catch (err) {
      fail(req, res, started, err);
    }
  });

  app.post('/v1/ai/chat/start', requireAuth, (req, res) => {
    const started = Date.now();
    const model = resolveModel(req, res);
    if (!model) return;

    const systemInstruction = typeof req.body?.systemInstruction === 'string'
      ? req.body.systemInstruction
      : '';
    const rawHistory = Array.isArray(req.body?.history) ? req.body.history : [];
    const history = rawHistory
      .filter((m) => m && typeof m.text === 'string')
      .map((m) => ({ role: m.role === 'model' ? 'model' : 'user', text: m.text }));

    const sessionId = newSessionId(randomBytes);
    sessions.create(sessionId, { systemInstruction, history, model });
    record(req, started, 200, ` history=${history.length}`);
    res.json({ sessionId });
  });

  app.post('/v1/ai/chat/send', requireAuth, async (req, res) => {
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

    session.history.push({ role: 'user', text: message });

    try {
      const text = await provider.generate({
        model,
        contents: toGeminiContents(session.history),
        systemInstruction: session.systemInstruction,
      });
      if (text) session.history.push({ role: 'model', text });
      record(req, started, 200, ` turns=${session.history.length} chars=${text.length}`);
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
