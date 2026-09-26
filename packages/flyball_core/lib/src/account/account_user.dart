/// A signed-up Flyball account, as the backend returns it and the app keeps
/// it. Never carries the password (or its hash) — that stays server-side.
class AccountUser {
  const AccountUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.createdAt,
  });

  final int id;

  /// Unique, case-insensitive login name (see [AccountRules.validateUsername]).
  final String username;

  /// Name shown in the UI. Defaults to [username] at sign-up.
  final String displayName;

  final DateTime createdAt;

  factory AccountUser.fromJson(Map<String, dynamic> json) => AccountUser(
        id: (json['id'] as num).toInt(),
        username: json['username'] as String,
        displayName: json['displayName'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (json['createdAt'] as num).toInt(),
          isUtc: true,
        ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'displayName': displayName,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };
}
