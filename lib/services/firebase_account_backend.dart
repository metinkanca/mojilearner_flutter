import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../constants/app_runtime_config.dart';
import 'account_service.dart';

/// [AccountBackend] against FirebaseAuth.
///
/// Thin on purpose: every decision worth testing lives in [AccountService],
/// and this exists so that logic never has to construct a `FirebaseAuth` to be
/// exercised. The one real job here is translating `FirebaseAuthException`
/// into [AccountBackendException] so nothing above this file depends on
/// Firebase's error type.
class FirebaseAccountBackend implements AccountBackend {
  FirebaseAccountBackend({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Google Sign-In must be initialised once before any sheet is shown, and
  /// only once — so it is done on first use rather than at startup, since a
  /// player who never signs in never needs it.
  bool _googleReady = false;

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  String? get currentEmail => _auth.currentUser?.email;

  @override
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;

  @override
  Future<void> linkEmailPassword(String email, String password) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AccountBackendException('no-current-user');
    }
    try {
      // Upgrades this uid in place. The Firestore document is named after the
      // uid, so the player's pet is untouched by a successful link.
      await user.linkWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
    } on FirebaseAuthException catch (e) {
      throw AccountBackendException(e.code, e.message);
    }
  }

  @override
  Future<void> signInEmailPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AccountBackendException(e.code, e.message);
    }
  }

  @override
  bool get supportsGoogleSignIn {
    try {
      return GoogleSignIn.instance.supportsAuthenticate();
    } catch (_) {
      // No platform implementation registered — desktop, or a test host.
      return false;
    }
  }

  @override
  Future<String?> linkGoogle() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AccountBackendException('no-current-user');
    }
    final credential = await _googleCredential();
    try {
      // Upgrades this uid in place, exactly as the email path does.
      final result = await user.linkWithCredential(credential);
      return result.user?.email;
    } on FirebaseAuthException catch (e) {
      throw AccountBackendException(e.code, e.message, e.email);
    }
  }

  @override
  Future<String?> signInGoogle() async {
    final credential = await _googleCredential();
    try {
      final result = await _auth.signInWithCredential(credential);
      return result.user?.email;
    } on FirebaseAuthException catch (e) {
      throw AccountBackendException(e.code, e.message, e.email);
    }
  }

  /// Puts the player through Google's sheet and turns the result into
  /// something FirebaseAuth will take.
  Future<AuthCredential> _googleCredential() async {
    final signIn = GoogleSignIn.instance;
    if (!_googleReady) {
      await signIn.initialize(
        // Apple platforms need their own client id; Android identifies itself
        // by signing certificate and must not be given one.
        clientId: _isApple ? AppRuntimeConfig.googleIosClientId : null,
        // Without this the sheet succeeds and Firebase then rejects the token.
        serverClientId: AppRuntimeConfig.googleServerClientId,
      );
      _googleReady = true;
    }

    try {
      final account = await signIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        // Nothing to hand Firebase. Treated as a failure rather than a crash,
        // so the player is offered the form instead of losing the screen.
        throw const AccountBackendException('missing-id-token');
      }
      return GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (e) {
      throw AccountBackendException(
        // Dismissing the sheet is a decision, not an error.
        e.code == GoogleSignInExceptionCode.canceled
            ? 'cancelled'
            : 'google-sign-in-failed',
        e.description,
      );
    }
  }

  static bool get _isApple =>
      !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  @override
  Future<void> signOut() async {
    // Signed out of Google too, or the next sheet silently reuses the same
    // account and "sign in as someone else" appears broken.
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Never signed in with Google, or the plugin is unavailable on this
      // platform. Either way the Firebase sign-out below is what matters.
    }
    await _auth.signOut();
  }
}
