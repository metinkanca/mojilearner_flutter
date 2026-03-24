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

- **AI-Powered Calibration**: Intelligent level assessment using Gemini 2.5 Flash
- **Offline Mode**: Complete functionality with mock AI for testing
- **8-Step Onboarding**: Comprehensive first-time user experience
- **Multi-Language Support**: 24 languages for learning
- **Interactive Chat**: Conversational language practice
- **Adaptive Quizzes**: Difficulty adjusts to your level
- **Retro Pixel UI**: Fun, nostalgic design aesthetic
- **Pet Companion**: Friendly mascot guides your journey

## Building for Distribution

### Android APK

```bash
# Setup offline mode
cp .env.offline .env

# Build release APK
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

**Full Guide:** See [QUICK_BUILD.md](QUICK_BUILD.md)

### iOS (Requires Mac + Xcode)

```bash
# Setup offline mode
cp .env.offline .env

# Build for iOS
flutter build ios --release
open ios/Runner.xcworkspace
```

**Full Guide:** See [IOS_BUILD_GUIDE.md](IOS_BUILD_GUIDE.md)

## Documentation

**For Developers:**
- [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md) - Complete build process for Android & iOS
- [IOS_BUILD_GUIDE.md](IOS_BUILD_GUIDE.md) - Detailed iOS/Mac instructions with TestFlight setup
- [QUICK_BUILD.md](QUICK_BUILD.md) - Quick reference commands
- [OFFLINE_MODE.md](OFFLINE_MODE.md) - How offline mode works and how to extend it

**For Testers:**
- [TESTER_GUIDE.md](TESTER_GUIDE.md) - Comprehensive testing checklist
- [INSTALL_GUIDE.md](INSTALL_GUIDE.md) - Simple installation instructions for Android & iOS

## Offline Mode

The app supports full offline functionality for testing without API costs:

1. **Copy offline config:** `cp .env.offline .env`
2. **Build the app** (Android or iOS)
3. **Share with testers** - app works completely offline

All AI features use pre-written mock responses. Perfect for beta testing!

**Learn more:** [OFFLINE_MODE.md](OFFLINE_MODE.md)

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue for any suggestions or improvements.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.