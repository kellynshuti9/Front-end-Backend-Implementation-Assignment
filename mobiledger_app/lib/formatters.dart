import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String currency(double amount, {String symbol = 'RWF'}) {
    final n = NumberFormat('#,###', 'en_US');
    return '${n.format(amount)} $symbol';
  }

  static String date(DateTime d) => DateFormat('d MMM yyyy').format(d);

  static String dateTime(DateTime d) =>
      DateFormat('d MMM yyyy, HH:mm').format(d);

  static String compact(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}
