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
| `POST /v1/ai/generate` | `{model, mode, params, source, generationConfig?}` | `{text}` |
| `POST /v1/ai/chat/start` | `{model, mode, params, source, history[]}` | `{sessionId}` |
| `POST /v1/ai/chat/send` | `{model, source, sessionId, message}` | `{text}` |
| `GET /healthz` | — | `{ok, sessions}` |

`Authorization: Bearer <AI_PROXY_TOKEN>` on all three when a token is set.
`history[]` entries are `{role: 'user'|'model', text}`.

### The caller names a prompt; it does not write one

`mode` picks one of the prompts in `src/prompts.js` and `params` fills in its
blanks. `chat`, `pet` and `assessment` open a session; `quiz` and `level`
answer a single generate call. An unknown mode — or a generate mode used as a
persona, or the reverse — is a 400 before the provider is touched.

| mode | params |
|---|---|
| `chat` | `targetCode`, `nativeCode`, `scenario?{title, objectives?[{id,label,bonus?,cleared?}]}`, `review?{trouble[],due[]}` |
| `pet` | `targetCode` |
| `assessment` | `targetCode`, `selfLevel` |
| `quiz` | `targetCode`, `nativeCode`, `level`, `review?{trouble[],due[]}` |
| `level` | `targetCode`, `selfLevel`, `transcript[{speaker,text}]` |

Review items are `{id, prompt, answer, kind: 'vocabulary'|'correction', lapses?}`.

There is no field in any of them that can carry a sentence of instruction, and
that is the point. Language is chosen by code from a closed set of 27; levels
normalise to one of three words; everything else — scenario titles, objective
labels, review text, transcript lines — is escaped, flattened to one line,
length-capped and rendered inside a block that tells the model it is reference
data. Caps are applied here as well as in the app, because a caller that skips
the app is exactly the caller this is for.

Before this, the client sent the finished `systemInstruction` and `prompt`
text. Anyone who pulled `AI_PROXY_TOKEN` out of the app bundle had a
general-purpose model on our bill, and a wording fix needed a store release.

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

## Spend controls

The app's own limiter in `lib/services/ai_guard.dart` is a UX guard, not a
defence — it lives in memory, resets when the app restarts, and anyone holding
the extracted token bypasses it entirely. These are the controls that actually
bound the bill. All are configured in `.env`; see it for the full commentary.

| | what it bounds | default |
|---|---|---|
| `DAILY_BUDGET_USD` | total USD per UTC day | **unset — no ceiling** |
| `RATE_LIMIT_PER_MINUTE` | requests per source address | 600 |
| `MAX_HISTORY_MESSAGES` | messages re-sent per chat turn | 16 |
| `MAX_OUTPUT_TOKENS` | ceiling on any `maxOutputTokens` | 2048 |
| `DEFAULT_THINKING_BUDGET` | reasoning when the caller sends none | 0 |

Three things are worth knowing about how they behave.

**The budget is the real control; the rate limit is not.** The rate limit keys
on the source address, and mobile traffic arrives through carrier-grade NAT
where many unrelated users share one — so it is sized to stop a script, not to
ration a person, and it does nothing at all against a caller rotating
addresses. `DAILY_BUDGET_USD` is what holds in that case. Set it.

**Exhausting either returns 429**, and the app turns any non-2xx into its local
fallback, so the degradation a user sees is the pet dozing rather than an
error. Accounting happens after each call, since the cost is not known until
the provider reports usage — so the ceiling can be crossed by whatever was
already in flight when it was reached. `/healthz` reports the day's spend and
stays answerable when the budget is gone, which is when you will want it.

**Chat now runs with an explicit generation config.** The client sends none —
`AiGenerationConfig.conversational` is empty — so chat previously ran on the
model's defaults with reasoning enabled and no output cap, and reasoning bills
at the output rate. The injected settings are exactly the ones `tools/eval`
scored 16/16 usable under, so the committed report's cost per 1k turns now
describes what the service actually does. A model that rejects
`thinkingBudget: 0` (Gemini 3.5 and 3.6 answer it with a 400) needs
`DEFAULT_THINKING_BUDGET=none`.

## The model this serves, and its net

**`google/gemini-2.5-flash-lite` via OpenRouter, with `gemini-3.1-flash-lite`
direct as the backup.** Set `OPENROUTER_API_KEY` and `OPENROUTER_MODEL` to get
it; leave them unset and the service runs Gemini direct with no fallback, at
about 3x the cost per turn.

That is a decision, not a default, and `tools/eval` is the reason. Measured
2026-08-31 at three samples per case against the 3.1 this app ships:

| | 2.5-flash-lite | 3.1-flash-lite |
|---|---|---|
| Language matrix | 48/48 usable | 48/48 |
| Off-topic / injection | 36/36 usable | 36/36 |
| Idioms — usable | 57/60 | 60/60 |
| Idioms — meaning correct | 59/60 | 60/60 |
| Cost / 1k turns | **$0.17–0.18** | $0.50–0.60 |
| Median latency | 1.5–1.7s | 1.6–3.0s |

The idiom set is the only one with a known right answer, and it holds the whole
remaining gap: all three losses are Japanese taught to a Chinese speaker — two
explanations that are correct Chinese but thick with romaji, and one real miss
where "什么意思" got a pronunciation instead of a meaning. Small, but it is a
real cell of a 27-locale app rather than a rounding error. Re-run
`npm run eval:idioms` before assuming it has gone away.

Google has closed 2.5 to new API keys, so OpenRouter's account is the only route
— a dependency on a third party's access surviving, and why the fallback is not
optional.

Four things worth knowing about how it behaves.

**The ledger prices what was served, not what was asked for.** The app keeps
requesting `gemini-3.1-flash-lite`; the deployment answers with 2.5. Billing the
requested id would overstate every call by 3x, tripping a `DAILY_BUDGET_USD=5`
ceiling at $1.50 of real spend and hiding the saving entirely. Providers report
the id that answered and `/healthz` counts against that, so a routed call logs
`cost=$0.000001 via=google/gemini-2.5-flash-lite`.

**It falls back on every primary failure, including 400.** That is not laziness.
OpenRouter answers an unknown model id with `400 … is not a valid model ID`, not
404 — so the day Google finishes retiring 2.5, the failure arrives as a 400. An
earlier version passed 4xx straight through on the theory that a malformed
request would fail identically on the backup, and it would have turned the one
event this exists for into an outage.

**It cannot detect a bad answer, only a failed one.** A primary that returns
HTTP 200 with nonsense is served as-is. Re-running `tools/eval` against whatever
model you ship is the only thing that catches that.

**Watch `routing.fallback` on `/healthz`.** The entire reason to run the cheap
primary is the price. If it starts failing permanently, every request quietly
lands on the backup, the app keeps working perfectly, and the bill triples with
nothing to announce it. That counter is the announcement:

```json
"routing": { "primary": 412, "fallback": 3, "failed": 0,
             "backupModel": "gemini-3.1-flash-lite", "fallbackRate": 0.0072 }
```

## What it still does not do

**No per-user identity.** The token is shared by every install, so nothing here
can tell one user from another — every control above is a ceiling on the
deployment as a whole, which means one abusive caller degrades service for
everyone rather than only for themselves. Fixing that properly means the app
sending a Firebase ID token and this service metering per account, which needs
an app release.

**One instance only.** Sessions live in memory; see Hosting above.

Prompts and replies are never logged. Log lines carry the `source` tag, the
status, the duration, a character count and the call's cost, and nothing the
user typed.
