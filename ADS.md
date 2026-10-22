# Ads & membership

Two ad formats, governed by different rules. The membership that suppresses
one of them is Mimikin Plus — see `MONETISATION.md` for what it sells and what
it deliberately does not.

| | Rewarded video | Interstitial |
|---|---|---|
| Trigger | Player taps an offer | Automatic, after a finished quiz or scenario |
| Pays | 5 / 8 / 10 / 12 / 15 coins, in that order | Nothing |
| Limit | 5 a day | One an hour |
| Removed by membership | **No** | **Yes** |
| Where | The shop's item shelves (`/shop/items`); wardrobe's "not enough coins" dialog | End of a quiz or a scenario run |

Membership deliberately does *not* remove rewarded ads. Taking them away
would remove a coin source and leave a paying player worse off than a free
one, which is not a thing worth selling. What it sells is the absence of
interruption.

## The rule that holds the economy together

`lib/constants/gold.dart` is built on coins coming from doing the content.
Ads are the one income source that is not, so two things keep them honest:

1. **Ad coins never touch the learning ledger.** They are paid with
   `UserProvider.addCoins`, never `awardLearningGold`. Routing them through
   the ledger would advance the daily taper, so watching an ad would quietly
   *reduce* what the next quiz paid.
2. **The offer only appears once the player has learned something today.**
   `AdsProvider.canOfferRewarded` checks the day's learning ledger before
   anything is shown.

The second one is load-bearing, and the numbers are why. Ungated, five ads a
day pay 50 coins against the 20 a casual player earns from a real session,
and a player who never opened a quiz could buy the entire purchasable
catalogue in about four months instead of five years — faster than a casual
learner who watched no ads at all. `test/unit/economy_curve_test.dart` walks
the whole curve and fails if that ever comes back.

## Where the code lives

| Layer | File | Holds |
|---|---|---|
| Policy (pure) | `lib/constants/ads.dart` | The ladder, the daily limit, the cooldown, the age rule. No Flutter, fully unit-tested. |
| Platform | `lib/services/ads_service.dart` | Talks to AdMob and nothing else. No rules. Swallows every platform error. |
| State | `lib/providers/ads_provider.dart` | Joins the two to the app: membership, coins, persistence. |
| Storage | `lib/repositories/ads_repository.dart` | The ledger and the stated birth year. |
| UI | `lib/components/free_coins_tile.dart` | The shop offer, and the shared watch-and-report flow. |

`AdsService` is reached through the static `AdsService.I`, and tests replace
it with `AdsService.debugOverride` — see `test/helpers/fake_ads.dart`. Nothing
under test ever touches the real plugin.

## Audience and consent

The app is mixed-audience, so onboarding asks for a birth year on the
username screen. It is neutral by design: a year, not "are you over 13?",
which signals the answer that unlocks more and is not an age screen Play's
Families policy accepts.

Under 13, and *until the question is answered*, every request carries
`AgeRestrictedTreatment.child` and `MaxAdContentRating.g`. Unknown is treated
exactly as child: wrongly restricting an adult costs a little revenue, and
the opposite mistake is a COPPA problem.

UMP consent runs before the SDK initialises, from the home screen rather than
`main` — the consent form is a native dialog that needs an activity to appear
over, and the home screen is only reachable after onboarding, so it can never
land on top of the opening.

## Before release

Everything below currently points at Google's public **test** inventory. That
is deliberate: a debug build serving live ads means developers generating
impressions and clicks on their own inventory, which is what gets an AdMob
account terminated. A release build on test units earns nothing at all, and
the symptom — ads that show perfectly well — looks like success, so this list
matters.

- [ ] Create the app in the AdMob console; create one rewarded and one
      interstitial unit per platform.
- [ ] Pass the real unit ids at build time:
      ```
      flutter build appbundle \
        --dart-define=ADMOB_REWARDED_ANDROID=ca-app-pub-XXX/YYY \
        --dart-define=ADMOB_INTERSTITIAL_ANDROID=ca-app-pub-XXX/ZZZ \
        --dart-define=ADMOB_REWARDED_IOS=... \
        --dart-define=ADMOB_INTERSTITIAL_IOS=...
      ```
      Defaults live in `lib/constants/app_runtime_config.dart`.
- [ ] Replace the AdMob **app** id in `android/app/src/main/AndroidManifest.xml`
      and `GADApplicationIdentifier` in `ios/Runner/Info.plist`. These cannot
      come from `--dart-define`: the SDK reads them at process start, before
      any Dart runs.
- [ ] Paste the full `SKAdNetworkItems` list from Google's iOS quick-start
      into `Info.plist`. Only Google's own identifier is listed today.
- [ ] Play Console: declare "contains ads", complete the Data Safety form,
      set the content rating.
- [ ] App Store Connect: privacy nutrition labels for ad data, age rating.

### Known gap: iOS App Tracking Transparency

`NSUserTrackingUsageDescription` is in `Info.plist`, but nothing requests the
ATT prompt yet — `google_mobile_ads` does not provide one, so it needs the
`app_tracking_transparency` package and a call before
`AdsService.initialize`. Without it iOS ads still serve, but always
non-personalised, which earns less. Not wired up because it cannot be
verified without a Mac build.

## Membership

`UserProvider.isPremium` is written by `PremiumProvider` from the store's own
purchase stream (`lib/services/purchase_service.dart`). It suppresses
interstitials and raises the daily AI allowance, and deliberately does nothing
to the rewarded path.

Store products are not configured yet, so on a build without
`--dart-define=IAP_PLUS_MONTHLY=…` the paywall says so rather than drawing a
price it cannot charge. To check the paid behaviour before then, call
`setPremium(true)` from a debug build — interstitials should stop, and the
rewarded offer should not.

## Rewarded ads now pay twice

`watchRewarded` grants the coins *and* one extra AI quiz
(`EntitlementConstants.quizzesPerRewardedAd`). That is the free player's route
past the daily allowance wall, and it is granted wherever the ad was watched:
the scarce thing is the slot, not the screen. A full day of ads lands a free
player at 8 quizzes, deliberately short of a member's ten. See
`MONETISATION.md`.
