/**
 * Per-account daily allowances.
 *
 * `limits.js` opens by explaining what it cannot do: `AI_PROXY_TOKEN` ships
 * inside the APK, so a source address and a total spend were the only things
 * to meter against, and neither "is a substitute for the per-account quota
 * that becomes possible once the app sends a Firebase ID token". This is that
 * quota.
 *
 * It matters because the app's own copy of these numbers
 * (`lib/constants/entitlements.dart`) is UX, not enforcement: a rebuilt client
 * can set its premium flag and skip its own meter entirely. The numbers here
 * are the ones that actually decide whether a model gets called, so they have
 * to agree with the app's — see `FREE` and `PREMIUM` below, which are the same
 * pair as `EntitlementConstants`.
 *
 * Held in memory on purpose, and that is a real limitation rather than an
 * oversight: a restart hands everyone a fresh day and forgets every quiz bank
 * (see `QUIZ_BANK_CAP`), and two instances behind a load balancer meter
 * separately. Both are acceptable while the ceiling that bounds the bill is
 * `SpendLedger`, which is a hard total. Moving this to a shared store is the
 * change to make when the deployment stops being one process, and the
 * interface here is deliberately small enough to swap.
 */

/**
 * Which meter a request draws on, keyed by the `mode` the client sends.
 *
 * `assessment` and `level` are deliberately unmetered. Both belong to
 * onboarding, they happen a handful of times in an account's life, and a
 * learner who cannot finish being assessed has no reason to come back at all.
 */
export const METER_BY_MODE = {
  quiz: 'quiz',
  chat: 'message',
  // The starter words a learner is given at the end of onboarding, and again
  // when the words the games draw on run thin. Small and its own: it must not
  // take from the quizzes or the messages.
  starter: 'words',
};

/**
 * The free tier. Mirrors `EntitlementConstants.free`.
 *
 * `sessions` is not shown to the player: it caps how many chats an account can
 * open in a day. Opening one costs the proxy memory, and an unlimited number
 * would let one caller push everyone else's live chats out of the capped
 * session store. Generous, since the app opens one per chat, scenario and
 * assessment; it only has to stop a script.
 */
export const FREE = { quiz: 3, message: 80, words: 3, sessions: 60 };

/** What Mimikin Plus buys. Mirrors `EntitlementConstants.premium`. */
export const PREMIUM = { quiz: 10, message: 300, words: 6, sessions: 150 };

/**
 * The most extra quizzes rewarded ads can add in a day.
 *
 * The server cannot see an ad being watched, so rather than trusting a client
 * that says one was, every account simply gets this much headroom on the quiz
 * meter. It costs at most five generations a day for a free account that never
 * watched anything, and it means the honest player who did watch an ad is
 * never refused by the proxy after the app told them they had earned one.
 *
 * Sized from `AdsConstants.rewardedDailyLimit` on the app side.
 */
export const REWARDED_QUIZ_HEADROOM = 5;

/**
 * The most unused quizzes a member carries between days.
 *
 * Mirrors `EntitlementConstants.quizBankCap`, and it has to be mirrored: the
 * app tells a member their unused quizzes roll over, so a proxy enforcing a
 * flat ten a day would refuse the eleventh quiz of a day the client already
 * promised. What has to agree between the two is the rolling total, not the
 * daily one.
 *
 * It cannot raise what an account costs over a week — a bank only fills with
 * quizzes that were not generated — so the ceiling this lifts is burst, not
 * spend.
 *
 * A restart drops every bank, which is the wrong direction to fail in: the
 * server would refuse a quiz the app still believes is banked. It is survivable
 * because the same restart clears the day's counters, so the member is handed
 * a whole fresh allowance in place of the bank they lost, and only a burst
 * already past that allowance notices. The fix is the same one the class doc
 * names for everything else here: a shared store, when the deployment stops
 * being one process.
 */
export const QUIZ_BANK_CAP = 30;

/**
 * Per-account daily counters.
 *
 * Days roll over in UTC, matching `SpendLedger` and for the same reason: the
 * budget is a property of the deployment, and a host reporting a different
 * timezone after a restart should not hand out a second day's allowance.
 * The app rolls over on the device's local calendar instead, so the two can
 * disagree by up to a day's offset at the boundary — which is why the
 * server's allowance is the more generous of the two at every tier, and the
 * app's meter is the one a player normally meets.
 */
export class AccountQuotas {
  /**
   * @param {{free?: object, premium?: object, now?: () => number}} opts
   */
  constructor({ free = FREE, premium = PREMIUM, now = () => Date.now() } = {}) {
    this.free = free;
    this.premium = premium;
    this.now = now;
    this.day = this._today();
    /** @type {Map<string, Record<string, number>>} uid -> meter -> used */
    this.used = new Map();
    /** @type {Map<string, number>} uid -> quizzes carried in from other days */
    this.banked = new Map();
    /** Accounts that have made a member's request today. @type {Set<string>} */
    this.members = new Set();
  }

  _today() {
    return new Date(this.now()).toISOString().slice(0, 10);
  }

  /** Whole days between two `YYYY-MM-DD` stamps. */
  _daysBetween(from, to) {
    return Math.round((Date.parse(to) - Date.parse(from)) / 86400000);
  }

  /**
   * Clears every counter when the UTC day turns over, banking whatever the
   * members among them did not use.
   *
   * Dropping the whole map rather than walking it also bounds memory: an
   * account that studied yesterday and not today stops being remembered. The
   * bank is the one thing that outlives the day, so it is kept in a map of its
   * own that holds nothing but a small integer, and only for the accounts that
   * have one.
   */
  _rollover() {
    const today = this._today();
    if (today === this.day) return;

    const elapsed = this._daysBetween(this.day, today);
    const banked = new Map();

    // Members who closed a day keep what they did not spend of it...
    for (const uid of this.members) {
      const spent = this.used.get(uid)?.quiz ?? 0;
      banked.set(uid, this._bankAfter(this.banked.get(uid) ?? 0, spent, elapsed));
    }

    // ...and so does a member already carrying one who did not call at all.
    // Whether they are still a member is not knowable from here, so this
    // assumes they are — generous, and bounded by the cap either way.
    for (const [uid, bank] of this.banked) {
      if (banked.has(uid)) continue;
      banked.set(uid, this._bankAfter(bank, 0, elapsed));
    }

    this.banked = new Map([...banked].filter(([, bank]) => bank > 0));
    this.day = today;
    this.used.clear();
    this.members.clear();
  }

  /**
   * A bank once [elapsed] days have closed, the first of which spent
   * [spentQuiz] quizzes.
   *
   * The draw and the leftover are never both non-zero: an account either
   * finished the day inside its own allowance and banked the rest, or went
   * past it and took the difference out of the bank.
   */
  _bankAfter(bank, spentQuiz, elapsed) {
    const own = this.premium.quiz + REWARDED_QUIZ_HEADROOM;
    const drawn = Math.max(0, spentQuiz - own);
    const leftover = Math.max(0, this.premium.quiz - spentQuiz);
    const unopened = Math.max(0, elapsed - 1);

    return Math.min(
      QUIZ_BANK_CAP,
      Math.max(0, bank - drawn + leftover + unopened * this.premium.quiz),
    );
  }

  /** What [meter] allows [isPremium] accounts, including the ad headroom. */
  limitFor(meter, isPremium) {
    const table = isPremium ? this.premium : this.free;
    const base = table[meter];
    if (base === undefined) return Infinity;
    return meter === 'quiz' ? base + REWARDED_QUIZ_HEADROOM : base;
  }

  /** Quizzes [uid] has carried in from other days. Members only. */
  bankedFor(uid, isPremium) {
    if (!isPremium) return 0;
    this._rollover();
    return this.banked.get(uid) ?? 0;
  }

  /**
   * Everything [uid] may spend on [meter] today: the day's own limit, plus
   * anything banked.
   */
  allowanceFor(uid, meter, isPremium) {
    const limit = this.limitFor(meter, isPremium);
    if (limit === Infinity || meter !== 'quiz') return limit;
    return limit + this.bankedFor(uid, isPremium);
  }

  spent(uid, meter) {
    this._rollover();
    return this.used.get(uid)?.[meter] ?? 0;
  }

  remaining(uid, meter, isPremium) {
    const limit = this.allowanceFor(uid, meter, isPremium);
    if (limit === Infinity) return Infinity;
    return Math.max(0, limit - this.spent(uid, meter));
  }

  /**
   * Records one call against [uid] and reports whether it was allowed.
   *
   * Unlike `SlidingWindowLimiter.check`, a refused call is *not* counted. That
   * limiter is shaped against a script hammering an address, where counting
   * refusals is what stops the window draining at the rate you retry. This is
   * a person's daily allowance: charging them for the request that told them
   * they were out would mean a client retrying once left them a call short
   * tomorrow — and worse, the number the app shows would stop matching.
   *
   * An unmetered mode always passes and records nothing.
   */
  check(uid, meter, isPremium) {
    if (!uid || !meter) return { allowed: true };

    const limit = this.allowanceFor(uid, meter, isPremium);
    if (limit === Infinity) return { allowed: true };

    const current = this.spent(uid, meter);
    if (current >= limit) {
      return { allowed: false, meter, limit, used: current };
    }

    const forUid = this.used.get(uid) ?? {};
    forUid[meter] = current + 1;
    this.used.set(uid, forUid);
    // Remembered so the rollover knows whose leftovers to bank. Recorded from
    // the request rather than looked up, for the same reason the allowance is:
    // the tier is whatever the verified token said at the point of the call.
    if (isPremium) this.members.add(uid);
    return { allowed: true, meter, limit, used: forUid[meter] };
  }

  /** Shape for `/healthz`. Deliberately a count, never a list of accounts. */
  snapshot() {
    this._rollover();
    return {
      day: this.day,
      accounts: this.used.size,
      banking: this.banked.size,
      free: this.free,
      premium: this.premium,
    };
  }
}

/** The meter a request body draws on, or null when the mode is unmetered. */
export function meterForBody(body) {
  const mode = typeof body?.mode === 'string' ? body.mode : '';
  return METER_BY_MODE[mode] ?? null;
}
