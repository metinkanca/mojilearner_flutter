import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/character_provider.dart';
import 'providers/language_provider.dart';
import 'providers/user_provider.dart';
import 'providers/chat_provider.dart';
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
      ChangeNotifierProvider(create: (_) => CharacterProvider()),
      ChangeNotifierProvider(create: (_) => ChatProvider()),
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
