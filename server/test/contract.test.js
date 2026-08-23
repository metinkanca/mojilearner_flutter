import test from 'node:test';
import assert from 'node:assert/strict';

import { createApp } from '../src/app.js';
import { MemorySessionStore } from '../src/sessions.js';
import { extractText, toGeminiContents, toGeminiGenerationConfig } from '../src/gemini.js';

/**
 * The shapes here are not this service's to choose — they are fixed by
 * lib/services/ai_service.dart, which throws a FormatException on a response
 * missing `text` or `sessionId`. These tests are the copy of that contract on
 * this side of the wire.
 *
 * No network and no API key: the provider is a stub, so the whole suite runs
 * anywhere.
 */

function stubProvider(reply = 'hello') {
  const calls = [];
  return {
    calls,
    async generate(req) {
      calls.push(req);
      if (typeof reply === 'function') return reply(req);
      return reply;
    },
  };
}

/** Starts the app on an ephemeral port and returns a `post` helper. */
async function serve(opts) {
  const app = createApp(opts);
  const server = await new Promise((resolve) => {
    const s = app.listen(0, () => resolve(s));
  });
  const base = `http://127.0.0.1:${server.address().port}`;
  return {
    base,
    async post(path, body, headers = {}) {
      const res = await fetch(base + path, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', ...headers },
        body: JSON.stringify(body),
      });
      const text = await res.text();
      return { status: res.status, body: text ? JSON.parse(text) : null };
    },
    async get(path) {
      const res = await fetch(base + path);
      return { status: res.status, body: await res.json() };
    },
    close: () => new Promise((r) => server.close(r)),
  };
}

const quietLogger = { info() {}, error() {} };

test('generate returns the text field the client requires', async () => {
  const provider = stubProvider('bonjour');
  const s = await serve({ provider, logger: quietLogger });
  try {
    const res = await s.post('/v1/ai/generate', {
      model: 'gemini-2.5-flash',
      prompt: 'say hello in french',
      source: 'quiz_screen',
    });
    assert.equal(res.status, 200);
    assert.equal(res.body.text, 'bonjour');
    assert.equal(provider.calls[0].contents[0].parts[0].text, 'say hello in french');
  } finally {
    await s.close();
  }
});

test('generate forwards generationConfig, mapping thinkingBudget', async () => {
  const provider = stubProvider();
  const s = await serve({ provider, logger: quietLogger });
  try {
    await s.post('/v1/ai/generate', {
      model: 'gemini-2.5-flash',
      prompt: 'p',
      source: 'quiz_screen',
      // AiGenerationConfig.structuredJson, as the app sends it.
      generationConfig: { maxOutputTokens: 2048, temperature: 0.4, thinkingBudget: 0 },
    });
    assert.deepEqual(provider.calls[0].generationConfig, {
      maxOutputTokens: 2048,
      temperature: 0.4,
      thinkingConfig: { thinkingBudget: 0 },
    });
  } finally {
    await s.close();
  }
});

// The app documents empty as "fall back", not as an error. A 5xx here would
// turn a soft degradation into an outage.
test('an empty model reply is 200, not an error', async () => {
  const s = await serve({ provider: stubProvider(''), logger: quietLogger });
  try {
    const res = await s.post('/v1/ai/generate', {
      model: 'gemini-2.5-flash', prompt: 'p', source: 'quiz_screen',
    });
    assert.equal(res.status, 200);
    assert.equal(res.body.text, '');
  } finally {
    await s.close();
  }
});

test('chat start returns a sessionId and send continues the conversation', async () => {
  const provider = stubProvider((req) => `turns:${req.contents.length}`);
  const s = await serve({ provider, logger: quietLogger });
  try {
    const start = await s.post('/v1/ai/chat/start', {
      model: 'gemini-2.5-flash',
      source: 'chat_screen',
      systemInstruction: 'You are Moji.',
      history: [{ role: 'user', text: 'hi' }, { role: 'model', text: 'hello' }],
    });
    assert.equal(start.status, 200);
    assert.equal(typeof start.body.sessionId, 'string');
    assert.ok(start.body.sessionId.length > 0);

    const first = await s.post('/v1/ai/chat/send', {
      model: 'gemini-2.5-flash',
      source: 'chat_screen',
      sessionId: start.body.sessionId,
      message: 'how are you',
    });
    // Two seeded turns plus the new user message.
    assert.equal(first.body.text, 'turns:3');
    assert.equal(provider.calls[0].systemInstruction, 'You are Moji.');

    // The reply is remembered, so the next turn carries five.
    const second = await s.post('/v1/ai/chat/send', {
      model: 'gemini-2.5-flash',
      source: 'chat_screen',
      sessionId: start.body.sessionId,
      message: 'and again',
    });
    assert.equal(second.body.text, 'turns:5');
  } finally {
    await s.close();
  }
});

// A free host that sleeps wakes with an empty session map. This is what makes
// that diagnosable instead of looking like a model failure.
test('an unknown session is 410, distinct from an upstream failure', async () => {
  const s = await serve({ provider: stubProvider(), logger: quietLogger });
  try {
    const res = await s.post('/v1/ai/chat/send', {
      model: 'gemini-2.5-flash', source: 'chat_screen',
      sessionId: 's_nope', message: 'hi',
    });
    assert.equal(res.status, 410);
    assert.equal(res.body.error, 'session_expired');
  } finally {
    await s.close();
  }
});

test('a failed turn is rolled back so a retry does not double-send', async () => {
  let fail = true;
  const provider = {
    calls: [],
    async generate(req) {
      this.calls.push(req);
      if (fail) {
        const e = new Error('upstream 429');
        e.upstreamStatus = 429;
        throw e;
      }
      return `turns:${req.contents.length}`;
    },
  };
  const s = await serve({ provider, logger: quietLogger });
  try {
    const start = await s.post('/v1/ai/chat/start', {
      model: 'gemini-2.5-flash', source: 'chat_screen',
      systemInstruction: '', history: [],
    });
    const bad = await s.post('/v1/ai/chat/send', {
      model: 'gemini-2.5-flash', source: 'chat_screen',
      sessionId: start.body.sessionId, message: 'hi',
    });
    assert.equal(bad.status, 502, 'an upstream refusal is 502, not 500');

    fail = false;
    const good = await s.post('/v1/ai/chat/send', {
      model: 'gemini-2.5-flash', source: 'chat_screen',
      sessionId: start.body.sessionId, message: 'hi',
    });
    // One user turn, not two: the failed attempt left nothing behind.
    assert.equal(good.body.text, 'turns:1');
  } finally {
    await s.close();
  }
});

test('auth is enforced when a token is configured', async () => {
  const s = await serve({
    provider: stubProvider(), authToken: 'secret', logger: quietLogger,
  });
  try {
    const anon = await s.post('/v1/ai/generate', {
      model: 'gemini-2.5-flash', prompt: 'p', source: 'quiz_screen',
    });
    assert.equal(anon.status, 401);

    const wrong = await s.post('/v1/ai/generate',
      { model: 'gemini-2.5-flash', prompt: 'p', source: 'quiz_screen' },
      { Authorization: 'Bearer nope' });
    assert.equal(wrong.status, 401);

    const ok = await s.post('/v1/ai/generate',
      { model: 'gemini-2.5-flash', prompt: 'p', source: 'quiz_screen' },
      { Authorization: 'Bearer secret' });
    assert.equal(ok.status, 200);
  } finally {
    await s.close();
  }
});

// The client picks the model, so without the allow-list the operator's key can
// be pointed at the most expensive one available.
test('a model outside the allow-list is refused', async () => {
  const s = await serve({
    provider: stubProvider(),
    allowedModels: ['gemini-2.5-flash'],
    logger: quietLogger,
  });
  try {
    const res = await s.post('/v1/ai/generate', {
      model: 'gemini-3-ultra-expensive', prompt: 'p', source: 'quiz_screen',
    });
    assert.equal(res.status, 400);
    assert.equal(res.body.error, 'model_not_allowed');
  } finally {
    await s.close();
  }
});

test('missing prompt, session or message are rejected before the provider', async () => {
  const provider = stubProvider();
  const s = await serve({ provider, logger: quietLogger });
  try {
    assert.equal((await s.post('/v1/ai/generate', { source: 'x' })).status, 400);
    assert.equal((await s.post('/v1/ai/chat/send', { source: 'x', message: 'hi' })).status, 400);
    assert.equal(
      (await s.post('/v1/ai/chat/send', { source: 'x', sessionId: 'a' })).status, 400);
    assert.equal(provider.calls.length, 0);
  } finally {
    await s.close();
  }
});

test('healthz reports liveness and the session count', async () => {
  const s = await serve({ provider: stubProvider(), logger: quietLogger });
  try {
    const res = await s.get('/healthz');
    assert.equal(res.status, 200);
    assert.equal(res.body.ok, true);
    assert.equal(res.body.sessions, 0);
  } finally {
    await s.close();
  }
});

test('sessions expire and are capped', () => {
  const store = new MemorySessionStore({ ttlMs: 50, maxSessions: 2 });
  store.create('a', { systemInstruction: '', history: [], model: 'm' });
  assert.ok(store.get('a'));

  store.create('b', { systemInstruction: '', history: [], model: 'm' });
  store.create('c', { systemInstruction: '', history: [], model: 'm' });
  assert.equal(store.size, 2, 'the cap evicts rather than growing without bound');
  assert.equal(store.get('a'), null, 'the least recently used session went first');

  store.sweep(Date.now() + 1000);
  assert.equal(store.size, 0, 'idle sessions are swept');
});

test('gemini helpers map the shapes the app sends', () => {
  assert.deepEqual(
    toGeminiContents([{ role: 'model', text: 'a' }, { role: 'user', text: 'b' }]),
    [
      { role: 'model', parts: [{ text: 'a' }] },
      { role: 'user', parts: [{ text: 'b' }] },
    ],
  );
  // AiGenerationConfig.conversational is empty and must not send a config at all.
  assert.equal(toGeminiGenerationConfig({}), undefined);
  // 0 is meaningful (thinking off) and must survive a falsy check.
  assert.deepEqual(
    toGeminiGenerationConfig({ thinkingBudget: 0 }),
    { thinkingConfig: { thinkingBudget: 0 } },
  );
  assert.equal(extractText({ candidates: [{ content: { parts: [{ text: ' hi ' }] } }] }), 'hi');
  assert.equal(extractText({}), '');
});
