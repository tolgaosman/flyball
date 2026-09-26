import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'coming_soon_screen.dart';

/// Placeholder screen for the future "Footballdle" word-guessing game.
class FootballdleScreen extends StatelessWidget {
  const FootballdleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ComingSoonScreen(
      title: 'Footballdle',
      icon: Icons.abc_rounded,
      tagline: l10n.footballdleTagline,
      previewWord: 'MESSI',
      features: [
        (Icons.calendar_today_rounded, l10n.footballdleFeatureDaily),
        (Icons.lightbulb_outline_rounded, l10n.footballdleFeatureHints),
        (Icons.ios_share_rounded, l10n.footballdleFeatureShare),
      ],
    );
  }
}
