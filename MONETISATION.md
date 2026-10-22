# Monetisation

Three products, deliberately separate. **Mimikin Plus** is a subscription that
sells capacity and the absence of a punishment; the **season pass** is a one-off that sells cosmetics; **coin
packs** sell the currency the ordinary catalogue is priced in. Bundling any two
of them would mean a player who only wants hats pays monthly forever.

Ads are the fourth income axis and have their own document — `ADS.md`.

All three are reached from one place. `/shop` is a strip of four tabs — items,
top-up, Plus, the pass — because the shop used to be the item grid alone, which
left the screen a player goes to in order to spend showing them a quarter of
what there was, and put the two paid products in front of people who were not
shopping.

**Tabs, not pages**, and that is the design rather than an implementation
detail. Someone comparing what a pound buys — coins, or capacity, or a track of
hats — is doing one thing, and a layout that makes them leave the shop and come
back to compare turns one decision into four errands. So the strip never moves,
the bottom bar never goes away, and no section has a back arrow, because
nothing was ever left behind. `/shop` is one route; the sections are state
inside `ShopHubScreen`.

It opens on the shelves, which is what `/shop` has always meant: the tab
reached by tapping "shop" in the bottom bar should be the shop, not an offer.

Plus and the pass keep their own routes as well (`/premium`, `/pass`) for the
doors that are not the shop — the allowance sheet, the profile tile. Those wrap
the *same* section bodies (`PremiumBody`, `SeasonPassBody`) in a Scaffold of
their own, so there is one copy of each page and two frames around it.

## Mimikin Plus

Mostly what it sells is a bigger number, so the paywall is a comparison table
rather than a pitch. Everything on it is already visible elsewhere in the app.

| | Free | Plus |
|---|---|---|
| AI quizzes a day | 3 | 10 |
| AI messages a day (chat + scenario share one meter) | 30 | 200 |
| Unused quizzes | Expire | Roll over |
| Interstitial ads | Shown | None |
| Pet stats | Decay | Decay slower |
| Rewarded ads | 5/day | 5/day |

Packaging is monthly + annual. Not lifetime: costs here are per-call and
ongoing, so a lifetime buyer with a heavy habit loses money forever.

### The bottom two rows, and why they cost nothing

Three numbers was a thin deal, and two of the three were badly chosen. The
message allowance is a runaway-cost backstop set well above an engaged day, so
"30 → 200" offers more of something the player already had spare. And a
determined free player who watches the day's five rewarded ads reaches eight
quizzes against a member's ten, which leaves the headline row selling **two**.
In practice the table sold ad removal at a subscription price.

Both additions are bounded by construction, which is what makes them
affordable:

**The bank** (`EntitlementConstants.quizBankCap`, 30). Unused quizzes carry
forward. Ten a day is invisible to the way people actually study — a long
Sunday and an empty Tuesday never meet the ceiling on either day — so the
number being paid for does nothing on the one day it was wanted. Banking can
move a quiz between days but can never conjure one: a bank fills only with
quizzes that were *not* generated, so spend across any stretch of days stays at
or under the allowance times the days in it. The cap bounds burst rather than
total.

Two rules are load-bearing and both are tested. **Only a day the player opened
banks anything** — a week away is worth one day's leftovers, not seven, partly
because absence is not itself worth paying for and mostly because the proxy
cannot bank for days it never saw the account call. **Today's own quizzes are
spent before the bank**, because the allowance and the day's ad quizzes both
expire tonight and the bank does not; the other order would turn a day of
rewarded ads into a permanent credit.

**The slower slope** (`PlusCareConstants`). The only line on the page that
sells time rather than a quantity, and the only one that costs nothing to serve
— it is one integer in the decay loop and one in the streak check. What a
lapsed player dreads is the state they will find the pet in, so Plus answers
that: an hour of absence costs a quarter of an hour of decay, and one missed
day no longer resets the streak.

**It slows the slide, it does not stop it**, and the reason is as much
commercial as it is design. The obvious alternative was a *floor* — hold the
stats above the crisis thresholds, so a member's pet is never starving or sick.
That reads better on a table and is worse in every other way. A pet that cannot
get into trouble stops being a pet, and the care loop is the game. It also caps
how much food any absence can demand, and caps it low — food and medicine are
the catalogue's only recurring coin sink, and coins are what the packs above
sell, so a floor would quietly retire the sink for exactly the players most
willing to spend. A divisor caps nothing. It buys time, and a member who is
away long enough still comes home to a pet that needs feeding from the bottom.

So the row says **Decay / Decay slower**, in the same verb on both sides. A
cell reading "Looked after" would be selling an exemption that is not on offer.

`BOND.md` is untouched: closeness still only grows through the language, and
nothing here moves a stat upwards — decay is slower, never reversed, so what a
membership buys is time rather than care given on the player's behalf.

This row briefly had a second half: a membership forgave one missed day on the
daily-reward streak. It is gone, and not because it was cut from the tier — the
reward cycle no longer resets for anybody. Working out what a missed day costs
is what showed that the reset was doing real damage to the food economy for
free players (`DailyRewardProvider.checkDailyReward` has the arithmetic), and a
perk whose only value came from a punishment was a reason to look harder at the
punishment.

### What it must never sell

Each of these breaks something already reasoned out elsewhere in the codebase.

- **Coins, or a coin stipend.** `gold.dart` cut the daily login reward from 375
  coins a week to 45 plus food precisely to stop money that was not earned by
  learning from outweighing money that was. A membership drip rebuilds that
  hole with a subscription attached. Note this rule is about the *drip*, not
  about coins being purchasable at all — coin packs sell them outright, and the
  difference is that a pack is a thing a player decides to buy once rather than
  a tap that pays them for holding a subscription.
- **Bond stages, or the accessories gated on them.** The premise of the game is
  that closeness grows through the language — see `BOND.md`.
- **Cloud backup.** A free player losing their pet with their phone is a
  support problem and a review-score problem, for a rounding error in Firestore
  cost.
- **Rewarded ads.** `ads.dart` already works this out: removing them would
  leave a paying player with fewer coin sources than a free one.

### The wall never stops studying

`gold.dart` refused a hard cap on coins because "hitting a wall mid-session
tells the player to stop studying". That objection stands, and a quiz cap only
survives it because a quiz is a **cost**, not a reward — so the cap may stop the
app *generating* and must never stop the player working.

So when the quiz allowance is spent, `_generateWithAi` returns empty and the
locally-built SRS quiz stays on screen. `AiLimitSheet` then names what is still
open before it names the two ways to have more today:

1. the review queue (or, on the message wall, the local quiz) — free, unlimited,
   no model call;
2. a rewarded ad, worth one extra quiz;
3. Plus.

"Come back tomorrow" is never the whole message. The middle line of that sheet
is load-bearing and has its own test.

**One ad, both rewards.** `AdsProvider.watchRewarded` grants the coins *and* a
quiz. The scarce thing is the slot, not which screen the offer was taken from,
so a player out of quizzes never has to guess which button was the right one. A
full day of ads lands a free player at 8 quizzes — deliberately short of ten.

Charges land on a *result*, not an attempt. A failed call still cost the
provider, but taking the player's allowance for the app's bad day is how a cap
starts feeling arbitrary; the proxy's `SpendLedger` is what bounds the money.

### The client is not the enforcer

`UserProvider.isPremium` is a stored bool and `EntitlementConstants` is a
client-side copy. Both are **UX**: the meter, the wall, the upgrade prompt. A
rebuilt APK can set the flag and skip its own meter entirely.

What actually decides whether a model gets called is `server/src/quotas.js`,
metering per account against a verified Firebase ID token. Those numbers must
agree with `lib/constants/entitlements.dart`, or the app promises an allowance
the proxy refuses.

The bank is part of that contract, and it is the easy one to miss: a proxy
enforcing a flat ten a day will refuse the eleventh quiz of a day the client
has already promised. `AccountQuotas` therefore carries its own bank
(`QUIZ_BANK_CAP`), and the direction of the mismatch is what the rules are
shaped around — the server must stay the *more* generous of the two, or the app
promises quizzes the proxy refuses. Two known asymmetries, both that way round:
the server banks for days an account was away when it already holds a bank for
them (the client never does), and a restart drops every bank while also handing
back a whole fresh day.

The slower decay needs nothing there. It never reaches the server.

## Season pass

Cosmetics, bought once per season and worked through. **Not** a battle pass,
and the difference is the expiry.

A normal pass says finish inside the season or lose what you paid for. That is
a charge for being away, and `BOND.md` already settled this app's position on
charging for absence. So three rules replace the deadline:

- **Progress is measured from the purchase.** A tier is owed XP earned *since
  this pass was bought*, so buying on a season's last day is worth what buying
  on the first day was — and a long-time player with a large balance unlocks
  nothing on purchase.
- **Nothing expires.** A tier reached stays reached; a tier unreached stays
  reachable. Someone who lapses for a month returns to something waiting rather
  than something wasted.
- **A season governs what is on sale, never what is still claimable.**
  `seasonPasses` is append-only for exactly this reason.

Shape: bimonthly, 500 XP a rung. Season one is ten wearable tiers and a scene
at the end, 5,500 for the track ≈ a month of committed use, longer for
everyone else, with nothing lost. Every tier is a cosmetic today.

The scene is the one tier that touches another lane's category, and the rule
that keeps it honest is in `SEASON_PASS.md`: a pass may carry a world the
level ladder never awards and the shop never lists, and may never carry one of
the ladder's three. The lane protects the item, not the category.

The page no longer *says* so. It used to carry "Cosmetics only. No coins, no
food, no XP." under the progress bar for a player who did not own the pass,
which is a strange thing to lead with on the one line somebody reads before
deciding — it advertises absences. It is also a promise worth not making in
print while what a pass contains is still open.

There is **no free track**. Coins are already the free cosmetic route, earned by
learning, which keeps three legible lanes:

| Route | Earned by | Items |
|---|---|---|
| Coins | learning | most of the catalogue |
| Bond stage | the relationship | 4, never buyable |
| Season pass | purchase | seasonal, never otherwise obtainable |

Backgrounds appear in two of those rows and that is deliberate: `bg_blue`,
`bg_forest` and `bg_sunset` are level rewards *and* coin-priced, `bg_galaxy`
is coins only, and `bg_airfield` is pass only. No single world is in two.

Coin packs feed the first lane and only the first: they buy the currency, so
they reach exactly what coins already reached and nothing else. The bond lane
and the pass lane stay where they are.

`AccessoryDef` enforces this: `price`, `requiredStage` and `requiredPass` are
mutually exclusive by assert. `passLocked` is a distinct availability from
`bondLocked` on purpose — telling somebody to keep studying for a thing no
amount of studying will give them is the worst answer that enum could give.

### The art, and the recolour pipeline

This is the binding constraint, not the code. The whole catalogue is twenty
pieces; a 10-tier pass every two months is sixty a year.

Each **new shape** needs:

| File | Required | Why |
|---|---|---|
| `assets/svgs/acc_<id>.svg` | yes | Cat drawing, also the dog's and the fallback. Canvas viewBox `-20 -90 222 328`, drawn on the pet's 7-unit grid |
| `assets/svgs/acc_<id>_icon.svg` | yes | Wardrobe/shop tile, standalone |
| `assets/svgs/acc_<id>_bird.svg` | in practice | The chick is drawn in profile and is smaller than the cat's head; a scaled copy swallows it |

Plus a measured `_AccessoryPlacement(dx, dy)` for the dog in
`character_sprite.dart`, and an emoji for `AccessoryDef.icon`.

A **palette variant** needs **no new files at all**. It borrows the source's cat
art, bird cut, icon and dog placement, and swaps fills at render time:

```dart
AccessoryDef(
  id: 'tophat_crimson',
  name: 'Crimson Top Hat',
  slot: AccessorySlots.hat,
  asset: 'assets/svgs/acc_tophat.svg',
  icon: '🎩',
  requiredPass: 'season-1',
  recolor: AccessoryRecolor(
    sourceId: 'tophat',
    fills: {'#1a1a1a': '#c0392b'},
  ),
)
```

Fills are named explicitly rather than inferred — a hat with three fills where
only two should move is common, and guessing would silently mis-tint half a
track. The outline (`#1f2223`) cannot be recoloured: it is shared by every pet
and every accessory, and a variant that moved it would put a piece on the pet
drawn in different ink from the animal wearing it.

Substitution is a single pass, so a palette that shades one colour into another
piece's colour does not collapse into one tone.

So a 10-tier track is realistically **3 new shapes (9 files) + 7 variants (0
files)** rather than 20–30 files.

## Coin packs

Coins for money, on one doubling ladder. Each rung holds twice the coins of
the rung below and costs a little *less* than twice as much, so the rate
improves all the way up without any rung ever being a bad buy. Six rungs, $0.99
to $23.99, and the top one hands over a third more coins per dollar than the
smallest.

| | 100 | 200 | 400 | 800 | 1,600 | 3,200 |
|---|---|---|---|---|---|---|
| US list price | $0.99 | $1.89 | $3.59 | $6.79 | $12.79 | $23.99 |
| Bonus | — | +5% | +10% | +17% | +24% | +32% |

The bottom rung is the anchor for the whole catalogue: roughly a hundred coins
to the dollar, so a 250-coin hat reads as "about two and a half dollars, or an
evening's studying" from any rung. The discount is deliberately gentle — a top
rung paying double would make every row beneath it look like a mistake rather
than a choice, and the bottom rung has to stay an honest purchase.

The badge is **derived**, not declared: `bonusPercent` is computed from the
coins and the price in `lib/constants/coin_packs.dart`, so a badge can never
advertise a discount the price does not give. `coin_packs_test.dart` pins the
rest of the promise: the coins double, the price rises by less than the coins
do, no rung costs more without paying better, and every rung is priced on a
real price point rather than a round number.

**Two prices, and it matters which is which.** `ProductDetails.price` is what
the player is actually charged, in their currency under their region's tax
rules, and it is what the page shows the moment the store answers. `usdPrice`
is the list price — the figure a console listing should be set to — and it is
what the rows fall back to before the store is open, under a line saying the
counter is not open yet. Nothing ever assembles a price out of both. The
fallback exists because an empty price slot reads as a broken row: a player who
opens the counter early should still be able to see what the piles cost.

The page states none of this in prose. It is six rows, each showing the coins
it hands over beside its price, and a player who has got as far as opening it
does not need coins explained to them. The rate is legible from any row without
a sentence about it. The top rung is marked with a tilted red seal hung off its
top-right corner rather than by filling the row with the accent colour — a
filled row read as the *selected* one rather than the recommended one.

**Why the badge says bonus and not discount.** "+32%" is literally what the
pack contains: a third more coins for the same money as the base rung. Read as
a cut in the price *per coin* the same rung is 24% off — different arithmetic
on the same offer — and quoting the larger number against a price would be the
sort of maths that gets a listing pulled.

Three rules keep this from eating the economy:

- **Packs buy appearance, never care.** Food and medicine are the cheapest
  things on the shelves and the daily reward hands them out, so no pack is ever
  the difference between a looked-after pet and a neglected one.
- **Nothing here touches the bond.** XP, bond stages and the accessories gated
  on them stay earned through the language. A pack moves the wardrobe closer,
  not the relationship.
- **The taper is untouched.** `GoldLedger` measures its daily bands against
  *earned* coins only, so buying coins is not a way to raise the ceiling on
  what learning pays.

### The coin

`assets/svgs/coin.svg`, built by `art_src/gen_coin.py` — generated rather than
drawn, like the pets, because the shape is a rule and a rule stays symmetrical
where hand-placed rects drift. It uses the pets' own outline ink (`#1f2223`) on
a 24x24 cell grid so it belongs to the same art set, and four gold tones lit
from the upper left.

The face carries a struck ring. It got there by elimination: the obvious idea
was a paw print, which is what this game's currency *should* have on it, and at
this size it reads unmistakably as a **face** — the outer toes become eyes, the
inner ones a nose, the pad a mouth. Shaping the pad does not fix it; the
arrangement is the problem. The paw is kept in the generator behind
`MARK = 'paw'`, with that note, because someone will have the idea again.

The coin replaced the 🪙 emoji on the shop's price badges, which rendered as
whatever the device's font felt like and as nothing at all where the glyph is
missing. The reward dialogs and the level track still use the emoji.

### Consumables, which the other two products are not

A pack is the app's only consumable, and both halves of that word are load-
bearing:

- It is bought with `buyConsumable`, not `buyNonConsumable`. An unconsumed Play
  purchase means that account can never buy that pack again. `PurchaseService`
  picks the call from the catalogue rather than trusting the caller, because
  the failure is invisible until someone tries to buy their second pack.
- **A restore must not pay out again.** Plus and the pass are granted on
  `restored` as well as `purchased`; coins are granted only on `purchased`.
  Coins are spent the moment they arrive, so replaying them would mint a
  player's entire top-up history on every reinstall. Pinned by
  `purchase_service_coins_test.dart`.

Prices come from `ProductDetails.price` and nowhere else — the dollars in
`coin_packs.dart` define the ladder and say what a console listing should be
set to, not what anyone is charged. With no listings the page says coin packs
are not open yet rather than drawing a button that cannot charge, which is the
call the paywall and the pass screen already make.

## State

Everything below is **in the working tree, uncommitted** — roughly 180 files
across the bond merge, allowances, IAP, proxy quotas and the pass.

### Done

| | Where |
|---|---|
| Allowance constants + `AiUsageLedger` | `lib/constants/entitlements.dart` |
| Provider wiring, persistence, day rollover | `lib/providers/user_provider.dart` |
| Quiz + chat gates | `quiz_screen.dart`, `chat_screen.dart` |
| The wall | `lib/components/ai_limit_sheet.dart` |
| Live meter (quiz header) | `quiz_screen.dart` `_allowanceMeter` |
| Paywall | `lib/screens/premium_screen.dart`, route `/premium` |
| Profile entry point | `lib/components/premium_tile.dart` |
| Store plumbing | `lib/services/purchase_service.dart`, `lib/providers/premium_provider.dart` |
| Per-account proxy quotas | `server/src/quotas.js` |
| ID token verification | `server/src/identity.js` (no `firebase-admin`) |
| Client sends its token | `AiService._proxyHeaders`, `X-Id-Token` |
| Pass model + progress | `lib/constants/season_pass.dart`, `lib/utils/season_pass_progress.dart` |
| Pass ownership + claiming | `UserProvider.grantPass` / `claimPassTiers` |
| Shop slider, four sections | `lib/screens/shop_hub_screen.dart`, route `/shop` |
| Coin pack ladder | `lib/constants/coin_packs.dart` |
| Top-up section | `lib/screens/coin_shop_screen.dart` `CoinShopBody` |
| Consumable purchase + coin grant | `PurchaseService.onCoinsPurchased`, `PremiumProvider.buyCoinPack` |
| The coin itself | `art_src/gen_coin.py` → `assets/svgs/coin.svg` |
| Accessory recolour | `AccessoryRecolor`, `recolorAccessory`, `AccessoryIcon` |

1143 Flutter tests + 122 server tests passing; analyzer clean; all 26 locales
translated (`untranslated_messages.txt` is `{}`).

### Next, in order

1. **Store products.** Create the subscriptions in Play Console and App Store
   Connect, then build with
   `--dart-define=IAP_PLUS_MONTHLY=… --dart-define=IAP_PLUS_ANNUAL=…`.
   Until then `PremiumProvider.isAvailable` is false and the paywall says
   "Subscriptions are not open yet" rather than drawing a price it cannot
   charge. **Plus pricing is still undecided.**

   The five coin packs need listings too, as **consumables**, at the ids in
   `coin_packs.dart` (`com.mimikin.app.coins.pouch` … `.hoard`) and the dollar
   tiers beside them. No dart-define: a pack's id decides how many coins a
   purchase is worth, so it belongs in the catalogue rather than in a build
   flag a later deployment could repoint.
2. **`FIREBASE_PROJECT_ID` on the proxy**, or per-account quotas stay off. It
   warns at boot and is documented in `server/.env.example`.
3. **Server-side receipt validation.** The one genuinely unfinished link. Until
   it exists, `quotas.js` meters *everyone* at the free tier, so a subscriber
   gets the app's larger allowance but not the server's. Needs a trusted
   process that verifies a store receipt and writes a custom claim the proxy
   can read.
4. **Season one art** — 3 shapes, then a `SeasonPassDef` entry, a pass screen,
   and hooking the purchase to `grantPass`.

### Decisions still open

- Prices for monthly and annual.
- Which 3 shapes for season one. A shape recolours well when it has 2–3 flat
  fills and no colour doing identifying work — a crown that stops reading as
  gold is no longer a crown. Guess: 2 hats + 1 neck.
- Whether one tier should be a distinct shape rather than a variant, so a
  ten-tier track does not read as three hats in different colours.

## Testing it by hand

The walls otherwise take a real session to reach, which made the one screen
carrying the upgrade offer the most tedious thing in the app to look at:

```
flutter run --dart-define=AI_QUIZ_LIMIT=1 --dart-define=AI_MESSAGE_LIMIT=1
```

Debug-gated, `-1` means no override, so the test suite still exercises the
shipping numbers.

| Piece | Where in the app |
|---|---|
| Allowance meter | Quiz screen header |
| Plus entry point | Profile screen tile |
| Paywall | Profile tile, or either wall's button |
| Quiz wall | 4th AI quiz |
| Chat wall | 31st message |
| Per-account quotas | Proxy `/healthz`, `quotas` key |
| Season pass | **Nothing yet** — catalogue is empty pending art |
