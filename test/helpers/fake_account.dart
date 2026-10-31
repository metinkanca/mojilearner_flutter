/// Test doubles for the account and sync layer.
///
/// Shared so the service tests and the opening's widget tests exercise the
/// same fake, rather than two that can drift apart.
library;
import 'package:mojilearner_flutter/services/account_service.dart';
import 'package:mojilearner_flutter/services/cloud_sync.dart';

class FakeAccountBackend implements AccountBackend {
  FakeAccountBackend({
    this.takenEmails = const {},
    this.googleEmail = 'metin@gmail.com',
    this.googleCancels = false,
  });

  /// Addresses that already belong to somebody — the conflict case.
  final Set<String> takenEmails;

  /// The address Google's sheet comes back with.
  final String googleEmail;

  /// Whether the player dismisses Google's sheet instead of finishing it.
  final bool googleCancels;

  String uid = 'anon-uid';

  /// The ID token this backend hands the AI proxy. Null stands for a refresh
  /// that failed, which the proxy meters anonymously rather than refusing.
  String? idToken = 'fake-id-token';

  @override
  Future<String?> currentIdToken() async => idToken;

  @override
  String? currentEmail;
  @override
  bool isAnonymous = true;

  /// Web withholds the Google option; everything else offers it.
  bool supportsGoogle = true;

  int links = 0;
  int signIns = 0;
  int googleLinks = 0;
  int googleSignIns = 0;

  @override
  String? get currentUid => uid;

  @override
  Future<void> linkEmailPassword(String email, String password) async {
    links++;
    if (takenEmails.contains(email)) {
      throw const AccountBackendException('credential-already-in-use');
    }
    if (password.length < 6) {
      throw const AccountBackendException('weak-password');
    }
    // The point of linking: the uid does not move.
    currentEmail = email;
    isAnonymous = false;
  }

  @override
  Future<void> signInEmailPassword(String email, String password) async {
    signIns++;
    if (password == 'wrong') {
      throw const AccountBackendException('wrong-password');
    }
    uid = 'account-uid-for-$email';
    currentEmail = email;
    isAnonymous = false;
  }

  @override
  bool get supportsGoogleSignIn => supportsGoogle;

  @override
  Future<String?> linkGoogle() async {
    googleLinks++;
    if (googleCancels) {
      throw const AccountBackendException('cancelled');
    }
    if (takenEmails.contains(googleEmail)) {
      throw AccountBackendException(
        'credential-already-in-use',
        null,
        googleEmail,
      );
    }
    currentEmail = googleEmail;
    isAnonymous = false;
    return googleEmail;
  }

  @override
  Future<String?> signInGoogle() async {
    googleSignIns++;
    if (googleCancels) {
      throw const AccountBackendException('cancelled');
    }
    uid = 'account-uid-for-$googleEmail';
    currentEmail = googleEmail;
    isAnonymous = false;
    return googleEmail;
  }

  @override
  Future<void> signOut() async {
    uid = 'anon-uid';
    currentEmail = null;
    isAnonymous = true;
  }

  /// Codes `deleteUser` throws, in order, before it finally succeeds.
  final List<String> deleteFailures = [];
  int deletes = 0;
  int reauths = 0;
  String? reauthPassword;

  /// The password an email account will accept on re-authentication.
  String correctPassword = 'right';

  @override
  Future<void> deleteUser() async {
    deletes++;
    if (deleteFailures.isNotEmpty) {
      throw AccountBackendException(deleteFailures.removeAt(0));
    }
    // A deleted user is gone; the next sign-in is a new anonymous identity.
    uid = 'anon-uid-${deletes + 1}';
    currentEmail = null;
    isAnonymous = true;
  }

  @override
  Future<void> reauthenticate({String? password}) async {
    reauths++;
    reauthPassword = password;
    if (isAnonymous) return;
    if (googleLinked) return;
    if (password == null || password.isEmpty) {
      throw const AccountBackendException('password-required');
    }
    if (password != correctPassword) {
      throw const AccountBackendException('wrong-password');
    }
  }

  /// Whether the account re-authenticates through Google (no password needed).
  bool googleLinked = false;
}

/// Mirrors the account backend's uid so [CloudSync] follows a sign-in.
class FakeSyncBackend implements CloudSyncBackend {
  FakeSyncBackend(this._account, {Map<String, Map<String, dynamic>>? docs})
      : _docs = docs ?? {};

  final FakeAccountBackend _account;
  final Map<String, Map<String, dynamic>> _docs;

  int uploads = 0;

  Map<String, dynamic>? docFor(String uid) => _docs[uid];

  @override
  Future<String?> signIn() async => _account.uid;

  @override
  Future<Map<String, dynamic>?> fetch(String uid) async => _docs[uid];

  @override
  Future<void> upload(String uid, Map<String, dynamic> data) async {
    uploads++;
    _docs[uid] = data;
  }

  /// Makes `delete` throw, standing in for no connection.
  bool offline = false;
  int deletes = 0;

  @override
  Future<void> delete(String uid) async {
    deletes++;
    if (offline) throw Exception('offline');
    _docs.remove(uid);
  }
}
