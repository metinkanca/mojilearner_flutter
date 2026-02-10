import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'components/navigation_wrapper.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/design_moji_screen.dart';
import 'screens/scenarios_screen.dart';
import 'screens/mistakes_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/onboarding/language_selection_screen.dart';
import 'screens/onboarding/calibration_screen.dart';
import 'screens/onboarding/result_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/level_rewards_screen.dart';
import 'screens/quiz_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/language-selection',
      builder: (context, state) => const LanguageSelectionScreen(),
    ),
    // Calibration moved to ShellRoute to have Navigation Bar
    GoRoute(
      path: '/result',
      name: 'result',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ResultScreen(
          score: extra['score'] ?? 0,
          totalQuestions: extra['totalQuestions'] ?? 5,
          level: extra['level'] ?? 'A1',
        );
      },
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return NavigationWrapper(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/calibration', 
          builder: (context, state) => const CalibrationScreen(),
        ),
        GoRoute(
          path: '/quiz', 
          builder: (context, state) => const QuizScreen(),
        ),
        GoRoute(
          path: '/scenarios',
          name: 'scenarios',
          builder: (context, state) => const ScenariosScreen(),
        ),
        // We probably want chat to be full screen or wrapped? 
        // User said "keep the bottomnavbar throughout the pages". 
        // So we include it here.
        GoRoute(
          path: '/new-chat',
          name: 'new_chat',
          builder: (context, state) => const ChatScreen(),
        ),
         GoRoute(
          path: '/chat/:chatId',
          name: 'chat',
          builder: (context, state) {
            final chatId = state.pathParameters['chatId'];
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return ChatScreen(
              chatId: chatId,
              scenarioTitle: extra['scenario'],
            );
          },
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/shop',
          name: 'shop',
          builder: (context, state) => const ShopScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/design-moji', // Fullscreen modal flow
      name: 'design_moji',
      builder: (context, state) => const DesignMojiScreen(),
    ),
    GoRoute(
      path: '/mistakes',
      name: 'mistakes',
      builder: (context, state) => const MistakesScreen(),
    ),
    GoRoute(
      path: '/level-rewards',
      name: 'level_rewards', // Fullscreen modal flow or standard
      builder: (context, state) => const LevelRewardsScreen(),
    ),
  ],
);
