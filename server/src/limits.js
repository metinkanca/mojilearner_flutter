/**
 * The two spend controls this service can enforce without knowing who is
 * calling.
 *
 * That constraint is the whole design. `AI_PROXY_TOKEN` is shared by every
 * install and ships inside the APK, so there is no per-user identity to meter
 * against — only the request's source address and the total. Both controls
 * below are therefore blunt instruments, and neither is a substitute for the
 * per-account quota that becomes possible once the app sends a Firebase ID
 * token. What they do buy is a bounded worst case today, without an app
 * release.
 */

/**
 * Requests per window, per key.
 *
 * Deliberately generous. The key is a source address, and mobile traffic
 * arrives through carrier-grade NAT where thousands of unrelated users can
 * share one — so a limit tight enough to shape a single user's behaviour would
 * eventually lock out a whole carrier. This is sized to stop a script, not to
 * ration a person: the app's own cooldown caps a real user near 20 requests a
 * minute, so the default leaves room for tens of them behind one address while
 * still cutting off anything running flat out.
 */
export class SlidingWindowLimiter {
  constructor({ windowMs = 60_000, max = 600 } = {}) {
    this.windowMs = windowMs;
    this.max = max;
    /** @type {Map<string, number[]>} key -> timestamps inside the window */
    this.hits = new Map();
  }

  /** Drops keys with no hits left in the window, so the map cannot grow forever. */
  sweep(now = Date.now()) {
    const cutoff = now - this.windowMs;
    for (const [key, times] of this.hits) {
      const live = times.filter((t) => t > cutoff);
      if (live.length) this.hits.set(key, live);
      else this.hits.delete(key);
    }
  }

  /**
   * Records a hit for [key] and reports whether it is allowed.
   *
   * A blocked request still counts. Otherwise a caller hammering the limit
   * would see the window drain at exactly the rate they are refused, which is
   * a rate limiter that rewards retrying hardest.
   */
  check(key, now = Date.now()) {
    const cutoff = now - this.windowMs;
    const times = (this.hits.get(key) ?? []).filter((t) => t > cutoff);
    times.push(now);
    this.hits.set(key, times);

    if (times.length <= this.max) return { allowed: true };
    return {
      allowed: false,
      retryAfterSeconds: Math.max(
        1,
        Math.ceil((times[times.length - this.max] + this.windowMs - now) / 1000),
      ),
    };
  }
}

/**
 * A daily USD ceiling on everything this service spends.
 *
 * The backstop the rate limiter is not. A limiter bounds requests per address;
 * this bounds money in total, which is the number that actually appears on the
 * bill and the only one that holds when an abuser rotates addresses.
 *
 * Accounted after the fact, because the cost of a call is not known until the
 * provider reports its usage. The ceiling can therefore be crossed by at most
 * the calls already in flight when it is reached — a few cents, against a
 * budget denominated in dollars. Reserving an estimate up front and
 * reconciling would close that gap and is not worth the machinery.
 */
export class SpendLedger {
  /**
   * @param {{dailyBudgetUsd: number, now?: () => number}} opts
   *   `dailyBudgetUsd` of 0 or less disables the ceiling entirely.
   */
  constructor({ dailyBudgetUsd = 0, now = () => Date.now() } = {}) {
    this.dailyBudgetUsd = dailyBudgetUsd;
    this.now = now;
    this.day = this._today();
    this.spentUsd = 0;
    this.calls = 0;
  }

  get enabled() {
    return this.dailyBudgetUsd > 0;
  }

  /**
   * The current UTC day.
   *
   * UTC rather than local time on purpose: the budget is a property of the
   * deployment, and a host that reports a different timezone after a restart
   * should not be able to hand out a second day's spend.
   */
  _today() {
    return new Date(this.now()).toISOString().slice(0, 10);
  }

  _rollover() {
    const today = this._today();
    if (today === this.day) return;
    this.day = today;
    this.spentUsd = 0;
    this.calls = 0;
  }

  /** USD left today, or Infinity when no ceiling is set. */
  remaining() {
    if (!this.enabled) return Infinity;
    this._rollover();
    return Math.max(0, this.dailyBudgetUsd - this.spentUsd);
  }

  /** True when today's budget is already spent and the call should be refused. */
  exhausted() {
    return this.enabled && this.remaining() <= 0;
  }

  /**
   * Books a completed call.
   *
   * `strict: false` so an unpriced model is charged the worst rate on file
   * rather than nothing — see `pricing.js`.
   */
  record(model, usage, costFn) {
    this._rollover();
    this.calls += 1;
    const cost = costFn(model, usage, { strict: false });
    if (Number.isFinite(cost) && cost > 0) this.spentUsd += cost;
    return cost ?? 0;
  }

  /** Shape for `/healthz`, rounded to something a human reads at a glance. */
  snapshot() {
    if (!this.enabled) return { enabled: false };
    this._rollover();
    return {
      enabled: true,
      day: this.day,
      budgetUsd: this.dailyBudgetUsd,
      spentUsd: Number(this.spentUsd.toFixed(4)),
      remainingUsd: Number(this.remaining().toFixed(4)),
      calls: this.calls,
    };
  }
}

/**
 * The address a request is attributed to.
 *
 * `trustProxy` matters and defaults to off: every managed host this is likely
 * to run on (Cloud Run, Fly, Railway, Render) terminates TLS in front of the
 * process and passes the real client in `X-Forwarded-For`, so without it every
 * request shares the load balancer's address and the limiter meters one key.
 * On by default would be worse though — an unproxied deployment would let any
 * caller forge the header and hand themselves a fresh quota per request.
 */
export function clientKey(req, { trustProxy = false } = {}) {
  if (trustProxy) {
    const forwarded = req.get('x-forwarded-for');
    if (forwarded) {
      const first = forwarded.split(',')[0].trim();
      if (first) return first;
    }
  }
  return req.socket?.remoteAddress ?? req.ip ?? 'unknown';
}
