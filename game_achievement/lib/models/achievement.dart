import 'package:cloud_firestore/cloud_firestore.dart';

/// achievements/{achievementId}  (read-only catalog)
class Achievement {
  const Achievement({
    required this.achievementId,
    required this.gameId,
    required this.name,
    required this.description,
    required this.points,
    required this.difficulty,
    required this.isHidden,
  });

  final String achievementId;
  final String gameId;
  final String name;
  final String description;
  final int points;
  final String difficulty; // easy | medium | hard | legendary
  final bool isHidden;

  factory Achievement.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return Achievement(
      achievementId: doc.id,
      gameId: d['game_id'] as String? ?? '',
      name: d['achievement_name'] as String? ?? '',
      description: d['description'] as String? ?? '',
      points: (d['points'] as num?)?.toInt() ?? 0,
      difficulty: d['difficulty'] as String? ?? 'easy',
      isHidden: d['is_hidden'] as bool? ?? false,
    );
  }
}
