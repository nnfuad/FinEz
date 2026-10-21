import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  /// Formats amount in Bangladeshi Taka: e.g. ৳2,000.00 or ৳2,000
  static String formatCurrency(num amount, {String locale = 'en', bool showDecimals = true}) {
    final formatter = NumberFormat.currency(
      symbol: '৳',
      decimalDigits: showDecimals ? 2 : 0,
      locale: locale == 'bn' ? 'bn_BD' : 'en_US',
    );
    return formatter.format(amount);
  }

  /// Format date for display: e.g. 18 Oct 2026 or ১৮ অক্টো ২০২৬
  static String formatDate(DateTime? date, {String locale = 'en'}) {
    if (date == null) return '-';
    // Bangladesh Standard Time offset is UTC+6
    final localDate = date.toLocal();
    final formatter = DateFormat('dd MMM yyyy', locale == 'bn' ? 'bn_BD' : 'en_US');
    return formatter.format(localDate);
  }

  /// Format date with time: e.g. 18 Oct 2026, 14:35
  static String formatDateTime(DateTime? dateTime, {String locale = 'en'}) {
    if (dateTime == null) return '-';
    final localDate = dateTime.toLocal();
    final formatter = DateFormat('dd MMM yyyy, HH:mm', locale == 'bn' ? 'bn_BD' : 'en_US');
    return formatter.format(localDate);
  }

  /// Format month & year: e.g. October 2026
  static String formatMonthYear(DateTime date, {String locale = 'en'}) {
    final formatter = DateFormat('MMMM yyyy', locale == 'bn' ? 'bn_BD' : 'en_US');
    return formatter.format(date);
  }

  /// Clean & normalize Bangladeshi phone numbers (e.g. 01711223344 or +8801711223344)
  static String normalizeMobile(String input) {
    var cleaned = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('+880')) {
      cleaned = '0${cleaned.substring(4)}';
    } else if (cleaned.startsWith('880')) {
      cleaned = '0${cleaned.substring(3)}';
    }
    return cleaned;
  }
}
