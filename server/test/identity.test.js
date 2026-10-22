import assert from 'node:assert/strict';
import test from 'node:test';
import { createSign, generateKeyPairSync } from 'node:crypto';

import { TokenCerts, idTokenFrom, verifyIdToken } from '../src/identity.js';

/**
 * ID token verification.
 *
 * Every test here is a token that must be *refused*, because that is the only
 * direction that matters: a forged token accepted once hands its bearer an
 * account's allowance and, once premium is read from a claim, someone else's
 * subscription. The happy path is one test; the rest is the attack surface.
 */

const PROJECT = 'mimikin-test';
const KID = 'test-key';

const { privateKey, publicKey } = generateKeyPairSync('rsa', {
  modulusLength: 2048,
});

const pem = publicKey.export({ type: 'spki', format: 'pem' }).toString();

/** Certs that never reach the network. */
const certs = new TokenCerts({
  fetchImpl: async () => ({ ok: true, json: async () => ({ [KID]: pem }) }),
});

function b64(input) {
  return Buffer.from(input)
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

const NOW_MS = Date.parse('2026-03-14T09:00:00Z');
const now = () => NOW_MS;
const seconds = Math.floor(NOW_MS / 1000);

function makeToken({
  header = { alg: 'RS256', kid: KID, typ: 'JWT' },
  claims = {},
  sign = true,
} = {}) {
  const body = {
    aud: PROJECT,
    iss: `https://securetoken.google.com/${PROJECT}`,
    sub: 'uid-a',
    iat: seconds - 60,
    exp: seconds + 3600,
    auth_time: seconds - 120,
    ...claims,
  };

  const unsigned = `${b64(JSON.stringify(header))}.${b64(JSON.stringify(body))}`;
  if (!sign) return `${unsigned}.${b64('not-a-signature')}`;

  const signer = createSign('RSA-SHA256');
  signer.update(unsigned);
  signer.end();
  return `${unsigned}.${signer.sign(privateKey, 'base64url')}`;
}

const verify = (token) => verifyIdToken(token, { projectId: PROJECT, certs, now });

test('a well-formed token yields its uid', async () => {
  const claims = await verify(makeToken());

  assert.equal(claims?.sub, 'uid-a');
});

test('a token signed by the wrong key is refused', async () => {
  const other = generateKeyPairSync('rsa', { modulusLength: 2048 });
  const unsigned = makeToken().split('.').slice(0, 2).join('.');
  const signer = createSign('RSA-SHA256');
  signer.update(unsigned);
  signer.end();
  const forged = `${unsigned}.${signer.sign(other.privateKey, 'base64url')}`;

  assert.equal(await verify(forged), null);
});

test('an unsigned token is refused', async () => {
  assert.equal(await verify(makeToken({ sign: false })), null);
});

// The classic JWT hole: trusting the header's own claim about how it was
// signed. Checked before anything touches the signature.
test('alg: none is refused', async () => {
  const token = makeToken({ header: { alg: 'none', kid: KID } });

  assert.equal(await verify(token), null);
});

test('HS256 is refused, whatever it was signed with', async () => {
  const token = makeToken({ header: { alg: 'HS256', kid: KID } });

  assert.equal(await verify(token), null);
});

// Without the audience check, a valid token minted by any other Firebase
// project would be accepted — including a project the attacker owns.
test('a token for another project is refused', async () => {
  const token = makeToken({ claims: { aud: 'someone-elses-project' } });

  assert.equal(await verify(token), null);
});

test('a token from another issuer is refused', async () => {
  const token = makeToken({
    claims: { iss: 'https://securetoken.google.com/evil' },
  });

  assert.equal(await verify(token), null);
});

test('an expired token is refused', async () => {
  const token = makeToken({ claims: { exp: seconds - 1 } });

  assert.equal(await verify(token), null);
});

test('a token issued in the future is refused', async () => {
  const token = makeToken({ claims: { iat: seconds + 600 } });

  assert.equal(await verify(token), null);
});

test('a token whose sign-in has not happened yet is refused', async () => {
  const token = makeToken({ claims: { auth_time: seconds + 600 } });

  assert.equal(await verify(token), null);
});

test('a token with no subject is refused', async () => {
  const token = makeToken({ claims: { sub: '' } });

  assert.equal(await verify(token), null);
});

// A caller who can choose the kid must not be able to make this issue an
// outbound request per bogus token.
test('an unknown key id is refused without refetching', async () => {
  let fetches = 0;
  const counting = new TokenCerts({
    fetchImpl: async () => {
      fetches += 1;
      return { ok: true, json: async () => ({ [KID]: pem }) };
    },
  });

  await verifyIdToken(makeToken(), { projectId: PROJECT, certs: counting, now });
  const before = fetches;

  for (let i = 0; i < 5; i += 1) {
    const token = makeToken({ header: { alg: 'RS256', kid: `bogus-${i}` } });
    assert.equal(
      await verifyIdToken(token, { projectId: PROJECT, certs: counting, now }),
      null,
    );
  }

  assert.equal(fetches, before);
});

test('garbage never throws, it just has no identity', async () => {
  for (const token of ['', 'not.a.token', 'a.b', '...', 'x'.repeat(5000)]) {
    assert.equal(await verify(token), null);
  }
});

test('verification is off when no project is configured', async () => {
  const claims = await verifyIdToken(makeToken(), {
    projectId: null,
    certs,
    now,
  });

  assert.equal(claims, null);
});

test('the header the app sends is where the token is read from', () => {
  const req = { get: (name) => (name === 'x-id-token' ? '  abc  ' : undefined) };

  assert.equal(idTokenFrom(req), 'abc');
  assert.equal(idTokenFrom({ get: () => undefined }), '');
});
