import { createApp } from './app.js';
import { GeminiProvider } from './gemini.js';
import { MemorySessionStore } from './sessions.js';
import { SlidingWindowLimiter, SpendLedger } from './limits.js';
import { AccountQuotas } from './quotas.js';
import { OpenRouterProvider } from './openrouter.js';
import { FallbackProvider } from './fallback.js';
import { PlayVerifier } from './entitlements.js';
import { readFileSync } from 'node:fs';

/**
 * Boot: read config from the environment, refuse to start misconfigured, then
 * listen.
 *
 * The refusals are deliberate. Every one of them is a mistake that otherwise
 * shows up as a surprise bill rather than as an error.
 */

const {
  PORT = '8080',
  GEMINI_API_KEY,
  AI_PROXY_TOKEN,
  ALLOWED_MODELS,
  DEFAULT_MODEL = 'gemini-3.1-flash-lite',
  SESSION_TTL_MINUTES = '30',
  CORS_ORIGINS = '',
  ALLOW_UNAUTHENTICATED,
  DAILY_BUDGET_USD = '0',
  RATE_LIMIT_PER_MINUTE = '600',
  MAX_HISTORY_MESSAGES = '16',
  MAX_OUTPUT_TOKENS = '2048',
  DEFAULT_THINKING_BUDGET = '0',
  TRUST_PROXY,
  FIREBASE_PROJECT_ID,
  FIREBASE_PROJECT_NUMBER,
  APP_CHECK_ENFORCE,
  ALLOW_NO_BUDGET,
  PLAY_SERVICE_ACCOUNT_JSON,
  PLAY_SERVICE_ACCOUNT_FILE,
  PLAY_PACKAGE_NAME = 'com.mimikin.app',
  PLUS_PRODUCT_IDS = '',
  OPENROUTER_API_KEY,
  OPENROUTER_MODEL,
  OPENROUTER_TIMEOUT_MS = '8000',
} = process.env;

if (!GEMINI_API_KEY) {
  console.error('GEMINI_API_KEY is not set. Copy .env.example to .env and fill it in.');
  process.exit(1);
}

// An open proxy holding a billable key is a free Gemini account for whoever
// finds the URL. Running without a token has to be a deliberate act.
if (!AI_PROXY_TOKEN && ALLOW_UNAUTHENTICATED !== 'true') {
  console.error(
    'AI_PROXY_TOKEN is not set, so anyone who learns this URL can spend your Gemini quota.\n' +
    'Set a token (and the matching value in the app), or set ALLOW_UNAUTHENTICATED=true ' +
    'if this really is a throwaway local run.',
  );
  process.exit(1);
}

const allowedModels = (ALLOWED_MODELS ?? DEFAULT_MODEL)
  .split(',')
  .map((m) => m.trim())
  .filter(Boolean);

const dailyBudgetUsd = Number(DAILY_BUDGET_USD);
const ratePerMinute = Number(RATE_LIMIT_PER_MINUTE);

// Fatal unless opted out. It used to only warn, to avoid breaking deployments
// on upgrade; nothing is hosted yet, so an uncapped proxy can simply never be
// started by accident.
if (!(dailyBudgetUsd > 0)) {
  // Refused rather than warned about. AI_PROXY_TOKEN is shared by every install
  // and can be read out of the APK, and anonymous sign-in is open to anyone, so
  // the per-account allowances alone do not bound the bill: this ceiling is the
  // only thing that does. Starting without one is a choice to be made on purpose.
  if (ALLOW_NO_BUDGET !== 'true') {
    console.error(
      'DAILY_BUDGET_USD is not set, so nothing caps what this service can spend in a day. ' +
      'Set it (for example 5), or set ALLOW_NO_BUDGET=true for a throwaway local run.',
    );
    process.exit(1);
  }
  console.warn('DAILY_BUDGET_USD is not set and ALLOW_NO_BUDGET=true: spend is uncapped.');
}

// Belt to the ledger's braces, and the only one of the two that survives an
// abuser rotating addresses is the ledger — see limits.js on why this is sized
// to stop a script rather than to ration a user.
const limiter = ratePerMinute > 0
  ? new SlidingWindowLimiter({ windowMs: 60_000, max: ratePerMinute })
  : null;

// The per-account allowance, and the only control here that meters a *person*
// rather than an address or a total. Needs a project id because that is what a
// Firebase ID token is verified against; without one there is no identity to
// meter and this stays off. See quotas.js and identity.js.
const quotas = FIREBASE_PROJECT_ID ? new AccountQuotas() : null;

// App Check proves a request comes from a genuine build of the app, which is
// what stops anonymous accounts being minted by script to collect a fresh
// allowance each. Monitor first (count, refuse nothing), enforce once the
// counts in /healthz show real clients all carry a token.
if (!FIREBASE_PROJECT_NUMBER) {
  console.warn(
    'FIREBASE_PROJECT_NUMBER is not set, so App Check is off: nothing stops a script ' +
    'creating anonymous accounts to collect a fresh daily allowance for each.',
  );
}

if (!quotas) {
  console.warn(
    'FIREBASE_PROJECT_ID is not set, so per-account daily allowances are off. ' +
    'Spend is bounded only by the address limiter and the daily budget, neither ' +
    'of which can tell one user from a thousand behind the same carrier NAT.',
  );
}

/**
 * `none` disables the injected thinking budget.
 *
 * Needed because 0 is not universally accepted: Gemini 3.5 and 3.6 answer
 * `thinkingBudget: 0` with a 400, so a deployment that moves ALLOWED_MODELS on
 * to one of those has to turn the injection off or every request fails.
 */
const defaultThinkingBudget = DEFAULT_THINKING_BUDGET.trim().toLowerCase() === 'none'
  ? null
  : Number(DEFAULT_THINKING_BUDGET);

// Google Play receipt checking: what lets the server, not the app, decide who
// is a Plus member. Needs a Play Console service account with access to the app.
let verifier = null;
const plusProductIds = PLUS_PRODUCT_IDS.split(',').map((id) => id.trim()).filter(Boolean);
if (PLAY_SERVICE_ACCOUNT_JSON || PLAY_SERVICE_ACCOUNT_FILE) {
  try {
    const serviceAccount = JSON.parse(
      PLAY_SERVICE_ACCOUNT_JSON || readFileSync(PLAY_SERVICE_ACCOUNT_FILE, 'utf8'),
    );
    if (!serviceAccount.client_email || !serviceAccount.private_key) {
      throw new Error('missing client_email or private_key');
    }
    if (!plusProductIds.length) throw new Error('PLUS_PRODUCT_IDS is empty');
    verifier = new PlayVerifier({
      serviceAccount,
      packageName: PLAY_PACKAGE_NAME,
      productIds: plusProductIds,
    });
  } catch (err) {
    console.error(`Play receipt checking is NOT enabled: ${err.message}`);
    process.exit(1);
  }
} else {
  console.warn(
    'No Play service account configured, so every account is metered at the free tier ' +
    'and paying members do not get the larger server allowance.',
  );
}

const gemini = new GeminiProvider({ apiKey: GEMINI_API_KEY });

/**
 * Serve from OpenRouter when it is configured, and fall back to Gemini direct.
 *
 * Set both OPENROUTER_API_KEY and OPENROUTER_MODEL to turn this on. The reason
 * it is opt-in rather than automatic: the model worth routing this way
 * (gemini-2.5-flash-lite) is one Google has closed to new keys, so a deployment
 * has to say out loud that it wants a model reachable only through a third
 * party. With neither set, this service behaves exactly as it did before.
 */
const provider = OPENROUTER_API_KEY && OPENROUTER_MODEL
  ? new FallbackProvider({
      primary: new OpenRouterProvider({
        apiKey: OPENROUTER_API_KEY,
        timeoutMs: Number(OPENROUTER_TIMEOUT_MS),
        referer: 'https://mimikin.app',
        title: 'Mimikin',
      }),
      backup: gemini,
      // The app asks for whatever it was built with; the deployment decides
      // what actually answers. That is what makes this switchable without a
      // release.
      primaryModel: OPENROUTER_MODEL,
      backupModel: DEFAULT_MODEL,
    })
  : gemini;

const app = createApp({
  provider,
  sessions: new MemorySessionStore({
    ttlMs: Number(SESSION_TTL_MINUTES) * 60 * 1000,
    maxHistory: Number(MAX_HISTORY_MESSAGES),
  }),
  authToken: AI_PROXY_TOKEN || null,
  allowedModels,
  defaultModel: DEFAULT_MODEL,
  corsOrigins: CORS_ORIGINS.split(',').map((o) => o.trim()).filter(Boolean),
  limiter,
  spend: new SpendLedger({ dailyBudgetUsd }),
  quotas,
  firebaseProjectId: FIREBASE_PROJECT_ID || null,
  verifier,
  appCheckProjectNumber: FIREBASE_PROJECT_NUMBER || null,
  appCheckEnforce: APP_CHECK_ENFORCE === 'true',
  trustProxy: TRUST_PROXY === 'true',
  maxOutputTokensCap: Number(MAX_OUTPUT_TOKENS),
  defaultThinkingBudget,
});

app.listen(Number(PORT), () => {
  console.info(
    `ai-proxy listening on :${PORT}  models=[${allowedModels.join(', ')}]  ` +
    `auth=${AI_PROXY_TOKEN ? 'on' : 'OFF'}  ` +
    `route=${OPENROUTER_API_KEY && OPENROUTER_MODEL ? `${OPENROUTER_MODEL} -> ${DEFAULT_MODEL}` : 'gemini direct'}  ` +
    `budget=${dailyBudgetUsd > 0 ? `$${dailyBudgetUsd}/day` : 'OFF'}  ` +
    `rate=${limiter ? `${ratePerMinute}/min/ip` : 'OFF'}  ` +
    `quotas=${quotas ? 'per-account' : 'OFF'}  ` +
    `history=${MAX_HISTORY_MESSAGES}`,
  );
});
