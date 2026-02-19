import 'dart:io' as io;

import 'package:cura/src/presentation/cli/themes/theme.dart';
import 'package:cura/src/presentation/cli/themes/theme_manager.dart';
import 'package:mason_logger/mason_logger.dart';

/// Logger console with mason_logger
///
/// Features:
/// - Automatic colorization (respects the use_colors configuration)
/// - Animated progress bars
/// - Emojis (respect the use_emojis configuration)
/// - Log levels (info, success, warning, error)
/// - Quiet mode support
class ConsoleLogger {
  final Logger _logger;
  final bool _useColors;
  final bool _useEmojis;
  final bool _quiet;

  ConsoleLogger({
    bool useColors = true,
    bool useEmojis = true,
    bool quiet = false,
    Level? level,
  })  : _useColors = useColors,
        _useEmojis = useEmojis,
        _quiet = quiet,
        _logger = Logger(
          level: level ?? (quiet ? Level.error : Level.info),
          // Disable colors if the configuration requires it.
          // theme: useColors ? LogTheme() : LogTheme.noColor(),
        );

  CuraTheme get theme => ThemeManager.current;

  // ==========================================================================
  // BASIC LOGGING
  // ==========================================================================

  /// Log info message
  void info(String message) {
    if (_quiet) return;
    _logger.info(_applyEmoji(message, ''));
  }

  /// Log success message (green)
  void success(String message) {
    if (_quiet) return;
    _logger.success(_applyEmoji(message, '✓'));
  }

  /// Log warning message (yellow)
  // void warn(String message, {bool showSymbol = true}) {
  //   _logger.warn(_applyEmoji(message, '⚠'), tag: '');
  // }

  void warn(String message, {bool showSymbol = true}) {
    if (showSymbol) {
      _logger.info('${theme.warning.wrap(message)}');
    } else {
      _logger.info('${theme.warning.wrap(message)}');
    }
  }

  /// Log error message (red)
  void error(String message) {
    _logger.err('${theme.error.wrap(message)}');
    //_logger.err(_applyEmoji(message, '✗'));
  }

  /// Log detail message (gray/dim)
  void detail(String message) {
    if (_quiet) return;
    _logger.detail(_applyEmoji(message, ''));
  }

  /// Log debug message (only in verbose mode)
  void debug(String message) {
    if (_quiet) return;
    _logger.detail(lightGray.wrap('🐛 $message'));
  }

  // ==========================================================================
  // PROGRESS INDICATORS
  // ==========================================================================

  /// Create a progress bar
  ///
  /// Example:
  /// ```dart
  /// final progress = logger.progress('Scanning packages');
  /// await doWork();
  /// progress.complete('Scan complete');
  /// ```
  Progress progress(String message) {
    return _logger.progress(_applyEmoji(message, ''));
  }

  /// Create a spinner (indeterminate progress)
  ///
  /// Example:
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

  /// Prompt user for confirmation (yes/no)
  ///
  /// Example:
  /// ```dart
  /// if (logger.confirm('Apply suggestion?')) {
  ///   applySuggestion();
  /// }
  /// ```
  bool confirm(String message, {bool defaultValue = false}) {
    return _logger.confirm(
      _applyEmoji(message, '❓'),
      defaultValue: defaultValue,
    );
  }

  /// Prompt user for choice (single select)
  ///
  /// Example:
  /// ```dart
  /// final choice = logger.chooseOne(
  ///   'Select theme:',
  ///   choices: ['dark', 'light', 'minimal'],
  /// );
  /// ```
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

  /// Prompt user for multiple choices
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
  // FORMATTING HELPERS
  // ==========================================================================

  /// Write without newline (for progress updates)
  void write(String message) {
    io.stdout.write(message);
  }

  /// Clear current line (for live updates)
  void clearLine() {
    if (_useColors) {
      io.stdout.write('\r\x1B[K'); // ANSI: clear line
    }
  }

  /// Write alert message (bold + colored)
  void alert(String message, {AlertLevel level = AlertLevel.info}) {
    final styled = switch (level) {
      AlertLevel.info => cyan.wrap(message),
      AlertLevel.success => green.wrap(message),
      AlertLevel.warning => yellow.wrap(message),
      AlertLevel.error => red.wrap(message),
    };

    _logger.info(_applyEmoji(styled ?? message, _getAlertEmoji(level)));
  }

  /// Spacer (empty line)
  void spacer() {
    if (_quiet) return;
    _logger.info('');
  }

  /// Divider line
  void divider({int length = 50, String char = '─'}) {
    if (_quiet) return;
    _logger.info(char * length);
  }

  // ==========================================================================
  // THEMED OUTPUT (Integration with CuraTheme)
  // ==========================================================================

  /// Log with theme color (primary)
  void primary(String message) {
    if (_quiet) return;

    final theme = ThemeManager.current;
    final styled = _useColors ? theme.primary.wrap(message) : message;

    _logger.info(styled ?? message);
  }

  /// Log with theme color (muted)
  void muted(String message) {
    if (_quiet) return;

    final theme = ThemeManager.current;
    final styled = _useColors ? theme.muted.wrap(message) : message;

    _logger.detail(styled ?? message);
  }

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  /// Apply emoji if enabled
  String _applyEmoji(String message, String emoji) {
    if (!_useEmojis || emoji.isEmpty) return message;
    return '$emoji $message';
  }

  /// Get emoji for alert level
  String _getAlertEmoji(AlertLevel level) {
    if (!_useEmojis) return '';

    return switch (level) {
      AlertLevel.info => 'ℹ️',
      AlertLevel.success => '✅',
      AlertLevel.warning => '⚠️',
      AlertLevel.error => '❌',
    };
  }

  // ==========================================================================
  // ADVANCED FEATURES
  // ==========================================================================

  /// Flush output (ensure all messages are written)
  void flush() {
    _logger.flush();
  }

  /// Get underlying mason_logger instance (for advanced usage)
  Logger get raw => _logger;
}

/// Alert levels
enum AlertLevel {
  info,
  success,
  warning,
  error,
}
