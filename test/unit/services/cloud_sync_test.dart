import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/services/cloud_sync.dart';
import 'package:mojilearner_flutter/services/local_snapshot.dart';
import 'package:mojilearner_flutter/utils/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records every call, so the tests can assert on *how many writes* happened
/// rather than only on the final state. Write count is the whole point of the
/// class under test.
class FakeBackend implements CloudSyncBackend {
  FakeBackend({this.uid = 'player-1', Map<String, dynamic>? stored})
      : _stored = stored;

  final String? uid;
  Map<String, dynamic>? _stored;

  int uploads = 0;
  int fetches = 0;

  Map<String, dynamic>? get stored => _stored;

  @override
  Future<String?> signIn() async => uid;

  @override
  Future<Map<String, dynamic>?> fetch(String uid) async {
    fetches++;
    return _stored;
  }

  @override
  Future<void> upload(String uid, Map<String, dynamic> data) async {
    uploads++;
    _stored = data;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SecureStorage.deleteAll();
  });

  group('what a session costs in writes', () {
    test('an idle app uploads once and then stops', () async {
      SharedPreferences.setMockInitialValues({'pet_happiness': 70});
      final backend = FakeBackend();
      final sync = CloudSync(backend: backend);
      await sync.start();

      expect(await sync.flush(), isTrue, reason: 'first flush has news');
      expect(backend.uploads, 1);

      // Nothing has changed since, so nothing should be paid for.
      for (var i = 0; i < 10; i++) {
        expect(await sync.flush(), isFalse);
      }
      expect(backend.uploads, 1,
          reason: 'an unchanged snapshot is not worth a write');

      await sync.dispose();
    });

    test('a whole session of changes still costs one write', () async {
      SharedPreferences.setMockInitialValues({'pet_happiness': 70});
      final backend = FakeBackend();
      final sync = CloudSync(backend: backend);
      await sync.start();

      final prefs = await SharedPreferences.getInstance();
      // Stand-ins for a session: feeding, petting, a quiz, some coins.
      for (var i = 0; i < 50; i++) {
        await prefs.setInt('pet_happiness', 50 + i);
        await prefs.setInt('coins', i);
      }
      await sync.flush();

      expect(backend.uploads, 1,
          reason: 'the document is the unit of cost, not the change');

      await sync.dispose();
    });

    /// The bug this test exists for: `sync_last_hash` and `sync_revision` are
    /// written by a flush. If they were part of the snapshot, every upload
    /// would change the next snapshot, so the hash would never settle and the
    /// app would write in a loop for as long as it stayed open — unbounded,
    /// billed, and on every install.
    test('the sync bookkeeping never re-triggers itself', () async {
      SharedPreferences.setMockInitialValues({'pet_happiness': 70});
      final backend = FakeBackend();
      final sync = CloudSync(backend: backend);
      await sync.start();

      await sync.flush();
      final afterFirst = backend.uploads;

      // Flushing repeatedly, exactly as the five-minute timer would.
      for (var i = 0; i < 20; i++) {
        await sync.flush();
      }

      expect(backend.uploads, afterFirst,
          reason: 'a flush must not make the next flush look like new state');

      final snapshot = await LocalSnapshot.capture();
      final prefs = snapshot['prefs'] as Map<String, dynamic>;
      for (final key in LocalSnapshot.syncBookkeepingPrefs) {
        expect(prefs.containsKey(key), isFalse,
            reason: '$key must never reach the snapshot');
      }

      await sync.dispose();
    });
  });

  group('restoring onto a new device', () {
    test('a fresh install takes the stored save', () async {
      SharedPreferences.setMockInitialValues({});
      final backend = FakeBackend(stored: {
        'prefs': {'pet_happiness': 88, 'coins': 250, 'username': 'Metin'},
        'secure': <String, dynamic>{},
        'revision': 7,
      });

      final sync = CloudSync(backend: backend);
      await sync.start();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pet_happiness'), 88);
      expect(prefs.getInt('coins'), 250);
      expect(prefs.getString('username'), 'Metin');

      await sync.dispose();
    });

    test('a device that has been played on is left alone', () async {
      // `sync_revision` present means this install has its own history. The
      // stored save is older or from elsewhere; overwriting would be the sync
      // layer deleting the pet it exists to protect.
      SharedPreferences.setMockInitialValues({
        'pet_happiness': 12,
        'sync_revision': 3,
      });
      final backend = FakeBackend(stored: {
        'prefs': {'pet_happiness': 99},
        'secure': <String, dynamic>{},
        'revision': 2,
      });

      final sync = CloudSync(backend: backend);
      await sync.start();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pet_happiness'), 12,
          reason: 'local progress outranks a stored save');
      expect(backend.fetches, 0,
          reason: 'and it should not even cost a read to find that out');

      await sync.dispose();
    });

    test('a player who has never synced gets nothing and loses nothing',
        () async {
      SharedPreferences.setMockInitialValues({'pet_happiness': 55});
      final backend = FakeBackend(stored: null);

      final sync = CloudSync(backend: backend);
      await sync.start();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pet_happiness'), 55);

      await sync.dispose();
    });
  });

  group('when the backend is not there', () {
    test('a refused sign-in leaves the app entirely local', () async {
      SharedPreferences.setMockInitialValues({'pet_happiness': 41});
      final backend = FakeBackend(uid: null);

      final sync = CloudSync(backend: backend);
      await sync.start();

      expect(sync.isSignedIn, isFalse);
      expect(await sync.flush(), isFalse);
      expect(backend.uploads, 0);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pet_happiness'), 41,
          reason: 'no identity is not a reason to touch the local save');

      await sync.dispose();
    });
  });

  group('what travels', () {
    test('progress goes, session scratch state stays', () async {
      SharedPreferences.setMockInitialValues({
        'pet_bond_points': 140,
        'total_xp': 900,
        'unlocked_items': ['apple', 'crown'],
        // Local-only: a half-finished quiz and a device migration flag.
        'quiz_saved_index': 4,
        'chat_migration_complete': true,
      });

      final snapshot = await LocalSnapshot.capture();
      final prefs = snapshot['prefs'] as Map<String, dynamic>;

      expect(prefs['pet_bond_points'], 140);
      expect(prefs['total_xp'], 900);
      expect(prefs.containsKey('quiz_saved_index'), isFalse);
      expect(prefs.containsKey('chat_migration_complete'), isFalse);
    });

    test('a string list survives the round trip', () async {
      SharedPreferences.setMockInitialValues({
        'unlocked_items': ['apple', 'crown', 'scarf'],
      });

      final snapshot = await LocalSnapshot.capture();

      SharedPreferences.setMockInitialValues({});
      await LocalSnapshot.restore(snapshot);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('unlocked_items'),
          ['apple', 'crown', 'scarf']);
    });
  });
}
