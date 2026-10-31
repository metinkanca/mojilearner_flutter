import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/secure_storage.dart';
import 'account_service.dart';
import 'cloud_sync.dart';
import 'notification_service.dart';

/// Wipes a player's data: "Reset App" and "Delete Account".
///
/// Both exist because erasing only what is on the phone is not erasing. The
/// save is mirrored to Firestore and restored onto any device with no save of
/// its own, so a reset that leaves the stored copy behind is undone by the next
/// launch, and an account deletion that leaves it behind has deleted nothing the
/// player can see. Both therefore go through the cloud copy first.
///
/// Wiping the in-memory state is not done here: every provider read storage
/// once at construction, so the caller restarts the app tree afterwards
/// (`AppRestart`).
class DataEraser {
  DataEraser({CloudSync? sync, AccountService? account, this.ready})
      : _sync = (() => sync),
        _account = (() => account);

  /// For an eraser built before sync has finished starting (a returning player
  /// opens the app without waiting for it): the sync and account are looked up
  /// when needed, and [ready] is awaited first. That wait is what stops a reset
  /// in the first moments from wiping the phone and then watching the late
  /// start restore the old save over it.
  DataEraser.lazy({
    required CloudSync? Function() sync,
    required AccountService? Function() account,
    required Future<void> Function() this.ready,
  })  : _sync = sync,
        _account = account;

  final CloudSync? Function() _sync;
  final AccountService? Function() _account;
  final Future<void> Function()? ready;

  /// Null when cloud sync never started, in which case there is nothing but the
  /// phone to wipe.
  CloudSync? get sync => _sync();
  AccountService? get account => _account();

  /// Starts again from the first screen, keeping the account.
  ///
  /// Never refused for being offline. If the stored save cannot be reached it
  /// is deleted on a later launch, and until then restoring is blocked.
  Future<void> resetProgress() async {
    await ready?.call();
    final cloudGone = await sync?.deleteCloudCopy() ?? true;
    await _wipeLocal();
    if (!cloudGone) await sync?.rememberPendingErase();
    await sync?.resumeAfterErase();
  }

  /// Deletes the stored save, the account, and everything on this device.
  ///
  /// Unlike a reset this needs a connection, because the account cannot be
  /// reached to be deleted any other way. [AccountDeleteStatus.failed] and
  /// [AccountDeleteStatus.needsPassword] leave the device untouched.
  Future<AccountDeleteStatus> deleteAccount({String? password}) async {
    await ready?.call();
    final account = this.account;
    if (account != null) {
      final status = await account.deleteAccount(password: password);
      if (status != AccountDeleteStatus.deleted) return status;
    }
    await _wipeLocal();
    // Under a brand-new anonymous identity, so the app keeps working.
    await sync?.resumeAfterErase();
    return AccountDeleteStatus.deleted;
  }

  Future<void> _wipeLocal() async {
    try {
      await NotificationService.I.cancelAll();
    } catch (e) {
      debugPrint('⚠️ ERASE: could not cancel reminders - $e');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    try {
      await SecureStorage.deleteAll();
    } catch (e) {
      // Prefs are already gone; the encrypted chats are the only thing left, so
      // say so rather than pretend all of it went.
      debugPrint('⚠️ ERASE: secure storage was not fully cleared - $e');
    }
  }
}
