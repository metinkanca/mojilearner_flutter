# Witching Hour: the Halloween event pass

Status: **pass planned; the four new wearables are in the catalogue as season-two pass content** (2026-10-10).
They are the owner's pixel-art PNGs and replaced the first hand-built drafts (jack-o'-lantern cap, bat mask, potion
pendant, cauldron pot). None is on a tier yet, so they are pass-locked for everyone until the event-pass model exists;
`--dart-define=UNLOCK_ALL_ACCESSORIES=true` shows them on a pet. The hat's and bandana's size and seat on the cat
and dog follow the owner's mock-ups of them. Season two's placeholder in
`lib/constants/season_pass.dart` still holds only the Pumpkin Patch scene.

This is a battle pass, and it deliberately overrides three things
`SEASON_PASS.md` and `MONETISATION.md` still say about season passes: "not a
battle pass", "no free track" and "progress measured from purchase". Season one
(First Flight) keeps those rules unchanged. Only event passes get the new ones.
When this is built, both docs need rewriting to match; see "Docs" below.

## Decisions already made

| Question | Decision |
|---|---|
| Pass model | **Event window, nothing lost.** Fixed window, free and premium tracks, XP counted from event start. Buying late unlocks every premium tier already reached. Premium is on sale only during the window. Reached tiers stay claimable forever. |
| Timing | **Date-agnostic.** Window dates are config, chosen last. Do not assume Oct 31 2026. |
| Length | **~30 tiers, ~4 weeks** for a committed learner. Finale at about 5,000 XP. |
| Rewards | **Wearables, coat and eye colours, coins and food.** No pass-exclusive pet. The Pumpkin Patch scene is the premium finale. |

The name stays a mood ("Witching Hour") rather than a date, so a window that
lands away from Oct 31 does not read stale. The "no dated holidays" rule no
longer binds an event pass, but it still binds permanent seasons.

## Rules

- **Pacing.** Tier 1 costs 60 XP, tiers 2 and 3 cost 60 more each, and every
  tier after that costs 180 more. Tier 30 sits at **5,040 XP**.
- **Who finishes.** The curve in `progression.dart` assumes about 184 XP a day
  for a committed learner, who finishes around day 28 of a 35-day window.
  A steady learner at 100 a day reaches tier 21, and a casual learner at
  50 a day reaches tier 11. Finishing inside the window takes about 144 XP a day.
- **Buying late.** It grants every premium tier already reached, so nobody is
  worse off for joining late.
- **Reached tiers never expire.** Only earning is bounded by the window.
- **XP only.** There is no mission system, and XP-only pacing matches the
  "reward activity, not proficiency" rule.
- **Window length** is 35 days by default and is configuration.

## The track

New shapes are marked ★. Gold leads nowhere. The palette is ember, plum, bone,
slime green and midnight. Bone needs something dark behind it to survive the
white wardrobe tile (the value-gap rule in `SEASON_PASS.md`).

| Tier | XP | Free | Premium |
|---|---|---|---|
| 1 | 60 | 15 coins | **Pumpkin witch hat ★** (hat) |
| 2 | 120 | | 20 coins |
| 3 | 180 | Ember eyes | Midnight coat |
| 4 | 360 | | Witch hat, plum |
| 5 | 540 | 20 coins | Treat basket |
| 6 | 720 | | Slime eyes |
| 7 | 900 | Treat basket | **Ghost bandana ★** (neck) |
| 8 | 1,080 | | 25 coins |
| 9 | 1,260 | Pumpkin coat | Ghost coat |
| 10 | 1,440 | | Bow tie, ember |
| 11 | 1,620 | 20 coins | Treat basket |
| 12 | 1,800 | | Ghost bandana, ember |
| 13 | 1,980 | Treat basket | 25 coins |
| 14 | 2,160 | | **Devil-horn headband ★** (hat) |
| 15 | 2,340 | 20 coins | Violet eyes |
| 16 | 2,520 | | Slime coat |
| 17 | 2,700 | Treat basket | 25 coins |
| 18 | 2,880 | | Pumpkin witch hat, moonlit |
| 19 | 3,060 | Cobweb scarf | Devil-horn headband, slime |
| 20 | 3,240 | | Treat basket |
| 21 | 3,420 | 20 coins | **Bat choker ★** (neck) |
| 22 | 3,600 | | Plum coat |
| 23 | 3,780 | Treat basket | 30 coins |
| 24 | 3,960 | | Hex eyes (odd-eyed) |
| 25 | 4,140 | Candy-corn party hat | Bat choker, slime |
| 26 | 4,320 | | Collar, midnight |
| 27 | 4,500 | 25 coins | Treat basket |
| 28 | 4,680 | | 30 coins |
| 29 | 4,860 | 25 coins | Witch hat, ember |
| 30 | 5,040 | Witch hat, black | **Pumpkin Patch scene** |

### Totals

- 46 rewards: 16 free and 30 premium.
- Premium: 12 wearables, 4 coats, 3 eye colours, 4 treat baskets, 6 coin
  rewards and the scene.
- Free: 3 wearables, 1 coat, 1 eye colour, 4 treat baskets and 7 coin rewards.
- **Coins: about 300** (145 free, 155 premium), kept under the 400-coin pack so
  the pass cannot undercut coin sales. Run it through
  `test/unit/economy_curve_test.dart`.
- **Treat basket** is a bundle of the existing foods, so it needs no new art.

### Art cost

#### New-shape cat fitting (2026-10-10)

The four base shapes are the owner's pixel-art PNGs (magenta key, in `art_src/`),
re-pixelised onto the app's current `assets/svgs/cat2.svg` (the file is named
`cat2`, not `cat-2`). They replaced the first hand-built drafts the same day.

| Shape | Slot | Source PNG | Wearable SVG | Wardrobe icon |
|---|---|---|---|---|
| Pumpkin witch hat | hat | `Pixel witch hat with tip-hung pumpkin bell.png` | `assets/svgs/acc_pumpkinwitch.svg` | `assets/svgs/acc_pumpkinwitch_icon.svg` |
| Devil-horn headband | hat | `Retro pixel devil-horn headband.png` | `assets/svgs/acc_devilband.svg` | `assets/svgs/acc_devilband_icon.svg` |
| Ghost bandana | neck | `Retro pixel ghost bandana.png` | `assets/svgs/acc_ghostbandana.svg` | `assets/svgs/acc_ghostbandana_icon.svg` |
| Bat choker | neck | `Flat-color bat bow on magenta.png` (kept under the name it was saved with) | `assets/svgs/acc_batchoker.svg` | `assets/svgs/acc_batchoker_icon.svg` |

Review `art_src/halloween/fit.png` or open `art_src/halloween/index.html`.
The reference previews use the natural cat coat and gold eyes rather than the
raw SVG markers. `art_src/halloween/fit-display-size.png` compares all four at
a 153-pixel pet width on paper and midnight backgrounds. These are static art
checks; Flutter animation and runtime fit checks remain part of catalogue
integration. Each `art_src/halloween/cat2_with_*.svg` is an editable assembled
reference. Regenerate with `python art_src/gen_halloween_acc.py`. Size and
seating live in its `PIECES` table (`cells` wide of `cell` units each, `xc`
centre, `yb` bottom edge); edit that, since regeneration replaces the shipped
SVGs and previews.

The `cat2_with_*.svg` previews are in cat2's own **`-36.5 -114.3784 255 376.7568`**
viewBox (the shipped SVGs use the shared canvas; see below). The four PNGs were
drawn at different pixel sizes (about 24, 16, 20 and 20 px), so each is
resampled onto a grid of cells and given a fresh one-cell outline in the cat's
ink. It keeps the interior detail (pumpkin face, ghost eyes) and leaves enclosed
gaps open, such as the hole in the hat's curl. The headband and the bow use
cat2's 3-unit cell. The hat and the bandana use their PNG's own pixel density,
3.5 and 2.37 units a cell, because that is how the owner's cat-and-dog mock-ups
draw them: the bandana is finer-grained than the cat and wider than its head,
with the knots outside it. Paths are traced in cell space and scaled, so the
fractional cells cost nothing. Sizes and seats, in cat2 units (the head is 132
wide, the eyes sit at y106..127):

| Shape | Cells | Cell | Size (w x h) | Seat on the cat |
|---|---|---|---|---|
| Pumpkin witch hat | 46 | 3.5 | 161 x 126 | brim bottom at y96.4, just above the eyes, centred x116.5. It is pulled down over the head as in the mock-up, so the right ear pokes out beside the cone. |
| Devil-horn headband | 42 | 3 | 126 x 96 | band ends at y102, just above the eyes. The horns sit over the ears and the band crosses solid head, so no background is enclosed. |
| Ghost bandana | 67 | 2.37 | 159 x 80 | top at y148.7 under the chin, centred x114.2; knots sit outside the head on both sides. |
| Bat choker | 34 | 3 | 102 x 36 | snug under the chin, top at y150 and centred on the neck (x114), level with the bandana's top edge. A choker wraps the neck, so it follows the neck line and not the muzzle. |

Generation checks canvas bounds and that neither eye is painted over.

**In the catalogue.** `lib/constants/accessories.dart` has all four (ids
`pumpkinwitch`, `devilband`, `ghostbandana`, `batchoker`) tagged
`requiredPass: kSeasonTwoId`, with names in all 27 locales
(`accessoryPumpkinWitchName`, `accessoryDevilBandName`,
`accessoryGhostBandanaName`, `accessoryBatChokerName`, shown through
`accessoryName` in `wardrobe_screen.dart`) and measured extents in
`accessory_extents.dart`. They are on no tier and not for sale, so nobody can
own one yet. The 11 recolours and the track itself are still pending.

**How they ship.** Every accessory asset is drawn on the shared pet canvas
(`-20 -90 222 328`) as if the old cat wore it, and each pet moves it to its own
head with a per-slot offset. These pieces were fitted straight onto cat2, so the
shipped SVGs are shifted back by the cat's own slot offset (hat 11, 24; neck
11, 35: `CAT_SLOT_OFFSET` in the generator, `_layeredPets['cat']` in
`character_sprite.dart`). The cat's offset then lands them exactly where they
were fitted, and every other pet seats them the way it seats any piece.

The hat is the exception, because the mock-up's seat is low. Pulled down to just
above the eyes, it is right for the cat and the dog and wrong for a pet with less
head above its eyes, whose eyes it would cover; most of the roster is like that.
So the hat ships at a generic seat 35.4 units higher (brim bottom at y61,
`GENERIC_HAT_BOTTOM`) for the roster to derive from, and the two pets with a
mock-up carry the difference as per-piece placements in `_layeredPets`: the cat
`pumpkinwitch (11, 59.4)` (`CAT_PIECE_OFFSET` in the generator), the dog
`pumpkinwitch (16, 17)` and `ghostbandana (17, 19)`. The dog's two were read off
the cat and dog mock-ups, as the difference between where each piece sits on the
cat and on the dog, and not from a reference drawing. The dog's hat is seated by
its brim and its bandana by its middle, because the mock-up draws the dog's
smaller. Checked through the real renderer, not only the static sheets: the cat
and dog match the mock-ups, and the bird, rabbit, hamster, fox, penguin, frog,
mouse and parrot wear the hat above their eyes and the bandana under their chins
at derived seats, roughly right and not measured.

`test/unit/halloween_accessories_test.dart` pins all of it: the art and the cat's
offsets as one number (change either and it fails until the generator's
constants are updated and it and `art_src/gen_acc_extents.py` are re-run), and
that the hat never lands over any pet's eyes.

- **4 new shapes:** Pumpkin witch hat, Devil-horn headband, Ghost bandana,
  Bat choker. Hats lead because season one led with a neck piece, and the slots
  alternate down the track (hat, neck, hat, neck). There is no face piece any
  more. Against the rules in `SEASON_PASS.md`, two things need a look in the
  running app: the headband's two ends are a hanging pair, and the bandana's
  knots flank the neck. Both read correctly in the static renders, and the
  headband's ends are drawn over the face rather than behind the ears, since
  an accessory always draws on top. Check them under the breathing animation.
  Each reads at wardrobe-tile size.
- **11 recolours:** 7 of existing pieces (Witch hat, which is the catalogue's
  `wizardhat`, in plum, ember and black, plus Bow tie, Collar, Scarf and Party
  hat) and 4 of the new shapes (Pumpkin witch hat moonlit, Ghost bandana ember,
  Devil-horn headband slime, Bat choker slime). Recolours are fill swaps via
  `AccessoryRecolor` and inherit their source's placements. The track's
  "Witch hat" rows are the old Wizard Hat; the Pumpkin witch hat is a separate
  shape, so rename one of them before the strings are written.
- **9 swatches:** 5 coats (Midnight, Ghost, Slime, Plum, Pumpkin) and 4 eye
  colours (Ember, Slime, Violet, Hex). These are runtime recolours through
  `pet_recolor.dart`.
- **0 new scene art.** The Pumpkin Patch is already drawn and wired.
- **Not on the sheet:** the Night Market roadmap row in `SEASON_PASS.md` uses
  ember and plum, so it collides with this palette.

## What changes in the code

1. **Reward kinds.** Tiers in `lib/constants/season_pass.dart` hold one
   accessory or one scene today. They need a free lane and a premium lane, and
   reward types for accessory, scene, coat swatch, eye swatch, coins and food.
   Season one stays as written.
2. **Two claim indexes.** A claim is one `claimedThroughTier` index per pass
   today. A second lane needs a second index. Event passes also need a progress
   record for everyone, because `OwnedPass` currently means "bought" and the free
   lane has no buyer. Saved records must stay readable (`xp`, `claimed`).
3. **Counting event XP.** `UserProvider.addXp` is the one place XP goes
   through, and the games' path calls it. It adds to the event's XP while the
   window is open, using a clock that tests can replace.
4. **Swatch gating.** `PetSwatch.isFree` is `price == null`, so a pass swatch
   would read as free. That is the same bug `AccessoryDef.isFreeStarter` had
   (`SEASON_PASS.md`, "A bug this uncovered"). Fix it first, with a regression
   test that fails against the old getter.
5. **Granting rewards.** Coins go through `UserProvider.addCoins`. Scenes and
   swatches go into the unlocked set the way `CharacterProvider.grantScene`
   does. Food needs its grant path found in `CharacterProvider`, which I have not
   located yet.
6. **Pass screen.** `lib/screens/season_pass_screen.dart` is a one-card pager
   today. It becomes a scrolling two-row strip with a premium call to action.
   The fitting room and the `?id=` route parameter stay.
7. **Dates.** Default dates sit in the catalogue, with an optional Firestore
   override so dates can change without a release. `cloud_firestore` is already
   a dependency and there is no remote config. The device clock is trusted,
   because the stakes are cosmetics.
8. **Entry points.** The profile `SeasonPassTile`, the shop slider and the home
   screen show only season one today. They need an "ends in N days" banner and a
   claim dot.
9. **Strings.** About 40 new strings in all 27 locales: lane labels, window
   text, reward names, swatch names. The four wearable names are already in.
10. **Store.** `com.mimikin.app.pass.season2` is a non-consumable with no
    listing yet. The page says "not on sale yet" until it exists.

### Traps

- **Index shifting.** Claims are indexes, so inserting tiers after the listing
  goes live corrupts them. Lock the track layout and pin it with a test before
  the listing exists.
- **`isFree` again.** See item 4. Any new "owned" check that asks the free
  question before the pass question hits it.
- **Pet coverage.** The four new shapes draw on every pet through the slot
  offsets, which seats them roughly and not exactly. Anything that has to sit
  exactly wants a measured placement (`_AccessoryPlacement`) or its own cut
  (`gen_bird_hats.py`). A pass piece that sits badly on someone's pet is a poor
  purchase, so look at each pet before the listing exists.

## Build order

1. **Rules and model.** No art, fully testable. Includes the swatch fix, reward
   kinds, two lanes, event XP, the window and the clock.
2. **Two-lane pass screen** with placeholder rewards. A dart-define like the
   existing `SEASON_PASS_XP` can show premium owned and a chosen XP.
3. **Art-free content:** swatches, coins, food and the scene. This is a
   shippable fallback on its own.
4. **Wearables.** The long pole: 4 shapes and 11 recolours. The 4 shapes are in
   the catalogue; the 11 recolours are not.
5. **Store, dates, entry points, docs.**

Tests across the build: window edges (first and last minute, late buy),
two-lane claims, the economy budget, the pinned track layout, canvas fit for
the new shapes on every pet, and a screen test with `SHOT_DIR` images.

## Not in v1

- Missions or dailies. There is no mission system, and building one is its own
  project.
- Ad-for-XP and buying a tier.
- A pass-exclusive pet.

## Docs

When this is built:

- `SEASON_PASS.md`: rewrite the opening, the theme rules, the "Season two"
  section and the roadmap. Keep season one's text.
- `MONETISATION.md`: rewrite the "Season pass" section. It currently says "Not a
  battle pass", "no free track" and "progress is measured from the purchase".
  Add the event pass to the lanes table.

## Open decisions

1. **What happens to tiers unreached when the window closes?** Recommended:
   premium owners keep earning with no deadline, because the repo's rule is that
   a season governs what is on sale, not what is claimable. The free lane stops
   at the window's end. Reached free tiers stay claimable and unreached ones are
   gone. The alternative is a last-week XP bonus for everyone, with the same
   hard stop.
2. **Do any pets want a measured seat for the 4 new shapes?** Every pet
   already wears them at derived seats, because the catalogue draws every piece
   on every pet. What is open is whether the dog or the bird needs a placement
   from a reference drawing, or a cut of its own, before the pass is on sale.
3. **Treat basket.** A bundle of existing foods (default), or a new seasonal
   food with its own art and stats.
4. **Price and window length.** A store price tier and the real dates. Both can
   wait until the end.
