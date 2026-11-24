# Game Achievement Tracker System (Flutter + Firebase, Android)

Track your game library and achievement progress.
Stack: Flutter, Firebase Authentication, Cloud Firestore, Firebase Storage.
Package / Android application ID: `com.example.game_achievement`

## Folder structure

```
lib/
  main.dart, app.dart, firebase_options.dart (placeholder, see step 2)
  core/        constants (collection names), theme, utils (validators, error messages)
  models/      Player, Game, Achievement, PlayerGame, PlayerAchievement
  services/    auth, player, game, library, achievement, storage (ALL Firebase calls live here)
  widgets/     reusable widgets and dialogs
  screens/     auth/ home/ library/ browse/ profile/
android/          Android project (INTERNET permission already added)
firestore.rules   Firestore security rules
storage.rules     Storage security rules
firebase.json     used by `firebase deploy` for the two rules files
tools/seed/       Node script that loads the games + achievements catalog
docs/DATABASE.md  How the MongoDB-style design was adapted to Firestore
```

## Setup

1. `flutter pub get`
2. **Connect Firebase** (console.firebase.google.com)
   - Create a project. Authentication > Sign-in method > enable **Email/Password**.
   - Build > Firestore Database > Create database (production mode).
   - Build > Storage > Get started (new projects may require the Blaze plan; only profile pictures need it).
   - In this folder run:
     ```
     npm install -g firebase-tools
     firebase login
     dart pub global activate flutterfire_cli
     flutterfire configure
     ```
     Select your project and **Android** only. When asked, overwrite `lib/firebase_options.dart`.
     It registers the app `com.example.game_achievement` and adds `google-services.json`.
3. **Deploy the security rules**
   ```
   firebase use --add
   firebase deploy --only firestore:rules,storage
   ```
4. **Seed the catalog** (games + achievements; the app cannot write these):
   - Firebase console > Project settings > Service accounts > Generate new private key
   - Save it as `tools/seed/serviceAccountKey.json` (git-ignored)
   - `cd tools/seed && npm install && node seed.js`
5. Start an Android emulator (or plug in a phone with USB debugging) and run `flutter run`.

## How the app works

- **Register**: creates the Auth account, then `players/{uid}` and a `usernames/{username}` reservation (unique usernames) in one transaction.
- **Library**: `player_games/{uid}_{gameId}`; removing a game also deletes its progress.
- **Progress**: `player_achievements/{playerGameId}_{achievementId}`. Hitting 100% unlocks it and adds points to `total_points_earned` (replaces the SQL trigger).
- **Profile picture**: uploaded to `profile_pictures/{uid}/...`, URL saved in `players.photo_url`.

Note: this code was written without a Flutter SDK available to compile it, so expect to fix small
version-specific issues on the first `flutter run` / `flutter analyze`.
