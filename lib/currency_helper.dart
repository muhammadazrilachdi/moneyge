import 'package:intl/intl.dart';

class CurrencyHelper {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _formatterWithoutSymbol = NumberFormat(
    '#,##0',
    'id_ID',
  );

  static String formatRupiah(int amount) {
    return _formatter.format(amount);
  }

  static String formatRupiahWithoutSymbol(int amount) {
    return _formatterWithoutSymbol.format(amount);
  }

  static int parseRupiah(String text) {
    // Remove all non-digit characters except dots and commas
    String cleanText = text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleanText) ?? 0;
  }
}
