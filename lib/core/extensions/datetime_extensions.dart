import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  /// Format as "Sep 5" or "Sep 5, 2026"
  String toShortDateString() {
    final now = DateTime.now();
    if (year == now.year) {
      return DateFormat('MMM d').format(this);
    }
    return DateFormat('MMM d, yyyy').format(this);
  }

  /// Days remaining until target date
  int daysRemaining() {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final target = DateTime(year, month, day);
    return target.difference(today).inDays;
  }
}
