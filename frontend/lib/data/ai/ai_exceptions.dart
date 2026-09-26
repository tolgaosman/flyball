/// Thrown when the configured [AiGateway] returned `null` — the AI is
/// unreachable, unconfigured, or a request otherwise failed. Callers catch
/// this to show a real error/retry state rather than an empty screen.
class AiUnavailableException implements Exception {
  const AiUnavailableException([this.message = 'AI is unavailable']);
  final String message;

  @override
  String toString() => message;
}
