import 'package:flyball_core/flyball_core.dart';
import 'package:test/test.dart';

void main() {
  group('AccountRules.validateUsername', () {
    test('accepts letters, digits, underscore and dot', () {
      expect(AccountRules.validateUsername('osman_10'), isNull);
      expect(AccountRules.validateUsername('a.b'), isNull);
    });

    test('rejects too short, too long, spaces and accents', () {
      for (final bad in ['ab', 'a' * 21, 'osman tolga', 'özil', 'x@y']) {
        expect(AccountRules.validateUsername(bad), AccountErrors.invalidUsername, reason: bad);
      }
    });
  });

  test('validatePassword enforces the minimum length', () {
    expect(AccountRules.validatePassword('1234567'), AccountErrors.weakPassword);
    expect(AccountRules.validatePassword('12345678'), isNull);
  });

  test('validateDisplayName rejects empty and over-long names', () {
    expect(AccountRules.validateDisplayName(''), AccountErrors.invalidDisplayName);
    expect(AccountRules.validateDisplayName('x' * 25), AccountErrors.invalidDisplayName);
    expect(AccountRules.validateDisplayName('İlkay'), isNull);
  });

  test('AccountUser round-trips through JSON', () {
    final user = AccountUser(
      id: 7,
      username: 'osman',
      displayName: 'Osman',
      createdAt: DateTime.utc(2026, 9, 26, 12),
    );
    final back = AccountUser.fromJson(user.toJson());
    expect(back.id, 7);
    expect(back.username, 'osman');
    expect(back.displayName, 'Osman');
    expect(back.createdAt, user.createdAt);
  });
}
