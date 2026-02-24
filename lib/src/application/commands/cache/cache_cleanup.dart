import 'package:args/command_runner.dart';
import 'package:cura/src/infrastructure/cache/database/cache_database.dart';
import 'package:cura/src/presentation/loggers/console_logger.dart';

/// Sub-command: `cura cache cleanup`
///
/// Removes only the entries whose TTL has elapsed, leaving valid cached data
/// untouched. Internally delegates to [CacheDatabase.cleanupExpired].
///
/// ### Behaviour
/// - Safe to run at any time — valid entries are never removed.
/// - Exits with code `1` when the database operation fails.
class CacheCleanupCommand extends Command<int> {
  final ConsoleLogger _logger;

  /// Creates a [CacheCleanupCommand].
  CacheCleanupCommand({required ConsoleLogger logger}) : _logger = logger;

  @override
  String get name => 'cleanup';

  @override
  String get description => 'Remove expired cache entries';

  @override
  Future<int> run() async {
    _logger.spacer();
    _logger.info('Cleaning up expired entries...');

    try {
      await CacheDatabase.cleanupExpired();
      _logger.success('Cleanup complete');
      _logger.spacer();
      return 0;
    } catch (e) {
      _logger.error('Failed to clean up cache: $e');
      return 1;
    }
  }
}
