import 'package:flutter/material.dart';

import 'data/account/session_controller.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_controller.dart';
import 'routing/app_routes.dart';
import 'theme/app_theme.dart';
import 'widgets/phone_frame.dart';

final localeController = LocaleController();

/// The signed-in Flyball account, app-wide (see [SessionController]).
final sessionController = SessionController.fromConfig();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await localeController.load();
  await sessionController.restore();
  runApp(const FlyballApp());
}

/// Root widget for Flyball — an AI-powered football trivia app.
class FlyballApp extends StatelessWidget {
  const FlyballApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: localeController,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'Flyball',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          initialRoute: AppRoutes.home,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          builder: (context, child) {
            return PhoneFrame(child: child ?? const SizedBox.shrink());
          },
        );
      },
    );
  }
}
