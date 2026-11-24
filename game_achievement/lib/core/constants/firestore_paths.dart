/// Collection names and document-ID helpers, so strings live in ONE place.
class FirestorePaths {
  FirestorePaths._();

  static const players = 'players';
  static const usernames = 'usernames';
  static const games = 'games';
  static const achievements = 'achievements';
  static const playerGames = 'player_games';
  static const playerAchievements = 'player_achievements';

  /// Library entry ID: one per (player, game), so a game can't be added twice.
  static String playerGameId(String uid, String gameId) => '${uid}_$gameId';

  /// Progress doc ID: one per (library entry, achievement).
  static String playerAchievementId(String playerGameId, String achievementId) =>
      '${playerGameId}_$achievementId';
}

/// Allowed values for player_games.status (matches the database reference).
class GameStatus {
  GameStatus._();

  static const playing = 'playing';
  static const completed = 'completed';
  static const onHold = 'on_hold';
  static const dropped = 'dropped';

  static const all = [playing, completed, onHold, dropped];

  static String label(String status) {
    switch (status) {
      case playing:
        return 'Playing';
      case completed:
        return 'Completed';
      case onHold:
        return 'On hold';
      case dropped:
        return 'Dropped';
      default:
        return status;
    }
  }
}
