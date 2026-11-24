/// Form field validators. Each returns an error message, or null when valid.
class Validators {
  Validators._();

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _usernameRegex = RegExp(r'^[a-z0-9_]{3,20}$');

  static String? email(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Use at least 8 characters';
    return null;
  }

  static String? confirmPassword(String? v, String original) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != original) return 'Passwords do not match';
    return null;
  }

  /// Usernames are stored lowercase: 3-20 chars, letters, numbers, underscore.
  static String? username(String? v) {
    final value = (v ?? '').trim().toLowerCase();
    if (value.isEmpty) return 'Username is required';
    if (!_usernameRegex.hasMatch(value)) {
      return '3-20 characters: letters, numbers, underscore';
    }
    return null;
  }

  static String? displayName(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Display name is required';
    if (value.length > 30) return 'Maximum 30 characters';
    return null;
  }

  static String? playtimeHours(String? v) {
    final value = double.tryParse(v?.trim() ?? '');
    if (value == null) return 'Enter a number';
    if (value < 0) return 'Cannot be negative';
    if (value > 100000) return 'That seems too high';
    return null;
  }
}
