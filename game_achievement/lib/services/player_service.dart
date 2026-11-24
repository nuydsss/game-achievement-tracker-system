import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../core/utils/app_exception.dart';
import '../models/player.dart';

class PlayerService {
  PlayerService._();
  static final instance = PlayerService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _ref(String uid) =>
      _db.collection(FirestorePaths.players).doc(uid);

  Stream<Player?> watchPlayer(String uid) =>
      _ref(uid).snapshots().map((s) => s.exists ? Player.fromDoc(s) : null);

  /// Creates players/{uid} and reserves the username in usernames/{username}.
  /// Firestore has no UNIQUE index, so the reservation doc + transaction
  /// guarantee two players can't claim the same username.
  Future<void> createPlayer({
    required String uid,
    required String email,
    required String username,
    required String displayName,
  }) async {
    final name = username.trim().toLowerCase();
    final nameRef = _db.collection(FirestorePaths.usernames).doc(name);

    await _db.runTransaction((tx) async {
      final taken = await tx.get(nameRef);
      if (taken.exists) {
        throw const AppException('That username is already taken.');
      }
      tx.set(nameRef, {'uid': uid});
      tx.set(_ref(uid), {
        'player_id': uid,
        'username': name,
        'email': email,
        'display_name': displayName.trim(),
        'status': 'active',
        'date_created': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateDisplayName(String uid, String displayName) =>
      _ref(uid).update({'display_name': displayName.trim()});

  Future<void> updatePhotoUrl(String uid, String photoUrl) =>
      _ref(uid).update({'photo_url': photoUrl});
}
