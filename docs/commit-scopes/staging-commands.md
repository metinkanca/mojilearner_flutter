# Suggested Staging Commands

Run from repo root.

## 1) Stage clean Scope B set
Use explicit add and then unstage mixed files if they were accidentally included.

```powershell
git add .
git restore --staged lib/providers/user_provider.dart
git restore --staged lib/screens/home_screen.dart
git restore --staged lib/components/daily_rewards_dialog.dart
git restore --staged lib/constants/progression.dart
git restore --staged lib/models/models.dart
git restore --staged lib/providers/character_provider.dart
```

## 2) Commit Scope B
```powershell
git commit -m "feat: onboarding flow, localization expansion, and security hardening"
```

## 3) Build Scope A from mixed files
Use patch staging per file and include only stability hunks.

```powershell
git add -p lib/providers/user_provider.dart
git add -p lib/screens/home_screen.dart
git add -p lib/components/daily_rewards_dialog.dart
git add -p lib/constants/progression.dart
git add -p lib/models/models.dart
git add -p lib/providers/character_provider.dart
```

## 4) Commit Scope A
```powershell
git commit -m "fix: stabilize daily reward and home reward flow"
```

## 5) Validation checkpoints
```powershell
flutter analyze
flutter test
```

If test runtime is long, run a targeted subset for reward/home/provider behavior before full suite.
