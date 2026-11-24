import 'package:cloud_firestore/cloud_firestore.dart';

/// players/{authUid}
class Player {
  const Player({
    required this.playerId,
    required this.username,
    required this.email,
    required this.displayName,
    required this.status,
    this.photoUrl,
    this.dateCreated,
  });

  final String playerId; // = Firebase Auth UID
  final String username;
  final String email;
  final String displayName;
  final String status; // active | inactive | banned
  final String? photoUrl;
  final DateTime? dateCreated;

  factory Player.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return Player(
      playerId: doc.id,
      username: d['username'] as String? ?? '',
      email: d['email'] as String? ?? '',
      displayName: d['display_name'] as String? ?? '',
      status: d['status'] as String? ?? 'active',
      photoUrl: d['photo_url'] as String?,
      dateCreated: (d['date_created'] as Timestamp?)?.toDate(),
    );
  }
}
