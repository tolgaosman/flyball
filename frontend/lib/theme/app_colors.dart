import 'package:flutter/material.dart';

/// Centralised colour palette for the "Night Pitch" design system.
///
/// A warm, stadium-at-night aesthetic: a warm charcoal (not cool SaaS gray)
/// base, a saturated pitch green paired with a trophy-gold secondary accent
/// (instead of green-vs-plain-white), and warm off-white text.
class AppColors {
  AppColors._();

  /// Primary app background — warm near-black charcoal.
  static const Color background = Color(0xFF14130F);

  /// Standard surface for cards — slightly elevated.
  static const Color surface = Color(0xFF1D1B14);

  /// Elevated surface for dialogs and prominent cards.
  static const Color surfaceHigh = Color(0xFF272419);

  /// Recessed surface for inputs or empty states.
  static const Color surfaceLow = Color(0xFF0A0906);

  /// Vibrant primary accent — a fresh, confident pitch green.
  static const Color pitchGreen = Color(0xFF2FD16B);

  /// Dimmed accent for secondary states.
  static const Color pitchGreenDim = Color(0xFF1B7A42);

  /// Faint glow for active states or focus rings.
  static const Color pitchGreenSoft = Color(0x2A2FD16B);

  /// Secondary accent — a warm trophy gold. Used for wins, the "O" mark,
  /// and to give the two-player game a real two-colour identity.
  static const Color gold = Color(0xFFF0B429);

  /// Dimmed gold for secondary states.
  static const Color goldDim = Color(0xFF9C6E13);

  /// Faint glow for gold-accented active states.
  static const Color goldSoft = Color(0x2AF0B429);

  /// Visible-but-soft border for separating surfaces with real structure.
  static const Color border = Color(0xFF3A3526);

  /// More prominent border for active/focused components.
  static const Color borderHigh = Color(0xFF534B34);

  /// Primary text colour — warm paper white, not clinical pure white.
  static const Color textPrimary = Color(0xFFF6F1E6);

  /// Muted text colour for secondary information — warm taupe gray.
  static const Color textMuted = Color(0xFFA79C86);

  /// High-contrast warm white for icons.
  static const Color white = Color(0xFFF6F1E6);

  /// Muted warm white for slightly dimmed icons or text.
  static const Color whiteMuted = Color(0xB3F6F1E6);

  /// A translucent warm white for soft highlights.
  static const Color whiteSoft = Color(0x1AF6F1E6);

  /// Pure black for deep shadows.
  static const Color black = Color(0xFF000000);

  /// Warm crimson for destructive actions or errors.
  static const Color danger = Color(0xFFFF5A4E);

  /// Semantic colour for the "X" mark / player one.
  static const Color playerX = pitchGreen;

  /// Semantic colour for the "O" mark / player two.
  static const Color playerO = gold;
}
