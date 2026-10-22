import { createPublicKey, createVerify } from 'node:crypto';

/**
 * Who is calling, from the Firebase ID token the app sends.
 *
 * `AI_PROXY_TOKEN` says *an install of this app* is calling; it is the same
 * string for everyone and it ships inside the APK. This says *which account*,
 * which is what a per-person allowance needs — see `quotas.js`.
 *
 * Verified here rather than through `firebase-admin` on purpose. The whole job
 * is checking one RS256 signature against Google's published certificates and
 * then five claims, which is a page of code against a dependency that pulls in
 * the entire Firebase server SDK for a proxy that otherwise depends only on
 * Express. The rules implemented below are Google's documented requirements
 * for verifying an ID token directly.
 *
 * Fails closed in the sense that matters: an unverifiable token yields no uid,
 * and a request with no uid is metered as the shared anonymous bucket rather
 * than being trusted with its own allowance.
 */

const CERT_URL =
  'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

/** Google rotates these daily and sends max-age; refetching hourly is ample. */
const CERT_TTL_MS = 60 * 60 * 1000;

function decodeSegment(segment) {
  return Buffer.from(segment.replace(/-/g, '+').replace(/_/g, '/'), 'base64');
}

/**
 * Fetches and caches Google's token-signing certificates.
 *
 * Cached by kid. A token signed with a key that has already rotated out is
 * refused rather than refetched on demand: a caller who can choose the kid
 * could otherwise make this issue an outbound request per bogus token.
 */
export class TokenCerts {
  constructor({ url = CERT_URL, ttlMs = CERT_TTL_MS, fetchImpl = fetch } = {}) {
    this.url = url;
    this.ttlMs = ttlMs;
    this.fetchImpl = fetchImpl;
    this.certs = null;
    this.fetchedAt = 0;
  }

  async get() {
    const now = Date.now();
    if (this.certs && now - this.fetchedAt < this.ttlMs) return this.certs;

    const response = await this.fetchImpl(this.url);
    if (!response.ok) throw new Error(`certs ${response.status}`);
    this.certs = await response.json();
    this.fetchedAt = now;
    return this.certs;
  }
}

/**
 * Verifies a Firebase ID token and returns its claims, or null.
 *
 * Never throws: every failure path is "this request has no identity", which
 * the caller handles the same way whatever went wrong.
 *
 * @param {string} token
 * @param {{projectId: string, certs: TokenCerts, now?: () => number}} opts
 */
export async function verifyIdToken(token, { projectId, certs, now = () => Date.now() }) {
  if (!token || !projectId) return null;

  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;

    const header = JSON.parse(decodeSegment(parts[0]).toString('utf8'));
    const claims = JSON.parse(decodeSegment(parts[1]).toString('utf8'));

    // Google signs ID tokens with RS256 and nothing else. Checking this before
    // anything else is what stops an `alg: none` token being read as valid.
    if (header.alg !== 'RS256' || !header.kid) return null;

    const seconds = Math.floor(now() / 1000);
    if (typeof claims.exp !== 'number' || claims.exp <= seconds) return null;
    if (typeof claims.iat !== 'number' || claims.iat > seconds + 60) return null;
    // auth_time in the future means the token describes a sign-in that has not
    // happened, which is only possible if it was assembled rather than issued.
    if (typeof claims.auth_time === 'number' && claims.auth_time > seconds + 60) {
      return null;
    }

    // Audience and issuer are what bind the token to *this* project. Without
    // them a valid token from any other Firebase project would be accepted.
    if (claims.aud !== projectId) return null;
    if (claims.iss !== `https://securetoken.google.com/${projectId}`) return null;
    if (typeof claims.sub !== 'string' || !claims.sub) return null;

    const pem = (await certs.get())[header.kid];
    if (!pem) return null;

    const verifier = createVerify('RSA-SHA256');
    verifier.update(`${parts[0]}.${parts[1]}`);
    verifier.end();
    const ok = verifier.verify(
      createPublicKey(pem),
      decodeSegment(parts[2]),
    );
    if (!ok) return null;

    return claims;
  } catch {
    return null;
  }
}

/** The ID token on a request, from the header the app sends it in. */
export function idTokenFrom(req) {
  const header = req.get('x-id-token');
  return typeof header === 'string' && header.trim() ? header.trim() : '';
}
