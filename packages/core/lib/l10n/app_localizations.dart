import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;
  Map<String, dynamic> _localizedValues = const {};

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  Future<void> load() async {
    final localeName = _resolveLocaleAsset(locale);
    final jsonString = await rootBundle
        .loadString('packages/nokta_core/assets/i18n/$localeName.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedValues = jsonMap;
    Intl.defaultLocale = locale.toLanguageTag();
  }

  String translate(String key, {Map<String, String>? params}) {
    final dynamic value = _lookupValue(key);
    if (value is String) {
      return _applyParams(value, params);
    }
    return key;
  }

  String plural(String key, num count, {Map<String, String>? params}) {
    final dynamic value = _lookupValue(key);
    if (value is Map<String, dynamic>) {
      final pluralized = Intl.plural(
        count,
        locale: locale.toLanguageTag(),
        zero: value['zero'] as String?,
        one: value['one'] as String?,
        two: value['two'] as String?,
        few: value['few'] as String?,
        many: value['many'] as String?,
        other: value['other'] as String? ?? value.values.first as String?,
      );
      return _applyParams(
        pluralized ?? key,
        <String, String>{'count': '$count', ...?params},
      );
    }
    return translate(key, params: <String, String>{'count': '$count', ...?params});
  }

  String formatCurrency(
    num amount, {
    String currencyCode = 'SAR',
    String? currencySymbol,
  }) {
    final format = NumberFormat.currency(
      locale: locale.toLanguageTag(),
      name: currencyCode,
      symbol: currencySymbol,
    );
    return format.format(amount);
  }

  String formatNumber(num number, {int? decimalDigits}) {
    final format = NumberFormat.decimalPatternDigits(
      locale: locale.toLanguageTag(),
      decimalDigits: decimalDigits,
    );
    return format.format(number);
  }

  String formatDateTime(DateTime dateTime, {String? pattern}) {
    final formatter = pattern != null
        ? DateFormat(pattern, locale.toLanguageTag())
        : DateFormat.yMd(locale.toLanguageTag()).add_Hm();
    return formatter.format(dateTime.toLocal());
  }

  TextDirection get textDirection =>
      Bidi.isRtlLanguage(locale.languageCode)
          ? TextDirection.rtl
          : TextDirection.ltr;

  dynamic _lookupValue(String key) {
    final segments = key.split('.');
    dynamic current = _localizedValues;
    for (final segment in segments) {
      if (current is Map<String, dynamic> && current.containsKey(segment)) {
        current = current[segment];
      } else {
        return null;
      }
    }
    return current;
  }

  String _applyParams(String value, Map<String, String>? params) {
    if (params == null || params.isEmpty) {
      return value;
    }
    return params.entries.fold(value, (acc, entry) {
      return acc.replaceAll('{${entry.key}}', entry.value);
    });
  }

  static String _resolveLocaleAsset(Locale locale) {
    final languageCode = locale.languageCode.toLowerCase();
    for (final supported in supportedLocales) {
      if (supported.languageCode == languageCode) {
        return supported.languageCode;
      }
    }
    return supportedLocales.first.languageCode;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((supported) => supported.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

extension AppLocalizationsBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
