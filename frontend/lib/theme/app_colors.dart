import 'package:flutter/material.dart';

/// Centralised colour palette for the Premium "Anti-Slop" design system.
///
/// Features deep, sophisticated midnight tones, smooth glassmorphic whites,
/// and subtle accent glows instead of harsh solids.
class AppColors {
  AppColors._();

  /// Primary app background — deep midnight, almost black but with depth.
  static const Color background = Color(0xFF09090B);

  /// Standard surface for cards — slightly elevated.
  static const Color surface = Color(0xFF141416);

  /// Elevated surface for dialogs and prominent cards.
  static const Color surfaceHigh = Color(0xFF1D1D21);

  /// Recessed surface for inputs or empty states.
  static const Color surfaceLow = Color(0xFF050505);

  /// Vibrant, elegant accent. A premium, glowing emerald instead of neon.
  static const Color pitchGreen = Color(0xFF22C55E);

  /// Dimmed accent for secondary states.
  static const Color pitchGreenDim = Color(0xFF166534);

  /// Faint, beautiful glow for active states or focus rings.
  static const Color pitchGreenSoft = Color(0x1F22C55E);

  /// Subtle, barely-there border for separating surfaces cleanly.
  static const Color border = Color(0xFF27272A);
  
  /// Slightly more prominent border for active components.
  static const Color borderHigh = Color(0xFF3F3F46);

  /// Primary text colour — pure white.
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Muted text colour for secondary information.
  static const Color textMuted = Color(0xFFA1A1AA);

  /// Pure white for high-contrast icons.
  static const Color white = Color(0xFFFFFFFF);

  /// A translucent white perfect for glassmorphic highlights.
  static const Color whiteSoft = Color(0x1AFFFFFF);

  /// Pure black for deep shadows.
  static const Color black = Color(0xFF000000);

  /// Elegant crimson for destructive actions or errors.
  static const Color danger = Color(0xFFEF4444);
}
