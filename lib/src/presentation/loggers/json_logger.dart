import 'dart:convert';

import 'package:cura/src/presentation/loggers/console_logger.dart';
import 'package:mason_logger/mason_logger.dart';

/// Logger that suppresses all human-readable output and instead accumulates
/// structured data for a single JSON payload written on [flush].
///
/// Usage:
/// ```dart
/// final logger = JsonLogger();
/// logger.addData('packages', results);
/// logger.flush(); // prints JSON to stdout
/// ```
class JsonLogger extends ConsoleLogger {
  final Map<String, dynamic> _output = {};

  JsonLogger()
      : super(
          useColors: false,
          useEmojis: false,
          quiet: true,
          level: Level.error,
        );

  // Override all text-output methods to suppress console noise.
  @override
  void info(String message) {}

  @override
  void success(String message, {bool showSymbol = true}) {}

  @override
  void warn(String message, {bool showSymbol = true}) {}

  @override
  void detail(String message) {}

  @override
  void debug(String message) {}

  @override
  void section(String title) {}

  @override
  void header(String title) {}

  @override
  void spacer() {}

  @override
  void divider({int length = 50, String char = '─'}) {}

  @override
  void primary(String message) {}

  @override
  void muted(String message) {}

  @override
  void alert(String message, {AlertLevel level = AlertLevel.info}) {}

  // ==========================================================================
  // JSON-SPECIFIC API
  // ==========================================================================

  /// Add a key-value pair to the JSON output.
  void addData(String key, dynamic value) {
    _output[key] = value;
  }

  /// Write the accumulated data as a single JSON document to stdout.
  @override
  void flush() {
    print(jsonEncode(_output));
  }
}
