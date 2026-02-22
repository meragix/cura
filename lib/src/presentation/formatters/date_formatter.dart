class DateFormatter {
  /// Format: "3 days ago"
  static String format(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? "year" : "years"} ago';
    }

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? "month" : "months"} ago';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? "day" : "days"} ago';
    }

    if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? "hour" : "hours"} ago';
    }

    return 'just now';
  }

  /// Format days as compact string for tables
  static String formatDaysAgo(int days) {
    if (days == 0) return 'today';
    if (days == 1) return '1 day';
    if (days < 30) return '$days days';

    final months = (days / 30).floor();
    if (months == 1) return '1 month';
    return '$months months';

    // final years = (days / 365).floor();
    // if (years == 1) return '1 year';
    // return '$years years';
  }

  /// Format: "2024-01-15"
  static String formatShort(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
