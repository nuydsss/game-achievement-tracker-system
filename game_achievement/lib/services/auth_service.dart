import 'package:firebase_auth/firebase_auth.dart';

import 'player_service.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Current user's UID (empty string if signed out).
  String get uid => _auth.currentUser?.uid ?? '';

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  /// Creates the Auth account, then the players/{uid} document.
  /// If the player document can't be created (e.g. username taken),
  /// the new Auth account is removed so nothing is left half-created.
  Future<void> register({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;
    try {
      await PlayerService.instance.createPlayer(
        uid: user.uid,
        email: email.trim(),
        username: username,
        displayName: displayName,
      );
    } catch (_) {
      await user.delete();
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() => _auth.signOut();
}
