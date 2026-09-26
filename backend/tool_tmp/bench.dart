import '../lib/password_hasher.dart';
void main() {
  final sw = Stopwatch()..start();
  const PasswordHasher().hash('password1');
  print('hash ms: ${sw.elapsedMilliseconds}');
}
