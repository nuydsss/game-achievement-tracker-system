import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// An error whose message is already safe to show to the user.
class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Turns any thrown object into a short, user-friendly message.
String friendlyError(Object error) {
  if (error is AppException) return error.message;

  // FirebaseAuthException extends FirebaseException, so check it first.
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with that email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to do that.';
      case 'unavailable':
        return 'Service unavailable. Check your connection and try again.';
      case 'not-found':
        return 'That item no longer exists.';
      case 'canceled':
        return 'The operation was cancelled.';
      default:
        return error.message ?? 'Something went wrong. Please try again.';
    }
  }

  return 'Something went wrong. Please try again.';
}
