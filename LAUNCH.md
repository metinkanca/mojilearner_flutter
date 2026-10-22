# Launch and revenue checklist

Written 2026-10-22 from a read of `ROADMAP.md`, `MONETISATION.md`, `ADS.md`,
`SEASON_PASS.md`, `HALLOWEEN_PASS.md`, the proxy's cost code and `pubspec.yaml`.
The design of the economy is far ahead of the machinery that sells it and
measures it, so this list is about closing that gap. `ROADMAP.md` is the
polish list; this is what has to be true before polish earns anything.

Tick boxes as things land. Items are in the order to do them.

## Decided

- **No free trial for now.** Wait until there is real data on conversion and
  retention to know the app is in a good spot to give one away. Revisit after
  the closed beta (step 4), not before.
- **Plus prices (2026-10-22): $4.99 a month, $39.99 a year** (about $3.33 a
  month, 33% off). US list prices; local prices are set per country (step 1).
- **Don't price too cheap.** The model cost of a member is the same in every
  country, so a deep regional discount cuts straight into margin. Floors below.
- **AI model: Gemini 2.5 Flash Lite through OpenRouter, with Gemini 3.1 Flash
  Lite direct as the backup.** This is already how the proxy is built (see
  "AI model plan").
- **Live testing with the OpenRouter balance is for later**, when the owner
  says so. Nothing is spent until then.

## 1. Make something buyable

Nothing can be bought today. Every paid surface says "not open yet", and the
ads serve Google's test inventory, which earns nothing in a release build while
looking exactly like success.

- [x] Plus pricing decided: $4.99 monthly, $39.99 annual
- [ ] Regional prices set per country in Play Console (one subscription, two
      base plans, a price per country for each). Don't leave Play's automatic
      exchange-rate conversion on: it ignores purchasing power, so low-income
      markets end up priced far too high and convert badly. Don't discount
      deeply either. Starting point, to be tuned from the beta:
      - Full price (US, Canada, UK, Western Europe, Japan, Korea, Australia):
        $4.99 / $39.99 in local currency, with local price endings
      - Middle (Eastern and Southern Europe, Turkey, Brazil, Mexico, Chile,
        Gulf states): about 60 to 75% of full price
      - Lower (India, Indonesia, Vietnam, Philippines, Egypt, Nigeria): about
        40 to 50% of full price, and no lower
      The percentages are judgement, not measured: the research found no
      authoritative conversion data by region (see "Pricing research").
- [ ] Keep the arbitrage risk in mind: a very cheap country invites people to
      buy there. Another reason for a floor
- [ ] Store products created in Play Console (and App Store Connect when iOS is
      real): Plus monthly, Plus annual, six coin packs as **consumables** at the
      ids in `coin_packs.dart`, season pass `com.mimikin.app.pass.season1` as a
      non-consumable
- [ ] Release build passes `IAP_PLUS_MONTHLY` / `IAP_PLUS_ANNUAL`
- [ ] **Server-side receipt validation.** The one unfinished link: until it
      exists the proxy meters every account at the free tier, so a subscriber
      gets the app's larger allowance but not the server's
- [ ] Real AdMob app and unit ids (checklist in `ADS.md`, "Before release")
- [ ] Proxy hosted, with `FIREBASE_PROJECT_ID` set so per-account quotas turn on
- [ ] Margin check before the regional prices are final: cost of a Plus member
      at the full daily allowance (10 quizzes, 300 messages) against what the
      owner nets in each price tier (after the store's cut, and tax where the
      price includes it), using real token counts from the proxy's spend ledger.
      Rough figures, not measured: chat on the primary model is about $0.00018 a
      turn (from the proxy's own eval), so 300 messages a day for 30 days is
      about $1.60, and a free player's 80 a day is about $0.43 a month. Quiz
      generation cost is not recorded anywhere I found. On the 3.1 backup
      everything costs about 3x, which puts a Plus member who maxes every day
      at about $4.90 a month: roughly the whole of the net revenue, so it only
      works while the primary model serves. If a tier's net doesn't comfortably
      clear the backup-model ceiling, lower the 300-message cap before lowering
      the price further

- [x] Free AI messages raised from 30 to 80 a day (Plus 300), because a daily
      player doing a few town scenarios could meet the wall on a first day.
      Re-check with real scenario runs in the live test
- [x] Release builds drop the stock words and sentences, so the toy chest is
      played with the player's own words; a game they have too few for stays
      shut and says so. Needs the generated daily pack before Fetch the Words
      and the "related words" can open (see `BOSS_PLAN.md`)

### AI model plan

What the code already does (`server/src/fallback.js`, `server/.env.example`):

- **Primary:** `google/gemini-2.5-flash-lite` on OpenRouter
  (`OPENROUTER_MODEL`). Google closed 2.5 to new direct API keys, so
  OpenRouter's own account is the only route. Eval 2026-08-31: about $0.17 to
  $0.18 per 1,000 chat turns, 1.5 to 1.7 s median.
- **Backup:** `gemini-3.1-flash-lite` direct (`DEFAULT_MODEL`), about 3x the
  cost per turn. Any primary failure, including OpenRouter's 400 for an unknown
  model, falls through to it. The app keeps working and the bill goes up.
- `/healthz` reports counts of primary, fallback and failed calls.

State checked 2026-10-22:

- OpenRouter lists three endpoints for 2.5 Flash Lite, all served by Google AI
  Studio, at $0.10 in and $0.40 out per million tokens, which matches
  `server/src/pricing.js`. No deprecation or expiry field.
- Google's Gemini API deprecations page says "no shutdown date announced". Its
  Vertex AI page reportedly lists 2026-10-20, but OpenRouter isn't using Vertex
  for this model, so that date shouldn't apply to our route. Nobody from Google
  has explained the difference (forum thread of 2026-08-11).
- Users reported 404s for 2.5 Flash and Flash Lite on 2026-07-09 that came
  back. So the ceiling can move without warning.
- Google's own note (owner's screenshot, 2026-10-22): the 2.5 models "are not
  deprecated and will continue to be served until further notice", access is
  limited to accounts that have used them before, and 2.5 Flash and Flash Lite
  both show "no shutdown date announced". That fits what we see: new direct
  keys get a 404, while OpenRouter's account still reaches it. It is a
  statement of intent, not a date. The same note points new projects at 3.5
  Flash-Lite and 3.8 Flash, which may be better or cheaper than the 3.1
  backup; worth an eval run once the live test is done.

To do:

- [ ] Watch `/healthz` `fallback`: alert when it is above zero for more than a
      few minutes. Without that a silent switch triples the AI bill and
      nothing says so
- [ ] Re-run `npm run eval:prices` (needs no key) before launch; the price
      table is a 2026-08-30 snapshot
- [ ] Decide whether a cheaper backup is worth screening. `tools/eval` has
      priced several candidates; any one must pass the eval on the tutor prompt
      before it replaces 3.1
- [ ] Set `DAILY_BUDGET_USD` low (for example $1) for the live test below, so a
      loop or a bug can't spend the whole balance

### Boss trials on AI

The owner's follow-up direction (level-gated stages, no Spells, daily limits,
ads, toy chest) and its open questions are in [BOSS_PLAN.md](BOSS_PLAN.md),
which supersedes this section where they differ.

Checked 2026-10-22: **boss trials make no model calls today.** The only AI
modes are chat, assessment, quiz and level. A trial's content is:

- The player's own vocabulary review items (`TrialWordPool.build`), in stored
  order, not ranked by lapses. Corrections are left out ("a sentence will not
  fit a tile"), so the player's mistakes reach a fight only when a mistake
  has already been turned into a vocabulary item.
- Topped up with 12 stock nouns and 6 stock sentences in every language
  (`boss_trial_words.dart`, `boss_trial_sentences.dart`). Both files are
  labelled "a testing placeholder".
- Seven openers (Lanternmaw's Shoal, Sableth's Riddle, Door and Tablets,
  Pyrewing's Parley, Link, Paraphrase and Hoard) have hand-written content in
  English and Turkish only (`boss_trial_en_tr.dart`). Any other pair fights
  them in English and Turkish instead.
- Nothing uses the player's level to choose the content.

What the owner wants: content generated for the player's level, built around
the mistakes and weak points the app has noted from any other activity.

What already exists to build on: `AiPromptSpec.quiz` takes a level plus
`troubleSpots` (items with lapses) and `dueItems`, and the proxy escapes and
caps them. The mistakes provider already feeds the review queue.

Plan, in order:

- [ ] Server: a new generate mode for trial content, taking language pair,
      level, the opener, and the same trouble and due items. Returns the shape
      that opener needs (words with meanings, sentences, riddles, doors,
      stories and so on), validated on the proxy
- [ ] Client: parse and validate the reply as the quiz parser does, then feed
      the existing pools. Reject anything a tile can't hold (length limits in
      `BossTrialRules`), duplicates, or a word spelled the same on both sides
- [ ] Start with the two rounds every boss shares, Catch (words) and Spells
      (sentences). Then the seven bespoke openers, one boss at a time
- [ ] Sentences for Japanese, Chinese and Thai must come back already split
      into word stones, since those scripts have no spaces; check each against
      real output before trusting it
- [ ] Put the player's weak points first: rank by lapses, and turn recorded
      mistakes (corrections) into words or sentences a fight can use
- [ ] Always keep a way to start: if the model is unavailable, over its
      allowance or returns something invalid, fall back to the player's own
      words and the stock sets, as today. The wall never stops playing
- [ ] Cache a generated set per level and pair so retrying a fight doesn't
      pay for it twice
- [ ] Decide what a generated fight counts against (see "Decisions needed")

Decisions needed:

- What a trial's generation costs the player: count it as an AI quiz, give
  boss trials their own small daily allowance, or keep it free and count it
  only in the proxy's budget. My lean: its own small allowance, so a fight
  doesn't eat the day's quizzes, and Plus raises it.
- Whether the trial's content is generated per fight or once per level
  (cheaper, and the same set every retry).

### Live test with the OpenRouter balance (later)

The owner has about $4 on OpenRouter and will say when to start. At the
primary's roughly $0.00018 a turn that is many thousands of chat turns, so
the balance is plenty; on the backup it is still well over a thousand.

- [ ] Run the proxy locally against OpenRouter with the budget ceiling above
- [ ] Onboarding: the level assessment and its follow-up
- [ ] Chat: ordinary conversation in a few language pairs
- [ ] Town scenarios: one run through each building
- [ ] Bosses: after "Boss trials on AI" below is built, run a fight at a few
      levels and language pairs, with a player who has made mistakes
- [ ] Quizzes: generation per level, including the review-queue variant
- [ ] Read the spend ledger afterwards and replace the rough cost figures in
      step 1's margin check with real ones
- [ ] Force a primary failure once, to see the fallback fire and `/healthz`
      show it

### Pricing research

Thin, and it should be read that way:

- Play accepts any local price per country, with no fixed ladder. Automatic
  conversion ignores purchasing power, and one guide puts the mispricing at 2x
  to 3x in price-sensitive markets. The usual method is full price plus a few
  tiers of discount, rounded to local endings, then tuned from conversion by
  region. All from third-party guides; Google has no official guide.
- Existing subscribers keep their price when you change it. New prices apply
  to new subscribers only.
- RevenueCat's 2026 report (as quoted by a blog, not checked against the
  report): median monthly price about $6.68, most common $9.99, annual median
  about $34.80, education and finance annual medians about $44.99. Annual plans
  keep about 44% of subscribers after a year against 17% for monthly. That
  supports $39.99 as the annual price and putting it first on the page.
- One low-reliability source puts Duolingo Super in Turkey at about 66% of
  the US price. No usable figures for India, Brazil or Indonesia were found.
- Google takes 15% of subscription revenue (from memory, not checked in this
  research; confirm in Play Console).

## 2. Measure it

`lib/` has no analytics, crash reporting, remote config or in-app review prompt.
Without them, every number in `MONETISATION.md` (3 free quizzes, pack prices,
the pass window) is a guess that cannot be corrected after launch.

- [ ] Firebase Analytics and Crashlytics (Firebase is already integrated)
- [ ] Events, roughly: onboarding step reached, first quiz done, first pet-care
      action, day-N return, AI wall hit, paywall viewed, purchase started,
      purchase completed, rewarded ad watched, pass tier claimed
- [ ] Remote Config for the tunables: free quiz and message allowance, pack
      prices shown, pass window dates, rewarded-ad ladder
- [ ] Respect the age rule: no ad-personalisation or analytics identifiers for
      the under-13 and unknown-age path (see `ADS.md`, "Audience and consent")
- [ ] In-app review prompt, shown after a good moment (a cleared boss, a
      streak milestone), never after a wall or an error

## 3. Retention levers that cost little

Retention multiplies every revenue line. The only retention tools today are
local notifications (pet care, review due, daily reward).

- [ ] Check the first session end to end after the Town and School changes: a
      new player should reach a quiz and a pet-care moment in about two minutes
- [ ] Make the streak visible and loss-averse in the UI (the code tracks it)
- [ ] A share hook: a pet card, or a clip cut from the existing promo video
- [ ] Tune notification copy and timing once step 2 shows when players drift

## 4. Closed beta, then decide

- [ ] Play closed testing for about two weeks with the real store products
- [ ] Read the funnel: onboarding drop-off, D1 and D7, wall hits, paywall view
      to purchase, ad opt-in rate
- [ ] Fix the single biggest drop before adding anything
- [ ] Then, and only then, decide on: a free trial, Plus price changes, the
      free quiz allowance

## 5. Reach

- [ ] Store listings written (title, short and long description, screenshots)
      for the top five to eight markets first. 27 languages is a real edge only
      if the listing is localised too
- [ ] Promo video as the Play preview
- [ ] Privacy policy URL and a landing page
- [ ] Trademark and name check for "Mimikin" in the markets that matter
- [ ] Small organic launch: short pet clips on TikTok or Shorts

## 6. Compliance, which can zero the business

Mixed audience, a pet game that appeals to children, ads, in-app purchases and
AI chat is the highest-risk combination under Play's Families policy, COPPA and
GDPR.

- [ ] Walk the under-13 / unknown-age path and decide what it may see: Plus,
      coin packs, AI chat, rewarded ads
- [ ] Play Data Safety form matches what Firebase, AdMob and the proxy collect
- [ ] Content rating completed; "contains ads" declared
- [ ] Play's policy on AI-generated content: in-app reporting and a stated
      policy for the chat and quiz output
- [ ] iOS App Tracking Transparency prompt (known gap in `ADS.md`), when there
      is a Mac build

## 7. Hold until the data is in

Large builds that assume the first pass sells. Season one (First Flight) is the
test: look at how it converts before building a second.

- [ ] Witching Hour event pass (`HALLOWEEN_PASS.md`): about 30 tiers, two lanes,
      about 40 strings in 27 locales, 11 recolours still unbuilt
- [ ] More boss pet animations and further art rounds
- [ ] Roadmap polish in `ROADMAP.md` (#3 toy chest, #6 nav art). #4, the Plus
      and pass page design, is the exception: it sits directly on conversion, so
      do it during or just after step 1

## Not checked

- No in-app screens were looked at; this is from code and docs.
- Whether a Play developer account, privacy policy URL or trademark clearance
  already exist.
- Per-call model cost is not measured here; see the margin check in step 1.
