/// How the app reaches the AI answer/board engine.
enum AiMode {
  /// Talk to the Flyball backend, which holds the Gemini key server-side.
  backend,

  /// Call Gemini directly from the app with a compiled-in key. Simpler to set
  /// up (no server to run) but the key is extractable from the app binary —
  /// fine for personal/local use, not recommended for a public release.
  direct,

  /// Neither is configured — the app has no way to answer anything.
  none,
}

/// App-wide runtime configuration, read from compile-time `--dart-define`
/// values (see `dart_define.example.json`).
class AppConfig {
  AppConfig._();

  /// Base URL of the Flyball backend (holds the Gemini key server-side).
  /// Takes priority over [geminiApiKey] when both are set.
  ///
  /// ```
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.23:8080
  /// # From an Android emulator, reach the host with 10.0.2.2:
  /// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
  /// ```
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// A Gemini API key compiled directly into the app (get one free at
  /// https://aistudio.google.com/apikey). Used only when [apiBaseUrl] is
  /// empty. NOT secret-safe — see [AiMode.direct].
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// Gemini model id, only used in [AiMode.direct].
  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );

  static AiMode get aiMode {
    if (apiBaseUrl.isNotEmpty) return AiMode.backend;
    if (geminiApiKey.isNotEmpty) return AiMode.direct;
    return AiMode.none;
  }

  static bool get hasAi => aiMode != AiMode.none;
}
