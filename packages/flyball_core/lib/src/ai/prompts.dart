import 'dart:convert';

/// Builds the prompts sent to Gemini for answer search and board building.
/// Centralised so every caller (party games, XOX reveal, board builder) gets
/// the same date-anchoring and club-alias rules.
class Prompts {
  Prompts._();

  /// Today's date as `YYYY-MM-DD`, so a prompt always anchors "recent" to the
  /// real current date instead of a year that goes stale after one transfer
  /// window.
  static String todayIso() => DateTime.now().toIso8601String().substring(0, 10);

  /// A human label for the most recently completed (or currently open)
  /// transfer window, computed from the current month so it never needs
  /// manual updates across seasons.
  static String currentWindowLabel() {
    final now = DateTime.now();
    final year = now.year;
    if (now.month <= 5) return 'January $year transfer window';
    return 'summer $year transfer window';
  }

  static const _clubAliasRule =
      '- Treat club name variants as the SAME club: "Leipzig" = "RB Leipzig", '
      '"Man United"/"Man Utd" = "Manchester United", "Inter" = "Internazionale", '
      '"PSG" = "Paris Saint-Germain", "Basaksehir" = "Istanbul Basaksehir", '
      'etc. Search under every common form of the name.\n';

  static const _sourcePreferenceRule =
      '- PREFER Wikipedia and Transfermarkt (transfermarkt.com) among your web '
      'search results for player profiles, clubs, nationalities, transfer '
      'history and trophies — they are the most reliable and up to date for '
      'this. Use other sources too when useful, but resolve conflicts in '
      'favor of what Transfermarkt or Wikipedia say.\n';

  /// PHASE 1 prompt — wide recall. Explicitly tells the model to over-include
  /// and NOT filter, so it never drops a correct-but-uncertain name (a later
  /// pass removes the wrong ones).
  static String recall(String condition1, String condition2) {
    return 'Act as an expert football researcher building a CANDIDATE list. '
        'Your ONLY job right now is RECALL, not verification. List every '
        'real-life footballer (senior men\'s or women\'s professional) who '
        'MIGHT satisfy BOTH of these conditions:\n'
        '1. "$condition1"\n'
        '2. "$condition2"\n\n'
        'RULES:\n'
        '- USE WEB SEARCH and think broadly. Include well-known players, '
        'lesser-known ones, retired ones, loanees, and anyone you are even '
        'reasonably unsure about. OVER-INCLUDE on purpose.\n'
        '- Do NOT filter, drop, or self-censor names at this stage. A separate '
        'verification step will remove the wrong ones later, so it is far better '
        'to list a borderline name than to omit a correct one.\n'
        '- INCLUDE the most recent season\'s transfers, brand-new signings and '
        'loan moves — today is ${todayIso()}, so treat any transfer completed '
        'on or before that date, including the ${currentWindowLabel()}, as '
        'valid and current. Recent arrivals are a common source of missed '
        'answers, so make a point of covering them.\n'
        '$_clubAliasRule'
        '$_sourcePreferenceRule'
        '- Only requirement: each name must be a real footballer who plausibly '
        'has some connection to BOTH conditions. Do not invent people.\n'
        '- A condition naming a tournament (e.g. "Champions League", "World '
        'Cup") refers to a player who WON it.\n'
        '- Respond with ONLY raw JSON, no markdown fences and no commentary, in '
        'exactly this shape: {"players": ["Full Name", "Full Name"]}.';
  }

  /// PHASE 2 prompt — coverage-first verification. Takes the recall
  /// [candidates] and keeps every name with a plausible link to BOTH
  /// conditions, dropping ONLY the ones it can positively rule out.
  static String verify(
    List<String> candidates,
    String condition1,
    String condition2,
  ) {
    final list = jsonEncode(candidates);
    return 'Act as a football fact-checker whose PRIORITY IS COVERAGE. Below is a '
        'CANDIDATE list of footballers. For EACH name, use WEB SEARCH to assess '
        'whether that player plausibly satisfies BOTH conditions:\n'
        '1. "$condition1"\n'
        '2. "$condition2"\n\n'
        'CANDIDATES: $list\n\n'
        'RULES:\n'
        '- KEEP a name if sources show a REASONABLE, LIKELY link to BOTH '
        'conditions — an actual spell, an announced/completed transfer, or a '
        'loan. You do NOT need ironclad proof; a credible connection is enough.\n'
        '- DROP a name ONLY when you can POSITIVELY rule it out — it is clearly a '
        'different player with a similar name, a transfer that never happened, or '
        'someone with no real connection to one of the conditions. When genuinely '
        'unsure, KEEP it.\n'
        '$_clubAliasRule'
        '$_sourcePreferenceRule'
        '- Count the MOST RECENT season\'s transfers, new signings and loans as '
        'valid — today is ${todayIso()}, so a move completed on or before that '
        'date, including the ${currentWindowLabel()}, is current. Do not drop a '
        'player just because the move is recent.\n'
        '- Do NOT add any new names that are not in the candidate list.\n'
        '- A condition naming a tournament (e.g. "Champions League", "World '
        'Cup") means the player WON it.\n'
        '- Respond with ONLY raw JSON, no markdown fences and no commentary, in '
        'exactly this shape: {"players": ["Full Name", "Full Name"]}.';
  }

  /// Board-building prompt: for a full 3×3 grid of (row × column) condition
  /// pairs, ask for 1–3 confirmed real players per cell (or an empty list if
  /// none exist), in one call. [rowLabels] and [colLabels] each have length 3;
  /// cells are requested in row-major order (row0×col0, row0×col1, …).
  static String boardCells(List<String> rowLabels, List<String> colLabels) {
    final pairs = <String>[];
    for (final r in rowLabels) {
      for (final c in colLabels) {
        pairs.add('"$r" AND "$c"');
      }
    }
    final numbered =
        [for (var i = 0; i < pairs.length; i++) '${i + 1}. ${pairs[i]}'].join('\n');
    return 'Act as an expert football researcher. Below are 9 pairs of '
        'conditions (a trivia-grid cell). For EACH pair, use WEB SEARCH and '
        'find 1 to 3 REAL footballers who satisfy BOTH conditions in that pair. '
        'If you cannot find any real player for a pair, return an empty list '
        'for it — do NOT invent one.\n\n'
        '$numbered\n\n'
        'RULES:\n'
        '$_clubAliasRule'
        '$_sourcePreferenceRule'
        '- A condition naming a tournament (e.g. "Won World Cup") means the '
        'player WON it. A condition naming just a country is a nationality.\n'
        '- Today is ${todayIso()}; count transfers up to and including the '
        '${currentWindowLabel()} as current.\n'
        '- Respond with ONLY raw JSON, no markdown fences and no commentary, in '
        'exactly this shape, with exactly 9 entries in the SAME order as above: '
        '{"cells": [{"players": ["Full Name"]}, {"players": []}, ...]}.';
  }
}
