import '../model/answer_result.dart';
import 'gemini_parser.dart';
import 'gemini_transport.dart';
import 'prompts.dart';

/// Finds live **reference answers** for a party-game round or XOX cell from
/// Google Gemini, aiming for **maximum coverage with zero hallucinations** via
/// two grounded passes:
///
///   1. **Recall** — ask for a deliberately generous candidate list, telling
///      the model NOT to filter (so it never self-censors correct-but-uncertain
///      names).
///   2. **Verify** — feed that candidate list back and keep ONLY the names the
///      model can confirm from sources for both conditions (drops
///      hallucinations like a player listed for a club they never played for).
///
/// This is the app's ONLY source of answers — there is no static player
/// database to fall back to, so a `null` result means the caller must show an
/// error/retry state, not silently show nothing.
class AnswerFinder {
  AnswerFinder(this._transport);

  final GeminiTransport _transport;

  /// Returns the players satisfying BOTH [condition1] and [condition2], or
  /// `null` on a recall failure (transport/timeout/parse failure — caller
  /// should show an error, not an empty list).
  ///
  /// NOTE: this makes up to TWO sequential Gemini calls (recall, then
  /// verify), so worst-case latency is ~2× a single call.
  Future<AnswerResult?> search({
    required String condition1,
    required String condition2,
  }) async {
    // PHASE 1 — RECALL: cast a wide net. `null` (transport/parse failure) or
    // an empty list (model found nobody) both mean nothing to verify.
    final candidates = await _recall(condition1, condition2);
    if (candidates == null || candidates.isEmpty) return null;

    // PHASE 2 — VERIFY: confirm each candidate against grounded sources.
    final verified = await _verify(candidates, condition1, condition2);

    if (verified != null && verified.isNotEmpty) {
      return AnswerResult(verified, verified: true);
    }

    // An EMPTY (but successful) verify response means the model rejected
    // every candidate — none could be confirmed for both conditions.
    if (verified != null) return AnswerResult(const [], verified: true);

    // `verified == null` means the verification CALL itself failed
    // (network/timeout/parse). Still surface the broad recall list for
    // maximum coverage, but flag it UNVERIFIED so the UI can warn that these
    // names were not fact-checked.
    return AnswerResult(candidates, verified: false);
  }

  /// PHASE 1: a generous candidate list. Lower thinking (brainstorming is
  /// shallow) leaves more of the output budget for a long list.
  Future<List<String>?> _recall(String condition1, String condition2) {
    return _postPrompt(
      Prompts.recall(condition1, condition2),
      thinkingBudget: 512,
      maxOutputTokens: 8192,
    );
  }

  /// PHASE 2: strict verification of [candidates].
  Future<List<String>?> _verify(
    List<String> candidates,
    String condition1,
    String condition2,
  ) {
    return _postPrompt(
      Prompts.verify(candidates, condition1, condition2),
      thinkingBudget: 2048,
      maxOutputTokens: 4096,
    );
  }

  Future<List<String>?> _postPrompt(
    String prompt, {
    required int thinkingBudget,
    required int maxOutputTokens,
  }) async {
    final body = await _transport.generateContent(
      prompt: prompt,
      thinkingBudget: thinkingBudget,
      maxOutputTokens: maxOutputTokens,
    );
    if (body == null) return null;
    return GeminiParser.parsePlayers(body);
  }
}
