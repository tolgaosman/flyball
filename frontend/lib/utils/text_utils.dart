import 'package:flutter/widgets.dart' show Locale;

/// Case/accent-insensitive text matching and locale-correct uppercasing.
///
/// Dart's built-in [String.toUpperCase]/[String.toLowerCase] use a
/// locale-invariant Unicode mapping, which gets Turkish wrong in both
/// directions: `'i'.toUpperCase()` gives `'I'` (dotless) instead of the
/// Turkish `'İ'` (dotted), and `'İ'.toLowerCase()` gives `'i̇'` (a plain 'i'
/// plus a stray combining dot) instead of plain `'i'`. Both show up visibly
/// wrong for a Turkish name like "İsmail".
class TextFold {
  TextFold._();

  /// Diacritic → plain-ASCII folding table, extended with the Turkish
  /// dotted/dotless 'i' pair — used by [fold] so search matching ignores both
  /// case AND accents (so "ozil" finds "Özil", "ilkay" finds "İlkay").
  static const Map<String, String> _map = {
    'İ': 'i', 'I': 'i', 'ı': 'i',
    'Ş': 's', 'ş': 's',
    'Ğ': 'g', 'ğ': 'g',
    'Ü': 'u', 'ü': 'u',
    'Ö': 'o', 'ö': 'o',
    'Ç': 'c', 'ç': 'c',
    'É': 'e', 'é': 'e', 'È': 'e', 'è': 'e', 'Ê': 'e', 'ê': 'e', 'Ë': 'e', 'ë': 'e',
    'Á': 'a', 'á': 'a', 'À': 'a', 'à': 'a', 'Â': 'a', 'â': 'a', 'Ä': 'a', 'ä': 'a',
    'Ñ': 'n', 'ñ': 'n',
    'Ø': 'o', 'ø': 'o',
    'Å': 'a', 'å': 'a',
    'Í': 'i', 'í': 'i', 'Î': 'i', 'î': 'i',
    'Ú': 'u', 'ú': 'u', 'Û': 'u', 'û': 'u',
    'Ý': 'y', 'ý': 'y',
  };

  /// Folds [input] to a lowercase, diacritic-stripped form suitable for
  /// `contains`-style search matching — never for display.
  static String fold(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(_map[ch] ?? ch.toLowerCase());
    }
    return buffer.toString();
  }

  /// True when [haystack] contains [needle], ignoring case and accents.
  static bool contains(String haystack, String needle) =>
      fold(haystack).contains(fold(needle));
}

/// Locale-correct uppercasing for display text (status banners, chips).
extension LocaleAwareCase on String {
  String toUpperCaseFor(Locale locale) {
    if (locale.languageCode != 'tr') return toUpperCase();
    // Only 'i' → 'İ' needs a manual override; Dart's default mapping already
    // gets 'ı' → 'I' right (that one isn't Turkish-specific).
    return replaceAll('i', 'İ').toUpperCase();
  }
}
