/// Thrown when the configured [AiGateway] returned `null` — the AI is
/// unreachable, unconfigured, or a request otherwise failed. Callers catch
/// this to show a real error/retry state rather than an empty screen.
class AiUnavailableException implements Exception {
  const AiUnavailableException([this.message = 'AI is unavailable', this.quotaExceeded = false]);

  /// Gemini's daily/rate quota was exhausted — distinct from a genuine
  /// network/timeout failure, so the UI can show an accurate message instead
  /// of telling the user to check their connection.
  const AiUnavailableException.quotaExceeded()
      : message = 'AI quota exceeded',
        quotaExceeded = true;

  final String message;
  final bool quotaExceeded;

  @override
  String toString() => message;
}
