import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  LocaleService(this._preferences);

  final SharedPreferences _preferences;

  static const _localeKey = 'nokta_locale';

  static Future<LocaleService> create() async {
    final preferences = await SharedPreferences.getInstance();
    return LocaleService(preferences);
  }

  Future<void> saveLocale(Locale locale) async {
    await _preferences.setString(_localeKey, locale.toLanguageTag());
  }

  Future<Locale?> loadLocale() async {
    final value = _preferences.getString(_localeKey);
    if (value == null || value.isEmpty) {
      return null;
    }
    final components = value.split('-');
    if (components.length == 1) {
      return Locale(components.first);
    }
    return Locale(components.first, components[1]);
  }
}
