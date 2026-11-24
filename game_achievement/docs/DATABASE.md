# Firestore design (adapted from the MongoDB-style reference)

| Collection | Document ID | Notes |
|---|---|---|
| `players` | Firebase Auth **UID** | username, email, display_name, status, date_created, photo_url |
| `usernames` | the lowercase username | `{uid}`; reservation doc for unique usernames |
| `games` | `GAME-G001` | read-only catalog |
| `achievements` | `ACH-001` | read-only catalog, `game_id` -> games |
| `player_games` | `{uid}_{gameId}` | playtime_hours, status, total_points_earned, date_added |
| `player_achievements` | `{playerGameId}_{achievementId}` | progress_percent, is_unlocked, date_unlocked, **player_id** |

## Changes from the reference, and why

1. **`password_hash` removed.** Firebase Authentication stores credentials. Never keep passwords or hashes in Firestore.
2. **`players` ID = Auth UID** (was `PLR-001`), so security rules can compare `request.auth.uid` to the document ID. `player_id` still exists and equals the UID. `photo_url` added for Storage.
3. **`usernames` collection added.** Firestore has no UNIQUE index (Mongo had a unique index), so a reservation document written in the same transaction enforces uniqueness.
4. **`player_id` added to `player_achievements`.** Rules and queries can't cheaply "join" through `player_games`, so the owner ID is stored on each progress document.
5. **Deterministic IDs** for `player_games` and `player_achievements` (instead of `PG-001`/`PA-001` counters). Firestore has no auto-increment; these IDs also stop duplicates.
6. **Progress documents are created lazily**, only when a player first updates an achievement.

## MongoDB -> Firestore mapping

| MongoDB feature | Firestore replacement |
|---|---|
| `$jsonSchema` validators | Security rules (`validEntry`, `validProgress`) |
| Unique index | `usernames` reservation + transaction |
| `$lookup` / joins | Second query by ID, done in the app |
| `aggregate` (leaderboards, totals) | Computed in the app from the player's own documents |
| `$inc` | `FieldValue.increment` |
| SQL trigger / unlock logic | Transaction in `AchievementService.setProgress` |
| `ON DELETE CASCADE` | Batch delete in `LibraryService.removeEntry` |

## Known limitations

- Points are computed on the client, so a determined user could edit their own points. Fine for a personal tracker; for a public leaderboard move this into a Cloud Function.
- A global leaderboard across players is not possible with these rules (each player can read only their own data).
