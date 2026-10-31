import { createPublicKey, createVerify } from 'node:crypto';

/**
 * Firebase App Check: is this request from a genuine copy of the app?
 *
 * `AI_PROXY_TOKEN` is the same string in every APK and anyone can read it out,
 * and anonymous sign-in is open to anyone holding the public Firebase config.
 * Together that means a script can mint as many "accounts" as it likes, each
 * with a fresh daily allowance, so the per-account quota in `quotas.js` limits
 * honest players and nobody else. App Check closes that gap: the app proves,
 * through Play Integrity on Android, that it is the real build running on a real
 * device, and gets a short-lived token Google signs. A script has no such
 * token to send.
 *
 * Verified in-process against Google's published keys, for the reason
 * `identity.js` gives: one RS256 signature and a handful of claims, against a
 * dependency that brings in the whole Firebase server SDK. The rules are the
 * documented ones for verifying an App Check token from a custom backend.
 *
 * Three modes, because turning this on cannot be done blindly. Builds already
 * in testers' hands send no token, and refusing them is a decision to make on
 * evidence, not a deploy-time surprise:
 *
 *   - off:     nothing is checked (no project number configured).
 *   - monitor: tokens are checked and counted, nothing is refused.
 *   - enforce: a request without a valid token is refused with 401.
 */

const JWKS_URL = 'https://firebaseappcheck.googleapis.com/v1/jwks';

/** Google publishes these with a long max-age; an hour is ample. */
const KEYS_TTL_MS = 60 * 60 * 1000;

function decodeSegment(segment) {
  return Buffer.from(segment.replace(/-/g, '+').replace(/_/g, '/'), 'base64');
}

/**
 * Fetches and caches Google's App Check signing keys (a JWK set).
 *
 * Looked up by kid and never refetched on demand for an unknown one, so a caller
 * who can choose the kid cannot make this issue an outbound request per bogus
 * token. A genuinely rotated key is picked up when the cache expires.
 */
export class AppCheckKeys {
  constructor({ url = JWKS_URL, ttlMs = KEYS_TTL_MS, fetchImpl = fetch } = {}) {
    this.url = url;
    this.ttlMs = ttlMs;
    this.fetchImpl = fetchImpl;
    this.keys = null;
    this.fetchedAt = 0;
  }

  async get() {
    const now = Date.now();
    if (this.keys && now - this.fetchedAt < this.ttlMs) return this.keys;

    const response = await this.fetchImpl(this.url);
    if (!response.ok) throw new Error(`jwks ${response.status}`);
    const body = await response.json();
    const byKid = {};
    for (const jwk of Array.isArray(body?.keys) ? body.keys : []) {
      if (jwk && typeof jwk.kid === 'string') byKid[jwk.kid] = jwk;
    }
    this.keys = byKid;
    this.fetchedAt = now;
    return this.keys;
  }
}

/**
 * Verifies an App Check token and returns its claims, or null. Never throws:
 * every failure is "this request is not provably from the app".
 *
 * @param {string} token
 * @param {{projectNumber: string, keys: AppCheckKeys, now?: () => number}} opts
 */
export async function verifyAppCheckToken(token, { projectNumber, keys, now = () => Date.now() }) {
  if (!token || !projectNumber) return null;

  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;

    const header = JSON.parse(decodeSegment(parts[0]).toString('utf8'));
    const claims = JSON.parse(decodeSegment(parts[1]).toString('utf8'));

    if (header.alg !== 'RS256' || !header.kid) return null;
    // Google marks these `JWT`; a differently typed token is some other
    // credential that happens to be signed by the same service.
    if (header.typ !== undefined && header.typ !== 'JWT') return null;

    const seconds = Math.floor(now() / 1000);
    if (typeof claims.exp !== 'number' || claims.exp <= seconds) return null;
    if (typeof claims.iat !== 'number' || claims.iat > seconds + 60) return null;

    // Issuer and audience bind the token to *this* project. Without them a
    // token from any other Firebase project's App Check would be accepted.
    if (claims.iss !== `https://firebaseappcheck.googleapis.com/${projectNumber}`) {
      return null;
    }
    const aud = Array.isArray(claims.aud) ? claims.aud : [claims.aud];
    if (!aud.includes(`projects/${projectNumber}`)) return null;
    // The subject is the Firebase app id the token was issued to.
    if (typeof claims.sub !== 'string' || !claims.sub) return null;

    const jwk = (await keys.get())[header.kid];
    if (!jwk) return null;

    const verifier = createVerify('RSA-SHA256');
    verifier.update(`${parts[0]}.${parts[1]}`);
    verifier.end();
    const ok = verifier.verify(
      createPublicKey({ key: jwk, format: 'jwk' }),
      decodeSegment(parts[2]),
    );
    return ok ? claims : null;
  } catch {
    return null;
  }
}

/** The App Check token on a request, from the header the Firebase SDKs use. */
export function appCheckTokenFrom(req) {
  const header = req.get('x-firebase-appcheck');
  return typeof header === 'string' && header.trim() ? header.trim() : '';
}
