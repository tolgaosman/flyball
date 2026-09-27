import 'dart:io';

import 'package:path/path.dart' as p;

/// Server-side configuration, read once from environment variables at
/// startup. The Gemini key lives ONLY here — it is never sent to, or read
/// from, the Flutter app.
class EnvConfig {
  EnvConfig({
    required this.geminiApiKey,
    required this.geminiModel,
    required this.port,
    required this.cacheDbPath,
    required this.userDbPath,
  });

  factory EnvConfig.fromEnvironment() {
    final env = Map<String, String>.from(Platform.environment);
    
    final envFile = File('.env');
    if (envFile.existsSync()) {
      for (final line in envFile.readAsLinesSync()) {
        if (line.trim().isEmpty || line.startsWith('#')) continue;
        final parts = line.split('=');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final value = parts.sublist(1).join('=').trim();
          env[key] = value;
        }
      }
    }

    return EnvConfig(
      geminiApiKey: env['GEMINI_API_KEY'] ?? '',
      geminiModel: env['GEMINI_MODEL'] ?? 'gemini-2.5-flash',
      port: int.tryParse(env['PORT'] ?? '') ?? 8080,
      cacheDbPath: env['CACHE_DB_PATH'] ??
          p.join(Directory.current.path, 'data', 'flyball_cache.db'),
      userDbPath: env['USER_DB_PATH'] ??
          p.join(Directory.current.path, 'data', 'flyball_users.db'),
    );
  }

  final String geminiApiKey;
  final String geminiModel;
  final int port;
  final String cacheDbPath;

  /// Accounts + sessions. Kept apart from [cacheDbPath] on purpose: the cache
  /// is safe to delete, this file is not.
  final String userDbPath;

  bool get hasGeminiKey => geminiApiKey.isNotEmpty;
}
