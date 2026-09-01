# Model evaluation

Answers one question: **can a cheaper model teach as well as the one we ship?**

The app's output *is* the product. A model that saves 95% on inference but
produces unnatural Japanese, or explains grammar in English to a Turkish
speaker, is not cheaper — it is a worse app that costs less to run. This
harness exists so that trade is measured rather than guessed.

## Running it

```sh
cd server
npm run eval:prices               # no key needed — check the price table first
npm run eval:mock                 # no keys, no spend — verifies the harness
OPENROUTER_API_KEY=sk-or-... GEMINI_API_KEY=... npm run eval
```

Check prices before a run, not after. They move: between 2026-08-24 and
2026-08-30, `gemini-3.7-flash` doubled and `deepseek-v4-flash` rose 41%, which
is enough to reorder a shortlist. `npm run eval:prices` reports drift and exits
non-zero; `-- --write` applies it to `src/pricing.js`, which is also what the
running service costs its daily budget against.

Useful flags:

```sh
node tools/eval/run.mjs --models google/gemini-2.5-flash,deepseek/deepseek-v4-flash
node tools/eval/run.mjs --repeat 3      # sample variance, not one lucky roll
node tools/eval/run.mjs --only ja-      # just the Japanese cases
node tools/eval/run.mjs --cases cases-idioms.json   # a focused set
```

Three case files, run separately so a focused set is not diluted into the
language matrix: `cases.json` (the 16-case matrix), `cases-offtopic.json`
(adversarial drift), and `cases-idioms.json` (known answers — see below).

Output lands in `tools/eval/results/` (gitignored), and a `--mock` run lands in
`tools/eval/results/mock/` so it cannot overwrite a real one. It used to, and
did — since the directory is gitignored, a real 16-case result was
unrecoverable.

## What it measures, and what it refuses to

The evaluation splits in two, because the question does.

**`report.md` — decided by machine.** Most of what makes a tutor reply
*unusable* needs no judgement. These are gates, not scores:

| Check | Why it is a gate |
|---|---|
| Format | Every section the app's parser needs is present. A missing `GRAMMAR:` renders as a blank panel. |
| Target script | The `TEXT` line is actually in the target language's script — not English, not bare romaji. The commonest small-model failure. |
| Reading romanized | A `READING` line still in the target script has romanized nothing. |
| Native language | The explanation reaches the learner in a language they read. |
| Persona | No leaked system prompt, no "as an AI". |

Alongside them: input/output tokens, latency, and cost per 1000 turns at the
prices in `providers.mjs`.

**`blind.md` — decided by a person.** Whether the Japanese is *natural* and
whether the grammar explanation is *true* cannot be scored by regex, and this
harness does not pretend otherwise. Model identities are shuffled per case
behind A/B labels, with the key held in `blind-key.json`. Rate every case
before opening the key.

A model that fails the gates is out regardless of how it reads. A model that
passes the gates is decided in `blind.md`.

## Case design

`cases.json` is small on purpose but not arbitrary. The riskiest cell in the
matrix is **non-Latin target taught in a non-English native language** —
Japanese explained in Turkish, Korean explained in Greek. That is where a
weaker model quietly falls back to English, and with 27 shipped locales it is
a large share of real sessions rather than an edge case.

The set also covers Latin-script targets, tracked scenario roleplay, learner
error correction, a prompt-injection attempt against the security preamble,
off-topic drift, an invitation to write a wall of text, and a near-empty turn.

## Keeping it honest

- **The prompt must match production.** `prompt.mjs` is a port of the
  instruction built in `lib/screens/chat_screen.dart`. When that changes,
  change this — an eval on a prompt nobody ships measures nothing.
- **Prices are a snapshot** (2026-08-24, from OpenRouter's `/api/v1/models`).
  Promotional rates expire. Re-check before deciding.
- **Pin a dated snapshot** when you switch, not a `-latest` alias, so quality
  cannot shift under you without a deploy.
- **The scorers are tested** (`scorers.test.mjs`, `npm test`). They decide
  which model wins, so they are not trusted until they pass.
- **A scorer change is a change to every past conclusion.** `npm run
  eval:rescore` applies the current scorers to the replies saved in every
  archived `raw.json` and prints only the verdicts that move. It costs nothing
  — the replies are already on disk — and it is the cheap answer to "does this
  fix invalidate what we decided last week?". Two examples from its first run:
  the `nativeScript` fix rescued two `ko-el-intro` replies that were correct
  Greek scored at 0.58 for quoting Hangul, and three pre-`targetLanguage`
  archives turned out to contain `TEXT: "Let's focus on learning Spanish!"`
  passing as Spanish.

## Known answers: the idiom set

Everything above measures *form*. `report.md` can tell you a reply was
parseable and in the right script; it cannot tell you the teaching was true,
and the file says so.

Idioms are the exception, and for the reason that makes them hard to teach: an
idiom has a settled meaning its own words do not give you. A model that reaches
for the words produces something fluent, well-formatted and wrong — the failure
that is hardest to notice in production, because nothing about it looks broken.
So there is one place in this harness where a machine can check correctness, and
`cases-idioms.json` is it.

```sh
npm run eval -- --cases cases-idioms.json --repeat 3 --models "..."
npm run eval:mock -- --cases cases-idioms.json     # no keys; exercises the scorer
```

Each case carries an `expect` block:

```json
"expect": {
  "anyOf": [["futil", "no use", "drop in the bucket"]],
  "notLiteralOnly": ["hot stone", "pouring water"]
}
```

`anyOf` is a list of groups; a group is satisfied by any one of its terms, and
the answer is right only when every group is satisfied. Terms are anchored on
the left at a word boundary and open on the right, so `futil` covers futile and
futility — keep them long enough that the open edge cannot collide. CJK terms
match as plain substrings, having no word boundaries to anchor to.

`notLiteralOnly` holds the words of the literal reading and of the published
wrong gloss. It fails **only when the meaning was missed**, because a good
answer routinely says "literally 'water on a hot stone', so: a futile gesture",
and a check that punished that would select against the model you want.

Only TRANS and GRAMMAR are searched. TEXT is in the language being learned, and
an idiom lesson whose meaning appears only there has taught nobody anything.

### Where the answers come from, and where they do not

The idioms are sampled from [IdiomKB](https://github.com/lisd0929/IdiomKB)
(AAAI 2024) — 12,903 idioms across English, Chinese and Japanese, each glossed
in all three. Point `idiomkb.mjs` at a checkout for a validation report:

```sh
node tools/eval/idiomkb.mjs --dir /path/to/IdiomKB/data
node tools/eval/idiomkb.mjs --dir /path/to/IdiomKB/data --lang ja --find 足元
```

**The gold answers are not IdiomKB's.** Its glosses were distilled from
`gpt-3.5-turbo-0613`, which its own README admits, and the Japanese set carries
that model's failure mode wholesale:

| Idiom | IdiomKB | Actually means |
|---|---|---|
| 鯖を読む | "to read the room" | to fudge a count, usually your age |
| 一杯食う | "to eat a lot" | to be taken in by a trick |
| 首が回らない | "lack of flexibility" | to be up to your neck in debt |
| 足元を見る | "to be cautious, mindful" | to exploit someone's weak position |
| 油を売る | "to talk someone into buying" | to slack off chatting |
| 情けは人の為ならず | "being too kind has bad consequences" | kindness comes back to you |

Every one of those is the literal reading, or a near-neighbour idiom, in place
of the meaning. Scoring a model against them would fail it *for being right* —
an eval that selects for the weaker model is worse than no eval at all.

So the dataset is used as a **candidate pool**, not a key. `idiomkb.mjs` does
the mechanical filtering it can (contamination, generation errors, glosses that
merely restate the idiom); the meanings in `cases-idioms.json` are verified by
hand, and each case records `idiomkb`, `verified` and `agreesWithIdiomKB` so
the call can be audited rather than taken on trust. Six of the twenty cases are
idioms where IdiomKB is wrong in the literal direction — those double as trap
cases, since a model that agrees with it there has made the same mistake.

Note that the dataset can disagree with itself inside one row: for
情けは人の為ならず its `ja_meaning` states the correct sense while its
`en_meaning` states the misreading. The English field is the least reliable one
for Japanese idioms.

### What this scoring cannot do

The term lists are recall-limited, and knowingly so. A model that writes "a loss
may turn out to be a gain" and one that writes "misfortune can be a blessing"
mean the same thing, and only a list that anticipated both scores both. The
lists here were grown against real replies for exactly that reason — which means
**a "meaning missed" verdict is a prompt to read the reply in `raw.json`, not a
verdict on the model.** Every miss in the first run but one turned out to be a
gap in the list rather than a fault in the answer.

What survives that scrutiny is worth having: in the run behind this section,
one model taught 焼け石に水 as "the proverb about water on a hot stone" and
spent the lesson on the word ことわざ instead. That is a real failure, it is the
exact failure the set exists to catch, and no format check would have seen it.
