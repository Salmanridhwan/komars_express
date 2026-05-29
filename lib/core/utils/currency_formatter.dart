import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _rupiahFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Format double to Indonesian Rupiah string (e.g. Rp 45.000)
  static String format(double amount) {
    return _rupiahFormat.format(amount);
  }

  /// Format int to Indonesian Rupiah string
  static String formatInt(int amount) {
    return _rupiahFormat.format(amount);
  }

  /// Parse Rupiah string back to double
  static double parse(String rupiahString) {
    try {
      return _rupiahFormat.parse(rupiahString).toDouble();
    } catch (_) {
      return 0.0;
    }
  }
}
