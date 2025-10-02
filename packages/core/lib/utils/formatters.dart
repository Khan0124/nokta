import 'package:intl/intl.dart';

String formatCurrency(double amount) {
  final formatter = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );
  return formatter.format(amount);
}

String formatNumber(int number) {
  final formatter = NumberFormat();
  return formatter.format(number);
}

String formatPercentage(double percentage) {
  final formatter = NumberFormat.decimalPercentPattern(
    decimalDigits: 1,
  );
  return formatter.format(percentage / 100);
}
