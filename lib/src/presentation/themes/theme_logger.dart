import 'package:cura/src/presentation/themes/theme.dart';
import 'package:cura/src/presentation/themes/theme_manager.dart';
import 'package:mason_logger/mason_logger.dart';

class ThemedLogger {
  final Logger _logger;

  ThemedLogger({Logger? logger}) : _logger = logger ?? Logger();

  CuraTheme get theme => ThemeManager.current;

  // Méthodes avec thème appliqué
  void info(String message) {
    _logger.info(theme.textPrimary.wrap(message));
  }

  void success(String message) {
    _logger.info('${theme.symbolSuccess} ${theme.success.wrap(message)}');
  }

  void warning(String message) {
    _logger.warn('${theme.symbolWarning} ${theme.warning.wrap(message)}');
  }

  void error(String message) {
    _logger.err('${theme.symbolError} ${theme.error.wrap(message)}');
  }

  void muted(String message) {
    _logger.info(theme.textMuted.wrap(message));
  }

  void section(String title) {
    _logger.info(theme.primary.wrap(styleBold.wrap(title)));
  }

  void header(String title) {
    final divider = '═' * 60;
    _logger.info(theme.primary.wrap(divider));
    _logger.info(theme.primary.wrap(styleBold.wrap(title)));
    _logger.info(theme.primary.wrap(divider));
  }

  // Score avec couleur thématique
  void score(int value, int max) {
    final percentage = (value / max * 100).round();
    final color = _getScoreColor(percentage);

    _logger.info(color.wrap('$value/$max (${percentage}%)'));
  }

  // Barre de progression thématique
  void progressBar(int value, int max, {int width = 20}) {
    final percentage = value / max;
    final filled = (percentage * width).round();
    final empty = width - filled;

    final bar = '${theme.success.wrap(theme.barFilled * filled) ?? (theme.barFilled * filled)}' +
        '${theme.textMuted.wrap(theme.barEmpty * empty) ?? (theme.barEmpty * empty)}';

    _logger.info(bar);
  }

  AnsiCode _getScoreColor(int percentage) {
    if (percentage >= 90) return theme.scoreExcellent;
    if (percentage >= 70) return theme.scoreGood;
    if (percentage >= 50) return theme.scoreFair;
    return theme.scorePoor;
  }
}
