import 'package:args/command_runner.dart';
import 'package:cura/src/application/commands/cache/cache_cleanup.dart';
import 'package:cura/src/application/commands/cache/cache_clear.dart';
import 'package:cura/src/application/commands/cache/cache_stats.dart';
import 'package:cura/src/presentation/loggers/console_logger.dart';

/// Parent command that groups all local cache management sub-commands.
///
/// Running `cura cache` without a sub-command prints the usage help.
///
/// ### Sub-commands
/// | Sub-command | Description                       |
/// |-------------|-----------------------------------|
/// | `clear`     | Delete all cached entries         |
/// | `stats`     | Display cache entry counts        |
/// | `cleanup`   | Purge only expired entries        |
class CacheCommand extends Command<int> {
  /// Creates the [CacheCommand] and registers all sub-commands.
  CacheCommand({required ConsoleLogger logger}) {
    addSubcommand(CacheClearCommand(logger: logger));
    addSubcommand(CacheStatsCommand(logger: logger));
    addSubcommand(CacheCleanupCommand(logger: logger));
  }

  @override
  String get name => 'cache';

  @override
  String get description => 'Manage the local SQLite cache';
}
