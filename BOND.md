# Bond

How close the pet has grown, and how long since you last taught it anything.

## One ledger, not two

Bond used to keep its own points, capped at 40 a day, credited from its own
`BondSource` enum. That ledger was fed by exactly the four events that already
pay XP, at the same call sites, within a line or two of each other:

| Event | XP | old bond | Where |
|---|---|---|---|
| Chat exchange | 5 | 2 | `lib/screens/chat_screen.dart` |
| Scenario cleared | 10 | +8 | `lib/screens/chat_screen.dart` |
| Quiz finished | 10–50 by accuracy | 2–8 | `lib/screens/quiz_screen.dart` |
| Card reviewed | 3 | 3 | `lib/screens/review_screen.dart` |

No event paid bond and not XP. It was XP at a second exchange rate, with a
second set of prefs and a second curve to tune — so the stage ladder now reads
the player's level and there is one ledger underneath.

What survived the merge is the part XP could not express: the pet's rung is
gated on *assessed fluency* as well as level, and an absence is noticed.

## The ladder

Levels are deliberately offset from the 5/10/15/20 milestones in
`levelRewards`, so reaching a stage is its own moment rather than a footnote on
the background unlock landing the same second.

| Stage | Level | Cumulative XP | ≈ days |
|---|---|---|---|
| Curious | 1 | 0 | day one |
| Friendly | 4 | 903 | ~5 |
| Attached | 8 | 6,143 | ~33 |
| Devoted | 13 | 22,073 | ~120 |
| Inseparable | 18 | 51,216 | most of a year |

Days assume ~184 XP/day, which is the pace `progression.dart` uses when it
says a committed daily learner reaches level 20 inside a year.

Each stage also needs a fluency floor — beginner / **intermediate** /
intermediate / **advanced**. Both halves are required: level alone would let a
player grind the pet to its final stage without their language moving, fluency
alone would evolve the pet off a single calibration and then never again.

**The gate applies only to the pet's rung, never to the level itself.** Levels
pay coins, food and backgrounds; stalling those because somebody has not re-sat
an assessment would punish them for the wrong thing.

## Two rules worth not breaking

**The fluency tier ratchets.** `highestFluencyTier` in
`lib/utils/bond_context.dart` takes the best level ever assessed in *any*
language. The gate used to read only the language being studied right now, so
picking up a second language — which has no assessment yet, and therefore reads
as beginner — dropped the pet from Attached back to Friendly and re-locked
accessories it was already wearing. Starting something new is not a reason for
the pet to forget you.

**XP is never scaled by the pet being sick.** `characterProvider.scaleReward`
still shades coins and happiness, and deliberately no longer touches `addXp`.
The pet's closeness is projected from XP, so a sick pet slowing its own bond
would make the relationship something bought back with food rather than earned
with the language — the exact coupling bond was built without.

## Absence

`PetWarmth` reads the gap since the last learning event: 2 days →
"Moji misses you", 7 days → "has been waiting for you". It costs nothing —
no XP, no coins, no scaled reward — and the first learning event back clears
it. Absence in a language app is usually life getting in the way, and charging
for it is how people decide not to come back at all.

That principle is load-bearing well beyond this file: it is why the season pass
has no expiry (`SEASON_PASS.md`) and why the AI allowance wall always names
something free to do instead (`MONETISATION.md`).

`CharacterProvider` holds only the timestamp now (`recordLearningMoment`,
persisted as `pet_last_learning`). Warmth is still consumed by nothing but the
bond strip's caption — giving it a real consumer (the sprite, the dialogue) is
open work.

## Where it shows

- **The strip** — home screen, the pill on the grass under the pet. Five pips
  plus the stage name, or the absence line when there is one.
- **The sheet** — tap the strip. Stage, an XP bar across the current rung, the
  countdown, and an amber badge naming the fluency level when that is what is
  blocking. The badge reuses the assessment's own translated level names rather
  than inventing copy, so it reads correctly in all 26 locales.
- **The wardrobe** — four accessories gate on stage (`medal`/friendly,
  `tophat`/attached, `crown`/devoted, `mortarboard`/inseparable). These are
  derived from the stage rather than written into `unlockedItems`, so there is
  no stored copy to drift.

Progress is measured in XP inside the current rung, not in whole levels, so the
bar moves every session instead of four times a year.

## Files

| | |
|---|---|
| `lib/constants/bond.dart` | Stages, gates, warmth thresholds |
| `lib/utils/bond_progress.dart` | Pure arithmetic; `BondStatus` |
| `lib/utils/bond_context.dart` | Assembly + the fluency ratchet |
| `lib/components/bond_meter.dart` | Strip and details sheet |
| `lib/providers/character_provider.dart` | `recordLearningMoment`, `warmth` |

Tests: `test/unit/utils/bond_progress_test.dart`,
`test/unit/utils/bond_context_test.dart`,
`test/unit/providers/character_provider_bond_test.dart`,
`test/widget/bond_meter_test.dart`.

## Open

- `PetWarmth` still has no consumer outside its own caption.
- No stage-up ceremony. `UserProvider._levelUpController` is the pattern to
  copy when one is wanted.
- Only four accessories gate on stage, so the back half of the ladder pays
  little. Worth more rewards per rung.
