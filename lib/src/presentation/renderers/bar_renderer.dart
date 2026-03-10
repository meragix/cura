import 'package:cura/src/domain/entities/score.dart';
import 'package:cura/src/presentation/themes/theme_manager.dart';

/// Renderer : Barres visuelles pour scores
class BarRenderer {
  final bool _useColors;

  const BarRenderer({bool useColors = true}) : _useColors = useColors;

  /// Render score breakdown as visual bars.
  ///
  /// The char identifies the dimension; the color reflects its health:
  /// scoreExcellent ≥ 75 %, scoreGood ≥ 50 %, scorePoor < 50 %, muted dot < 10 %.
  ///
  /// Example: █ Vitality  ▓ Tech  ▒ Trust  ░ Maint
  String renderScoreBreakdown(Score score) {
    final parts = <String>[];

    parts.add(_renderBar(
        label: 'Vitality', value: score.vitality, max: 40, char: '█'));
    parts.add(_renderBar(
        label: 'Tech', value: score.technicalHealth, max: 30, char: '▓'));
    parts.add(
        _renderBar(label: 'Trust', value: score.trust, max: 20, char: '▒'));
    parts.add(_renderBar(
        label: 'Maint', value: score.maintenance, max: 10, char: '░'));

    return parts.join('  ');
  }

  /// Render single category bar.
  ///
  /// Color is driven by [value]/[max] percentage using theme score tokens:
  /// - ≥ 75 % → scoreExcellent
  /// - ≥ 50 % → scoreGood
  /// - ≥ 10 % → scorePoor
  /// - <  10 % → muted dot
  String _renderBar({
    required String label,
    required int value,
    required int max,
    required String char,
  }) {
    final theme = ThemeManager.current;
    final percentage = (value / max * 100).round();

    if (percentage < 10) {
      return _useColors ? '${theme.muted.wrap('·')} $label' : '· $label';
    }

    if (!_useColors) return '$char $label';

    final color = percentage >= 75
        ? theme.scoreExcellent
        : percentage >= 50
            ? theme.scoreGood
            : theme.scorePoor;
    return '${color.wrap(char)} $label';
  }

  /// Render popularity dots (●●●)
  String renderPopularityDots(int popularity) {
    final theme = ThemeManager.current;
    const maxDots = 3;
    final dotsCount = (popularity / 100 * maxDots).round().clamp(0, maxDots);
    final emptyCount = maxDots - dotsCount;

    final filled = '●' * dotsCount;
    final empty = '○' * emptyCount;

    if (!_useColors) return filled + empty;

    return theme.success.wrap(filled)! + theme.muted.wrap(empty)!;
  }

  /// Render pub score indicator (●)
  String renderPubScoreIndicator(int panaScore) {
    final theme = ThemeManager.current;
    final char = panaScore >= 120
        ? '●'
        : panaScore >= 80
            ? '◐'
            : '○';

    if (!_useColors) return char;

    if (panaScore >= 120) return theme.scoreExcellent.wrap(char)!;
    if (panaScore >= 80) return theme.scoreGood.wrap(char)!;
    return theme.scorePoor.wrap(char)!;
  }

  /// Render last update status (🟢/🟡/🔴)
  String renderUpdateStatus(int daysSinceUpdate) {
    final theme = ThemeManager.current;
    if (daysSinceUpdate <= 90) {
      return _useColors ? theme.success.wrap('🟢')! : '✓';
    }
    if (daysSinceUpdate <= 365) {
      return _useColors ? theme.warning.wrap('🟡')! : '!';
    }
    return _useColors ? theme.error.wrap('⚠')! : '✗';
  }
}
