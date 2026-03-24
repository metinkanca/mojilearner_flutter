# Scope B - Onboarding + Localization + Security Feature Set

This file list is clean for the feature commit and excludes mixed stability files that require hunk-level separation.

## B-only tracked files
- .gitignore
- README.md
- analysis_options.yaml
- lib/components/chat_header.dart
- lib/components/chat_sidebar.dart
- lib/components/message_bubble.dart
- lib/components/navigation_wrapper.dart
- lib/constants/translations.dart
- lib/main.dart
- lib/providers/chat_provider.dart
- lib/providers/language_provider.dart
- lib/providers/mistakes_provider.dart
- lib/router.dart
- lib/screens/chat_screen.dart
- lib/screens/design_moji_screen.dart
- lib/screens/mistakes_screen.dart
- lib/screens/onboarding/calibration_screen.dart
- lib/screens/onboarding/welcome_screen.dart
- lib/screens/profile_screen.dart
- lib/screens/quiz_screen.dart
- lib/screens/scenarios_screen.dart
- lib/screens/shop_screen.dart
- lib/utils/progression_utils.dart
- linux/flutter/generated_plugin_registrant.cc
- linux/flutter/generated_plugins.cmake
- macos/Flutter/GeneratedPluginRegistrant.swift
- pubspec.lock
- pubspec.yaml
- test/widget_test.dart (deleted)
- windows/flutter/generated_plugin_registrant.cc
- windows/flutter/generated_plugins.cmake

## B-only untracked files
- assets/fonts/
- assets/svgs/bird.svg
- assets/svgs/cat.svg
- assets/svgs/dog.svg
- l10n.yaml
- lib/components/character_sprite.dart
- lib/components/quiz_rewards_popup.dart
- lib/l10n/
- lib/screens/onboarding/adaptive_quiz_screen.dart
- lib/screens/onboarding/conversational_assessment_screen.dart
- lib/screens/onboarding/mock_conversational_assessment_screen.dart
- lib/screens/onboarding/native_language_screen.dart
- lib/screens/onboarding/pet_farewell_screen.dart
- lib/screens/onboarding/pet_greeting_screen.dart
- lib/screens/onboarding/quiz_intro_screen.dart
- lib/screens/onboarding/self_assessment_screen.dart
- lib/screens/onboarding/target_language_screen.dart
- lib/screens/onboarding/username_screen.dart
- lib/utils/fonts.dart
- lib/utils/input_sanitizer.dart
- lib/utils/offline_detector.dart
- lib/utils/output_validator.dart
- lib/utils/rate_limiter.dart
- lib/utils/secure_storage.dart
- lib/utils/security_logger.dart
- lib/utils/shop_item_localizer.dart
- test/TESTING_AGENT_INSTRUCTIONS.md
- tool/
- untranslated_messages.txt

## Explicitly excluded from B until split
- lib/providers/user_provider.dart
- lib/screens/home_screen.dart
- lib/components/daily_rewards_dialog.dart
- lib/constants/progression.dart
- lib/models/models.dart
- lib/providers/character_provider.dart

## B verification
- flutter analyze
- Onboarding happy path: native language -> username -> target language -> assessment -> quiz -> farewell.
- Offline path: mock conversational assessment and adaptive quiz fallback.
- Localization generation parity and runtime loading.
