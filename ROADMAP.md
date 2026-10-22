# Mimikin roadmap

Started 2026-10-19 from the owner's list. Tick the boxes as things land.
Each item says what was found in the code, what is still undecided, and what
it depends on. Findings are from reading the code on 2026-10-19; the "to
check" notes are things I could not confirm.

## At a glance

| # | Item | Kind | Size | Blocked by |
|---|------|------|------|------------|
| 5 | Remove the XP bar from the quiz | code | - | **done** (removed in another session) |
| 7 | Bond: drop the meter from home, keep the stages | code | small | **done 2026-10-21** |
| 8 | Overall UI lineup | design | medium | - |
| 9 | Town: rename, own tab, add the School (quizzes move there) | art + code + l10n | large | **mostly done 2026-10-21**: tab, School, rename and names on the map are in; chat's town button and Review/Mistakes are open |
| 10 | Drop the chat box from home | code | small | **done 2026-10-22** |
| 6 | New bottom nav art | art + code | medium | #8, #9 |
| 1 | Slow app launch | perf | medium | measure first |
| 2 | Filler between screens, no half-loaded frames | perf + art | medium | **half-loaded pet fixed 2026-10-20**; filler still open |
| 3 | Toy chest art and game backgrounds | art + code | large | art sheets |
| 4 | Battle pass and Plus page design | design + art | large | pass structure decision |

## Suggested order

1. **Decide, no code:** #8 (lineup), #9 scope, #7 (bond), #5 (which bar).
   Four answers unblock almost everything else.
2. **Quick wins:** #5 and the home bond meter from #7.
3. **Speed:** #1 and #2 together. Both are about not showing a screen until
   it is ready.
4. **Structure:** #9, then #6, since the nav art depends on how many tabs
   there are and what they are.
5. **Art batch:** #3, #4, #6 art. These wait on image sheets from the owner,
   so they can run in parallel with step 3 or 4 whenever the art arrives.

---

## 1. App launch is slow

- [ ] Measure a cold-start timeline on the Reno2 Z (the target phone)
- [ ] Get `runApp` on screen before the network is touched
- [ ] Cut what the first frame waits for

**What the code does today**
- [lib/main.dart](lib/main.dart) awaits `_startCloudSync()` *before*
  `runApp`. That means `Firebase.initializeApp` and then `sync.start()`,
  which is capped at 8 seconds. On a slow network the player sees no app UI
  for up to that long, because the splash screen does not exist yet.
- The reason it is awaited is deliberate and documented in `main()`: a
  restore rewrites local storage and every provider reads that storage once
  at construction. So this cannot just be moved to the background; see the
  plan below.
- `GoogleFonts.config.allowRuntimeFetching = true`, with a comment saying
  some GoogleFonts styles are not bundled. Any font fetched over the network
  on first use is a launch cost and a flash of the wrong font.
- Several providers load from disk at construction (`ScenarioProvider`,
  `SettingsProvider`, `TutorialProvider`, `VocabProvider`, `AdsProvider`).
  Ads and the store connection are not needed for the first frame.
- [lib/screens/splash_screen.dart](lib/screens/splash_screen.dart) is a
  spinner and the word "Mimikin". It is only reached after `runApp`.

**Plan**
1. Measure first: time to first frame, time to home interactive, and how
   much of it is Firebase, fonts, provider loads, and asset decoding.
2. Show the splash immediately and run the cloud restore behind it, but
   only wait for it when this device has no local save (the one case where
   the restore has to land before the providers read). A returning player
   with a save should never wait on the network at all; sync can then
   reconcile in the background.
3. Bundle the fonts that are fetched at runtime.
4. Defer ads and premium setup until after the first frame.

**Decide:** how much launch delay is acceptable for a brand-new install that
has to restore from the cloud (a spinner with the pet, probably).

---

## 2. Cute filler between screens, and no half-loaded frames

- [x] Find where the half-loaded pet comes from
- [x] Make the pet appear as one finished unit (built 2026-10-20, uncommitted,
      not yet seen on the phone)
- [ ] Look at it on the Reno2 Z and in the Chrome preview
- [ ] Add a filler for whatever delay is left (only if the phone still shows one)

**What was wrong (three causes, all in the pet sprite)**
1. flutter_svg parses each layer in the background when a widget mounts and
   throws the parsed picture away when the widget unmounts. So every screen
   re-parsed the pet, and each of its ~8 layers (coat, tail, mouth, eyes, each
   hat) finished in its own frame: the coat first, then the rest.
2. Until its raw SVG text had been read, each sprite drew the *un-recoloured*
   original art, which is the "pet in its original colour" flash. The text was
   also read again by every sprite, one file at a time, for all 30 pets.
3. At launch the sprite drew before the saved pet had been read, so it showed
   the default cat in the default coat with nothing on, then changed.

**What was built**
- [lib/components/pet_art_cache.dart](lib/components/pet_art_cache.dart): one
  shared cache that reads and parses each layer once and keeps it across
  screens, plus `PetPicture`, which draws a parsed layer in the same frame it
  is built.
- [lib/components/character_sprite.dart](lib/components/character_sprite.dart):
  a sprite now draws a complete "look" (every layer ready) or nothing. When
  the pet changes (new hat, new coat, another pet) the old look stays up until
  the new one is entirely ready, then swaps in at once. It also waits for the
  saved pet to be read (`CharacterProvider.isLoaded`).
- [lib/main.dart](lib/main.dart): the current pet is read and parsed while the
  splash is up, so the first screen already has it.
- Tests: `test/widget/pet_art_test.dart` (all layers in one frame; whole on the
  first frame of a later screen; a hat swap never shows a half state; an unread
  save is not drawn; pixel-for-pixel against flutter_svg in three box shapes).
  Mutation-checked: removing the readiness check fails the four behaviour tests.
  Full suite 1857 pass, analyzer clean.
- Test note: tests that look inside the pet now call `settlePet(tester)`
  (`test/helpers/pet_art.dart`), because the pet draws nothing until its art
  has really loaded and a widget test's clock never lets real time pass.

**Still open**
- Only the *pet* is covered. Other art that pops in on a screen change
  (scenery, accessory icons in the shop, boss arenas) still loads on its own.
  The perf work's `RasterizedSvg` already caches scenery between screens.
- The filler between routes is only worth building if the phone still shows a
  gap after this. A short themed transition (pet curled asleep, a pixel
  curtain, a bouncing paw) as one shared widget in the router would cover it.
- Not measured on the phone: the first launch after install parses the pet
  during the splash, so check that the splash does not now run longer.

---

## 3. Toy chest artwork and proper game backgrounds

- [ ] Toy chest art: closed, open, and the picker
- [ ] A background for each game
- [ ] Game pieces and icons that match the new art

**Where it lives**
- The chest and its picker: [lib/components/play/toy_chest.dart](lib/components/play/toy_chest.dart),
  placed on the home screen.
- The games: [lib/screens/play/](lib/screens/play/) (Bubble Bath, Pounce,
  Pond Hop, Fetch) and [lib/screens/play_catch_screen.dart](lib/screens/play_catch_screen.dart)
  (Catch), all routed from [lib/router.dart](lib/router.dart). Each shares a
  cooldown and a daily XP cap of 30.
- They were built from the boss-trial openers, so today they borrow
  boss-trial pieces and not art of their own.

**Plan:** the same route the boss UI and the scenes took: owner sheet
(image tool) -> script that cuts it -> Dart art table -> wired in. One scene
per game, plus the chest.

**Decide:** one shared style for all five backgrounds, or each game gets its
own mood (bath = bubbly bathroom, pond = lily pads, and so on). The second
is more work and reads much better.

---

## 4. Proper design for the battle pass and the Plus page

- [ ] Decide the pass structure (see below)
- [ ] Design the Plus page
- [ ] Design the pass page

**Where it lives**
- Plus is `PremiumScreen` in [lib/screens/premium_screen.dart](lib/screens/premium_screen.dart).
  The code calls it "premium", so search for that when you want it.
- The pass is [lib/screens/season_pass_screen.dart](lib/screens/season_pass_screen.dart).
  Both also appear as bodies inside the shop hub ([lib/screens/shop_hub_screen.dart](lib/screens/shop_hub_screen.dart)).

**Open structural question first:** the 2026-10-10 plan turns the Witching
Hour pass into a windowed free-plus-premium battle pass of about 30 tiers.
That overrides the older "not a battle pass, no free track" docs. The page
design depends on which of those is true, so settle it before drawing.

**What each page needs from a design pass:** a clear reason to buy at the
top, a preview of what is unlocked (the pass track with free and premium
rows), the price and the thing you get, and the restore-purchases path. The
pet should be the hero on both.

---

## 5. Remove the XP bar from the quiz

- [x] Removed in another session (confirmed 2026-10-20)

**Notes from when I went looking.** I could not find an XP bar in the quiz. What I found:
- The quiz header in [lib/screens/quiz_screen.dart](lib/screens/quiz_screen.dart)
  already has a comment, "No level here: it is a number about the player,
  and this is a lesson". It shows the daily-allowance meter and Pause.
- The rewards popup after a quiz prints "+N XP" in its REWARDS box
  ([lib/components/quiz_rewards_popup.dart](lib/components/quiz_rewards_popup.dart)).
- The home screen has the level and XP pill, which is not the quiz.
- The onboarding quizzes show a question counter.

So the working tree may already be past this, or the bar is one of the above
(most likely the rewards popup, or the allowance meter, which looks like a
bar). Send me a screenshot of the one you mean and this is a ten-minute job.

---

## 6. New art for the bottom nav bar

- [ ] Wait for the lineup (#8) and Town (#9) before drawing
- [ ] New icons and bar background
- [ ] Update labels, the home tour and tests

**Where it lives:** [lib/components/navigation_wrapper.dart](lib/components/navigation_wrapper.dart).
Today: Quiz, Chat, Home (centre, no label), Shop, Profile, using
`assets/svgs/icon-*.svg` on a plain white bar with a 4px border.

**Updated 2026-10-20:** the tabs are now Town, Chat, Home, Shop, Profile (Town
replaces Quiz, see #9). The icon for Quiz is retired and Town needs one.

**Things to know before redesigning**
- The bar is only drawn on `/`, `/shop`, `/new-chat` and `/chat/*`. It is
  hidden on the quiz and profile screens. Decide whether the new bar should
  be everywhere.
- Labels sit in a fixed 72-wide slot because the East Asian pixel fonts are
  wide (the code names `navLabelSlotWidth`, and tests guard it). A sixth tab
  will not fit unless labels shorten or go icon-only.
- The home tour points at four nav items through showcase keys, so adding,
  removing or renaming a tab means updating the tour and its strings.

---

## 7. Is there a point to the bond system, and drop it from the main page

- [x] Decided 2026-10-20: meter out, stage ladder kept as an internal gate,
      missing-you / lonely states kept
- [x] Remove the meter from the bottom of home (2026-10-21: `bond_meter.dart`
      and its test deleted, the home tour step gone, the pet keeps its place)
- [x] Clean up what the meter leaves behind (`bondLabel`, `bondToNextStage`,
      `bondKeepLearning`, `tutorialHomeBond` removed from all 27 files).
      `bondLonely` and `bondMissesYou` are kept, now unused, for when the pet
      says them somewhere else.

**What it is today.** [lib/constants/bond.dart](lib/constants/bond.dart)
says it plainly: bond *used to be* its own point ledger and is now just the
player's level read through a ladder. Five pet stages (curious, friendly,
attached, devoted, inseparable) unlock at levels 1, 6, 12, 19 and 27. The
only thing it adds beyond level is the "missing you" (2 days) and "lonely"
(7 days) pet states when the player has not learned anything.

**My read:** the home meter duplicates the level pill, since a stage is a
function of level. The stage system itself is doing real work: accessories,
colours and the season pass reference it as unlock gates. So the two parts
have different answers.
- The **meter on home**: no real point, remove it.
- The **stage ladder**: keep as an internal gate, and tell the player about
  it only at the moment it matters, such as a "your pet is now Friendly"
  level-up moment, or as a line on the pet's card. If you would rather
  retire it, unlocks need re-keying to plain levels. That is a much bigger
  change.
- The **missing you / lonely** states: keep, they are the gentle retention
  hook and cost the player nothing.

**Where it lives:** the widget is [lib/components/bond_meter.dart](lib/components/bond_meter.dart),
placed in [lib/screens/home_screen.dart](lib/screens/home_screen.dart) (around
line 1886). Bond is also threaded through `accessory_ownership`,
`character_provider`, `bond_progress`, `bond_context`, `shop`, `gold`,
`ads` and `season_pass`, so removing only the widget is safe and removing
the concept is not.

**Cleanup if the widget goes:** the meter's own strings (`bondLabel`,
`bondToNextStage`, `bondKeepLearning`, and probably the missing-you and
lonely lines unless the pet speaks them elsewhere) become unused across the
30-odd `.arb` files. The stage names stay, since the wardrobe uses them for
its locked tiles. `tutorialHomeBond` already looks unused: nothing in the
Dart code reads it, so it can go regardless. Edit the arb files with the
Edit tool or Python on bytes, never PowerShell, which corrupts the encoding.

**Decide:** meter out and stage kept (my recommendation), or the whole
concept retired?

---

## 8. Ideas for a better overall UI lineup

- [ ] Write down what each screen is *for*
- [ ] Sketch two or three tab layouts and pick one
- [ ] One header, one back-button, one popup style across the app

This is a design pass, not code, and it comes first because #6 and #9 hang
off it.

**Today's map:** nav tabs are Quiz, Chat, Home, Shop, Profile. Scenarios is
reachable only from inside the chat screen. Plus and the pass sit inside
the shop hub, and the wardrobe, toy chest and boss climb are opened from
home. The bar is hidden on two of its own five destinations (quiz and
profile).

**A strawman to react to (not a recommendation yet)**

| Tab | Holds |
|-----|-------|
| Home | the pet, care, toy chest, wardrobe, daily reward |
| Town | the scenario buildings and the School, where the quiz is (see #9) |
| Chat | free conversation |
| Shop | shop, Plus, the pass |
| Profile | profile, settings |

Updated 2026-10-20: with the quiz moving into the Town's School, Town takes
the Quiz tab's place and the bar stays at five. Review and mistakes have no
tab of their own any more; they could be rooms or a sign in the School, or
sit on the profile.

**Questions this pass should answer:** where the boss climb belongs (it is
currently opened from a badge on home); whether Review and Mistakes deserve
a place of their own; whether Plus and the pass belong in the shop or are
promoted; and what the single most important thing on home is.

---

## 9. Call it "Town", make it its own tab, disconnect it from chat

- [x] Decided 2026-10-20: Town is its own tab in the bar
- [ ] Rename Scenarios to Town everywhere
- [ ] Make it a nav tab (which tab it replaces or joins is #8's call)
- [ ] Remove the chat screen's entry point to it
- [x] Decided 2026-10-20: building conversations stay as they are (option a
      below). Entering a building still opens the scenario chat.
- [x] Decided 2026-10-20: a **School** building beside the office (the town
      hall), where the quizzes are done. See "The School" below.

**Today (before the changes above):** the town map is [lib/screens/scenarios_screen.dart](lib/screens/scenarios_screen.dart)
at `/scenarios`, and the only way in is a button in
[lib/screens/chat_screen.dart](lib/screens/chat_screen.dart) (around line
1004). Walking into a building opens a *chat* with scenario parameters
(`isScenario`, `scenarioId`), so the conversation itself still runs through
the chat screen. There is already scenario-specific UI inside the chat
(`scenario_stage`, `scenario_objective_tracker`).

**What needs deciding.** "Not connected to the chat" could mean either:
- **(a) Navigation only.** Town becomes a top-level tab, entered from the
  bar, and a building still opens a scenario conversation. This is the
  small version.
- **(b) A real split.** Scenarios get their own conversation screen, with
  their own history, separate from the Chat tab's chat list. Larger, and it
  touches `ChatProvider` and how scenario chats are stored.

Decided: (a).

### The School

The quiz moves out of the nav bar and into the town, which also answers
which tab Town takes: **Town replaces Quiz in the bar**, so it stays at five
tabs (Town, Chat, Home, Shop, Profile) and #6's width problem does not arise.

**What it needs**
- **Art.** A new building on the town map, beside the town hall (the office,
  `job_interview`, at the top of the avenue on its forecourt). The town is cut
  from the owner's single map image by `art_src/gen_city.py`, so this means a
  new map (or a school sprite plus a ground change) from the image tool, then
  a re-cut: a new `city_school.svg`, new door and pavement numbers in the
  generator's `BUILDINGS` table, and a path link from the avenue. Check the
  forecourt has the room: the hall is centred on x=510 and the lots either
  side are currently open grass.
- **It is not a scenario.** Every other building is a scenario with a host
  pet, objectives and a progress chip, and tapping one walks the pet there
  and opens a chat. The School has none of that: it opens the quiz. The town
  code assumes one building per scenario, so the School needs its own kind of
  spot (door, pavement, label, no host, no chip) and its own action on the
  bottom card.
- **Where the quiz sits.** The quiz screen currently has its pause/exit
  dialog tied to the nav bar (`navigation_wrapper.dart`, the `/quiz`
  special cases). With the quiz entered from a building, "back" and "exit"
  should return to the town, standing at the School door.
- **The quiz's other doors.** Anything that sends the player to `/quiz`
  today (home, daily reward, tutorial, notifications) should still work. Decide
  whether they keep going straight to the quiz or arrive via the School.
- **The home tour** points at four nav items including Quiz; its step and
  strings change. A first-time player also needs to be told the School is
  where the quiz went.
- **Name.** "School" needs translating in every language file, with the same
  short-label limit as the other building names.

**Decided 2026-10-20**
- Tapping the School walks the pet to the door first, like every other
  building.
- Tapping it shows the player's **progress** on the bottom card (the card the
  other buildings use for their objectives), with the button to start a quiz.
  Default I will build unless told otherwise: quizzes done today against
  today's allowance (the quiz screen already has that meter).
- Quizzes start from the School now. The Quiz tab is gone and the home screen
  gets no separate quiz button.
- Art order: the School building on its own first, then the town rearranged
  around it. The path down the middle of the town is copied to separate the
  School from the office, the way the avenue separates the buildings on the
  lower rows.
- **Town art done in code, not with the image tool (2026-10-20).** The hall is
  scaled to the restaurant's width, the School is cut from
  `art_src/School building.jpg` at the same width with its windows redrawn,
  the avenue runs up between them off the top edge, the row-2 sidewalk is
  copied in front of both top doors, both sidewalks have a top border, the
  edge trees the new sidewalk covered are put back over it, the dome's and
  cafe's stubs are one slab wide, the plaza's side roads have the avenue's slab
  spacing, and every straight path border and joint is two cells. All of it
  lives in `art_src/gen_city.py` (`rearrange`, `school_cells`, ...).

**Status 2026-10-20 (School in the app)**
- [x] Town art generated and in `assets/svgs/` (`city_school.svg` new,
      `city_office.svg` and `city_ground.svg` changed). The previous town is
      saved in `art_src/_before_school/`.
- [x] The School is on the map, beside the hall. The pet walks to its door
      first, along the paths; tapping it shows its card with today's quizzes
      used against the allowance (for a member, what the quiz is instead); the
      card's door starts a quiz (`/quiz` is pushed, so backing out lands in the
      town). New string `townSchool` ("School") in all 27 languages.
- [x] Tests: layout (the School's lot, door, paths, picture) and
      `test/widget/school_card_test.dart`. Suite 1868 pass, analyzer clean.
- [x] Overwrite guard: the generator records a fingerprint of every file it
      writes in `art_src/.city_manifest.json` and leaves any file that no longer
      matches (hand-edited) alone, with a message; `--force` overwrites. Tested.
      If you move or resize a hand-edited building, the numbers in
      `scenario_city.dart` need updating too (the layout test will fail until
      they do).
- [x] **Tab swap and quiz exit (2026-10-20).** Town replaces the Quiz tab in the
      bar (new `icon-town.svg`, label "Town", the bar stays up on the town, the
      town's own back arrow is gone). A quiz is left by the way it came: Exit,
      Pause and finishing all go back to the town (pop; with nothing under it,
      to `/scenarios`, not home). Home tour: the first nav step now points at
      the Town tab (`navTownShowcaseKey`, string `tutorialNavTown`). Tests in
      `test/widget/town_tab_test.dart`, mutation-checked.
- [x] **Translated 2026-10-21:** `townTab`, `tutorialNavTown` and `scenarios`
      (now the header "Town") are in all 27 languages. The translations are mine,
      not a native speaker's: worth a skim for Spanish ("Pueblo"), Japanese
      ("まち") and Vietnamese ("Thị trấn", the longest tab label).
- [x] Cleanup: `tutorialNavQuiz` and `quizMode` removed from all 27 files.
- [x] Rename Scenarios to Town (the header and the tab; internal Dart names stay).
- [x] **Names on the map (2026-10-21).** The "0/3" progress chip on each building
      is replaced by the building's translated name on its roof (a green sign
      once cleared). The progress is on the card when a building is picked. The
      yellow frame round the picked building is gone; the pin stays.
- [x] Chat's button to the town removed (2026-10-22). It was a card in the
      "choose chat type" dialog behind the sidebar's new-chat button; with the
      scenario card gone the dialog had one option, so the button now starts a
      blank chat directly. Strings `chooseChatType`, `blankChat`,
      `blankChatDesc`, `roleplayScenario`, `roleplayScenarioDesc` removed.
- [x] Review and mistakes live behind a new **study button** on home (2026-10-22,
      `lib/components/study_hub.dart`): a book icon on the top bar, always
      shown, with the due count on its corner. It replaced the review badge that
      only appeared when cards were due. It opens a two-row dialog, Review and
      Mistakes, each with its count. The home tour's review step is now always
      shown (`tutorialHomeReview` rewritten in 27 languages).
- [x] **Bug found and fixed (2026-10-22):** `MistakesProvider.loadMistakes` was
      never called, so saved mistakes were not loaded at startup, and the next
      recorded one overwrote the saved list with just itself. `main.dart` now
      loads them.
- [x] **Sample mistakes for development (2026-10-22):** six English sentences
      with a slip, a correction and a Turkish explanation
      (`lib/constants/sample_mistakes.dart`), added to the Mistakes list and the
      review queue with `flutter run --dart-define=SAMPLE_MISTAKES=true` (debug
      builds only). Held in memory and never saved, so they cannot reach a real
      save or the cloud copy.

**The rename touches:** the route and screen names, the nav label, and the
localized `scenarios` string in every language file (the name "Town" has to
be translated for 30-odd locales, and the CJK pixel faces need the labels
to be short). Internal Dart names can stay as they are, as with the
Mimikin rename.

---

## 10. Drop the chat box from home

- [x] Input dock, send logic and the home AI session removed from
      [lib/screens/home_screen.dart](lib/screens/home_screen.dart)
      (2026-10-22). Talking to the pet is the Chat tab's job.
- [x] Tour step `homeChatShowcaseKey` gone; strings `typeHere`, `youLabel`,
      `mojiSleepReconnect`, `tutorialHomeChat` removed from all 27 locales.
- [x] Tests updated: the AI-outage bubble test became a night-sleep one, and
      three layout assertions that leaned on the dock were loosened.
- [ ] Look at it on a device: the scene now runs to the nav bar, about 100pt
      taller, so the pet stands lower on the screen. `_kPetFootOffset` (88)
      is still measured from the scene's bottom.
- [x] Dead leftovers removed (2026-10-22): the AI-outage sleep state
      (`setAiIssueSleepMode`, `SleepReason`, the provider guards), the pet
      persona (`AiPromptSpec.pet`, `FallbackPrompts._pet`, `buildPetInstruction`
      and its quota entry in the server, its README row), and seven unused
      sleep strings. Server tests now use `chat` as the session-opening mode.
- [x] The space the dock left now holds an action bar
      ([lib/components/home_action_bar.dart](lib/components/home_action_bar.dart)),
      scattered around the pet on the scene's ground (chest and tower in the
      side margins level with its feet, books in front), with no bar or frame
      behind them:
      toy chest (moved off the grass), Mistakes (new stack-of-books icon,
      opens the list directly) and the boss climb (new tower icon). Icons are
      pixel grids in code, placeholders until there is art. The climb button
      is still behind `BOSS_TRIAL`, as the badge it replaces was; ungating it
      is one line in `home_screen.dart` plus a translated label.
- [x] Mistakes art is real: row 2, piece 2 of the generated props sheet
      (`art_src/home-props-sheet-v2.png`), cut and cleaned by
      `art_src/gen_home_props.py`. The toy chest and tower are still the
      3pt-cell placeholders, so they look chunkier than the books; the sheet's
      rows 1 and 3 were rejected, a second round is being generated.
- [ ] Open: the book button on the top row still opens the Review/Mistakes
      hub, so Mistakes has two ways in. Decide whether that button becomes
      Review-only (its tour text mentions mistakes in all 27 locales).
- [ ] Open: the home tour has no step for the action bar.

---

## Parking lot

- The Halloween pass plan (windowed, free plus premium) feeds #4.
- Nothing is published yet, so tab structure, route names and the Android
  app ID are the cheap things to get right now.
- The work tree has a large uncommitted pile (art, l10n, perf). Commit it in
  slices before starting the nav and Town changes so they diff cleanly.
