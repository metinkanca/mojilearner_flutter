import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mojilearner_flutter/models/models.dart';
import 'package:mojilearner_flutter/providers/calibration_provider.dart';
import 'package:mojilearner_flutter/providers/user_provider.dart';
import 'package:mojilearner_flutter/repositories/calibration_repository.dart';
import 'package:mojilearner_flutter/router.dart';
import 'package:mojilearner_flutter/utils/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Delays loading so startup state is genuinely still pending on the first
/// frame — with mocked SharedPreferences the real repository resolves within
/// it, which would skip the re-evaluation path this test exists to cover.
class _SlowCalibrationRepository extends CalibrationRepository {
  @override
  Future<Map<String, LanguageProficiency>> loadAll() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return {};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('resolveStartupRedirect', () {
    test('holds on splash while startup state is loading', () {
      expect(
        resolveStartupRedirect(
          location: splashRoute,
          isLoading: true,
          hasCompletedOnboarding: false,
        ),
        isNull,
      );
    });

    test('sends any other route back to splash while loading', () {
      expect(
        resolveStartupRedirect(
          location: '/',
          isLoading: true,
          hasCompletedOnboarding: true,
        ),
        equals(splashRoute),
      );
    });

    test('leaves splash for home when onboarding is complete', () {
      expect(
        resolveStartupRedirect(
          location: splashRoute,
          isLoading: false,
          hasCompletedOnboarding: true,
        ),
        equals('/'),
      );
    });

    test('leaves splash for onboarding when not complete', () {
      expect(
        resolveStartupRedirect(
          location: splashRoute,
          isLoading: false,
          hasCompletedOnboarding: false,
        ),
        equals(welcomeRoute),
      );
    });

    test('keeps an un-onboarded user inside the onboarding flow', () {
      expect(
        resolveStartupRedirect(
          location: '/onboarding/username',
          isLoading: false,
          hasCompletedOnboarding: false,
        ),
        isNull,
      );
      expect(
        resolveStartupRedirect(
          location: '/shop',
          isLoading: false,
          hasCompletedOnboarding: false,
        ),
        equals(welcomeRoute),
      );
    });

    test('pushes a completed user out of the onboarding flow', () {
      expect(
        resolveStartupRedirect(
          location: '/onboarding/welcome',
          isLoading: false,
          hasCompletedOnboarding: true,
        ),
        equals('/'),
      );
    });

    test('leaves normal routes alone for a completed user', () {
      expect(
        resolveStartupRedirect(
          location: '/shop',
          isLoading: false,
          hasCompletedOnboarding: true,
        ),
        isNull,
      );
    });
  });

  // Verifies the startup wiring against real providers: that the redirect is
  // re-evaluated once they finish reading storage. Destination screens are
  // stubbed — the real ones need the full provider tree and animate forever,
  // which is orthogonal to the routing decision under test.
  group('router refresh wiring', () {
    Future<String> startupDestination(
      WidgetTester tester, {
      required Map<String, Object> prefs,
    }) async {
      SharedPreferences.setMockInitialValues(prefs);
      late GoRouter router;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => UserProvider()),
            ChangeNotifierProvider(
              create: (_) => CalibrationProvider(
                repository: _SlowCalibrationRepository(),
              ),
            ),
          ],
          child: Builder(
            builder: (context) {
              final userProvider =
                  Provider.of<UserProvider>(context, listen: false);
              final calibrationProvider =
                  Provider.of<CalibrationProvider>(context, listen: false);

              router = GoRouter(
                initialLocation: splashRoute,
                // The wiring under test.
                refreshListenable:
                    Listenable.merge([userProvider, calibrationProvider]),
                redirect: (context, state) => resolveStartupRedirect(
                  location: state.matchedLocation,
                  isLoading:
                      userProvider.isLoading || calibrationProvider.isLoading,
                  hasCompletedOnboarding:
                      userProvider.hasCompletedOnboarding ||
                          calibrationProvider.hasAnyCalibratedLanguage,
                ),
                routes: [
                  for (final path in [splashRoute, '/', welcomeRoute])
                    GoRoute(
                      path: path,
                      builder: (c, s) => const SizedBox.shrink(),
                    ),
                ],
              );
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );

      // First frame: providers are still loading, so we sit on splash.
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        equals(splashRoute),
        reason: 'should hold on splash while startup state loads',
      );

      // Let the providers finish; refreshListenable must re-run the redirect.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      return router.routerDelegate.currentConfiguration.uri.path;
    }

    setUp(() async {
      await SecureStorage.deleteAll();
    });

    testWidgets('returning user ends up on home, not onboarding',
        (tester) async {
      final destination = await startupDestination(
        tester,
        prefs: {'onboarding_complete': true},
      );

      expect(destination, equals('/'));
    });

    testWidgets('first-time user ends up on onboarding', (tester) async {
      final destination = await startupDestination(tester, prefs: {});

      expect(destination, equals(welcomeRoute));
    });
  });
}
