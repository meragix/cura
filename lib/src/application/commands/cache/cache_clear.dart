import 'package:args/command_runner.dart';
import 'package:cura/src/infrastructure/cache/database/cache_database.dart';
import 'package:cura/src/presentation/loggers/console_logger.dart';

/// Sub-command: `cura cache clear`
///
/// Prompts the user for confirmation and then deletes every row in every cache
/// table via [CacheDatabase.clearAll].
///
/// ### Behaviour
/// - Prints a confirmation prompt before acting (defaults to **no**).
/// - Cancels silently when the user declines.
/// - Exits with code `1` when the database operation fails.
class CacheClearCommand extends Command<int> {
  final ConsoleLogger _logger;

  /// Creates a [CacheClearCommand].
  CacheClearCommand({required ConsoleLogger logger}) : _logger = logger;

  @override
  String get name => 'clear';

  @override
  String get description => 'Clear all cache entries';

  @override
  Future<int> run() async {
    _logger.spacer();

    if (!_logger.confirm('Clear all cache?', defaultValue: false)) {
      _logger.info('Cancelled');
      return 0;
    }

    _logger.info('Clearing cache...');

    try {
      await CacheDatabase.clearAll();
      _logger.success('Cache cleared');
      _logger.spacer();
      return 0;
    } catch (e) {
      _logger.error('Failed to clear cache: $e');
      return 1;
    }
  }
}
