import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Salted PBKDF2-HMAC-SHA256 password hashing.
///
/// Encoded as `pbkdf2_sha256$<iterations>$<salt b64>$<hash b64>`, so the
/// iteration count can be raised later without breaking existing hashes —
/// [verify] always uses the count stored alongside each hash.
class PasswordHasher {
  const PasswordHasher({this.iterations = 100000});

  /// Tests pass a small count; production keeps the default.
  final int iterations;

  static const _scheme = 'pbkdf2_sha256';
  static final _random = Random.secure();

  String hash(String password) {
    final salt = Uint8List.fromList(List.generate(16, (_) => _random.nextInt(256)));
    final derived = _pbkdf2(utf8.encode(password), salt, iterations);
    return '$_scheme\$$iterations\$${base64.encode(salt)}\$${base64.encode(derived)}';
  }

  bool verify(String password, String encoded) {
    final parts = encoded.split(r'$');
    if (parts.length != 4 || parts[0] != _scheme) return false;
    final storedIterations = int.tryParse(parts[1]);
    if (storedIterations == null || storedIterations < 1) return false;
    final List<int> salt;
    final List<int> expected;
    try {
      salt = base64.decode(parts[2]);
      expected = base64.decode(parts[3]);
    } on FormatException {
      return false;
    }
    final actual = _pbkdf2(utf8.encode(password), salt, storedIterations);
    return _constantTimeEquals(actual, expected);
  }

  /// Single-block PBKDF2 (32-byte output = one SHA-256 block, so the block
  /// index is always 1).
  static List<int> _pbkdf2(List<int> password, List<int> salt, int iterations) {
    final hmac = Hmac(sha256, password);
    var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final out = Uint8List.fromList(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < out.length; j++) {
        out[j] ^= u[j];
      }
    }
    return out;
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
