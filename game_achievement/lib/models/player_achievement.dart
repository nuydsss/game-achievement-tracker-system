import 'package:cloud_firestore/cloud_firestore.dart';

/// player_achievements/{playerGameId_achievementId}
class PlayerAchievement {
  const PlayerAchievement({
    required this.id,
    required this.playerGameId,
    required this.achievementId,
    required this.progressPercent,
    required this.isUnlocked,
    this.dateUnlocked,
  });

  final String id;
  final String playerGameId;
  final String achievementId;
  final int progressPercent; // 0..100
  final bool isUnlocked;
  final DateTime? dateUnlocked;

  factory PlayerAchievement.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return PlayerAchievement(
      id: doc.id,
      playerGameId: d['player_game_id'] as String? ?? '',
      achievementId: d['achievement_id'] as String? ?? '',
      progressPercent: (d['progress_percent'] as num?)?.toInt() ?? 0,
      isUnlocked: d['is_unlocked'] as bool? ?? false,
      dateUnlocked: (d['date_unlocked'] as Timestamp?)?.toDate(),
    );
  }
}
