import 'package:mason_logger/mason_logger.dart';

class ScoreFormatter {
  String miniBar(int value, int max) {
    final percentage = (value / max * 100).round();

    if (percentage >= 90) return green.wrap('█')!;
    if (percentage >= 70) return lightGreen.wrap('▓')!;
    if (percentage >= 50) return yellow.wrap('▒')!;
    if (percentage >= 30) return lightYellow.wrap('░')!;
    return darkGray.wrap('·')!;
  }

  AnsiCode getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return green;
      case 'B':
        return lightGreen;
      case 'C':
        return yellow;
      default:
        return red;
    }
  }

  String getGradeEmoji(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return '✨';
      case 'B':
        return '✓';
      case 'C':
        return '⚠';
      default:
        return '✗';
    }
  }
}
