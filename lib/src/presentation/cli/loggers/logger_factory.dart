import 'package:cura/src/infrastructure/config/models/cura_config.dart';
import 'package:cura/src/presentation/cli/loggers/console_logger.dart';
import 'package:mason_logger/mason_logger.dart';

class LoggerFactory {
  const LoggerFactory._();

  /// Create logger from config
  static ConsoleLogger fromConfig(CuraConfig config) {
    return ConsoleLogger(
      useColors: config.useColors,
      useEmojis: config.useEmojis,
      quiet: config.quiet,
      level: config.verboseLogging ? Level.verbose : Level.info,
    );
  }

  /// Create quiet logger (CI/CD mode)
  static ConsoleLogger quiet() {
    return ConsoleLogger(
      useColors: false,
      useEmojis: false,
      quiet: true,
      level: Level.error,
    );
  }

  /// Create verbose logger (debug mode)
  static ConsoleLogger verbose() {
    return ConsoleLogger(
      useColors: true,
      useEmojis: true,
      quiet: false,
      level: Level.verbose,
    );
  }

  /// Create minimal logger (CI/CD with minimal output)
  static ConsoleLogger minimal() {
    return ConsoleLogger(
      useColors: false,
      useEmojis: false,
      quiet: false,
      level: Level.info,
    );
  }
}
