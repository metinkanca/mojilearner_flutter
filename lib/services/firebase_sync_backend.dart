import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'cloud_sync.dart';

/// [CloudSyncBackend] against Firebase: anonymous auth plus one document per
/// player at `users/{uid}`.
///
/// Anonymous on purpose. The problem being solved is "I reinstalled and my pet
/// is gone", and that needs an identity, not a login screen — a sign-in wall
/// in front of a pet game costs more players than it saves. Offering Google
/// sign-in also obliges an equivalent private option on iOS under App Store
/// guideline 4.8, so it is roughly twice the work and belongs in the later
/// account-linking step, where `linkWithCredential` upgrades this same uid and
/// nothing stored here has to move.
class FirebaseSyncBackend implements CloudSyncBackend {
  FirebaseSyncBackend({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const String _collection = 'users';

  @override
  Future<String?> signIn() async {
    try {
      final existing = _auth.currentUser;
      if (existing != null) return existing.uid;
      final credential = await _auth.signInAnonymously();
      return credential.user?.uid;
    } catch (e) {
      // No identity means no sync, and no sync means the app behaves exactly
      // as it did before any of this existed: local saves, nothing lost.
      debugPrint('⚠️ SYNC: anonymous sign-in failed - $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> fetch(String uid) async {
    final doc = await _firestore.collection(_collection).doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  @override
  Future<void> upload(String uid, Map<String, dynamic> data) {
    // set() without merge: the document *is* the snapshot, so a key removed
    // locally should disappear here too. One document, one write.
    return _firestore.collection(_collection).doc(uid).set(data);
  }
}
