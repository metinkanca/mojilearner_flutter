import test from 'node:test';
import assert from 'node:assert/strict';

import { GeminiProvider } from '../src/gemini.js';
import { OpenRouterProvider, toMessages, toOpenAiParams } from '../src/openrouter.js';
import { FallbackProvider } from '../src/fallback.js';

/**
 * What each provider actually puts on the wire, and what happens when one of
 * them fails.
 *
 * The first half exists because of a real near-miss. Moving format conversion
 * out of `app.js` and into the providers left the app sending the old shape and
 * `GeminiProvider` reading the new one — so every request would have reached
 * Gemini with an empty conversation. The whole suite stayed green, because every
 * other test uses a stub provider and nothing checked the request body. These
 * tests are that missing check.
 */

const quiet = { warn() {}, info() {}, error() {} };

/** A fetch that records the request and returns a canned provider response. */
function stubFetch(payload, { status = 200 } = {}) {
  const calls = [];
  const impl = async (url, init) => {
    calls.push({ url, init, body: JSON.parse(init.body) });
    return {
      ok: status >= 200 && status < 300,
      status,
      json: async () => payload,
    };
  };
  impl.calls = calls;
  return impl;
}

// --- Gemini wire format ----------------------------------------------------

test('GeminiProvider converts neutral history into contents', async () => {
  const fetchImpl = stubFetch({
    candidates: [{ content: { parts: [{ text: 'bonjour' }] } }],
    usageMetadata: { promptTokenCount: 10, candidatesTokenCount: 5 },
  });
  const provider = new GeminiProvider({ apiKey: 'k', fetchImpl });

  const reply = await provider.generate({
    model: 'gemini-3.1-flash-lite',
    history: [{ role: 'user', text: 'hello' }, { role: 'model', text: 'hi' }],
    systemInstruction: 'You are Moji.',
    generationConfig: { temperature: 0.7, maxOutputTokens: 1024, thinkingBudget: 0 },
  });

  const body = fetchImpl.calls[0].body;
  assert.deepEqual(body.contents, [
    { role: 'user', parts: [{ text: 'hello' }] },
    { role: 'model', parts: [{ text: 'hi' }] },
  ], 'an empty contents array here is the bug this test exists for');
  assert.deepEqual(body.systemInstruction, { parts: [{ text: 'You are Moji.' }] });
  assert.deepEqual(body.generationConfig, {
    temperature: 0.7,
    maxOutputTokens: 1024,
    thinkingConfig: { thinkingBudget: 0 },
  }, 'thinkingBudget must survive as thinkingConfig, and 0 must not be dropped');
  assert.equal(reply.text, 'bonjour');
  assert.deepEqual(reply.usage, { inputTokens: 10, outputTokens: 5, cachedInputTokens: 0 });
});

// --- OpenRouter wire format ------------------------------------------------

test('toMessages puts the system instruction first and renames the model role', () => {
  assert.deepEqual(
    toMessages([{ role: 'user', text: 'a' }, { role: 'model', text: 'b' }], 'sys'),
    [
      { role: 'system', content: 'sys' },
      { role: 'user', content: 'a' },
      { role: 'assistant', content: 'b' },
    ],
  );
  assert.deepEqual(toMessages([], null), []);
});

test('toOpenAiParams drops thinkingBudget rather than guessing an effort level', () => {
  assert.deepEqual(
    toOpenAiParams({ temperature: 0.7, maxOutputTokens: 1024, thinkingBudget: 0 }),
    { temperature: 0.7, max_tokens: 1024 },
  );
  assert.deepEqual(toOpenAiParams(null), {});
});

test('OpenRouterProvider reads text and usage without double-counting reasoning', async () => {
  const fetchImpl = stubFetch({
    choices: [{ message: { content: '  hola  ' } }],
    // completion_tokens already includes reasoning on this API.
    usage: { prompt_tokens: 20, completion_tokens: 30, prompt_tokens_details: { cached_tokens: 4 } },
  });
  const provider = new OpenRouterProvider({ apiKey: 'k', fetchImpl });

  const reply = await provider.generate({
    model: 'google/gemini-2.5-flash-lite',
    history: [{ role: 'user', text: 'hola?' }],
    systemInstruction: 'sys',
  });

  assert.equal(fetchImpl.calls[0].body.model, 'google/gemini-2.5-flash-lite');
  assert.equal(reply.text, 'hola');
  assert.deepEqual(reply.usage, { inputTokens: 20, outputTokens: 30, cachedInputTokens: 4 });
});

test('an upstream error carries its status and never the body', async () => {
  const provider = new OpenRouterProvider({ apiKey: 'k', fetchImpl: stubFetch({}, { status: 404 }) });
  await assert.rejects(
    () => provider.generate({ model: 'gone', history: [] }),
    (err) => {
      assert.equal(err.upstreamStatus, 404);
      assert.match(err.message, /upstream 404/);
      return true;
    },
  );
});

// --- fallback --------------------------------------------------------------

/** A provider that fails the first `failures` calls with `status`, then succeeds. */
function flaky({ failures = Infinity, status = 500, reply = 'primary' } = {}) {
  let seen = 0;
  return {
    calls: [],
    async generate(req) {
      this.calls.push(req);
      seen += 1;
      if (seen <= failures) {
        const err = new Error(`upstream ${status}`);
        if (Number.isFinite(status)) err.upstreamStatus = status;
        throw err;
      }
      return reply;
    },
  };
}

test('a retired primary model falls through to the backup', async () => {
  const primary = flaky({ status: 404 });
  const backup = flaky({ failures: 0, reply: 'from backup' });
  const fb = new FallbackProvider({
    primary, backup, primaryModel: 'google/gemini-2.5-flash-lite',
    backupModel: 'gemini-3.1-flash-lite', logger: quiet,
  });

  assert.equal(await fb.generate({ model: 'whatever', history: [] }), 'from backup');
  assert.equal(primary.calls[0].model, 'google/gemini-2.5-flash-lite',
    'the deployment overrides whatever model the app asked for');
  assert.equal(backup.calls[0].model, 'gemini-3.1-flash-lite');
  assert.equal(fb.snapshot().fallback, 1);
  assert.equal(fb.snapshot().fallbackRate, 1);
});

test('a timeout or network error also falls through', async () => {
  const primary = { async generate() { throw new Error('aborted'); } };
  const backup = flaky({ failures: 0, reply: 'ok' });
  const fb = new FallbackProvider({ primary, backup, backupModel: 'b', logger: quiet });
  assert.equal(await fb.generate({ model: 'm', history: [] }), 'ok');
  assert.equal(fb.snapshot().fallback, 1);
});

test('a 400 falls over too, because that is how a retired model presents', async () => {
  // Measured, not assumed: OpenRouter answers an unknown model id with 400 and
  // "is not a valid model ID", not with 404. An earlier version of this class
  // passed 4xx straight through, which meant the one event it was built for —
  // Google finishing the retirement of gemini-2.5 — would have been an outage.
  const primary = flaky({ status: 400 });
  const backup = flaky({ failures: 0, reply: 'from backup' });
  const fb = new FallbackProvider({ primary, backup, backupModel: 'b', logger: quiet });
  assert.equal(await fb.generate({ model: 'm', history: [] }), 'from backup');
  assert.equal(backup.calls.length, 1);
  assert.equal(fb.snapshot().fallback, 1);
  assert.equal(fb.snapshot().failed, 0);
});

test('a healthy primary never touches the backup, and the counters say so', async () => {
  const primary = flaky({ failures: 0, reply: 'primary' });
  const backup = flaky({ failures: 0, reply: 'backup' });
  const fb = new FallbackProvider({ primary, backup, backupModel: 'b', logger: quiet });
  for (let i = 0; i < 3; i += 1) await fb.generate({ model: 'm', history: [] });
  const s = fb.snapshot();
  assert.equal(backup.calls.length, 0);
  assert.deepEqual([s.primary, s.fallback, s.fallbackRate], [3, 0, 0]);
});

test('both failing surfaces the backup error rather than a silent success', async () => {
  const fb = new FallbackProvider({
    primary: flaky({ status: 503 }),
    backup: flaky({ status: 500 }),
    backupModel: 'b',
    logger: quiet,
  });
  await assert.rejects(() => fb.generate({ model: 'm', history: [] }), /upstream 500/);
  assert.equal(fb.snapshot().failed, 1);
});

test('the fallback pair refuses to be built half-configured', () => {
  const p = flaky({ failures: 0 });
  assert.throws(() => new FallbackProvider({ primary: p, backup: p }), /backupModel/);
  assert.throws(() => new FallbackProvider({ primary: p, backupModel: 'b' }), /backup provider/);
});
