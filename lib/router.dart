import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import 'screens/onboarding/native_language_screen.dart';
import 'screens/onboarding/username_screen.dart';
import 'screens/onboarding/target_language_screen.dart';
import 'screens/onboarding/self_assessment_screen.dart';
import 'screens/onboarding/pet_greeting_screen.dart';
import 'screens/onboarding/conversational_assessment_screen.dart';
import 'screens/onboarding/mock_conversational_assessment_screen.dart';
import 'screens/onboarding/quiz_intro_screen.dart';
import 'screens/onboarding/adaptive_quiz_screen.dart';
import 'screens/onboarding/pet_farewell_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/level_rewards_screen.dart';
import 'screens/quiz_screen.dart';
import 'providers/user_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/onboarding/welcome',
  redirect: (context, state) {
    // Get user provider to check onboarding status
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // If still loading, don't redirect yet
    if (userProvider.isLoading) {
      return null;
    }
    
    final isOnboardingRoute = state.matchedLocation.startsWith('/onboarding/');
    final hasCompletedOnboarding =
      userProvider.hasCompletedOnboarding || userProvider.hasAnyCalibratedLanguage;
    
    // If user hasn't completed onboarding and not on an onboarding route, redirect to welcome
    if (!hasCompletedOnboarding && !isOnboardingRoute) {
      return '/onboarding/welcome';
    }
    
    // If user has completed onboarding and is on any onboarding route, redirect to home
    if (hasCompletedOnboarding && isOnboardingRoute) {
      return '/';
    }
    
    // No redirect needed
    return null;
  },
  routes: [
    // New onboarding flow
    GoRoute(
      path: '/onboarding/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/onboarding/native-language',
      builder: (context, state) => const NativeLanguageScreen(),
    ),
    GoRoute(
      path: '/onboarding/username',
      builder: (context, state) => const UsernameScreen(),
    ),
    GoRoute(
      path: '/onboarding/target-language',
      builder: (context, state) => const TargetLanguageScreen(),
    ),
    GoRoute(
      path: '/onboarding/self-assessment',
      builder: (context, state) => const SelfAssessmentScreen(),
    ),
    GoRoute(
      path: '/onboarding/pet-greeting',
      builder: (context, state) => const PetGreetingScreen(),
    ),
    GoRoute(
      path: '/onboarding/conversational-assessment',
      builder: (context, state) => const ConversationalAssessmentScreen(),
    ),
    GoRoute(
      path: '/onboarding/mock-conversational-assessment',
      builder: (context, state) => const MockConversationalAssessmentScreen(),
    ),
    GoRoute(
      path: '/onboarding/quiz-intro',
      builder: (context, state) {
        final aiLevel = state.uri.queryParameters['aiLevel'];
        return QuizIntroScreen(aiLevel: aiLevel);
      },
    ),
    GoRoute(
      path: '/onboarding/adaptive-quiz',
      builder: (context, state) {
        final aiLevel = state.uri.queryParameters['aiLevel'];
        return AdaptiveQuizScreen(aiLevel: aiLevel);
      },
    ),
    GoRoute(
      path: '/onboarding/pet-farewell',
      builder: (context, state) => const PetFarewellScreen(),
    ),
    // Old onboarding routes (keep for backward compatibility)
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/language-selection',
      builder: (context, state) => const LanguageSelectionScreen(),
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
