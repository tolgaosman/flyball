import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Spacing scale — a consistent set of gaps so layouts breathe the same
/// way everywhere. Prefer these over magic numbers.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // Convenient gap widgets.
  static const SizedBox gapXs = SizedBox(height: xs, width: xs);
  static const SizedBox gapSm = SizedBox(height: sm, width: sm);
  static const SizedBox gapMd = SizedBox(height: md, width: md);
  static const SizedBox gapLg = SizedBox(height: lg, width: lg);
  static const SizedBox gapXl = SizedBox(height: xl, width: xl);
  static const SizedBox gapXxl = SizedBox(height: xxl, width: xxl);
}

/// Shared visual constants and the global [ThemeData] for Flyball.
///
/// The aesthetic is "Night Pitch": a warm, stadium-at-night look with
/// confident geometric headlines, soft diffuse shadows, colour glows on
/// active elements, and smooth spring-physics motion.
class AppTheme {
  AppTheme._();

  /// Standard corner radius for cards — tighter and more confident than a
  /// generic bubbly SaaS radius.
  static const double radius = 20.0;

  /// A smaller radius for chips / compact elements.
  static const double radiusSm = 12.0;

  /// Standard border width.
  static const double borderWidth = 1.0;

  // ---- Motion ---------------------------------------------------------------
  
  static const Duration durFast = Duration(milliseconds: 250);
  static const Duration durMed = Duration(milliseconds: 500);
  static const Duration durSlow = Duration(milliseconds: 700);

  /// A luxurious, hyper-smooth spring curve for UI interactions.
  static const Curve springCurve = Curves.easeOutCirc;

  /// A beautiful fluid entrance curve.
  static const Curve emphasized = Curves.fastLinearToSlowEaseIn;

  // ---- Shadows --------------------------------------------------------------

  /// A beautiful, diffuse shadow giving a floating effect, replacing hard shadows.
  static List<BoxShadow> softShadow({double elevation = 1}) {
    return [
      BoxShadow(
        color: AppColors.black.withValues(alpha: 0.4 * elevation),
        offset: Offset(0, 8 * elevation),
        blurRadius: 24 * elevation,
        spreadRadius: -4 * elevation,
      ),
      BoxShadow(
        color: AppColors.black.withValues(alpha: 0.2 * elevation),
        offset: Offset(0, 2 * elevation),
        blurRadius: 8 * elevation,
        spreadRadius: -2 * elevation,
      ),
    ];
  }

  /// A soft colour glow "lit from within" a surface, layered under
  /// [softShadow] for primary actions and active states.
  static List<BoxShadow> glowShadow(Color color, {double elevation = 1}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.35 * elevation),
        offset: Offset(0, 4 * elevation),
        blurRadius: 20 * elevation,
        spreadRadius: -2 * elevation,
      ),
      ...softShadow(elevation: elevation),
    ];
  }

  // ---- Type scale -----------------------------------------------------------

  /// A confident, geometric display sans-serif (Space Grotesk) — used for
  /// headings and anywhere the type needs personality.
  static TextStyle heading(double size, {Color color = AppColors.textPrimary}) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.1,
      letterSpacing: -0.6,
    );
  }

  /// Body / label text style.
  static TextStyle label(
    double size, {
    Color color = AppColors.textPrimary,
    FontWeight weight = FontWeight.w500,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.5,
      letterSpacing: -0.2,
    );
  }

  // Named scale — prefer these for consistent hierarchy.
  static TextStyle displayXL({Color color = AppColors.textPrimary}) =>
      heading(48, color: color).copyWith(fontWeight: FontWeight.w700, letterSpacing: -1.2);
  static TextStyle display({Color color = AppColors.textPrimary}) =>
      heading(36, color: color).copyWith(fontWeight: FontWeight.w700, letterSpacing: -1.0);
  static TextStyle title({Color color = AppColors.textPrimary}) => heading(24, color: color);
  static TextStyle headline({Color color = AppColors.textPrimary}) => heading(18, color: color);
  static TextStyle body({Color color = AppColors.textPrimary}) => label(16, color: color, weight: FontWeight.w400);
  static TextStyle caption({Color color = AppColors.textMuted}) =>
      label(14, color: color, weight: FontWeight.w400);

  /// Uppercase, tracked label for section headers — set in the display face
  /// (Space Grotesk) so section labels carry the same brand personality.
  static TextStyle overline({Color color = AppColors.textMuted}) {
    return GoogleFonts.spaceGrotesk(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.2,
      letterSpacing: 1.2,
    );
  }

  // ---- ThemeData ------------------------------------------------------------

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.pitchGreen,
        secondary: AppColors.gold,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background.withValues(alpha: 0.7),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
        titleTextStyle: heading(20),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceHigh,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceHigh,
        elevation: 24,
        surfaceTintColor: Colors.transparent,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      splashColor: AppColors.pitchGreen.withValues(alpha: 0.1),
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
    );
  }
}
