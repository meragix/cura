class DateFormatter {
  const DateFormatter._();

  /// Returns number of days between [date] and [now]
  static int daysSince(DateTime date, DateTime now) {
    final now = DateTime.now();
    return now.toUtc().difference(date.toUtc()).inDays;
  }

  /// Format: "487 days ago"
  static String formatDaysAgo(int days) {
    if (days == 0) return 'today';
    if (days == 1) return '1 day ago';
    return '$days days ago';
  }

  /// Format ISO short: "2024-10-12"
  static String formatShort(DateTime date) {
    final utc = date.toUtc();
    final year = utc.year;
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Final Cura output
  /// Example: 2024-10-12 (487 days ago)
  static String formatWithRelative(DateTime date) {
    final now = DateTime.now();
    final days = daysSince(date, now);
    final iso = formatShort(date);
    final relative = formatDaysAgo(days);

    return '$iso ($relative)';
  }

  /// Format days as compact string for tables
  static String formatCompactDays(int days) {
    if (days == 0) return 'today';
    if (days == 1) return '1 day';
    if (days < 30) return '$days days';

    final months = (days / 30).floor();
    if (months == 1) return '1 month';
    return '$months months';
  }
}
