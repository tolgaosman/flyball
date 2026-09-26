import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's language choice, persisted across launches.
///
/// Starts as `null`, which tells [MaterialApp] to resolve the locale from the
/// device's own language via its default resolution algorithm (Turkish
/// device → Turkish; anything else → the first supported locale, English).
/// Once the user picks a language explicitly (the toggle on the home
/// screen), that choice is saved and always wins after that.
class LocaleController extends ValueNotifier<Locale?> {
  LocaleController() : super(null);

  static const _prefsKey = 'flyball.locale';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null) value = Locale(saved);
  }

  Future<void> setLocale(Locale locale) async {
    value = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }
}
