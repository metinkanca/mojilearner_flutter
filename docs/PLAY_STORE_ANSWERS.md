# Play Console answers: draft cheat sheet

Written 2026-10-31 from the code, so the form can be filled in without
re-reading it. **Answers are what the app does today**; re-check against the
code if features change. Items marked **DECIDE** are open questions only the
owner can settle. Google can change the form's wording; match intent, not
labels.

Related: `docs/PRIVACY_POLICY_DRAFT.md`, `LAUNCH.md` sections 1b and 6, `ADS.md`.

## Data safety

**Does the app collect or share required user data types?** Yes.

**Is all data encrypted in transit?** Yes (HTTPS to the AI proxy, Firebase and
AdMob).

**Do you provide a way for users to request data deletion?** Yes.
- In the app: Profile, then Delete Account (also deletes the cloud copy and the
  sign-in account).
- Web address required for requests outside the app: **[OWNER: host a page, e.g.
  the deletion section of the privacy policy, and paste the URL]**.

### Data types

| Data type | Collected | Shared | Purpose | Optional? |
|---|---|---|---|---|
| **Personal info: Name** (display name) | Yes | No | App functionality | Required for the pet to greet you; any nickname works |
| **Personal info: Email address** | Yes, only if the player signs in with email/Google | No | Account management | Optional |
| **Personal info: User IDs** (anonymous Firebase uid) | Yes | No | App functionality, account management | Required |
| **Personal info: Other** (birth year) | Yes | No | App functionality (age-appropriate ads) | Asked; unanswered is treated as under 13 |
| **App activity: Other user-generated content** (chat messages, quiz answers sent to the AI) | Yes | **Yes, with the AI providers acting as service providers** (Google Gemini / OpenRouter) | App functionality | Required for the AI features |
| **App activity: In-app interactions / other actions** (progress, coins, streaks, mistakes, review words) | Yes | No | App functionality | Required |
| **Device or other IDs** (Advertising ID) | Yes, by AdMob | **Yes, with Google AdMob** | Advertising | Free version; not personalised for under-13 / unknown age |
| **Financial info: Purchase history** | Not by the app: Google Play handles payment. The server checks a purchase token with Google to grant Plus. | No | App functionality | n/a. **DECIDE** whether Play counts the token check as collecting "purchase history"; the conservative answer is yes, not shared |
| **App info and performance: Crash logs / Diagnostics** | **No** today | | | Becomes **Yes** the day Crashlytics or Analytics is added (LAUNCH.md section 2) |
| **Location, contacts, photos, audio, files, health** | No | | | |

Notes for the shared column: "shared" in Play's sense excludes service providers
processing on your behalf under your instructions; the AI providers are in that
bucket, AdMob (advertising) is not, so declare it.

### Security practices

- Data encrypted in transit: **Yes**.
- You can request data deletion: **Yes**.
- Independent security review: **No**.
- Follows Families Policy: see below, **DECIDE**.

## Target audience and content

The pet game appeals to children, which Play treats as a deliberate decision:

- **DECIDE: target age groups.** If any group under 13 is selected, the app
  falls under the Families Policy: only certified ad SDKs, no personalised ads,
  and restrictions on AI chat and purchases. The code already treats under-13 and
  unknown-age players as child-directed for ads. What else they may see (Plus,
  coin packs, AI chat, rewarded ads) is not yet decided; `LAUNCH.md` section 6.
  Choosing "13+ / general audience only" is simpler, but then the app must not be
  designed to attract children, and the pet-game look may still be judged as
  appealing to them.
- **Ads**: answer **Yes, contains ads**.
- **In-app purchases**: **Yes** (Plus subscription, coin packs, season pass).

## Content rating (IARC questionnaire)

Answers from the app's behaviour (re-answer honestly if content changes):

- Violence: cartoon creature combat in boss trials, no blood. Answer for
  **mild fantasy violence** if asked about fantasy or cartoon violence.
- Sexual content, profanity, drugs, gambling: none in authored content.
  **However** the AI tutor generates free text. Answer the "user-generated or
  AI-generated content" question **Yes** and state that outputs are filtered by
  system prompts but can't be guaranteed.
- Users interact or exchange content with other users: **No** (AI only, no
  player-to-player chat).
- Shares location: **No**.
- Digital purchases: **Yes**.

## AI-generated content policy

Play expects apps with generative AI to let users report offensive output.
**Not built yet.** What exists: the system prompts (server-side, in
`server/src/prompts.js`), input redaction, and a rate/budget limiter. What is
missing: an in-app way to flag a reply. Add one before launch; it is a small
change on the chat screen and the Play review checks for it.

## Account deletion (Play policy)

Required for apps that let users create an account. The app creates anonymous
accounts automatically and offers email/Google linking, so assume it applies.
Done in-app (Delete Account). The web link for the Data Safety form is the open
part (above).

## Permissions to justify

| Permission | Reason |
|---|---|
| `POST_NOTIFICATIONS` | Pet-care, review and daily-reward reminders (local, scheduled on the device) |
| `RECEIVE_BOOT_COMPLETED` | Re-schedules those reminders after a reboot |
| `com.google.android.gms.permission.AD_ID` | AdMob advertising ID; not used for under-13 / unknown-age players |
| Internet (implicit) | AI proxy, Firebase, AdMob, store |

## Store listing facts to keep consistent

- Package: `com.mimikin.app` (permanent once uploaded).
- Subscription ids must match the build flags `IAP_PLUS_MONTHLY` and
  `IAP_PLUS_ANNUAL`, and the proxy's `PLUS_PRODUCT_IDS`.
- Support email and privacy policy URL must match the policy text.
