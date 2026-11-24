import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../models/achievement.dart';
import '../models/game.dart';

/// Read-only access to the game + achievement catalog.
class GameService {
  GameService._();
  static final instance = GameService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Game>> watchGames() => _db
      .collection(FirestorePaths.games)
      .orderBy('game_name')
      .snapshots()
      .map((s) => s.docs.map(Game.fromDoc).toList());

  /// Achievements for one game, highest points first.
  /// (Sorted in the app so no composite Firestore index is needed.)
  Stream<List<Achievement>> watchAchievements(String gameId) => _db
      .collection(FirestorePaths.achievements)
      .where('game_id', isEqualTo: gameId)
      .snapshots()
      .map((s) {
        final list = s.docs.map(Achievement.fromDoc).toList();
        list.sort((a, b) => b.points.compareTo(a.points));
        return list;
      });
}
