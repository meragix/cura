import 'dart:io';

import 'package:cura/src/presentation/themes/theme_manager.dart';

/// Logger console avec support des couleurs ANSI
class ConsoleLogger {
  final bool _useColors;
  final bool _useEmojis;

  ConsoleLogger({
    bool useColors = true,
    bool useEmojis = true,
  })  : _useColors = useColors,
        _useEmojis = useEmojis;

  void info(String message) {
    final colored = _useColors ? ThemeManager.current.info.wrap(message) : message;
    stdout.writeln(colored);
  }

  void success(String message) {
    final colored = _useColors ? ThemeManager.current.success.wrap(message) : message;
    stdout.writeln(colored);
  }

  void warn(String message) {
    final colored = _useColors ? ThemeManager.current.warning.wrap(message) : message;
    stdout.writeln(colored);
  }

  void error(String message) {
    final colored = _useColors ? ThemeManager.current.error.wrap(message) : message;
    stderr.writeln(colored);
  }

  void write(String message) {
    stdout.write(message);
  }

  void clearLine() {
    if (_useColors) {
      stdout.write('\r\x1B[K'); // ANSI escape: clear line
    }
  }
}
