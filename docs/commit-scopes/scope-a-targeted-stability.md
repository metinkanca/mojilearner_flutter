# Scope A - Targeted Stability (Hunk Split Required)

Current state: no fully clean A-only files were found. The stability fixes are embedded in mixed files that also include onboarding/calibration/security feature work.

## Goal
Extract ONLY test-fix/stability hunks (daily reward/home flow correctness) into Scope A.

## Mixed files to split
- lib/providers/user_provider.dart
  - Keep for A: daily reward state/check/claim and pending reward handling.
  - Exclude to B: onboarding completion, language calibration persistence, secure storage migration.
- lib/screens/home_screen.dart
  - Keep for A: reward resolution and one-time daily reward dialog trigger.
  - Exclude to B: broader UI/layout rewrites and localization modernization not required for reward stability.
- lib/components/daily_rewards_dialog.dart
  - Keep for A: dialog behavior and claim flow display logic.
  - Exclude to B: localization/shop-item integration if not needed for immediate stability fix.
- lib/constants/progression.dart
  - Keep for A: reward cycle constants needed by daily reward logic.
  - Exclude to B: any onboarding/quiz reward tier additions.
- lib/models/models.dart
  - Keep for A: DailyRewardInfo/RewardDef model compatibility only.
  - Exclude to B: language assessment/onboarding models.
- lib/providers/character_provider.dart
  - Keep for A: reward application behavior required by daily reward flow.
  - Exclude to B: quiz/outcome tier logic.

## Recommended extraction flow
1. Stage B-only files first (see scope-b-feature-manifest.md).
2. Use patch-mode staging to selectively stage A hunks from mixed files.
3. Validate A with targeted tests and analyzer before commit.

## A verification
- Run targeted tests touching daily reward and home flow behavior.
- Run analyzer to ensure no dependency break from partial staging.
- Confirm home screen shows reward dialog once per eligible login.
