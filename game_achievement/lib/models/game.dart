import 'package:cloud_firestore/cloud_firestore.dart';

/// games/{gameId}  (read-only catalog)
class Game {
  const Game({
    required this.gameId,
    required this.gameCode,
    required this.gameName,
    required this.genre,
    required this.developer,
    required this.totalAchievements,
    required this.tags,
  });

  final String gameId;
  final String gameCode;
  final String gameName;
  final String genre;
  final String developer;
  final int totalAchievements;
  final List<String> tags;

  factory Game.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return Game(
      gameId: doc.id,
      gameCode: d['game_code'] as String? ?? '',
      gameName: d['game_name'] as String? ?? 'Unknown game',
      genre: d['genre'] as String? ?? '',
      developer: d['developer'] as String? ?? '',
      totalAchievements: (d['total_achievements'] as num?)?.toInt() ?? 0,
      tags: List<String>.from(d['tags'] as List? ?? const []),
    );
  }
}
