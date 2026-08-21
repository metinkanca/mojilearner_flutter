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
}
