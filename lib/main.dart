import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/character_provider.dart';
import 'providers/language_provider.dart';
import 'providers/user_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/mistakes_provider.dart';
import 'providers/settings_provider.dart';
import 'router.dart';
import 'constants/theme.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set fullscreen mode - hide system navigation bar
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [],
  );
  
  // Configure Google Fonts to use local fonts (no internet required)
  GoogleFonts.config.allowRuntimeFetching = false;
  
  // Ensure .env exists or handle the error gracefully
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // ignore: avoid_print
    print(".env file not found, using defaults");
  }
  
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => UserProvider()),
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ChangeNotifierProxyProvider<UserProvider, CharacterProvider>(
        create: (context) {
          final characterProvider = CharacterProvider();
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          characterProvider.subscribeToRewards(userProvider);
          return characterProvider;
        },
        update: (context, userProvider, characterProvider) {
          characterProvider?.subscribeToRewards(userProvider);
          return characterProvider ?? CharacterProvider();
        },
      ),
      ChangeNotifierProvider(create: (_) => ChatProvider()),
      ChangeNotifierProvider(create: (_) => QuizProvider()),
      ChangeNotifierProvider(create: (_) => MistakesProvider()),
      ChangeNotifierProvider(create: (_) => SettingsProvider()),
    ],
    child: const MojiLearnerApp(),
  ));
}

class MojiLearnerApp extends StatelessWidget {
  const MojiLearnerApp({super.key});

  // Strip underline decoration from every text style in the theme
  static TextStyle _noUnderline(TextStyle? style) =>
      (style ?? const TextStyle()).copyWith(decoration: TextDecoration.none);

  static ThemeData _buildTheme() {
    final base = GoogleFonts.interTextTheme();
    final clean = base.copyWith(
      displayLarge:  _noUnderline(base.displayLarge),
      displayMedium: _noUnderline(base.displayMedium),
      displaySmall:  _noUnderline(base.displaySmall),
      headlineLarge: _noUnderline(base.headlineLarge),
      headlineMedium:_noUnderline(base.headlineMedium),
      headlineSmall: _noUnderline(base.headlineSmall),
      titleLarge:    _noUnderline(base.titleLarge),
      titleMedium:   _noUnderline(base.titleMedium),
      titleSmall:    _noUnderline(base.titleSmall),
      bodyLarge:     _noUnderline(base.bodyLarge),
      bodyMedium:    _noUnderline(base.bodyMedium),
      bodySmall:     _noUnderline(base.bodySmall),
      labelLarge:    _noUnderline(base.labelLarge),
      labelMedium:   _noUnderline(base.labelMedium),
      labelSmall:    _noUnderline(base.labelSmall),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTheme.primary,
        // ignore: deprecated_member_use
        background: AppTheme.background,
      ),
      textTheme: clean,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp.router(
          title: 'MojiLearner',
          theme: _buildTheme(),
          routerConfig: router,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale(languageProvider.nativeLanguage.code),
        );
      },
    );
  }
}
