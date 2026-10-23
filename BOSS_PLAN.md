# Boss trials and toy chest: the plan

Started 2026-10-22. Nothing here is built. This is the owner's direction plus
what the code says today, and the decisions still open. It supersedes the
"Boss trials on AI" section of `LAUNCH.md` where they differ.

## The owner's direction

1. **Player level unlocks boss stages**, so the app knows the player before it
   builds a stage around their shortcomings.
2. **Remove Spells completely.** Each boss is four phases, one per level, then
   one finale that combines the four.
3. **A daily limit on boss fights:** one a day, Plus up to three.
4. **Ads:** one after a boss fight, and one when the player runs out of hearts
   so they can continue.
5. **The toy chest games get limits too**, AI-generated content, same ad ideas.
6. Content comes from the model, matched to the player's level and, most
   importantly, built around the mistakes and weak points noted in the app.

## Status

**Built 2026-10-22 (uncommitted, like all the boss code):**
- The finale's Spells round is gone. A finale is now the four openings in a
  row (`TrialPlan.forStep`, `isFinale` is "more than one round"). Removed with
  it: the casting stage and its board, the boss's charge and boulder attack,
  the pet's body-cast move, `castTime` / `spellDamage` / `phaseFor` /
  `TrialPhase`, `TrialRun.castRight` and `.cast`, the intro's "PRACTISE
  SPELLS" button, and the per-boss `charge`, `roundTwoIntro`, `practiseLabel`,
  `roundTwoHint` and `castLabel`. Kept because other things use them: the
  sentence stones (`SpellWave`, `SpellCast`), the witch's hex, Amethyst's Echo,
  Hoothex's Scroll, Fetch the Words and Bubble Bath.
- Climb stops are gated by player level: tapping a stop above the player's
  level says "Reach level N to fight this." and opens nothing.
- Tests: the Spells-only tests were deleted (about 30, listed in the commit
  or diff), including six screenshot-capture tests that drove the removed
  round. Those captures need rewriting if wanted.
- A backup of the boss code from before this change is in the session
  scratchpad. **None of the boss code is in git** (it is all untracked), so
  committing it is the only real undo.

**Built 2026-10-22, second pass:** first-clear rewards. The first clear of a
level pays and a repeat pays nothing: 15 coins and one care item for an
opening, 100 coins plus medicine and a pizza slice for a finale
(`BossRewards`, `BossProgressProvider`, results screen). The clears are stored
under `boss_cleared`, which cloud sync carries with the rest of the prefs. The
economy test counts them.

**Built 2026-10-22, third pass:**
- **Resume on close.** A fight is saved between throws and as each begins
  (`BossRunSave`, kept on the device, off the cloud copy). Coming back to the
  same boss, level and language pair offers CONTINUE or START OVER. A throw that
  was in the air when the fight was left counts as landed and costs a heart,
  which closes dodging a loss or looking at an answer and quitting. Saved at
  throw boundaries because a throw's state is a different shape for each of the
  24 openings. Not saved: the scrolls a run missed (they only feed the results
  list).
- **Revive.** A lost fight, on any boss or level, offers "REVIVE · WATCH AN AD"
  when a rewarded ad is loaded: the same fight on with 2 hearts, once an
  attempt. It uses a slot of the five rewarded ads a day and pays no coins or
  quiz. Members still see it.

**Built 2026-10-23, fourth pass (toy chest and limits):**
- **No stock words in a release.** `AppRuntimeConfig.stockContent` is on in debug
  and test builds and off in a release (override with `--dart-define=STOCK_CONTENT=true`).
  With it off the games are played with the player's own words and nothing else,
  and a game they have too few words for stays shut: the chest greys the toy and
  says "Learn a few more words to play" (`playNeedsWords`, 27 locales). Four
  distinct meanings fill a throw. Fetch the Words stays shut in a release,
  because its sentences only exist as stock until the AI can write them.
- **Same words as the fights.** Games and boss trials already build their pools
  from the same player vocabulary (`TrialWordPool`); the daily content pack will
  feed both, so practising in the toy chest practises what the boss will throw.
  "Words related to the player's" needs the generated pack and is not built.
- **AI messages raised: 80 a day free, 300 for Plus** (were 30 and 200), shared
  by chat and every town scenario. The old free number was a wall a daily
  player could meet on day one. A fight's content will have its own small
  allowance, not touching these.

**Decided and built 2026-10-23, fifth pass: related words instead of a call.**
Rather than a separate model call per fight or per day, the player's vocabulary
grows from the chat they already do. The tutor's vocabulary block now also
carries up to 2 *related* words about the topic, at the player's level (the
level is now sent with chat requests), marked `"related": true`. They are
**kept in a suggested pile**, apart from the review queue, because the learner
has not met them: reviewing them as cards would bury the queue. The toy chest
and the boss fights draw on the player's words plus the pile
(`VocabProvider.practiseItems`); a word met properly moves into the queue and
leaves the pile; the pile keeps the newest 150. It costs no extra call, so
there is no new allowance and the 80 messages cover it.
- The app does not trust the model to leave out words the player just wrote:
  in a real check on the main model (8 short chats, about $0.002) it handed back
  `lago` and `montaña` after the player typed both, so those are filtered out,
  and so is anything the player already has.
- That check also found: the vocabulary block parsed every time and 7 of 8
  replies had related words, but some were off-topic ("school" and "home" after
  a market) and a roleplay scene (French coffee shop) produced none. Quality is
  fair, not good; worth another look with more samples.
- **Not covered:** a player who never chats has no words, so the toys stay shut;
  and the openers that need sentences, riddles or grammar still have no content
  outside English and Turkish. Those still need generated content or a way to
  take sentences from the player's corrections.

**Next:** a first source of words for players who have not chatted yet; content
for the sentence and grammar openers; the toy chest's art.

## Decided 2026-10-22 (the owner's answers to the questions below)

These replace the owner's first list where they differ.

- **Level only unlocks. It never sets difficulty.** Difficulty always scales
  with the player's latest performance (recent answers, trouble spots,
  recorded mistakes, how the last fights went), not with XP level.
- **No daily limit on boss entries**, since a fight costs little. A limit of
  three a day makes no sense late in the game, when a player rarely unlocks a
  new stage in a day. The level gate is what paces new stages. This replaces
  "one a day, Plus three", so Plus gets no boss perk from it.
- **Only the final round goes** (the finale's Spells round). The openers that
  use sentences (Amethyst's Echo, Hoothex's Scroll and brewing) stay.
- **Fetch the Words stays**, but its art has to be redone when we get to the
  toy chest: the word sticks and treats don't read as anything.
- **Count a fight when it ends, not when it starts**, so an unexpected problem
  doesn't cost anything. To stop that being abused, a fight that is closed
  mid-way is frozen and resumed from where it was left (see "Resuming").
- **Reused content is re-laid-out on every attempt.** A retry may use the same
  generated set, but where things sit is randomised: Mossback's Shells with
  apple, star, house must come back as, say, house, apple, star. The seed is
  saved with the run so a *resumed* fight keeps its layout (see "Resuming").
- **The ad-earned bonus fight is dropped** (there is no limit to buy back).
- **Revive on any boss fight** (rewarded ad, not just the finale).
- **Fights reward coins and a few pet-care items** (food, medicine). Every
  finale pays more: about 100 coins, enough to buy something substantial.
  First clear only, 15 coins per opening, 100 per finale (see "Rewards").

### Resuming a closed fight

The run is saved at every change: stage, round, patience, hearts, streak, the
generated content it was using, the wave in play, and the clock remaining on
it. On the next launch the player is offered "continue" and lands on the same
wave with the same time left.
- Resuming the **same** wave with the **remaining** clock gives no way to
  dodge a loss or reroll: leaving right before the clock runs out just returns
  you to a nearly-run-out clock.
- The clock stops while the app is in the background, as any pause would.
- Resuming a *different* wave would let a player look at the answer, quit, and
  come back to a new wave. Don't do that.
- With no entry limit this protects hearts and finale progress rather than an
  entry. It is still worth it: a finale is several minutes of work.

## Rewards (decided)

The owner wants coins plus food and medicine, and a finale worth about 100
coins. With **no entry limit**, a reward that repeats is a coin farm: the same
stage cleared again and again. So the rule has to say what pays twice.

For scale (`gold.dart`, `shop.dart`): a casual player earns about 20 coins a
day, the full-rate band is 100 a day, accessories cost 100 to 200 and pets 300.
A 100-coin finale is about five days of casual earning and a third of a pet.

Decided (owner, 2026-10-22):
- **First clear of a stage pays; repeat clears pay nothing.** Openings 15
  coins and one food or medicine item; each finale 100 coins and a few items.
  All six bosses once: 960 coins across the 30 levels, one-off. About 6.5% of
  the catalogue the economy model counts (it was first guessed at 3%; the test
  holds it under 8%) and about $9 of coin-pack value spread over months, so
  it is bounded.
- **Pay on a clear, not on the grade.** A grade bonus would reward proficiency,
  which the economy deliberately doesn't (`MONETISATION.md`, "reward activity,
  not proficiency"); difficulty already adapts to the player, so a clear means
  the same thing for everyone.
- **Pay through `addCoins`, not the learning ledger**, as ad coins do
  (`ADS.md`), so a fight doesn't advance the daily taper or get reduced by it.
- **Revives don't change the payout**: a revived clear pays like any other.
  The revive is a rewarded ad and uses the shared five-a-day cap unless data
  says otherwise.
- **The levels gate is the real brake.** XP comes from learning, so the stages
  that pay open as the player learns.
- Pet-care items are a small dent in the food and medicine sink that sells
  coin packs (`MONETISATION.md`), which is acceptable at this size.
- Update `test/unit/economy_curve_test.dart` with the new one-off income so it
  still fails if the curve breaks.

## What the code says today (checked 2026-10-22)

- **The structure is already four phases and a finale.** `BossTrialRules.
  levelsPerBoss` is 5: four openings, one level each (the boss gets away when
  it is won), then a finale with every opening as a round (half length each)
  and then a Spells round (`TrialPlan.forStep` in `lib/utils/boss_trial.dart`).
  So "remove Spells" means removing that last round and the code behind it,
  not restructuring the bosses.
- **The climb map already ties stops to player level.** Six floors, one boss
  each, 30 stops, stop = player level 1 to 30. It draws `reached` and `you`
  from the level (`climb_map.dart`), but tapping any stop starts that fight:
  nothing is locked.
- **Hearts:** 3 per run, one back at the start of each later finale round. A
  fight ends when they are gone.
- **Fights pay nothing.** The end screen shows a grade, no XP and no coins.
- **Boss trials are a debug-only feature** behind `--dart-define=BOSS_TRIAL`,
  with English copy "for the testing build". Nothing in them is translated yet.
- **Toy chest** (`lib/utils/play_games.dart`): five no-lose games built from
  boss rules. Happiness is paid at most once per 30 minutes across all games
  (`CharacterProvider.playCooldown`), and play XP is capped at 30 a day. There
  are no hearts and nothing to lose, so "ad when out of hearts" has no meaning
  there.
- **Fetch the Words is the Spells round as a game.** Removing Spells from the
  bosses forces a decision about it (below).
- **No model calls anywhere in trials or games**: the player's own vocabulary,
  topped up with 12 stock nouns and 6 stock sentences, plus seven openers
  hand-written in English and Turkish only.

## Things to settle before building

### 1. What "Spells" covers
The Spells round is the finale's last round and the "castSpells" phase. Sentence
content is also used by openers that are not Spells (Amethyst's Echo, Hoothex's
Scroll and brewing), so removing the round does not remove sentence data.
Confirm that only the round goes. Also decide **Fetch the Words**: keep it as a
toy chest game with its own rules, or drop it with the round.

### 2. Level versus proficiency
Player level is XP, which measures activity, not skill (`progression.dart`:
"reward activity, not proficiency"). Someone who chats all week can be level 14
and still a beginner. So:
- **Level decides which stage is open.** Consistent with the XP-only rule.
- **Difficulty comes from the assessed level** (`CalibrationProvider`, the
  `level` mode: one of three bands) **plus the player's actual data**: trouble
  spots (lapses), due items and recorded mistakes. Using XP level as difficulty
  would make a high-XP beginner's fights impossible.

### 3. When a stage is generated
Recommended: **at the moment the fight starts**, from the data as it is then,
with a short themed wait and the stock set as the fallback. Not at level-up:
that is the stalest the data will ever be. Cache the generated set for the day
and pair so a retry doesn't pay twice. The finale needs four openings' content,
so it is one request for four sets.

### 4. What costs a fight
The limit is a game-design and revenue choice, not a cost one: a fight costs a
fraction of a cent in model calls. The loop only works if a loss costs
something:
- If a lost attempt can be retried free, "hearts out, watch an ad to continue"
  has no reason to exist.
- Recommended: **an attempt is counted when it starts**; a loss ends it; the
  **rewarded ad continues the same attempt** (once per attempt, with the hearts
  it gave back) and does not use another fight. An abandoned attempt still
  counts, so quitting at the first mistake isn't free.
- Alternative: count only when an attempt ends (win or final loss). Kinder, but
  quitting before a loss then costs nothing.

### 5. The limit itself
One a day is very little for the feature that has had the most art and code put
into it, and a daily gate on the content a Tamagotchi-style game leans on can
cost reviews. It is also the best Plus differentiator so far: Plus's current
perks are quantities, and a game-flavoured "three fights a day" is easy to
show. Options:
- **A:** 1 a day free, 3 with Plus, plus an ad-earned bonus fight (below).
- **B:** 2 free, 5 Plus, no bonus fight.
- Decide after the beta shows how often players actually fight. Make the
  numbers Remote Config values (`LAUNCH.md`, step 2).

### 6. Ads: which kind, and how many
Existing rules (`ADS.md`): rewarded is opt-in, 5 a day, pays coins and one
quiz, and membership does **not** remove it. Interstitials are automatic, one
an hour, after a quiz or scenario, and membership removes them.
- **Continue after hearts run out:** rewarded, opt-in. Fine as designed.
- **"An ad after a boss fight":** two different things. A **rewarded** ad that
  grants a bonus fight is opt-in and fine. An **interstitial** after every
  fight is forced, and sits badly with a game that may be played by children,
  and the existing hourly cooldown would apply. Recommend rewarded only.
- **Shared cap.** Coins, quiz, revive and bonus fight would all draw on the same
  five a day, or the player is offered a steady stream. Decide whether revives
  count against the five or have their own cap.
- Revives and bonus fights are **not** a coin faucet because fights pay
  nothing. If fights ever pay coins or XP, the existing "learned something
  today" gate has to apply to them as well.
- Under-13 and unknown-age players keep the child ad treatment (`ADS.md`). An
  ad on a loss screen for a child is the riskiest placement under Play's
  Families policy: check it before shipping.
- Too many hooks hurt retention. Introduce them in steps and measure.

### 7. Toy chest
- The 30-minute shared cooldown and the 30 XP a day cap already limit games.
  Additional limit options: N games a day (Plus more), or leave games
  uncapped and only ration what they pay.
- Recommended content idea: **one "daily pack"**, generated once a day per pair
  from the player's level, trouble spots and mistakes, shared by the boss fight
  and the five games. One call a day instead of one per game.
- A cooldown skipped for an ad is the natural ad hook for games. There are no
  hearts, so no revive.

### 8. Server-side limits
Per-day boss and pack generations have to be metered on the proxy
(`server/src/quotas.js`) as well, or a rebuilt client ignores them. The client
copy is for the meter and the prompt (`MONETISATION.md`, "The client is not the
enforcer").

### 9. Quality of generated content
The fight "tests" the player, so a wrong translation is a game that marks a
right answer wrong. Mitigations:
- Prefer the player's own review items (their words, already stored) over
  invented ones; generate extra words only to top up at the right level.
- Validate on the proxy and the client: length limits, duplicates, a word
  spelled the same on both sides, scripts that need word splitting.
- Extend `server/tools/eval` with trial-content cases, in the language pairs
  that matter, before trusting it. The eval already has a language matrix and
  an idiom set; trial content would be a third.

## Build order

0. **Decisions** above: Spells scope and Fetch the Words, what a fight costs,
   the limit numbers, which ads.
1. **Cleanup, no AI:** remove the Spells round and its code, tests and strings;
   gate stages by level; the daily fight limit and its meter; hearts and the
   revive hook with a fake ad in tests.
2. **Words content first:** the new proxy mode and client parser for the word
   pool. Most openers draw on it (not yet counted per opener: verify before
   estimating). Ranked by lapses, with mistakes as sources.
3. **The other content types**, boss by boss: sentences, riddles, doors,
   stories, parleys, links, paraphrases, phrases, groups.
4. **The daily pack and the toy chest.**
5. **Test with the OpenRouter balance** (`LAUNCH.md`), then the eval cases.
6. **Ship readiness:** translate the trial copy into 27 languages, remove the
   `BOSS_TRIAL` gate, add the first-time tour step.

## Not verified

- Per-opener content needs (which of the 24 openers use words, which sentences,
  which the seven bespoke types) were not tallied.
- Boss end-of-run behaviour at zero hearts was read only through its constants.
- No estimate here of ad revenue: it varies too much by country and I have no
  figure from this app's own data.
