import 'dart:convert';

/// Parses Gemini `generateContent` responses.
///
/// With Google Search grounding the model returns free text (no enforced JSON
/// mime type), possibly across multiple `parts` and wrapped in markdown or
/// prose, so callers concatenate all text parts and pull the JSON object out
/// of it.
class GeminiParser {
  GeminiParser._();

  /// Extracts the list of player names from a `{"players": [...]}` shaped
  /// response. Returns `null` if no usable shape can be recovered (no
  /// candidates / wrong shape / truncated / missing key). A present-but-empty
  /// `players` array returns an empty list, NOT `null`, so a caller can tell a
  /// successful "found/confirmed nobody" apart from a failed request.
  static List<String>? parsePlayers(String responseBody) {
    final obj = _extractResponseJson(responseBody, key: 'players');
    if (obj == null) return null;
    final players = obj['players'];
    if (players is! List) return null;
    return players
        .map((e) {
          if (e is String) return e;
          if (e is Map) return e['name']?.toString() ?? '';
          return e.toString();
        })
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .toList();
  }

  /// Extracts a `{"cells": [{"players": [...]}, ...]}` shaped response (used
  /// by the board builder to verify all 9 cells in one call). Returns `null`
  /// on any parse failure; otherwise a list of per-cell player-name lists
  /// (padded with empty lists if the model returned fewer than [expectedCells]).
  static List<List<String>>? parseCells(
    String responseBody, {
    required int expectedCells,
  }) {
    final obj = _extractResponseJson(responseBody, key: 'cells');
    if (obj == null) return null;
    final cells = obj['cells'];
    if (cells is! List) return null;
    return List.generate(expectedCells, (i) {
      if (i >= cells.length) return const <String>[];
      final cell = cells[i];
      if (cell is! Map) return const <String>[];
      final players = cell['players'];
      if (players is! List) return const <String>[];
      return players.map((e) => e.toString().trim()).where((n) => n.isNotEmpty).toList();
    });
  }

  /// Decodes the outer Gemini envelope, stitches together all text parts,
  /// slices out the first-to-last `{`…`}` span, and decodes THAT as JSON,
  /// checking it contains [key]. Returns null on any failure along the way,
  /// including a `MAX_TOKENS` finish reason (a truncated answer yields a
  /// partial/invalid list — better to discard and let the caller fall back).
  static Map<String, dynamic>? _extractResponseJson(
    String responseBody, {
    required String key,
  }) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) return null;

      final candidates = decoded['candidates'];
      if (candidates is! List || candidates.isEmpty) return null;
      final first = candidates.first;
      if (first is! Map) return null;
      if (first['finishReason'] == 'MAX_TOKENS') return null;
      final content = first['content'];
      if (content is! Map) return null;
      final parts = content['parts'];
      if (parts is! List || parts.isEmpty) return null;

      final text = parts
          .whereType<Map>()
          .map((p) => p['text'])
          .whereType<String>()
          .join();
      if (text.isEmpty) return null;

      final inner = _extractJsonObject(text);
      if (inner == null || !inner.containsKey(key)) return null;
      return inner;
    } catch (_) {
      return null;
    }
  }

  /// Recovers the first JSON object embedded in [text], tolerating markdown
  /// code fences and surrounding prose by slicing from the first `{` to the
  /// last `}`. Returns `null` if that span does not decode to a JSON map.
  static Map<String, dynamic>? _extractJsonObject(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end <= start) return null;
    try {
      final decoded = jsonDecode(text.substring(start, end + 1));
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}
