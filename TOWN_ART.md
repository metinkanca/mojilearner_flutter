# Town art: getting the generated PNGs into the app

For any chat asked to "add the town art" / "wire the scenario interiors". Read this
first; it was written 2026-10-10 from the session that produced the art, so it holds
what was measured and decided there. The scenarios feature itself is described in the
`scenario-city` memory.

**What exists:** 14 generated PNGs (town ground, 6 building exteriors + the kiosk,
7 interiors) in [art_src/town_src/](art_src/town_src/). **What does not exist yet:**
anything in the app. The app still draws the old placeholder map
(`assets/images/riverdale_city.png`) and a flat room for every scenario except the
doctor's (`assets/svgs/scenario_doctor_backdrop.svg`, old shaded art).

Do the work in this order, and ask the owner at the four decisions in section 5
before building past them.

---

## 1. The files

| File in `art_src/town_src/` | Size | What it is | Scenario id | Host pet |
|---|---|---|---|---|
| `ground.png` | 1024x1536 RGB | the town ground: avenue, walkways, park, plaza + fountain, pond, trees. **No buildings** | - | - |
| `exterior_cafe.png` | 1536x1024 RGBA | café building (transparent bg) | `coffee` | fox |
| `exterior_office.png` | 1402x1122 RGBA | office, the biggest building | `job_interview` | rabbit |
| `exterior_kiosk.png` | 1536x1024 RGBA | information kiosk **and its signpost** (signpost is to the right) | `directions` | dog |
| `exterior_clinic.png` | 1536x1024 RGBA | pet clinic | `doctor` | cat |
| `exterior_shop.png` | 1536x1024 RGBA | accessory shop (still has a dress + shirts in the windows, see 5.3) | `shopping` | hamster |
| `exterior_restaurant.png` | 1402x1122 RGBA | restaurant | `restaurant` | axolotl |
| `interior_cafe_A.png` / `_B.png` | 1942x809 RGB | café room, wide window (A) or tall window (B). **Pick one** | `coffee` | |
| `interior_office.png` | 1942x809 | office room | `job_interview` | |
| `interior_kiosk.png` | 1942x809 | outdoors, kiosk counter + signpost + tree | `directions` | |
| `interior_clinic.png` | 1942x809 | vet exam room | `doctor` | |
| `interior_shop.png` | 1942x809 | shop with **empty** stands, to be filled (5.4) | `shopping` | |
| `interior_restaurant.png` | 1942x809 | restaurant room | `restaurant` | |

Exteriors have alpha (0..254/255; a few semi-transparent edge pixels, clean them).
Interiors and the ground are opaque.

The generator did **not** produce clean pixel grids: every image is anti-aliased
(~100k distinct colours), colours are near but not equal to the intended palette, and a
few "no shading" rules were broken (darker browns in the office bookcase and desk
front, for example). Everything below is built around fixing that in the build step.

## 2. What the app does today (verify before editing; line numbers drift)

**Map** - `lib/components/scenario_city.dart`
- `CityLayout.mapAsset = 'assets/images/riverdale_city.png'`, `mapSize = Size(1024, 1536)`;
  the world is drawn 1:1 with these units, `Image.asset(..., FilterQuality.none)`.
  `ground.png` is the same 1024x1536, so `mapSize` can stay.
- `CityLayout._spots` has one `_CitySpot` per scenario id: `bounds` (the building's
  rect, also the tap target and where the progress chip sits, top-right corner),
  `doorX`, `pavement` (the y the pets' feet stand on), `hostDx` / `visitorDx` (offsets
  from the door; host on the side away from the avenue, mirrored if it stands right).
  Also `avenueX = 505`, `start` (where the player's pet waits, now (505,1330)),
  `fountain` (now (510,770)), `_mapEdge` (letterbox colour, old grass `0xFF89c95a`).
  All of these were measured off the old picture and **must be re-measured**.
- `route()` walks: along the paving to the avenue, down it, along the target's paving.
  The avenue is a vertical line at `avenueX`; every walkway must join it.
- `_petSize = 124` map units (the sprite box; the visible pet is ~65 tall).
- `scenarioPlaceColor(id)` is the placeholder wall colour. It is used for the stage's
  background (visible until the room SVG loads and as the fallback) and for the icon
  tile in `lib/screens/scenarios_screen.dart` (~line 182). Update it to the new
  places' colours (5.6).

**Chat room** - `lib/components/scenario_stage.dart`
- `scenarioRoomBackdrop(id)` (top of file) returns an asset path or null. Only
  `'doctor'` is set. It is drawn with `SvgPicture.asset(fit: BoxFit.cover, alignment:
  Alignment.bottomCenter)`, so **bottom-aligned, never stretched**.
- Stage is `fullHeight = 150` (compact `76`, shown when the keyboard is up) with a 4 px
  border and 12 px side margins. Inner box on a 390 px phone is about 358x142, aspect
  2.5; the 2.40 interiors lose a sliver of the top there and a sliver of each side on
  a 360 px phone. Aspects from 2.3 to 2.6 are safe.
- Pets: learner at 24% of the width, host at 76%, feet 9.8% of the height above the
  bottom, pet box `min(0.84 * height, 0.3 * width)` (about 107 px). They are drawn in
  front of the room. Compact mode shows only the bottom ~46% of the picture.
- `_RoomSign` (the localised place name, white box, 10 px from the top, about 22 px
  tall, 40% of the width, centred) is drawn over the top middle. A `_ServiceTicket`
  takes its place while the restaurant/doctor offers food/medicine.

**Existing pipeline to reuse** - `art_src/scene_art.py` (read its docstring). It is
for hand-edited layered SVGs (cozy room, meadow, glade): render in headless Chrome ->
`quantise(rgb, palette, snap)` -> `lint(classes, palette)` -> `asset_svg(*palette.for_app(classes))`,
which writes one path per colour with a 1 px bleed under the ink and re-checks that the
SVG reproduces the pixels. `Palette(colours, cell, ...)`: first colour is the underlay
(full-canvas rect), last is the ink, the rest paint in order (back to front).
`build_mushroom_glade.py` is the 10-line template. Output rules that matter:
flutter_svg ignores `crispEdges`, so shapes must not merely touch (the bleed handles it);
after a rebuild, **hot restart** the app, not hot reload (assets are cached).

## 3. Measurements from the generated art

**Interior floor line** (fraction of the picture height where the wall meets the floor;
pets stand in the floor band, so any of these works):
cafe A/B 0.72, kiosk 0.71 (the path, lawn above), office 0.745, restaurant 0.76,
clinic 0.79, shop 0.79.

**Ground geometry**, in `ground.png` pixels (= world units):
- Avenue: x 470-552 (centre ~511, 82 wide), from y ~260 to the bottom edge; a slightly
  flared cap at its top end (y 255-275, x ~455-570). `avenueX` should become ~511.
- Upper walkway: y 532-582 (pets' feet ~y 557). Lower walkway: y 852-900 (feet ~y 876).
  Both run from x ~75 to ~950 and join the avenue.
- Plaza + fountain: fountain bbox (446,1106)-(577,1223), centre (~511,1160). Short side
  paths (spurs) at y 1126-1172: west x ~160-360, east x ~665-865.
- Pond: bbox (119,1238)-(385,1447). Benches near (320,1020) and (705,1020).
- Lots: the **top lot** (y < ~255) is for the office, facing down the avenue. Upper-row
  lots y ~260-530, lower-row lots y ~585-850, left x ~75-465, right x ~557-950. The
  buildings' bottom edge goes on the top of the walkway they face (y 532 / y 852).
- Suggested placement (matches the old scenario slots): upper row restaurant (left) and
  shop (right); lower row clinic (left) and café (right); office at the top;
  kiosk in the park, on the **east spur**, counter facing the spur (pets on the spur at
  y ~1150, host on the far side from the avenue). Check by eye; the owner may prefer
  other slots.
- The avenue is only 82 wide; two pets side by side need ~130. At the office, put the
  pets on its front-step line or widen the avenue's mouth. Look at it composited.

**Building native sizes** (alpha bbox, px) and outline thickness (modal dark-run, px):
cafe 1516x981 / 12; office 1334x1003 / 8; kiosk+signpost 1506x969 / 16; clinic
1471x968 / 11; shop 1475x907 / 11; restaurant 1402x1087 / 10. Ground outline: **6**.
Interiors: outline 6-9 (shop 7, café 9, clinic 6).

Door centres, as a fraction of the canvas width, eyeballed (+-3%): café 0.55, clinic
0.52, shop 0.50, restaurant 0.57, office 0.50; the kiosk's counter window ~0.41 (the
booth is left of centre, signpost right). Measure them properly when placing.

## 4. How to build it

### 4.1 De-blur every PNG onto a real pixel grid (do this first)
For each image: estimate the art-pixel size P (the values above; confirm with the modal
run length of dark pixels), then rebuild it as a grid of `P x P` cells, each cell taking
the **majority palette class** of the pixels it covers. That removes the anti-aliasing,
makes every edge a clean step, and makes later scaling exact. Quantise to the palette in
section 6 with nearest-colour snapping, print the cluster -> target mapping, and stop to
look at any cluster over ~2% of the image that is far from every palette colour
(example: the ground's outline is `#25241d`, which must go to ink `#14120e`, but a new
colour must not be silently turned into ink). `scene_art.quantise(rgb, palette, snap=True)`
does the snapping; it expects exact palette pixels otherwise, so call it on the
de-blurred grid. Work on the exterior PNGs' alpha the same way (threshold at 128, trim
semi-transparent fringe).

### 4.2 Interiors -> six backdrop SVGs
One script, `art_src/build_scenario_rooms.py` (new), one `Palette` per room (section 6),
`scene_art.lint` for outline problems, `scene_art.asset_svg` for the output:
`assets/svgs/scenario_<id>_backdrop.svg`, ids `coffee`, `job_interview`, `directions`,
`doctor` (replaces the old file; `gen_clinic.py` is then dead, keep it unless the owner
says delete), `shopping`, `restaurant`. Crop nothing: keep 1942x809 (aspect 2.40).
Then add the six entries to `scenarioRoomBackdrop` in `scenario_stage.dart`, and update
`scenarioPlaceColor`. Overlays (5.4) are painted onto the grid **before** quantising.

### 4.3 Town map
1. Build the world canvas 1024x1536 from the de-blurred `ground.png`.
2. De-blur and trim each building (4.1), then resample it **by whole cells** so its width
   fits its lot (about 300-330 map units, so scale ~0.2-0.24 from native). Decide the
   pixel-density question (5.1) before this step.
3. Paste building bottoms on the walkway tops (532 / 852), the office at the avenue's top,
   the kiosk on the east spur. Keep the pets' standing lines clear (nothing in front of
   a door, a pet's width of empty paving each side).
4. Output a layered editable master `art_src/town-editable.svg` (one named layer per
   building plus ground + trees, so the owner can move things in Inkscape) and a
   `build_town.py` like `build_cozy_room.py`, writing `assets/svgs/town_map.svg`. If that
   SVG comes out over ~1 MB, ship a PNG at 1024x1536 instead and keep
   `Image.asset(... FilterQuality.none)`. For the SVG, switch the map to
   `SvgPicture.asset(..., fit: BoxFit.fill)`.
5. Re-measure and write into `scenario_city.dart`: the six `_spots` (`bounds` = each
   building's footprint in world units, `doorX`, `pavement`, `hostDx`/`visitorDx`),
   `avenueX`, `start` (the bridge is gone: pick the avenue's bottom end, ~(511,1450)),
   `fountain` (~(511,1160)), `_mapEdge` (the lawn colour). Delete `riverdale_city.png`
   only after the new map is confirmed (it is untracked; ask first).
6. The selection frame on a tapped building is `AppTheme.retroAccent` yellow
   (`#fbf236`); against the gold café it is hard to see. Mention it to the owner.

### 4.4 Verify
- Render the built SVGs in headless Chrome (see `build_cozy_room.py` / the
  `pet-sprite-render-loop` memory) and look at them, at stage size and at phone size.
- `test/widget/scenario_city_capture_test.dart` renders the town and stage to PNG with
  `CAPTURE_DIR`; run it and look at: each building with both pets at its door, the
  route between the farthest two, and each room with a pet on each side (full and
  compact).
- Run `flutter test test/widget/scenario_stage_test.dart
  test/widget/scenario_city_capture_test.dart test/widget/scenario_progress_test.dart`.
  In widget tests warm `rootBundle.loadString` inside `tester.runAsync` before pumping
  (second test of a file hangs otherwise; see the `cozy-room-scene` memory).
- Never rewrite Dart files with PowerShell `Get-Content`/`Set-Content` (BOM + mojibake;
  see `powershell-rewrites-corrupt-source`).

## 5. Open decisions and known problems (ask the owner)

**5.1 Pixel density does not match (the big one).** The ground is coarse: outline ~6
map units and the whole town is only ~170 cells wide. Buildings drawn at their lot size
(~320 units wide) get outlines of only ~2-3.5 units (café 2.5, clinic 2.4, office 1.9,
kiosk 3.4): their lines come out roughly **half the ground's thickness**. Matching them
exactly is impossible by scaling, because a building 126 cells wide would be most of
the map's width at the ground's grid. Options:
- A. Accept it and look at a composite first (expected to be visible, and also a few
  tiny details on the buildings would be under one screen pixel at fit-to-width).
- B. Coarsen each building onto the ground's grid (art pixel ~6 units): matches, but
  keeps only ~1/6 of the cells (café 126 -> ~50 wide) and loses most of the detail the
  owner asked not to lose.
- C. **Recommended if A looks off:** regenerate the ground with finer pixels (~3 units
  outline, e.g. trees ~45 art-pixels tall, picture ~400-500 art-pixels wide), same
  layout. Ask the assistant to write that prompt.
Build a quick composite (ground + 2 buildings + a pet at `_petSize`) and show the owner
before building the whole map.

**5.2 Items the shop doesn't sell are in two rooms.** `interior_cafe_A/B` still shows
cakes under the dome, a teapot and a bean jar; `interior_restaurant` has a water jug and
empty plates. The shop only sells apple, donut, pizza slice, sushi set, espresso and
medicine. Either (i) paint them out on the cell grid and overlay the shop's own items
(5.4), (ii) regenerate those two rooms with "empty displays" prompts (ask the assistant
to write them, as was done for the shop), or (iii) leave them. Recommend (ii) or (i).

**5.3 Shop exterior still has clothes.** `exterior_shop.png` shows a dress on a stand
(left window) and three shirts on a rail (right window). The owner asked for both
windows to be plain: delete everything inside the two cream window frames and fill the
interior with the glass colour (`#a8dcef`, the same pale blue as the other panes),
leaving the frames, their inner black outline and the door untouched. Do this on the
cell grid in 4.1.

**5.4 Café A or B?** Wide window (A) vs tall window (B). Owner to choose; default A.

**5.5 Things in the rooms that will collide with the app's UI.**
- `interior_office.png` has its wall clock at top-middle (about x 50%, y 20-38% of the
  height), exactly where `_RoomSign` sits. Move or remove the clock (do it in the grid;
  fill with wall colour) or the sign covers half of it.
- Tall things behind the pets (clinic cabinet and carrier, shop mirror) are at the ends
  or low; the 24%/76% pet positions overlap the clinic's cone lamp and carrier, which is
  fine because pets draw in front.

**5.6 `scenarioPlaceColor` values** (interior wall = the stage fallback; the same value
colours the scenarios list tile). Suggested: coffee `#f0a93c`, job_interview `#cfc6b8`,
directions `#a8dcef` (sky), doctor `#f6f0dc`, shopping `#9a7cc8`, restaurant `#e98a7b`.

**5.7 Overlays: put the real shop items into the rooms** (the owner wants this; the
items match the shop exactly and can be swapped later):
- **Shop** (`interior_shop.png`): empty stands: 3 round stands on the wall shelf (centres
  at about x 41%, 50%, 59% of the width and y 41%), one T-shaped stand on the counter at
  the left (x ~37%, y ~62%), an open box on the counter at the right (x ~63%, y ~58%), a
  hat tree on the far left with 3 pegs, a mirror at the far right. Candidates, from
  `assets/svgs/`: `acc_cowboyhat`, `acc_partyhat`, `acc_wizardhat`, `acc_beanie`
  (hats on stands/pegs), `acc_glasses`, `acc_sunglasses` (T-stand), `acc_bowtie`,
  `acc_collar` (box). Also `acc_flowercrown`, `acc_headphones`, `acc_mask` if the owner
  wants all 11 coin-priced pieces (they bring green, grey and maroon, so extra palette).
  Not for sale, so do not show: tophat, crown, mortarboard, medal (bond-gated), the cap
  (free), the season-pass items.
  Those SVGs are on the pet canvas (`viewBox="-20 -90 222 328"`) with a **7-unit cell**;
  render each, crop to its alpha bbox, then scale so one cell equals the room's art
  pixel (shop ~7 px, so 1 unit = 1 px), snapping to whole cells. Ask the owner which item
  goes on which stand.
- **Café** (after 5.2): `food_donut.svg` (3 under the dome, 1 on the plate) and
  `food_coffee.svg` (the espresso mug, 2 on the counter), both on a 7-unit grid
  (viewBoxes 84x63 etc.). Café art pixel is ~9 px. The donut brings pink icing
  (`#f2a7b8`), so the café palette gets that colour.
- **Restaurant** (after 5.2): `food_pizza.svg` slices on the two plates. It brings red
  and cheese yellow; the earlier prompt used coral + gold to stay in palette.
- Clinic's capsule jars are already drawn; `food_medicine.svg` is the reference.

## 6. Palettes to snap to

Shared hexes (the whole set uses these; the generator's actual values differ slightly,
e.g. the ground's stone measured `#d5c7b4` and lawn `#bae39c`, so snap, don't match):

| Name | Hex | | Name | Hex |
|---|---|---|---|---|
| ink | `#14120e` | | sea blue | `#3f93c4` |
| pale lawn | `#c6e6a4` | | coral | `#e98a7b` |
| grass | `#8cc56a` | | gold | `#f0a93c` |
| bark brown | `#b07a4f` | | violet | `#9a7cc8` |
| off-white | `#f6f0dc` | | pink (donut) | `#f2a7b8` |
| stone | `#cfc6b8` | | sky/glass | `#a8dcef` |

Per image (order for `Palette`: underlay first, ink last, the rest back to front):
- `ground`: pale lawn (underlay), stone, grass, bark brown, off-white, sea blue, coral,
  gold, ink
- `exterior_cafe`: gold, bark brown, off-white, sky, ink
- `exterior_office`: stone, sea blue, off-white, sky, ink
- `exterior_kiosk`: bark brown, gold, off-white, ink (the counter window is near-black:
  ink)
- `exterior_clinic`: off-white, grass, sky, bark brown, coral, ink
- `exterior_shop`: violet, off-white, bark brown, sky, coral, gold, ink (coral + gold
  drop out once 5.3 is done)
- `exterior_restaurant`: off-white, coral, bark brown, sky, gold, ink
- `interior_cafe`: gold, bark brown, off-white, coral, sky, grass, ink (+ pink after 5.7)
- `interior_office`: stone, bark brown, sea blue, off-white, sky, grass, ink
- `interior_kiosk`: sky, pale lawn, grass, bark brown, gold, stone, off-white, ink
- `interior_clinic`: off-white, grass, bark brown, sea blue, sky, coral, ink
- `interior_shop`: violet, bark brown, off-white, gold, sky, ink (accessories add their
  own colours, section 5.7)
- `interior_restaurant`: coral, bark brown, off-white, gold, grass, sky, ink

Darker tones the generator added anyway (office bookcase interior, desk front, some
shading) will snap to the base brown; the black outlines still separate the parts. Look
at the result.

## 7. Rules from the owner (don't relitigate)

- No text, letters, numbers or icons anywhere in the art (no crosses, cups, cutlery).
  The app prints the names. Don't add any.
- Flat fills only: no shading, gradients, shadows, dithering, or darker/lighter tints.
- Leave detail alone; the owner resizes. Never "simplify" a building to fit.
- Flat colour only on the map: a building is a building, nothing baked under it.
- Buildings and rooms must not contain things the shop does not sell.
- Nothing is published: it is fine to change the art, scenario ids and asset names.
