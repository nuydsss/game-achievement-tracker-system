import 'package:cloud_firestore/cloud_firestore.dart';

/// player_games/{playerUid_gameId}  (one game in one player's library)
class PlayerGame {
  const PlayerGame({
    required this.playerGameId,
    required this.playerId,
    required this.gameId,
    required this.playtimeHours,
    required this.status,
    required this.totalPointsEarned,
    this.dateAdded,
  });

  final String playerGameId;
  final String playerId;
  final String gameId;
  final double playtimeHours;
  final String status; // playing | completed | on_hold | dropped
  final int totalPointsEarned;
  final DateTime? dateAdded;

  factory PlayerGame.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return PlayerGame(
      playerGameId: doc.id,
      playerId: d['player_id'] as String? ?? '',
      gameId: d['game_id'] as String? ?? '',
      playtimeHours: (d['playtime_hours'] as num?)?.toDouble() ?? 0,
      status: d['status'] as String? ?? 'playing',
      totalPointsEarned: (d['total_points_earned'] as num?)?.toInt() ?? 0,
      dateAdded: (d['date_added'] as Timestamp?)?.toDate(),
    );
  }
}
