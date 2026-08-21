import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'components/navigation_wrapper.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/design_moji_screen.dart';
import 'screens/wardrobe_screen.dart';
import 'screens/scenarios_screen.dart';
import 'screens/mistakes_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/onboarding/first_launch_screen.dart';
import 'screens/onboarding/calibration_screen.dart';
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
import 'screens/review_screen.dart';
import 'screens/splash_screen.dart';
import 'providers/calibration_provider.dart';
import 'providers/user_provider.dart';
import 'utils/level_validator.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

const String splashRoute = '/splash';
/// Where a player who has not finished onboarding belongs. Named for the
/// role, not the screen, so the opening can be reshaped without renaming it.
const String welcomeRoute = '/onboarding/start';

/// Decides where the user belongs given the loaded startup state. Extracted
/// so it can be unit-tested without building a widget tree.
///
/// [location] is the route being evaluated. Returns the route to redirect to,
/// or null to stay put.
String? resolveStartupRedirect({
  required String location,
  required bool isLoading,
  required bool hasCompletedOnboarding,
}) {
  final isSplash = location == splashRoute;

  // Hold on the splash screen until persisted state is known, so a returning
  // user never sees the onboarding flow flash past.
  if (isLoading) {
    return isSplash ? null : splashRoute;
  }

  // State is known — leave the splash screen.
  if (isSplash) {
    return hasCompletedOnboarding ? '/' : welcomeRoute;
  }

  final isOnboardingRoute = location.startsWith('/onboarding/');

  if (!hasCompletedOnboarding && !isOnboardingRoute) {
    return welcomeRoute;
  }
  if (hasCompletedOnboarding && isOnboardingRoute) {
    return '/';
  }
  return null;
}

/// Builds the app router.
///
/// [refreshListenable] must notify when startup state changes (i.e. when
/// UserProvider / CalibrationProvider finish loading), otherwise the redirect
/// below is evaluated only once — while both are still loading — and the user
/// is stranded on the splash screen.
GoRouter createRouter({required Listenable refreshListenable}) => GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: splashRoute,
  refreshListenable: refreshListenable,
  redirect: (context, state) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final calibrationProvider =
        Provider.of<CalibrationProvider>(context, listen: false);

    return resolveStartupRedirect(
      location: state.matchedLocation,
      isLoading: userProvider.isLoading || calibrationProvider.isLoading,
      hasCompletedOnboarding: userProvider.hasCompletedOnboarding ||
          calibrationProvider.hasAnyCalibratedLanguage,
    );
  },
  routes: [
    GoRoute(
      path: splashRoute,
      builder: (context, state) => const SplashScreen(),
    ),
    // New onboarding flow
    GoRoute(
      path: welcomeRoute,
      builder: (context, state) => const FirstLaunchScreen(),
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
        final aiLevel = LevelValidator.normalizeLevel(
          state.uri.queryParameters['aiLevel'],
        );
        return QuizIntroScreen(aiLevel: aiLevel);
      },
    ),
    GoRoute(
      path: '/onboarding/adaptive-quiz',
      builder: (context, state) {
        final aiLevel = LevelValidator.normalizeLevel(
          state.uri.queryParameters['aiLevel'],
        );
        return AdaptiveQuizScreen(aiLevel: aiLevel);
      },
    ),
    GoRoute(
      path: '/onboarding/pet-farewell',
      builder: (context, state) => const PetFarewellScreen(),
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
          path: '/review',
          name: 'review',
          builder: (context, state) => const ReviewScreen(),
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
              scenarioId: extra['scenarioId'],
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
      path: '/wardrobe', // Fullscreen modal flow
      name: 'wardrobe',
      builder: (context, state) => const WardrobeScreen(),
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
