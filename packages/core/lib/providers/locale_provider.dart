import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../services/locale_service.dart';

final localeServiceProvider = Provider<LocaleService>((ref) {
  throw UnimplementedError(
    'LocaleService must be provided via ProviderScope overrides',
  );
});

final localeProvider = StateNotifierProvider<LocaleController, Locale>((ref) {
  final service = ref.watch(localeServiceProvider);
  return LocaleController(service);
});

class LocaleController extends StateNotifier<Locale> {
  LocaleController(this._localeService)
      : super(AppLocalizations.supportedLocales.first) {
    _initialize();
  }

  final LocaleService _localeService;

  Future<void> _initialize() async {
    final storedLocale = await _localeService.loadLocale();
    if (storedLocale != null) {
      state = storedLocale;
    }
    Intl.defaultLocale = state.toLanguageTag();
  }

  Future<void> setLocale(Locale locale) async {
    if (state == locale) {
      return;
    }
    state = locale;
    Intl.defaultLocale = locale.toLanguageTag();
    await _localeService.saveLocale(locale);
  }
}
