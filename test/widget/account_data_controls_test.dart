import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/account_data_controls.dart';
import 'package:mojilearner_flutter/components/app_restart.dart';
import 'package:mojilearner_flutter/l10n/app_localizations.dart';
import 'package:mojilearner_flutter/services/account_service.dart';
import 'package:mojilearner_flutter/services/data_eraser.dart';
import 'package:provider/provider.dart';

/// The buttons that wipe a player's data, as the player meets them.
///
/// The services behind them are tested in `data_eraser_test.dart`. What is
/// pinned here is the part a service test cannot see: that a destructive action
/// asks first, that "cancel" really cancels, that a failure leaves the app
/// alone and says so, and that success rebuilds the app so the wiped state is
/// what the player sees.
class _FakeEraser extends DataEraser {
  _FakeEraser([List<AccountDeleteStatus>? statuses])
      : statuses = statuses ?? [AccountDeleteStatus.deleted];

  final List<AccountDeleteStatus> statuses;
  final List<String?> deleteCalls = [];
  int resets = 0;

  @override
  Future<void> resetProgress() async => resets++;

  @override
  Future<AccountDeleteStatus> deleteAccount({String? password}) async {
    deleteCalls.add(password);
    return statuses.removeAt(0);
  }
}

class _Probe extends StatefulWidget {
  const _Probe({required this.onInit, required this.child});
  final VoidCallback onInit;
  final Widget child;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Lets animations finish, then runs out the pause that holds the confirmation
/// on screen before the app is rebuilt (a timer, which settling does not wait
/// for).
Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

void main() {
  late _FakeEraser eraser;
  late int builds;

  Future<void> pump(WidgetTester tester, Widget child) async {
    builds = 0;
    await tester.pumpWidget(
      Provider<DataEraser?>.value(
        value: eraser,
        child: AppRestart(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: _Probe(onInit: () => builds++, child: child),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> tapDelete(WidgetTester tester) async {
    await tester.tap(find.text('DELETE ACCOUNT'));
    await settle(tester);
  }

  group('Delete Account', () {
    testWidgets('asks before doing anything, and cancel does nothing',
        (tester) async {
      eraser = _FakeEraser();
      await pump(tester, const DeleteAccountButton());

      await tapDelete(tester);
      expect(find.text('DELETE ACCOUNT?'), findsOneWidget);
      expect(eraser.deleteCalls, isEmpty, reason: 'asking is not doing');

      await tester.tap(find.text('CANCEL'));
      await settle(tester);

      expect(eraser.deleteCalls, isEmpty);
      expect(builds, 1, reason: 'cancelled, so the app is left as it was');
    });

    testWidgets('confirming deletes, says so, and rebuilds the app',
        (tester) async {
      eraser = _FakeEraser();
      await pump(tester, const DeleteAccountButton());

      await tapDelete(tester);
      await tester.tap(find.text('DELETE'));
      await tester.pumpAndSettle();

      // The confirmation is up while the pause runs, and the app is rebuilt
      // only after it.
      expect(eraser.deleteCalls, [null]);
      expect(find.text('Your account and data were deleted.'), findsOneWidget);
      expect(builds, 1, reason: 'not rebuilt until the confirmation has been seen');

      await settle(tester);
      expect(builds, 2, reason: 'rebuilt, so providers re-read the empty state');
    });

    testWidgets('a failure leaves everything alone and tells the player',
        (tester) async {
      eraser = _FakeEraser([AccountDeleteStatus.failed]);
      await pump(tester, const DeleteAccountButton());

      await tapDelete(tester);
      await tester.tap(find.text('DELETE'));
      await settle(tester);

      expect(find.textContaining("Couldn't delete your account"), findsOneWidget);
      expect(builds, 1, reason: 'nothing was wiped, so nothing is rebuilt');
    });

    testWidgets('an email account is asked for its password, then retried with it',
        (tester) async {
      eraser = _FakeEraser(
        [AccountDeleteStatus.needsPassword, AccountDeleteStatus.deleted],
      );
      await pump(tester, const DeleteAccountButton());

      await tapDelete(tester);
      await tester.tap(find.text('DELETE'));
      await settle(tester);

      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'hunter22');
      await tester.tap(find.text('DELETE'));
      await settle(tester);

      expect(eraser.deleteCalls, [null, 'hunter22']);
      expect(builds, 2);
    });

    testWidgets('backing out of the password prompt stops there',
        (tester) async {
      eraser = _FakeEraser([AccountDeleteStatus.needsPassword]);
      await pump(tester, const DeleteAccountButton());

      await tapDelete(tester);
      await tester.tap(find.text('DELETE'));
      await settle(tester);
      await tester.tap(find.text('CANCEL'));
      await settle(tester);

      expect(eraser.deleteCalls, [null], reason: 'no second attempt');
      expect(builds, 1);
    });
  });

  group('Reset App', () {
    testWidgets('resets through the eraser and rebuilds the app', (tester) async {
      eraser = _FakeEraser();
      await pump(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => resetAndRestart(context),
            child: const Text('go'),
          ),
        ),
      );

      await tester.tap(find.text('go'));
      await settle(tester);

      expect(eraser.resets, 1);
      expect(builds, 2);
    });
  });

  group('Privacy policy link', () {
    testWidgets('is not shown until there is an address to open',
        (tester) async {
      eraser = _FakeEraser();
      await pump(tester, const PrivacyPolicyLink(url: ''));
      expect(find.text('PRIVACY POLICY'), findsNothing);
    });

    testWidgets('is shown once an address is set', (tester) async {
      eraser = _FakeEraser();
      await pump(tester, const PrivacyPolicyLink(url: 'https://example.com/p'));
      expect(find.text('PRIVACY POLICY'), findsOneWidget);
    });
  });
}
