import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatCurrency(
  num amount, {
  String currencyCode = 'SAR',
  String? currencySymbol,
  Locale? locale,
}) {
  final formatter = NumberFormat.currency(
    locale: locale?.toLanguageTag() ?? Intl.getCurrentLocale(),
    name: currencyCode,
    symbol: currencySymbol,
  );
  return formatter.format(amount);
}

String formatNumber(num number, {Locale? locale, int? decimalDigits}) {
  final formatter = NumberFormat.decimalPatternDigits(
    locale: locale?.toLanguageTag() ?? Intl.getCurrentLocale(),
    decimalDigits: decimalDigits,
  );
  return formatter.format(number);
}

String formatPercentage(double percentage, {Locale? locale, int? decimalDigits}) {
  final formatter = NumberFormat.decimalPercentPattern(
    locale: locale?.toLanguageTag() ?? Intl.getCurrentLocale(),
    decimalDigits: decimalDigits ?? 1,
  );
  return formatter.format(percentage / 100);
}
