class NumberFormatter {
  /// Format: "3425" → "3,4K"
  static String formatCompact(int number) {
    if (number >= 1000000) {
      return _trimTrailingZero(number / 1000000) + 'M';
    }
    if (number >= 1000) {
      return _trimTrailingZero(number / 1000) + 'K';
    }
    return number.toString();
  }

  /// Format: "3425" → "3,425"
  static formatGrouped(int value) {
    final s = value.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < s.length; i++) {
      final indexFromEnd = s.length - i;
      buffer.write(s[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  static String _trimTrailingZero(double value) {
    final fixed = value.toStringAsFixed(1);
    return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
  }
}
