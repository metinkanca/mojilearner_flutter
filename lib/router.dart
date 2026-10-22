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
import 'screens/shop_hub_screen.dart';
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
import 'screens/onboarding/pet_tutorial_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/level_rewards_screen.dart';
import 'screens/premium_screen.dart';
import 'screens/season_pass_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/review_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/boss_climb_screen.dart';
import 'screens/boss_trial_screen.dart';
import 'screens/play_catch_screen.dart';
import 'screens/play/bubble_bath_screen.dart';
import 'screens/play/fetch_words_screen.dart';
import 'screens/play/pond_hop_screen.dart';
import 'screens/play/pounce_screen.dart';
import 'components/boss_trial/trial_boss.dart';
import 'providers/calibration_provider.dart';
import 'providers/user_provider.dart';
import 'utils/boss_trial.dart';
import 'utils/intro_handoff.dart';
import 'utils/level_validator.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

const String splashRoute = '/splash';
/// Where a player who has not finished onboarding belongs. Named for the
/// role, not the screen, so the opening can be reshaped without renaming it.
const String welcomeRoute = '/onboarding/start';

/// Where onboarding ends: meeting the pet, and learning the one gesture the
/// game runs on.
const String petTutorialRoute = '/onboarding/pet-tutorial';

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

/// The fight that `/boss-trial/fight/:boss/:step` names: the boss by its id,
/// and which of its levels (its openings one each, then its finale), with no
/// pickers, since the climb map has chosen both. An unknown boss falls back to
/// the first, and a step outside the boss's levels to the nearest.
BossTrialScreen bossFightFor(Map<String, String> pathParameters) {
  final boss = TrialBosses.all.firstWhere(
    (b) => b.id == pathParameters['boss'],
    orElse: () => TrialBosses.mossback,
  );
  final step = (int.tryParse(pathParameters['step'] ?? '') ?? 0)
      .clamp(0, BossTrialRules.levelsPerBoss - 1);
  return BossTrialScreen(boss: boss, step: step, picker: false);
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
    // The last step, and the only one that marks onboarding complete: the
    // redirect above sends a finished player away from every /onboarding/
    // route, so whichever screen sets the flag has to be the final one.
    GoRoute(
      path: petTutorialRoute,
      // No transition, and the shell below has none either. This screen
      // hands the home screen the pet's exact pose and the home screen picks
      // it up there, so the two frames either side of this navigation are
      // the same picture -- and any transition at all would be a slide or a
      // fade playing over a pet that is already in the right place.
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: PetTutorialScreen()),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      // A page rather than a bare builder, so the shell's own arrival on the
      // root navigator can be silenced. Only routes outside the shell reach
      // this -- the splash screen and the opening -- and neither wants the
      // app to slide in over itself.
      pageBuilder: (context, state, child) =>
          NoTransitionPage(child: NavigationWrapper(child: child)),
      routes: [
        GoRoute(
          path: '/',
          // Claims the pet's parting pose when the player has just come off
          // the meet-your-pet screen, and gets null every other time. See
          // [IntroHandoff] for why it is claimed here rather than passed.
          builder: (context, state) =>
              HomeScreen(introHandoff: IntroHandoff.claim()),
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
          path: '/premium',
          name: 'premium',
          builder: (context, state) => const PremiumScreen(),
        ),
        GoRoute(
          path: '/pass',
          name: 'pass',
          builder: (context, state) =>
              SeasonPassScreen(passId: state.uri.queryParameters['id']),
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
        // One route for the whole shop. Its four sections are tabs inside the
        // screen rather than routes of their own, so the strip stays put and
        // the bottom bar never goes away — see [ShopHubScreen].
        GoRoute(
          path: '/shop',
          name: 'shop',
          builder: (context, state) => const ShopHubScreen(),
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
    // Outside the shell: a fight takes the whole screen, and a bottom bar
    // under four falling tiles is one more thing to tap by accident. The page
    // is the climb through the six bosses' floors, and a stop on it is a
    // fight, pushed over it so that leaving one comes back to the climb.
    GoRoute(
      path: '/boss-trial',
      name: 'boss_trial',
      builder: (context, state) => const BossClimbScreen(),
      routes: [
        GoRoute(
          path: 'fight/:boss/:step',
          name: 'boss_fight',
          builder: (context, state) => bossFightFor(state.pathParameters),
        ),
      ],
    ),
    // Outside the shell for the same reason as the trial: blocks fall to the
    // bottom of the screen, where the bar would be.
    GoRoute(
      path: '/play-catch',
      name: 'play_catch',
      builder: (context, state) => const PlayCatchScreen(),
    ),
    // The rest of the toy chest, outside the shell for the same reason:
    // every one of them puts what to tap at the bottom of the screen.
    GoRoute(
      path: '/play-bubble-bath',
      name: 'play_bubble_bath',
      builder: (context, state) => const BubbleBathScreen(),
    ),
    GoRoute(
      path: '/play-pounce',
      name: 'play_pounce',
      builder: (context, state) => const PounceScreen(),
    ),
    GoRoute(
      path: '/play-pond-hop',
      name: 'play_pond_hop',
      builder: (context, state) => const PondHopScreen(),
    ),
    GoRoute(
      path: '/play-fetch-words',
      name: 'play_fetch_words',
      builder: (context, state) => const FetchWordsScreen(),
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
