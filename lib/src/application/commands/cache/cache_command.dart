import 'package:args/command_runner.dart';
import 'package:cura/src/application/commands/cache/cache_cleanup.dart';
import 'package:cura/src/application/commands/cache/cache_clear.dart';
import 'package:cura/src/application/commands/cache/cache_stats.dart';
import 'package:cura/src/infrastructure/cache/json_file_system_cache.dart';
import 'package:cura/src/presentation/loggers/console_logger.dart';

/// Parent command that groups all local cache management sub-commands.
///
/// Running `cura cache` without a sub-command prints the usage help.
///
/// ### Sub-commands
/// | Sub-command | Description                              |
/// |-------------|------------------------------------------|
/// | `clear`     | Delete all cached entries                |
/// | `stats`     | Display valid entry counts per namespace |
/// | `cleanup`   | Purge expired entries and orphaned .tmp  |
class CacheCommand extends Command<int> {
  /// Creates the [CacheCommand] and registers all sub-commands.
  CacheCommand({
    required ConsoleLogger logger,
    required JsonFileSystemCache cache,
  }) {
    addSubcommand(CacheClearCommand(logger: logger, cache: cache));
    addSubcommand(CacheStatsCommand(logger: logger, cache: cache));
    addSubcommand(CacheCleanupCommand(logger: logger, cache: cache));
  }

  @override
  String get name => 'cache';

  @override
  String get description => 'Manage the local JSON file cache';
}
