import '../../config/app_config.dart';
import 'ai_gateway.dart';
import 'backend_ai_gateway.dart';
import 'direct_ai_gateway.dart';
import 'no_ai_gateway.dart';

/// Builds the right [AiGateway] for how the app was configured (see
/// [AppConfig.aiMode]). Built once and shared for the app's lifetime.
AiGateway createAiGateway() {
  switch (AppConfig.aiMode) {
    case AiMode.backend:
      return BackendAiGateway(baseUrl: AppConfig.apiBaseUrl);
    case AiMode.direct:
      return DirectAiGateway(
        apiKey: AppConfig.geminiApiKey,
        model: AppConfig.geminiModel,
      );
    case AiMode.none:
      return const NoAiGateway();
  }
}
