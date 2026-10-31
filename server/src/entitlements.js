import { createSign } from 'node:crypto';

/**
 * Who is a Mimikin Plus member, according to Google Play rather than the app.
 *
 * The app flips a local flag when a purchase completes, but that flag lives on
 * the player's phone and anyone can set it. What may raise a daily allowance has
 * to be a receipt the server checked itself, so this module asks Google Play
 * whether the purchase token the app sends is a live subscription, and
 * remembers the answer per account until the subscription's own expiry time.
 *
 * Kept in memory like the rest of this service's state (see `quotas.js`): a
 * restart drops members back to the free allowance until their app next checks
 * in, which it does on launch. That is the safe direction to be wrong in.
 */

const TOKEN_URL = 'https://oauth2.googleapis.com/token';
const SCOPE = 'https://www.googleapis.com/auth/androidpublisher';
const API = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications';

/**
 * Subscription states in which the player has paid and should have Plus.
 * CANCELED means "will not renew", and the access they paid for runs to the
 * expiry time, so it counts; ON_HOLD, PAUSED and EXPIRED do not.
 */
const ENTITLED_STATES = new Set([
  'SUBSCRIPTION_STATE_ACTIVE',
  'SUBSCRIPTION_STATE_IN_GRACE_PERIOD',
  'SUBSCRIPTION_STATE_CANCELED',
]);

/** Remembers which accounts are members, and until when. */
export class EntitlementStore {
  constructor({ now = () => Date.now() } = {}) {
    this.now = now;
    /** @type {Map<string, number>} uid -> expiry (ms since epoch) */
    this.members = new Map();
    /** @type {Map<string, string>} purchase token -> the uid holding it */
    this.holders = new Map();
  }

  /** Whether this account is a member right now. An unknown uid is not. */
  isPremium(uid) {
    if (!uid) return false;
    const expiresAt = this.members.get(uid);
    if (expiresAt === undefined) return false;
    if (expiresAt <= this.now()) {
      this.members.delete(uid);
      return false;
    }
    return true;
  }

  /**
   * Records a verified subscription for [uid] until [expiresAt].
   *
   * One purchase token is one subscription, so it can be held by one account at
   * a time. A new holder takes it and the previous one loses Plus: a player
   * restoring onto a new phone (a new anonymous uid after a reinstall) must be
   * able to, but a token handed round to ten friends keeps being stolen back and
   * serves none of them for long.
   */
  grant(uid, purchaseToken, expiresAt) {
    const previous = this.holders.get(purchaseToken);
    if (previous && previous !== uid) this.members.delete(previous);
    this.holders.set(purchaseToken, uid);
    this.members.set(uid, expiresAt);
  }

  /** Drops an account's membership, e.g. when Play says the token has lapsed. */
  revoke(uid) {
    this.members.delete(uid);
  }

  /** A count, never a list of accounts. */
  snapshot() {
    return { members: this.members.size };
  }
}

function base64url(input) {
  return Buffer.from(input).toString('base64url');
}

/**
 * Asks the Google Play Developer API about a subscription purchase token.
 *
 * Authenticates as a service account by signing an OAuth JWT itself, for the
 * reason `identity.js` gives: it is one signature and one POST, against pulling
 * in Google's whole client library for a proxy that otherwise needs only Express.
 */
export class PlayVerifier {
  /**
   * @param {{
   *   serviceAccount: {client_email: string, private_key: string},
   *   packageName: string,
   *   productIds: string[],
   *   fetchImpl?: typeof fetch,
   *   now?: () => number,
   * }} opts
   */
  constructor({ serviceAccount, packageName, productIds, fetchImpl = fetch, now = () => Date.now() }) {
    this.serviceAccount = serviceAccount;
    this.packageName = packageName;
    this.productIds = new Set(productIds);
    this.fetchImpl = fetchImpl;
    this.now = now;
    this.accessToken = null;
    this.accessTokenExpiresAt = 0;
  }

  async _accessToken() {
    if (this.accessToken && this.now() < this.accessTokenExpiresAt - 60_000) {
      return this.accessToken;
    }

    const seconds = Math.floor(this.now() / 1000);
    const unsigned = `${base64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))}.${base64url(JSON.stringify({
      iss: this.serviceAccount.client_email,
      scope: SCOPE,
      aud: TOKEN_URL,
      iat: seconds,
      exp: seconds + 3600,
    }))}`;
    const signer = createSign('RSA-SHA256');
    signer.update(unsigned);
    const assertion = `${unsigned}.${signer.sign(this.serviceAccount.private_key).toString('base64url')}`;

    const response = await this.fetchImpl(TOKEN_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion,
      }).toString(),
    });
    if (!response.ok) throw new Error(`play auth ${response.status}`);
    const body = await response.json();
    if (typeof body.access_token !== 'string') throw new Error('play auth: no token');
    this.accessToken = body.access_token;
    this.accessTokenExpiresAt = this.now() + (Number(body.expires_in) || 3600) * 1000;
    return this.accessToken;
  }

  /**
   * Whether [purchaseToken] is a live subscription to one of our Plus products.
   *
   * Returns `{valid: true, expiresAt}` or `{valid: false, reason}`; throws only
   * when Google itself could not be reached, which the caller reports as a
   * retryable failure rather than as "not a member".
   */
  async verify({ productId, purchaseToken }) {
    if (typeof productId !== 'string' || !this.productIds.has(productId)) {
      return { valid: false, reason: 'unknown_product' };
    }
    if (typeof purchaseToken !== 'string' || !purchaseToken || purchaseToken.length > 2048) {
      return { valid: false, reason: 'bad_token' };
    }

    const access = await this._accessToken();
    const url = `${API}/${encodeURIComponent(this.packageName)}/purchases/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`;
    const response = await this.fetchImpl(url, { headers: { Authorization: `Bearer ${access}` } });

    // 400 and 404 are Google's answer for a token that is not a purchase of this
    // app: a forgery or a typo, not an outage.
    if (response.status === 400 || response.status === 404) {
      return { valid: false, reason: 'not_found' };
    }
    if (!response.ok) throw new Error(`play ${response.status}`);

    const purchase = await response.json();
    if (!ENTITLED_STATES.has(purchase.subscriptionState)) {
      return { valid: false, reason: 'not_active' };
    }

    // The token must be for the product the caller named, and for one of ours:
    // otherwise a cheap unrelated subscription could be presented as Plus.
    const item = (purchase.lineItems ?? []).find((i) => i.productId === productId);
    const expiresAt = Date.parse(item?.expiryTime ?? '');
    if (!item || !Number.isFinite(expiresAt)) return { valid: false, reason: 'not_found' };
    if (expiresAt <= this.now()) return { valid: false, reason: 'expired' };

    return { valid: true, expiresAt };
  }
}
