/// Turning the silent per-install identity into a real account.
///
/// The sync layer keys everything off a uid, and anonymous sign-in already
/// supplies one — so the job here is not "log in", it is **upgrade the uid the
/// player already has** without their pet moving. `link` does exactly that:
/// same uid, same document, nothing migrates, and a player who has been
/// raising a cat for a week keeps it the instant they sign up.
///
/// Why this is needed at all, given anonymous already works: the anonymous
/// credential lives in the device's local credential store. On iOS that is the
/// Keychain, which survives a reinstall; on Android it is shared preferences,
/// which does not, and only returns if Android Auto Backup happens to restore
/// it. Neither survives a new phone. Anonymous is a good default, not a
/// guarantee — this is the guarantee.
library;

import 'cloud_sync.dart';

/// What happened when a player tried to attach an account.
enum AccountLinkStatus {
  /// The anonymous uid was upgraded. Nothing moved; there is nothing to ask.
  linked,

  /// Those credentials already belong to an account — which means a save
  /// already exists somewhere else, *and* this device has progress of its own.
  ///
  /// Two pets, and no honest way to merge them: there is no meaningful
  /// combination of a cat fed at 8am here and a cat fed at 8am there. The
  /// player has to choose, so this is a question, not an error.
  conflict,

  /// Ordinary refusals — bad password, malformed email, weak password, a
  /// network that is not there.
  failed,

  /// The player backed out of the provider's own sheet. Not a refusal and not
  /// a success: nothing went wrong, so nothing should be reported as having
  /// gone wrong. Kept distinct from [failed] precisely so the UI does not
  /// apologise for a decision the player made on purpose.
  cancelled,
}

class AccountLinkResult {
  const AccountLinkResult(this.status, {this.code, this.email});

  final AccountLinkStatus status;

  /// The provider's own error code, for mapping onto a localized message.
  final String? code;

  /// The address involved, so a conflict prompt can name it.
  final String? email;

  bool get isLinked => status == AccountLinkStatus.linked;
  bool get isConflict => status == AccountLinkStatus.conflict;
  bool get isCancelled => status == AccountLinkStatus.cancelled;
}

/// How a player resolves a [AccountLinkStatus.conflict].
enum ConflictChoice {
  /// Take the save already attached to the account, discarding what is on this
  /// device. The reinstall and new-phone case.
  useSavedAccount,

  /// Keep what is on this device and overwrite the account's save. The "I have
  /// been playing here for a week and only just signed up" case.
  keepThisDevice,
}

/// The identity operations, behind a seam so the logic above can be tested
/// without a live Firebase.
abstract class AccountBackend {
  /// Current uid, or null when signed out entirely.
  String? get currentUid;

  /// The signed-in address, or null while still anonymous.
  String? get currentEmail;

  /// Whether the current identity is the silent per-install one.
  bool get isAnonymous;

  /// Attaches an email/password credential to the *current* uid.
  ///
  /// Throws with code `credential-already-in-use` or `email-already-in-use`
  /// when the address belongs to someone already.
  Future<void> linkEmailPassword(String email, String password);

  /// Signs in to an existing account, abandoning the anonymous uid.
  Future<void> signInEmailPassword(String email, String password);

  /// Whether this platform can show Google's sheet at all. False on web,
  /// where the plugin requires a rendered Google button instead — so the
  /// option is withheld rather than offered and then failing.
  bool get supportsGoogleSignIn;

  /// Puts the player through Google's sheet and attaches the result to the
  /// *current* uid, returning the address it belongs to.
  ///
  /// Throws with code `credential-already-in-use` when that Google account is
  /// already somebody's, and `cancelled` when the player dismisses the sheet.
  Future<String?> linkGoogle();

  /// Signs in with Google to an account that already exists, abandoning the
  /// anonymous uid.
  Future<String?> signInGoogle();

  Future<void> signOut();
}

/// Drives [AccountBackend] and keeps the sync layer pointed at the right save.
class AccountService {
  AccountService({required AccountBackend backend, required CloudSync sync})
      : _backend = backend,
        _sync = sync;

  final AccountBackend _backend;
  final CloudSync _sync;

  bool get isAnonymous => _backend.isAnonymous;
  String? get email => _backend.currentEmail;

  /// See [AccountBackend.supportsGoogleSignIn].
  bool get supportsGoogle => _backend.supportsGoogleSignIn;

  /// Attaches an account to the pet this device is already raising.
  ///
  /// The happy path never touches the save: linking keeps the uid, so the
  /// document the player has been writing all week is the document the account
  /// now owns. Only the conflict path has anything to decide, and it decides
  /// nothing on its own — it reports back and waits.
  Future<AccountLinkResult> linkAccount(String email, String password) async {
    try {
      await _backend.linkEmailPassword(email, password);
      // The uid did not change, so the local save is already the account's
      // save. Nothing to push, nothing to pull.
      return AccountLinkResult(AccountLinkStatus.linked, email: email);
    } on AccountBackendException catch (e) {
      if (e.code == 'credential-already-in-use' ||
          e.code == 'email-already-in-use') {
        return AccountLinkResult(
          AccountLinkStatus.conflict,
          code: e.code,
          email: email,
        );
      }
      return AccountLinkResult(AccountLinkStatus.failed, code: e.code);
    }
  }

  /// Completes a link that hit a [AccountLinkStatus.conflict], once the player
  /// has said which pet they want to keep.
  ///
  /// Either way this signs in to the existing account, so the uid changes and
  /// the anonymous one is abandoned. What differs is which direction the data
  /// then flows, and [CloudSync.onAccountChanged] is what enforces it.
  Future<AccountLinkResult> resolveConflict({
    required String email,
    required String password,
    required ConflictChoice choice,
  }) async {
    try {
      await _backend.signInEmailPassword(email, password);
      await _sync.onAccountChanged(
        keepLocalProgress: choice == ConflictChoice.keepThisDevice,
      );
      return AccountLinkResult(AccountLinkStatus.linked, email: email);
    } on AccountBackendException catch (e) {
      return AccountLinkResult(AccountLinkStatus.failed, code: e.code);
    }
  }

  /// [linkAccount], through Google's sheet rather than a form.
  ///
  /// Same shape and same guarantee: the happy path keeps the uid, so the pet
  /// does not move. Only the provider differs.
  Future<AccountLinkResult> linkGoogleAccount() async {
    try {
      final email = await _backend.linkGoogle();
      return AccountLinkResult(AccountLinkStatus.linked, email: email);
    } on AccountBackendException catch (e) {
      if (e.code == 'cancelled') {
        return const AccountLinkResult(AccountLinkStatus.cancelled);
      }
      if (e.code == 'credential-already-in-use' ||
          e.code == 'email-already-in-use') {
        return AccountLinkResult(
          AccountLinkStatus.conflict,
          code: e.code,
          email: e.email,
        );
      }
      return AccountLinkResult(AccountLinkStatus.failed, code: e.code);
    }
  }

  /// [resolveConflict] for the Google path, where there is no password to
  /// re-enter — the player goes back through the sheet instead.
  Future<AccountLinkResult> resolveGoogleConflict({
    required ConflictChoice choice,
  }) async {
    try {
      final email = await _backend.signInGoogle();
      await _sync.onAccountChanged(
        keepLocalProgress: choice == ConflictChoice.keepThisDevice,
      );
      return AccountLinkResult(AccountLinkStatus.linked, email: email);
    } on AccountBackendException catch (e) {
      if (e.code == 'cancelled') {
        return const AccountLinkResult(AccountLinkStatus.cancelled);
      }
      return AccountLinkResult(AccountLinkStatus.failed, code: e.code);
    }
  }

  /// Signs in on a device that has no pet of its own yet — the new-phone case.
  Future<AccountLinkResult> signIn(String email, String password) async {
    try {
      await _backend.signInEmailPassword(email, password);
      await _sync.onAccountChanged(keepLocalProgress: false);
      return AccountLinkResult(AccountLinkStatus.linked, email: email);
    } on AccountBackendException catch (e) {
      return AccountLinkResult(AccountLinkStatus.failed, code: e.code);
    }
  }
}

/// Provider errors, normalised so [AccountService] does not depend on
/// FirebaseAuth's exception type.
class AccountBackendException implements Exception {
  const AccountBackendException(this.code, [this.message, this.email]);

  final String code;
  final String? message;

  /// The address the failure was about, when the provider names one — a
  /// conflict prompt has to be able to say whose account it collided with.
  final String? email;

  @override
  String toString() => 'AccountBackendException($code): ${message ?? ''}';
}
