import 'package:args/command_runner.dart';
import 'package:cura/src/infrastructure/cache/database/cache_database.dart';
import 'package:cura/src/presentation/loggers/console_logger.dart';
import 'package:sqflite_common/utils/utils.dart' as sqflite_utils;

/// Sub-command: `cura cache stats`
///
/// Queries the SQLite cache database and prints entry counts for each table.
///
/// ### Output example
/// ```
/// Cache Statistics:
///
///   Package cache    : 12 entries
///   Aggregated cache : 10 entries
///   ──────────────────────────────
///   Total            : 22 entries
/// ```
///
/// Exits with code `1` when the database cannot be opened or queried.
class CacheStatsCommand extends Command<int> {
  final ConsoleLogger _logger;

  /// Creates a [CacheStatsCommand].
  CacheStatsCommand({required ConsoleLogger logger}) : _logger = logger;

  @override
  String get name => 'stats';

  @override
  String get description => 'Show cache entry counts per table';

  @override
  Future<int> run() async {
    _logger.spacer();
    _logger.info('Cache Statistics:');
    _logger.spacer();

    try {
      final db = await CacheDatabase.instance;

      final packageCount = sqflite_utils.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM package_cache'),
          ) ??
          0;

      final aggregatedCount = sqflite_utils.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM aggregated_cache'),
          ) ??
          0;

      _logger.info('  Package cache    : $packageCount entries');
      _logger.info('  Aggregated cache : $aggregatedCount entries');
      _logger.divider();
      _logger.info('  Total            : ${packageCount + aggregatedCount} entries');
      _logger.spacer();

      return 0;
    } catch (e) {
      _logger.error('Failed to read cache statistics: $e');
      return 1;
    }
  }
}
