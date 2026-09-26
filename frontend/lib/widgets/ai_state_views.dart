import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_button.dart';
import '../widgets/states.dart';

/// Shown when the app has no AI connection configured at all (no
/// `API_BASE_URL` and no `GEMINI_API_KEY`). There is nothing a retry can fix
/// here — it's a launch-config problem — so this explains what to set instead
/// of offering a button that would just fail again.
class AiNotConfiguredView extends StatelessWidget {
  const AiNotConfiguredView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      iconColor: AppColors.danger,
      title: l10n.aiNotConfiguredTitle,
      message: l10n.aiNotConfiguredMessage,
    );
  }
}

/// Shown when the AI is configured but a request failed (network, timeout, or
/// the model itself errored). Always paired with a retry action — this is the
/// one state every AI-backed screen must show instead of silently rendering
/// nothing when a gateway call returns `null`.
class AiUnavailableView extends StatelessWidget {
  const AiUnavailableView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ErrorState(
      icon: Icons.wifi_off_rounded,
      title: l10n.aiUnavailableTitle,
      message: l10n.aiUnavailableMessage,
      action: PremiumButton(
        onPressed: onRetry,
        expand: false,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        child: Text(l10n.retry),
      ),
    );
  }
}
