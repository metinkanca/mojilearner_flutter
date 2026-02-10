import 'package:flutter/material.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MojiLearner',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primary,
          background: AppTheme.background,
        ),
        textTheme: GoogleFonts.interTextTheme(),
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
