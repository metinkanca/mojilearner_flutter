import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/services/account_service.dart';
import 'package:mojilearner_flutter/services/cloud_sync.dart';
import 'package:mojilearner_flutter/utils/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_account.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SecureStorage.deleteAll();
  });

  group('signing up on the device you already play on', () {
    test('linking keeps the pet exactly where it is', () async {
      SharedPreferences.setMockInitialValues({'pet_bond_points': 140});
      final account = FakeAccountBackend();
      final syncBackend = FakeSyncBackend(account);
      final sync = CloudSync(backend: syncBackend);
      await sync.start();
      await sync.flush();

      final service = AccountService(backend: account, sync: sync);
      final result = await service.linkAccount('metin@example.com', 'hunter22');

      expect(result.isLinked, isTrue);
      expect(service.isAnonymous, isFalse);
      expect(service.email, 'metin@example.com');

      // The uid never moved, so the document the player has been writing all
      // along is the one the account now owns. No migration, no restore.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pet_bond_points'), 140);
      expect(syncBackend.docFor('anon-uid'), isNotNull);

      await sync.dispose();
    });

    test('an ordinary refusal is not a conflict', () async {
      final account = FakeAccountBackend();
      final sync = CloudSync(backend: FakeSyncBackend(account));
      await sync.start();

      final service = AccountService(backend: account, sync: sync);
      final result = await service.linkAccount('metin@example.com', 'short');

      expect(result.status, AccountLinkStatus.failed);
      expect(result.code, 'weak-password');
      expect(service.isAnonymous, isTrue, reason: 'still the install identity');

      await sync.dispose();
    });
  });

  group('signing up through Google', () {
    test('linking keeps the pet exactly where it is', () async {
      SharedPreferences.setMockInitialValues({'pet_bond_points': 140});
      final account = FakeAccountBackend();
      final syncBackend = FakeSyncBackend(account);
      final sync = CloudSync(backend: syncBackend);
      await sync.start();
      await sync.flush();

      final service = AccountService(backend: account, sync: sync);
      final result = await service.linkGoogleAccount();

      expect(result.isLinked, isTrue);
      expect(service.isAnonymous, isFalse);
      expect(service.email, 'metin@gmail.com');

      // Same guarantee as the email path: the uid never moved, so no save
      // was restored over the pet this device has been raising.
      expect(account.uid, 'anon-uid');
      expect(syncBackend.docFor('anon-uid'), isNotNull);
    });

    test('backing out of the sheet is not a failure', () async {
      final account = FakeAccountBackend(googleCancels: true);
      final sync = CloudSync(backend: FakeSyncBackend(account));
      await sync.start();

      final service = AccountService(backend: account, sync: sync);
      final result = await service.linkGoogleAccount();

      // Nothing went wrong, so nothing should be reported as having gone
      // wrong — the player is still anonymous and still playing.
      expect(result.isCancelled, isTrue);
      expect(result.isLinked, isFalse);
      expect(result.status, isNot(AccountLinkStatus.failed));
      expect(service.isAnonymous, isTrue);
    });

    test('a Google account that already belongs to someone is a question, '
        'not an error', () async {
      final account = FakeAccountBackend(takenEmails: {'metin@gmail.com'});
      final sync = CloudSync(backend: FakeSyncBackend(account));
      await sync.start();

      final service = AccountService(backend: account, sync: sync);
      final result = await service.linkGoogleAccount();

      expect(result.isConflict, isTrue);
      // The prompt has to be able to name the account it collided with.
      expect(result.email, 'metin@gmail.com');
      // Nothing was decided on the player's behalf.
      expect(service.isAnonymous, isTrue);
      expect(account.googleSignIns, 0);
    });

    test('resolving in favour of this device overwrites the saved pet',
        () async {
      SharedPreferences.setMockInitialValues({'pet_bond_points': 140});
      final account = FakeAccountBackend(takenEmails: {'metin@gmail.com'});
      final syncBackend = FakeSyncBackend(account, docs: {
        'account-uid-for-metin@gmail.com': {
          'prefs': {'pet_bond_points': 3},
          'secure': <String, dynamic>{},
          'revision': 12,
        },
      });
      final sync = CloudSync(backend: syncBackend);
      await sync.start();
      await sync.flush();

      final service = AccountService(backend: account, sync: sync);
      expect((await service.linkGoogleAccount()).isConflict, isTrue);

      final resolved = await service.resolveGoogleConflict(
        choice: ConflictChoice.keepThisDevice,
      );

      expect(resolved.isLinked, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pet_bond_points'), 140,
          reason: 'the local pet survives');

      // And it must actually have reached the account, not just stayed local.
      final stored = syncBackend.docFor('account-uid-for-metin@gmail.com')!;
      expect((stored['prefs'] as Map)['pet_bond_points'], 140);

      await sync.dispose();
    });

    test('resolving in favour of the account takes the saved pet', () async {
      SharedPreferences.setMockInitialValues({'pet_bond_points': 140});
      final account = FakeAccountBackend(takenEmails: {'metin@gmail.com'});
      final syncBackend = FakeSyncBackend(account, docs: {
        'account-uid-for-metin@gmail.com': {
          'prefs': {'pet_bond_points': 999, 'username': 'OldPhone'},
          'secure': <String, dynamic>{},
          'revision': 12,
        },
      });
      final sync = CloudSync(backend: syncBackend);
      await sync.start();
      await sync.flush();

      final service = AccountService(backend: account, sync: sync);
      expect((await service.linkGoogleAccount()).isConflict, isTrue);

      final resolved = await service.resolveGoogleConflict(
        choice: ConflictChoice.useSavedAccount,
      );

      expect(resolved.isLinked, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pet_bond_points'), 999);
      expect(prefs.getString('username'), 'OldPhone');

      await sync.dispose();
    });
  });

  group('the two-pets problem', () {
    test('an address that is taken asks rather than guessing', () async {
      SharedPreferences.setMockInitialValues({'pet_bond_points': 140});
      final account =
          FakeAccountBackend(takenEmails: {'metin@example.com'});
      final sync = CloudSync(backend: FakeSyncBackend(account));
      await sync.start();

      final service = AccountService(backend: account, sync: sync);
      final result = await service.linkAccount('metin@example.com', 'hunter22');

      expect(result.isConflict, isTrue);
      expect(result.email, 'metin@example.com');

      // Nothing has happened yet. Still anonymous, still this device's pet.
      expect(service.isAnonymous, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pet_bond_points'), 140);

      await sync.dispose();
    });

    test('choosing the saved account replaces the local pet', () async {
      SharedPreferences.setMockInitialValues({'pet_bond_points': 140});
      final account =
          FakeAccountBackend(takenEmails: {'metin@example.com'});
      final syncBackend = FakeSyncBackend(account, docs: {
        'account-uid-for-metin@example.com': {
          'prefs': {'pet_bond_points': 999, 'username': 'OldPhone'},
          'secure': <String, dynamic>{},
          'revision': 12,
        },
      });
      final sync = CloudSync(backend: syncBackend);
      await sync.start();
      await sync.flush();

      final service = AccountService(backend: account, sync: sync);
      await service.resolveConflict(
        email: 'metin@example.com',
        password: 'hunter22',
        choice: ConflictChoice.useSavedAccount,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pet_bond_points'), 999);
      expect(prefs.getString('username'), 'OldPhone');

      await sync.dispose();
    });

    test('choosing this device overwrites the saved pet', () async {
      SharedPreferences.setMockInitialValues({'pet_bond_points': 140});
      final account =
          FakeAccountBackend(takenEmails: {'metin@example.com'});
      final syncBackend = FakeSyncBackend(account, docs: {
        'account-uid-for-metin@example.com': {
          'prefs': {'pet_bond_points': 999},
          'secure': <String, dynamic>{},
          'revision': 12,
        },
      });
      final sync = CloudSync(backend: syncBackend);
      await sync.start();
      await sync.flush();

      final service = AccountService(backend: account, sync: sync);
      await service.resolveConflict(
        email: 'metin@example.com',
        password: 'hunter22',
        choice: ConflictChoice.keepThisDevice,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pet_bond_points'), 140,
          reason: 'the local pet survives');

      // And it must actually have reached the account, not just stayed local.
      final stored =
          syncBackend.docFor('account-uid-for-metin@example.com')!;
      expect((stored['prefs'] as Map)['pet_bond_points'], 140);

      await sync.dispose();
    });
  });

  group('signing in on a new phone', () {
    test('pulls the saved pet onto a device that has none', () async {
      SharedPreferences.setMockInitialValues({});
      final account = FakeAccountBackend();
      final syncBackend = FakeSyncBackend(account, docs: {
        'account-uid-for-metin@example.com': {
          'prefs': {'pet_bond_points': 640, 'coins': 300},
          'secure': <String, dynamic>{},
          'revision': 31,
        },
      });
      final sync = CloudSync(backend: syncBackend);
      await sync.start();

      final service = AccountService(backend: account, sync: sync);
      final result = await service.signIn('metin@example.com', 'hunter22');

      expect(result.isLinked, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pet_bond_points'), 640);
      expect(prefs.getInt('coins'), 300);

      await sync.dispose();
    });

    test('a wrong password changes nothing at all', () async {
      SharedPreferences.setMockInitialValues({'pet_bond_points': 55});
      final account = FakeAccountBackend();
      final sync = CloudSync(backend: FakeSyncBackend(account));
      await sync.start();

      final service = AccountService(backend: account, sync: sync);
      final result = await service.signIn('metin@example.com', 'wrong');

      expect(result.status, AccountLinkStatus.failed);
      expect(result.code, 'wrong-password');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pet_bond_points'), 55);

      await sync.dispose();
    });
  });
}
