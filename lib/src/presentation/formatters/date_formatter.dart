import 'dart:ffi';

class DateFormatter {
  static String formatDaysAgo(int days) {
    if (days == 0) return 'today';
    if (days == 1) return 'yesterday';
    if (days < 7) return '$days days ago';
    if (days < 30) {
      final weeks = (days / 7).round();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    }
    if (days < 365) {
      final months = (days / 30).round();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
    final years = (days / 365).round();
    return '$years ${years == 1 ? 'year' : 'years'} ago';
  }

  static String formatDate(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    return formatDaysAgo(days);
  }

  static int formatInDays(DateTime date) {
    return DateTime.now().difference(date).inDays;
  }
}
