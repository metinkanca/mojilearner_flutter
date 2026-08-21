import { createApp } from './app.js';
import { GeminiProvider } from './gemini.js';
import { MemorySessionStore } from './sessions.js';

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
  DEFAULT_MODEL = 'gemini-2.5-flash',
  SESSION_TTL_MINUTES = '30',
  ALLOW_UNAUTHENTICATED,
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

const app = createApp({
  provider: new GeminiProvider({ apiKey: GEMINI_API_KEY }),
  sessions: new MemorySessionStore({
    ttlMs: Number(SESSION_TTL_MINUTES) * 60 * 1000,
  }),
  authToken: AI_PROXY_TOKEN || null,
  allowedModels,
  defaultModel: DEFAULT_MODEL,
});

app.listen(Number(PORT), () => {
  console.info(
    `ai-proxy listening on :${PORT}  models=[${allowedModels.join(', ')}]  ` +
    `auth=${AI_PROXY_TOKEN ? 'on' : 'OFF'}`,
  );
});
