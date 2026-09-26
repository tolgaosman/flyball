import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../widgets/states.dart';

/// Shared "Coming Soon" placeholder used by the not-yet-built games.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title.toUpperCase())),
      body: EmptyState(
        icon: icon,
        iconColor: AppColors.pitchGreen,
        title: l10n.comingSoonTitle,
        message: l10n.comingSoonMessage,
      ),
    );
  }
}
