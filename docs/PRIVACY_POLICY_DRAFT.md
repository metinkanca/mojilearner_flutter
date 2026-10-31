# Mimikin privacy policy: DRAFT

**Status:** a starting point written from what the code does on 2026-10-31. It
is not legal advice. Fill in the `[BRACKETS]`, have someone qualified read it,
host it at a stable public address, and build the app with
`--dart-define=PRIVACY_POLICY_URL=<that address>` (the profile screen hides the
link until this is set). Play needs the same address in the store listing.

**Keep it true.** Every statement below is checked against the code listed in
"Where this came from" at the end. If a feature changes what is collected,
change this first.

---

# Privacy Policy

*Last updated: [DATE]*

Mimikin ("the app", "we") is a language-learning game where you look after a
pet and practise a language to help it grow. It is made by **[YOUR NAME OR
COMPANY, ADDRESS]**. For anything in this policy, write to **[CONTACT EMAIL]**.

## What we collect, and why

**What you give the app**

- **A display name and a birth year**, asked during setup. The name is shown in
  the app. The birth year is used only to decide how ads are served: players who
  are under 13, or who do not answer, get child-directed ads and limited
  features (see "Children").
- **What you type to the AI tutor and in quizzes**: chat messages, quiz
  answers, and the sentences you practise with. These are sent to our server so
  an AI model can reply. Before sending, the app hides things that look like
  phone numbers, email addresses, passwords or ID numbers. Please do not type
  personal details anyway.
- **Your progress**: your pet and what it wears, coins, level, streaks, the
  words and mistakes the app has noted for review, the languages you study, and
  your settings.
- **An email address or Google account**, only if you choose to sign in so your
  pet follows you to a new phone. You can use the app without one.

**What is created for you**

- **An anonymous account identifier.** The first time the app starts it signs
  you in anonymously. This is what lets your save be stored and restored
  without a login.

**What the stores and advertisers handle**

- **Purchases** (Mimikin Plus, coin packs, the season pass) are processed by
  Google Play. We do not see your card details. We ask Google Play whether a
  subscription is active, using a purchase token, to give you the paid
  allowance.
- **Ads.** The free version shows ads from Google AdMob. AdMob may use your
  device's advertising identifier. Where the law requires, the app asks for
  your consent first, and it never serves personalised ads to players under 13
  or who have not stated an age. Mimikin Plus removes the interruptions.

**What we do not collect**

We do not use analytics or crash-reporting services, we do not track your
location, we do not read your contacts, and we do not sell personal data.
[CHECK THIS LINE IS STILL TRUE BEFORE PUBLISHING; see LAUNCH.md section 2, where
analytics and crash reporting are an open decision.]

## Where it is stored

| Data | Where | Notes |
|---|---|---|
| Chat history | Your phone only, encrypted | Not uploaded to our cloud save. |
| Progress, settings, name, birth year, mistakes, review words, assessment answers | Your phone, and a copy in Google Firebase (Cloud Firestore) under your anonymous or signed-in account | The cloud copy is how a new phone gets your pet back. It is not encrypted by us beyond Google's own storage encryption. |
| Messages you send to the tutor | Our AI server, briefly, then the AI provider | See below. |

## The AI tutor

When you chat or take an AI quiz, your message and the recent conversation are
sent to our server, which forwards them to an AI model (Google Gemini, directly
or through the OpenRouter service) and returns the reply. Our server keeps the
conversation in memory only, so the model has context, and drops it after about
30 minutes of inactivity. Our server logs record that a request happened (which
screen, how long it took, what it cost) and **not what was said**.

The AI providers process what we send under their own terms and may keep it for
a limited time to run and secure their services. [VERIFY AND LINK THE CURRENT
TERMS: Google Gemini API, OpenRouter.] AI replies can be wrong; do not rely on
them for anything important.

## Children

Mimikin is for a general audience, including children. We ask for a birth year
rather than "are you over 13?". If you are under 13, or you do not answer:

- ads are child-directed and limited to a general rating, and are never
  personalised;
- [DECIDE AND STATE WHAT ELSE IS LIMITED: Plus, coin packs, AI chat. LAUNCH.md
  section 6 lists this as undecided.]

Parents or guardians can ask us to delete a child's data at any time using the
contact above.

## Your choices and rights

- **Delete everything, in the app.** Profile, then **Delete Account**. This
  deletes the saved copy in our cloud, your account, and everything on the
  phone, and cannot be undone.
- **Start over but keep your account**: Profile, then **Reset App**. This also
  removes the cloud copy.
- **Delete without the app**: write to **[CONTACT EMAIL]** from the address on
  your account and we will delete it within [30] days. [HOST THIS AS A WEB PAGE
  TOO: Play's Data Safety form asks for a web address for deletion requests.]
- **Ads**: you can reset or opt out of personalisation in your Android
  settings (Google, then Ads).
- **Access, correction, portability, objection, complaint**: if you live in the
  EU, UK or similar, you have these rights; write to us, and you may also
  complain to your local data-protection authority.

## How long we keep things

Your cloud save stays until you delete it or delete your account. Server
conversation memory lasts about 30 minutes. [STATE ANY BACKUPS OR LOG RETENTION
ONCE HOSTING IS CHOSEN.]

## Security

Traffic to our servers uses HTTPS. Chats on your phone are stored encrypted.
Access to the cloud save is limited by rules so that only your own account can
read or write it. No system is perfectly secure.

## Changes

If this policy changes in a way that matters, we will say so in the app. The
date at the top shows the latest version.

---

## Where this came from (delete before publishing)

| Statement | Code |
|---|---|
| Name and birth year asked at setup | `lib/screens/onboarding/username_screen.dart`, `lib/constants/ads.dart` (`audienceForBirthYear`) |
| Under-13 and unknown get child-directed ads | `lib/services/ads_service.dart` (`applyAudience`, `_requestConsentInfoUpdate`) |
| Hides personal details before sending | `lib/utils/pii_detector.dart`, used by the chat and assessment screens |
| Anonymous sign-in | `lib/services/firebase_sync_backend.dart` |
| What syncs; chats do not | `lib/services/local_snapshot.dart` (`_localOnlyPrefs`, `_syncedSecureKeys`) |
| Chats encrypted on the phone | `lib/utils/secure_storage.dart`, `lib/providers/chat_provider.dart` |
| Access limited to own document | `firestore.rules` |
| Server keeps chats in memory ~30 min; logs never content | `server/src/sessions.js`, `server/src/app.js` (`record`) |
| AI via Gemini or OpenRouter | `server/src/fallback.js`, `server/src/openrouter.js`, `server/src/gemini.js` |
| Play subscription check by token | `server/src/entitlements.js` |
| In-app deletion | `lib/components/account_data_controls.dart`, `lib/services/data_eraser.dart` |
