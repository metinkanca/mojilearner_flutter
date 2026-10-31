import assert from 'node:assert/strict';
import test from 'node:test';
import { createSign, generateKeyPairSync } from 'node:crypto';

import { createApp } from '../src/app.js';
import { AppCheckKeys, appCheckTokenFrom, verifyAppCheckToken } from '../src/appcheck.js';

/**
 * App Check token verification, and what the proxy does with the result.
 *
 * As with ID tokens, nearly every case is a token that must be *refused*: an
 * accepted forgery is exactly the "script that mints accounts" this exists to
 * stop. The happy path is one test; the rest is the attack surface.
 */

const NUMBER = '592310164564';
const KID = 'appcheck-key';

const { privateKey, publicKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
const jwk = { ...publicKey.export({ format: 'jwk' }), kid: KID, alg: 'RS256', use: 'sig' };

/** Keys that never reach the network. */
const keys = new AppCheckKeys({
  fetchImpl: async () => ({ ok: true, json: async () => ({ keys: [jwk] }) }),
});

function b64(input) {
  return Buffer.from(input).toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

const NOW_MS = Date.parse('2026-10-31T09:00:00Z');
const now = () => NOW_MS;
const seconds = Math.floor(NOW_MS / 1000);

function makeToken({ header = { alg: 'RS256', kid: KID, typ: 'JWT' }, claims = {}, sign = true } = {}) {
  const body = {
    iss: `https://firebaseappcheck.googleapis.com/${NUMBER}`,
    aud: [`projects/${NUMBER}`, 'projects/mimikin-test'],
    sub: '1:592310164564:android:7ddb35a8cd8e80455a61c1',
    iat: seconds - 60,
    exp: seconds + 3600,
    ...claims,
  };
  const unsigned = `${b64(JSON.stringify(header))}.${b64(JSON.stringify(body))}`;
  if (!sign) return `${unsigned}.${b64('not-a-signature')}`;
  const signer = createSign('RSA-SHA256');
  signer.update(unsigned);
  return `${unsigned}.${signer.sign(privateKey).toString('base64url')}`;
}

const verify = (token, extra = {}) =>
  verifyAppCheckToken(token, { projectNumber: NUMBER, keys, now, ...extra });

test('a genuine token is accepted and yields the app id', async () => {
  const claims = await verify(makeToken());
  assert.equal(claims?.sub, '1:592310164564:android:7ddb35a8cd8e80455a61c1');
});

test('refuses what is not provably from the app', async (t) => {
  const cases = {
    'no token': '',
    'garbage': 'not.a.jwt.at.all',
    'wrong segment count': 'a.b',
    'bad signature': makeToken({ sign: false }),
    'alg none': makeToken({ header: { alg: 'none', kid: KID, typ: 'JWT' } }),
    'HS256 confusion': makeToken({ header: { alg: 'HS256', kid: KID, typ: 'JWT' } }),
    'missing kid': makeToken({ header: { alg: 'RS256', typ: 'JWT' } }),
    'unknown kid': makeToken({ header: { alg: 'RS256', kid: 'other', typ: 'JWT' } }),
    'wrong typ': makeToken({ header: { alg: 'RS256', kid: KID, typ: 'at+jwt' } }),
    'expired': makeToken({ claims: { exp: seconds - 1 } }),
    'issued in the future': makeToken({ claims: { iat: seconds + 3600 } }),
    'other project issuer': makeToken({ claims: { iss: 'https://firebaseappcheck.googleapis.com/111' } }),
    'other project audience': makeToken({ claims: { aud: ['projects/111'] } }),
    'no audience': makeToken({ claims: { aud: undefined } }),
    'no subject': makeToken({ claims: { sub: '' } }),
  };
  for (const [name, token] of Object.entries(cases)) {
    await t.test(name, async () => assert.equal(await verify(token), null));
  }
});

test('a token signed by someone else\'s key is refused', async () => {
  const other = generateKeyPairSync('rsa', { modulusLength: 2048 });
  const unsigned = `${b64(JSON.stringify({ alg: 'RS256', kid: KID, typ: 'JWT' }))}.${b64(JSON.stringify({
    iss: `https://firebaseappcheck.googleapis.com/${NUMBER}`,
    aud: [`projects/${NUMBER}`],
    sub: 'x',
    iat: seconds - 1,
    exp: seconds + 600,
  }))}`;
  const signer = createSign('RSA-SHA256');
  signer.update(unsigned);
  const forged = `${unsigned}.${signer.sign(other.privateKey).toString('base64url')}`;
  assert.equal(await verify(forged), null);
});

test('with no project number nothing is trusted', async () => {
  assert.equal(await verify(makeToken(), { projectNumber: '' }), null);
});

test('an unreachable key set refuses rather than throws', async () => {
  const down = new AppCheckKeys({ fetchImpl: async () => ({ ok: false, status: 503 }) });
  assert.equal(await verify(makeToken(), { keys: down }), null);
});

test('the token is read from the header the Firebase SDKs send', () => {
  const req = (value) => ({ get: (name) => (name === 'x-firebase-appcheck' ? value : undefined) });
  assert.equal(appCheckTokenFrom(req('  abc ')), 'abc');
  assert.equal(appCheckTokenFrom(req('')), '');
  assert.equal(appCheckTokenFrom(req(undefined)), '');
});

// --- the middleware ---------------------------------------------------------

const quietLogger = { info() {}, error() {} };
const stub = { async generate() { return 'hello'; } };

async function serve(opts) {
  const app = createApp({ provider: stub, logger: quietLogger, ...opts });
  const server = await new Promise((resolve) => {
    const s = app.listen(0, () => resolve(s));
  });
  const base = `http://127.0.0.1:${server.address().port}`;
  return {
    async post(headers = {}) {
      const res = await fetch(`${base}/v1/ai/generate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', ...headers },
        body: JSON.stringify({ mode: 'chat', params: {} }),
      });
      return res.status;
    },
    async health() {
      return (await fetch(`${base}/healthz`)).json();
    },
    close: () => new Promise((r) => server.close(r)),
  };
}

// 400 means "got past the App Check gate and failed on the body", which is
// all these tests need to know: the gate is what is under test.
const PASSED = 400;

test('enforce: a request without a token is refused, one with a token passes the gate', async () => {
  const s = await serve({ appCheckProjectNumber: NUMBER, appCheckEnforce: true, appCheckKeys: keys });
  try {
    assert.equal(await s.post(), 401);
    assert.equal(await s.post({ 'X-Firebase-AppCheck': 'junk' }), 401);
    // makeToken is dated for the fixed clock above; the middleware uses real
    // time, so mint one that is valid now.
    const live = makeToken({ claims: { iat: Math.floor(Date.now() / 1000) - 5, exp: Math.floor(Date.now() / 1000) + 600 } });
    assert.equal(await s.post({ 'X-Firebase-AppCheck': live }), PASSED);
  } finally {
    await s.close();
  }
});

test('monitor: nothing is refused, and the counts say what enforcing would do', async () => {
  const s = await serve({ appCheckProjectNumber: NUMBER, appCheckEnforce: false, appCheckKeys: keys });
  try {
    assert.equal(await s.post(), PASSED);
    assert.equal(await s.post({ 'X-Firebase-AppCheck': 'junk' }), PASSED);
    const live = makeToken({ claims: { iat: Math.floor(Date.now() / 1000) - 5, exp: Math.floor(Date.now() / 1000) + 600 } });
    assert.equal(await s.post({ 'X-Firebase-AppCheck': live }), PASSED);

    const health = await s.health();
    assert.deepEqual(health.appCheck, { mode: 'monitor', valid: 1, missing: 1, invalid: 1 });
  } finally {
    await s.close();
  }
});

test('without a project number the gate is not there at all', async () => {
  const s = await serve({});
  try {
    assert.equal(await s.post(), PASSED);
    assert.equal((await s.health()).appCheck, undefined);
  } finally {
    await s.close();
  }
});

test('the shared bearer token is compared in constant time and still gates', async () => {
  const s = await serve({ authToken: 'secret-token' });
  try {
    assert.equal(await s.post(), 401);
    assert.equal(await s.post({ Authorization: 'Bearer secret-tokeX' }), 401);
    assert.equal(await s.post({ Authorization: 'Bearer short' }), 401);
    assert.equal(await s.post({ Authorization: 'Bearer secret-token' }), PASSED);
  } finally {
    await s.close();
  }
});
