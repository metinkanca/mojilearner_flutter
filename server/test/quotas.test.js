import assert from 'node:assert/strict';
import test from 'node:test';

import {
  AccountQuotas,
  FREE,
  PREMIUM,
  QUIZ_BANK_CAP,
  REWARDED_QUIZ_HEADROOM,
  meterForBody,
} from '../src/quotas.js';

/**
 * The per-account allowance — the control `limits.js` says it cannot be.
 *
 * What matters here is that this meters a *person*: an address limiter cannot
 * tell one user from a thousand behind the same carrier NAT, and the total
 * spend ceiling cannot tell them apart either. So the assertions are about two
 * accounts being independent, and about one account not being able to reset
 * itself by retrying.
 */

test('the free and premium tables match the app', () => {
  // These are the numbers `EntitlementConstants` shows the player. If they
  // drift, the app promises an allowance the proxy will refuse.
  assert.equal(FREE.quiz, 3);
  assert.equal(FREE.message, 30);
  assert.equal(PREMIUM.quiz, 10);
  assert.equal(PREMIUM.message, 200);
});

test('modes map onto the two meters, and onboarding onto neither', () => {
  assert.equal(meterForBody({ mode: 'quiz' }), 'quiz');
  assert.equal(meterForBody({ mode: 'chat' }), 'message');
  // A learner who cannot finish being assessed has no reason to come back.
  assert.equal(meterForBody({ mode: 'assessment' }), null);
  assert.equal(meterForBody({ mode: 'level' }), null);
  assert.equal(meterForBody({}), null);
});

test('an account spends its own allowance and then is refused', () => {
  const quotas = new AccountQuotas();
  const limit = quotas.limitFor('quiz', false);

  for (let i = 0; i < limit; i += 1) {
    assert.equal(quotas.check('uid-a', 'quiz', false).allowed, true);
  }
  assert.equal(quotas.check('uid-a', 'quiz', false).allowed, false);
});

test('the quiz meter carries headroom for the ads the server cannot see', () => {
  const quotas = new AccountQuotas();

  assert.equal(
    quotas.limitFor('quiz', false),
    FREE.quiz + REWARDED_QUIZ_HEADROOM,
  );
  // Messages get none: ads buy quizzes and nothing else.
  assert.equal(quotas.limitFor('message', false), FREE.message);
});

test('two accounts do not spend each other', () => {
  const quotas = new AccountQuotas();
  const limit = quotas.limitFor('quiz', false);

  for (let i = 0; i < limit; i += 1) quotas.check('uid-a', 'quiz', false);

  assert.equal(quotas.check('uid-a', 'quiz', false).allowed, false);
  assert.equal(quotas.check('uid-b', 'quiz', false).allowed, true);
});

test('the two meters are independent', () => {
  const quotas = new AccountQuotas();
  const limit = quotas.limitFor('quiz', false);

  for (let i = 0; i < limit; i += 1) quotas.check('uid-a', 'quiz', false);

  assert.equal(quotas.check('uid-a', 'quiz', false).allowed, false);
  assert.equal(quotas.check('uid-a', 'message', false).allowed, true);
});

// Unlike the address limiter, where counting refusals is what stops the window
// draining at the rate you retry, charging a person for the request that told
// them they were out would leave them a call short tomorrow.
test('a refused request is not charged', () => {
  const quotas = new AccountQuotas();
  const limit = quotas.limitFor('quiz', false);

  for (let i = 0; i < limit; i += 1) quotas.check('uid-a', 'quiz', false);
  const before = quotas.spent('uid-a', 'quiz');

  quotas.check('uid-a', 'quiz', false);
  quotas.check('uid-a', 'quiz', false);

  assert.equal(quotas.spent('uid-a', 'quiz'), before);
});

test('a member gets the larger allowance', () => {
  const quotas = new AccountQuotas();
  const freeLimit = quotas.limitFor('message', false);

  for (let i = 0; i < freeLimit; i += 1) quotas.check('uid-a', 'message', false);

  assert.equal(quotas.check('uid-a', 'message', false).allowed, false);
  assert.equal(quotas.check('uid-a', 'message', true).allowed, true);
});

test('an unmetered mode always passes and records nothing', () => {
  const quotas = new AccountQuotas();

  for (let i = 0; i < 100; i += 1) {
    assert.equal(quotas.check('uid-a', null, false).allowed, true);
  }
  assert.equal(quotas.spent('uid-a', 'quiz'), 0);
});

test('the UTC day turning over gives the allowance back', () => {
  let now = Date.parse('2026-03-14T09:00:00Z');
  const quotas = new AccountQuotas({ now: () => now });
  const limit = quotas.limitFor('quiz', false);

  for (let i = 0; i < limit; i += 1) quotas.check('uid-a', 'quiz', false);
  assert.equal(quotas.check('uid-a', 'quiz', false).allowed, false);

  now = Date.parse('2026-03-15T00:05:00Z');

  assert.equal(quotas.check('uid-a', 'quiz', false).allowed, true);
});

test('the same UTC day is not a new one', () => {
  let now = Date.parse('2026-03-14T09:00:00Z');
  const quotas = new AccountQuotas({ now: () => now });
  const limit = quotas.limitFor('quiz', false);

  for (let i = 0; i < limit; i += 1) quotas.check('uid-a', 'quiz', false);

  now = Date.parse('2026-03-14T23:59:00Z');

  assert.equal(quotas.check('uid-a', 'quiz', false).allowed, false);
});

// The map is the only thing here that grows, so the rollover has to drop it or
// a long-running process remembers every account that ever called.
test('rolling over forgets yesterday entirely', () => {
  let now = Date.parse('2026-03-14T09:00:00Z');
  const quotas = new AccountQuotas({ now: () => now });

  quotas.check('uid-a', 'quiz', false);
  quotas.check('uid-b', 'quiz', false);
  assert.equal(quotas.snapshot().accounts, 2);

  now = Date.parse('2026-03-16T00:05:00Z');

  assert.equal(quotas.snapshot().accounts, 0);
});

// The app promises a member that unused quizzes roll over, so a proxy holding
// a flat ten a day would refuse the eleventh quiz of a day the client had
// already agreed to. What has to match between the two is the rolling total.
test('a member carries an unused day forward', () => {
  let now = Date.parse('2026-03-14T09:00:00Z');
  const quotas = new AccountQuotas({ now: () => now });

  quotas.check('uid-a', 'quiz', true);
  now = Date.parse('2026-03-15T00:05:00Z');

  assert.equal(quotas.bankedFor('uid-a', true), PREMIUM.quiz - 1);
  assert.equal(
    quotas.allowanceFor('uid-a', 'quiz', true),
    quotas.limitFor('quiz', true) + PREMIUM.quiz - 1,
  );
});

test('a member can spend the bank in one burst', () => {
  let now = Date.parse('2026-03-14T09:00:00Z');
  const quotas = new AccountQuotas({ now: () => now });

  quotas.check('uid-a', 'quiz', true);
  now = Date.parse('2026-03-15T09:00:00Z');
  const allowance = quotas.allowanceFor('uid-a', 'quiz', true);
  assert.ok(allowance > quotas.limitFor('quiz', true));

  for (let i = 0; i < allowance; i += 1) {
    assert.equal(quotas.check('uid-a', 'quiz', true).allowed, true);
  }
  assert.equal(quotas.check('uid-a', 'quiz', true).allowed, false);
});

test('a free account banks nothing', () => {
  let now = Date.parse('2026-03-14T09:00:00Z');
  const quotas = new AccountQuotas({ now: () => now });

  quotas.check('uid-a', 'quiz', false);
  now = Date.parse('2026-03-16T00:05:00Z');

  assert.equal(quotas.bankedFor('uid-a', false), 0);
  assert.equal(
    quotas.allowanceFor('uid-a', 'quiz', false),
    quotas.limitFor('quiz', false),
  );
});

test('the bank is capped however long an account is away', () => {
  let now = Date.parse('2026-03-14T09:00:00Z');
  const quotas = new AccountQuotas({ now: () => now });

  quotas.check('uid-a', 'quiz', true);
  now = Date.parse('2027-03-14T09:00:00Z');

  assert.equal(quotas.bankedFor('uid-a', true), QUIZ_BANK_CAP);
});

// The property that makes banking affordable: it can move a quiz between days
// but never conjure one, so a fortnight cannot cost more than a fortnight.
test('banking moves quizzes between days without creating any', () => {
  let day = Date.parse('2026-03-01T09:00:00Z');
  const quotas = new AccountQuotas({ now: () => day });
  let allowed = 0;

  for (let i = 0; i < 14; i += 1) {
    // Someone who studies hard every third day and not at all otherwise.
    const wanted = i % 3 === 2 ? 40 : 0;
    for (let n = 0; n < wanted; n += 1) {
      if (quotas.check('uid-a', 'quiz', true).allowed) allowed += 1;
    }
    day += 86400000;
  }

  const ceiling = 14 * (PREMIUM.quiz + REWARDED_QUIZ_HEADROOM);
  assert.ok(allowed <= ceiling, `${allowed} > ${ceiling}`);
});

// The map of banks is the one thing that now outlives a day, so it must not
// become a list of every account that ever subscribed.
test('a spent bank stops being remembered', () => {
  let now = Date.parse('2026-03-14T09:00:00Z');
  const quotas = new AccountQuotas({ now: () => now });

  // A day spent to the last quiz banks nothing...
  const limit = quotas.limitFor('quiz', true);
  for (let i = 0; i < limit; i += 1) quotas.check('uid-a', 'quiz', true);
  now = Date.parse('2026-03-15T00:05:00Z');

  assert.equal(quotas.bankedFor('uid-a', true), 0);
  assert.equal(quotas.snapshot().banking, 0);
});

test('the snapshot counts accounts without naming them', () => {
  const quotas = new AccountQuotas();
  quotas.check('uid-a', 'quiz', false);

  const snapshot = quotas.snapshot();

  assert.equal(snapshot.accounts, 1);
  assert.equal(JSON.stringify(snapshot).includes('uid-a'), false);
});
