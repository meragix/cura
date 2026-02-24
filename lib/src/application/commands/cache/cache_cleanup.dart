import 'package:args/command_runner.dart';
import 'package:cura/src/infrastructure/cache/json_file_system_cache.dart';
import 'package:cura/src/presentation/loggers/console_logger.dart';

/// Sub-command: `cura cache cleanup`
///
/// Removes only the entries whose TTL has elapsed and orphaned `.tmp` files,
/// leaving valid cached data untouched. Delegates to
/// [JsonFileSystemCache.cleanupExpired].
///
/// ### Behaviour
/// - Safe to run at any time — valid entries are never removed.
/// - Reports the number of files deleted.
/// - Exits with code `1` when the cache operation fails.
class CacheCleanupCommand extends Command<int> {
  final ConsoleLogger _logger;
  final JsonFileSystemCache _cache;

  /// Creates a [CacheCleanupCommand].
  CacheCleanupCommand({
    required ConsoleLogger logger,
    required JsonFileSystemCache cache,
  })  : _logger = logger,
        _cache = cache;

  @override
  String get name => 'cleanup';

  @override
  String get description => 'Remove expired cache entries';

  @override
  Future<int> run() async {
    _logger.spacer();
    _logger.info('Cleaning up expired entries...');

    try {
      final deleted = await _cache.cleanupExpired();
      _logger.success(
        deleted > 0
            ? 'Cleanup complete — $deleted ${deleted == 1 ? "entry" : "entries"} removed'
            : 'Cleanup complete — nothing to remove',
      );
      _logger.spacer();
      return 0;
    } catch (e) {
      _logger.error('Failed to clean up cache: $e');
      return 1;
    }
  }
}
