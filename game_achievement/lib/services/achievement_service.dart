import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../models/achievement.dart';
import '../models/player_achievement.dart';

/// Achievement progress (player_achievements collection).
class AchievementService {
  AchievementService._();
  static final instance = AchievementService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Progress docs for one library entry, keyed by achievement ID.
  /// Achievements the player hasn't touched yet simply have no document.
  Stream<Map<String, PlayerAchievement>> watchProgress({
    required String uid,
    required String playerGameId,
  }) =>
      _db
          .collection(FirestorePaths.playerAchievements)
          .where('player_id', isEqualTo: uid)
          .where('player_game_id', isEqualTo: playerGameId)
          .snapshots()
          .map((s) => {
                for (final doc in s.docs)
                  (doc.data()['achievement_id'] as String? ?? doc.id):
                      PlayerAchievement.fromDoc(doc),
              });

  /// Saves progress and keeps player_games.total_points_earned in sync.
  /// This is the Firestore replacement for the SQL trigger trg_unlock_achievement:
  /// at 100% the achievement unlocks (date stamped) and its points are added;
  /// dropping back below 100% removes those points again.
  Future<void> setProgress({
    required String uid,
    required String playerGameId,
    required Achievement achievement,
    required int percent,
  }) async {
    final String id =
        FirestorePaths.playerAchievementId(playerGameId, achievement.achievementId);
    final DocumentReference<Map<String, dynamic>> progressRef =
        _db.collection(FirestorePaths.playerAchievements).doc(id);
    final DocumentReference<Map<String, dynamic>> entryRef =
        _db.collection(FirestorePaths.playerGames).doc(playerGameId);
    final int value = percent.clamp(0, 100).toInt();

    await _db.runTransaction((Transaction tx) async {
      final DocumentSnapshot<Map<String, dynamic>> snap = await tx.get(progressRef);
      final Map<String, dynamic> old = snap.data() ?? <String, dynamic>{};
      final bool wasUnlocked = old['is_unlocked'] == true;
      final bool nowUnlocked = value == 100;

      int pointsDelta = 0;
      if (nowUnlocked && !wasUnlocked) pointsDelta = achievement.points;
      if (!nowUnlocked && wasUnlocked) pointsDelta = -achievement.points;

      // Keep the original unlock date if it was already unlocked,
      // stamp the server time on a new unlock, or null below 100%.
      final Object? dateUnlocked = !nowUnlocked
          ? null
          : (wasUnlocked ? old['date_unlocked'] : FieldValue.serverTimestamp());

      tx.set(progressRef, <String, dynamic>{
        'player_achievement_id': id,
        'player_game_id': playerGameId,
        'achievement_id': achievement.achievementId,
        'player_id': uid,
        'progress_percent': value,
        'is_unlocked': nowUnlocked,
        'date_unlocked': dateUnlocked,
      });

      if (pointsDelta != 0) {
        tx.update(entryRef, <String, dynamic>{
          'total_points_earned': FieldValue.increment(pointsDelta),
        });
      }
    });
  }
}
