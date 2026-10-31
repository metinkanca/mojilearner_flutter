import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/services/account_service.dart';
import 'package:mojilearner_flutter/services/cloud_sync.dart';
import 'package:mojilearner_flutter/services/data_eraser.dart';
import 'package:mojilearner_flutter/utils/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_account.dart';

/// The two ways a player can ask for their data to be gone. What matters in
/// both is that "gone" includes the copy in the cloud, because that copy is
/// restored onto any device with no save of its own.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAccountBackend account;
  late FakeSyncBackend backend;
  late CloudSync sync;
  late DataEraser eraser;

  Future<void> boot({Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues(prefs);
    await SecureStorage.deleteAll();
    account = FakeAccountBackend();
    backend = FakeSyncBackend(account);
    sync = CloudSync(backend: backend);
    await sync.start();
    eraser = DataEraser(
      sync: sync,
      account: AccountService(backend: account, sync: sync),
    );
  }

  tearDown(() async => sync.dispose());

  group('Reset App', () {
    test('wipes the phone and the stored save', () async {
      await boot(prefs: {'pet_bond_points': 140});
      await SecureStorage.saveString('assessment_en', 'answers');
      await sync.flush();
      expect(backend.docFor('anon-uid'), isNotNull);

      await eraser.resetProgress();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pet_bond_points'), isNull);
      expect(await SecureStorage.readString('assessment_en'), isNull);
      expect(backend.docFor('anon-uid'), isNull);
    });

    test('the next launch does not bring the old save back', () async {
      await boot(prefs: {'pet_bond_points': 140});
      await sync.flush();
      await eraser.resetProgress();
      await sync.dispose();

      // A relaunch: same account, same (now empty) device.
      final relaunch = CloudSync(backend: backend);
      await relaunch.start();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pet_bond_points'), isNull);
      await relaunch.dispose();
    });

    test('works offline, and finishes the delete on a later launch', () async {
      await boot(prefs: {'pet_bond_points': 140});
      await sync.flush();
      backend.offline = true;

      await eraser.resetProgress();

      // Wiped locally even though the cloud could not be reached.
      var prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pet_bond_points'), isNull);
      expect(backend.docFor('anon-uid'), isNotNull);
      await sync.dispose();

      // Still offline on the next launch: the old save must not be restored.
      final stillOffline = CloudSync(backend: backend);
      await stillOffline.start();
      prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pet_bond_points'), isNull);
      await stillOffline.dispose();

      // Back online: the leftover copy is deleted, and still not restored.
      backend.offline = false;
      final online = CloudSync(backend: backend);
      await online.start();
      expect(backend.docFor('anon-uid'), isNull);
      prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pet_bond_points'), isNull);
      await online.dispose();
    });

    test('a pending delete never removes progress made after the reset',
        () async {
      await boot(prefs: {'pet_bond_points': 140});
      await sync.flush();
      backend.offline = true;
      await eraser.resetProgress();
      backend.offline = false;

      // The player starts over and plays; their new save is uploaded.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('sync_pending_erase'), isTrue);
      await prefs.setInt('pet_bond_points', 5);
      expect(await sync.flush(), isTrue);
      expect(prefs.getBool('sync_pending_erase'), isNull);
      await sync.dispose();

      final relaunch = CloudSync(backend: backend);
      await relaunch.start();

      expect(backend.docFor('anon-uid'), isNotNull,
          reason: 'the upload replaced the old save, so there is nothing '
              'left to delete and the new one must survive');
      await relaunch.dispose();
    });
  });

  group('Delete Account', () {
    test('removes the stored save, the account and the phone data', () async {
      await boot(prefs: {'pet_bond_points': 140});
      await sync.flush();

      final status = await eraser.deleteAccount();

      expect(status, AccountDeleteStatus.deleted);
      expect(backend.docFor('anon-uid'), isNull);
      expect(account.deletes, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pet_bond_points'), isNull);
    });

    test('the app carries on under a new identity afterwards', () async {
      await boot(prefs: {'pet_bond_points': 140});
      await sync.flush();
      await eraser.deleteAccount();

      expect(sync.isSignedIn, isTrue);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('pet_bond_points', 1);
      expect(await sync.flush(), isTrue);
      expect(backend.docFor('anon-uid'), isNull,
          reason: 'the deleted identity must not be written to again');
      expect(backend.docFor(account.uid), isNotNull);
    });

    test('offline: nothing is touched and the player is told to retry',
        () async {
      await boot(prefs: {'pet_bond_points': 140});
      await sync.flush();
      backend.offline = true;

      final status = await eraser.deleteAccount();

      expect(status, AccountDeleteStatus.failed);
      expect(account.deletes, 0, reason: 'the account is kept while the save '
          'cannot be deleted, or nothing could ever delete the save');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pet_bond_points'), 140);
    });

    test('a Google account is re-verified through Google, no password',
        () async {
      await boot(prefs: {'pet_bond_points': 140});
      account
        ..isAnonymous = false
        ..googleLinked = true
        ..deleteFailures.add('requires-recent-login');

      final status = await eraser.deleteAccount();

      expect(status, AccountDeleteStatus.deleted);
      expect(account.reauths, 1);
      expect(account.deletes, 2);
    });

    test('an email account is asked for its password, then deleted', () async {
      await boot(prefs: {'pet_bond_points': 140});
      account
        ..isAnonymous = false
        ..deleteFailures.addAll(['requires-recent-login', 'requires-recent-login']);

      expect(await eraser.deleteAccount(), AccountDeleteStatus.needsPassword);
      // Asking for the password must not have wiped the phone.
      var prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pet_bond_points'), 140);

      expect(await eraser.deleteAccount(password: 'wrong'),
          AccountDeleteStatus.needsPassword);

      account.deleteFailures.add('requires-recent-login');
      expect(await eraser.deleteAccount(password: 'right'),
          AccountDeleteStatus.deleted);
      prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pet_bond_points'), isNull);
    });

    test('with no cloud layer it still wipes the phone', () async {
      SharedPreferences.setMockInitialValues({'pet_bond_points': 140});
      final status = await DataEraser().deleteAccount();

      expect(status, AccountDeleteStatus.deleted);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pet_bond_points'), isNull);
    });
  });

  group('an eraser built before sync finished starting', () {
    test('waits for startup, so a late restore cannot undo the reset', () async {
      await boot(prefs: {'pet_bond_points': 140});
      await sync.flush();

      // A returning player opens the app at once and sync is still coming up
      // when they reach Reset: the eraser sees no sync yet.
      CloudSync? live;
      final starting = Completer<void>();
      final lazy = DataEraser.lazy(
        sync: () => live,
        account: () => null,
        ready: () => starting.future,
      );

      var done = false;
      final reset = lazy.resetProgress().then((_) => done = true);
      await pumpEventQueue();
      expect(done, isFalse, reason: 'must not wipe before it knows about sync');

      live = sync;
      starting.complete();
      await reset;

      expect(backend.docFor('anon-uid'), isNull,
          reason: 'the cloud copy was found and deleted once sync was up');
    });
  });
}
