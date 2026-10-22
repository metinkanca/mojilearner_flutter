# Season pass content

What each season *is*. The commercial design — why this is not a battle pass,
why there is no free track, and how the three cosmetic lanes stay separate —
lives in `MONETISATION.md`, and the no-expiry principle it inherits is argued
in `BOND.md`. This file is the content plan: themes, shapes, tracks.

## What makes a theme valid

Six rules, and they rule out most of the obvious ideas.

**No dated holidays.** The pass has no expiry and progress runs from purchase,
so somebody buys season three in month eleven and claims tier seven the
following spring. A Christmas track claimed in April is a purchase that
visibly aged. Use the *mood* of a season, never its date.

**A theme is a palette, not a motif.** Six of ten tiers are recolours, so the
theme has to survive being expressed purely as fills. "Nautical" works because
it is navy, cream and rope. "Sports day" does not — it is props, and props
cost three files each.

**Gold cannot lead.** It is not reserved outright; `collar`, `mask` and
`flowercrown` all use `#f8b230` and all are coin-priced. But gold is `crown`'s
entire identity and the accent on `medal` and `mortarboard`, which are bond
lane. A gold-led pass reads as bond content with a price on it — the one
confusion `passLocked` exists to prevent.

**Every shape must read at tile size.** The wardrobe icon is the first and
usually only place a player judges a piece. A silhouette that only works at
sprite scale is a tier nobody looks forward to.

**Rotate the slot lead.** The catalogue is already ten hats to five neck and
four face. Two consecutive hat-led passes compound that; alternating does not.

**Twenty-six locales.** Anything tied to one culture's calendar excludes most
of the people who would buy it.

## Season one — First Flight

A departure, which is what starting a language is. Chosen over the
alternatives because it is the only candidate whose meaning is *season one
specifically*, and because it makes the four shapes cohere without swapping
any of them. Its palette corner — dusk navy against coral — is one the
catalogue barely touches, so the track looks like new content rather than
restock.

Palette: dusk navy `#1a3340`, cloud cream `#efeae1`, sunrise coral `#e3664f`,
plus a brass accent for the goggles.

### The track

New shapes land at tiers 1, 4, 7 and 10 — one every third rung, so no three
recolours ever run together and the first claim is a real object rather than a
tint. A track that opens on a recolour makes the purchase feel thin.

| Tier | XP | Item | Cost |
|---|---|---|---|
| 1 | 500 | **Bandana** — coral | new shape |
| 2 | 1,000 | Bandana — cream | variant |
| 3 | 1,500 | `scarf` — dusk navy | variant of existing |
| 4 | 2,000 | **Goggles** — brass frame, smoke lens | new shape |
| 5 | 2,500 | Goggles — coral strap, amber lens | variant |
| 6 | 3,000 | `beanie` — cream | variant of existing |
| 7 | 3,500 | **Flight cap** — leather brown | new shape |
| 8 | 4,000 | Flight cap — dusk navy | variant |
| 9 | 4,500 | `cowboyhat` — charcoal | variant of existing |
| 10 | 5,000 | **Flight scarf** — coral, cream tail tip | new shape |
| 11 | 5,500 | **Departures** — the airfield | new scene, finale |

Tiers 3 and 6 recolour `scarf` and `beanie`, which share the same teal pair
(`#4e95a3` / `#94d1d5`). Recoloured to the same palette two rungs apart they
land as a matched set, which is a better beat than two unrelated tints.

Twelve new files — four shapes at three each. The six variants cost nothing;
see the recolour pipeline in `MONETISATION.md`. The scene costs no SVGs at
all — it is three palettes and a generated block in `constants/scenes.dart` —
which is the argument for and against ending a season this way. See the
roadmap note.

### Tier eleven is the world, not a thing to wear

Ten rungs dress the pet for a departure and the eleventh is the departure: an
airfield drawn to a reference: an airliner climbing out over a control tower,
a terminal, a second building, an airliner at a stand, and an apron marked out
in paint. It is the only tier on any track that is
not an accessory, and the only scene in the catalogue that is neither free nor
for sale.

It is a finale for a structural reason as much as a dramatic one. A scene
changes every screen the pet appears on, so a player who got one at tier three
would spend the rest of the track looking at the thing they had already been
given. It is also the only reward here that cannot be worn *with* anything —
one world shows at a time — so putting it anywhere but last would make some
later rung the real ending.

The lane question it raises is answered above: this is a new world, not one of
the ladder's three. Nobody is sold a thing they were going to earn.

The art is still a palette and a decor list rather than a picture — see
`constants/scenes.dart` — which is what lets it keep the pixel look, the pet's
contact shadow and the day/night cycle. Tarmac with painted marks is the only
man-made ground in a catalogue of meadow, water, forest, dunes and moon rock,
and the only one with a skyline, so it reads as new content at tile size: the test every shape on this
track has to pass.

**One new type came with it.** A `SceneSpeck` is placed by fraction, which is
right for grass and wave crests and hopeless for anything that has to hold a
shape — a plane whose wings were each placed that way would come apart on a
wider screen. A `SceneMotif` is anchored once and lays its blocks out in its
own pixels, so it scales as one drawing. Sixteen of them make the airfield:
the airliner, the tower, the terminal, a second building, an airliner at a
stand, five clouds, the haze at the horizon, four dashes of white paint, and
the shadow on the apron.

The haze is the one that is background rather than object, and the one that
must span any screen: authored at the design width it fitted a phone exactly
and floated as a stripe in the middle of a tablet. It is authored far wider
than any screen and clipped.

One thing was built and then removed after seeing it on a phone, which is the
only place the failure was visible: a grid of slab joints across the apron,
meant to make the tarmac read as laid concrete, drew a grid of visible boxes
on it instead. An empty apron is better than a wrong one.

The airliner at the stand was removed too, and then came back. Hand-drawn it
read as a lump — everything that told you what it was lived in cells a phone
does not have. Traced from the vector reference at that reference's own
resolution, the same object at the same size is an aircraft. The lesson is
not "draw it smaller"; it is that a measurement beats an approximation at
exactly the sizes where approximation is tempting.

**And a way to afford the detail.** A motif used to render as a `Positioned`
and a `ColoredBox` per block, which puts every rectangle in the widget tree of
a screen that rebuilds whenever the pet moves. That was tolerable at three
hundred rectangles and is the reason the first trace was taken at half the
reference's resolution. `SceneMotifBox` paints instead: one render object,
`drawRect` per block, anti-aliasing off — so detail costs drawing time and
nothing else, and the art can be as fine as the source. The home screen and
`SceneThumbnail` share it, which is also what keeps a tile an honest
miniature; they used to hold separate copies of the same arithmetic.

**And a new way to author art.** The first plane was a hundred hand-written
rectangle coordinates and it read as a plus sign. The drawings are now
character grids in `art_src/gen_airfield.py`, one character per cell naming an
*ink*; it merges runs into rectangles and writes them between two markers in
`scenes.dart`. Edit the grid, re-run it, never touch the numbers.

**And then the grids stopped being guesses.** The scene is drawn to a
reference, and the reference arrived twice.

The raster came first: `ref_airfield.png`, 896x1200, thirty thousand
near-identical colours, its own pixel lattice smeared by compression.
`trace_ref.py` recovers that lattice by autocorrelating the colour-change
signal — the peaks are multiples of four pixels, so the art is natively
224x300 inside the file — then reads each cell back by median and majority
vote. It works, and it has a floor: a majority vote cannot preserve a
one-cell outline at any output size below the source.

The vectors came second, and they are what made an exact trace possible.
`render_ref.py` renders `ref_airfield.svg` at 4x and then samples the *centre*
of each cell — not a box filter, which blends every edge into its neighbour
and turns small features like the control tower into speckle. One source pixel
is then exactly one cell, the colours are the flat ones the artist drew, and
`trace_native.py` traces by palette lookup rather than by vote. Distinct
colours drop from four thousand to a couple of dozen that matter.

Both readings of the cell size agree at 224x300, independently, which is the
only reason to believe either.

What gets traced and what gets drawn is not arbitrary. Organic shapes — the
airliner, the clouds — are traced, because a silhouette is the one thing a
hand cannot better a measurement at. The buildings are drawn from the traced
proportions: they are regular, repetitive and mostly window, and in the
reference their lower storeys are half-hidden behind parked vehicles and
ground crew, which trace as holes in the wall. The brief was the airfield
without the people, so the walls are rebuilt whole.

Backgrounds still have to be told apart from buildings, and colour cannot do
it: the reference paints its terminals in almost exactly the tan of the apron
they stand on. The horizon can, though — above it, anything that is not sky is
a building — so a crop that stays above the horizon drops only sky, and one
that reaches below it drops the apron too.

**Take the whole silhouette and almost none of the shading.** The aircraft is
traced at the reference's own 102x43 and kept there — the engine slung under
the wing lives in cells a smaller trace does not have, and it was the first
thing lost when this was drawn by hand. What is dropped is colour: the
reference gives every surface a lit and a shaded face, six greys down the
fuselage and thirteen cabin windows, and at two logical pixels a cell all of
that reads as speckle rather than as form. On a phone it looked overworked,
and at night the thirteen windows lit as a dotted line. It is region-inked to
four — hull, grey, glass, line — with six windows and a door.

Silhouette from the measurement, shading by hand. And the *outline is
recomputed* from the silhouette rather than traced, because a traced one comes
back one cell in some places and two in others wherever a diagonal edge
crossed a cell boundary. Trace the shape, draw the line.

Everything is drawn on a two-pixel cell, which puts the scene at about 1.24x
the reference's proportions — 224 native cells at 2px against a 360-wide
design. Uniformly, so the objects keep their sizes relative to each other;
what changes is how close the viewer stands.

The ink indirection is what makes three times of day cost nothing. A cell says
`glass`, not a colour, and each palette supplies ten colours in that order —
so the same grids fly in daylight, warm and go dark-windowed at sunset, and
at night swap jobs entirely: glass becomes the brightest ink on the field,
because a terminal after dark *is* its lit windows.

Two of those ten exist only because one palette dresses two materials. `body`
is the aircraft's white hull and `stone` the terminal's tan concrete; sharing
one ink between them made either the aircraft tan or the buildings white.

**Iterate with the preview, not with the app.**

    python art_src/preview_airfield.py out_dir

That draws the scene the way `SceneThumbnail` does — same 5:4 bands, same
scale by tile width over `kSceneDesignWidth` — at both 360 and 88 px, in under
a second, where a `flutter test` round trip is minutes. It has no art or
colours of its own: the drawings come from the generator's own table and the
palettes are read back out of `scenes.dart`, so there is no second copy to
drift. `test/widget/airfield_render_test.dart` is the check that the preview
and the real renderer agree; pass it `SHOT_DIR` and compare the two.

Two cautions, both learned the hard way. The preview strips `//` comments
before reading the palettes, because a comment that names a colour by its
literal — explaining why an ink was changed, say — is otherwise read as an
extra entry, and every ink after it shifts by one. The symptom is a scene that
previews in entirely the wrong colours while the app is fine.

And `scenes.dart` holds six scenes, each with
a `day: ScenePalette(` in it, so a script that repalettes the airfield by
searching for that unanchored finds the *meadow's*, and silently moves the
free starting world to an airport. Anchor on `const SceneTheme _airfield =`
first.

### Tier ten was a cape, and a cape does not work

Built and rejected on the animal, twice. An accessory always draws on top
of the pet, so there is no *behind* to hang cloth in, and a cape's whole
read is fabric falling behind the shoulders. Both readings available from
the front fail: a closed shoulder mantle is a bib, and an open two-panel
cape is a horseshoe — a symmetric hanging pair, the same failure that once
made the scarf read as striped shorts. Widening the shoulders past the body
to fake the depth just makes a bigger bib.

The replacement turns the constraint into the subject. A scarf caught by
the wind needs only the one thing this canvas has spare — clean background
beside the animal — so its tail streams to the viewer's right, where the
silhouette is clear (the cat's own tail occupies the lower left). It is
also the only asymmetric piece in the catalogue, which is what keeps a
single streamer from reading as one of a pair of legs.

### Which existing pieces may be recoloured

Not `tophat`, `crown`, `medal` or `mortarboard`. Those four are the bond-gated
pieces, and a recognisable variant of one, sold, is the lane confusion above:
a player short of Attached would wear the bought top hat while the earned one
stayed locked. `crown` is doubly out on the gold rule.

Not `glasses`, `partyhat_border` or `partyhat_noborder` — no recolourable
fills at all.

Everything else is fair game. The best sources have two flat fills and no
colour doing identifying work: `scarf`, `beanie`, `bowtie`, `cowboyhat`,
`collar`, `necklace`, `mask`, `partyhat`.

## Season two — Witching Hour (the world only)

Season two exists so far as one world and no pieces. The owner drew a pumpkin
patch — a crooked witch's house, a bubbling cauldron and a crowd of
jack-o'-lanterns on green grass under a lavender sky — and it is wired as a
pass world, `bg_pumpkin_patch`, on its own track in `seasonPasses`.

**Named for the mood, not the date.** The first rule above is *no dated
holidays*, and this art is Halloween art. The world is called Pumpkin Patch and
the pass Witching Hour — a place and a time of night, which still read right
when somebody claims the rung in April. Both names are placeholders: the pass
name is a plain string in `season_pass.dart`, the world's is the arb key
`scenePumpkinPatchName`.

**What is there.** The scene is drawn and recoloured for sunset and night (the
windows, the faces and the pumpkins light up, and each lit thing throws a
halo), it shelves last in the wardrobe under the pass's name, and a tap on it
opens that pass's own page: the pass screen takes a pass id (`/pass?id=season-2`),
with no id meaning season one, the one on sale. The page says "not on sale yet",
because there is no store listing for `com.mimikin.app.pass.season2`.

**What is not.** The ten pieces that would lead up to it, and the store
product. Until both exist nothing can be bought or claimed.

**Two things to know before adding the pieces.**

* The world sits at 5,500 XP, the finale's place on an eleven-rung track, so the
  ten rungs can go in front of it without moving it. Inserting them shifts its
  *index*, and a claim is recorded as an index (`claimedThroughTier`). That is
  safe only while the pass cannot be bought: add the pieces before the listing
  goes live, never after.
* This was not on the roadmap below, whose second season is Night Market. The
  table is left as it was; decide whether Witching Hour replaces that row or
  slots in ahead of it.

The art pipeline is the one the other picture scenes use, with a one-time
conversion in front of it, because this one arrived as a PNG: see
`art_src/gen_pumpkin_patch.py` (PNG to the editable SVG, six colours on a 3px
grid) and `art_src/build_pumpkin_patch.py` (editable SVG to the app's copy).

## Roadmap

Six a year at the bimonthly cadence. Slot lead alternates and no season
repeats the previous palette family.

| # | Theme | Lead slot | Palette | Note |
|---|---|---|---|---|
| 1 | **First Flight** | neck | dusk navy, cream, coral | Confirmed; shapes below |
| 2 | **Night Market** | face | ember, plum, lantern amber | Amber accent only — see the gold rule |
| 3 | **Tide & Harbour** | hat | teal, cream, rope tan | Closest to the house palette; needs the most distinct shapes to feel new |
| 4 | **Ink & Almanac** | neck | inkstone, parchment, seal red | Strongest fit for a language app. Wants spectacles, not goggles |
| 5 | **Wildflower** | face | meadow green, rose, honey | Widest appeal, weakest narrative |
| 6 | **Frost & Ember** | hat | ice blue, charcoal, ember orange | Winter mood without naming a holiday, so it still reads claimed in June |

Season one's shapes are Bandana (neck), Goggles (face), Flight cap (hat) and
Flight scarf (neck). Later seasons should avoid reissuing a silhouette already on a
track — a variant of a *pass* shape is fine, a second shape that reads the
same is not.

Whether every season ends on a scene is open. It is the cheapest tier on the
track to make — no SVG, no per-pet placement, no re-pixelising for the chick,
and `gen_airfield.py` makes the next one cheaper still — and the most valuable
to receive, which is a suspiciously good deal and a reason to be careful
rather than to repeat it by default. Six worlds a year
would also make the wardrobe's scenery shelf mostly pass content, which is the
lane creeping. Treat it as available to a season, not owed to one.

### Shapes held for later seasons

Considered for season one and kept rather than discarded. All recolour well:
**necktie** and **ruff** (neck), **round spectacles** and **cheek marks**
(face), **bucket hat**, **ushanka** and **flat cap** (hat).

Round spectacles are worth their own note: existing `glasses` is outline-only
and cannot be tinted, so a coloured-rim spectacle is a genuinely new object
rather than a duplicate. It is the obvious face shape for Ink & Almanac.

### Rejected, and why

**Chef's hat, halo, straw boater, pirate tricorn, monocle, eyepatch.** Each
has a colour doing identifying work — a crown that stops reading as gold is no
longer a crown, and a white hat that turns navy is no longer a chef's. They
would each be one shape yielding zero variants, which is the opposite of what
a track needs.

**Capes, and anything else whose read depends on depth.** Nothing can be
drawn behind the pet. See the tier-ten note above.

**A background the ladder already gives.** `bg_blue` at level 10, `bg_forest`
at 15 and `bg_sunset` at 19 are the earned lane, and a pass that handed one of
them over would sell something the ladder gives away for studying. This was
first written as a ban on backgrounds outright, which was too wide: what the
lane rule protects is the *item*, not the category. A world the ladder never
awards and the shop never lists cannot be sold back to anybody, which is why
tier eleven is one — see below. The test that holds the line is in
`test/unit/constants/scenes_test.dart`: every scene must be reachable by
exactly one of free, shop and pass.

## State

**The four cat shapes are drawn and the track is wired.**
`art_src/gen_pass_acc.py` authors them directly on the 7-unit cell grid —
symmetry then holds by construction rather than surviving a resample — and
emits `acc_<id>.svg` plus `acc_<id>_icon.svg` for bandana, goggles, flightcap
and flightscarf. Zero seams on all four, measured with `shape-rendering`
stripped, which is the only way the check means anything (Chrome honours the
attribute and flutter_svg does not).

`seasonPasses` carries season one, all ten pieces are in `kAccessories` tagged
`requiredPass: kSeasonOneId`, the track has a screen at `/pass` with a door on
the profile, the store is wired end to end, and every new string is translated
into all 27 locales (`untranslated_messages.txt` is `{}`).
1,202 tests pass; analyzer clean.

**Tier eleven is drawn and wired too.** `Departures` is in `kSceneThemes`, in
neither the shop catalogue nor the level ladder, and `isPassScene` gates it.
Its sixteen drawings are traced from `art_src/ref_airfield.svg` and generated
from the grids in `art_src/gen_airfield.py`, and painted by `SceneMotifBox`.
`SeasonPassTier.scene` carries it; the track card draws it as a
`SceneThumbnail` and the fitting room puts the player's own pet in front of
it. Claiming it calls `CharacterProvider.grantScene`, which hands the world
over and moves the pet in — the same beat buying a scene has, for a rung that
cost 5,500 XP rather than 200 coins. The wardrobe shelves it last, labelled
with the pass's name rather than a price, and a tap on it opens `/pass`.

Ownership deliberately lands in the unlocked set rather than being derived
from the claim record the way pass *accessories* are: the home screen has to
answer "which world am I painting" with no pass record in reach. The record
still gets the last word — `updateFromUser` puts back a claimed world whose
unlock never reached the save, whichever of the two providers loaded first.

### Final palettes

| Tier | id | Name | Palette |
|---|---|---|---|
| 1 | `bandana` | Sunrise Bandana | coral, navy roll |
| 2 | `bandana_cloud` | Cloud Bandana | cream, navy roll |
| 3 | `scarf_dusk` | Dusk Scarf | navy / cream stripes |
| 4 | `goggles` | Flight Goggles | navy frame, smoke lens |
| 5 | `goggles_brass` | Brass Goggles | leather frame, amber lens |
| 6 | `beanie_dusk` | Dusk Beanie | navy / cream — matches tier 3 |
| 7 | `flightcap` | Flight Cap | leather, cream band |
| 8 | `flightcap_cloud` | Cloud Flight Cap | cream, navy band |
| 9 | `cowboyhat_charcoal` | Charcoal Cowboy Hat | slate / grey |
| 10 | `flightscarf` | Windswept Scarf | coral, cream tail tip |
| 11 | `bg_airfield` | Departures | six inks per time of day; see `scenes.dart` |

Tier 9 uses the top hat's `#242e38` and `#727072` rather than the
mortarboard's `#4a5668`: the latter is blue enough that the hat reads as navy,
and the track has navy pieces already.

### A bug this uncovered

`AccessoryDef.isFreeStarter` was `price == null && requiredStage == null`, and
`AccessoryOwnership.isOwned` asks it *before* it asks about the pass. A pass
piece carries neither a price nor a stage, so every one of them answered "free
starter" and the pass branch below was unreachable — the whole track would
have been free the moment the first piece was tagged. It had never bitten
because no accessory had `requiredPass` until now. Fixed, with a regression
test that fails against the old getter.

### Remaining

1. **The other two pets.** Only the cat is layered, so only the cat wears
   anything. The dog needs a measured `_AccessoryPlacement` per new shape, read
   out of an `art_src/dog_with_<accessory>.svg` reference drawing by
   `art_src/acc_offset.py`; the chick needs its hats re-pixelised smaller
   (`gen_bird_hats.py`) and its face pieces cut to one eye (`gen_bird_acc.py`).
   The six variants need none of this — they inherit the source's placements.
2. **Store product** `com.mimikin.app.pass.season1`, as a non-consumable, in
   Play Console and App Store Connect. Everything on this side is done and
   waiting for it: the service queries the id, a purchase or a restore lands
   on `UserProvider.grantPass`, and the screen draws the store's own formatted
   price. Until the listing exists there is no price to draw, so the page says
   the pass is not on sale rather than showing a button that cannot charge.

   Note the pass id is NOT a dart-define like the two subscription ids. It is
   recorded against every tier a player claims and has to outlive their save,
   so it lives in the catalogue beside the track it sells.

## Looking at it

The screen is at `/pass`, reached from the tile under the Plus tile on the
profile. Nothing owns the pass in a dev build and there is nothing to buy, so
the track is otherwise only ever visible in its empty state:

    flutter run --dart-define=SEASON_PASS_XP=2600

That draws the pass as though it were bought and 2,600 XP in — four tiers
ready, seven locked. It is display only: it grants nothing, writes nothing and
marks nothing claimed, so a dev run cannot leave a purchase record behind. 0
shows a freshly bought pass, 5500 a finished one.

To see the pieces on the pet rather than in the track:

    flutter run --dart-define=UNLOCK_ALL_ACCESSORIES=true

And to look at the page without building the app at all, the widget test
writes a PNG of each state:

    flutter test test/widget/season_pass_screen_test.dart --dart-define=SHOT_DIR=shots
