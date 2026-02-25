import 'dart:io' as io;

import 'package:cura/src/presentation/themes/theme.dart';
import 'package:cura/src/presentation/themes/theme_manager.dart';
import 'package:mason_logger/mason_logger.dart';

/// Console logger backed by mason_logger.
///
/// Features:
/// - Automatic colorisation (respects the `use_colors` config)
/// - Animated progress bars and spinners
/// - Emoji support (respects the `use_emojis` config)
/// - Log levels: info, success, warning, error, detail, debug
/// - Quiet mode (suppresses all non-error output)
/// - Themed score display and progress bars
/// - Prompts: confirm, chooseOne, chooseAny
class ConsoleLogger {
  final Logger _logger;
  final bool _useColors;
  final bool _useEmojis;
  final bool _quiet;
  final Level _level;

  ConsoleLogger({
    bool useColors = true,
    bool useEmojis = true,
    bool quiet = false,
    Level? level,
  })  : _useColors = useColors,
        _useEmojis = useEmojis,
        _quiet = quiet,
        _level = level ?? (quiet ? Level.error : Level.info),
        _logger = Logger(
          level: level ?? (quiet ? Level.error : Level.info),
        );

  CuraTheme get theme => ThemeManager.current;

  // ==========================================================================
  // LEVEL CHECKS
  // ==========================================================================

  bool get isVerbose => _level == Level.verbose;
  bool get isQuiet => _quiet;
  bool get isNormal => _level == Level.info;

  // ==========================================================================
  // BASIC LOGGING
  // ==========================================================================

  /// Log plain info message.
  void info(String message) {
    if (_quiet) return;
    _logger.info(_applyEmoji(message, ''));
  }

  /// Log success message (green check).
  void success(String message, {bool showSymbol = true}) {
    if (_quiet) return;
    if (showSymbol) {
      _logger.success(_applyEmoji(message, '✓'));
    } else {
      _logger.success(message);
    }
  }

  /// Log warning message (yellow).
  void warn(String message) {
    _logger.warn('${theme.warning.wrap(message)}', tag: '');
  }

  /// Log error message (red).
  void error(String message) {
    _logger.err('${theme.error.wrap(message)}');
  }

  /// Log detail/dim message.
  void detail(String message) {
    if (_quiet) return;
    _logger.detail(_applyEmoji(message, ''));
  }

  /// Log debug message (only visible in verbose mode).
  void debug(String message) {
    if (_quiet) return;
    _logger.detail(lightGray.wrap('🐛 $message'));
  }

  // ==========================================================================
  // STRUCTURED OUTPUT
  // ==========================================================================

  /// Log a section heading using the theme's primary colour + bold.
  void section(String title) {
    if (_quiet) return;
    _logger.info(theme.primary.wrap(styleBold.wrap(title)));
  }

  /// Log a full-width header (double-line box).
  void header(String title) {
    if (_quiet) return;
    final divider = '═' * 60;
    _logger.info(theme.primary.wrap(divider));
    _logger.info(theme.primary.wrap(styleBold.wrap(title)));
    _logger.info(theme.primary.wrap(divider));
  }

  /// Spacer (empty line).
  void spacer() {
    if (_quiet) return;
    _logger.info('');
  }

  /// Horizontal divider.
  void divider({int length = 50, String char = '─'}) {
    if (_quiet) return;
    _logger.info(char * length);
  }

  // ==========================================================================
  // SCORE & PROGRESS
  // ==========================================================================

  /// Log a score value with colour derived from the percentage.
  void score(int value, int max) {
    if (_quiet) return;
    final percentage = (value / max * 100).round();
    final color = _getScoreColor(percentage);
    _logger.info(color.wrap('$value/$max (${percentage}%)'));
  }

  /// Render a themed progress bar.
  void progressBar(int value, int max, {int width = 20}) {
    if (_quiet) return;
    final percentage = value / max;
    final filled = (percentage * width).round();
    final empty = width - filled;

    final bar = '${theme.success.wrap(theme.barFilled * filled) ?? (theme.barFilled * filled)}'
        '${theme.muted.wrap(theme.barEmpty * empty) ?? (theme.barEmpty * empty)}';

    _logger.info(bar);
  }

  // ==========================================================================
  // PROGRESS INDICATORS
  // ==========================================================================

  /// Create a progress indicator (determinate).
  ///
  /// ```dart
  /// final progress = logger.progress('Scanning packages');
  /// await doWork();
  /// progress.complete('Scan complete');
  /// ```
  Progress progress(String message) {
    return _logger.progress(_applyEmoji(message, ''));
  }

  /// Create a spinner (indeterminate progress).
  ///
  /// ```dart
  /// final spinner = logger.spinner('Fetching from pub.dev');
  /// await fetchData();
  /// spinner.complete('Fetched');
  /// ```
  Progress spinner(String message) {
    return _logger.progress(_applyEmoji(message, '🔄'));
  }

  // ==========================================================================
  // PROMPTS (User Input)
  // ==========================================================================

  /// Prompt user for yes/no confirmation.
  bool confirm(String message, {bool defaultValue = false}) {
    return _logger.confirm(
      _applyEmoji(message, '❓'),
      defaultValue: defaultValue,
    );
  }

  /// Prompt user to pick one choice from a list.
  String chooseOne(
    String message, {
    required List<String> choices,
    String? defaultValue,
  }) {
    return _logger.chooseOne(
      _applyEmoji(message, ''),
      choices: choices,
      defaultValue: defaultValue,
    );
  }

  /// Prompt user to pick multiple choices from a list.
  List<String> chooseAny(
    String message, {
    required List<String> choices,
    List<String>? defaultValues,
  }) {
    return _logger.chooseAny(
      _applyEmoji(message, ''),
      choices: choices,
      defaultValues: defaultValues,
    );
  }

  // ==========================================================================
  // THEMED OUTPUT
  // ==========================================================================

  /// Log with theme primary colour.
  void primary(String message) {
    if (_quiet) return;
    final styled = _useColors ? theme.primary.wrap(message) : message;
    _logger.info(styled ?? message);
  }

  /// Log with theme muted colour.
  void muted(String message) {
    if (_quiet) return;
    final styled = _useColors ? theme.muted.wrap(message) : message;
    _logger.info(styled ?? message);
  }

  /// Log a coloured alert message.
  void alert(String message, {AlertLevel level = AlertLevel.info}) {
    final styled = switch (level) {
      AlertLevel.info => cyan.wrap(message),
      AlertLevel.success => green.wrap(message),
      AlertLevel.warning => yellow.wrap(message),
      AlertLevel.error => red.wrap(message),
    };

    _logger.info(_applyEmoji(styled ?? message, _getAlertEmoji(level)));
  }

  // ==========================================================================
  // LOW-LEVEL I/O
  // ==========================================================================

  /// Write without a trailing newline (for live progress updates).
  void write(String message) {
    io.stdout.write(message);
  }

  /// Clear the current terminal line (ANSI environments only).
  void clearLine() {
    if (_useColors) {
      io.stdout.write('\r\x1B[K');
    }
  }

  /// Flush output — ensure all messages are written.
  void flush() {
    _logger.flush();
  }

  /// Underlying mason_logger instance (for advanced / custom usage).
  Logger get raw => _logger;

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  AnsiCode _getScoreColor(int percentage) {
    if (percentage >= 90) return theme.scoreExcellent;
    if (percentage >= 70) return theme.scoreGood;
    if (percentage >= 50) return theme.scoreFair;
    return theme.scorePoor;
  }

  String _applyEmoji(String message, String emoji) {
    if (!_useEmojis || emoji.isEmpty) return message;
    return '$emoji $message';
  }

  String _getAlertEmoji(AlertLevel level) {
    if (!_useEmojis) return '';
    return switch (level) {
      AlertLevel.info => cyan.wrap('i')!,
      AlertLevel.success => green.wrap('✓')!,
      AlertLevel.warning => yellow.wrap('!')!,
      AlertLevel.error => red.wrap('✗')!,
    };
  }
}

/// Alert severity levels for [ConsoleLogger.alert].
enum AlertLevel { info, success, warning, error }
