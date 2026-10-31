import assert from 'node:assert/strict';
import test from 'node:test';
import { createSign, generateKeyPairSync } from 'node:crypto';

import { createApp } from '../src/app.js';
import { EntitlementStore, PlayVerifier } from '../src/entitlements.js';
import { TokenCerts } from '../src/identity.js';
import { AccountQuotas, FREE, PREMIUM, REWARDED_QUIZ_HEADROOM } from '../src/quotas.js';

// What a free account may actually spend: the table plus the rewarded-ad headroom.
const FREE_LIMIT = FREE.quiz + REWARDED_QUIZ_HEADROOM;

/**
 * Plus membership, decided by Google Play and not by the app.
 *
 * The thing to protect is the paid allowance: a member gets a larger daily
 * quota, so anything that lets an account claim membership without a live
 * subscription is a free upgrade. Most cases here are claims that must fail.
 */

const PRODUCT = 'mimikin_plus_monthly';
const NOW = Date.parse('2026-10-31T09:00:00Z');
const later = new Date(NOW + 20 * 24 * 3600 * 1000).toISOString();

const sa = generateKeyPairSync('rsa', { modulusLength: 2048 });
const serviceAccount = {
  client_email: 'proxy@mimikin.iam.gserviceaccount.com',
  private_key: sa.privateKey.export({ type: 'pkcs8', format: 'pem' }).toString(),
};

/** A fake Google: one OAuth endpoint, one subscriptions endpoint. */
function fakeGoogle({ purchases = {}, authStatus = 200, playStatus = null } = {}) {
  const calls = { auth: 0, play: 0, lastAssertion: null };
  const fetchImpl = async (url, init = {}) => {
    if (String(url).startsWith('https://oauth2.googleapis.com/token')) {
      calls.auth += 1;
      calls.lastAssertion = new URLSearchParams(init.body).get('assertion');
      return { ok: authStatus === 200, status: authStatus, json: async () => ({ access_token: 'at-1', expires_in: 3600 }) };
    }
    calls.play += 1;
    if (playStatus) return { ok: false, status: playStatus, json: async () => ({}) };
    const token = decodeURIComponent(String(url).split('/tokens/')[1]);
    const purchase = purchases[token];
    if (!purchase) return { ok: false, status: 404, json: async () => ({}) };
    return { ok: true, status: 200, json: async () => purchase };
  };
  return { fetchImpl, calls };
}

const live = (extra = {}) => ({
  subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
  lineItems: [{ productId: PRODUCT, expiryTime: later }],
  ...extra,
});

function verifierWith(google) {
  return new PlayVerifier({
    serviceAccount,
    packageName: 'com.mimikin.app',
    productIds: [PRODUCT],
    fetchImpl: google.fetchImpl,
    now: () => NOW,
  });
}

// --- the verifier -----------------------------------------------------------

test('a live subscription is accepted, with the expiry Google gave', async () => {
  const google = fakeGoogle({ purchases: { good: live() } });
  const result = await verifierWith(google).verify({ productId: PRODUCT, purchaseToken: 'good' });
  assert.deepEqual(result, { valid: true, expiresAt: Date.parse(later) });
});

test('the service account signs a real RS256 assertion for Google', async () => {
  const google = fakeGoogle({ purchases: { good: live() } });
  await verifierWith(google).verify({ productId: PRODUCT, purchaseToken: 'good' });

  const [h, c, sig] = google.calls.lastAssertion.split('.');
  const claims = JSON.parse(Buffer.from(c, 'base64url'));
  assert.equal(claims.iss, serviceAccount.client_email);
  assert.equal(claims.scope, 'https://www.googleapis.com/auth/androidpublisher');
  assert.equal(JSON.parse(Buffer.from(h, 'base64url')).alg, 'RS256');
  const check = (await import('node:crypto')).createVerify('RSA-SHA256');
  check.update(`${h}.${c}`);
  assert.ok(check.verify(sa.publicKey, Buffer.from(sig, 'base64url')));
});

test('the access token is reused, not fetched per receipt', async () => {
  const google = fakeGoogle({ purchases: { a: live(), b: live() } });
  const verifier = verifierWith(google);
  await verifier.verify({ productId: PRODUCT, purchaseToken: 'a' });
  await verifier.verify({ productId: PRODUCT, purchaseToken: 'b' });
  assert.equal(google.calls.auth, 1);
  assert.equal(google.calls.play, 2);
});

test('a cancelled subscription still counts until it runs out; a held or expired one does not', async () => {
  const google = fakeGoogle({
    purchases: {
      cancelled: live({ subscriptionState: 'SUBSCRIPTION_STATE_CANCELED' }),
      grace: live({ subscriptionState: 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD' }),
      hold: live({ subscriptionState: 'SUBSCRIPTION_STATE_ON_HOLD' }),
      expired: live({ subscriptionState: 'SUBSCRIPTION_STATE_EXPIRED' }),
      paused: live({ subscriptionState: 'SUBSCRIPTION_STATE_PAUSED' }),
    },
  });
  const v = verifierWith(google);
  const ask = (t) => v.verify({ productId: PRODUCT, purchaseToken: t });
  assert.equal((await ask('cancelled')).valid, true);
  assert.equal((await ask('grace')).valid, true);
  for (const t of ['hold', 'expired', 'paused']) {
    assert.deepEqual(await ask(t), { valid: false, reason: 'not_active' }, t);
  }
});

test('refuses claims that are not a live Plus subscription', async (t) => {
  const google = fakeGoogle({
    purchases: {
      otherProduct: { subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE', lineItems: [{ productId: 'cheap_unrelated', expiryTime: later }] },
      pastExpiry: live({ lineItems: [{ productId: PRODUCT, expiryTime: new Date(NOW - 1000).toISOString() }] }),
      noExpiry: live({ lineItems: [{ productId: PRODUCT }] }),
    },
  });
  const v = verifierWith(google);
  const cases = [
    ['an unknown product id', { productId: 'free_for_all', purchaseToken: 'otherProduct' }, 'unknown_product'],
    ['a token Google has never seen', { productId: PRODUCT, purchaseToken: 'forged' }, 'not_found'],
    ['a token for a different product', { productId: PRODUCT, purchaseToken: 'otherProduct' }, 'not_found'],
    ['a subscription past its expiry', { productId: PRODUCT, purchaseToken: 'pastExpiry' }, 'expired'],
    ['no expiry time at all', { productId: PRODUCT, purchaseToken: 'noExpiry' }, 'not_found'],
    ['no token', { productId: PRODUCT, purchaseToken: '' }, 'bad_token'],
    ['an enormous token', { productId: PRODUCT, purchaseToken: 'x'.repeat(5000) }, 'bad_token'],
    ['a token that is not a string', { productId: PRODUCT, purchaseToken: { $ne: 1 } }, 'bad_token'],
  ];
  for (const [name, input, reason] of cases) {
    await t.test(name, async () => assert.deepEqual(await v.verify(input), { valid: false, reason }));
  }
});

test('Google being down is an error to retry, not "not a member"', async () => {
  const down = verifierWith(fakeGoogle({ playStatus: 503 }));
  await assert.rejects(down.verify({ productId: PRODUCT, purchaseToken: 'x' }));
  const noAuth = verifierWith(fakeGoogle({ authStatus: 401 }));
  await assert.rejects(noAuth.verify({ productId: PRODUCT, purchaseToken: 'x' }));
});

// --- the store --------------------------------------------------------------

test('membership ends at the expiry time on its own', () => {
  let t = NOW;
  const store = new EntitlementStore({ now: () => t });
  store.grant('uid-a', 'tok', NOW + 1000);
  assert.equal(store.isPremium('uid-a'), true);
  t = NOW + 1001;
  assert.equal(store.isPremium('uid-a'), false);
  assert.equal(store.isPremium('never-seen'), false);
  assert.equal(store.isPremium(''), false);
});

test('one subscription serves one account at a time', () => {
  const store = new EntitlementStore({ now: () => NOW });
  store.grant('first-phone', 'tok', NOW + 1000);
  // Reinstalled: a new anonymous uid restores the same subscription.
  store.grant('second-phone', 'tok', NOW + 1000);
  assert.equal(store.isPremium('second-phone'), true);
  assert.equal(store.isPremium('first-phone'), false, 'a shared token must not serve both');
});

// --- the endpoint and the allowance it changes -------------------------------

const PROJECT = 'mimikin-test';
const idKeys = generateKeyPairSync('rsa', { modulusLength: 2048 });
const certs = new TokenCerts({
  fetchImpl: async () => ({
    ok: true,
    json: async () => ({ kid1: idKeys.publicKey.export({ type: 'spki', format: 'pem' }).toString() }),
  }),
});

function idToken(uid) {
  const b = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const s = Math.floor(Date.now() / 1000);
  const unsigned = `${b({ alg: 'RS256', kid: 'kid1', typ: 'JWT' })}.${b({
    aud: PROJECT,
    iss: `https://securetoken.google.com/${PROJECT}`,
    sub: uid,
    iat: s - 10,
    exp: s + 3000,
    auth_time: s - 20,
  })}`;
  const signer = createSign('RSA-SHA256');
  signer.update(unsigned);
  return `${unsigned}.${signer.sign(idKeys.privateKey).toString('base64url')}`;
}

async function serve(opts = {}) {
  const google = fakeGoogle({ purchases: { good: live(), other: live() } });
  const app = createApp({
    provider: { async generate() { return 'ok'; } },
    logger: { info() {}, error() {} },
    firebaseProjectId: PROJECT,
    certs,
    quotas: new AccountQuotas(),
    verifier: verifierWith(google),
    ...opts,
  });
  const server = await new Promise((resolve) => {
    const s = app.listen(0, () => resolve(s));
  });
  const base = `http://127.0.0.1:${server.address().port}`;
  const post = async (path, body, uid) => {
    const res = await fetch(base + path, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', ...(uid ? { 'X-Id-Token': idToken(uid) } : {}) },
      body: JSON.stringify(body),
    });
    return { status: res.status, body: await res.json() };
  };
  const quiz = (uid) => post('/v1/ai/generate', {
    mode: 'quiz',
    params: { targetCode: 'fr', nativeCode: 'en', level: 'beginner' },
  }, uid);
  return { post, quiz, close: () => new Promise((r) => server.close(r)) };
}

test('a verified member gets the paid allowance; everyone else stays on free', async () => {
  const s = await serve();
  try {
    const verified = await s.post('/v1/entitlement', { productId: PRODUCT, purchaseToken: 'good' }, 'member');
    assert.equal(verified.status, 200);
    assert.equal(verified.body.premium, true);

    for (let i = 0; i < FREE_LIMIT; i += 1) assert.equal((await s.quiz('member')).status, 200);
    assert.equal((await s.quiz('member')).status, 200, 'past the free allowance');
    assert.ok(PREMIUM.quiz > FREE_LIMIT - REWARDED_QUIZ_HEADROOM);

    for (let i = 0; i < FREE_LIMIT; i += 1) assert.equal((await s.quiz('free-rider')).status, 200);
    assert.equal((await s.quiz('free-rider')).status, 429, 'an account that never proved a subscription');
  } finally {
    await s.close();
  }
});

test('a made-up purchase token buys nothing', async () => {
  const s = await serve();
  try {
    const res = await s.post('/v1/entitlement', { productId: PRODUCT, purchaseToken: 'forged' }, 'cheat');
    assert.equal(res.status, 200);
    assert.equal(res.body.premium, false);
    for (let i = 0; i < FREE_LIMIT; i += 1) await s.quiz('cheat');
    assert.equal((await s.quiz('cheat')).status, 429);
  } finally {
    await s.close();
  }
});

test('membership needs a signed-in account to attach to', async () => {
  const s = await serve();
  try {
    const none = await s.post('/v1/entitlement', { productId: PRODUCT, purchaseToken: 'good' });
    assert.equal(none.status, 401);
  } finally {
    await s.close();
  }
});

test('the same subscription cannot serve two accounts', async () => {
  const s = await serve();
  try {
    await s.post('/v1/entitlement', { productId: PRODUCT, purchaseToken: 'good' }, 'owner');
    await s.post('/v1/entitlement', { productId: PRODUCT, purchaseToken: 'good' }, 'friend');
    for (let i = 0; i < FREE_LIMIT; i += 1) await s.quiz('owner');
    assert.equal((await s.quiz('owner')).status, 429, 'the first holder lost it to the second');
    for (let i = 0; i < FREE_LIMIT; i += 1) await s.quiz('friend');
    assert.equal((await s.quiz('friend')).status, 200);
  } finally {
    await s.close();
  }
});

test('Google being unreachable is a 502 the app can retry, and grants nothing', async () => {
  const google = fakeGoogle({ playStatus: 500 });
  const s = await serve({ verifier: verifierWith(google) });
  try {
    const res = await s.post('/v1/entitlement', { productId: PRODUCT, purchaseToken: 'good' }, 'someone');
    assert.equal(res.status, 502);
    for (let i = 0; i < FREE_LIMIT; i += 1) await s.quiz('someone');
    assert.equal((await s.quiz('someone')).status, 429);
  } finally {
    await s.close();
  }
});

test('with no Play account configured the endpoint says so and nobody is a member', async () => {
  const s = await serve({ verifier: null });
  try {
    const res = await s.post('/v1/entitlement', { productId: PRODUCT, purchaseToken: 'good' }, 'someone');
    assert.equal(res.status, 501);
  } finally {
    await s.close();
  }
});

test('opening chats is capped per account, so one caller cannot flood the session store', async () => {
  const s = await serve();
  try {
    const open = (uid) => s.post('/v1/ai/chat/start', {
      mode: 'chat', params: { targetCode: 'ja', nativeCode: 'en' }, history: [],
    }, uid);
    for (let i = 0; i < FREE.sessions; i += 1) assert.equal((await open('flooder')).status, 200);
    assert.equal((await open('flooder')).status, 429);
    assert.equal((await open('someone-else')).status, 200, 'other accounts are unaffected');
  } finally {
    await s.close();
  }
});
