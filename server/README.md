# MojiLearner AI proxy

Keeps the Gemini API key off the phone.

The app never talks to Gemini directly. `lib/services/ai_service.dart` calls
three endpoints on this service, and if no proxy is configured it fails closed
— AI features degrade to local fallbacks rather than shipping a key in the APK.
That is why this exists and why the app looks half-broken without it.

## Endpoints

The shapes are fixed by the Dart client, which throws a `FormatException` on a
response missing `text` or `sessionId`. `test/contract.test.js` is the copy of
that contract on this side; change one without the other and it fails.

| | request | response |
|---|---|---|
| `POST /v1/ai/generate` | `{model, prompt, source, generationConfig?}` | `{text}` |
| `POST /v1/ai/chat/start` | `{model, source, systemInstruction, history[]}` | `{sessionId}` |
| `POST /v1/ai/chat/send` | `{model, source, sessionId, message}` | `{text}` |
| `GET /healthz` | — | `{ok, sessions}` |

`Authorization: Bearer <AI_PROXY_TOKEN>` on all three when a token is set.
`history[]` entries are `{role: 'user'|'model', text}`.

### Two behaviours worth knowing

**Empty `text` is a success, not an error.** A low `maxOutputTokens` with
thinking enabled spends the budget on reasoning and returns nothing. The app
treats empty as "use the local fallback", so this service returns it as 200.
Turning it into a 5xx would convert a soft degradation into an outage.

**`/v1/ai/chat/send` sends only a session id and one message**, so conversation
history lives here, in memory. That is the single fact that decides how this
can be hosted — see below.

## Running it

```sh
cp .env.example .env      # fill in GEMINI_API_KEY and AI_PROXY_TOKEN
npm install
npm start                 # :8080
npm test                  # contract tests, no key or network needed
```

The service refuses to start without `GEMINI_API_KEY`, and without
`AI_PROXY_TOKEN` unless you pass `ALLOW_UNAUTHENTICATED=true`. Both refusals
are deliberate: the failure mode they prevent is a surprise bill, which is not
something you find out about from a log line.

## Pointing the app at it

Build-time defines, so a deployment's URL and token stay out of the repo:

```sh
flutter build apk \
  --dart-define=AI_PROXY_BASE_URL=https://your-proxy.example.com \
  --dart-define=AI_PROXY_TOKEN=the-same-token-as-.env
```

Or edit `checkedInAiProxyBaseUrl` / `checkedInAiProxyToken` in
`lib/constants/app_runtime_config.dart` for a value you are happy to commit.

`AI_PROXY_TOKEN` ships inside the binary and can be extracted. It is not
secret in the way the Gemini key is — what it buys is a credential scoped to
this proxy that you can rotate on its own, so a leak costs you a revoked token
instead of a stolen Gemini account.

> The app depends on `flutter_dotenv` but never calls `dotenv.load()`, so a
> `.env` file in the Flutter project configures nothing. `--dart-define` and
> the constants above are the only routes that work.

## Hosting

Sessions are held in an in-memory `Map`, which is correct for one long-lived
process and wrong for more than one. Two consequences:

- **Do not run more than one instance** without replacing `MemorySessionStore`
  with a shared implementation. The endpoints only use four methods, so a Redis
  version is a small file — but round-robin across two instances without it
  means every other chat turn 410s.
- **Free tiers that sleep will drop sessions.** A conversation lasts minutes
  and keeps the instance warm, so in practice this bites between sessions
  rather than during one, and the client just starts a new session. An unknown
  session returns **410 `session_expired`**, deliberately distinct from a model
  failure, so a cold start is diagnosable from the logs.

Container hosts (Cloud Run, Fly.io, Railway, Render) work with the included
`Dockerfile`; they inject `PORT` and `index.js` reads it. Check current pricing
and sleep behaviour yourself before committing to one.

```sh
docker build -t mojilearner-ai-proxy .
docker run --rm -p 8080:8080 --env-file .env mojilearner-ai-proxy
```

## What it does not do

No rate limiting and no per-user identity — the token is shared by every
install. The app has its own client-side rate limiter in
`lib/services/ai_guard.dart`, which is a UX guard, not a defence: anyone with
the extracted token can bypass it. If this ever gets real traffic, per-device
attestation and a server-side limit are the next things to add.

Prompts and replies are never logged. Log lines carry the `source` tag, the
status, the duration and a character count, and nothing the user typed.
