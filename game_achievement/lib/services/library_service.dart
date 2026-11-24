import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../core/utils/app_exception.dart';
import '../models/player_game.dart';

/// A player's game library (player_games collection).
class LibraryService {
  LibraryService._();
  static final instance = LibraryService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _ref(String id) =>
      _db.collection(FirestorePaths.playerGames).doc(id);

  Stream<List<PlayerGame>> watchLibrary(String uid) => _db
      .collection(FirestorePaths.playerGames)
      .where('player_id', isEqualTo: uid)
      .snapshots()
      .map((s) {
        final list = s.docs.map(PlayerGame.fromDoc).toList();
        list.sort((a, b) => (b.dateAdded ?? DateTime.now())
            .compareTo(a.dateAdded ?? DateTime.now()));
        return list;
      });

  Stream<PlayerGame?> watchEntry(String playerGameId) => _ref(playerGameId)
      .snapshots()
      .map((s) => s.exists ? PlayerGame.fromDoc(s) : null);

  Future<void> addGame({
    required String uid,
    required String gameId,
    String status = GameStatus.playing,
  }) async {
    final id = FirestorePaths.playerGameId(uid, gameId);
    final ref = _ref(id);
    await _db.runTransaction((tx) async {
      final existing = await tx.get(ref);
      if (existing.exists) {
        throw const AppException('This game is already in your library.');
      }
      tx.set(ref, {
        'player_game_id': id,
        'player_id': uid,
        'game_id': gameId,
        'playtime_hours': 0,
        'status': status,
        'total_points_earned': 0,
        'date_added': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateEntry(
    String playerGameId, {
    required String status,
    required double playtimeHours,
  }) =>
      _ref(playerGameId).update({
        'status': status,
        'playtime_hours': playtimeHours,
      });

  /// Removes the library entry AND its achievement progress
  /// (replaces SQL's ON DELETE CASCADE).
  Future<void> removeEntry({
    required String uid,
    required String playerGameId,
  }) async {
    final progress = await _db
        .collection(FirestorePaths.playerAchievements)
        .where('player_id', isEqualTo: uid)
        .where('player_game_id', isEqualTo: playerGameId)
        .get();

    final batch = _db.batch();
    for (final doc in progress.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_ref(playerGameId));
    await batch.commit();
  }
}
