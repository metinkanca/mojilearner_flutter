import test from 'node:test';
import assert from 'node:assert/strict';

import { createApp } from '../src/app.js';
import { MemorySessionStore } from '../src/sessions.js';
import { SlidingWindowLimiter, SpendLedger, clientKey } from '../src/limits.js';
import { FallbackProvider } from '../src/fallback.js';
import { costOf, priceFor } from '../src/pricing.js';
import { extractUsage } from '../src/gemini.js';

/**
 * The Phase 0 spend controls: a per-address rate limit, a daily USD ceiling, a
 * history window, and a floor under the generation config.
 *
 * All four are enforced here rather than in the app, because the app's token is
 * shared by every install and its client-side limiter resets on restart. A test
 * that only proved the happy path would prove nothing about any of them.
 */

function stubProvider(reply = 'hello') {
  const calls = [];
  return {
    calls,
    async generate(req) {
      calls.push(req);
      return typeof reply === 'function' ? reply(req) : reply;
    },
  };
}

async function serve(opts) {
  const app = createApp(opts);
  const server = await new Promise((resolve) => {
    const s = app.listen(0, () => resolve(s));
  });
  const base = `http://127.0.0.1:${server.address().port}`;
  return {
    close: () => server.close(),
    async post(path, body) {
      const res = await fetch(base + path, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
      const text = await res.text();
      return { status: res.status, headers: res.headers, body: text ? JSON.parse(text) : null };
    },
    async get(path) {
      const res = await fetch(base + path);
      return { status: res.status, body: await res.json() };
    },
  };
}

// --- pricing ---------------------------------------------------------------

test('prices resolve by bare provider id as well as by slug', () => {
  assert.deepEqual(priceFor('gemini-3.1-flash-lite'), priceFor('google/gemini-3.1-flash-lite'));
  assert.equal(priceFor('nope'), null);
});

test('cost reproduces the committed eval report', () => {
  // tools/eval/results/report.md: 16 cases averaging 487.25 in / 231.4 out came
  // to $0.468969 per 1000 turns. If this drifts, the budget ceiling is costing
  // live traffic differently from how the model was chosen.
  const per1k = costOf('gemini-3.1-flash-lite', { inputTokens: 487.25, outputTokens: 231.4 }) * 1000;
  assert.ok(Math.abs(per1k - 0.468969) < 0.001, `got ${per1k}`);
});

test('an unpriced model costs the worst rate on file, never zero', () => {
  const usage = { inputTokens: 1000, outputTokens: 1000 };
  assert.equal(costOf('invented-model', usage), null, 'strict reports honestly');
  assert.ok(costOf('invented-model', usage, { strict: false }) > 0, 'the ledger never bills zero');
});

test('cached input is discounted, not double counted', () => {
  const plain = costOf('gemini-3.1-flash-lite', { inputTokens: 1000, outputTokens: 0 });
  const cached = costOf('gemini-3.1-flash-lite', {
    inputTokens: 1000,
    outputTokens: 0,
    cachedInputTokens: 1000,
  });
  assert.ok(cached < plain);
});

test('usage counts reasoning as output, because it is billed as output', () => {
  const usage = extractUsage({
    usageMetadata: { promptTokenCount: 500, candidatesTokenCount: 200, thoughtsTokenCount: 300 },
  });
  assert.deepEqual(usage, { inputTokens: 500, outputTokens: 500, cachedInputTokens: 0 });
  assert.equal(extractUsage({}), null);
});

// --- rate limiting ---------------------------------------------------------

test('the limiter counts refused requests, so retrying does not drain the window', () => {
  const limiter = new SlidingWindowLimiter({ windowMs: 1000, max: 2 });
  const t = 1_000_000;
  assert.equal(limiter.check('a', t).allowed, true);
  assert.equal(limiter.check('a', t).allowed, true);
  assert.equal(limiter.check('a', t).allowed, false);
  // Still refused just before the window rolls, despite the failed attempts.
  assert.equal(limiter.check('a', t + 999).allowed, false);
  assert.equal(limiter.check('a', t + 1001).allowed, true);
});

test('the limiter meters each address separately and forgets idle ones', () => {
  const limiter = new SlidingWindowLimiter({ windowMs: 1000, max: 1 });
  assert.equal(limiter.check('a', 1000).allowed, true);
  assert.equal(limiter.check('b', 1000).allowed, true, 'b has its own budget');
  limiter.sweep(3000);
  assert.equal(limiter.hits.size, 0, 'idle keys are dropped rather than accumulated');
});

test('a rate-limited request is refused with Retry-After and never reaches the provider', async () => {
  const provider = stubProvider('hi');
  const srv = await serve({
    provider,
    limiter: new SlidingWindowLimiter({ windowMs: 60_000, max: 1 }),
  });
  try {
    assert.equal((await srv.post('/v1/ai/generate', { mode: 'quiz', params: {} })).status, 200);
    const second = await srv.post('/v1/ai/generate', { mode: 'quiz', params: {} });
    assert.equal(second.status, 429);
    assert.equal(second.body.error, 'rate_limited');
    assert.ok(Number(second.headers.get('retry-after')) > 0);
    assert.equal(provider.calls.length, 1, 'the refused call cost nothing');
  } finally {
    srv.close();
  }
});

// --- daily budget ----------------------------------------------------------

test('the ledger stops spending once the day is used up, and rolls over', () => {
  let now = Date.parse('2026-08-30T10:00:00Z');
  const spend = new SpendLedger({ dailyBudgetUsd: 1, now: () => now });
  assert.equal(spend.exhausted(), false);
  spend.record('gemini-3.1-flash-lite', { inputTokens: 4_000_000, outputTokens: 0 }, costOf);
  assert.equal(spend.exhausted(), true, '4M input tokens at $0.25/M is exactly $1');

  now = Date.parse('2026-08-31T00:01:00Z');
  assert.equal(spend.exhausted(), false, 'a new UTC day restores the budget');
  assert.equal(spend.snapshot().spentUsd, 0);
});

test('a ledger with no budget set never refuses', () => {
  const spend = new SpendLedger();
  assert.equal(spend.enabled, false);
  assert.equal(spend.exhausted(), false);
  assert.equal(spend.remaining(), Infinity);
  assert.deepEqual(spend.snapshot(), { enabled: false });
});

test('an exhausted budget refuses every billable endpoint but not healthz', async () => {
  const spend = new SpendLedger({ dailyBudgetUsd: 0.000001 });
  spend.record('gemini-3.1-flash-lite', { inputTokens: 100_000, outputTokens: 0 }, costOf);
  const provider = stubProvider('hi');
  const srv = await serve({ provider, spend });
  try {
    const cases = [
      ['/v1/ai/generate', { mode: 'quiz', params: {} }],
      ['/v1/ai/chat/start', { mode: 'pet', params: {}, history: [] }],
      ['/v1/ai/chat/send', { sessionId: 'whatever', message: 'x' }],
    ];
    for (const [path, body] of cases) {
      const res = await srv.post(path, body);
      assert.equal(res.status, 429, path);
      assert.equal(res.body.error, 'daily_budget_exhausted', path);
    }
    assert.equal(provider.calls.length, 0);

    const health = await srv.get('/healthz');
    assert.equal(health.status, 200, 'healthz stays answerable when the budget is spent');
    assert.equal(health.body.budget.enabled, true);
  } finally {
    srv.close();
  }
});

test('a served request is billed against the ledger', async () => {
  const spend = new SpendLedger({ dailyBudgetUsd: 10 });
  const provider = {
    async generate() {
      return { text: 'hi', usage: { inputTokens: 1_000_000, outputTokens: 0 } };
    },
  };
  const srv = await serve({ provider, spend });
  try {
    await srv.post('/v1/ai/generate', { mode: 'quiz', params: {} });
    assert.equal(spend.snapshot().spentUsd, 0.25);
    assert.equal(spend.snapshot().calls, 1);
  } finally {
    srv.close();
  }
});

// --- generation config -----------------------------------------------------

test('chat turns get the settings the eval actually validated', async () => {
  const provider = stubProvider('reply');
  const srv = await serve({ provider });
  try {
    const { body } = await srv.post('/v1/ai/chat/start', { mode: 'pet', params: {}, history: [] });
    await srv.post('/v1/ai/chat/send', { sessionId: body.sessionId, message: 'hi' });
    // The client sends no config for chat at all, so anything here came from
    // the server. thinkingBudget 0 is the one that matters: reasoning bills at
    // the output rate, which is 6x the input rate on Gemini.
    assert.deepEqual(provider.calls[0].generationConfig, {
      temperature: 0.7,
      maxOutputTokens: 1024,
      thinkingBudget: 0,
    });
  } finally {
    srv.close();
  }
});

test('the config clamp only ever narrows what a caller asked for', async () => {
  const provider = stubProvider('reply');
  const srv = await serve({ provider, maxOutputTokensCap: 2048 });
  try {
    await srv.post('/v1/ai/generate', {
      mode: 'quiz',
      params: {},
      generationConfig: { maxOutputTokens: 999_999, temperature: 0.4 },
    });
    assert.equal(provider.calls[0].generationConfig.maxOutputTokens, 2048, 'capped');

    await srv.post('/v1/ai/generate', {
      mode: 'quiz',
      params: {},
      generationConfig: { maxOutputTokens: 256, temperature: 0 },
    });
    assert.equal(provider.calls[1].generationConfig.maxOutputTokens, 256, 'a smaller ask stands');
    assert.equal(provider.calls[1].generationConfig.temperature, 0, 'temperature is left alone');
  } finally {
    srv.close();
  }
});

test('the injected thinking budget can be turned off for models that reject 0', async () => {
  const provider = stubProvider('reply');
  const srv = await serve({ provider, defaultThinkingBudget: null });
  try {
    await srv.post('/v1/ai/generate', { mode: 'quiz', params: {} });
    assert.equal(provider.calls[0].generationConfig.thinkingBudget, undefined);
  } finally {
    srv.close();
  }
});

// --- history window --------------------------------------------------------

test('history is windowed on create and never starts on a model turn', () => {
  const store = new MemorySessionStore({ maxHistory: 4 });
  const history = Array.from({ length: 21 }, (_, i) => ({
    role: i % 2 === 0 ? 'user' : 'model',
    text: `m${i}`,
  }));
  store.create('s1', { systemInstruction: 's', history, model: 'm' });
  const kept = store.get('s1').history;
  assert.ok(kept.length <= 4);
  assert.equal(kept[0].role, 'user', 'Gemini rejects contents starting with a model turn');
  assert.equal(kept[kept.length - 1].text, 'm20', 'the newest turns are the ones kept');
});

test('a long chat stops growing instead of going quadratic', async () => {
  const provider = stubProvider('reply');
  const srv = await serve({ provider, sessions: new MemorySessionStore({ maxHistory: 6 }) });
  try {
    const { body } = await srv.post('/v1/ai/chat/start', { mode: 'pet', params: {}, history: [] });
    for (let i = 0; i < 20; i += 1) {
      await srv.post('/v1/ai/chat/send', { sessionId: body.sessionId, message: `turn ${i}` });
    }
    const sent = provider.calls[provider.calls.length - 1].history;
    assert.ok(sent.length <= 6, `history grew to ${sent.length}`);
    assert.equal(sent[sent.length - 1].text, 'turn 19', 'the latest turn still arrives');
  } finally {
    srv.close();
  }
});

test('a failed turn still rolls back the user message it added', async () => {
  const provider = {
    async generate() {
      throw new Error('upstream down');
    },
  };
  const sessions = new MemorySessionStore({ maxHistory: 6 });
  const srv = await serve({ provider, sessions });
  try {
    const { body } = await srv.post('/v1/ai/chat/start', { mode: 'pet', params: {}, history: [] });
    const res = await srv.post('/v1/ai/chat/send', { sessionId: body.sessionId, message: 'hi' });
    assert.equal(res.status, 500);
    assert.equal(sessions.get(body.sessionId).history.length, 0, 'a retry must not send it twice');
  } finally {
    srv.close();
  }
});

// --- attribution -----------------------------------------------------------

test('a forwarded address is trusted only when the deployment says so', () => {
  const req = {
    get: (h) => (h === 'x-forwarded-for' ? '203.0.113.7, 10.0.0.1' : undefined),
    socket: { remoteAddress: '10.0.0.1' },
  };
  assert.equal(clientKey(req), '10.0.0.1', 'unproxied: the header is forgeable, so ignore it');
  assert.equal(clientKey(req, { trustProxy: true }), '203.0.113.7');
});

test('the ledger prices the model that served, not the one requested', async () => {
  // The whole point of routing 3.1 requests to 2.5-flash-lite is that it costs
  // about a third as much. Billing the requested id would overstate every call
  // by 3x: a $5 daily ceiling would trip at $1.50 of real spend, and the saving
  // the switch was made for would never appear in the ledger.
  const spend = new SpendLedger({ dailyBudgetUsd: 10 });
  const provider = {
    async generate() {
      return {
        text: 'hi',
        usage: { inputTokens: 1_000_000, outputTokens: 0 },
        model: 'google/gemini-2.5-flash-lite',
      };
    },
  };
  const srv = await serve({ provider, spend });
  try {
    await srv.post('/v1/ai/generate', { mode: 'quiz', params: {} });
    // 2.5-flash-lite input is $0.10/M; the requested 3.1 would have been $0.25.
    assert.equal(spend.snapshot().spentUsd, 0.10);
  } finally {
    srv.close();
  }
});

test('a provider that reports no model is billed against the requested one', async () => {
  // Every test stub, and any provider written before this existed.
  const spend = new SpendLedger({ dailyBudgetUsd: 10 });
  const provider = {
    async generate() {
      return { text: 'hi', usage: { inputTokens: 1_000_000, outputTokens: 0 } };
    },
  };
  const srv = await serve({ provider, spend });
  try {
    await srv.post('/v1/ai/generate', { mode: 'quiz', params: {} });
    assert.equal(spend.snapshot().spentUsd, 0.25);
  } finally {
    srv.close();
  }
});

test('a fallback to the backup is billed at the backup model rate', async () => {
  // The expensive direction, and the one worth catching: when the cheap primary
  // is down, every call costs 2.5x more and the ledger has to say so.
  const spend = new SpendLedger({ dailyBudgetUsd: 10 });
  const provider = new FallbackProvider({
    primary: { async generate() { throw new Error('upstream 400'); } },
    backup: {
      async generate({ model }) {
        return { text: 'hi', usage: { inputTokens: 1_000_000, outputTokens: 0 }, model };
      },
    },
    primaryModel: 'google/gemini-2.5-flash-lite',
    backupModel: 'gemini-3.1-flash-lite',
    logger: { warn() {} },
  });
  const srv = await serve({ provider, spend });
  try {
    await srv.post('/v1/ai/generate', { mode: 'quiz', params: {} });
    assert.equal(spend.snapshot().spentUsd, 0.25);
    assert.equal(provider.snapshot().fallback, 1);
  } finally {
    srv.close();
  }
});
