# Mojilearner Flutter

Mojilearner is a Flutter application designed to facilitate interactive learning experiences through chat and various engaging screens. This project aims to provide a user-friendly interface for language learning and character interactions.

## Project Structure

```
mojilearner_flutter
├── android
│   └── app
│       └── build.gradle
├── ios
│   └── Runner
│       └── Info.plist
├── lib
│   ├── components
│   │   ├── ascii_face.dart
│   │   ├── chat_header.dart
│   │   ├── chat_input.dart
│   │   ├── chat_sidebar.dart
│   │   ├── language_modal.dart
│   │   ├── message_bubble.dart
│   │   ├── modern_avatar.dart
│   │   ├── three_dots_loader.dart
│   │   └── typing_indicator.dart
│   ├── constants
│   │   ├── character_frames.dart
│   │   ├── faces.dart
│   │   ├── languages.dart
│   │   ├── shop.dart
│   │   ├── theme.dart
│   │   └── translations.dart
│   ├── context
│   │   ├── character_provider.dart
│   │   ├── language_provider.dart
│   │   ├── mistakes_provider.dart
│   │   ├── toast_provider.dart
│   │   └── user_provider.dart
│   ├── hooks
│   │   ├── use_audio_recorder.dart
│   │   └── use_chat_session.dart
│   ├── utils
│   │   └── utils.dart
│   ├── screens
│   │   ├── call_screen.dart
│   │   ├── chat_screen.dart
│   │   ├── design_moji_screen.dart
│   │   ├── home_screen.dart
│   │   ├── mistakes_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── quiz_screen.dart
│   │   ├── scenarios_screen.dart
│   │   ├── shop_screen.dart
│   │   └── onboarding
│   │       ├── calibration_screen.dart
│   │       ├── language_selection_screen.dart
│   │       ├── result_screen.dart
│   │       └── welcome_screen.dart
│   ├── types
│   │   ├── env.dart
│   │   └── index.dart
│   └── main.dart
├── assets
│   └── character
│       └── idle
├── test
│   └── widget_test.dart
├── .env
├── .gitignore
├── analysis_options.yaml
├── pubspec.yaml
└── README.md
```

## Getting Started

To get started with the Mojilearner Flutter project, follow these steps:

1. **Clone the repository**:
   ```
   git clone <repository-url>
   ```

2. **Navigate to the project directory**:
   ```
   cd mojilearner_flutter
   ```

3. **Install dependencies**:
   ```
   flutter pub get
   ```

4. **Run the application**:
   ```
   flutter run
   ```

## Features

- Interactive chat interface for language learning.
- Various screens for onboarding, quizzes, and user profiles.
- Custom hooks for managing audio recording and chat sessions.
- Context providers for managing application state.

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue for any suggestions or improvements.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.