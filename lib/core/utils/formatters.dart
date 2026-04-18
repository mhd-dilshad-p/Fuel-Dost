import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _indianCurrency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final _indianCurrencyNoDecimal = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final _numberFormat = NumberFormat('#,##0.##', 'en_IN');

  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final _monthYearFormat = DateFormat('MMM yyyy');
  static final _shortMonthFormat = DateFormat('MMM');

  /// Format as Indian currency (₹1,23,456.78)
  static String currency(double value) {
    return _indianCurrency.format(value);
  }

  /// Format as Indian currency without decimals (₹1,23,457)
  static String currencyRounded(double value) {
    return _indianCurrencyNoDecimal.format(value);
  }

  /// Format number with Indian grouping
  static String number(double value) {
    return _numberFormat.format(value);
  }

  /// Format distance in km
  static String distance(double km) {
    if (km < 1) {
      return '${(km * 1000).toStringAsFixed(0)} m';
    }
    return '${_numberFormat.format(km)} km';
  }

  /// Format litres
  static String litres(double value) {
    return '${value.toStringAsFixed(2)} L';
  }

  /// Format date
  static String date(DateTime dateTime) {
    return _dateFormat.format(dateTime);
  }

  /// Format date and time
  static String dateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  /// Format month and year
  static String monthYear(DateTime dateTime) {
    return _monthYearFormat.format(dateTime);
  }

  /// Format short month
  static String shortMonth(DateTime dateTime) {
    return _shortMonthFormat.format(dateTime);
  }

  /// Format duration from seconds
  static String duration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes} min';
  }

  /// Format cost per km
  static String costPerKm(double value) {
    return '₹${value.toStringAsFixed(2)}/km';
  }
}
