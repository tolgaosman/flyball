import 'dart:convert';

import 'package:http/http.dart' as http;

/// Everything needed to talk to Gemini: which model, and (for
/// [DirectGeminiTransport]) the API key.
class GeminiConfig {
  const GeminiConfig({required this.model, this.apiKey = ''});

  final String model;
  final String apiKey;

  bool get hasKey => apiKey.isNotEmpty;

  static const defaultModel = 'gemini-2.5-flash';
}

/// Sends one grounded `generateContent` request and returns Gemini's raw JSON
/// response body, or `null` on any transport failure (network, timeout,
/// non-200). Kept as an interface so the backend (real key, server-side) and
/// the frontend's "direct" mode (key via `--dart-define`) share one
/// implementation, and so tests can inject a fake.
abstract class GeminiTransport {
  Future<String?> generateContent({
    required String prompt,
    required int thinkingBudget,
    required int maxOutputTokens,
  });
}

/// Thrown by [DirectGeminiTransport] instead of returning `null` when Gemini
/// responds with HTTP 429 (quota/rate-limit exhausted) — distinct from every
/// other failure (network, timeout, malformed response), which still returns
/// `null` as before. Callers that don't care about the distinction can leave
/// it uncaught: it propagates past retry loops that only check for `null`,
/// which is the point — retrying a call that's guaranteed to fail the same
/// way just wastes what quota may still exist.
class GeminiQuotaExceededException implements Exception {
  const GeminiQuotaExceededException();
}

/// Calls the Gemini API directly (`v1beta/models/<model>:generateContent`)
/// with the Google Search grounding tool attached. Used server-side by the
/// backend (where the key never leaves the server) and optionally by the
/// frontend when a `GEMINI_API_KEY` is compiled in directly.
class DirectGeminiTransport implements GeminiTransport {
  DirectGeminiTransport(this.config, {http.Client? client, Duration? timeout})
      : _client = client ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 60);

  final GeminiConfig config;
  final http.Client _client;
  final Duration _timeout;

  @override
  Future<String?> generateContent({
    required String prompt,
    required int thinkingBudget,
    required int maxOutputTokens,
  }) async {
    if (!config.hasKey) return null;
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '${config.model}:generateContent?key=${config.apiKey}',
    );
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'tools': [
        {'google_search': {}},
      ],
      'generationConfig': {
        'temperature': 0.2,
        'thinkingConfig': {'thinkingBudget': thinkingBudget},
        'maxOutputTokens': maxOutputTokens,
      },
    });

    final http.Response res;
    try {
      res = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(_timeout);
    } catch (_) {
      return null;
    }
    if (res.statusCode == 429) throw const GeminiQuotaExceededException();
    if (res.statusCode != 200) return null;
    return res.body;
  }
}
