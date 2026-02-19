import 'package:cura/src/domain/entities/score.dart';
import 'package:mason_logger/mason_logger.dart';

/// Renderer : Barres visuelles pour scores
class BarRenderer {
  final bool _useColors;

  const BarRenderer({bool useColors = true}) : _useColors = useColors;

  /// Render score breakdown as visual bars
  ///
  /// Example: █ Vitality  ▓ Tech  █ Trust  ▒ Maint
  String renderScoreBreakdown(Score score) {
    final parts = <String>[];

    // Vitality (40 max)
    parts.add(_renderBar(
      label: 'Vitality',
      value: score.vitality,
      max: 40,
      color: green,
      char: '█',
    ));

    // Technical Health (30 max)
    parts.add(_renderBar(
      label: 'Tech',
      value: score.technicalHealth,
      max: 30,
      color: blue,
      char: '▓',
    ));

    // Trust (20 max)
    parts.add(_renderBar(
      label: 'Trust',
      value: score.trust,
      max: 20,
      color: cyan,
      char: '█',
    ));

    // Maintenance (10 max)
    parts.add(_renderBar(
      label: 'Maint',
      value: score.maintenance,
      max: 10,
      color: magenta,
      char: '▒',
    ));

    return parts.join('  ');
  }

  /// Render single category bar
  String _renderBar({
    required String label,
    required int value,
    required int max,
    required AnsiCode color,
    required String char,
  }) {
    // Calculate bar length (proportional)
    final percentage = (value / max * 100).round();

    // Empty bar for very low scores
    if (percentage < 10) {
      final emptyChar = '·';
      return _useColors ? '${lightGray.wrap(emptyChar)} $label' : '$emptyChar $label';
    }

    // Filled bar
    return _useColors ? '${color.wrap(char)} $label' : '$char $label';
  }

  /// Render popularity dots (●●●)
  String renderPopularityDots(int popularity) {
    const maxDots = 3;
    final dotsCount = (popularity / 100 * maxDots).round().clamp(0, maxDots);
    final emptyCount = maxDots - dotsCount;

    final filled = '●' * dotsCount;
    final empty = '○' * emptyCount;

    if (!_useColors) return filled + empty;

    return green.wrap(filled)! + lightGray.wrap(empty)!;
  }

  /// Render pub score indicator (●)
  String renderPubScoreIndicator(int panaScore) {
    final char = panaScore >= 120
        ? '●'
        : panaScore >= 80
            ? '◐'
            : '○';

    if (!_useColors) return char;

    if (panaScore >= 120) return green.wrap(char)!;
    if (panaScore >= 80) return yellow.wrap(char)!;
    return red.wrap(char)!;
  }

  /// Render last update status (🟢/🟡/🔴)
  String renderUpdateStatus(int daysSinceUpdate) {
    if (daysSinceUpdate <= 90) {
      return _useColors ? green.wrap('🟢')! : '✓';
    }
    if (daysSinceUpdate <= 365) {
      return _useColors ? yellow.wrap('🟡')! : '!';
    }
    return _useColors ? red.wrap('⚠')! : '✗';
  }
}
