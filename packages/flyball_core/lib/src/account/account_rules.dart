/// Why a username/password was rejected. The same codes are sent by the
/// backend as `{"error": "<code>"}` and mapped to localized text in the app.
abstract final class AccountErrors {
  static const invalidUsername = 'invalid_username';
  static const weakPassword = 'weak_password';
  static const invalidDisplayName = 'invalid_display_name';
  static const usernameTaken = 'username_taken';
  static const invalidCredentials = 'invalid_credentials';
  static const tooManyAttempts = 'too_many_attempts';
  static const unauthorized = 'unauthorized';
}

/// Sign-up rules shared by the app (instant form validation) and the backend
/// (the authoritative check), so the two can never disagree.
abstract final class AccountRules {
  static const usernameMinLength = 3;
  static const usernameMaxLength = 20;
  static const passwordMinLength = 8;
  static const passwordMaxLength = 128;
  static const displayNameMaxLength = 24;

  static final _usernamePattern = RegExp(r'^[A-Za-z0-9_.]+$');

  /// Returns an [AccountErrors] code, or `null` if [username] is acceptable.
  /// Letters, digits, `_` and `.` only — no spaces or accents, so a login
  /// name types the same on every keyboard.
  static String? validateUsername(String username) {
    if (username.length < usernameMinLength ||
        username.length > usernameMaxLength ||
        !_usernamePattern.hasMatch(username)) {
      return AccountErrors.invalidUsername;
    }
    return null;
  }

  /// Returns an [AccountErrors] code, or `null` if [password] is acceptable.
  static String? validatePassword(String password) {
    if (password.length < passwordMinLength ||
        password.length > passwordMaxLength) {
      return AccountErrors.weakPassword;
    }
    return null;
  }

  /// Returns an [AccountErrors] code, or `null` if [displayName] (already
  /// trimmed) is acceptable.
  static String? validateDisplayName(String displayName) {
    if (displayName.isEmpty || displayName.length > displayNameMaxLength) {
      return AccountErrors.invalidDisplayName;
    }
    return null;
  }
}
