import 'package:args/command_runner.dart';
import 'package:cura/src/infrastructure/cache/json_file_system_cache.dart';
import 'package:cura/src/presentation/loggers/console_logger.dart';

/// Sub-command: `cura cache stats`
///
/// Queries the JSON file cache and prints valid (non-expired) entry counts
/// per namespace.
///
/// ### Output example
/// ```
/// Cache Statistics:
///
///   Aggregated cache : 10 entries
///   ──────────────────────────────
///   Total            : 10 entries
/// ```
///
/// Exits with code `1` when the cache directory cannot be read.
class CacheStatsCommand extends Command<int> {
  final ConsoleLogger _logger;
  final JsonFileSystemCache _cache;

  /// Creates a [CacheStatsCommand].
  CacheStatsCommand({
    required ConsoleLogger logger,
    required JsonFileSystemCache cache,
  })  : _logger = logger,
        _cache = cache;

  @override
  String get name => 'stats';

  @override
  String get description => 'Show cache entry counts per namespace';

  @override
  Future<int> run() async {
    _logger.spacer();
    _logger.info('Cache Statistics:');
    _logger.spacer();

    try {
      final counts = await _cache.stats();

      final aggregatedCount =
          counts[JsonFileSystemCache.aggregatedNamespace] ?? 0;
      final total = counts.values.fold(0, (sum, v) => sum + v);

      _logger.info('  Aggregated cache : $aggregatedCount entries');
      _logger.divider();
      _logger.info('  Total            : $total entries');
      _logger.spacer();

      return 0;
    } catch (e) {
      _logger.error('Failed to read cache statistics: $e');
      return 1;
    }
  }
}
